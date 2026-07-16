/**
 * Wisp Proxy Worker
 *
 * The Mac app never holds API keys. Everything sensitive lives here as
 * Cloudflare secrets. Routes:
 *   POST /chat  -> Anthropic Messages API (Claude, streaming SSE passthrough)
 *   POST /tts   -> Inworld TTS (Kurzgesagt voice); falls back to ElevenLabs
 *
 * Optional light guard: if CLIENT_TOKEN is set, requests must send
 * `Authorization: Bearer <CLIENT_TOKEN>`. Keeps the proxy from being an
 * open faucet to paid APIs. ponytail: shared-secret, not per-user auth —
 * swap for real auth if this ever ships to many users.
 */

interface Env {
  ANTHROPIC_API_KEY: string;
  INWORLD_API_KEY: string;
  INWORLD_VOICE_ID: string;
  ELEVENLABS_API_KEY: string;
  ELEVENLABS_VOICE_ID: string;
  CLIENT_TOKEN?: string;
}

const INWORLD_TTS_MODEL = "inworld-tts-2";

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (request.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }
    if (env.CLIENT_TOKEN) {
      const auth = request.headers.get("authorization");
      if (auth !== `Bearer ${env.CLIENT_TOKEN}`) {
        return new Response("Unauthorized", { status: 401 });
      }
    }

    try {
      if (url.pathname === "/chat") return await handleChat(request, env);
      if (url.pathname === "/tts") return await handleTTS(request, env);
    } catch (error) {
      console.error(`[${url.pathname}] Unhandled error:`, error);
      return json({ error: String(error) }, 500);
    }
    return new Response("Not found", { status: 404 });
  },
};

/** Pass the Anthropic Messages request through untouched; stream the SSE body back. */
async function handleChat(request: Request, env: Env): Promise<Response> {
  const body = await request.text();
  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": env.ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
      "content-type": "application/json",
    },
    body,
  });

  if (!response.ok) {
    const errorBody = await response.text();
    console.error(`[/chat] Anthropic error ${response.status}: ${errorBody}`);
    return new Response(errorBody, { status: response.status, headers: { "content-type": "application/json" } });
  }

  return new Response(response.body, {
    status: response.status,
    headers: {
      "content-type": response.headers.get("content-type") || "text/event-stream",
      "cache-control": "no-cache",
    },
  });
}

/**
 * Body: { "text": "...", "voiceId"?: "..." }
 * Tries Inworld first (returns base64 audioContent), decodes to audio/mpeg.
 * On any Inworld failure, transparently falls back to ElevenLabs so a bad
 * Inworld key / SESSION_PAUSED never kills the voice.
 */
async function handleTTS(request: Request, env: Env): Promise<Response> {
  const { text, voiceId } = (await request.json()) as { text?: string; voiceId?: string };
  if (!text || !text.trim()) return json({ error: "text is required" }, 400);

  const inworldVoice = voiceId || env.INWORLD_VOICE_ID;
  if (env.INWORLD_API_KEY && inworldVoice) {
    try {
      const audio = await inworldTTS(text, inworldVoice, env.INWORLD_API_KEY);
      if (audio) return new Response(audio, { status: 200, headers: { "content-type": "audio/mpeg" } });
    } catch (error) {
      console.error("[/tts] Inworld failed, falling back to ElevenLabs:", error);
    }
  }
  return await elevenLabsTTS(text, env);
}

async function inworldTTS(text: string, voiceId: string, apiKey: string): Promise<ArrayBuffer | null> {
  const response = await fetch("https://api.inworld.ai/tts/v1/voice", {
    method: "POST",
    headers: { authorization: `Basic ${apiKey}`, "content-type": "application/json" },
    body: JSON.stringify({ text, voiceId, modelId: INWORLD_TTS_MODEL }),
  });
  if (!response.ok) {
    console.error(`[/tts] Inworld error ${response.status}: ${await response.text()}`);
    return null;
  }
  const data = (await response.json()) as { audioContent?: string };
  if (!data.audioContent) return null;
  return base64ToBytes(data.audioContent);
}

async function elevenLabsTTS(text: string, env: Env): Promise<Response> {
  const response = await fetch(
    `https://api.elevenlabs.io/v1/text-to-speech/${env.ELEVENLABS_VOICE_ID}`,
    {
      method: "POST",
      headers: { "xi-api-key": env.ELEVENLABS_API_KEY, "content-type": "application/json", accept: "audio/mpeg" },
      body: JSON.stringify({ text, model_id: "eleven_flash_v2_5" }),
    }
  );
  if (!response.ok) {
    const errorBody = await response.text();
    console.error(`[/tts] ElevenLabs error ${response.status}: ${errorBody}`);
    return new Response(errorBody, { status: response.status });
  }
  return new Response(response.body, { status: 200, headers: { "content-type": "audio/mpeg" } });
}

function base64ToBytes(b64: string): ArrayBuffer {
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

function json(obj: unknown, status: number): Response {
  return new Response(JSON.stringify(obj), { status, headers: { "content-type": "application/json" } });
}
