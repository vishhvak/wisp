# Clicky "Spatial Context" Demo — Frame-by-Frame Analysis

Source: `FarzaTV_2074973272463310905_0.mp4` — 3840x2160, 82.39s, h264, 30fps, has audio.

## Full verbatim transcription (with timestamps)

| Start | End | Text |
|---|---|---|
| 00:00:00 | 00:00:03 | Hey, so today we're introducing spatial context to Clicky. |
| 00:00:03 | 00:00:17 | How this works is when you want to actually point out something specific on your screen that you have a question about, you can actually just press the hotkey and use your cursor to hover around the area that you want the model to focus on. |
| 00:00:17 | 00:00:24 | Let's say I'm studying for my human anatomy exam. I can say, "Hey Clicky, can you tell me more about the muscles in this particular region?" |
| 00:00:24 | 00:00:30 | From what you circled, that muscle is the deltoid. It has three parts, anterior in the front, middle... |
| 00:00:30 | 00:00:43 | So this is possible today with things like ChatGPT and Claude, but you've got to actually take a screenshot, annotate it, and do a bunch of nonsense before you pass it off to the model. But it would be a lot nicer if it was just one step, right? |
| 00:00:43 | 00:00:51 | Let's say I'm building a website and I want to say, "Hey Clicky Agent, could you actually go and add a button to this part of the website right here?" |
| 00:00:51 | 00:01:00 | The model then takes the area that I circle and passes it off to our agent which will then add a button exactly where I circled. |
| 00:01:00 | 00:01:09 | I've actually never seen anything like this across the entire AI industry where it's like you can give context of specific things on your screen. |
| 00:01:09 | 00:01:17 | As humans, we just want to take our cursor and hover on the things that we find important, kind of like we show a friend like, "Hey, check this part of the screen out, look at this." |
| 00:01:17 | 00:01:23 | So, that's that. We hope you like it. It's in production right now. And I'm actually behind a glass wall, by the way. Tricked you. |

## Structure / shot list

**00:00–00:16 — Cold-open hook (STYLIZED, not a real screen recording).** Host (Farza) stands and talks to camera while what looks like a hand-drawn white-marker browser-window wireframe (title bar dots, nested content panels, nav icons) hovers over him, plus a small blue triangle "cursor" icon near his head. This entire sequence is later revealed (01:15–01:18) to be the host literally drawing on a glass wall with a blue marker, shot from the other side — a visual gag, not app UI. It recurs as B-roll cutaway under voiceover through the whole video (00:30–00:43, 00:56–01:18).

**00:16–00:30 — Demo 1: "ask about a region" (real screen capture).**
- 00:16: hard cut from stylized glass-wall shot into a real macOS screen recording — Chrome open to `anatomyatlases.org/atlasofanatomy/plate11/01headtrunkarmant.shtml`, a 19th-century-style muscle anatomy plate (head/neck/shoulder).
- 00:17–00:19: static frame, plain system arrow cursor sits near the shoulder; a tiny red triangle badge is already anchored just below/right of the cursor tip — this reads as the "spatial marker" icon, present even before any stroke is drawn.
- 00:20: cut to macro B-roll: a finger presses a hotkey (bottom-row modifier key, globe/fn-style icon) on a MacBook keyboard — this is the push-to-talk hotkey press, captioned "I can say, "HeyClicky, can you". Same instant, on the app-side frame, a tiny red pulsing waveform icon (4 short bars) appears right at the cursor tip on the shoulder — a live "listening/recording" badge tied to the cursor position, not a fixed HUD element.
- 00:21: cut to macro B-roll: two hands resting on a MacBook trackpad (captioned "tell me more about the muscles") — implies the annotation stroke is drawn via a trackpad-drag while the hotkey is held (push-to-talk + point gesture is simultaneous, one continuous hold-and-drag).
- 00:22–00:23: the actual annotation stroke renders on-screen: a **salmon/coral, semi-translucent, thick freehand arc** (rounded caps, ~6–8px at 1000px-wide export ≈ a soft highlighter/marker stroke, not a hard vector line) swooping up and over the deltoid muscle, closing into a rough circle/hook shape around it. The red waveform badge continues to sit at the stroke's leading tip while it's being drawn.
- 00:24: the browser chrome (not the page) is momentarily visible zoomed out — the **macOS menu bar shows "Speaking" as a menu item** in place of the app's normal menu (History/Bookmarks/Profiles/Tab/Window/**Speaking**), with a small audio-bar icon next to it — i.e. system-level indication that TTS playback is active. Caption: "From what you circled, that".
- 00:24–00:29: the drawn stroke itself is gone (consumed/faded after capture — it does not persist as permanent screen ink), but the small red triangle marker remains anchored at the same point on the shoulder as a residual "last-referenced" flag while Claude's spoken answer streams as captions: "muscle is the deltoid. It has three parts, Anterior in the front,".

**00:30–00:43 — Explainer beat (stylized glass-wall B-roll only).** Host explains the problem this solves: "possible today with things like ChatGPT and Claude, but you've got to actually take a screenshot, annotate it, and do a bunch of nonsense before you pass it off to the model... a lot nicer if it was just one step."

**00:41–01:03 — Demo 2: "circle it and have the agent build it" (real screen capture).**
- 00:41: cut to a real localhost dev site (`127.0.0.1:8088`) — a summer-camp landing page ("Golden Gate Summer Camp," dark forest-green hero photo, cream body, "San Francisco." headline, "Start registration" button). Caption: "Let's say I'm building" / "a website and I want to say,".
- 00:44: a **green** (not red) pulsing waveform badge appears at the cursor next to the "Start registration" button — confirms the badge color is mode-dependent: red for the Q&A/vision mode (demo 1), green for the agent/build mode (demo 2). Caption: ""HeyClicky agent, could you".
- 00:45–00:46: user draws a **green, translucent, same-style thick freehand arc** looping in the empty space to the right of "Start registration" — marking where the new button should go. Caption: "actually go and" / "add a button to this".
- 00:48: cut to macro B-roll of a hand on an external mouse (different device than demo 1's trackpad; watch visible on wrist) — captioned "part of the website right here?"" — this is the release/submit beat.
- 00:49: a small **green circular spinner/loader** appears right at the annotation point on the page (replacing the waveform badge) — agent is now processing. Caption: "The model then takes the".
- 00:51–00:55: page live-reloads: headline changes to "Big summer days, rooted in San Francisco.", a new **"Explore Programs" button** appears immediately next to "Start registration" — exactly inside the circled area. A **green toast/callout pill** appears anchored under the new button reading: *"The Explore Programs button is back in the hero next to Start registration, and the preview is live."* — styled like an agent diff-confirmation toast (cf. Cursor/v0-style change summaries), rounded pill, white text on solid green. Caption sync: "and passes it off to our agent, which will then add a" (00:52) → "button exactly where I circled." (00:55).

**00:56–01:18 — Reveal / CTA (stylized glass-wall B-roll).**
- 00:56–01:03: host talks about this being novel ("I've actually never seen anything like this across the entire AI industry"). B-roll cutaway inserts (fast, near-subliminal, ~1 frame each) of unrelated desktop/DaVinci Resolve/Wikipedia/YouTube screenshots flash by at 00:58–01:02 — these look like generic "editing this video" meta B-roll, not app footage, used purely for pacing/visual noise under the VO.
- 01:04–01:11: host mimics the "hover to point" gesture with his own index finger directly on the glass, tracing small circles over parts of the drawn wireframe, captioned "our cursor and hover on the... things that we find important, kind of like we show a friend like, 'Hey, check this part of the screen now, look at this.'"
- 01:12–01:15: "We hope you like it. It's in production right now."
- 01:15–01:18: camera reveal — "And I'm actually behind a glass wall, by the way." — pulls back enough to show the marker-drawn wireframe is literally on a glass panel he's been writing on the whole video, host smirks at camera: "Tricked you."
- 01:18: hard cut to black.

**01:18–01:22 — End card.** Black background, bold white lowercase wordmark-style type, sequential reveal: `try it` → `try it for free` → `heyclicky` (full-word logo lockup), then fade to black.

## Draw-to-direct mechanics (the core mechanism)

1. **Activation**: hold a hotkey (push-to-talk style keyboard shortcut) — same hotkey/gesture family as Clicky's existing voice activation per `CLAUDE.md`'s "ctrl+option" push-to-talk pattern. No visible full-screen tint/crosshair overlay is shown; the drawing surface is the live app content itself, not a dimmed annotation layer.
2. **Drawing surface**: while the hotkey is held, the trackpad/mouse becomes a freehand draw input directly over whatever's on screen — the stroke renders in real time as the user drags.
3. **Stroke style**: thick (~6–8px @1000px export), soft/translucent, rounded-cap freehand arcs — deliberately informal/marker-like, not a crisp vector annotation. Two color variants observed, tied to the invocation mode: **coral/salmon-red** for conversational "tell me about this" (demo 1), **mint/emerald-green** for "agent, build this" (demo 2).
4. **Live feedback while drawing**: a small pulsing mini-waveform badge (matching the stroke's color) rides at the stroke's leading tip — this is the only real-time confirmation that voice + point are both being captured together.
5. **Capture/send**: releasing the hotkey ends the gesture. The drawn stroke itself fades/disappears (not left as permanent ink); a small solid triangle marker persists briefly at the referenced point as a "last pointed-at" flag. No separate flash/countdown/checkmark confirmation animation was observed — the fade of the stroke plus the waveform-badge → spinner-badge transition (00:49) is the only "sent" signal.
6. **Model response**: for conversational mode, Claude answers in TTS + captions referencing "what you circled" (00:24, "From what you circled, that muscle is the deltoid."). For agent mode, the coordinate is handed to an agent that edits the live page and confirms via a green toast pill anchored to the changed element (00:52–00:55).

## Color palette (approximate, eyeballed from frames)

- Spatial stroke — conversational/Q&A mode: coral/salmon red, ~`#E8776B`–`#EA7A6D`, ~70–80% opacity
- Spatial stroke — agent/build mode: mint/emerald green, ~`#3ECC8E`
- Confirmation toast (agent mode): saturated leaf-green pill, ~`#3CB371`-ish, white bold text
- Pointer/marker badge (persistent dot after stroke fades): solid darker red, ~`#D9483A`
- Website-under-edit palette (Golden Gate Summer Camp mock): dark forest-green hero (~`#1B3A2B`), cream/tan body (~`#F0E6D2`), olive-green primary buttons
- End-card: pure black background, pure white type
- macOS chrome throughout: standard light Chrome/Finder chrome, unmodified

## Typography / motion feel

- Burned-in captions: bold, high-contrast white sans-serif, no background box, centered lower-third (~80–85% down frame), phrase-chunked (2–5 words per card), swapped every ~1–2s in sync with speech — classic short-form auto-caption style (CapCut/Opus-Clip aesthetic).
- End-card wordmark ("heyclicky"): bold, fully lowercase, rounded geometric sans (reads similar to a heavy-weight Poppins/Circular/Inter-round style), tight tracking, large scale, left-of-center placement on black.
- Motion feel: hand-drawn strokes ease in with a slight organic wobble (not perfectly smooth bezier) consistent with real trackpad/mouse drag capture, not a programmatic animation. Toast pill appears with what reads like a quick scale/fade-in (can't confirm easing curve from stills alone).

## Production notes

- **Hook/structure**: cold open buries the actual UI demo under a gimmick (host appears to draw a live wireframe overlay on himself in the air) that's revealed as "he's just writing on a glass wall" at the very end — a full-video bait-and-pay-off structure, not just an intro trick.
- **Pacing**: very fast cuts throughout, especially in both demo segments (scene-change detector flagged near-continuous cuts every 1–2s from 00:17–00:25 and 00:43–01:03) — consistent with the B-roll/screen-capture interleaving (keyboard press → trackpad/mouse hands → screen → back to host) used to sell the "one seamless gesture" pitch without ever showing a single unbroken take of the actual interaction.
- **B-roll devices**: demo 1 uses a MacBook trackpad for the point-gesture; demo 2 switches to an external Apple Magic Mouse — likely just shooting variety, not a feature difference.
- **Mic**: host wears a small black clip-on/lapel mic on the hoodie zipper (visible blue LED) — professional audio setup separate from any in-app mic UI.
- **No visible full-screen "draw mode" chrome**: no dimmed overlay, no crosshair cursor change, no dedicated toolbar was seen — the annotation appears to draw directly on the live app surface with only the color-coded stroke + waveform badge as feedback. This is worth confirming against the real implementation since the demo may be simplifying/staging the actual UI (the whole cold-open being staged suggests some editorial embellishment is plausible elsewhere too).
- **Menu-bar "Speaking" indicator** (00:24) is a genuine, reproducible UI detail worth carrying into the rebuild — TTS state surfaces at the macOS menu-bar/app-menu level, not just in-app.
- No on-screen music/lower-third graphics beyond captions and the two end cards; no visible logo bug during the demo itself (only at the very end).

## Timestamp index (for re-review)

- 00:00–00:16 stylized glass-wall cold open
- 00:16–00:24 anatomy screen capture, drawing the coral circle
- 00:20 hotkey press B-roll; 00:21 trackpad B-roll
- 00:24 "Speaking" menu-bar indicator
- 00:24–00:29 Claude's spoken/captioned answer referencing "what you circled"
- 00:30–00:43 explainer VO over glass-wall B-roll ("screenshot, annotate it, a bunch of nonsense")
- 00:41–00:55 website screen capture, green circle → agent edit → green confirmation toast
- 00:48 mouse B-roll
- 00:56–01:18 reveal VO, finger-circle gesture demo on the glass, camera pulls back to expose the glass wall, "Tricked you."
- 01:18–01:22 end cards: "try it" → "try it for free" → "heyclicky"
