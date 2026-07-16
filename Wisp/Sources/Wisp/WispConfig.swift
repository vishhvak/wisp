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
        // Default: the sidecar shipped alongside this package at ../voice-sidecar/parakeet_stt.py,
        // resolved relative to the current working directory the app was launched from.
        return "../voice-sidecar/parakeet_stt.py"
    }

    // The Claude model the app requests through the Worker's /chat route. Fable 5 is the default
    // per the design spec (Opus reserved for the heavier draw/point tutor path).
    static let defaultClaudeModel = "claude-fable-5"

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
