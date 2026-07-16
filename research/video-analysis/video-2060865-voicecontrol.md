# Clicky Voice-Control Demo — Frame Analysis
Video: FarzaTV_2060865350036750847_0.mp4 — 1660x1080, 60fps, 1:44 duration, 14k likes ("control my computer with just my voice")

## 1. Full verbatim narration (transcription)

| Time | Speaker line |
|---|---|
| 00:00–00:02 | "All right, check this out. No hands. Ready?" |
| 00:02–00:08 | "Hey, Clicky, can you please open up Spotify and play AC/DC for me? Maybe Back in Black? I love that song." |
| 00:11–00:13 | Clicky: "Rock on! It's playing Back in Black now." |
| 00:14–00:18 | "Amazing, amazing! Hey Clicky, it's a little bit loud. Could you turn it down in Spotify 50%? It's so loud." |
| 00:20–00:23 | Clicky: "Got it. Lowering Spotify to 50% so it's less than 10." |
| 00:23–00:28 | "Okay, thank you. Hey Clicky, can you open up my Stripe dashboard for me in my browser? Let's see if we made any money today." |
| 00:30–00:32 | Clicky: "Opening your Stripe dashboard now." |
| 00:33–00:38 | "Oh man, $140 in a day is not very good. Um, hey, do you have my Google Ads integration connected?" |
| 00:41–00:44 | Clicky: "Yes, Google Ads is connected and ready to go." |
| 00:44–00:54 | "Okay, Clicky, hey Clicky, I want you to focus. Uh, I want you to double this revenue number by the end of the day. Start a Google Ads campaign for me in the background by starting an agent, and go work on it for me in the background, please." |
| 00:56–00:59 | Clicky: "All right, I'll get a background worker going to set up a campaign with reasonable defaults and pause before launching." |
| 00:59–01:04 | "Amazing. Hey Clicky, I think I have an event at Y Combinator on Wednesday next week. Who's speaking?" |
| 01:05–01:14 | Clicky: "Let me quickly check your calendar details for that event. Paul Graham and Jessica Livingston are listed as the guest speakers for that Y Combinator event." |
| 01:14–01:25 | "Pretty cool, pretty cool. Uh, well, I'm free on the weekend. Hey Clicky, can you set a reminder for me this Saturday at 9 PM to get dinner with my buddy Sharif? And then open up my reminders when you're done to confirm." |
| 01:26–01:29 | Clicky: "Nice! Let me set that up and then pop open reminders for you." |
| 01:31–01:38 | "Amazing. Thanks Clicky! And hey, Twitter's actually watching you right now. Do you want to say hi to them real quick? Just say hi out loud." |
| 01:38–01:42 | Clicky: "Hi Twitter! Thanks for hanging out with us." |
| 01:42–01:44 | "Bye guys!" |

## 2. Voice trigger + real-time HUD

**No wake-word visual "listening bubble" is shown.** The app is in an **always-on / hands-free mode** — confirmed by the menu bar text literally reading **"Always on"** as the idle state label. There's no push-to-talk keypress moment in this video (contrary to CLAUDE.md's ctrl+option push-to-talk description — this demo showcases the always-listening path).

- **00:00–00:08** (first 8s): screen is NOT the live demo — it shows the presenter's own **Xcode editor with a live-scrolling debug console** (`leanring-buddy` project, `ClickyChimeWarmer.swift` visible), used as "proof of work" while he talks. The console prints raw internal state transitions in real time, e.g.:
  - `[notch] voiceState responding → idle`
  - `[Realtime] always-on speech_start gate turn=#1 gate=normal delayMs=220 passed=true`
  - `[notch] apply: liveEvent(HeyClicky.NotchLiveEvent.activityListening) → ...`
  - `[Realtime] confirmed always-on speech — stopping local playback without response.cancel`
  This is a rare, unintentionally-revealing look at the actual internal voice-state machine naming: **idle → listening → processing/thinking → responding**, mapped to menu-bar labels `Always on / Thinking / Speaking`.
- **00:00:02** (2nd sub-frame): a **false-trigger blip** — menu bar flips to "Thinking" for a split second (background noise almost fires a turn) then reverts to "Always on" by 00:03 — an authentic reliability wrinkle, not scripted.
- **00:08–00:09**: menu bar flips to **"Thinking"** as the real command ("play Back in Black") is parsed — Spotify is already showing "Back In Black" by 00:10, i.e. the open+search+play round-trip completed in ~1–2s of visible "Thinking" state.
- **No live/streaming transcript text of the user's speech is ever shown on screen** — there's no captions bubble echoing what the user said. The only real-time feedback is the menu-bar state word + the tiny cursor-trailing status icon (see §4).

## 3. "No hands" computer control — what actually happens on screen

Clicky performs true OS/app-level actions, not simulated clicks-and-drags:
- **00:10** — Spotify opens directly to "Back In Black" (AC/DC), already playing (green pause icon lit). No visible app-launch animation, no Dock bounce, no cursor click shown — it's an instant state jump between frames.
- **00:20** — Spotify volume drops (menu bar flips "Speaking" → confirms verbally "Lowering Spotify to 50%"); no visible volume slider UI manipulation on screen, purely backend audio control.
- **00:30–00:34** — new Chrome tab opens to `dashboard.stripe.com`, resolves through an "Opening link…" title state, then the real Stripe dashboard loads (`$140` gross volume revealed) — again no click/drag shown, just tab creation + navigation.
- **00:44–00:59** — "start a Google Ads campaign... as a background agent" — **no visible on-screen action at all**; the work is delegated to a background worker (confirmed only via TTS reply), screen stays on the Stripe dashboard throughout. This demonstrates the "agent working in the background while you keep using your computer" pitch — deliberately invisible.
- **01:05–01:14** — a calendar lookup happens with **zero visible Calendar app UI** — Clicky answers from data with no screen change (silent backend query).
- **01:26–01:31** — a Reminder is created (backend-only, no visible Reminders UI while it happens) and then, per the explicit request "open up my reminders when you're done," **macOS Reminders.app is opened and foregrounded** at 01:31, showing a genuine new reminder "Dinner with Sharif — Tomorrow, 9:00 PM" inside the Scheduled list. This is the one moment the video shows Clicky opening a native macOS app window as a visible, verifiable "proof" beat.
- **There is no blue cursor overlay flying to/pointing at UI elements anywhere in this video** — the CLAUDE.md-documented `[POINT:x,y:...]` cursor-arc feature is not demonstrated here; all actions are executed as direct API/URL/app-launch calls with instant results, no simulated mouse movement or click ripple.
- The real macOS system cursor (thin black arrow) stays essentially stationary the entire video — the presenter never touches the mouse/trackpad.

## 4. The floating "panel" — actually a tiny cursor-trailing status pill (not a big HUD)

This is the most important rebuild finding: **there's no large floating companion panel visible on screen during active use in this video.** Two much smaller UI surfaces do the work:

**(a) Menu-bar text status label** (top center-right of the menu bar, to the left of the standard icon cluster):
- Renders as plain text, sentence case, single word or two: `Always on`, `Thinking`, `Speaking`.
- Sits directly in the macOS menu bar next to a small animated waveform/mic icon, then the usual system icon tray (screen recording dot, Wi-Fi, battery, clock).
- Font matches system menu bar font (SF Pro ~13px), white on the translucent dark menu bar.

**(b) A tiny circular/pill status glyph that trails the system mouse cursor**, ~10–14px, rendered in **Clicky blue (~#3B82F6–#5B8DEF range)**, seen consistently offset a small distance down-and-right of the actual cursor position:
- **Blue vertical waveform bars** (▍▎▍ animated) = idle/listening ambient audio level (seen at 00:12–00:19, 00:34–00:59 while player continues, 01:14–01:38 intermittently)
- **Blue spinning arc/loader** = "Thinking" processing state (00:22, 00:39, 00:54, 01:08, 01:33, 01:39 — co-occurs exactly with menu bar "Thinking")
- **Solid blue right-pointing triangle (▶)** = "Speaking"/TTS-playing state (00:31–00:33, 00:42, 01:28, 01:32, 01:40–01:41 — co-occurs exactly with menu bar "Speaking")
- At **01:43** (the very end, as the interaction wraps) this icon is seen **moving** — drifting from its resting spot down toward the dock area, confirming it does track/trail cursor position rather than being pinned to one fixed screen coordinate; it had simply looked "fixed" all video because the presenter's mouse never moved.
- No blur/glass material, no visible container/card chrome around this glyph — it reads as a bare icon, not a panel with background.

**No shape/corner-radius/material data available for a bigger floating panel** — it is simply never shown in this clip. (The webcam bubble described in §6 is the only rounded-container UI element visible, and it's the presenter's own camera PiP, not app UI.)

## 5. Voice/state visual language summary

| State | Menu bar text | Cursor-glyph | Trigger moments (timestamps) |
|---|---|---|---|
| Idle/ambient | "Always on" | blue waveform bars (subtle, near-still) | 00:00–00:01, 00:03–00:08, 00:12–00:19, 00:24–00:28, 00:34–00:38, 00:45–00:53, 01:14–01:27, 01:33–01:38, 01:42–01:43 |
| False-trigger blip | "Thinking" (reverts in <1s) | n/a | 00:02 |
| Processing | "Thinking" | blue spinning arc | 00:09, 00:22, 00:29, 00:39, 00:54, 01:08, 01:31, 01:33, 01:39 |
| Responding (TTS) | "Speaking" | solid blue ▶ triangle | 00:31–00:33, 00:42, 01:28, 01:32, 01:40–01:41 |

No color change to the menu bar itself (always dark translucent) — only the text label + tiny glyph communicate state. No mascot/face/avatar is shown anywhere (the "face" the audience sees is the presenter's own webcam, not an in-app character).

## 6. Webcam bubble (production element, not app UI)

- Squircle/superellipse shape, generous corner radius (~35–45px on a ~270x270px box at 960w scale, i.e. roughly 20% radius — heavily rounded but not a full circle).
- Positioned bottom-left, ~30–40px inset from the left edge, vertically centered-low.
- Thin light border/subtle drop shadow separating it from background.
- This is the creator's talking-head PiP overlay (standard recording software, e.g. OBS/ScreenStudio), not part of Clicky's own UI — should not be treated as product chrome.

## 7. Animations / transitions

- All app-triggered screen changes (Spotify open, Stripe tab open/navigate, Reminders open) are **hard cuts between frames** — no visible slide/fade/zoom transition captured; likely near-instant native app-launch/window-focus animations happening faster than the sampled frame rate, not a custom animated reveal.
- The only continuously-animated element is the tiny cursor-trailing glyph (waveform pulse / spinner rotation / triangle pop) — no easing curves observable at this frame density, reads as a simple native macOS-style spinner/level-meter.
- Menu bar text swaps are instant (no crossfade observed between "Always on" ↔ "Thinking" ↔ "Speaking").

## 8. Color palette / typography (best-guess hex from frames)

- **Accent blue** (status glyph, animated bars/spinner/triangle): approx `#4C7CF5`–`#5B8DEF` (a mid-saturation system-blue, similar to macOS `systemBlue`).
- Menu bar: standard macOS dark translucent bar, white/near-white text (`#FFFFFF` @ ~90% opacity), system font.
- No other Clicky-specific color surfaces are visible (no panel background color to sample — see §4 caveat).
- Third-party app chrome visible only incidentally: Spotify dark theme (`#121212`-ish bg, green `#1ED760` play button), Stripe light dashboard (white bg, purple `#635BFF` accents, red "Reminders" red `#FF3B30`-ish for macOS Reminders app icon/badges).

## 9. Content/production structure

- **Hook (00:00–00:02)**: direct verbal cold-open, "check this out, no hands, ready?" — zero visual hook beyond the presenter's face; relies entirely on curiosity from the line itself.
- **Proof-of-authenticity beat (00:00–00:09)**: unusual choice to show raw Xcode debug console scrolling instead of the demo itself for the first ~9 seconds — reads as "look, it's really doing something" (dev-credibility signal) before cutting to the payoff.
- **Escalating task structure**: music control (easy/fun) → volume adjustment (utility) → dashboard/business data (stakes) → background agent delegation (the "wow, it works while I'm not watching" beat) → calendar lookup (info retrieval) → reminder creation + confirmation loop (closes the trust loop by having Clicky show its own work) → live audience interaction ("say hi to Twitter") as a closing/proof-of-liveness beat.
- **Pacing**: long, mostly-static single takes per task (5–15s each) rather than fast cuts; the Stripe dashboard screen alone is held from 00:30 to 01:43 (73s, most of the video) while multiple unrelated voice tasks are layered on top of it — the fixed background lets viewers focus entirely on the state-label/glyph feedback and the presenter's reactions rather than screen changes.
- **No on-screen captions/subtitles burned in** were observed in any sampled frame (spoken dialogue is audio-only per the transcription pass; no text overlay layer detected).
- **Ending**: direct-to-camera sign-off + a scripted live "say hi" moment to the audience (01:31–01:44), closing on a personable, unscripted-feeling beat rather than a hard CTA.

## Rebuild takeaways
1. The real, shipped visual language for "AI is working" is **minimal**: a one-word menu-bar label + a ~12px cursor-trailing glyph with 3 states (bars/spinner/triangle) — not a large glassy floating panel. If CLAUDE.md's described floating panel exists, it is not what's shown in real-world usage/marketing; prioritize the lightweight glyph+menubar language as the "always-on ambient" mode, and treat the bigger panel as the explicit push-to-talk/menu-click surface (not shown here).
2. Background-agent delegation is communicated **purely through speech**, with intentionally zero screen change — worth preserving as a deliberate "invisible work" affordance rather than adding a progress UI.
3. The one moment of visible app-opening (Reminders, 01:31) is the template for "show your work" UI: open the relevant native app, scroll/foreground directly to the created item.
4. No pointing/cursor-arc feature appears in real usage footage — if kept, it's an optional/secondary mode, not the default action-visualization method.
