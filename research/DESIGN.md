# Clicky Rebuild — Design & Architecture (synthesis v1)

Status: seeded from verified findings — tweet arc, hero demo (2048), tutor demo (2066983), voice/infra. Sections marked ⏳ await the voice-control / spatial / dictation video reports + full app-bundle RE.

## Product thesis (from the demoed experience, not the old repo)
"An AI buddy that lives on your Mac. It sits right next to your cursor and sees everything you see. Ask out loud and it walks you through what you're doing — or say 'clicky agent' and it spins up a background agent to build, research, or do whatever."

Two interaction modes, one companion:
1. **Ask/guide mode** — talk, it answers with voice + draws/points on your screen to teach (the tutor).
2. **Agent mode** — "clicky agent, …" spawns a background agent that does real work (files, native apps, research, building Mac apps), surfaced as **task cards**.

The current repo (big NSPanel HUD + arc-flying blue cursor pointing at elements) is the **old** language. The relaunch language is **minimal + cursor-adjacent + card-based**. Rebuild to the relaunch language.

## Design language (verified from hero + tutor frames)
- **Menu-bar only** (LSUIElement). Brand icon purple/violet `#7C5CFC`–`#8A5CF6`; highlights/fills on state change. No dock icon, no main window.
- **Cursor-adjacent micro-glyphs** (NOT a big HUD):
  - Listening: tiny blue vertical-bar **waveform glyph** (`#3B82F6`) riding to the right of the OS cursor.
  - Spawn/activity: small blue (occasionally amber) **triangle/play glyph** near the cursor.
- **Agent status-dot stack**: small filled circles stacked under the menu-bar icon, one per concurrent agent, color = state (green done, blue running, amber queued, red error).
- **Task card** (the workhorse) — top-right, dark charcoal `#17171A`, generous radius, soft shadow:
  - Header: **bold small-caps task title** + right status **pill** (green Running/Done).
  - Body: one plain-English **result sentence**.
  - **"Suggested next"**: 2 dark capsule action pills.
  - **"Follow up"**: **Text** (A icon) + **Voice** (mic icon) pills — the card is also the continue-this-thread surface.
- **Completion toast**: ephemeral iMessage-blue `#2F6FED` rounded bubble with a tail pointing to the menu icon; same copy as the card body, fires first.
- **On-screen teaching overlay** (tutor): single saturated **red `#FF3B30`**; primitives = stroked outlines/arrows (4–6px, no fill) + a pixel-precise filled dot + **white-on-red chip labels that accumulate into a persistent legend**. Mechanism: screenshot → model returns coordinates → transparent full-screen overlay paints at absolute coords. Hard cut-in synced to narration (no draw-on animation observed, but we may add a subtle one as an elegant improvement).
- Typography: SF (system) for all native surfaces & cards; digital/monospace numerals where a "readout" is wanted.
- Color tokens (seed): brand `#7C5CFC`, running/listening blue `#3B82F6`, toast blue `#2F6FED`, done green `#34C759`, teach red `#FF3B30`, card bg `#17171A`, amber accent `#E0A23D`, digital green `#3ED598`.

## Voice pipeline (verified stack — `~/Repos/projects/claude-voice`)
- **STT: Parakeet TDT 0.6B v3** local (parakeet-mlx, Apple Silicon) + **Silero VAD** + **Pipecat Smart Turn V3** for end-of-turn. In a Swift app: run as a **Python sidecar** (XPC/stdio) that streams partial+final transcripts. Fallbacks: Apple `SFSpeechRecognizer`, OpenAI whisper.
- **TTS: Inworld** (`inworld-tts-2`, Kurzgesagt voice `default-gv-cgitsgv4b40lhxxqpza__kutz`) via REST; fallback ElevenLabs (`aJxmRyDvcRx8qVUaBKM6`) → OpenAI TTS → `AVSpeechSynthesizer`.
- **Trigger**: hold-to-talk (ctrl+opt, listen-only CGEvent tap) AND/OR "clicky / clicky agent" keyword. Hero demo shows keyword; repo shows PTT — support both.
- ~450ms STT latency is a product promise (screen-aware dictation) — Parakeet local is how they hit it.

## Model / agent runtime
- Default model **Claude Fable 5**; Opus for the draw/point tutor path.
- Keys NEVER in the app — all via a **Cloudflare Worker proxy** (shipped app uses `clicker-proxy-v2.farza-0cb.workers.dev`; we build our own). Routes: `/chat` (Claude vision+SSE), `/tts`, plus STT token if a streaming cloud STT is used.
- Agent mode: the shipped app embeds a Codex runtime + Composio + Cua Computer Use (⏳ confirm from bundle RE). For the clean rebuild, scope agent execution to a **local sandboxed runner** invoked by the app; integrations via native scripting (AppleScript/EventKit for Reminders/Calendar/Notes) first, external via a pluggable tool layer.

## Rebuild scope (ambitious but honest)
Tier 1 (core, buildable + testable now): menu-bar app, PTT + keyword trigger, Parakeet STT sidecar with fallback, screen capture, Claude Fable 5 via Worker proxy, streamed voice response (Inworld TTS), cursor-adjacent listening glyph, **task-card system**, completion toast, agent status-dot stack.
Tier 2 (the magic): on-screen teaching overlay (red draw/point + accumulating chips), screen-aware dictation (write into focused app), native app actions (Reminders/Calendar via EventKit).
Tier 3 (stretch): spatial context (user draws to direct), multi-agent concurrency, "build a Mac app" agent, research→CSV. ⏳ refine from remaining videos.

## Architecture (clean, minimal, modular — SwiftUI + AppKit bridges)
- `ClickyApp` (menu-bar entry, LSUIElement) → `AppCoordinator` (state machine: idle/listening/thinking/speaking/agent-running).
- `VoiceEngine`: PTT/keyword monitor + Parakeet sidecar client + TTS player, provider-pluggable.
- `ScreenContext`: ScreenCaptureKit multi-monitor capture + coordinate mapping.
- `ClaudeClient`: Worker-proxied SSE chat; `[DRAW:...]`/`[POINT:...]` tag parsing.
- `OverlayWindow`: full-screen transparent NSPanel — listening glyph, teaching draw layer, dictation pill.
- `TaskCardManager`: top-right card stack, status pills, follow-up routing; `AgentBadgeStack` under menu icon.
- `AgentRuntime`: spawns/tracks background agent runs; pluggable tools (EventKit, shell-sandbox, web research).
- `DesignSystem`: tokens above.
- `worker/`: Cloudflare Worker proxy (keys as secrets).
Preserve as *concepts* (not code): shared single URLSession for streaming, short-lived proxy tokens, multi-display coordinate conversion, coordinate-tag protocol.

## Refinements from voice-control (2060865) + dictation (2077130) videos — VERIFIED

### Cursor-trailing glyph — 3 states (this is THE primary live feedback)
~12px blue (`#4C7CF5`) element that tracks the OS cursor (confirmed drifting with the mouse):
- **listening**: animated waveform bars
- **thinking/processing**: spinning arc
- **speaking/responding**: solid right-pointing triangle
No large HUD panel in real use. (The old repo's full-screen waveform panel is not the shipped language.)

### Menu-bar state label (text, not just icon)
The menu bar shows a literal text status that swaps with state: "Always on" / "Listening" / "Dictating" / "Thinking" / "Speaking". Leaked Xcode debug console confirms internal state names **`idle / listening / processing / responding`** (same as old repo — keep this state machine). Agent actions are instant (no simulated-click theater); background agents can produce zero screen change (invisible delegation), with a "show the work" beat (opening Reminders) for trust.

### Dictation (distinct from agent voice)
- **Trigger: hold `fn + control`** (push-to-talk). (Agent/ask voice uses its own trigger — ctrl+opt per old repo and/or "clicky" keyword.)
- **Two modes**, shown by the menu-bar pill:
  - **Raw dictation** ("Dictating" pill): literal STT streams live into the focused text field, phrase by phrase, ~450ms feel (Parakeet local). Apple Notes example.
  - **Screen-aware compose** ("Listening" pill): speech is an *instruction*, not a transcript. Clicky reads the focused app's screen, composes an app-appropriate block, and inserts it as one paste ("I've pasted…"). Reformats per surface: Gmail → signed email in the user's voice (uses memory); Claude Code terminal → structured numbered prompt; Slides → on-brand marketing line (uses an activated skill). Native insert (Gmail "Draft saved" confirms), not image paste.
- Menu-bar pill: small black rounded pill, white text. A recording dot may appear in the host app's own toolbar (Gmail).

### Skills Library (new surface)
- A **Skills Library** panel (dark charcoal `#1c1c1e`, rounded, macOS traffic lights): left sidebar of skill cards ("Write like Farza", "Y Combinator", "YouTube Analysis Aid", …), right detail pane (description, tags, contents, **"Activate Skill"** button).
- The menu-bar dropdown panel ("Add skills / Skills give HeyClicky superpowers", "+", Active integrations, "Dock" button) is the companion panel (maps to old `CompanionPanelView`). Skills augment both agent mode and screen-aware dictation.

### Memory
- Clicky has per-user **memory** ("in my voice, based on HeyClicky's memories of me") feeding compose. Rebuild: a lightweight local memory store (facts/preferences) injected into compose prompts. Supabase optional for sync.

### Design decision — keep it honest
The demos use zoomed/cropped insets, so some chrome is off-frame. Where two demos differ (tab-title state in the tutor vs menu-bar-label state elsewhere), treat the **menu-bar text label + cursor glyph** as canonical; the tutor's tab-title was likely a web/other-surface variant.

### Spatial context / draw-to-direct (2074973) — VERIFIED
The user draws on their OWN screen to give the AI spatial context:
- **Activation**: hold the PTT hotkey and drag on the trackpad/mouse — you draw directly on the live app content (no dimmed overlay, no crosshair).
- **Stroke**: thick (~6–8px) translucent freehand **marker** arcs, rounded caps — deliberately hand-drawn, not vector. **Mode-coded color = intent**:
  - **coral/salmon-red `#E8776B`** → conversational "tell me about this / what is this?"
  - **mint-green `#3ECC8E`** → agent "build/change this".
- A small pulsing **mini-waveform badge in the stroke color rides the stroke's tip** while drawing+recording (the live feedback).
- **Release** ends the gesture; the stroke **fades** (not permanent ink); a small triangle marker persists briefly at the referenced point. Agent mode: badge → green spinner → target live-reloads → **green confirmation toast pill anchored to the changed element** ("The Explore Programs button is back in the hero…").
- Conversational response references the mark ("From what you circled, that muscle is the deltoid") via TTS + captions. The macOS **menu bar swaps a menu item to "Speaking"** (audio-bar icon) during TTS — state at OS-chrome level.

This unifies the annotation language:
- **User-drawn** marks = mode-coded (red=ask, green=build), thick translucent marker, fades after capture, waveform badge on tip.
- **AI-drawn** teaching marks (tutor) = single red `#FF3B30`, crisp outlines/dots + accumulating white-on-red chips, persist through the lesson.

## Ambient/proactive + agents surfaces (batch video sweep) — VERIFIED from video 2055774
- **Proactive nudge**: a dismissible toast **docked at the top of the frontmost window** (not in Clicky's own panel). Trigger: passive recognition of the app/site in use, no voice command. Anatomy: header ("Connect Notion to Clicky?"), subtext ("Use Clicky to:"), three concrete suggestion chips ("Create a meeting notes page" / "Attach this screenshot to a page" / "Update a task row"), buttons **✕ No · 🕐 Not now · 🔗 Yes** (Yes highlighted). Rebuild note: this is the "ambient agent UX" flagship — Tier 3, but the toast component itself reuses the completion-toast styling.
- **Agents panel**: a task-list panel with **RUNNING / TODAY** sections, per-task progress bars, and "Open Agent" buttons — a fuller sibling of the task-card stack.
- **Settings/Home panel** includes a **cursor-color picker** (red / blue / yellow / green) — the cursor glyph color is user-configurable, blue is only the default.
- Additional observed state label: **"Reasoning"** (alongside Listening/Thinking/Speaking) — treat display labels as a presentation map over the 4-state machine, not new states.
- **Skills marketplace ("Power-Ups")** is real (teaser + narration corroborate the dictation video's Skills Library).
- Demoed agent outputs are real, not staged: an inbound bug-report email became a real Linear ticket (CLI-19) and a real Slack DM.

## Additional surfaces (batch 1 sweep — all 24 videos now covered) — VERIFIED
- **Invocation gestures** (full set): hold **ctrl+option** = push-to-talk · **double-tap Control** = text mode · **triple-tap Control** = always-on mode · hold **fn+control** = dictation.
- **Drag-files-in attach UI**: dragging files toward the top-of-screen zone expands the companion panel into a drop target ("Drop files here to attach…"), resolving into a chat input with per-file-type icon chips above an "ask HeyClicky…" text field. Multi-file, mixed types.
- **Companion panel** (clearest capture): shows "Hold ⌃control + ⌥option to talk", the cursor-color picker (4 presets: red/blue/yellow/green), and a "Dock" button.
- **Clicky Notes**: a categorized agent-memory wiki surface (the "memories of me" store behind screen-aware compose).
- Computer-use/agentic browsing built with partner **Cua** ("Kua" spoken) — corroborates the bundle's ClickyComputerUseRuntime.
- AI can draw beyond teaching: annotated route+callout on macOS Maps, dashed box on sheet music, progressive labeled squares in a Figma-like tool.

## Bundle deep-inventory conclusions (report-appbundle.md) — VERIFIED, closes all open questions
1. **Pointing protocol — adopt the richer vocabulary**: `[TARGET:x,y,r:label]`, `[HOVER:x,y,r:label]`, `[HIGHLIGHT]`, `[SHAPE:arrow]`, `[SHAPE:curve]` (legacy `[POINT]` kept for compat). Rule: TARGET/HOVER only when there is a single observable next action; HIGHLIGHT+POINT+SHAPE for manual steps ("say continue").
2. **Primary surface is a notch-anchored HUD** (`NotchAgentSurface`, collapsed/expanded, file-drag composer, auto-dismissing text responses) — the floating panel/cards are satellites. Rebuild: anchor the HUD at the camera notch with a top-center fallback on non-notch displays.
3. **Agent cursor motion contract**: bezier-glide triangle pointer, ring-ripple on landing, idle-hide ~1.5s.
4. **Only the 14 bundled skills are live**; the big integration .md catalog is vendored (hermes-agent) onboarding copy, NOT wired. Scope integration claims to: Composio MCP (Google Workspace etc.), Obsidian vault, Cua computer use, native EventKit.
5. **Shipped voice stack is cloud-heavy** — always-on OpenAI Realtime (barge-in + AEC caching), Deepgram dictation (`~450ms`), AssemblyAI PTT. Our **Parakeet-local STT is a deliberate divergence** (user-specified) that keeps the same UX contract (streaming partials, ~450ms feel).
6. Agent runtime = pinned Codex CLI 0.132.0 (gpt-5.6-sol) + standalone Computer-Use Mach-O MCP server with a snapshot-act-verify, never-steal-focus contract. Our rebuild scopes agent mode to a native tool layer (EventKit, sandboxed shell, web) — same UX (task cards, badges), simpler engine.
7. Memory = `<user_memory>` block injected into the system prompt (cross-session learnings) — matches our lightweight local memory plan.
8. Extras observed: PowerUp marketplace with creator attribution + hatching celebration; hard paywall before agent launches (Haiku generates launch-card labels); PostHog feature flags gate whole surfaces; remappable hotkeys; onboarding skip-shake gesture; sound palette mapped to UX moments (agent lifecycle, notch text panel, skill hatching).
