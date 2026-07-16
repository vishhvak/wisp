# Clicky Screen-Aware Dictation Demo — Frame-by-Frame Analysis

Video: `FarzaTV_2077130366230639022_0.mp4` — 3840x2160, 2:00 (120.1s), h264, has audio.
Transcribed via video_analyze (Whisper backend); frames sampled via video_watch, variable fps, resolution 1280w.

---

## 1. Full verbatim narration (timestamped)

| Time | Text |
|---|---|
| 00:00–00:11 | "Hey, so today we're adding dictation to Hey Clicky. All you've got to do is press and hold FN plus Control, start talking, and whatever you're saying will stream in as text into whatever text box your cursor is on." |
| 00:11–00:21 | "For example, if I'm in Apple Notes, I can just say, today I have to ship three things: first skills, second memory, and third this bug that this one user gave about dictation." |
| 00:21–00:32 | "So that's pretty cool, and honestly, many products already do this exact thing today. But here's the thing: when I'm writing, I often don't really know what I even want to say. So check this out, we're shipping screen-aware dictation." |
| 00:32–00:47 | "It's pretty cool, I've never seen anything like it before and I want to show you. Let's say I want to write a reply to this email, but I'm not quite sure what I want to say. I can just say, Hey Clicky, type a reply to this email and say something like thanks, appreciate you, and ask him what his use cases are for the product." |
| 00:47–00:58 | "And this will take like five seconds, but it'll actually generate a reply directly in my text box in Gmail. I've pasted your reply. And it'll be in my voice, based on Hey Clicky's memories of me." |
| 00:58–01:14 | "This is magical because one, we're using the context of the actual screen to write the reply, and two, it's as if I can write while having a conversation, even if I don't know what I want to say. Hey Clicky, I'm non-technical and I've no idea what Claude is talking about here. Can you type a follow-up prompt in the terminal and also explain it to me so I can learn?" |
| 01:14–01:25 | "I've pasted in a good follow-up prompt. Claude said the next step is to build the app in Xcode. And this whole screen dictation feature gets so much more powerful with skills." |
| 01:25–01:39 | "You can activate a skill like our Y Combinator skill directly in the product, and then you can say, Hey Clicky, this is the one-liner for my pitch deck, type something good that YC would appreciate as the first opener slide on my Google Slides here. And it'll just do it." |
| 01:39–01:54 | "We've been seeing our users use screen-aware dictation for tons of different things: people using it in Google Ads to help them write better ad copy, people getting help on writing their resume, and lots of people just using it to reply to messages on Slack, LinkedIn, stuff like that." |
| 01:54–02:00 | "So that's it. This is in production right now. It's a little bit buggy, but we're making it better every single day. Let us know what you think and enjoy." |

**Note on the "~450ms" claim**: it is never stated verbatim in the narration. It's conveyed purely visually — see §3.

---

## 2. Trigger mechanism

- **Hotkey**: `fn + control`, held down (push-to-talk style, not toggle).
- Shown via a macOS keyboard close-up insert at **00:03–00:05**: camera cuts to a top-down shot of the MacBook keyboard, finger resting near the bottom-left `fn`/globe key, caption "hold fn + control," at 00:03; finger shifts toward `control` key at 00:05 with caption "start talking, and".
- No visible on-screen confirmation of the *key press* itself (no keyboard-overlay HUD) — the only feedback the video shows is the subsequent text-box behavior.

## 3. The dictation HUD / floating UI element

Two distinct HUD elements appear across the demo, in different app contexts:

**A. Menu-bar "Dictating" pill** — seen in the Apple Notes example, 00:12–00:13:
- Small **black, rounded-rectangle pill**, sits in the macOS menu bar top area (not top-center where the clock is — positioned left-of-center among the status icons cluster), white text reading **"Dictating"**.
- Appears already fully formed by the first captured frame after cut (00:12) — no fade-in captured, but it persists across 00:12–00:20 while text streams into Notes.
- Extremely small/subtle relative to the 3840-wide frame — easy to miss, no waveform or partial-transcript preview visible inside the pill itself (it's a static status label, not a live-transcript readout).

**B. Menu-bar "Listening" label** — seen in the Google Slides / YC-skill example, 00:30–00:38:
- Same position (menu bar), but reads **"Listening"** instead of "Dictating" — implies the HUD label changes based on state (e.g., "Listening" while capturing audio for a screen-aware *command*, vs. "Dictating" for raw literal dictation) — this is inferred from the label swap, not stated in narration.

**No floating pill/bar was visible near the text-insertion point itself** (e.g., near the Gmail reply box or the terminal cursor) in any captured frame — the only affordance near the insertion point is a small **red dot/pill indicator** in the Gmail compose toolbar area (bottom-right of the reply box, visible 00:41–00:53, e.g. frame 00:00:53) which looks like a recording-in-progress indicator, separate from the menu-bar label.

No waveform visualization was captured in any frame (unlike what CLAUDE.md's `OverlayWindow.swift` cursor-overlay waveform suggests exists elsewhere in the app — it's simply not shown in this particular demo, possibly because these are zoomed/cropped screen recordings that may crop out the overlay, or the overlay wasn't active on the display being recorded).

## 4. Speed (~450ms) — how it's conveyed visually

Never stated as a number. Conveyed two different ways depending on mode:

- **Raw dictation (Apple Notes, 00:12–00:20)**: words appear on screen essentially in lockstep with the spoken-word captions below the frame — "ship three things." → "First, skills, second, memory," → "and third, this bug that this one user gave about dictation." — each caption chunk change corresponds to new text already visible in the Notes body in the *same* frame, i.e., no perceptible lag dramatized between speech and on-screen text. This is the visual proof of low-latency streaming STT.
- **Screen-aware compose (Gmail, terminal, Slides)** is explicitly called out as **slower** and different in kind: narration says "this will take like five seconds" (00:47) before the Gmail reply appears — this is LLM composition time, not STT latency, and the video doesn't try to visually compress or hide that wait (there's a talking-head cutaway while it happens).

## 5. Screen-aware dictation — how it adapts per app

Confirmed pattern across all three screen-aware examples: the assistant does **not** insert a literal transcript of the spoken words. It uses the spoken instruction as a *prompt*, reads screen context, and composes a fully-formed, app-appropriate output that is inserted as one paste-like block once generation finishes (matching "I've pasted in ..." / "I've pasted your reply" phrasing used every time).

**Gmail example (00:33–00:53)**
- Screen: Gmail thread "Re: The progress of clicky is insane :)" from Blu Revolution, reply pane open.
- 00:37: reply box empty, Gmail placeholder "Press / to write using your Gmail & Drive" visible.
- Spoken command: "Hey Clicky, type a reply to this email and say something like thanks, appreciate you, and ask him what his use cases are for the product." (casual, incomplete sentence)
- 00:47: window pulls back to full Gmail interface (sidebar, inbox list) — no longer just the cropped reply pane.
- 00:51–00:53: reply box now contains a fully composed, properly-punctuated reply: *"Hey! Thanks so much for this, seriously appreciate you being one of the first. Quick question, I'm curious: what are the main use cases you're using the product for? Would love to hear how it fits into your work. Farza"* — signed with the user's name, written in first person, polished — not a transcript of the spoken command.
- Gmail's own native "Draft saving…" / "Draft saved" label appears at top of the compose box (00:51, 00:53) confirming the text landed via normal text-input events (native autosave fired), not an image paste.
- Caption at 00:52: "text box in Gmail." — explicitly narrating *where* it lands.

**Claude Code / Terminal example (00:59–01:20)**
- Screen: a terminal window titled "clicky-closed — Claude Code — claude --dangerously-skip-permissions", composited over the same desert background used elsewhere.
- Spoken command (00:59–01:14): "Hey Clicky, I'm non-technical and I've no idea what Claude is talking about here. Can you type a follow-up prompt in the terminal and also explain it to me so I can learn?"
- 01:15: the terminal's Claude Code input box now contains a **restructured, numbered, technical prompt**: *"I'm non-technical, so before I open Xcode: 1) verify the worker on :8787 is still healthy and restart it if not, 2) then give me the Xcode steps one at a time in plain language (which scheme to pick, what button to press), and 3) tell me exactly what I should see on screen if the app launched successfully, plus what to copy back to you if it fails."*
- This is the clearest evidence that screen-aware dictation reformats output for the target surface — casual spoken request → structured numbered CLI prompt appropriate for an agentic coding tool.
- 01:17–01:20: Claude Code visibly responds in the terminal ("Claude said the next step is to build the app in Xcode"), shown as normal terminal output scrolling above the input box.

**Google Slides / YC skill example (01:23–01:38)**
- First shows Clicky's own **Skills Library** panel (dark rounded floating window, macOS traffic lights, left sidebar of skill cards: "Write like Farza," "Google Plugin Forge," "Google Wingman," "Y Combinator," "YouTube Analysis Aid," "Zero Day Edge"), right-hand detail pane for the "Y Combinator.md" skill — description "YC partner brain: business models, pricing, landing pages, and blunt founder advice from Aaron Epstein's playbook," tags (Y Combinator / Founders / Pitch Decks), bullet list of contents, "Activate Skill" button.
- 01:23 also shows a smaller dark card "Add skills / Skills give HeyClicky superpowers" with a "+" and "Active integrations" row + "Dock" button — reads as the app's menu-bar dropdown/onboarding panel (matches `CompanionPanelView.swift` in the codebase).
- Cut to Google Slides doc "Muse Yard Pitch Deck," slide "Introducing MuseYard," a text box selected (cyan selection handles) with placeholder body copy.
- Spoken command: "this is the one-liner for my pitch deck, type something good that YC would appreciate as the first opener slide on my Google Slides here."
- 01:38: text box now contains a polished marketing one-liner: *"MuseYard organizes everything you save (WhatsApp chats, Apple Notes, screenshots) into a personal museum that shows creators the patterns behind their taste)"* — written in on-brand marketing voice, clearly informed by the activated YC skill.

## 6. Where transcribed/composed text lands

In every example the text appears **directly inside the focused text field** of the target app (Notes body, Gmail compose box, Claude Code terminal input line, Google Slides text box) — never as a separate popup/preview requiring manual copy. The narration repeatedly uses the word "pasted" ("I've pasted your reply," "I've pasted in a good follow-up prompt") suggesting the underlying mechanism is a programmatic paste/insert into the focused field rather than simulated keystrokes for the composed (screen-aware) outputs — consistent with the compose-then-insert pattern seen (full block appears at once) vs. the raw dictation case (Notes) where text visibly streams in incrementally, phrase by phrase, matching live STT partials.

## 7. Voice states + confirmation

Observed states: **idle → "Listening"/"Dictating" (menu-bar label) → text insertion → (for screen-aware) generation delay ("like five seconds") → composed text appears**. No distinct checkmark/toast/"done" confirmation UI was captured in any frame — the only confirmation signals are (a) the host's narration ("I've pasted...") and (b) the target app's own native save indicator (Gmail's "Draft saved").

## 8. Color palette (approximate hex from frames)

- Menu-bar "Dictating"/"Listening" pill: black/near-black background (`#000000`–`#1a1a1a`), white text.
- Skills Library / app panels: dark charcoal (`#1c1c1e`–`#232326`), rounded corners, macOS traffic-light dots (red/yellow/green `#ff5f57`/`#febc2e`/`#28c840`).
- Y Combinator skill icon: YC-orange (`#ff6600`-ish) badge with "Y" mark.
- Desert compositing background (used behind every screen recording — Notes, Terminal, Skills, Slides): warm sand gradient (`#c9a06e` → `#e8c795`) under a teal-to-orange sky gradient (`#2ec9c0`-ish teal at top blending to warm orange), small silhouetted figure with a camera tripod in the dune — a consistent "keynote" framing device across all screen-capture segments.
- Talking-head shots: warm golden-hour exterior light, subject in black crewneck, blurred green trees + a distinctive teal/turquoise building facade in the background (recurring location), a red water bottle prop visible bottom-right of frame in most talking-head shots.
- Gmail UI: warm cream/tan themed inbox (`#ede6d6`-ish), not stock white Gmail — looks like a custom Gmail theme.
- Google Slides: standard white canvas, black slide text, yellow-green "MuseYard" wordmark, cyan (`#00c8ff`-ish) selection handles on the active text box.
- Caption plates: white bold text, no visible background chip in most frames (text sits directly over footage with a drop shadow for legibility), centered, positioned in lower-middle third.
- Outro card: pure black background, white lowercase "heyclicky" wordmark, bold rounded sans-serif, centered (00:57–00:59).

## 9. Typography & motion feel

- Captions: short 3–6 word chunks, karaoke-style (new chunk roughly every 1–2s in sync with speech), bold sans-serif (SF Pro Display/Inter-like), all lower/sentence case matching speech casing, no highlight-per-word animation — chunks simply cut in and out.
- Subject and captions are kept within a centered "vertical-safe" column despite the 3840×2160 (16:9) canvas — strongly suggests this is framed for repurposing into a 9:16 crop (typical of a short-form multi-platform post), even though delivered as a widescreen file.
- Cuts are frequent — roughly every 1–3 seconds — alternating between talking-head and inset screen-recording B-roll, giving a brisk short-form pace throughout.
- Screen recordings are never full-bleed screen captures; they're always an inset floating window (drop shadow, rounded corners) composited over the desert background — a consistent "framed demo" visual device used for every single app example (Notes, Gmail, Terminal, Skills Library, Slides), reinforcing a single visual system across very different underlying apps.
- No music/SFX data was available from the analysis backend (audio filter returned no tags); no distinct confirmation "ding" moment is visually cued in the frame captures.

## 10. Content/production structure notes

- **Hook** (00:00–00:11): cold open, direct address, immediately states the feature and the trigger mechanism — no preamble.
- **Baseline demo** (00:11–00:21): simple literal dictation into Apple Notes — establishes the "boring but useful" baseline.
- **Explicit "many products already do this" pivot** (00:21–00:32): the presenter names the commodity nature of basic dictation out loud, gestures self-consciously (hands to face, then chin, exasperated expression at 00:25), then pivots to "we're shipping screen-aware dictation" — a deliberate expectation-reset beat before the differentiated feature.
- **Three escalating screen-aware examples**, each demonstrating a different target-app class: consumer web app (Gmail — everyday task), developer tool (terminal/Claude Code — technical/agentic task), and creative/productivity doc (Google Slides — enhanced further by an activated "skill" for domain-specific tone). This is a clear escalation ladder: simple → technical → skill-augmented.
- **Social proof montage** (01:39–01:54): rapid-fire named real-world use cases (Google Ads copy, resumes, Slack/LinkedIn replies) with no screen recording — pure talking-head, fastest pacing of the video.
- **Close** (01:54–02:00): candid "it's a little buggy but we're improving it" admission, then logo card outro.

---

## 11. Timestamp index (quick reference)

| Time | Beat |
|---|---|
| 00:00 | Hook: "we're adding dictation to HeyClicky" |
| 00:03–00:05 | Keyboard close-up: hold fn + control |
| 00:11 | "For example, if I'm on Apple [Notes]" — cut to screen |
| 00:12–00:13 | Menu-bar "Dictating" pill visible; text streams into Notes |
| 00:20 | Full dictated note visible, orange caret at end of text |
| 00:25 | Presenter reaction beat before the pivot |
| 00:31 | "screen-aware dictation" first spoken |
| 00:37 | Gmail reply box empty, placeholder visible |
| 00:41 | Red recording indicator appears in Gmail compose toolbar |
| 00:47 | Full Gmail window revealed |
| 00:51–00:53 | Composed reply appears in compose box; "Draft saved" |
| 00:54–00:58 | "in my voice, based on HeyClicky's memories of me" |
| 01:08–01:20 | Terminal / Claude Code example; composed numbered prompt appears at 01:15 |
| 01:23–01:29 | Skills Library UI; Y Combinator skill detail pane |
| 01:30–01:38 | Google Slides; "Listening" menu-bar label; composed one-liner lands in text box at 01:38 |
| 01:39–01:54 | Social-proof montage (Google Ads, resumes, Slack/LinkedIn) |
| 01:54–01:57 | Close: "a little bit buggy... enjoy" |
| 01:57–01:59 | "heyclicky" logo outro card |
