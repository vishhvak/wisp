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

    func startTranscribing() -> AsyncStream<TranscriptUpdate> {
        AsyncStream { continuation in
            let launchedProcess = Process()
            // Use `python3` from PATH; the sidecar itself imports parakeet-mlx and reports cleanly
            // if it's not installed.
            launchedProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            launchedProcess.arguments = ["python3", sidecarScriptPath]

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
        }
        // An {"error": ...} line is ignored here; the process exit + fallback path handles recovery.
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
            guard let speechRecognizer, speechRecognizer.isAvailable else {
                // No recognizer available (e.g. unsupported locale) — finish immediately.
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
                continuation.finish()
                return
            }

            self.recognitionTask = speechRecognizer.recognitionTask(with: bufferRecognitionRequest) { recognitionResult, error in
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
