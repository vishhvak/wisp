# Wisp Rebuild — Build Notes

Clean-room SwiftPM rebuild of the Wisp menu-bar companion, built from the authoritative specs in
`research/DESIGN.md`, the video-analysis reports, and `research/report-appbundle.md`. No proprietary
source was opened. Builds with `swift build` only (never `xcodebuild`, which would invalidate TCC
permissions). Repo now lives at `/Users/vish/Repos/wisp`.

## Round 2 changes (from app-bundle RE)

1. **Clickable task cards.** The overlay is now TWO panels owned by one `OverlayController`: a
   full-screen click-through panel (`ignoresMouseEvents = true`) for teaching ink + cursor glyph
   only (`TeachingOverlayRootView`), and a small top-right `.nonactivatingPanel` with
   `ignoresMouseEvents = false` for the cards + toast (`CardsPanelRootView`). The cards panel is
   sized to content via an `NSHostingController` with `sizingOptions = [.preferredContentSize]`,
   KVO-observed to resize + re-anchor top-right, so only the card area intercepts clicks and focus
   is never stolen. Card buttons now actually receive clicks.

2. **Richer pointing vocabulary.** `TeachingAnnotationShape` gained `curve`, `target`, `hover`
   (rect/arrow/dot/chip retained). `ClaudeClient` now parses `[TARGET:x,y,r:label]`,
   `[HOVER:x,y,r:label]`, `[HIGHLIGHT:x,y,w,h:label]`, `[SHAPE:arrow:...]`, `[SHAPE:curve:...]` plus
   legacy `[POINT]`/`[DRAW]`. Rendering: target = ring + center dot + chip; hover = dashed ring +
   chip; highlight = stroked rect + chip; arrow/curve = stroked path with arrowhead. All teachRed,
   accumulating chips, trim-based draw-on, reduced-motion aware.

3. **Notch-anchored HUD.** New `Overlay/NotchHUDController.swift` + `NotchHUDView.swift`: a
   non-activating, click-through panel anchored top-center of the notched display (detected via
   `NSScreen.safeAreaInsets.top > 0`; top-center fallback otherwise). Collapsed = slim charcoal
   `#17161F` pill (rounded-bottom via `UnevenRoundedRectangle`) with state label + tiny state glyph;
   expanded = live partial transcript (listening) or last response line (responding), auto-dismissing
   after `notchTextResponseAutoDismissDurationSeconds` (4s). Driven by new `AppCoordinator`
   `notchExpandedText` / `latestResponseLine` state.

Round-2 build: `swift build` exits 0 from scratch (0 warnings). Note: `.build` had to be wiped once
because the module cache carried the old `wisp-rebuild` path.

## File tree

```
wisp-rebuild/
├── Wisp/
│   ├── Package.swift                         # macOS 14, executable "Wisp", NO external deps
│   ├── README.md                             # build/run + permissions
│   └── Sources/Wisp/
│       ├── WispApp.swift                   # @main App, MenuBarExtra, .accessory policy (no dock)
│       ├── AppCoordinator.swift              # @MainActor state machine + VoiceEngine + TaskCardStore
│       ├── DesignSystem.swift                # DS tokens (hex colors, radii, spacing) + Color(hex:)
│       ├── WispConfig.swift                # workerBaseURL / sidecar path / cursor color (env-driven)
│       ├── PointerCursorOnHover.swift        # shared .pointerCursorOnHover() modifier
│       ├── Overlay/
│       │   ├── OverlayController.swift        # TWO panels: click-through teaching overlay + clickable top-right cards panel
│       │   ├── CursorGlyphView.swift          # 3-state cursor glyph (waveform / spinner / triangle)
│       │   ├── TeachingAnnotation.swift       # rect/arrow/curve/dot/chip/target/hover model
│       │   ├── TeachingOverlayView.swift      # accumulating red ink (target/hover/highlight/arrow/curve), trim draw-on
│       │   ├── NotchHUDController.swift        # notch-anchored non-activating panel (safeAreaInsets.top detection)
│       │   └── NotchHUDView.swift              # collapsed pill / expanded transcript+response, rounded-bottom charcoal
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

`swift build` from `wisp-rebuild/Wisp` exits 0. Final clean (`rm -rf .build`) build output:

```
Building for debugging...
[0/6] Write Wisp-entitlement.plist
[1/6] Write sources
[2/6] Write swift-version--1AB21518FC5DEDBE.txt
[4/24] Compiling Wisp OverlayController.swift
...
[21/24] Emitting module Wisp
[22/25] Compiling Wisp TranscriptionProvider.swift
[23/25] Linking Wisp
[24/25] Applying Wisp
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
- Teaching overlay: real rendering of target (ring+dot+chip), hover (dashed ring+chip), highlight
  (rect+chip), arrow, curved arrow, dot, and chip, with trim-based draw-on and accumulating chips.
- Task card + stack + completion toast: full layout, status pills, wrapping "suggested next" pills
  (custom `Layout`), follow-up Text/Voice pills, pointer-cursor-on-hover everywhere, auto-dismiss
  toast — now hosted in a dedicated clickable (`ignoresMouseEvents = false`) content-sized top-right
  panel, so the buttons actually receive clicks while the user's app keeps focus.
- Notch HUD: real notched-display detection (`NSScreen.safeAreaInsets.top`), collapsed pill +
  expanded transcript/response, 4s auto-dismiss, rounded-bottom charcoal, reduced-motion aware.
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
- **Card actions don't do real work.** The card buttons now receive clicks, but their handlers
  (`handleSuggestedNextAction`, follow-ups) just re-enter the voice pipeline as a placeholder — there
  is no agent runtime behind them (see above).
- **No `MenuBarExtra`-triggered listening yet**: listening starts from hotkey gestures; the always-on
  keyword-trigger ("Hey Wisp") path is not implemented (would need continuous STT + wake-word).
- **No memory store, Skills Library, proactive nudges, or draw-to-direct (spatial) gestures** — these
  are Tier 2/3 surfaces in the design and are out of scope for this scaffold.
- **The Worker isn't required to compile/run the app**, but `/chat` and `/tts` calls will fail until
  a Worker is running at `WISP_WORKER_URL` (default `http://127.0.0.1:8788`). Failures are handled
  gracefully (no crash; empty/no response).
- Teaching-ink coordinates are consumed directly in overlay space; the display-index routing field
  is parsed and stored (now for TARGET/HOVER/HIGHLIGHT/SHAPE too) but the overlay currently paints
  all ink on the main-screen panel.
- The pointing-vocabulary "observable next action vs manual step" rule (TARGET/HOVER for a single
  next action; HIGHLIGHT+POINT+SHAPE for manual multi-step, then "say continue") is a prompt-side
  convention — the parser/renderer support all tags, but no system prompt enforcing that rule ships yet.
- Notch HUD auto-dismiss uses a single last-response line; there's no notch file-drag composer or
  `NotchAgentSurface` gallery from the RE (Tier 2/3).

## Runtime steps needing user permissions

Running the app (`swift run Wisp`) requires the user to grant, against a **stable binary path**:
1. **Accessibility** — for the global hotkey CGEvent tap (else it silently falls back to NSEvent).
2. **Screen Recording** — for ScreenCaptureKit screenshots (else requests go text-only).
3. **Microphone** (+ **Speech Recognition** if the Apple fallback is used) — for voice capture.

For local end-to-end voice, also run `pip install -r voice-sidecar/requirements.txt` (Apple Silicon)
and start a Cloudflare Worker exposing `/chat` and `/tts`, then set `WISP_WORKER_URL`.
```
