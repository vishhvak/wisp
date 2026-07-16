#!/usr/bin/env python3
"""Parakeet speech-to-text warm daemon for Wisp.

Launched ONCE at app startup by the Swift app (Sources/Wisp/Voice/TranscriptionProvider.swift) and
kept alive for the app's whole life. The expensive part — loading the Parakeet TDT 0.6B v3 model —
happens exactly once, at startup. After that, each push-to-talk hold is driven by newline-delimited
JSON commands on stdin and costs only a mic-stream open (~0.1s):

    {"cmd": "start"}   → open the microphone, buffer + transcribe
    {"cmd": "stop"}    → close the microphone, transcribe EVERYTHING heard, emit the final
    {"cmd": "quit"}    → clean shutdown (EOF on stdin does the same)

Emitted on stdout (one JSON object per line, always flushed):

    {"status": "ready"}       # model loaded — the daemon is warm
    {"status": "listening"}   # mic open (follows each start)
    {"partial": "<text>"}     # in-progress transcript while speaking
    {"final": "<text>"}       # committed transcript (on stop, or after a mid-hold silence)
    {"status": "stopped"}     # session closed (follows each stop)
    {"error": "<reason>"}     # setup problems, e.g. parakeet-mlx not installed

If parakeet-mlx (or its dependencies) is missing, prints {"error": ...} and exits 1 so the app can
fall back to Apple's on-device Speech framework.
"""

import sys
import json
import queue
import signal
import threading


def emit(json_object):
    """Print one JSON object as a line and flush so the parent process sees it immediately."""
    sys.stdout.write(json.dumps(json_object) + "\n")
    sys.stdout.flush()


def main():
    # Import inside main so a missing dependency produces a clean {"error": ...} line + exit 1,
    # rather than an uncaught traceback the Swift side can't interpret.
    try:
        import numpy as np
        import sounddevice as sd
        from parakeet_mlx import from_pretrained
    except ImportError:
        emit({"error": "parakeet-mlx not installed"})
        sys.exit(1)

    # SIGTERM = parent shutting down; exit cleanly.
    signal.signal(signal.SIGTERM, lambda signum, frame: sys.exit(0))

    # Load the model ONCE, up front. This is the whole point of the daemon design: the 1–2s load
    # happens at app launch, never inside a push-to-talk hold.
    try:
        speech_model = from_pretrained("mlx-community/parakeet-tdt-0.6b-v3")
    except Exception as model_load_error:  # noqa: BLE401 - report any load failure cleanly
        emit({"error": f"failed to load parakeet model: {model_load_error}"})
        sys.exit(1)
    emit({"status": "ready"})

    # Audio capture configuration. Parakeet expects 16 kHz mono PCM.
    sample_rate_hz = 16000
    channel_count = 1
    # Short blocks so partial transcripts update roughly every ~0.5s.
    block_duration_seconds = 0.5
    block_frame_count = int(sample_rate_hz * block_duration_seconds)

    # Mid-hold silence finalization: after this many consecutive quiet blocks following speech, the
    # utterance is committed early (lets a long hold produce multiple utterances).
    silence_rms_threshold = 0.010
    silence_blocks_to_finalize = 2

    captured_audio_queue: "queue.Queue[np.ndarray]" = queue.Queue()

    # All session state is guarded by state_lock. transcribe() also runs under it — the model isn't
    # thread-safe, and serializing the worker thread against stop-finalization is exactly what we
    # want anyway.
    state_lock = threading.Lock()
    is_listening = False
    current_utterance_samples = []
    consecutive_silent_blocks = 0
    last_emitted_partial_text = ""
    active_input_stream = None

    def audio_input_callback(indata, frames, time_info, status):
        # Copy the block (indata is reused by the driver) and hand it to the worker thread.
        captured_audio_queue.put(indata.copy())

    def transcribe_locked(sample_array):
        """Model inference; caller must hold state_lock."""
        try:
            transcription_result = speech_model.transcribe(sample_array)
            return getattr(transcription_result, "text", "").strip()
        except Exception:
            return ""

    def audio_worker():
        nonlocal consecutive_silent_blocks, last_emitted_partial_text
        while True:
            try:
                audio_block = captured_audio_queue.get(timeout=0.1)
            except queue.Empty:
                continue
            with state_lock:
                if not is_listening:
                    continue  # stale block from a session that just stopped
                mono_samples = audio_block.reshape(-1)
                # Always accumulate — under push-to-talk the WHOLE hold is the utterance.
                current_utterance_samples.append(mono_samples)

                block_rms_energy = float(np.sqrt(np.mean(np.square(mono_samples)))) if mono_samples.size else 0.0
                if block_rms_energy >= silence_rms_threshold:
                    consecutive_silent_blocks = 0
                    partial_text = transcribe_locked(np.concatenate(current_utterance_samples))
                    if partial_text and partial_text != last_emitted_partial_text:
                        last_emitted_partial_text = partial_text
                        emit({"partial": partial_text})
                elif last_emitted_partial_text:
                    consecutive_silent_blocks += 1
                    if consecutive_silent_blocks >= silence_blocks_to_finalize:
                        final_text = transcribe_locked(np.concatenate(current_utterance_samples))
                        if final_text:
                            emit({"final": final_text})
                        current_utterance_samples.clear()
                        consecutive_silent_blocks = 0
                        last_emitted_partial_text = ""

    threading.Thread(target=audio_worker, daemon=True).start()

    def handle_start_command():
        nonlocal is_listening, consecutive_silent_blocks, last_emitted_partial_text, active_input_stream
        with state_lock:
            if is_listening:
                return
            current_utterance_samples.clear()
            consecutive_silent_blocks = 0
            last_emitted_partial_text = ""
            is_listening = True
        stream = sd.InputStream(
            samplerate=sample_rate_hz,
            channels=channel_count,
            blocksize=block_frame_count,
            dtype="float32",
            callback=audio_input_callback,
        )
        stream.start()
        active_input_stream = stream
        # Diagnostics to stderr (mirrored into the app log): WHICH device is being captured.
        # A silent capture with a healthy-looking stream is the TCC-zeros signature.
        try:
            default_input_device = sd.query_devices(kind="input")
            print(f"[audio] capturing from: {default_input_device['name']}", file=sys.stderr, flush=True)
        except Exception as device_query_error:
            print(f"[audio] device query failed: {device_query_error}", file=sys.stderr, flush=True)
        emit({"status": "listening"})

    def handle_stop_command():
        nonlocal is_listening, consecutive_silent_blocks, last_emitted_partial_text, active_input_stream
        with state_lock:
            if not is_listening:
                emit({"status": "stopped"})
                return
            is_listening = False
        if active_input_stream is not None:
            active_input_stream.stop()
            active_input_stream.close()
            active_input_stream = None
        # Drain whatever the driver delivered but the worker hasn't consumed, then transcribe the
        # complete hold — release means "I'm done, transcribe NOW".
        drained_blocks = []
        while not captured_audio_queue.empty():
            drained_blocks.append(captured_audio_queue.get().reshape(-1))
        with state_lock:
            current_utterance_samples.extend(drained_blocks)
            if current_utterance_samples:
                combined_samples = np.concatenate(current_utterance_samples)
                # Amplitude diagnostics: distinguishes "mic delivered zeros" (peak ≈ 0 → TCC/
                # device problem) from "model heard audio but produced nothing" (peak normal).
                print(
                    f"[audio] session captured {combined_samples.size} samples "
                    f"({combined_samples.size / sample_rate_hz:.1f}s) "
                    f"peak={float(np.max(np.abs(combined_samples))):.4f} "
                    f"rms={float(np.sqrt(np.mean(np.square(combined_samples)))):.5f}",
                    file=sys.stderr, flush=True,
                )
                final_text = transcribe_locked(combined_samples)
                if final_text:
                    emit({"final": final_text})
            else:
                print("[audio] session captured ZERO blocks", file=sys.stderr, flush=True)
            current_utterance_samples.clear()
            consecutive_silent_blocks = 0
            last_emitted_partial_text = ""
        emit({"status": "stopped"})

    # Command loop: one JSON object per stdin line. EOF (parent died) exits.
    for raw_command_line in sys.stdin:
        try:
            command_name = json.loads(raw_command_line).get("cmd")
        except (json.JSONDecodeError, AttributeError):
            continue
        if command_name == "start":
            handle_start_command()
        elif command_name == "stop":
            handle_stop_command()
        elif command_name == "quit":
            break

    handle_stop_command()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
