import Foundation
import Speech
import AVFoundation

// A single transcript update from a provider — either an in-progress partial guess or the final,
// committed text for an utterance.
enum TranscriptUpdate: Equatable {
    case partial(String)
    case final(String)
}

// The pluggable interface every speech-to-text backend implements. A provider streams
// TranscriptUpdate values while it is running; callers consume the AsyncStream until it finishes.
protocol TranscriptionProvider: AnyObject {
    // Begins capturing + transcribing and returns a stream of partial/final updates. The stream
    // finishes when `stopTranscribing()` is called (or the provider errors out).
    func startTranscribing() -> AsyncStream<TranscriptUpdate>
    // Stops capture and finalizes any in-flight utterance.
    func stopTranscribing()
}

// MARK: - Parakeet warm daemon engine

// Runs the Parakeet TDT 0.6B v3 model via a LONG-LIVED Python daemon (voice-sidecar/parakeet_stt.py),
// spawned once at app startup. The model loads exactly once — at launch — and each push-to-talk
// hold is then just a {"cmd":"start"} / {"cmd":"stop"} exchange over stdin, so the mic is hot
// ~0.1s after the press. (The first architecture launched a fresh process per hold and paid a
// model load inside every hold; users talked into a dead mic. Never again.)
final class ParakeetWarmEngine: TranscriptionProvider {
    private let sidecarScriptPath: String

    private var sidecarProcess: Process?
    private var sidecarStandardInput: Pipe?

    // Guards the mutable session state below — stdout parsing runs on a pipe-callback thread while
    // start/stop arrive from the main actor.
    private let stateLock = NSLock()
    private var activeSessionContinuation: AsyncStream<TranscriptUpdate>.Continuation?
    private(set) var isModelReady = false
    private var respawnAttemptCount = 0
    private static let maximumRespawnAttempts = 3

    // Whether the daemon can plausibly run at all: its script exists and a python3 is available
    // (preferring the sidecar's venv). Checked before choosing this engine.
    static func isSidecarRunnable(sidecarScriptPath: String = WispConfig.parakeetSidecarScriptPath) -> Bool {
        guard FileManager.default.fileExists(atPath: sidecarScriptPath) else { return false }
        if WispConfig.sidecarPythonExecutablePath != "python3" { return true }
        let pathEnvironment = ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin"
        return pathEnvironment
            .split(separator: ":")
            .contains { FileManager.default.isExecutableFile(atPath: "\($0)/python3") }
    }

    init(sidecarScriptPath: String = WispConfig.parakeetSidecarScriptPath) {
        self.sidecarScriptPath = sidecarScriptPath
    }

    // MARK: Engine lifecycle (once per app run)

    // Spawns the daemon and starts the model load. Call once at app startup, BEFORE any session —
    // by the time the user first presses the hotkey the model is warm.
    func startEngine() {
        spawnSidecarDaemon()
    }

    // Clean shutdown at app quit.
    func shutdownEngine() {
        sendCommand("quit")
        let processToReap = sidecarProcess
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            if let processToReap, processToReap.isRunning {
                processToReap.terminate()
            }
        }
        sidecarProcess = nil
    }

    private func spawnSidecarDaemon() {
        let daemonProcess = Process()
        daemonProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        daemonProcess.arguments = [WispConfig.sidecarPythonExecutablePath, sidecarScriptPath]
        // The daemon idles blocked on stdin between sessions, which makes it a prime App Nap
        // victim — observed live: after ~9 idle minutes, a start command took 5–10s to open the
        // mic because macOS had throttled the child. Interactive QoS keeps it wake-ready.
        daemonProcess.qualityOfService = .userInteractive

        let standardInputPipe = Pipe()
        let standardOutputPipe = Pipe()
        let standardErrorPipe = Pipe()
        daemonProcess.standardInput = standardInputPipe
        daemonProcess.standardOutput = standardOutputPipe
        daemonProcess.standardError = standardErrorPipe

        standardOutputPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            let availableData = fileHandle.availableData
            guard !availableData.isEmpty,
                  let outputChunk = String(data: availableData, encoding: .utf8) else {
                return
            }
            for jsonLine in outputChunk.split(separator: "\n") {
                self?.handleSidecarLine(String(jsonLine))
            }
        }

        // Mirror stderr into the log — model downloads, tracebacks, audio-device complaints.
        standardErrorPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let availableData = fileHandle.availableData
            guard !availableData.isEmpty,
                  let errorChunk = String(data: availableData, encoding: .utf8) else {
                return
            }
            for errorLine in errorChunk.split(separator: "\n") where !errorLine.trimmingCharacters(in: .whitespaces).isEmpty {
                WispLog.log("sidecar", String(errorLine.prefix(300)))
            }
        }

        daemonProcess.terminationHandler = { [weak self] endedProcess in
            guard let self else { return }
            WispLog.log("voice", "parakeet daemon exited (status \(endedProcess.terminationStatus))")
            self.stateLock.lock()
            self.isModelReady = false
            let orphanedContinuation = self.activeSessionContinuation
            self.activeSessionContinuation = nil
            let shouldRespawn = self.respawnAttemptCount < Self.maximumRespawnAttempts
            if shouldRespawn { self.respawnAttemptCount += 1 }
            self.stateLock.unlock()

            orphanedContinuation?.finish()
            if shouldRespawn {
                WispLog.log("voice", "respawning parakeet daemon (attempt \(self.respawnAttemptCount)/\(Self.maximumRespawnAttempts))")
                DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.spawnSidecarDaemon()
                }
            } else {
                WispLog.log("voice", "parakeet daemon gave up after \(Self.maximumRespawnAttempts) respawns — sessions will fall back to Apple Speech")
            }
        }

        do {
            try daemonProcess.run()
            sidecarProcess = daemonProcess
            sidecarStandardInput = standardInputPipe
            WispLog.log("voice", "parakeet daemon spawned — loading model (once)…")
        } catch {
            WispLog.log("voice", "parakeet daemon failed to launch: \(error.localizedDescription)")
            sidecarProcess = nil
            sidecarStandardInput = nil
        }
    }

    // MARK: TranscriptionProvider (per push-to-talk session)

    func startTranscribing() -> AsyncStream<TranscriptUpdate> {
        AsyncStream { continuation in
            stateLock.lock()
            activeSessionContinuation = continuation
            let engineIsAlive = sidecarProcess?.isRunning ?? false
            let modelWasReadyAtStart = isModelReady
            stateLock.unlock()

            guard engineIsAlive else {
                WispLog.log("voice", "parakeet daemon not running — session cannot start")
                continuation.finish()
                return
            }
            if !modelWasReadyAtStart {
                // Command is queued in the pipe; the daemon opens the mic as soon as the model
                // finishes loading. Only possible in the first seconds after app launch.
                WispLog.log("voice", "session started before model ready — daemon will open mic once warm")
            }
            sendCommand("start")
        }
    }

    func stopTranscribing() {
        sendCommand("stop")
        // The daemon replies: (optional) {"final": …} then {"status": "stopped"} — the stopped
        // status finishes the session stream, so the final always drains first. No process kill.
    }

    private func sendCommand(_ commandName: String) {
        guard let commandData = "{\"cmd\": \"\(commandName)\"}\n".data(using: .utf8) else { return }
        // Timestamped so the log shows send→"listening" latency (the App Nap lag was found by
        // exactly this gap; keep it observable).
        WispLog.log("voice", "→ daemon: \(commandName)")
        sidecarStandardInput?.fileHandleForWriting.write(commandData)
    }

    // MARK: stdout protocol

    private func handleSidecarLine(_ jsonLine: String) {
        let trimmedLine = jsonLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLine.isEmpty,
              let lineData = trimmedLine.data(using: .utf8),
              let decodedObject = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
            return
        }

        if let partialText = decodedObject["partial"] as? String {
            currentContinuation()?.yield(.partial(partialText))
        } else if let finalText = decodedObject["final"] as? String {
            currentContinuation()?.yield(.final(finalText))
        } else if let statusText = decodedObject["status"] as? String {
            WispLog.log("voice", "parakeet daemon status: \(statusText)")
            switch statusText {
            case "ready":
                stateLock.lock()
                isModelReady = true
                respawnAttemptCount = 0
                stateLock.unlock()
            case "stopped":
                stateLock.lock()
                let finishedContinuation = activeSessionContinuation
                activeSessionContinuation = nil
                stateLock.unlock()
                finishedContinuation?.finish()
            default:
                break
            }
        } else if let errorText = decodedObject["error"] as? String {
            WispLog.log("voice", "parakeet daemon error: \(errorText)")
        }
    }

    private func currentContinuation() -> AsyncStream<TranscriptUpdate>.Continuation? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return activeSessionContinuation
    }
}

// MARK: - Apple Speech fallback provider

// A local, on-device fallback that uses Apple's Speech framework (SFSpeechRecognizer) driven by an
// AVAudioEngine microphone tap. Used automatically when the Parakeet daemon is unavailable. This
// needs Microphone + Speech Recognition permissions.
final class AppleSpeechProvider: TranscriptionProvider {
    private let speechRecognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func startTranscribing() -> AsyncStream<TranscriptUpdate> {
        AsyncStream { continuation in
            // Speech recognition is permission-gated; without an explicit authorization request the
            // recognition task errors out instantly and the session looks silently dead.
            let currentAuthorizationStatus = SFSpeechRecognizer.authorizationStatus()
            if currentAuthorizationStatus == .notDetermined {
                // TCC ABORTS an unbundled (bare `swift run`) binary that requests speech auth —
                // __TCC_CRASHING_DUE_TO_PRIVACY_VIOLATION__ — so only request from a real .app.
                guard Bundle.main.bundlePath.hasSuffix(".app") else {
                    WispLog.log("voice", "Apple Speech unavailable unbundled (TCC would abort on the auth request) — run as Wisp.app via scripts/make-app.sh, or rely on Parakeet")
                    continuation.finish()
                    return
                }
                WispLog.log("voice", "requesting Speech Recognition authorization…")
                SFSpeechRecognizer.requestAuthorization { grantedStatus in
                    WispLog.log("voice", "Speech Recognition authorization: \(grantedStatus.rawValue) (1=denied 2=restricted 3=authorized)")
                }
                // The user is mid-permission-dialog; this session can't proceed. The next hold will.
                continuation.finish()
                return
            }
            guard currentAuthorizationStatus == .authorized else {
                WispLog.log("voice", "Speech Recognition not authorized (status \(currentAuthorizationStatus.rawValue)) — grant it in System Settings → Privacy & Security → Speech Recognition")
                continuation.finish()
                return
            }

            guard let speechRecognizer, speechRecognizer.isAvailable else {
                WispLog.log("voice", "SFSpeechRecognizer unavailable (locale/offline model)")
                continuation.finish()
                return
            }

            let bufferRecognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            bufferRecognitionRequest.shouldReportPartialResults = true
            self.recognitionRequest = bufferRecognitionRequest

            // Tap the microphone input and feed buffers into the recognition request.
            let inputNode = audioEngine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { audioBuffer, _ in
                bufferRecognitionRequest.append(audioBuffer)
            }

            audioEngine.prepare()
            do {
                try audioEngine.start()
            } catch {
                WispLog.log("voice", "AVAudioEngine failed to start: \(error.localizedDescription) (microphone permission?)")
                continuation.finish()
                return
            }

            self.recognitionTask = speechRecognizer.recognitionTask(with: bufferRecognitionRequest) { recognitionResult, error in
                if let error {
                    WispLog.log("voice", "recognition error: \(error.localizedDescription)")
                }
                if let recognitionResult {
                    let transcribedText = recognitionResult.bestTranscription.formattedString
                    if recognitionResult.isFinal {
                        continuation.yield(.final(transcribedText))
                    } else {
                        continuation.yield(.partial(transcribedText))
                    }
                }
                if error != nil || (recognitionResult?.isFinal ?? false) {
                    continuation.finish()
                }
            }

            continuation.onTermination = { [weak self] _ in
                self?.teardownAudioEngine()
            }
        }
    }

    func stopTranscribing() {
        // Ending audio tells the recognizer to finalize; then tear down the engine + tap.
        recognitionRequest?.endAudio()
        teardownAudioEngine()
    }

    private func teardownAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }
}
