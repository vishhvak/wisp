# Wisp

A little light that lives on your Mac. Wisp sits next to your cursor and sees
what you see — ask out loud and it walks you through what you're doing, drawing
directly on your screen; or hand it a task and it works in the background,
reporting back on a small card.

Named for the will-o'-the-wisp: a floating light that guides travelers. That's
the whole product — a tiny glowing companion that glides to the thing you
should look at next.

Wisp is a **clean-room study**: it reconstructs the experience demonstrated in
the public launch videos of [Clicky](https://x.com/heyclicky) (by
[@FarzaTV](https://x.com/FarzaTV)), rebuilt from scratch by analyzing 24 launch
tweets, 23 demo videos frame-by-frame, and the shipped app's *observable*
behavior. **No proprietary source code was copied.** The full research corpus —
including the design language every pixel here derives from — lives in
[`research/`](research/).

## What's here

```
Wisp/            SwiftUI macOS app (SwiftPM) — notch HUD, cursor glyph, bezier
                 agent pointer, teaching ink, task cards, voice engine
worker/          Cloudflare Worker proxy — /chat (Claude), /tts (Inworld→ElevenLabs)
voice-sidecar/   Local Parakeet TDT 0.6B v3 STT sidecar (Python, Apple Silicon)
research/        The reverse-engineering + frame-by-frame demo analysis + DESIGN.md
workspace/       Living HTML workspace documenting the whole rebuild
skills/          launch-playbook — a reusable content-production skill
```

## The experience

- **Talk to it** — hold ⌃⌥ and speak. Wisp screenshots your displays, asks
  Claude, and answers out loud (Inworld TTS) while a tiny glyph beside your
  cursor shows listening / thinking / speaking.
- **It draws on your screen** — responses can carry `[TARGET]`, `[HOVER]`,
  `[HIGHLIGHT]`, `[SHAPE:arrow]`, `[SHAPE:curve]` tags; Wisp's pointer glides
  along a bezier arc to each new annotation, ripples on landing, and the red
  teaching ink accumulates into a legend, chip by chip.
- **Notch HUD** — a slim pill hangs from the camera notch showing state, the
  live transcript while you speak, and the response line (auto-dismissing).
- **Task cards** — background work reports into dark top-right cards with
  status pills, a result sentence, suggested next actions, and Text/Voice
  follow-ups.

## Build

**App** (Swift 6+; runtime needs Microphone, Screen Recording, and
Accessibility granted in System Settings):

```bash
cd Wisp && swift build && swift run
```

**Worker proxy** (holds all API keys as Cloudflare secrets):

```bash
cd worker && npm install
npx wrangler secret put ANTHROPIC_API_KEY
npx wrangler secret put INWORLD_API_KEY
npx wrangler secret put ELEVENLABS_API_KEY
npx wrangler deploy
```

**Voice sidecar** (local STT, ~600MB model on first run):

```bash
cd voice-sidecar && pip install -r requirements.txt && python parakeet_stt.py
```

## Design

The complete design language — palette, the three-state cursor glyph, the task
card anatomy, the two drawing languages, invocation gestures — is documented in
[`research/DESIGN.md`](research/DESIGN.md), with the browsable workspace at
[`workspace/index.html`](workspace/index.html). Default model: Claude Fable 5.
Voice: local Parakeet STT + Inworld TTS (ElevenLabs fallback), all proxied.

## Credits

The product concept and demonstrated experience belong to Clicky
([@heyclicky](https://x.com/heyclicky) / [@FarzaTV](https://x.com/FarzaTV)).
This repository is an independent, educational, from-scratch reconstruction and
is not affiliated with or derived from the original source code.

## License

MIT — see [LICENSE](LICENSE).
