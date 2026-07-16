# Clicky

A macOS menu-bar companion (macOS 14+). Clicky lives entirely in the status bar — no dock icon, no
main window. Hold a hotkey and talk; it captures a screenshot of your screen, streams the request to
Claude through a Cloudflare Worker proxy, speaks the answer back, and can paint teaching ink (red
outlines / arrows / dots / labels) directly on your screen. Background agent work surfaces as
dark task cards in the top-right corner.

This is a clean-room SwiftPM rebuild of the relaunch design language: **minimal, cursor-adjacent,
card-based** — a ~12pt glyph that trails the OS cursor (waveform → spinner → triangle), a menu-bar
text status label, task cards, and a completion toast. No large HUD panel.

## Build & Run

Build with **`swift build` only** — do NOT use `xcodebuild`, which invalidates the app's TCC
(Transparency, Consent & Control) permission grants and forces you to re-authorize Screen Recording,
Accessibility, and Microphone on every rebuild.

```bash
cd Clicky
swift build            # compiles the executable
swift run Clicky       # launches the menu-bar app
```

The app has no external Swift dependencies — everything (SwiftUI, AppKit, ScreenCaptureKit,
AVFoundation, Speech) ships with macOS.

## Configuration (environment variables)

| Variable | Default | Purpose |
|----------|---------|---------|
| `CLICKY_WORKER_URL` | `http://127.0.0.1:8788` | Base URL of the Cloudflare Worker proxy (`/chat`, `/tts`). |
| `CLICKY_SIDECAR_PATH` | `../voice-sidecar/parakeet_stt.py` | Path to the Parakeet STT Python sidecar. |
| `CLICKY_CURSOR_COLOR` | `blue` | Cursor glyph color: `red` / `blue` / `yellow` / `green`. |

## Permissions

Because Clicky observes global input, captures the screen, and records audio, macOS requires the
user to grant three permissions. **Grant them against a stable app path** — if the built binary
moves (e.g. a new `.build` location), macOS treats it as a new app and the grants reset.

- **Accessibility** — required for the global hotkey monitor (a listen-only `CGEvent` tap detects
  hold ctrl+option, hold fn+control, and double/triple-tap Control). Without it, the app falls back
  to a less-reliable `NSEvent` global monitor.
- **Screen Recording** — required for `ScreenCaptureKit` to screenshot each display so Claude can
  see what you're looking at. Without it, requests are sent text-only (no screenshot).
- **Microphone** (and **Speech Recognition** if the Apple Speech fallback is used) — required for
  voice capture.

## Voice sidecar (local STT)

Speech-to-text prefers the local **Parakeet TDT 0.6B v3** model via a Python sidecar
(`../voice-sidecar/parakeet_stt.py`), which streams partial + final transcripts as JSON lines. If
the sidecar can't launch (missing Python, `parakeet-mlx`, or the model), the app automatically falls
back to Apple's on-device `SFSpeechRecognizer`.

```bash
cd ../voice-sidecar
python3 -m pip install -r requirements.txt   # Apple Silicon required for parakeet-mlx
```

## Cloudflare Worker

All real API keys live on the Worker, never in the app. The app only ever calls the Worker's
`/chat` (Claude vision + SSE) and `/tts` (ElevenLabs) routes. See the sibling `worker/` directory.
