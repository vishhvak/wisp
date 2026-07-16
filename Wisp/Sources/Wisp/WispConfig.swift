import Foundation
import SwiftUI

// Runtime configuration for Wisp. Values are read from the environment when present so the
// app can be pointed at a local Cloudflare Worker during development, or a deployed Worker in
// production, WITHOUT recompiling. Anything not overridden falls back to a sensible default.
enum WispConfig {

    // The base URL of the Cloudflare Worker proxy that holds all real API keys. The app NEVER
    // calls Anthropic / ElevenLabs / AssemblyAI directly — it only ever talks to this Worker.
    // Override with the WISP_WORKER_URL environment variable (e.g. the deployed workers.dev URL).
    static var workerBaseURL: URL {
        if let workerURLString = ProcessInfo.processInfo.environment["WISP_WORKER_URL"],
           let parsedWorkerURL = URL(string: workerURLString) {
            return parsedWorkerURL
        }
        // Default assumes `npx wrangler dev` running locally on the standard Worker dev port.
        return URL(string: "http://127.0.0.1:8788")!
    }

    // Absolute path to the Parakeet speech-to-text Python sidecar script. The sidecar is launched
    // as a child Process; if it (or its Python deps / model) is missing, transcription falls back
    // to Apple's on-device Speech framework. Override with WISP_SIDECAR_PATH.
    static var parakeetSidecarScriptPath: String {
        if let sidecarPathOverride = ProcessInfo.processInfo.environment["WISP_SIDECAR_PATH"] {
            return sidecarPathOverride
        }

        // Candidates, most specific first. CWD-relative covers `swift run` from Wisp/ or the repo
        // root; executable-relative covers dist/Wisp.app (whose CWD when launched via `open` is /).
        let executableDirectory = (Bundle.main.executablePath as NSString?)?.deletingLastPathComponent ?? ""
        let candidateSidecarPaths = [
            "../voice-sidecar/parakeet_stt.py",
            "voice-sidecar/parakeet_stt.py",
            "\(executableDirectory)/../../../../voice-sidecar/parakeet_stt.py",  // dist/Wisp.app → repo root
        ]
        for candidatePath in candidateSidecarPaths where FileManager.default.fileExists(atPath: candidatePath) {
            return candidatePath
        }
        return candidateSidecarPaths[0]
    }

    // The Python interpreter used to run the sidecar. Prefers the sidecar's own virtualenv
    // (voice-sidecar/.venv — where `pip install -r requirements.txt` puts parakeet-mlx) and falls
    // back to `python3` from PATH. WHY: the system python almost never has parakeet-mlx; a
    // dedicated venv keeps the model stack isolated and detectable.
    static var sidecarPythonExecutablePath: String {
        let sidecarDirectory = (parakeetSidecarScriptPath as NSString).deletingLastPathComponent
        let venvPythonPath = "\(sidecarDirectory)/.venv/bin/python3"
        if FileManager.default.isExecutableFile(atPath: venvPythonPath) {
            return venvPythonPath
        }
        return "python3"
    }

    // The Claude model the app requests through the Worker's /chat route. Fable 5 is the default
    // per the design spec (Opus reserved for the heavier draw/point tutor path).
    static let defaultClaudeModel = "claude-fable-5"

    // The ChatGPT model used by the direct OAuth transport (ChatGPTCodexClient) — the default LLM.
    // Luna at low reasoning keeps voice replies snappy; override with WISP_CHAT_MODEL /
    // WISP_CHAT_EFFORT without recompiling.
    static var chatModel: String {
        ProcessInfo.processInfo.environment["WISP_CHAT_MODEL"] ?? "gpt-5.6-luna"
    }
    static var chatReasoningEffort: String {
        ProcessInfo.processInfo.environment["WISP_CHAT_EFFORT"] ?? "low"
    }

    // The user's preferred color for the cursor-trailing glyph. The design spec notes the glyph
    // color is user-configurable (red / blue / yellow / green presets), with blue as the default.
    static var cursorGlyphColor: Color {
        switch ProcessInfo.processInfo.environment["WISP_CURSOR_COLOR"]?.lowercased() {
        case "red":
            return DS.Colors.teachRed
        case "yellow":
            return DS.Colors.amber
        case "green":
            return DS.Colors.buildGreen
        case "blue":
            return DS.Colors.listeningBlue
        default:
            return DS.Colors.listeningBlue
        }
    }
}
