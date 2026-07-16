# HeyClicky.app Reverse-Engineering Inventory (read-only, observable behavior)

Target: `/Applications/HeyClicky.app` — `com.humansongs.clicky` v1.0.38 (build 47), git `main @ 61a9a3d2` (ClickyBuildInfo.plist).

**Headline**: a leaked dev path in binary strings (`/Users/nilesh/Documents/Projects/HeyClicky/clicky-closed/leanring-buddy/DictationDeepgramTranscriber.swift`) confirms the shipped app is built from the same `leanring-buddy` Xcode project as the local repo — the local repo is an earlier snapshot; the shipped build (`clicky-closed`) is a materially advanced superset: OpenAI Realtime always-on voice, a notch-anchored HUD, Codex agent runtime, Computer Use, Composio, a hard paywall, PostHog feature flags, and a proactive-suggestions engine.

## 1. Entitlements
Unsandboxed (`app-sandbox=false`); `device.audio-input=true`; `device.camera=true` (likely vestigial); `network.client=true`; mach-lookup exception for `com.apple.screencapturekit.picker`.

## 2. Bundled skills (`Resources/ClickyBundledSkills/*` — the LIVE routing surface, 14 skills)
Meta-router `clicky-*` skills own domains and delegate to shared implementation skills (`pdf`, `doc`, `spreadsheet`, `frontend-design`, `cua-driver`) and connectors (Composio MCP, filesystem, Vercel CLI). Pattern: identify target → do work → verify (render/read-back) → report exact path; explicit "Do Not Use When" hand-offs.
- **clicky-artifacts** — open/reveal/export produced files.
- **clicky-build-preview** — build/launch/iterate sites/apps; prefers single self-contained HTML; detached server launches + curl polling.
- **clicky-creative-studio** — creative router; reports missing image/video/slide provider capability instead of faking it (not shipped in this build).
- **clicky-dev-setup-doctor** — Node/npm/Python/Supabase/Cloudflare/Codex/Claude-Code/MCP/localhost diagnosis; diagnose-before-fix.
- **clicky-email-assistant** — draft/rewrite/triage; hard approval gate before send/delete.
- **clicky-google-workspace** — Composio: 5 separate toolkits (gmail, googlesheets, googlecalendar, googledrive, googledocs); exact-schema write recipes; mandatory read-back verification.
- **clicky-repo-operator** — local git; Composio GitHub or gh for PRs/issues/CI.
- **clicky-research-report** — research → MD/PDF/DOCX/CSV; structured fetch before GUI automation.
- **cua-driver** — Computer Use contract (§4).
- **doc / pdf / spreadsheet** — python-docx / reportlab+pypdf / openpyxl+pandas, each with visual verification loops (soffice/pdftoppm renders). Spreadsheet skill encodes IB-style finance-model color conventions.
- **frontend-design** — anti-generic-AI-aesthetic rules; transform/opacity-only animation; 100–500ms bands; reduced-motion.
- **obsidian** — filesystem-only via `OBSIDIAN_VAULT_PATH` (not Composio).
- **vercel-deploy** — `vercel deploy -y` preview; unauthenticated fallback script; returns previewUrl/claimUrl.

## 3. Integration docs (`Resources/*.md`) — INERT, vendored
Per `ATTRIBUTION.md`: all vendored unmodified from **NousResearch/hermes-agent** (MIT); they power only the pre-sign-in "What should Clicky be good at?" onboarding picker (toggles write an ID to UserDefaults). "Backend wiring … intentionally not included yet." So airtable/notion/linear/github-*/imessage/spotify/maps/polymarket/blender/etc. are catalog copy, NOT live integrations. The live external surface is Composio MCP (Settings→Integrations), Obsidian (local vault), and Cua Computer Use.

## 4. Codex runtime & Computer Use
- `Resources/CodexRuntime/.clicky-codex-version` = `0.132.0:34f2fc2b…` (pinned Codex CLI). `bin/codex` = 648-byte shell dispatcher → `vendor/{aarch64,x86_64}-apple-darwin/codex/codex` (~194MB Mach-O each) + vendored ripgrep. Agent model: **gpt-5.6-sol**.
- `Helpers/ClickyComputerUseRuntime` — universal Mach-O binary, a standalone native Accessibility/Computer-Use driver spawned as local MCP server `computer-use` (TCC attributes to HeyClicky).
- cua-driver contract: **snapshot-act-verify mandatory** (`get_window_state` before AND after every action; element indexes stale across snapshots); **no-foreground contract** (never change the user's frontmost app; `launch_app({bundle_id, urls})` is the safe primitive with FocusRestoreGuard); AX element addressing (coordinate-only clicks blocked); `capture_mode: som | ax | vision`; menu-bar nav only when target frontmost; web via `page` tool (Apple Events → Chrome/Safari; SIGUSR1→CDP for Electron). Agent cursor overlay: **Bezier-glide triangle pointer, ring-ripple on landing, idle-hide ~1.5s**.

## 5. Sounds → UX moments
agent-launch/done/close (agent lifecycle) · clicky-text-open/close/send/receive (notch text panel) · clicky-question/surprised (reactions) · connection-question (pairing) · enter (confirm tick) · hatching + skill-up/skill-down (PowerUp reveal/expand — matches `_hatchPowerUpWiggleTrigger`) · eshop (marketplace browse chime) · ff.mp3 (5.7-min music bed for onboarding/paywall videos) · realtime-voice-preview-{alloy…verse} (OpenAI Realtime voice picker) · voice-preview-{bright…techy} (second friendlier-branded voice picker, likely ElevenLabs). Also `onboarding-intro-v2.mp4` (44MB), `paywall-intro-v2.mp4` (26MB).

## 6. Binary strings — key themes
- **Voice/state**: `activityListening/Speaking/Thinking`; legacy waveform/equalizer/pulsing-dot indicators; full `[Realtime] always-on` family — barge-in rescue, per-topology AEC verdict caching, `beginAlwaysOnListening` → an always-on OpenAI Realtime mode (`wss://api.openai.com/v1/realtime?model=`) distinct from PTT.
- **Hotkeys**: user-remappable (`ClickyHotkeyConfiguration/Recorder`): `dictationHold.v1`, `handsFreeDictation.v1`, `textTrigger.v1`, `voiceHold.v1`; CGEvent tap for global PTT.
- **Notch UI**: `NotchAgentSurface`, `NotchActivitySurface`, `NotchRootView`, `notch_collapsed/expanded`, notch file-drag composer, `_notchTextResponseAutoDismissDurationSeconds`, gallery images — the notch HUD is the primary surface.
- **Proactive**: `ProactiveAgentsClient` + server `/proactive-agents`; suggestion cards with daily slots, corner nudges (`onTopRightScreenCornerNudge`), resolution reporting (approve/deny + reason), permission/capacity/quota gates.
- **PowerUps/Skills**: `PowerUpPanelManager/View`, `PowerUpSkillFileStore`, `SkillCatalogRow`, active/recent IDs, celebration animation, **author/creator rows** → creator-marketplace model.
- **Memory**: `<user_memory note="What HeyClicky has learned about this user across past conversations…` → cross-session memory injected into the system prompt.
- **Pointing vocabulary (richer than [POINT])**: `[TARGET:x,y,r:label]`, `[HOVER:x,y,r:label]`, `[HIGHLIGHT]`, `[SHAPE:arrow]`, `[SHAPE:curve]` (+legacy `[POINT]`). Embedded rule: `[TARGET]/[HOVER]` only for a single observable next action; `[HIGHLIGHT]+[POINT]+[SHAPE]` for manual steps, then tell the user to say "continue."
- **STT**: THREE providers — AssemblyAI, **Deepgram** (`DictationDeepgramTranscriber`, `wss://api.deepgram.com/v1/listen`, worker `/v2/dictation/deepgram-token`), OpenAI upload; dictation speed likely Deepgram-backed.
- **Endpoints**: worker `clicker-proxy-v2.farza-0cb.workers.dev` (`/chat`, `/chat-tool-call`, dictation token); Supabase auth (authorize/refresh/user); Composio `[mcp_servers.composio]` + `/agent/composio/session` (schema cache ~10min); direct `AnthropicMessagesURL`/`OpenAIChatCompletionsURL` constants also present (possible fallback paths).
- **Paywall**: `AgentPaywallHUDManager/View`, `PaywallCardContent` (plans, billing toggle, benefits, "maxed out"); agent launches gated pre-Codex-submit; **Claude Haiku** generates agent-launch-card labels.
- **Feature flags (PostHog)**: CatMode, ColorfulAgentCards, HistoryTab, LibraryMode, OpenAgentMode, ProactiveAgentSuggestions, ProactiveCapsLockDebugTrigger, SkillPinnedNotchState, TransparentPanes, UpcomingMeetings.
- **Onboarding**: skip-shake gesture; `clicky.onboarding.completed.v2`; paid users skip video.
- Notable errors: "Failed to capture any screen", "Screenshot compatibility mode force-exited by hotkey summon (issue #270)", "Deepgram session was not ready."

## 7. Frameworks
Sparkle 2.9.0 (hourly update checks, EdDSA key) · Sentry 8.58.1 + PLCrashReporter · PostHog bundle (analytics + flags). Computer Use lives in the standalone helper binary, not a framework.

## 8. AGENTS.md / claude-*.md
`AGENTS.md` is leftover internal source doc describing a `FloatingSessionButton` feature (hover-glow circle, screenshot-exclusion) — undocumented in the local repo. `claude-code.md` / `claude-design.md` belong to the inert vendored catalog (§3).

## Rebuild-relevant conclusions
1. Adopt the **richer pointing vocabulary** (`TARGET/HOVER/HIGHLIGHT/SHAPE`) over bare `[POINT]`, including the "observable next action vs manual step" rule.
2. The **notch-anchored HUD** is the shipped primary surface (with the cursor glyph + task cards as satellites) — our rebuild's overlay/panel design should anchor at the notch with a non-notch fallback.
3. Only the 14 bundled skills are live — scope our "integrations" claims accordingly.
4. Their voice stack is cloud-heavy (Realtime/Deepgram/AssemblyAI); our Parakeet-local STT is a deliberate divergence (user-specified), keeping their UX contract (~450ms, streaming partials).
5. The agent cursor's motion contract: bezier-glide triangle, ring-ripple on landing, idle-hide ~1.5s — adopt.
