# @heyclicky Mascot Channel — Batch Analysis (9 videos)

Method: `claude-video-vision` MCP server driven directly via a custom stdio client (the deferred MCP tools named in the task were not present in this session's tool registry, so the npm package `claude-video-vision@1.3.2` was installed in scratch and called programmatically — same backend/config as the plugin: Gemini API audio transcription, ffmpeg frame extraction). Each video: `video_analyze` (scene_changes + silence + transcription) then `video_watch` (frame_mode: images, resolution: 1024, fps tuned to ~12–25 frames depending on duration, skip_audio since transcript was already captured).

---

## 1. heyclicky_2048940512095420431_0.mp4 — "i am being fixed" (51s, 4K landscape)

**Narration (verbatim, group voice — 5 team members trade lines to camera):** "This is everything we're fixing... One day the time will come where we can say 'Hey Clicky, fix all the bugs' but today's not that day... This weird bug when the app freezes and nobody knows why, it shouldn't happen again... Right now you can't quit the app, so I'm fixing that bug... there's a lot of communication that we need to do in what use cases... Right now you have to say 'Clicky agent' to do any task, so I'm trying to fix that and make it more natural... fixing a bug where Clicky doesn't work on multiple monitors... You're not shipping a bug this day? / I'm not shipping a bug this time." Then a solo cutaway to founder at a desk: "We have about 80,000 messages sent so far, 10,000 agents spawned... almost 2 million views across Instagram and Twitter... we just got our first customers, so money. This might be a business."

**Visuals:** No product UI at all — pure talking-head B-roll. Five people (recurring cast) crowded into one frame in a brick-and-timber office, holding a small black lav mic that gets passed hand to hand as the speaker changes (a runtime visual gag: whoever's holding the mic is talking). Cuts to a close-up over-the-shoulder shot of a hand on a wireless mouse next to a Red Bull can and a laptop, captioned "'Clicky agent' to do any task" — B-roll illustrating the *problem*, not the UI. Ends on the founder solo at his desk (iMac visible, "first customers, so money" line).

**Production style:** Big bold white caption text burned in, synced almost 1:1 with speech (karaoke-less, phrase-at-a-time). No music bed audible in the transcript — it's a straight talk-to-camera clip. The "pass the mic" blocking is the only real visual device. Confirms bugs mentioned in CLAUDE.md's known-issue list are being actively worked (freeze bug, quit bug, multi-monitor bug) — good cross-reference for a "known issues" audit, though this is a marketing clip, not a changelog.

---

## 2. heyclicky_2049325751271616982_0.mp4 — "my creators are upgrading me" (48s, 4K landscape)

**Narration:** "You should've caught this... One Mississippi, two Mississippi, three Mississippi. That's pretty good... How far? / It's always been fast. Thanks to Josue for figuring it out... And no [third party] connectors? / No, just authentication. Basically you're getting the Gmail CLI so that [Clicky] can actually talk to your Gmail... This is going to change my life. Oh! The sender just went in! It's in the Gmail!... Dude, [Clicky] just changed my life, basically. Alright guys, sick, amazing work, we'll package this up tomorrow nicely... this is v1.0.11."

Gemini's transcription consistently renders the product name as **"ClickUp"** rather than "Clicky" throughout this clip — almost certainly an ASR mishearing rather than evidence of a different product or reused meme audio (see visuals below, which confirm it's genuinely about a Gmail integration).

**Visuals:** Opens on a title card "working on new stuff" over park B-roll (team on laptops under a tree). Cuts to a blurry hallway/desk shot, a moody close-up portrait, then a **laptop screen showing Gmail open in Chrome** ("Re: clicky, oops, and what's next" thread) — direct confirmation the "Gmail CLI" narration is about a real feature build, not a gag. Later: a hand writing on a glass whiteboard with **"v1.0.11"** and other notes (partially matches version number spoken in video #3 too). No in-app Clicky UI is shown — it's dev-process B-roll, not a feature demo.

**Production style:** Same "working on new stuff" title-card format as video #5 (recurring template for weekly-update videos). Whiteboard version-numbering ("v1.0.11") is a recurring on-camera prop across at least 2 of these clips — the team visibly tracks/announces version bumps this way.

---

## 3. heyclicky_2051461823212474702_0.mp4 — "i got updated" (4:29, 4K landscape — longest clip, major feature-drop video)

**Narration (extensive — full feature rundown, solo founder on a park bench):** "Clicky is now being used by thousands of people every single day... today I want to show you new stuff we've been working on the last seven days... We launched agents last week... Today we're making the agent more powerful with Google. Now you can connect your Google directly to Clicky... 'Hey Clicky, can you upload this folder to my Google Drive using the Google Skill? Give me the link when done'... Another example: 'Hey Clicky, can you find a time for me to talk with Subhash next week at Monday 2pm? Send him a calendar invite'... Clicky can also interact with Google Sheets, Docs, Slides... **Clicky can actually click things now** — it can use your computer in the background and get stuff done for you. Massive shout out to our friends at [Kua] for helping us build this out... 'Hey Clicky, can you figure out all the ingredients for a high protein lasagna and add it to my cart?'... this feature is interesting but early, sometimes it breaks... Lastly we got **Clicky Notes**... you can tell Clicky what you want to save and it'll save it in the background in its own personal notes system that it writes and maintains for you... these notes and this wiki is not really for you, it's for your agents — this is kind of our own version of agent memory... Clicky can now **inject text into any text box** — 'can you type something into this box that replies to this person'... kind of like WhisperFlow but instead of dictating exactly what you want to say, you leave it up to the AI... And last one: **no need to say 'Clicky agent' anymore**... So that's it, that's version 1.0.11. It's available now."

**Product UI visible (this is the richest single video for UI evidence):**
- **Agent task card** in the companion panel: a dark rounded card titled "Email Summary And Replies" with a "Running" pill badge, a chat-bubble line of live status text ("I'm ranking important recent threads first, then filling to five if needed."), a blue play/send triangle, and a "History ▾" dropdown — this is a live agent-task UI not documented in CLAUDE.md's file list (goes beyond the described chat bubble/waveform response overlay).
- Real macOS desktop B-roll: Finder desktop with folders (Screenshots, Videos, Work, a "lol-snake-game" folder), the third-party menu-bar utility **boringNotch 2.7.3** visible as a downloaded app — not a Clicky feature, just the presenter's own setup.
- **Google Drive** web UI (Chrome) showing "GameCube System Sounds" folder with files, matching the transcript's Google Skill upload demo.
- **Clicky Notes / wiki panel**: a dark two-pane UI titled "Clicky Notes" with a left sidebar list of note titles ("Locky Launch Post — references", "Locky — projects", "Farhaj Mayan — people", "David Horovitz — people", "Sartak Shah — people", "Food Preferences — preferences", "Codex Agent Mode — concepts", "Clicky — projects") each tagged with a category label, and a right detail pane showing the "Locky Launch Post" article with prose Clicky wrote itself plus an embedded screenshot of the X/Twitter post it's referencing. This is a full personal-wiki/agent-memory feature with categorized entries — a significant, currently undocumented UI surface.
- **Text injection into Gmail compose**: a Gmail reply draft box in Chrome with a blue cursor/pointer flying to the compose toolbar and a small blue "found it!" tooltip — the same pointing-tooltip pattern described in `OverlayWindow.swift`, but here demonstrating **third-party text-box injection**, not just pointing.
- Recurring "battery % + folder icons" desktop overlay in B-roll shots — likely a third-party dock/desktop widget, not Clicky.

**Production style:** Solo founder, single park-bench setup, jump-cut talking segments intercut with full-screen screen-recording demos. Numbered feature rundown format ("Lastly...", "And last one..."). This is the closest thing to an official changelog/keynote among the 9 clips — worth treating as a primary source for feature audits over the shorter personality clips. Confirms named integration partner **"Kua"** for the computer-use/agentic-browsing feature.

---

## 4. heyclicky_2052436744226939050_0.mp4 — "i am being used" (53s, vertical 1080×1920)

**Narration (solo, on a rooftop with a chalkboard behind him):** "Two weeks ago I was in my apartment trying to figure out a cool idea to work on. Two weeks later I built this thing that's now being used by thousands of people every single day. And the crazy part is they're not even using it for what I made it for. This is Clicky, it's this cute little AI buddy that lives next to your cursor and can teach you anything in real time. I made a reel about it on IG last week — nearly one million views, ten thousand downloads, and I even got my first one hundred paying customers... There's this eleven-year-old kid using it to make his own RPG game. There's this guy using it to build an iPhone app around mental health for his Instagram community. There are even founders at Y Combinator using it to research their competitors... build the thing and show people early... Can I go home now please?"

**Product UI visible:** A brief screen-recording cutaway: a macOS desert-dune wallpaper desktop with the **blue cursor companion + a speech-bubble tooltip reading "found it!"** and caption text "little AI buddy" — this is the actual cursor-overlay/pointing feature (`OverlayWindow.swift`) shown in the wild, matching CLAUDE.md's description almost exactly. Other cutaways are non-product B-roll: a DaVinci Resolve Studio 20 color-grading panel (behind-the-scenes footage of editing this very video, not a Clicky feature) and an Instagram post from a comic account "@dinoinitiative" (unrelated — likely just scrolling B-roll for "people are using it in ways I never imagined," not literally Clicky-related). Ends with the founder cross-legged on a bench, outro card "heyclicky.com".

**Production style:** Founder-story format (classic indie-hacker "built X, went viral" narrative), talking head on a chalkboard-covered rooftop, minimal captions, one quick self-aware breaking-the-fourth-wall gag at the very end ("Can I go home now please?").

---

## 5. heyclicky_2060824338035868152_0.mp4 — "im getting harder better faster stronger" (59s, 4K landscape)

**Narration (3-person group, park playground set):** "All right, this is everything we're working on this week... one thing we've heard a lot is that HeyClicky is really slow. So we're making HeyClicky 10 times faster, in real time, it'll reply to you near instantly. HeyClicky can now draw on your screen — it'll annotate on screen, show you exactly where to click, and walk you through step by step. [demo aside: 'I want to find the best parts of the city where I can ride my horse' / 'Nice, sweet, partner, true, really, is that what you wanted to say?'] I've been doing lots of cleaning the codebase. I've been working on a new feature where HeyClicky's gonna greet you every morning, but not sure if we'll ship this week... shipping three reels, a couple Twitter videos, making these guys famous again... Did you move to Vibe Dream, or? / No, not yet."

**Product UI visible:** Two screen shots: (1) a laptop/monitor pair showing the **macOS Maps app** with a route/pins UI — matches the "find the best parts of the city" demo aside, implying an annotation-on-Maps use case similar to video #9's route demo. (2) A code editor (VS Code-style) showing what looks like the actual app source — visible top-level tabs "Home / Agents", a struct/class definition, and burned-in caption "new feature where HeyClicky [...]" over a dark editor pane, referencing the in-development "morning greeting" feature and hinting at a Notion integration (partial identifier text visible: "...notion...").

**Production style:** Same "working on [X] this week" weekly-update template as videos #2 and #7 — confirms a recurring "sprint update" content format distinct from the founder-solo feature-drop format (#3) and the personality-story format (#1/#4). Playground/park set with three cast members trading a passed mic, similar blocking device to video #1.

---

## 6. heyclicky_2064128816327655585_0.mp4 — "i wanna help you make music" (66s, vertical 1080×1920) — feature demo, high UI value

**Narration:** "I've always wanted to make music, but FL Studio is so complicated... I hated this so much. So I built a buddy that can see my screen in real time and teach me FL Studio from zero. It can literally draw on your screen just like a sharpie. All you gotta do is press control-option and say 'Hey Clicky, can you show me how to make my first loop?' And Clicky goes showing you how to do it. It highlights the section you want to work on. 'Click the loops folder to open it.' It suggested me a loop I should use. 'Click a loop.' And it shows me where to drag it. 'Then drag it from the browser into the playlist on the right.'... Now Clicky's guiding me to get that bass loop... And just like that you were able to make music with Hey Clicky... for the first time I was able to make a fire beat. Fred Again, Skrillex, I'm coming for you."

**Product UI visible (second-richest video for UI, after #3):**
- Opening gag: presenter's face replaced by an FL Studio (mango) emoji logo over the "FL Studio" title card.
- **The companion panel itself**, fully visible and legible: dark rounded card, top row "🏠 Home / ✦ Agents" tabs with a gear icon, body text **"Hold ⌃control + ⌥option to talk."** and **"Also, you can press Control twice to enter text mode."** — confirms the push-to-talk shortcut documented in CLAUDE.md, plus reveals an undocumented **double-tap-Control-for-text-mode** shortcut not mentioned anywhere in the codebase docs. Below that, a **"Cursor color"** section with four selectable swatches (red, blue, gold/yellow — selected with a highlight ring, green), each rendered as a small triangle-cursor icon, and a **"Dock"** button at bottom right. This is a settings surface not described in `CompanionPanelView.swift`'s CLAUDE.md summary (which only mentions model picker, permissions, DM feedback, quit).
- Live burned-in captions of the voice transcript appear directly over the FL Studio window ("buddy that can", "'HeyClicky, can", "music with") — these are video-editing captions, not in-app UI, but they're overlaid convincingly close to where an in-app caption might sit.
- **The actual pointing/drawing feature in action inside FL Studio**: a thick gold/yellow arrow drawn from the Pattern-list panel across the screen to Track 1 in the playlist, where a loop clip labeled "DL Breaker" is highlighted — a clean, unambiguous capture of the bezier-arc pointing feature (`OverlayWindow.swift`) directing the user's eye to a specific timeline location, matching the "draws like a sharpie" claim.

**Production style:** Solo creator, outdoor park setting, laptop in lap. Emoji-head opening gag. This is a genuine hands-on feature demo (screen-recording + narration), not just B-roll — one of the two videos explicitly flagged as high-value, and it delivers: full settings-panel legibility plus a live pointing-feature capture.

---

## 7. heyclicky_2064493410116112633_0.mp4 — "i am taking big steps" (44s, 4K landscape)

**Narration (2–3 person group, office lounge with couches):** "Here is everything we are shipping. So I am shipping a couple of reels, also working on branding, working on scripts... I am fixing annotation issues, just making sure things are working as expected so you guys have a smooth process... I am adding a new feature where you can invite any of your friends and gift them one month of HeyClicky Pro. Wait, where's Fasa? / Fasa! What are you shipping? / Money to the company's bank account, so we can pay for your competition cappuccino, let's go!... underground methods, the underground way."

**Product UI visible:** None. Opens on a "heyclicky" wordmark title card over an office-lounge establishing shot (leather couches, brick wall). All subsequent footage is talking-head/office B-roll — two guys on a couch with a laptop closed on the table, an open-office shot with monitors showing code in the deep background (too small/unreadable to count as a UI capture), two guys with a MacBook walking, a shaky first-person walking shot, then a solo outdoor close-up ending on the "heyclicky.com" black title card.

**Production style:** Same "everything we are shipping" weekly-update template as #2 and #5, office-lounge setting this time instead of park/playground. Confirms **referral/gift-a-month-of-Pro** as an in-development feature (not yet visually demoed) and reiterates "fixing annotation issues" as ongoing work on the pointing/drawing feature seen in #5, #6, #9.

---

## 8. heyclicky_2064520227455705579_0.mp4 — "drag your files in and start chatting" (4s, 4K landscape) — flagged feature demo

The whole video is a single unbroken 4-second screen recording — no narration, no talking head, no title card. It is a pure product-UI micro-demo, presumably meant to loop or serve as a b-roll insert elsewhere.

**Product UI, frame by frame:**
1. A macOS Finder window titled "files" showing three real files: **`pythagorean.svg`**, **`IMG_0705.png`** (a sheet-music screenshot, 827×1,169), and **`hands-free-clicky_hin.srt`** (a Hindi-language subtitle file) — these are the exact three assets used as demo content in video #9 (the Pythagorean-theorem drawing, the "Interstellar" sheet music, and what appears to be a captions file for a "hands-free Clicky" demo).
2. The user drag-selects all three files with the cursor.
3. As the drag crosses into the top-of-screen zone, the **companion panel appears/expands from a docked-at-top state** and shows a **drop-target overlay**: a dark rounded strip reading **"Drop files here to atta[ch]"** with the three dragged file chips floating above it.
4. On drop, the panel resolves into its **chat-input state**: three small square file-type icon chips (a Chrome/generic-file icon, a document icon, an image icon) sit above a text field reading **"ask HeyClicky..."**, with a paperclip icon and a filled gold/yellow circular send-arrow button on the right.

This is a genuine, previously-undocumented **drag-and-drop multi-file attachment** UI for the chat/agent input — distinct from the screenshot-only vision pipeline described in CLAUDE.md (`CompanionScreenCaptureUtility.swift`). It shows the companion panel accepting arbitrary Finder files (not just images) as chat attachments, with per-file-type icon chips in the input tray before sending.

**Production style:** No cast, no music cue captured, no captions — a pure functional micro-demo, the shortest and most "product-manager-brief" of the nine clips, likely intended as an in-feed feature-announcement snippet rather than a personality/diary clip.

---

## 9. vikpat_2065203535449633213_0.mp4 — "cave walls to whiteboards… why shouldn't AI draw?" (1:48, 4K landscape, posted by @vikpat not @heyclicky) — flagged feature demo

**Narration (solo, presenter "Vikrant," graffiti-covered classroom/studio wall background):** "Could you play 'Can You Hear the Music' on Spotify?... Hey there, this is Vikrant, and in this quick demo video I'm going to show you HeyClicks' drawing capabilities. To show you that, I'm going to use the **always-on mode**, which we can activate by **pressing Ctrl three times**. Could you change my MacBook to light mode?... Sure, switching that over to light mode now. Could you show me a path from the Embarcadero to South Park?... This is the Embarcadero along the waterfront near the Ferry Building. Head south along the Embarcadero into SoMa, South Park sits right around here, just west of Oracle Park... Could you show me what's a measure in this sheet?... Let me take a closer look — this boxed section is one measure, all the notes between two vertical bar lines... Now could you explain this math equation?... Here's the right triangle with its two short legs and the slanted hypotenuse... this square on the vertical leg is a squared, the area built on side a... the two smaller squares, a squared plus b squared, add up to exactly fill this largest square, c squared... This is a very complicated software I need to learn — this vertical strip of icons is the properties editor where the deepest settings live. Thank you for watching."

**Product UI (drawing/annotation demo, exactly as flagged):**
- A **"press Ctrl three times" always-on activation** — this is a distinct invocation gesture from the ctrl+option push-to-talk shortcut documented elsewhere, and from the "press Control twice for text mode" shortcut seen in video #6. Three separate Control-key gestures now observed across the batch (hold ctrl+option = push-to-talk; double-tap ctrl = text mode; triple-tap ctrl = always-on mode) — worth reconciling against `GlobalPushToTalkShortcutMonitor.swift`.
- **macOS Maps app**, dark mode → light mode toggle demoed live, then a drawn **route line with an orange highlight box + text callout** overlaid directly on the map between the Embarcadero and South Park — the drawing feature annotating third-party map content, not just pointing at it.
- A **sheet-music PDF/viewer** (Hans Zimmer "Interstellar" piano arrangement) with a **dashed gold rectangle drawn around one measure**, plus a small triangular cursor glyph anchored at the box's corner — same visual language as the map annotation.
- A **Figma-like design tool** (canvas + left Pages panel labeled "...gorgean 1" [Pythagorean], right Variables/Styles/Export panel) into which Clicky **draws new vector shapes directly onto the canvas**: an orange right-triangle outline tagged "right triangle", then progressively squares on each leg labeled "a squared" / "b squared" / "c squared" — this goes beyond pointing/highlighting into actual freehand shape construction with text-label tags, a materially richer capability than the "bezier arc pointing" description in `OverlayWindow.swift` suggests.
- A cutaway to Blender's default cube/viewport (used as generic "complicated software" B-roll for the "properties editor" line, not an actual annotation target caught on camera).

**Production style:** Single-presenter demo video, none of the recurring @heyclicky cast — cross-posted from creator "@vikpat," graffiti/chalkboard studio backdrop, AirPods visible, "always-on mode" framing suggests this is a partner/community demo rather than an official studio production. Much more technical/methodical pacing than the @heyclicky clips (walks a sequence of distinct annotation use-cases back to back) — reads as a feature-capability showcase aimed at other builders, consistent with the title's "why shouldn't AI draw?" thesis framing.

---

## Cross-cutting notes

**Undocumented UI/features surfaced across this batch** (not in current CLAUDE.md):
- Companion panel settings: cursor-color picker (4 preset colors) + a "Dock" action (#6).
- Two additional Control-key gestures beyond ctrl+option push-to-talk: double-tap Control = text mode (#6), triple-tap Control = always-on mode (#9).
- Drag-and-drop multi-file attachment into the chat input, with per-file-type icon chips (#8) — separate from the screenshot-vision pipeline.
- Agent task cards with live status + History dropdown (#3, "Email Summary And Replies").
- **Clicky Notes** — a categorized personal wiki (people / projects / concepts / preferences / references tags) that Clicky writes and reads as its own long-term/agent memory (#3).
- Text injection into arbitrary third-party text boxes (not just Clicky's own input) (#3).
- Computer-use / agentic browsing ("Clicky can click things now"), built with a named partner, **"Kua"** (#3).
- Google Skill: Drive/Sheets/Docs/Slides + Calendar integration (#3).
- No-wake-word natural agent invocation ("no need to say Clicky agent anymore") (#3).
- Referral feature: gift a friend one month of HeyClicky Pro (#7, mentioned not demoed).
- Morning-greeting feature and a hinted Notion integration, both in-progress (#5).

**Mascot-channel production formula:**
- Three recurring templates: (1) **"everything we're [fixing/shipping]"** weekly sprint-update — 3–5 person cast in a rotating outdoor/office set, one mic passed hand-to-hand as speaker changes, big synced burned-in captions, ends with a joke or fourth-wall break (#1, #2, #5, #7); (2) **founder-solo narrative** — one presenter, a fixed outdoor seat (bench/rooftop/park), talking-to-camera storytelling about virality/traction with 1–2 short screen-recording cutaways as proof, ends on the "heyclicky.com" title card (#3, #4); (3) **pure feature demo** — no cast, no narrative frame, just a screen recording (with or without narration) of one capability end-to-end (#6, #8, #9).
- Version numbers are treated as a visual prop — "v1.0.11" appears handwritten on a whiteboard (#2) and spoken aloud on camera (#3), suggesting the team markets version bumps as milestones rather than hiding them in a changelog.
- The "mango head" emoji gag in #6 and the FL-Studio-as-antagonist framing suggest the channel leans into lightweight editing gags for feature videos, not just the sprint-update jokes.
- Two videos (#3, #6, #9) are genuine screen-recorded feature demos with legible in-app UI; the rest are personality/community-building content with little-to-no product UI, confirming the task's framing that this account is lighter/diary-voice compared to flagship demo content.
