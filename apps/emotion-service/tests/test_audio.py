import wave

import numpy as np

from app.audio import SAMPLE_RATE, read_mono_pcm16_wav, speech_windows


def test_read_valid_pcm16_wav(tmp_path) -> None:
    path = tmp_path / "sample.wav"
    samples = np.zeros(SAMPLE_RATE, dtype=np.int16)
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(samples.tobytes())

    loaded = read_mono_pcm16_wav(path)
    assert loaded.size == SAMPLE_RATE


def test_silence_creates_no_speech_windows() -> None:
    samples = np.zeros(SAMPLE_RATE * 8, dtype=np.int16)
    assert speech_windows(
        samples,
        target_seconds=6,
        max_seconds=10,
    ) == []


def test_voiced_audio_creates_timed_window() -> None:
    samples = np.full(SAMPLE_RATE * 6, 4000, dtype=np.int16)
    windows = speech_windows(
        samples,
        target_seconds=6,
        max_seconds=10,
    )
    assert windows
    assert windows[0].start_ms == 0
    assert 5900 <= windows[0].end_ms <= 6100
