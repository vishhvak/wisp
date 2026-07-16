# Clicky

An AI buddy that lives on your Mac. It sits next to your cursor and sees what
you see — ask out loud and it walks you through what you're doing, or say
"clicky agent" and it spins up a background agent to build, research, or act
for you.

This is a **clean-room rebuild** of the demonstrated Clicky experience: menu-bar
companion, push-to-talk voice, an on-screen teaching overlay, task cards for
background agents, and screen-aware dictation. It was rebuilt from scratch by
studying the public launch demos and the shipped app's *observable* behavior —
**no proprietary source code was copied.**

## Layout

```
Clicky/          SwiftUI macOS app (SwiftPM) — menu bar, overlay, voice, task cards
worker/          Cloudflare Worker proxy — /chat (Claude), /tts (Inworld→ElevenLabs)
voice-sidecar/   Local Parakeet TDT 0.6B v3 STT sidecar (Python, Apple Silicon)
research/        Reverse-engineering + frame-by-frame demo analysis + DESIGN.md
workspace/       Living HTML workspace documenting the whole rebuild
skills/          launch-playbook — a reusable content-production skill
```

## Build

**App** (needs Swift 6+; full runtime needs macOS permissions granted in
System Settings — Screen Recording, Microphone, Accessibility):

```bash
cd Clicky && swift build && swift run
```

**Worker proxy** (holds all API keys as Cloudflare secrets):

```bash
cd worker && npm install
npx wrangler secret put ANTHROPIC_API_KEY
npx wrangler secret put INWORLD_API_KEY
npx wrangler secret put ELEVENLABS_API_KEY
npx wrangler deploy
```

**Voice sidecar** (local STT):

```bash
cd voice-sidecar && pip install -r requirements.txt && python parakeet_stt.py
```

## Design

The full design language, architecture, and the reasoning behind every decision
live in [`research/DESIGN.md`](research/DESIGN.md), and the browsable workspace
is in [`workspace/index.html`](workspace/index.html). Default model: Claude
Fable 5. Voice: Parakeet-local STT + Inworld (fallback ElevenLabs) TTS, proxied.

## Credits

Clicky is an original product by [@FarzaTV](https://x.com/FarzaTV) /
[@heyclicky](https://x.com/heyclicky). This repository is an independent,
educational, from-scratch reconstruction of the *demonstrated experience* and is
not affiliated with or derived from the original source code.

## License

MIT — see [LICENSE](LICENSE).
