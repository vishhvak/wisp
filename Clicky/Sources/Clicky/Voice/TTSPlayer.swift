import Foundation
import AVFoundation

// Plays Clicky's spoken responses. Text is POSTed to the Cloudflare Worker's /tts route (which
// holds the ElevenLabs key and forwards to ElevenLabs), and the returned audio bytes are played
// back locally via AVAudioPlayer. `isSpeaking` is published-style state the overlay uses to show
// the "responding" cursor glyph and to schedule the transient-cursor fade-out.
@MainActor
final class TTSPlayer: NSObject, ObservableObject {
    // True while audio is actively playing, so the UI can reflect the "Speaking" state.
    @Published private(set) var isSpeaking = false

    private var audioPlayer: AVAudioPlayer?

    // Sends `text` to the Worker's /tts route and plays the returned audio. Any network/decoding
    // failure is swallowed to a no-op — TTS is a non-critical enhancement, not a hard dependency.
    func speak(_ text: String) async {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let textToSpeechURL = ClickyConfig.workerBaseURL.appendingPathComponent("tts")
        var textToSpeechRequest = URLRequest(url: textToSpeechURL)
        textToSpeechRequest.httpMethod = "POST"
        textToSpeechRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // The Worker expects a simple JSON body carrying the text to synthesize.
        let requestBody: [String: String] = ["text": trimmedText]
        textToSpeechRequest.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        do {
            let (audioData, _) = try await URLSession.shared.data(for: textToSpeechRequest)
            playAudioData(audioData)
        } catch {
            // Network error or Worker unavailable — leave isSpeaking false and return quietly.
            isSpeaking = false
        }
    }

    // Stops any in-progress playback immediately.
    func stopSpeaking() {
        audioPlayer?.stop()
        audioPlayer = nil
        isSpeaking = false
    }

    private func playAudioData(_ audioData: Data) {
        do {
            let createdAudioPlayer = try AVAudioPlayer(data: audioData)
            createdAudioPlayer.delegate = self
            self.audioPlayer = createdAudioPlayer
            isSpeaking = true
            createdAudioPlayer.play()
        } catch {
            // The returned bytes weren't playable audio (e.g. an error JSON from the Worker).
            isSpeaking = false
        }
    }
}

extension TTSPlayer: AVAudioPlayerDelegate {
    // AVAudioPlayerDelegate calls back on an arbitrary thread; hop to the main actor to update the
    // published `isSpeaking` state safely.
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
