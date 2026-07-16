# Clicky Launch Campaign — Video Batch Analysis (9 videos)

Method note: The MCP `video_analyze`/`video_watch` tools referenced in the task were not actually registered in this
subagent's toolset (ToolSearch returned no matches under any query, and the `claude-video-vision:watch-video` skill's
underlying MCP tools were also absent). Built an equivalent pipeline manually: `ffmpeg` for frame extraction (JPEG,
~15 frames/video evenly spaced, 35 for the FarzaTV flagship) and audio extraction, then `whisper-cli` (whisper.cpp,
base model, local) for timestamped transcripts, then read frames via the Read tool (multimodal). Same inputs/outputs
as the intended tool, different plumbing.

---

## 1. vikpat_2068160211303678403_0.mp4 — "draw on your screen to give spatial context. It's live" (vertical, 75s)

**Narration (verbatim):** "Hi there, Vikrant and here's a quick demo about what's dealing with HeyClicky's new drawing
capabilities. Last week we launched the ability for HeyClicky to draw on your computer screen. It could draw
polygons, curved lines, arrows and stuff like that. But then we thought, why don't we give this drawing capability to
you guys so that you can give more context to HeyClicky by just pressing Ctrl+Option. [...] Pardon my drawing, I'm
using my pen to describe what you're pointing at. That's a silhouette of a person standing on a dune crest. Let me
build a mockup using HeyClicky. Can you make a simple mockup about IMAX 70mm locations for the movie The Odyssey?
Could you add a button over here with their Google Maps link? [...] It added a button and it takes me to the actual
place. So yeah, just press Ctrl+Option and glide your cursor around the screen and give HeyClicky more context about
your query or whatever you want to do. It's live and yeah, see ya."

**Screen contents / product UI:** Real captured product UI is brief and appears at ~0:07 and ~0:26: the macOS menu
bar shows a **text state label "Speaking"** in the same slot documented for the app (top-left of the menu bar, next
to the app name area) — confirms a text-based voice-state indicator beyond just an icon. At the same moment, a small
red pill-shaped label reading **"perso[n]"** (cut off) sits next to a pointer/cursor over a screenshot of a person on
a sand dune — this is the on-screen "point + label" annotation the video's whole premise is about. The rest of the
laptop-screen content (a desert wallpaper, in later clips a mockup with an IMAX theater button) is real Mac desktop,
but most of what's "drawn" in-frame is a **hand-drawn whiteboard-style overlay composited in post** (an outline of a
laptop window with polygon/curve/arrow doodles, word-by-word burned-in captions like "polygons, curve", "HeyClicky by
just", "press control + option") — i.e. stylized b-roll illustration, not a literal screen recording of the drawing
feature in action. Only the two frames above show the actual live product overlay.

**Production style:** Vertical 9:16, glass-walled modern office corridor, presenter (Vikrant, curly hair, glasses)
holding a MacBook and narrating to camera while a translucent white sketch-style graphic of a laptop + shapes is
composited over him — a recurring visual motif (this "ghost laptop with doodles" graphic reappears across multiple
frames as a connective visual thread). Large bold word-by-word captions, mixed serif-less sans, white text,
positioned mid-frame. No music audible in this segment of transcript; delivery is fast, casual, single-take talking
head with B-roll cutaways to a real MacBook screen recording only twice.

**Surprises:** The actual product screen recording is used far less than the illustrated/animated version of the
same idea — the video sells the concept more than it demonstrates the UI. The real UI moment (the "Speaking" label +
red "perso" pointer pill) is the single clearest piece of ground truth for the on-screen annotation feature in the
whole batch alongside video 4.

---

## 2. heyclicky_2068516733812658476_0.mp4 — "i went to demo day" (horizontal/mixed aspect, 114s)

**Narration (verbatim, condensed):** Mostly ambient/vlog audio ("Hey, clicky, jam out there. Feeling good?"), then:
"So I asked Vaza what we should be wearing for the demo... Hey, my name is Vaza and I'm working on Hey Clicky. It's
the simplest interface in the world to talk to your computer and spawn agents. Let me just show you how it works.
Hey Clicky, we're at demo day, say something." [...] "I started working on this because I was just really annoyed
that everybody was talking about agents. Yet no one I actually knew really used them. And I feel like it's just an
interface problem, not a technology problem. And this is our solution." [applause] Then a wrap-party/mentor speech:
"It's been amazing three months with you all... stay tuned to help each other, that's your unfair advantage."

**Screen contents / product UI:** None. This is pure event vlog b-roll — car interior with a rear-seat infotainment
screen playing Spotify (unrelated to Clicky, just ambient), backstage demo-day prep, a pitch to a small audience, and
a bar/afterparty montage with visible neon signage. No Clicky UI is shown at any point in the sampled frames.

**Production style:** Handheld, natural light, letterboxed clips mixed with full-bleed clips (suggesting stitched
source footage of varying native aspect ratios), diaristic pacing, ambient in-scene audio kept rather than
voiceover-only. Reads as an accelerator demo-day recap (the "farza@buildspace..." email domain seen in video 9
corroborates a Buildspace/YC-style accelerator batch).

**Surprises:** This is the one video in the batch that is 100% narrative/brand storytelling with zero product UI —
useful as a pure "content-production style" data point: the origin-story pitch line ("it's an interface problem, not
a technology problem") is the closest thing to an official positioning statement in the whole batch, and it recurs in
spirit in video 9's closing pitch.

---

## 3. heyclicky_2069491818992193877_0.mp4 — "let me help you finally install claude code plz" (vertical, 48s)

**Narration (verbatim):** "[Press] control plus option. Hey Kiki, can you show me how to install [Claude Code] on my
computer using Terminal? I am scared of Terminal, I have never used it." → "I'm dropping the official native install
command." → "So it's setting up Claude Code now, yo, it's insane." → "Could you tell me how do I run this and how to
start using this?" → "type 'claude' and press return to start an interactive session. Once it opens, just type what
you want in plain English." → "Okay, so I just installed Claude Code on my computer by just using my voice."

**Screen contents / product UI — dev-setup flow (timestamps approximate, evenly-sampled frames):**
- **~0:14:** Menu bar shows **"Speaking"** state label again (confirms state label persists across videos/builds).
  Terminal window titled `vikpat — -zsh — 80×24`. Command on screen, drawn-in with a red dashed underline + arrow
  callout pointing at it: `vikpat@vikrantsworkmac ~ % curl -fsSL https://claude.ai/install.sh | bash` — the real,
  official Claude Code install one-liner.
- **~0:20:** Same terminal now shows full install output: `Setting up Claude Code...` → `✓ Claude Code successfully
  installed!` → `Version: 2.1.186` → `Location: ~/.local/bin/claude` → `Next: Run claude --help to get started` →
  `✅ Installation complete!` → prompt returns to `vikpat@vikrantsworkmac ~ % claude▌` (cursor blinking, ready to
  launch).

**Production style:** Same visual language as video 1 (same presenter Vikrant, same desert-wallpaper MacBook, same
red hand-annotation style calling out the exact command being spoken/typed). Word-by-word burned captions again
("my computer using", "Okay, so could", "computer by just"). This is effectively a two-part series with video 1 (same
"press control + option" framing, same B-roll aesthetic).

**Surprises:** The demo is a genuinely real, voice-driven install of Anthropic's own Claude Code CLI via HeyClicky —
i.e., HeyClicky is shown controlling the Terminal end-to-end via dictation (open Terminal → dictate the curl command →
confirm → run `claude`), not just answering questions about the screen. This is the most literal "voice controls your
computer" demo in the batch.

---

## 4. heyclicky_2070614244463428071_0.mp4 — "i can teach you figma motion" (vertical, 54s)

**Narration (verbatim):** "This is the motion beta icon. Click it to switch into motion mode. Click this diamond next
to position to drop your first keyframe at time zero. Now drag the playhead to the right, to about the one-second
mark. Then change the rectangle's X value here. Your arrow points down here to the lower right, with the playhead
still at the second keyframe. Drag the square from here down to there on the canvas. Nice. Drag the playhead all the
way back to zero. Click this diamond to size rotation. Now drag the playhead to the right, then type a value here,
like 360 degrees. Click this play button at the far left of the timeline to preview your animation."

**Screen contents / product UI — the teaching overlay:**
- **Title card (0:00):** sage-green background, cursor + small red audio-waveform glyph, then burned caption
  `"heyclicky, can you teach me figma motion?"`, then the black Figma app-icon badge fades in — establishing the
  voice query that triggers the lesson.
- **~0:07–0:20, real Figma "Motion (Beta)" panel**, screen-recorded (not illustrated) on an iPad-shaped device (visible
  rounded bezel + front camera cutout, actually a tablet, not a MacBook, in this video): panel shows `Motion Beta`
  label, `Rectangle` selection, `Animations` section, `Transform` group with `Position X→148 Y→146`, `Scale 100%/100%`,
  `Rotation 0°`, `Layout` (`Dimensions W100 H100`), `Appearance` (`Opacity 100%`, `Corner radius 0`), `Fill D9D9D9`.
- **Red arrow + pill-label annotations overlaid live on the real UI**, same visual grammar as video 1's "perso" label
  and video 9's callouts: a label reading **"posit[ion]"** points at the Position/keyframe diamond; a label reading
  **"move playhead"** with a long red arrow points from the left side of the timeline to the current playhead
  position; a label reading **"target spot"** points at an empty canvas region where the object should end up.
- Top menu-bar strip again shows the **"Speaking"** state-label pattern.

**Production style:** Closer to a literal screen-recorded tutorial than videos 1/3 — real Figma UI, real cursor
drags, real keyframe diamonds clicked, with the app's own pointing/annotation system doing the highlighting instead
of post-production doodles. Captions are shorter, more instructional/neutral in tone than the other clips' comedic
captions.

**Surprises:** This is the clearest evidence that Clicky's "point at UI elements" feature (documented in the
codebase as `[POINT:x,y:label:screenN]` tags parsed into a cursor overlay — see `ElementLocationDetector.swift`,
`OverlayWindow.swift`) is used for **teaching workflows in third-party apps**, not just pointing inside its own UI.
However, the on-screen annotation color here is **red**, not the blue accent (`#2563eb`) specified in
`DesignSystem.swift` — either the annotation styling differs from the cursor-overlay styling, or marketing renders
used a different/older palette than what's currently in source.

---

## 5. heyclicky_2070992648870178935_0.mp4 — "i am celebrating $10k mrr at a gas station" (53s, 4K)

**Narration (verbatim, condensed):** "Hey, this is everything we're shipping this week. So I mainly talk to users
this week... Also we had 400 customers this week, which is insane, so now we gotta celebrate... Vikrant, what do you
want to buy? On the company, we can live large today... We're also adding skills. So you're going to be able to
actually use skills — [things] much better at certain tasks, like Claude, Blender, After Effects, that sort of
stuff... What's 400 customers in MRR? 9,000. 9,000 MRR."

**Screen contents / product UI:** No Clicky app UI shown. B-roll is a build-in-public "week in review": a laptop on a
desk showing a blurred email/inbox (sender name legible: **"Ann Bordetsky"**, likely an investor/advisor — the page
title/content is otherwise blurred deliberately), then a chaotic, motion-blurred convenience-store snack-grab montage
(matches the "we can live large today" caption), ending on a gas-station/convenience-store celebration.

**Production style:** Weekly-update vlog format, handheld and shaky by design (intentional blur during the "let's go
buy stuff" beat), burned captions synced to speech. No music cues audible in the sampled transcript segment.

**Surprises:** Despite the clip title referencing "$10k MRR," the transcript's actual number is **9,000 MRR** off 400
customers — the $10k figure in the campaign's video title is rounding/marketing shorthand, not a number stated on
screen. Also the first on-camera confirmation in the batch that a **Skills marketplace** is in development ("adding
skills... much better at certain tasks, like Claude, Blender, After Effects") — corroborated independently by video 8's
"Power-Up" card UI.

---

## 6. heyclicky_2072514248220225885_0.mp4 — "i now use claude fable 5 as my default model" (38s, 4K)

**Narration (verbatim):** "Everyone, so about two weeks ago we released this drawing feature that can draw directly
on your screen using Claude Fable 5. In that video I actually mentioned that we use Fable 5, but then two days later
Fable 5 got banned by Donald Trump or whoever runs the government. Happy to say that Fable 5 is back now and now it's
the default model on Hey Clicky. So when you actually ask a question related to your screen on Hey Clicky, it will
use Fable 5 as the model and it's so much better at pointing, understanding, stuff like that. So give it a shot,
we've been using it on some really complex programs and it's doing really well, so I hope it helps — here's the
less hallucinations. Okay, bye."

**Screen contents / product UI — the standout frame of this video:** A real **Claude Code terminal window**, title
`clicky-closed — ✳ Claude Code — claude — 80×24`, showing:
```
Claude Code v2.1.193
Opus 4.8 (1M context) · Claude Max
~/clicky-closed
▲ 2 MCP servers need authentication · run /mcp

│ Fable 5 is back.
│ Until July 7, you can use up to 50% of your plan's weekly usage limit on
│ Fable 5. If you hit your limit, you can continue on Fable 5 with usage
│ credits. Fable 5 draws down usage faster than Opus 4.8. Learn more
│ (https://support.claude.com/en/articles/15424964-claude-fable-5-promotional-access)
> Try "refactor index.ts"
```
The macOS menu bar in this same frame shows a **"Thinking"** state label — a fourth distinct text state (alongside
"Listening", "Speaking", "Reasoning" seen elsewhere) that does not map onto the shipped `CompanionVoiceState` enum in
`CompanionManager.swift:17-21` (`idle`, `listening`, `processing`, `responding` — 4 cases, none literally named
"Thinking" or "Reasoning" or "Speaking", though they likely render to these display strings).

**Production style:** Outdoor talking-head (yellow cap, glasses — the same presenter/"Farza" persona as video 9),
short single-topic update video, no B-roll beyond one terminal screenshot insert. Straightforward "here's what
changed" tone typical of a build-in-public model-swap announcement.

**Surprises:** This is a striking real-world corroboration that **"Claude Fable 5" is a genuine, currently-promoted
Anthropic model** (with an actual `support.claude.com` promo article and a "50% of weekly usage limit until July 7"
mechanic) — not a joke or internal codename. The dev-repo folder is literally named `clicky-closed`, suggesting a
private/closed-source counterpart repo. Also notable: the currently-checked-out source's model picker
(`CompanionPanelView.swift:601-611`) only exposes **Sonnet** (`claude-sonnet-4-6`) and **Opus** (`claude-opus-4-6`) —
no Fable 5 entry — so either this vision-routing behavior ("uses Fable 5 for screen-related questions") is decided
server-side/automatically rather than via the visible model picker, or the local checkout predates this change.

---

## 7. heyclicky_2072811513136681001_0.mp4 — "based on a true story" (vertical, 86s)

**Narration (verbatim, condensed, comedic/rant tone):** "Every goddamn day I open Instagram and I grow more and more
confused. Everyone makes it sound like AI is so easy... Well let me tell you something, it's not that easy. First of
all, what the heck is GitHub? How do you prompt Claude Code, is this like ChatGPT? [...] Even if you do manage to
build an app with AI, good luck learning how to get people to check it out... So I FaceTime my little brother and...
'I'll be honest bro, I don't know any of this stuff either.' That confirms it, raw cooked. [...] I built an app that
can see your screen and teach you anything in real time. It's kind of like having an expert mentor next to you 24/7.
So when you have no idea what you're doing, you can just say 'Hey Clicky, how do I use a skill file in Claude Code
properly, can you teach me?' And from there the app will see your screen, analyze it, and help you right there. It's
kind of like a teacher by your side. It's totally free to try. If you're someone trying to learn how to build stuff
with AI, comment 'help' and I'll send you the link."

**Screen contents / product UI:** No Clicky UI. All B-roll is phone-in-hand footage of scrolling Instagram Reels
(a video titled "ARE WE IN AN AI..." with an ouroboros graphic captioned "THE AI OUROBOROS" — meta commentary on
AI-content saturation) and a FaceTime call screenshot with the presenter's brother.

**Production style:** Fast-cut, meme-adjacent, direct-to-camera rant/relatable-pain-point opening (classic
short-form hook structure: complaint → escalation → confession → pivot to solution → CTA "comment help"). No product
demo at all — pure pain-point/CTA video, functionally a lead-gen ad disguised as a rant.

**Surprises:** This is the most aggressively "hook-first" video of the batch by viral-shortform convention (cursing,
self-deprecating confession beat, screen-recorded phone scrolling as texture) and the only one using a lead-magnet
CTA ("comment help and I'll send you the link") rather than a direct install/try link.

---

## 8. heyclicky_2073244153593663659_0.mp4 — "see you tomorrow" (teaser, 35s, 4K)

**Narration (verbatim):** "Hey everyone, so tomorrow I'll be doing a live stream where I'll be showing you everything
that we've been hacking on these last couple of weeks. I'll also be showing you just how we're building this
company, all the different AI workflows we've been using, all the different things we've learned, and just share.
It'll be really fun, tomorrow at 11am, I'll see you there." [singing: "dreamer, dreamer, dreamer..."]

**Screen contents / product UI — teased features (quick B-roll inserts, not fully shown):**
- A **"Resume Roaster.md"** skill card: title, a green **"New"** tag, tag chips `Resume` / `Job Search` / `Career`,
  description "Brutal recruiter-grade resume roasts, plus the exact fixes that get interviews," a bullet list under
  "INSIDE THIS SKILL" (roast style, 7-second recruiter scan, Google's XYZ formula, buzzword hit-list), a
  **"Created by [avatar] Nilesh Rathore"** attribution, and a full-width **"+ Activate Power-Up"** button — i.e. a
  marketplace/store card UI for installable "Skills" (aka "Power-Ups"), matching the roadmap item mentioned narratively
  in video 5.
- A same-family bullet list from a different skill card in the background: "Marketplace launch playbook that got
  70,000 buyers pre-launch," "YC application and pitch advice from a reader of 8,000+ apps," "First-time manager
  rules for founders growing a team" — suggests multiple pre-built Skills content packs, not just Resume Roaster.
- A dark-mode animation-timeline UI (looks like a code/motion editor, teal grid, blue playhead, cyan chat bubble
  reading `(^-^)ノ morning! go grab` — an in-app assistant greeting bubble) and another **red arrow + "playhead"
  pill-label** annotation over a timeline UI (same visual grammar as video 4's Figma teaching overlay), suggesting
  the teaching/pointing feature also gets used in the presenter's own motion-graphics tooling, not just Figma.
- Closing card: black background, white text **`heyclicky.com/july4`** — the livestream's landing URL, dating this
  teaser to just before July 4.

**Production style:** Gas-station backdrop talking head (same presenter as video 6), quick-cut teaser format packing
several feature-preview inserts into 35 seconds, ending on a deliberately off-key a cappella "dreamer" sting as a
sign-off flourish/brand quirk.

**Surprises:** Confirms a **Skills/Power-Up marketplace** is real and imminent (not just a stray comment in video 5)
— complete with per-skill attribution to named creators, suggesting a creator-marketplace model (think a plugin
store) is planned, not just first-party skills.

---

## 9. FarzaTV_2055774393243230387_0.mp4 — "proactive nudge / notch UX" (240s, 4K) — FLAGSHIP, extra depth

This is a fundamentally different pitch from the other 8 videos: it demos a **"new design"** for Clicky that does not
match the shipped menu-bar-panel architecture described in the project's own `CLAUDE.md` (`NSStatusItem` + custom
floating `NSPanel`). It is best read as a **forward-looking concept/redesign demo**, not the current build.

### Full narrative arc (paraphrased from the verbatim transcript)
"So this is the new design we're messing around with for Clicky... instead of following you around 24/7, he actually
lives up top in your MacBook's notch." The pitch: AI should be *proactive* — "it should tell you it can be helpful
while you're trying to do some work." Demo sequence: (1) working in Notion → Clicky detects it and pops a nudge
offering to connect the Notion integration → user approves → (2) presenter browses to Stripe's landing page, says
"Hey Clicky, I love this landing page, can you save it to my Notion so I can reference it later, make a database of
landing pages I find interesting" → an agent spins up in the background, the notch changes to show it's working,
and it (3) builds a real Notion "Landing Page Inspiration" database, tagging Stripe with Fintech/SaaS/Bold and the
URL. Second workflow: on a real internal support inbox, presenter dictates "put this bug in Linear for me, check for
duplicates, track their version/build, then send it to Kamil on Slack" → the agent (4) reads the bug email, creates a
Linear ticket with structured fields, and (5) DMs Kamil on Slack with a summary + the Linear link, unprompted
("Notice I didn't have to say 'we're spawning an agent' — I just asked, Clicky's brain is smart enough to know it's a
multi-step task"). Presenter later checks status by voice ("are my agents done yet, the two I just ran?") and the
notch confirms both are complete. Closing stats: "this thing's four weeks old... about a thousand daily active users,
about a hundred customers paying... available right now to try for free."

### The proactive-nudge UI itself (the part we know least about — this is the answer)
At **~0:15–0:19** (frame_004 of 35), while the presenter is simply browsing Notion in Chrome (no voice command
issued), a **small dark toast/popup docks at the top of the browser, overlapping the tab strip**, reading:
- Header row: a Telegram-like icon + the Notion icon, then bold text **"Connect Notion to Clicky?"**
- Subtext: **"Use Clicky to:"** followed by three horizontally-scrolled suggestion chips: **"Create a meeting notes
  page,"** **"Attach this screenshot to a page,"** and (partially visible, cut off at the frame edge) **"Update a
  task row."**
- Action row, right-aligned: **"✕ No"**, **"🕐 Not now"**, and a highlighted primary button **"🔗 Yes"** (paperclip
  icon) — the cursor is shown actively clicking "Yes" in this frame.

So the mechanism is: Clicky watches the active app/site (ambient screen awareness, no explicit voice trigger),
recognizes a known SaaS surface it has an integration for (Notion here), and surfaces an **unsolicited,
dismissible, three-way-choice (No / Not now / Yes) toast** anchored to the top of whatever window is frontmost —
not inside its own panel — offering to wire up that integration, with example use-cases as suggestion chips so the
user immediately understands *why* connecting would help. This directly operationalizes the narration's thesis
("AI should be proactive... most people don't know where agents can be helpful in their current workflows").

### The "notch" status/agent-task UI
Two distinct notch-adjacent panels recur:
1. **A settings-style panel** (frame_002, ~0:05): tabs **"Home" / "Agents"**, hint text "Hold control+option to
   talk," "you can press Control twice to enter text mode," and a **cursor-color picker** with four swatches
   (red / blue / **yellow, selected, highlighted with a gold ring** / green) — confirms the pointer/cursor overlay
   color is user-configurable, not fixed to the blue accent documented in `DesignSystem.swift`.
2. **An "Agents" task-list panel** (frame_013, ~0:41): header tabs "Home" / **"Agents"** (active), a **"RUNNING"**
   section containing a live task card — **"Saving Stripe to Notion"** with a **"RUNNING"** status pill, status
   line "Notion is connected; I'm checking for the existing database now," and a progress bar — followed by a
   **"TODAY"** section with two more task cards: **"Building coffee website"** (subtitled "# Clicky Child Worker
   Task") and **"Researching Instagram influenc[ers]"** (with a thumbnail of a generated `.csv` file), each with an
   **"Open Agent"** button. A later frame (frame_028) shows the same running-task toast in a more compact form,
   docked top-right near a Gmail "Ask Gemini" button, with updated status text "Routing follow-up through the Clicky
   runtime" — confirming these agent cards can also appear as small persistent toasts outside the full Agents panel.

### Menu-bar / state-label confirmation
Across this video the top status strip cycles through more text states than the other 8 videos combined:
**"Listening"** (~1:44 timestamp on-screen), **"Speaking"** (~1:20 and ~2:22), **"Reasoning"** (~1:19), and
**"Thinking"** is not seen here but appears in video 6 — between the two videos, at least four distinct state labels
are demonstrated (Listening / Speaking / Reasoning / Thinking), more granular than the 4-case
`enum CompanionVoiceState { idle, listening, processing, responding }` in `CompanionManager.swift:17-21` unless
"processing" fans out into "Reasoning"/"Thinking" and "responding" into "Speaking" at the display-string level.

### Real dogfooding artifacts (not staged)
Frames 17–33 show what appears to be genuine internal tooling, not a mockup: a real Gmail inbox thread titled
**"hey clicky"** with an actual bug report from **Arshia Navabi** — *"Clicky currently doesn't work with fullscreen
Google Chrome on Mac. Is this a bug or an upcoming feature? -- App: Clicky 1.0.15, Build: main @ 11020774, macOS
26.3.0, Mac14,9 Apple M2 Pro (arm64)"* — with a reply from "Clicky Support" ("Oh got ya! Clicky is not visible but
you can still talk to it using control+option. Can you check if that works?") and a follow-up from Navabi confirming
it works and requesting "keep the cursor around when full screen." The agent then autonomously creates a **real
Linear ticket** (`CLI-19 "Clicky not working in fullscreen Google Chrome on Mac"`) pre-filled with Reporter,
Issue, Environment (App/Build/macOS/Mac model), and Source-email fields extracted from the thread, and sends a
**real Slack DM** to a teammate named Kamil in a "Humansongs" workspace: *"Hey Kamil, heads up on a bug to track:
Clicky doesn't work in fullscreen Google Chrome on Mac. Reporter is on Clicky 1.0.15, build main @ 11020774, macOS
26.3.0, Mac14,9 Apple M2 Pro. Linear ticket: [link]"* — verbatim matching the ticket just created. This is a legible,
reproducible, real known bug (fullscreen Chrome) being triaged live using the product on itself.

### Production style
Long-form (4 min) talking-head-plus-screen-capture explainer/pitch video, casual living-room setting (leather
couch, brick wall, natural light), single presenter narrating continuously over a mix of macro lifestyle B-roll
(hands on keyboard/trackpad) and full desktop screen recordings. Much more "product demo video" in structure
(problem → mechanism → two live workflows → status check-in → traction stats → CTA) than the other 8 short-form
clips, which lean short-form-social conventions (hooks, captions, quick cuts).

### Overall assessment
This video is the most substantive source in the batch for exactly the UX the task flagged as least understood.
Net-net: the "proactive nudge" is a **dismissible top-of-window toast triggered by passive app/site recognition**,
offering a named integration connection with concrete example actions and a three-choice response, and it's paired
with a broader **notch-centric redesign** (status label, cursor-color picker, and a running/queued agent-task list
with per-task progress and "Open Agent" drill-in) that is materially different from the current shipped
menu-bar-icon-plus-floating-panel architecture. Whether this is an active work-in-progress or an aspirational future
pitch is not settled by the video alone, but the real Linear/Slack/Notion artifacts strongly suggest at least the
agent-execution backend (Notion/Linear/Slack integrations, autonomous multi-step task execution) is real and
working today, even if the notch-shaped front-end shown is conceptual.

---

## Cross-video product/UI findings (synthesis)

- **State labels are real and richer than the shipped enum suggests.** "Listening," "Speaking," "Thinking," and
  "Reasoning" all appear as literal menu-bar text across different videos/builds. Current source
  (`CompanionManager.swift:17-21`) defines only 4 cases (`idle`, `listening`, `processing`, `responding`) — plausible
  the extra labels are display-string variants of `processing`/`responding` depending on context, but worth
  verifying against `CompanionPanelView.swift`/`OverlayWindow.swift` if precise parity matters.
- **The point/annotate-on-screen feature is confirmed in the wild, styled in red, not blue.** Every hand-off
  annotation shown live in the actual app (videos 1, 4, 9) uses a red arrow + red pill label, contradicting
  `DesignSystem.swift`'s documented blue accent (`#2563eb`) for the cursor overlay. Either annotation color is
  independently configurable (video 9's cursor-color picker — red/blue/yellow/green swatches — supports this) or the
  shipped default differs from what's in the current checkout.
- **"Claude Fable 5" is a real, currently-promoted Anthropic model**, corroborated by an actual Claude Code CLI
  banner (video 6) referencing a `support.claude.com` promotional-access article and a specific "50% of weekly usage
  limit until July 7" mechanic — not marketing invention.
- **Skills/Power-Ups marketplace is a real, imminent feature**, independently corroborated by narration (video 5)
  and an actual card UI with per-skill attribution and an "Activate Power-Up" button (video 8).
- **The "proactive nudge" and "notch" redesign (video 9) is not present in the current source tree** — no
  "draw," "spatial context," "proactive," "nudge," or "figma" (feature-specific) hits in a repo-wide grep beyond
  incidental comments — so it should be treated as a preview/concept, not confirmed-shipped, despite the real
  Notion/Linear/Slack artifacts suggesting the agent-execution layer behind it is functioning.
- **Genuine dogfooding, not staged demos, at least in video 9**: real build numbers (`Clicky 1.0.15`, `build main @
  11020774`), a real reporter name, a real internal Slack workspace ("Humansongs"), and a real known bug (fullscreen
  Google Chrome) triaged end-to-end on camera.
- **Two distinct presenter/brand faces recur**: Vikrant (curly hair, glasses — videos 1, 3) and "Farza" (yellow cap,
  glasses, beard — videos 6, 9, and likely 5/8 based on visual match), suggesting a small, consistent on-camera team
  rather than outsourced talent.

## Content-production style synthesis

- **Format split**: short-form vertical hook-driven clips (1, 3, 4, 7) vs. horizontal/mixed vlog-style
  build-in-public content (2, 5, 6, 8) vs. one long-form flagship demo (9).
- **Recurring devices**: word-by-word burned captions (bold sans, white, high-contrast) on nearly every clip; a
  consistent red arrow + pill-label annotation graphic used both as real in-product UI (1, 4, 9) and as
  post-production illustration (1, 3) — the line between "this is the product" and "this is an explainer graphic of
  the product" is deliberately blurred.
- **Hook craft**: video 7 is the clearest viral-hook execution (complaint → escalation → confession → pivot →
  lead-magnet CTA); video 8 is a pure curiosity-gap teaser; videos 5/6 are build-in-public "here's what shipped"
  format, low-hook, high-authenticity; video 2 is pure narrative/origin-story vlog.
- **CTA variety**: "it's live, go check it out" (1), "comment help for the link" (7), "heyclicky.com/july4" livestream
  URL (8), "available right now to try for free" (9) — no single consistent CTA pattern across the campaign.
