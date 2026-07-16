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

// MARK: - Parakeet Python sidecar provider

// Runs the Parakeet TDT 0.6B v3 speech-to-text model via a Python sidecar process. The sidecar
// (voice-sidecar/parakeet_stt.py) captures the microphone locally on Apple Silicon and prints JSON
// lines — {"partial": "..."} while speaking and {"final": "..."} at end of utterance — which we
// parse and forward. WHY a sidecar: Parakeet runs through parakeet-mlx (Python), so the cleanest
// integration from Swift is to launch it as a child process and stream its stdout. If Python, the
// package, or the model is missing the sidecar exits with an error and the caller falls back to
// AppleSpeechProvider.
final class ParakeetSidecarProvider: TranscriptionProvider {
    private let sidecarScriptPath: String
    private var sidecarProcess: Process?

    // A handle we can check to decide whether to fall back before even starting.
    private(set) var didFailToLaunch = false

    init(sidecarScriptPath: String = WispConfig.parakeetSidecarScriptPath) {
        self.sidecarScriptPath = sidecarScriptPath
    }

    // Whether the sidecar can plausibly run at all: its script exists and a python3 is on PATH.
    // Checked BEFORE choosing this provider — a launch-failure flag set after the fact is useless
    // for provider selection (that bug shipped once; hence this).
    static func isSidecarRunnable(sidecarScriptPath: String = WispConfig.parakeetSidecarScriptPath) -> Bool {
        guard FileManager.default.fileExists(atPath: sidecarScriptPath) else { return false }
        let pathEnvironment = ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin"
        return pathEnvironment
            .split(separator: ":")
            .contains { FileManager.default.isExecutableFile(atPath: "\($0)/python3") }
    }

    func startTranscribing() -> AsyncStream<TranscriptUpdate> {
        AsyncStream { continuation in
            let launchedProcess = Process()
            // Prefer the sidecar's own venv python (which has parakeet-mlx); `python3` otherwise.
            launchedProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            launchedProcess.arguments = [WispConfig.sidecarPythonExecutablePath, sidecarScriptPath]

            let standardOutputPipe = Pipe()
            let standardErrorPipe = Pipe()
            launchedProcess.standardOutput = standardOutputPipe
            launchedProcess.standardError = standardErrorPipe

            // Parse each newline-delimited JSON object emitted on stdout into a TranscriptUpdate.
            standardOutputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
                let availableData = fileHandle.availableData
                guard !availableData.isEmpty,
                      let outputChunk = String(data: availableData, encoding: .utf8) else {
                    return
                }
                for jsonLine in outputChunk.split(separator: "\n") {
                    Self.parseSidecarLine(String(jsonLine), into: continuation)
                }
            }

            do {
                try launchedProcess.run()
                self.sidecarProcess = launchedProcess
            } catch {
                // The sidecar couldn't even be launched (e.g. python3 not found). Signal failure so
                // the caller can fall back to Apple Speech.
                self.didFailToLaunch = true
                continuation.finish()
                return
            }

            // When the process exits, close out the stream.
            launchedProcess.terminationHandler = { _ in
                continuation.finish()
            }

            // If the stream is torn down (task cancelled), make sure we kill the child process.
            continuation.onTermination = { [weak self] _ in
                self?.terminateSidecarProcessIfRunning()
            }
        }
    }

    func stopTranscribing() {
        terminateSidecarProcessIfRunning()
    }

    private func terminateSidecarProcessIfRunning() {
        guard let sidecarProcess, sidecarProcess.isRunning else { return }
        sidecarProcess.terminate()
        self.sidecarProcess = nil
    }

    // Parses one line of sidecar stdout. Recognized shapes: {"partial": "..."}, {"final": "..."},
    // and {"error": "..."} (which we surface as a final empty result so the caller can fall back).
    private static func parseSidecarLine(_ jsonLine: String, into continuation: AsyncStream<TranscriptUpdate>.Continuation) {
        let trimmedLine = jsonLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLine.isEmpty,
              let lineData = trimmedLine.data(using: .utf8),
              let decodedObject = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
            return
        }

        if let partialText = decodedObject["partial"] as? String {
            continuation.yield(.partial(partialText))
        } else if let finalText = decodedObject["final"] as? String {
            continuation.yield(.final(finalText))
        } else if let errorText = decodedObject["error"] as? String {
            // Surface sidecar-reported problems (e.g. "parakeet-mlx not installed") in the log so a
            // silent no-transcript session is diagnosable.
            WispLog.log("voice", "parakeet sidecar error: \(errorText)")
        }
    }
}

// MARK: - Apple Speech fallback provider

// A local, on-device fallback that uses Apple's Speech framework (SFSpeechRecognizer) driven by an
// AVAudioEngine microphone tap. Used automatically when the Parakeet sidecar is unavailable. This
// needs Microphone + Speech Recognition permissions; the caller is responsible for requesting them.
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
