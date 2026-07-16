# Clicky Rebuild — Build Notes

Clean-room SwiftPM rebuild of the Clicky menu-bar companion, built from the authoritative specs in
`research/DESIGN.md` and the video-analysis reports. No proprietary source was opened. Builds with
`swift build` only (never `xcodebuild`, which would invalidate TCC permissions).

## File tree

```
clicky-rebuild/
├── Clicky/
│   ├── Package.swift                         # macOS 14, executable "Clicky", NO external deps
│   ├── README.md                             # build/run + permissions
│   └── Sources/Clicky/
│       ├── ClickyApp.swift                   # @main App, MenuBarExtra, .accessory policy (no dock)
│       ├── AppCoordinator.swift              # @MainActor state machine + VoiceEngine + TaskCardStore
│       ├── DesignSystem.swift                # DS tokens (hex colors, radii, spacing) + Color(hex:)
│       ├── ClickyConfig.swift                # workerBaseURL / sidecar path / cursor color (env-driven)
│       ├── PointerCursorOnHover.swift        # shared .pointerCursorOnHover() modifier
│       ├── Overlay/
│       │   ├── OverlayController.swift        # transparent click-through NSPanel + OverlayRootView + cursor tracking
│       │   ├── CursorGlyphView.swift          # 3-state cursor glyph (waveform / spinner / triangle)
│       │   ├── TeachingAnnotation.swift       # rect/arrow/dot/chip model
│       │   └── TeachingOverlayView.swift      # accumulating red teaching ink, trim draw-on
│       ├── Cards/
│       │   ├── AgentTask.swift                # task model (running/done/error, resultSentence, suggestedNext)
│       │   ├── TaskCardView.swift             # charcoal card: small-caps title, status pill, suggested/follow-up
│       │   ├── TaskCardStackView.swift        # top-right newest-on-top stack
│       │   └── CompletionToastView.swift      # blue toast w/ tail, auto-dismiss ~4s
│       ├── Voice/
│       │   ├── HotkeyMonitor.swift            # listen-only CGEvent tap + NSEvent fallback; 4 gestures
│       │   ├── TranscriptionProvider.swift    # protocol + ParakeetSidecarProvider + AppleSpeechProvider
│       │   └── TTSPlayer.swift                # POST /tts, AVAudioPlayer, isSpeaking
│       ├── Chat/
│       │   └── ClaudeClient.swift             # POST /chat, SSE parse, [POINT]/[DRAW] tag extraction
│       └── Screen/
│           └── ScreenCapture.swift            # ScreenCaptureKit per-display capture + coord mapping
└── voice-sidecar/
    ├── parakeet_stt.py                        # Parakeet TDT 0.6b v3 STT; JSON lines; clean ImportError exit
    └── requirements.txt                       # parakeet-mlx, sounddevice, numpy
```

## Build result

`swift build` from `clicky-rebuild/Clicky` exits 0. Final clean (`rm -rf .build`) build output:

```
Building for debugging...
[0/6] Write Clicky-entitlement.plist
[1/6] Write sources
[2/6] Write swift-version--1AB21518FC5DEDBE.txt
[4/24] Compiling Clicky OverlayController.swift
...
[21/24] Emitting module Clicky
[22/25] Compiling Clicky TranscriptionProvider.swift
[23/25] Linking Clicky
[24/25] Applying Clicky
Build complete! (49.78s)
```

No errors, no warnings. (Swift 6.3.1 / macOS 26.3, targeting macOS 14+.)

The Python sidecar was syntax-checked and run: with deps absent it prints
`{"error": "parakeet-mlx not installed"}` and exits 1, as designed.

## What's real vs. stubbed

**Real / functional (compiles and runs the actual logic):**
- Menu-bar-only app via `MenuBarExtra` + `.accessory` policy; state-reactive icon + text label.
- Full 5-state machine (`idle/listening/processing/responding/agentRunning`) with the display-label
  map (`idle→"Always on"`, etc.).
- Design system: all hex tokens from the spec, `Color(hex:)`, radii, spacing.
- Transparent, non-activating, all-Spaces, click-through overlay `NSPanel` hosting SwiftUI, with
  global+local mouse monitors that feed the cursor-glyph position (real coordinate conversion from
  AppKit bottom-left global space to the overlay's top-left space).
- 3-state cursor glyph with real animations (waveform oscillation, spinning trimmed arc, triangle),
  reduced-motion aware.
- Teaching overlay: real rect/arrow/dot/chip rendering with trim-based draw-on, accumulating chips.
- Task card + stack + completion toast: full layout, status pills, wrapping "suggested next" pills
  (custom `Layout`), follow-up Text/Voice pills, pointer-cursor-on-hover everywhere, auto-dismiss toast.
- HotkeyMonitor: real listen-only `CGEvent` tap with the C-callback trampoline, NSEvent fallback,
  and gesture recognition for all four gestures (hold ctrl+opt, hold fn+ctrl, double/triple-tap Ctrl).
- TranscriptionProvider: ParakeetSidecarProvider launches the real Process, parses stdout JSON lines
  into an AsyncStream, and auto-falls-back to a real SFSpeechRecognizer+AVAudioEngine provider.
- ClaudeClient: real POST to `/chat` with an Anthropic Messages body (model `claude-fable-5`, stream
  true, base64 image blocks), real SSE line parsing of `content_block_delta`/`text_delta`, and a
  streaming `[POINT:...]`/`[DRAW:...]` tag extractor (buffers tags split across deltas).
- TTSPlayer: real POST to `/tts` + `AVAudioPlayer` playback with `isSpeaking`.
- ScreenCapture: real `SCScreenshotManager` per-display capture + PNG encode + coord mapping.
- Parakeet sidecar: real mic capture, VAD-lite silence chunking, model transcription, JSON-line output.

**Stubbed / scoped down (deliberately, for a compiling scaffold — not wired to real backends):**
- **No agent runtime.** `AgentTask`s are data models; there is no process that actually executes
  background agent work (desktop cleanup, Reminders, CSV research, "build a Mac app"). Card action
  handlers (`handleSuggestedNextAction`, follow-ups) re-enter the voice pipeline as a placeholder.
- **Cards/toast are display-only.** The overlay panel is click-through (`ignoresMouseEvents = true`
  per spec), so the card buttons render and show hover cursors but cannot receive clicks through the
  overlay. A real interactive card surface needs a separate non-click-through panel or per-region
  hit-testing carved out of the overlay — noted as the next step.
- **No `MenuBarExtra`-triggered listening yet**: listening starts from hotkey gestures; the always-on
  keyword-trigger ("Hey Clicky") path is not implemented (would need continuous STT + wake-word).
- **No memory store, Skills Library, proactive nudges, or draw-to-direct (spatial) gestures** — these
  are Tier 2/3 surfaces in the design and are out of scope for this scaffold.
- **The Worker isn't required to compile/run the app**, but `/chat` and `/tts` calls will fail until
  a Worker is running at `CLICKY_WORKER_URL` (default `http://127.0.0.1:8788`). Failures are handled
  gracefully (no crash; empty/no response).
- Teaching-ink coordinates are consumed directly in overlay space; the display-index routing field
  is parsed and stored but the overlay currently paints all ink on the main-screen panel.

## Runtime steps needing user permissions

Running the app (`swift run Clicky`) requires the user to grant, against a **stable binary path**:
1. **Accessibility** — for the global hotkey CGEvent tap (else it silently falls back to NSEvent).
2. **Screen Recording** — for ScreenCaptureKit screenshots (else requests go text-only).
3. **Microphone** (+ **Speech Recognition** if the Apple fallback is used) — for voice capture.

For local end-to-end voice, also run `pip install -r voice-sidecar/requirements.txt` (Apple Silicon)
and start a Cloudflare Worker exposing `/chat` and `/tts`, then set `CLICKY_WORKER_URL`.
```
