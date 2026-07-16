#!/usr/bin/env python3
"""Parakeet speech-to-text warm daemon for Wisp.

Launched ONCE at app startup by the Swift app (Sources/Wisp/Voice/TranscriptionProvider.swift) and
kept alive for the app's whole life. The expensive part — loading the Parakeet TDT 0.6B v3 model —
happens exactly once, at startup.

This daemon NEVER touches the microphone. The Swift app (the process that actually holds the mic
TCC grant) captures audio and streams 16kHz mono float32 PCM in over stdin. A python child that
captured for itself received pure TCC silence (verified live: peak=0.0000 across a full session).

stdin (one JSON object per line):

    {"cmd": "start"}          → begin a transcription session
    {"audio": "<base64 pcm>"} → one chunk of 16kHz mono float32 PCM
    {"cmd": "stop"}           → finalize: emit the session's transcript NOW
    {"cmd": "quit"}           → clean shutdown (EOF on stdin does the same)

stdout (one JSON object per line, always flushed):

    {"status": "ready"}       # model loaded — the daemon is warm
    {"status": "listening"}   # session open, accepting audio
    {"partial": "<text>"}     # live transcript as audio streams in
    {"final": "<text>"}       # committed transcript (on stop)
    {"status": "stopped"}     # session closed (follows each stop)
    {"error": "<reason>"}     # setup problems, e.g. parakeet-mlx not installed

THREADING: MLX is thread-affine — every model operation (including load) happens on ONE dedicated
inference thread that owns the model and the streaming session. stdin parsing is pure I/O and just
feeds a queue. (First cut split load/inference across threads and MLX raised
"There is no Stream(gpu, …) in current thread." Logged exceptions made that visible in minutes;
a silent catch-all had hidden the previous bug for hours. Log inference errors, always.)
"""

import sys
import json
import queue
import signal
import base64
import threading


def emit(json_object):
    """Print one JSON object as a line and flush so the parent process sees it immediately."""
    sys.stdout.write(json.dumps(json_object) + "\n")
    sys.stdout.flush()


SAMPLE_RATE_HZ = 16000

# Items flowing from the stdin loop to the inference thread: ("start",) / ("audio", ndarray) /
# ("stop",) / ("quit",).
inference_work_queue: "queue.Queue[tuple]" = queue.Queue()


def inference_thread_main():
    """Owns the model and ALL MLX operations, per MLX's thread affinity."""
    try:
        import numpy as np  # noqa: F401  (used via the queue payloads)
        import mlx.core as mx
        from parakeet_mlx import from_pretrained
    except ImportError:
        emit({"error": "parakeet-mlx not installed"})
        sys.exit(1)

    try:
        speech_model = from_pretrained("mlx-community/parakeet-tdt-0.6b-v3")
    except Exception as model_load_error:  # noqa: BLE401 — report any load failure cleanly
        emit({"error": f"failed to load parakeet model: {model_load_error}"})
        sys.exit(1)
    emit({"status": "ready"})

    streaming_session = None
    last_emitted_partial_text = ""
    session_sample_count = 0
    session_peak_amplitude = 0.0

    def close_session_and_finalize():
        nonlocal streaming_session, last_emitted_partial_text
        nonlocal session_sample_count, session_peak_amplitude
        final_text = ""
        if streaming_session is not None:
            try:
                final_text = streaming_session.result.text.strip()
            except Exception as finalize_error:
                print(f"[stt] finalize error: {finalize_error!r}", file=sys.stderr, flush=True)
            finally:
                streaming_session.__exit__(None, None, None)
                streaming_session = None
        print(
            f"[audio] session: {session_sample_count} samples "
            f"({session_sample_count / SAMPLE_RATE_HZ:.1f}s) peak={session_peak_amplitude:.4f}",
            file=sys.stderr, flush=True,
        )
        session_sample_count = 0
        session_peak_amplitude = 0.0
        last_emitted_partial_text = ""
        if final_text:
            emit({"final": final_text})
        emit({"status": "stopped"})

    while True:
        work_item = inference_work_queue.get()
        kind = work_item[0]

        if kind == "start":
            if streaming_session is None:
                # depth=2 trades a little compute for markedly better streaming accuracy.
                streaming_session = speech_model.transcribe_stream(context_size=(256, 256), depth=2)
                streaming_session.__enter__()
                last_emitted_partial_text = ""
                session_sample_count = 0
                session_peak_amplitude = 0.0
            emit({"status": "listening"})

        elif kind == "audio":
            if streaming_session is None:
                continue  # stale chunk from a session that just stopped
            sample_block = work_item[1]
            try:
                streaming_session.add_audio(mx.array(sample_block))
                session_sample_count += sample_block.size
                block_peak = float(abs(sample_block).max()) if sample_block.size else 0.0
                session_peak_amplitude = max(session_peak_amplitude, block_peak)
                partial_text = streaming_session.result.text.strip()
                if partial_text and partial_text != last_emitted_partial_text:
                    last_emitted_partial_text = partial_text
                    emit({"partial": partial_text})
            except Exception as inference_error:
                print(f"[stt] streaming inference error: {inference_error!r}", file=sys.stderr, flush=True)

        elif kind == "stop":
            close_session_and_finalize()

        elif kind == "quit":
            if streaming_session is not None:
                close_session_and_finalize()
            return


def main():
    import numpy as np

    # SIGTERM = parent shutting down; exit cleanly.
    signal.signal(signal.SIGTERM, lambda signum, frame: sys.exit(0))

    inference_thread = threading.Thread(target=inference_thread_main, daemon=True)
    inference_thread.start()

    # stdin loop: pure parsing, no model work. EOF (parent died) behaves like quit.
    for raw_line in sys.stdin:
        try:
            parsed_line = json.loads(raw_line)
        except json.JSONDecodeError:
            continue
        if not isinstance(parsed_line, dict):
            continue

        if "audio" in parsed_line:
            try:
                pcm_bytes = base64.b64decode(parsed_line["audio"] or "")
                sample_block = np.frombuffer(pcm_bytes, dtype=np.float32)
            except Exception as decode_error:
                print(f"[audio] chunk decode failed: {decode_error}", file=sys.stderr, flush=True)
                continue
            if sample_block.size:
                inference_work_queue.put(("audio", sample_block))
            continue

        command_name = parsed_line.get("cmd")
        if command_name in ("start", "stop"):
            inference_work_queue.put((command_name,))
        elif command_name == "quit":
            break

    inference_work_queue.put(("quit",))
    inference_thread.join(timeout=10)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
