# Clicky "Screen-Drawing Tutor" Demo — Frame-by-Frame Analysis

Source: `FarzaTV_2066983088035656086_0.mp4` — 3840x2160, 30fps, 02:20 (140.4s) total, has audio.
Extracted via `video_analyze` (transcription + scene detect) and `video_watch` (variable-fps frame sampling, ~1280px, images).

**Note on timestamps**: all times below are verified against the tool's own audio transcription pass (which is authoritative and internally consistent) and cross-checked against frame captions. One `video_watch` call returned a batch of frames with corrupted/offset timestamp labels beyond 02:20 (impossible, since the file is only 140s long) — that duplicate batch was discarded; every timestamp cited below is from a correctly-labeled frame or the transcription.

---

## 1. Structure / timeline

| Time | Segment |
|---|---|
| 0:00–0:10 | Hook: direct-to-camera, chalkboard b-roll |
| 0:11–0:27 | Setup: Khan Academy YouTube video, wake-word |
| 0:28–0:59 | **Demo 1 payoff: Pythagorean theorem drawing** |
| 1:00–1:18 | Bridge: FL Studio pain-point setup |
| 1:19–1:54 | **Demo 2 payoff: FL Studio channel-rack pointing** |
| 1:55–2:16 | Wrap / testimonial / CTA |
| 2:16–2:20 | End cards (wordmark + tagline) |

---

## 2. Full verbatim narration (from transcription)

- 0:00–0:10: "Hey, so we built a system that can draw directly on your screen. It can draw polygons, arrows, curve lines, and a lot more. It can teach you literally anything, no matter what app you're in."
- 0:11–0:22: "So let's say I'm watching this YouTube video about the Pythagorean theorem on Khan Academy and I don't quite understand it. I could just say: 'Hey Clicki, I don't understand how a^2 + b^2 = c^2. Can you draw on my screen directly and show me?'"
- 0:23–0:27: "So now what it's going to do is it's going to take a screenshot to actual return coordinates of drawings that it's going to paint on my screen directly."
- 0:28–0:43: "This little square is the right angle. That's what makes the theorem work. This bottom leg is a. This side is b, and this slanted side across from the right angle is c. Pretty cool! Squared means area, so build a square on the 4 leg. Its area is 4 times 4..."
- 0:44–0:48: "And it's just going to keep showing me how a^2 + b^2 = c^2."
- 0:49–0:54: "The magic is that this square on the hypotenuse holds exactly 16 + 9, 25."
- 0:55–0:59: "And just like that, it drew directly on a YouTube video to explain the Pythagorean theorem."
- 1:00–1:18: "Pretty cool! All right, so that's kind of cute, but what if I wanted to do something a little bit more complicated? What if I wanted to learn FL Studio, which is a program that people use to make music? And I've always wanted to make music, but I find myself always going to YouTube videos where they're 40 minutes long and I'm going back and forth between the video, program, video, program... What if I could learn it all in the program directly?"
- 1:19–1:25: "Let's try: 'Hey Clicki, can you show me how to make my first beat? I'm new to FL Studio.'"
- 1:26–1:42: "Here's the channel rack again. Every row is one drum sound. On the kick row, click this first square. Step 1. Then step 5, the start of beat 2. Then step 9, beat 3, and step 13, beat 4. That's a kick on every beat. Now drop down to this 808 snare row."
- 1:43–1:54: "Click step 5 here, that's the snare on beat 2, and step 13, beat 4. Kick plus backbeat. Press space to hear it groove. All right, and so there we go. We made our first beat literally in like 10 seconds."
- 1:55–2:16: "And we had everything pointed out for us. I feel like I can keep going, I can keep asking more questions about how to add loops, bass, whatever. And this is just a brand new interface for you to actually talk to your computer. Check it out, it's live, it works in literally any program. Try it out, try to break it, I dare you! And enjoy! Bye!"

---

## 3. The drawing/pointing system — exact mechanics observed

### 3a. Two visually distinct annotation primitives, always in the same red

Everything Clicky draws — in both the browser demo and the FL Studio demo — is a single saturated red/crimson (visually reads close to iOS system red, my best hex guess **#FF3B30–#FF2D2D**), used consistently as the "AI drew this" color against both a black paused-video background and FL Studio's dark teal UI. Three shapes recur:

1. **Outlined polygons/squares** (Pythagorean demo) — stroked only, no fill, medium-thick line (~4–6px at 4K, so ~1–2px visually at 1080p equivalent), square/rectangular corners, drawn as geometric construction shapes (see 3b).
2. **Bounding-box highlight rectangles** (FL Studio demo) — a stroked red rectangle drawn around a target UI region (e.g. the whole channel-rack panel, or a single instrument row) to say "this is the thing I'm talking about."
3. **A small solid red dot/marker** (FL Studio demo) — placed at the *exact pixel* of a clickable target (a single 16px-wide step-cell in a 16-step sequencer row). This is the closest thing to a "pointing cursor" in this video — it is **not** a blue circular cursor with a bezier flight path; it's a static red dot that simply appears at the target coordinate, timed to the narration ("click this first square" → dot appears on step 1's cell). No animated flight/arc is visible in the 1fps sampling; it reads as a hard cut-in, not a glide.

### 3b. Callout labels ("chips")

Every drawn element gets a red pill/rounded-rectangle label chip with bold white sans-serif text, positioned inline next to the shape it describes (not lower-third, not fixed — it floats near the annotated element). Observed chip texts, in order of appearance:

- Pythagorean sequence (0:28–0:51): `right angle` → `leg A equals 4` → `leg B equals 3` → `hypotenuse C` → `area 16, side 4` (square-of-leg-A callout) → (second square gets its own area chip, obscured by OCR at 0:44–0:48) → `area 25` / `hypotenuse C` (final large square).
- FL Studio sequence (1:29–1:53): `kick step one` → `kick step five` → `kick step nine` → `kick step 13` → `snare row` → `click step 5 here` → `snare step 5` → `snare step 13`.

Critically, **chips accumulate rather than replace one another** — by 0:37 the frame shows `hypotenuse C`, `leg B equals 3`, and `leg A equals 4` all stacked and visible simultaneously at the top of the shape, like a legend being built up live. This is a deliberate "progressive whiteboard build" — nothing is cleared until the whole proof (or whole beat-programming walkthrough) is complete.

### 3c. How the drawings clear

No fade-out or wipe transition is visible on this footage. The Pythagorean overlay is still fully drawn (all 3 squares, all 4 chips) when Farza cuts back to the laptop-in-hand shot at 0:53 and says "and just like that, it drew directly on a YouTube video" — implying the annotations simply persist on screen at the end of a task rather than auto-clearing. (Nothing in this clip shows a "clear" trigger — that would need a longer capture past the wrap-up.)

### 3d. Coordinate mapping / "pixel-perfect" claim

Explicitly narrated at 0:23–0:27: "it's going to take a screenshot [and] actual[ly] return coordinates of drawings that it's going to paint on my screen directly" — i.e. screenshot → model returns (x,y) coordinates → overlay paints at those absolute screen coordinates. The FL Studio sequence is the strongest visual proof of pixel accuracy: the red dot markers land inside individual ~16px sequencer step-cells in a dense 16×5 grid (frames 1:29–1:53), which only works if the coordinate return is accurate to a few pixels at 4K capture resolution.

### 3e. Narration/drawing sync and pacing

Each spoken clause is paired 1:1 with one drawn element appearing (new arrow, new square, new chip, or new dot) — e.g. "This bottom leg is a" (0:33) syncs with the red arrow-and-chip for leg A; "step 5, start of beat 2" (1:33–1:34) syncs with the dot moving to cell 5 and chip updating to "kick step five." Pacing is roughly one visual beat every 2–4 seconds, matched to natural speech cadence — this reads as scripted/deterministic tool-call pacing (draw → speak → pause → next draw) rather than a continuously-updating live stream.

### 3f. No blue "cursor overlay" / HUD visible in this clip

Notably, none of the companion-app chrome described elsewhere (floating panel, blue flying cursor with bezier arc, waveform, response bubble) appears anywhere in this specific video. The only in-app state indicators visible are:
- A **browser tab title label** that changes text to reflect voice state: `"Listening"` (0:16), `"Thinking"` (0:23) — visible as literal window/tab-title text, not a custom HUD graphic.
- A small **green dot/icon** in the macOS menu bar area next to the FL Studio window title, present continuously through the whole FL Studio segment (1:25–1:53) and paired with a text label reading `"Speaking"` in the title bar — likely Clicky's active/connected state indicator.

This suggests the marketing demo is showcasing the *drawing/annotation* capability specifically, separate from the cursor-pointing/companion-panel UI documented elsewhere in the codebase — they may be two different interaction modes (draw-and-label vs. fly-a-cursor-and-point).

---

## 4. Segment-by-segment shot notes

### Hook (0:00–0:10)
Farza stands in front of a chalkboard/blackboard wall with a **pre-existing hand-drawn chalk sketch** (white chalk on black board) of a simplified browser-window mockup (title bar with 3 dots, 2 small icon squares top right, a content box below). While narrating "it can draw polygons, arrows, curved lines" (0:03–0:06) he **physically chalk-draws** a triangle and a squiggly/wave icon onto the board himself — this is practical set-dressing/b-roll illustrating the concept, not a capture of the app's actual overlay. The same chalk mockups remain visible over his shoulder in every subsequent talking-head shot (0:00, 0:06, 0:53–1:18, 1:54–2:16) as a recurring visual callback.

### Setup / wake-word (0:11–0:27)
Cuts to Farza holding a space-gray MacBook. Screen shows a paused Khan Academy YouTube video on the Pythagorean theorem — the video's **own** built-in animated diagram (pink/yellow/cyan hand-drawn-style triangle with labels "hypotenuse," "90° angle," "Right triangle," and "A²+B²=C²") is visible; these are **not** Clicky's annotations, they're Khan Academy's pre-existing on-screen graphics. At 0:16 a clean screen-recording insert (not laptop-in-hand) shows the full desktop browser with tab reading `"Listening"`. At 0:23 tab reads `"Thinking"`.

### Pythagorean drawing payoff (0:28–0:51)
Full-screen recording insert of the paused Khan Academy frame with Clicky's red overlay building up, in order:
1. **0:28** — small red square placed exactly at the 90° vertex + chip `right angle`.
2. **0:29–0:31** — red arrow drawn along the bottom leg (length 4) + chip `leg A equals 4`.
3. **0:32–0:34** — red arrow along the left/up leg (length 3) + chip `leg B equals 3`.
4. **0:35–0:37** — red arrow to the hypotenuse + chip `hypotenuse C` (now 3 chips stacked simultaneously).
5. **0:38–0:43** — red square constructed off the bottom leg (the "4×4" square), chip reading `area 16` region.
6. **0:44–0:48** — second red square constructed off the other leg (3×3), area chip.
7. **0:48–0:51** — the **big reveal**: a large red square built directly on the diagonal hypotenuse (drawn as a rotated/diamond square since the hypotenuse is at an angle), overlapping the original triangle, with a chip reading `area 25` / `hypotenuse C` — visually demonstrating 16 + 9 = 25.
Cut back to laptop-in-hand at 0:53 with the full annotated proof still on screen; Farza: "and just like that, it drew directly on a YouTube video."

### FL Studio bridge (1:00–1:18)
Talking-head + FL Studio screen inserts (teal/dark default FL Studio theme — Channel Rack, Playlist, Mixer panel all visible, no Clicky annotation yet). Pure setup/pain-point narration, no drawing.

### FL Studio drawing payoff (1:19–1:53)
Full-screen recording insert of FL Studio's Channel Rack (5 rows: 808 Kick, 808 Clap, 808 HiHat, 808 Snare, FLEX Bass; each row a 16-step grid).
1. **1:23–1:24** — red bounding-box rectangle drawn around the whole channel-rack panel (re-establishing the region of interest) + chip `here's the channel rack again`.
2. **1:29–1:30** — red dot lands on kick row, step 1 + chip `kick step one`.
3. **1:33–1:34** — dot moves to step 5 + chip `kick step five`.
4. **1:36** — dot moves to step 9 + chip `kick step nine`.
5. **1:38** — dot moves to step 13 + chip `kick step 13`; by this point steps 1/5/9/13 all show small red dot markers left in place (persistent trail across the row).
6. **1:43** — red bounding box around the 808 Snare row + chip `snare row`.
7. **1:44–1:45** — dot on snare step 5 + chip `click step 5 here` / `snare step 5`.
8. **1:48–1:49** — dot on snare step 13 + chip `snare step 13`.
9. **1:52** — chip `press space to hear it groove` (no new shape, just an instructional chip).
Cut back to laptop-in-hand at 1:54, beat plays, "we made our first beat literally in like 10 seconds."

### Wrap / CTA (1:55–2:16)
Pure talking-head, chalk mockups visible behind him again. No screen/drawing content. Key CTA lines: "check it out, it's live, it works in literally any program," "try it out, try to break it, I dare you," "and enjoy, bye."

### End cards (2:16–2:20)
Cuts to pure black background with a centered, bold, lowercase white wordmark. Observed cards, in order: `clicky` → `heyclicky` (held ~1–2s) → `try it for free` tagline card. Simple hard cuts, no visible crossfade in the sampled frames.

---

## 5. Typography / color / motion notes for rebuild reference

- **Annotation red**: single consistent hue across both demos — best-guess hex **#FF3B30** (iOS system red) or a slightly deeper crimson like **#E63946**; used for stroked squares/rectangles/arrows, filled dots, and chip backgrounds. No secondary annotation color observed anywhere in this clip (no blue, no green, no yellow drawing — contradicts any assumption of multi-color annotation).
- **Chip/label style**: rounded-rectangle (pill), solid red fill, bold white sans-serif text, small size (looks like ~14–18px at 1080p-equivalent), positioned adjacent to (not on top of) the element it labels, chips persist and accumulate rather than being replaced.
- **Burned-in narration captions** (viewer-facing, not app UI): white bold sans-serif, no background box, centered, lower-third, standard short-form-video caption style — visually distinct from the red app-drawn chips (different color, different position, different purpose).
- **End-card wordmark**: white, lowercase, bold geometric sans, centered on pure black, "clicky" / "heyclicky" — friendly rounded terminals, no italics or effects.
- **FL Studio UI**: default FL Studio dark/teal theme (teal-green tracks, dark gray-black chrome) — not app-controlled, just the demoed host application.
- **Khan Academy video content**: black background, neon/pastel marker-style annotations (pink, yellow, cyan) baked into the YouTube video itself — visually similar in *spirit* (hand-drawn-marker look) to Clicky's own red annotations, which may be intentional: the demo picks a video whose own visual language already looks like "drawing on screen," making Clicky's red overlay feel like a natural continuation rather than a jarring addition.
- **Motion**: no evidence of animated draw-on strokes, fades, or spring/bounce entrances in the sampled frames (~0.6–1fps during the dense sequences) — shapes and chips appear to hard-cut into existence, synced tightly to narration beats (~2–4s cadence). No bezier-arc cursor flight observed anywhere in this clip; the "pointing" mechanism here is a static dot appearing at the target, not a moving cursor.
- **No companion panel/waveform/response-bubble UI appears in this video** — state is only signaled via browser-tab-title text (`Listening`, `Thinking`) and a small green status dot in the macOS menu bar area next to the FL Studio window title (paired with title-bar text `Speaking`).

---

## 6. Key timestamp index

| Time | What happens |
|---|---|
| 0:00 | Hook line begins, chalk mockup visible |
| 0:03–0:06 | Farza chalk-draws triangle/wave icons on board (b-roll, not app) |
| 0:11 | Cut to laptop, Khan Academy paused video |
| 0:16 | Screen-recording insert, tab reads "Listening" |
| 0:19–0:22 | Wake phrase spoken: "Hey Clicky... can you draw on my screen directly" |
| 0:23 | Tab reads "Thinking" |
| 0:24–0:27 | VO explains screenshot→coordinates→paint mechanism |
| 0:28 | First red annotation appears (right-angle square + chip) |
| 0:29–0:37 | Leg A, leg B, hypotenuse arrows + chips drawn in sequence |
| 0:38–0:48 | Two construction squares (area 16, area 9) drawn |
| 0:48–0:51 | Large hypotenuse square drawn (area 25 reveal) |
| 0:53 | Cut back to laptop, full proof still visible |
| 0:55–0:59 | "just like that, it drew directly on a YouTube video" |
| 1:00–1:18 | FL Studio bridge/setup, no drawing |
| 1:19–1:25 | Wake phrase #2: "Hey Clicky, can you show me how to make my first beat" |
| 1:23–1:24 | Red bounding box around channel rack |
| 1:29–1:38 | Kick row: dots + chips at steps 1, 5, 9, 13 |
| 1:43–1:49 | Snare row: bounding box, dots + chips at steps 5, 13 |
| 1:52 | "Press space to hear it groove" chip |
| 1:54 | Beat plays, cut to laptop-in-hand |
| 1:55–2:16 | Wrap/testimonial/CTA, no screen content |
| 2:16–2:20 | End cards: "clicky" → "heyclicky" → "try it for free" |
