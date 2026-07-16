# Clicky Hero Relaunch Demo — Frame Analysis
Video: `FarzaTV_2048203459976188261_0.mp4` — 3840x2160, 3:43 (223s), h264, has audio.

## IMPORTANT CAVEAT UP FRONT

This demo shows a **much leaner UI than the app's current documented architecture** (CLAUDE.md describes a big floating dark `NSPanel` HUD with waveform + response-text bubble + an animated blue cursor overlay that flies/points at UI elements). **None of that appears in this video.** What's on screen instead, consistently, across all three feature demos:

1. A menu-bar icon (purple/violet, top-right of the menu bar) that is the only persistent chrome.
2. A tiny blue waveform glyph that rides next to the literal OS mouse cursor while the user is talking (not a big HUD).
3. A tiny blue/colored triangle glyph that also rides near the cursor at certain moments (agent-spawn / activity ticks) — this is the closest thing to a "mascot cursor," and it is small and subtle, not a large animated companion.
4. A dark rounded **task/result card** anchored top-right of the screen (not centered, not near the cursor) that shows agent status (Running → Done), a plain-language result sentence, "Suggested next" action pills, and "Text"/"Voice" follow-up pills.
5. A blue rounded **toast bubble** (different, simpler component) that also appears top-right pointing back at the menu bar icon, used for a quick inline status message.
6. Small colored circular badges that stack vertically below the menu bar icon, one per concurrently-running agent (status-dot style).

I never observed the big full-screen overlay panel, the arc-animated cursor pointing at specific UI elements, or a large text/waveform bubble following the cursor described in the existing codebase. Whoever rebuilds this should treat the current CLAUDE.md description as the *old*/other design and this video as the **new, minimal relaunch design language**. Flagging this because it's the single most load-bearing fact for a rebuild.

---

## Full spoken narration (verbatim, from transcription)

- **00:00:01–00:00:17** — "Hey everyone. So this is the new version of Clicky. It's the simplest interface in the world for you to interact with models and actually spawn agents. So check this out. I can literally just be here on my computer and I can just tell Clicky, 'Hey Clicky agent, can you clean up these screenshots on my desktop? It's just looking really cluttered.'"
- **00:00:18–00:00:41** — "And this is a really simple use case, but you can see Clicky just created a new version of himself and went off to actually spawn an agent to go do that work, which is cleaning my desktop. And what's cool is I can also hover this thing, I can see what it's doing, and I had just spawned an agent with just my voice, and just like that it cleaned up my desktop."
- **00:00:41–00:01:00** — "And I can pretty much spawn an agent for anything. So I want to show you also another one which I'm which is really cool, which is that Clicky can actually interact with native Apple apps. So I can say, 'Hey Clicky agent, can you set a reminder for me for tomorrow at 9 p.m. to get dinner with Sharif at Buckwan?' And that's it, and it's going to go off and it's going to actually go in the background interact with my native Mac apps"
- **00:01:01–00:01:21** — "and just go do that task for me. I want to show you some other examples here. This is one that's really cool. This is my landing page, right? I can do something, this is one example of where Clicky can do real work for you in a meaningful way."
- **00:01:21–00:01:46** — "'Hey Clicky agent, this is my landing page. You see it. Can you find Instagram influencers for me that are under 50,000 followers? Research the best influencers for my niche. And I want to find people that are like not super famous, but like not not famous because I don't have that much money. So go and find these people and create a CSV of like 25 people that I could reach out to, and maybe tell me have an example DM I could send them as well so they can promote my product.'"
- **00:01:47–00:02:03** — "And just like that Clicky agent's going to go spawn an agent to go to that work now, and actually research people across the web that could potentially market my product for me. And I'll do one more crazy one, because this is also really exciting. Because Clicky is an agent that can run on your computer, that means that it can also build software."
- **00:02:03–00:02:22** — "So I can say something like, 'Hey Clicky agent, can you build a Mac app for me that can control my local Spotify? I'm trying to build like a cool retro-looking record player type Mac app that controls my Spotify, with a play button, shows the song name, all that. Please make that Mac app for me and then launch it on my Mac when you're done.'"
- **00:02:23–00:02:44** — "And just like that it's going to go off and do that now, do that work now as well. And this is super cool because now we have, well now we have two agents that are done and two agents that are still running. So I can look at my agents that are done. So this is the desktop agent. It's done. It cleaned up my screenshots. And here's my reminder agent, so I can open up my reminders, and there's my reminder that I just asked for."
- **00:02:44–00:02:59** — "And for the final two agents, I'm just going to hang around until they're done and then show you. All right, so here's the work that Clicky did for us. It took like five, it's funny, the Mac app took five minutes, the CSV took like 10 minutes. But here's the Mac app. It's a full native Mac app that I built with my voice in one line that could control my Spotify."
- **00:03:01–00:03:22** — "And that's so cool. Like this was all done with just my voice. And here's the CSV with all of the people that I could potentially reach out to to market what I'm working on. And yeah, I could just click whoever, maybe this guy, and seems legit. Seems like an actual person who's like talking about AI and maybe someone that I may want to work with to talk about Clicky, right?"
- **00:03:22–00:03:36** — "And so that's it. And what's really cool is I can keep following up as well. So if I want to add something new to my my Mac app here, I can say something like, 'Oh hey, can you make the background red and make it feel more retro?' And I can now keep building upon more threads of work."
- **00:03:36–00:03:41** — "And so yeah, that's Clicky Agent. Hope you guys have fun with it and yeah, see ya. Bye."
- **00:03:42–00:03:46** (blooper, kept as sign-off) — "Oh man. I'm going to have to do it again tomorrow, but maybe this is fine."

---

## Menu bar icon & invocation

- Sits in the standard macOS menu bar, roughly in the middle of the right-hand icon cluster (left of Wi-Fi/battery/clock, right of a screen-share-style icon). Rendered as a **rounded-square, solid purple/violet** icon (looks close to `#7C5CFC`–`#8A5CF6`), containing a small rectangle/screen glyph.
- **Caveat**: this could plausibly be macOS's own system "screen recording in progress" indicator rather than Clicky's actual app icon, since the video itself is a screen recording — I could not fully disambiguate at the frame resolutions available. Its position is stable across the entire video (00:00:13 → 00:03:37), and its highlight state visibly changes in sync with voice-command/agent moments (e.g. brighter/filled at 00:00:56, 00:02:26, 00:02:41), which is consistent with it being the real app icon reacting to state.
- No hotkey is shown/heard being pressed on-camera in this cut — the presenter always speaks the phrase "**Hey Clicky agent, …**" directly into a hot mic; there's no visible click on the icon before each command triggers. This suggests background/always-listening or a keyboard shortcut done off-screen, not demonstrated visually. (No push-to-talk key-press visual, unlike the CLAUDE.md's push-to-talk architecture — worth clarifying with the team whether this cut is voice-activated-by-keyword ("Clicky agent") rather than PTT.)

## Floating HUD/panel — there isn't a big one; there are three small components

### 1. Listening indicator (during speech)
- 00:02:03–00:02:20: a tiny **blue vertical-bar waveform glyph** (~4 short bars) appears directly to the right of the normal macOS arrow cursor, floating with no background/card — just the glyph itself, blue (~`#3B82F6`/`#4C8DFF`).
- No visible mic-level animation beyond bar-height variation; it's subtle, not a big pulsing panel.

### 2. Cursor-adjacent triangle glyph ("mascot" equivalent)
- 00:00:18–00:00:21 (zoomed at 1600px): a small solid **blue right-pointing triangle** (looks like a rotated "play" icon) sits just below/right of the OS arrow cursor. Recurs at 00:02:21–00:02:24 and 00:03:10 in a similar cursor-adjacent position, sometimes blue, once briefly yellow-ish at 00:02:20/00:02:21.
- This is the closest analog to the "blue cursor overlay" in the current codebase, but it's tiny (roughly cursor-glyph sized) and doesn't appear to fly/arc toward UI elements in this cut — it just rides near the pointer.

### 3. Status badge stack
- 00:02:20–00:02:24 and 00:02:31–00:02:41: small filled **circular badges stack vertically** just under/right of the menu bar icon — colors observed: yellow/orange, red, blue, green, roughly one per concurrently active/finished agent. Reads as a lightweight "how many agents, what state" indicator, not a list UI.

## Agent result / task card (the actual "hover to see progress" UI)

This is the real workhorse component, appearing 3 times, always same layout, anchored **top-right** of the screen, dark near-black rounded card:

- **00:00:29** (mid-run): header **"ORGANIZE DESKTOP SCREE…"** (truncated caps title) + green **"Running"** pill top-right. Body shows a monospace shell command being executed: `ls -1 ~/Desktop/Desktop Screenshots | sed -n '1,40p'`.
- **00:02:30–00:02:35** (done): header **"ORGANIZE DESKTOP SCREE…"** + green **"Done"** pill. Body: *"Your Desktop screenshots are cleaned up and moved into Desktop Screenshots."* Then a **"Suggested next"** label with two pill buttons: **"Open Desktop Screenshots"** / **"Tidy the other desktop files"**. Then a **"Follow up"** label with two pill buttons: **"Text"** (icon "A") / **"Voice"** (mic icon).
- **00:02:34–00:02:35**: same card format, header **"SET DINNER REMINDER"** + green **"Done"**. Body: *"Your reminder is set for Friday, April 24 at 9:00 PM to get dinner with Sharif at Pakwan."* Suggested next: **"Open Reminders"** / **"Show tomorrow's reminders"**. Follow up: Text/Voice, same layout.
- **00:03:22–00:03:27**: header **"BUILD SPOTIFY MAC"** + green **"Done"**. Body: *"Your retro Spotify app is built and open on your Mac as SilverDisc; if macOS asks, allow Spotify access so the controls work."* Suggested next: **"Open the app folder"** / **"Add album art"**. Follow up: Text/Voice.

Design notes on the card: dark charcoal/near-black background, generous rounded corners, header row is bold small-caps task title + right-aligned colored status pill (green fill for Done; presumably a different color, likely blue, for Running based on the one glimpse at 00:00:29 — the pill itself read green there too, so "Running" may also be green, just labeled differently), body copy in white/light gray sentence case, section labels ("Suggested next", "Follow up") in small dim gray caps, action buttons are dark-gray filled capsule/pill shapes with white text, follow-up row uses two icon+label pills side by side. This card component visibly **doubles as the "continue this thread" surface** — at 00:03:22 the same "BUILD SPOTIFY MAC / Done" card re-appears when the user says "make the background red," which is how the transcript's "I can now keep building upon more threads of work" (00:03:22–00:03:36) is expressed visually — no separate chat window, the same result card is the follow-up entry point via its Text/Voice pills.

## Completion toast (separate, smaller component)

- **00:00:41–00:00:47**: a solid **blue rounded rectangle bubble**, white text, appears top area near the menu bar icon with a small pointer/tail connecting toward the icon: *"Your Desktop screenshots are cleaned up and moved into Desktop Screenshots."* (Same copy as the task-card body, but delivered as an ephemeral toast first, before/alongside the persistent card.) Blue looks close to iMessage blue, ~`#2F6FED`–`#3B82F6`.

## Voice interaction flow, summarized

1. **Listening**: tiny blue waveform glyph next to cursor (00:02:03–00:02:20 window while dictating the Spotify-app request).
2. **Spawning/processing**: cursor-adjacent triangle glyph appears (00:00:18–21, 00:02:21–24), plus a colored status badge gets added to the stack near the menu bar icon.
3. **Running**: task card shows title + "Running" pill + live shell command text (00:00:29).
4. **Responding/Done**: blue toast bubble fires first (00:00:43–47), task card flips to "Done" pill with a plain-English result sentence + suggested-next + follow-up pills (00:02:30–35, 00:03:22–27).

No large mascot, no pointing-at-elements animation, and no dedicated chat transcript panel were visible anywhere in this cut.

## Every distinct feature demonstrated

1. **Desktop cleanup agent** (00:00:01–00:00:47): voice command → agent runs a shell `ls`/sort over `~/Desktop/Desktop Screenshots` → screenshots get corralled into a `Desktop Screenshots` folder (macOS desktop icon-grid visibly less cluttered at 00:00:22 vs 00:00:13) → task card "Done" + blue toast confirming.
2. **Native Reminders integration** (00:00:47–00:01:00, reveal at 00:02:36–02:39): voice command sets a reminder → task card "SET DINNER REMINDER / Done" → cut to native macOS **Reminders.app** (dark mode) showing the created reminder: **"Get dinner with Sharif at Pakwan"**, subtext "Dinner with Sharif at Pakwan / Tomorrow, 9:00 PM," unchecked circle checkbox, red "1" badge in the sidebar's "Scheduled" tile. (A stray system toast "You won't be notified when reminders are due / Go to System Settings" also appears, unrelated to Clicky — a real macOS notification-permission nag.)
3. **Instagram micro-influencer research → CSV** (00:01:21–00:01:47, reveal 00:03:01–00:03:21): voice request while looking at the presenter's own landing page in Chrome → agent researches and produces a spreadsheet. Reveal shows **Apple Numbers** (dark mode) with a table titled **`clicky_instagram_micro_influencers`**, columns: `priority, name, instagram_handle, followers, profile_url, niche_segment, why_they_fit_clicky` (7th column may include an outreach-DM example per the ask, cut off-screen). Rows include handles like `riano_digitals`, `lukesbrave`, `sicknider.raw`, `stevenshoaf`, `samalytics`, `mpaige13`, `ellelegare`, `gfx_ma`, `ai.with.andrew`, follower counts in the 10K–200K range, niche tags like "Marketing automation / chatbots," "AI tools / automations," "Build-with-AI creator," "Voice AI founder," and short justification strings like "Strong fit for Clicky AI audience," "Good low-cost creator." Numbers' right-hand "Table Styles" inspector is open (dark-theme swatches selected). Presenter then clicks through to a real Instagram profile, `nicholas.puru` ("Nick Puroczky | AI Automation," 35.2K followers, Reels about "Claude Code," "5 Secret Codes for Claude/ChatGPT") to validate the lead.
4. **"Build me a Mac app" — SilverDisc retro Spotify controller** (00:02:03–00:02:22, reveal 00:02:42–00:03:37, tweak request 00:03:22–00:03:36): voice request for a "retro-looking record player" Spotify controller → agent builds and launches a real native Mac app window named **SilverDisc**. Full app description below. Follow-up voice request ("make the background red, more retro") is issued through the same result card's Voice pill, demonstrating iterative/threaded builds.
5. **Multi-agent concurrency / "agents that are done vs still running"** (00:02:22–00:02:44): presenter narrates checking on 4 agents at once (2 done: desktop cleanup + reminder; 2 still running: CSV research + Mac app build) — visualized only via the colored badge stack near the menu bar, not a dedicated agent-list window.

## SilverDisc Mac app — full visual spec (00:02:42–00:03:37)

Native macOS window, standard traffic-light buttons top-left. Two-column layout inside one window:
- **Left panel**: wordmark **"SilverDisc"** top-left, **"HOLD"** label top-right (looks like a physical-media metaphor label, maybe a hold/lock toggle). Center: a **circular vinyl record** graphic — amber/gold disc (~`#E0A23D`) with a dark center label showing curved text "SILVERD… / FIRST OF THE / YEAR (EQU…)" and a diagonal tonearm/needle line from upper-right pivot to the disc edge. When playing (00:02:56–58) the disc shows motion-blur/spin cues and a **"SPIN"** label. Below the disc: transport row — prev (dark rounded-square icon) / **large amber-gold circular play button** with a triangle icon / next (dark rounded-square icon). When playing, the center button becomes a pause icon, same amber-gold fill.
- **Right panel**: header **"LOCAL SPOTIFY LINK"** + a status pill that toggles **orange "Paused"** ↔ **green "Now Spinning"** (with a tiny spin icon) depending on playback state. Song title in bold white: **"First of the Year (Equ[al Vision])"**, artist in gray: **"Skrillex • More Monsters and [Sprites]"**. **"TRACK TIMER"** label above a monospace/digital green readout, e.g. **"0:49 / 4:21"** (green ~`#3ED598`, LED/digital-clock font), with a thin green progress bar beneath that fills as the track plays (0:49→0:52 observed). **"DISC"** label with right-aligned state word ("PAUSED"/"PLAYING"). Two pill buttons: **"Open Spotify"** and **"Reconnect"**. **"OUTPUT"** section with a horizontal slider/toggle reading **"95"** (volume). **"NOTES"** section with rotating italic/gray helper copy, e.g. *"Press play and the disc sta[rts spinning]"* / *"The disc motion mirrors t[he track]."*

Palette: near-black charcoal background (~`#17171A`), amber/gold primary accent (~`#E0A23D`) for the play button and disc, green/teal accent (~`#3ED598`) for the digital timer/progress bar and the "Now Spinning" pill, orange for "Paused." Typography: bold sans title, monospace/digital-style numerals for the timer, small gray caps for section labels — an intentionally retro hi-fi/skeuomorphic language (record player, VU-style readouts) rendered with flat modern surfaces, not literal skeuomorphism.

## Response text, typography, colors — general

- Task-card and toast copy is plain-language sentence case, white/light-gray on near-black or on solid blue.
- No streaming-text effect was visually distinguishable at this frame sampling rate (cards/toasts appear fully formed between sampled frames); can't confirm/deny char-by-char streaming without denser sampling.
- Landing page (heyclicky.com, shown 00:01:55–00:02:25) typography: small gray tracked-out caps eyebrow **"MEET CLICKY"**, then a large, bold, tight-tracked sans-serif headline in near-black: **"an ai buddy that lives on your mac."** (lowercase, no period-emphasis styling beyond size). Body paragraph beneath, legible at 00:01:57–02:00 (2048px frame): *"Clicky sits right next to your cursor and sees everything you see, ask a question out loud and it walks you through whatever you're working on, or say 'clicky agent' and it'll spin up an agent to build, research, or do whatever for you in the background."* Below that: a rounded input field + a dark filled pill **"download"** button side by side, and two gray example-prompt chips: **"How do I color grade this in davinci resolve?"** and **"clicky agent, build me a snake game."** Page background white, headline/body near-black, on a blue browser chrome (Chrome itself, not app-related).

## Animations & transitions

- Card/toast entrances read as quick fades/slides from the top-right corner — sampling density (~0.3–2fps) is too coarse to characterize exact easing curves; nothing looked like a large spring-bounce given how compact the motion is.
- SilverDisc's record graphic shows a rotation/spin cue tied to play state (00:02:56 "SPIN" label + blur), and the progress bar fills linearly.
- The task-card "Suggested next"/"Follow up" pills appear simultaneously with the body text, not staggered, at the sampling resolution available.
- Desktop icon reorganization (00:00:13→00:00:22) happens off-camera between sampled frames — icons are already consolidated by the time the "Running" card shows; can't confirm a fly-into-folder icon animation, though a folder badge/highlight pulse is visible on the "Desktop Screenshots" folder icon at 00:02:30–33.

## Onboarding/setup

None shown in this cut — the video jumps straight from the desktop-cleanup demo into the landing page as a "here's my landing page" example (00:01:00), not an onboarding flow. No permission prompts, no first-run screen, no download/install sequence shown (the landing page's "download" button appears but is never clicked on camera).

## Color palette (best-guess hex from frames)

| Role | Approx hex | Where seen |
|---|---|---|
| Menu bar icon / brand purple | `#7C5CFC`–`#8A5CF6` | menu bar, all scenes |
| Toast / listening waveform blue | `#3B82F6`–`#2F6FED` | 00:00:43 toast, 00:02:03 waveform |
| Status "Done"/"Running" green | `#34C759`-ish (Apple green) | task cards |
| SilverDisc amber/gold accent | `#E0A23D` | 00:02:47 play button, disc |
| SilverDisc green digital readout | `#3ED598` | 00:02:47 timer/progress bar |
| SilverDisc background | `#17171A` | 00:02:47 app window |
| Landing page headline/body | near-black `#111111` on white | 00:01:57 |

Fonts: system UI sans throughout (San Francisco-esque) for macOS-native surfaces and the task cards; landing page headline is a bold geometric/grotesk sans (bigger, tighter tracking than system UI — could be a custom web font, not legible enough to name); SilverDisc's timer uses a monospace/digital-styled numeral face distinct from the rest of its UI.

## Production notes

- **Hook** (00:00:00–00:00:02): opens on a literal **camera-viewfinder overlay** graphic (AF-C focus mode, ISO 100, F4.0, 1/60 shutter, battery icon, crosshair focus brackets) framing the presenter's face through a fake "lens" — a meta behind-the-scenes framing device — before hard-cutting to the real talking-head shot at 00:00:03.
- **Talking head cam**: presenter in a green cap and glasses, seated at a round table by a bright window, DSLR-on-tripod visible in-frame at wide shots (00:00:09, 00:01:45, 00:02:45, 00:03:37); a second person is visible in the background on a couch/bed throughout, occasionally glancing at a phone/laptop — adds a casual, unstaged, roommate-vibe production feel.
- **Screen-recording cuts**: every feature demo cuts from the talking-head cam to a desktop screen-recording with the presenter's webcam picture-in-picture inset (varies position: bottom-right small, later floats near wherever's relevant).
- **Structure**: hook → "simplest interface" claim → demo 1 (desktop cleanup, quick/low-stakes) → demo 2 (Reminders, native-app proof point) → demo 3 (IG research CSV, "real work" claim) → demo 4 (build a Mac app, the "crazy one") → concurrency beat (checking on 4 agents) → reveal demo 2 native app → reveal demo 4 built app + demo 3 CSV → live playback proof (hits play on SilverDisc, confirms real Spotify control) → live web-validation of one CSV lead (clicks into an Instagram profile) → follow-up/iteration proof (asks for a UI tweak on the same thread) → sign-off → blooper stinger (silly dance + "gotta do it again tomorrow" outtake) as the button.
- **Pacing**: each demo command is spoken in one continuous take with no visible cuts mid-sentence — deliberately showing the raw, un-edited "just talk" simplicity claim. No captions/on-screen text overlays were present anywhere except native OS/app chrome — this is a clean, caption-free demo cut (a captioned version, if any, is not this file).
- **No music/SFX cues were inferable from the visual analysis** (no audio waveform/loudness filter was run); transcription suggests continuous natural speech with no obvious voiceover-over-music structure.

---

## Timestamp index (for quick re-reference)
- 00:00:00–02 — camera viewfinder hook
- 00:00:03–17 — intro, first voice command
- 00:00:13–22 — desktop full of screenshot files (before)
- 00:00:22–29 — desktop consolidating; "Running" task card first appears (00:00:29)
- 00:00:41–47 — blue toast "Desktop screenshots cleaned up…"
- 00:00:47–01:00 — reminder voice command, listening waveform + triangle glyph
- 00:01:05–01:47 — heyclicky.com landing page shown, full copy legible ~00:01:57–02:01
- 00:02:03–02:22 — Mac-app-build voice command, listening waveform visible
- 00:02:20–02:24 — status badge stack appears near menu icon
- 00:02:25–02:42 — top-left "camera control"-style dock panel cycles idle→green (ambiguous whether Clicky's or system Continuity Camera controls)
- 00:02:30–02:35 — "Organize Desktop" and "Set Dinner Reminder" Done cards
- 00:02:36–02:39 — Reminders.app reveal
- 00:02:42–03:37 — SilverDisc app + Numbers CSV reveal, live playback, Instagram profile check, follow-up card
- 00:03:22–03:27 — "Build Spotify Mac / Done" card reappears for the follow-up tweak request
- 00:03:37–03:41 — sign-off
- 00:03:42–03:46 — blooper stinger
