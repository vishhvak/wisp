# Repo, Voice & Infra Findings (verified)

## Current clicky repo (the EARLIER snapshot — to be replaced)
Preserve these *research patterns* (not code) for the clean rebuild:
- Pluggable STT session abstraction (provider protocol: AssemblyAI / OpenAI / Apple).
- Single shared `URLSession` across all streaming sessions (never recreate per session — OS connection-pool corruption otherwise).
- Short-lived Worker-minted tokens (client never holds API keys).
- Multi-display screenshot capture + coordinate conversion.
- `[POINT:x,y:label:screenN]` pointing protocol + quadratic Bézier flight/return animation for the cursor.
Skip/ignore: unreferenced legacy paths (`ElementLocationDetector`, `OpenAIAPI`, `CompanionResponseOverlayManager`).

## Voice reference — CORRECTED (verified from source)
The user's pointer to `~/Repos/whoami` was off. **whoami is a personal life-wiki ("whoami.wiki"), with ZERO voice/TTS/STT code.** A subagent HALLUCINATED a whoami voice stack (Silero+Deepgram+Inworld-via-LiveKit); that is fabricated — ignore it. The REAL voice implementation is:

**`~/Repos/projects/claude-voice`** (= the `voice` Claude skill; a Claude Code voice daemon). Verified from its `.env` and `voice-cfg.sh`:
- **STT: Parakeet TDT 0.6B v3, local on Apple Silicon** (`parakeet-mlx`) + **Silero VAD** + **Pipecat Smart Turn V3** (end-of-turn detection). ~600MB model download. (No Deepgram, no LiveKit anywhere.)
- **TTS: switchable Inworld ⇆ ElevenLabs.** Currently `TTS_PROVIDER=inworld`.
  - Inworld: `INWORLD_VOICE_ID=default-gv-cgitsgv4b40lhxxqpza__kutz` (Kurzgesagt clone, "kutz"), model `inworld-tts-2`. REST API `https://api.inworld.ai/tts/v1`. Instant voice cloning (IVC) endpoint `voices:clone` accepts ≤60s / ≤12MB WAV/MP3.
  - ElevenLabs fallback voice: `aJxmRyDvcRx8qVUaBKM6`.
  - Cloned Kurzgesagt source audio lives at `claude-voice/cloning/final/kurzgesagt_60s.wav`.
  - API keys in `claude-voice/.env` (INWORLD_API_KEY, ELEVENLABS_API_KEY) — do NOT commit.
- Architecture: TTS runs via a Claude Code **Stop hook** → provider → `afplay`. `tts-helper.py`, `voice-daemon.py`, `providers/{inworld,elevenlabs}.md`.

### Voice plan for the rebuild (native macOS app)
- **STT: local Parakeet TDT 0.6B v3** via parakeet-mlx. In a Swift app this needs a Python sidecar/helper process (parakeet-mlx is Python/MLX). Fallback: Apple `SFSpeechRecognizer` / OpenAI whisper.
- **TTS: Inworld** REST (Kurzgesagt voice id above), model inworld-tts-2, initially; fallback ElevenLabs → OpenAI TTS → macOS `AVSpeechSynthesizer`.
- Keys must be proxied (Cloudflare Worker), never shipped in the app — matches the shipped Clicky's proxy pattern.
- Graceful degradation is a hard requirement (mic/permission/local-model/network unavailability).

## Credentials available (NEVER commit/expose — presence only)
- Vercel: `~/.config/vercel/auth.json` (vca_) → AI Gateway usable.
- Supabase: `~/.config/supabase/pat` and `pat-vishhvak` (sbp_) → free-tier project provisionable.
- Railway: personal.token (65a5) + others.
- Env (this session): `OPENAI_API_KEY` (sk-pr…) and a Gemini key are set.
- Not found in ~/.config: Inworld / Anthropic keys (Inworld key must be sourced separately, e.g. whoami's config or env, before TTS works).

## Model
- Clicky's shipped default model is **Claude Fable 5** (per Jul 2 tweet). Rebuild should target Claude Fable 5 via the proxy/gateway; Opus for the drawing/pointing (tutor) path per the Jun 16 tweet.
