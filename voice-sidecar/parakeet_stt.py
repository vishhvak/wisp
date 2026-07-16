#!/usr/bin/env python3
"""Parakeet speech-to-text sidecar for Wisp.

This script is launched as a child process by the Swift app (see
Sources/Wisp/Voice/TranscriptionProvider.swift). It captures the microphone locally on Apple
Silicon using the Parakeet TDT 0.6B v3 model (via parakeet-mlx), performs lightweight
silence-based utterance chunking, and prints newline-delimited JSON to stdout:

    {"partial": "<in-progress text>"}   # emitted repeatedly while the user is speaking
    {"final":   "<committed text>"}     # emitted once at the end of each utterance

Every line is flushed immediately so the Swift side sees transcripts with minimal latency.

If parakeet-mlx (or its dependencies) is not installed, the script prints
    {"error": "parakeet-mlx not installed"}
to stdout and exits with status 1 so the app can fall back to Apple's on-device Speech framework.
"""

import sys
import json
import queue
import signal


def emit(json_object):
    """Print one JSON object as a line and flush so the parent process sees it immediately."""
    sys.stdout.write(json.dumps(json_object) + "\n")
    sys.stdout.flush()


# Set when the parent sends SIGTERM (the user released the push-to-talk key). Push-to-talk
# semantics: release means "I'm done talking — transcribe what you heard NOW", so the main loop
# finalizes the accumulated utterance and emits it BEFORE exiting, instead of dying with the
# transcript still in memory.
shutdown_requested = False


def _handle_sigterm(signum, frame):
    global shutdown_requested
    shutdown_requested = True


signal.signal(signal.SIGTERM, _handle_sigterm)


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

    # Audio capture configuration. Parakeet expects 16 kHz mono PCM.
    sample_rate_hz = 16000
    channel_count = 1
    # We process audio in short blocks so partial transcripts update roughly every ~0.5s.
    block_duration_seconds = 0.5
    block_frame_count = int(sample_rate_hz * block_duration_seconds)

    # Silence-based (VAD-lite) chunking: when the recent audio's RMS energy stays below this
    # threshold for `silence_blocks_to_finalize` consecutive blocks, we treat the utterance as done.
    silence_rms_threshold = 0.010
    silence_blocks_to_finalize = 2

    # Load the model. This can take a few seconds on first run (weights download + init).
    try:
        speech_model = from_pretrained("mlx-community/parakeet-tdt-0.6b-v3")
    except Exception as model_load_error:  # noqa: BLE401 - report any load failure cleanly
        emit({"error": f"failed to load parakeet model: {model_load_error}"})
        sys.exit(1)

    # A thread-safe queue the audio callback pushes captured blocks into.
    captured_audio_queue: "queue.Queue[np.ndarray]" = queue.Queue()

    def audio_input_callback(indata, frames, time_info, status):
        # Copy the block (indata is reused by the driver) and hand it to the main loop.
        captured_audio_queue.put(indata.copy())

    # Accumulates the samples of the current utterance so we can transcribe the whole thing.
    current_utterance_samples = []
    consecutive_silent_blocks = 0
    last_emitted_partial_text = ""

    def transcribe_samples(sample_array):
        """Runs the model over a mono float32 sample array and returns the recognized text."""
        try:
            transcription_result = speech_model.transcribe(sample_array)
            # parakeet-mlx returns an object with a `.text` attribute for the full transcript.
            return getattr(transcription_result, "text", "").strip()
        except Exception:
            return ""

    with sd.InputStream(
        samplerate=sample_rate_hz,
        channels=channel_count,
        blocksize=block_frame_count,
        dtype="float32",
        callback=audio_input_callback,
    ):
        # Tell the parent the mic is actually open — the gap between launch and this line is model
        # load time, which the Swift log can now show.
        emit({"status": "listening"})

        while True:
            if shutdown_requested:
                # Push-to-talk release: transcribe everything accumulated (plus anything still
                # queued) and emit it as the final result before exiting.
                while not captured_audio_queue.empty():
                    current_utterance_samples.append(captured_audio_queue.get().reshape(-1))
                if current_utterance_samples:
                    final_text = transcribe_samples(np.concatenate(current_utterance_samples))
                    if final_text:
                        emit({"final": final_text})
                emit({"status": "stopped"})
                return

            try:
                audio_block = captured_audio_queue.get(timeout=0.1)
            except queue.Empty:
                continue
            # Flatten to mono float32 samples.
            mono_samples = audio_block.reshape(-1)

            # Compute this block's RMS energy to decide speech vs silence.
            block_rms_energy = float(np.sqrt(np.mean(np.square(mono_samples)))) if mono_samples.size else 0.0

            # Always accumulate while the stream is open — under push-to-talk the WHOLE hold is the
            # utterance, and energy-gating the buffer made quiet speech vanish entirely.
            current_utterance_samples.append(mono_samples)

            if block_rms_energy >= silence_rms_threshold:
                # Speech: emit an updated partial transcript.
                consecutive_silent_blocks = 0

                combined_samples = np.concatenate(current_utterance_samples)
                partial_text = transcribe_samples(combined_samples)
                if partial_text and partial_text != last_emitted_partial_text:
                    last_emitted_partial_text = partial_text
                    emit({"partial": partial_text})
            else:
                # Silence: if we were mid-utterance, count silent blocks toward finalizing it.
                if last_emitted_partial_text:
                    consecutive_silent_blocks += 1
                    if consecutive_silent_blocks >= silence_blocks_to_finalize:
                        combined_samples = np.concatenate(current_utterance_samples)
                        final_text = transcribe_samples(combined_samples)
                        if final_text:
                            emit({"final": final_text})
                        # Reset for the next utterance.
                        current_utterance_samples = []
                        consecutive_silent_blocks = 0
                        last_emitted_partial_text = ""


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        # The parent process terminated us; exit quietly.
        sys.exit(0)
