---
name: launch-playbook
version: 0.1.0
description: Produce founder-led product launch content that actually spreads — flagship demo videos, a product-as-mascot social channel, and the campaign cadence that ties them together. Reverse-engineered from a real launch that repeatedly hit 5k–14k likes. Use when writing a launch tweet or thread, scripting a product demo or launch video, planning a ship-day post, building a recurring social presence for a product, or critiquing a draft demo for pacing/hook/structure.
triggers:
  - launch video
  - product demo video
  - ship day post
  - launch tweet
  - demo script
  - product launch content
  - mascot account
  - how do i announce this feature
---

# Launch Playbook

How to make a product launch that spreads. Distilled from a real founder-led
campaign (see `references/teardown.md` for the evidence and the numbers). The
core insight: **run two voices in parallel** — a founder flagship channel that
ships authority, and a product-as-character channel that ships personality —
and **ship exactly one crisp new primitive per flagship drop.**

## The dual-channel system

Don't run one account trying to be both credible and charming. Split it.

- **Founder flagship** (high reach): "Today we're shipping X." 4K landscape,
  one un-cut live demo, escalating stakes. This is where the big numbers come
  from — it earns attention with a real capability shown working.
- **Product-as-mascot** (personality + cadence): post *as the product*, first
  person, a diary voice — "i am being fixed", "i wanna help you make music",
  "i am celebrating $10k mrr at a gas station". Vertical clips. This keeps the
  brand alive between flagship drops and makes people *like* it, not just
  respect it. Lower individual reach, compounding affection.

The flagship makes people believe. The mascot makes people root for you.

## The flagship hook formula

Every high-performing flagship demo follows this spine. Use it.

1. **Bold claim, stated flat.** "We built an AI that can draw on your screen."
   No throat-clearing. First 2 seconds.
2. **Name the crowd.** "Many products already do this." Say it out loud — it
   disarms the skeptic and raises the stakes for your differentiation.
3. **"So we went further."** The pivot. This one line is the whole video's
   engine — it promises the thing they haven't seen.
4. **The magic, shown live and un-cut.** Real screen, real latency, real
   result. Escalate: fun → useful → high-stakes (music → volume → revenue).
   One continuous take per command sells the "just talk" simplicity.
5. **Candid close.** "It's live. It's a little buggy, but we ship every day."
   The admission builds more trust than a polished CTA.

Ship **one** new primitive per flagship. The campaign in the teardown laddered
its reveals — pointer → drawing → spatial context → dictation — so each drop
earned the next. Resist bundling features; a single sharp capability travels
further than a feature list.

## The mascot voice

Write the product account as a slightly naive, earnest character narrating its
own life. Rules:
- First person, lowercase, present tense. Short.
- Milestones become feelings, not announcements: not "v2.1 released" but
  "my creators are upgrading me."
- Let it be vulnerable ("i am being fixed") and let it celebrate small
  ("celebrating $10k mrr at a gas station"). Relatability > polish.
- The mascot demos a feature by *wanting* to help, not by listing specs.

## Production craft (what the frames show)

- **Format split**: 4K landscape for founder demos; 1080×1920 vertical for
  mascot/social. Frame widescreen shots inside a vertical-safe center column so
  one shoot repurposes to both.
- **Unify the demos visually.** Composite every app screen-recording as an
  inset window (rounded corners, drop shadow) over ONE consistent backdrop.
  Wildly different apps then read as a single product world.
- **Captions**: karaoke style, 3–6 word chunks, cut in sync with speech, bold
  sans, no box — a drop shadow for legibility. Built for sound-off feeds.
- **Pacing**: brisk 1–3s cuts, alternating talking-head and screen B-roll.
- **State on screen**: if the product has states, show them at the OS-chrome
  level (a menu-bar label flipping to "Listening"/"Speaking") — it reads as
  real software, not a mockup.
- **Open on the most characteristic moment**, not a logo. A viewfinder overlay,
  a hand drawing on a chalkboard, the product doing its one weird trick.

## The repeatable process

1. **Pick the one primitive.** What can this drop show that nobody has seen?
   If you can't say it in one sentence, it's not ready to launch.
2. **Write the hook first** (steps 1–3 above), then script the demo backward
   from the payoff.
3. **Script the demo as spoken commands**, one continuous take each. Rehearse
   until the live run is clean — the un-cut take is the proof.
4. **Record**: talking-head cold open → screen-recording insets over the shared
   backdrop → live payoff → candid close.
5. **Cut** to the pacing above; add karaoke captions; end on a plain wordmark.
6. **Post**: flagship on the founder account with "Demo:" ; clip a vertical
   mascot cut for the product account; keep the mascot cadence going daily.

## Studying reference videos

To learn from a launch you admire, watch it frame-by-frame, not just once:
use the video-vision tooling (`watch-video` / the video-vision MCP) to pull the
transcript + sampled frames, then extract: the exact hook wording and timing,
the reveal order, the caption cadence, the shot structure, and how state/results
are shown on screen. `references/teardown.md` is a worked example of this.

## Anti-patterns

- Feature lists in one video. Ship one primitive.
- Polished, over-produced demos that hide latency — the raw take is the trust.
- A single account trying to be both authoritative and cute.
- Ending on a hard CTA instead of a candid, human close.
- A logo-first open. Lead with the trick.
