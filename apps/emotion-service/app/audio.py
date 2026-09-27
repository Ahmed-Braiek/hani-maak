from __future__ import annotations

import math
import wave
from dataclasses import dataclass
from pathlib import Path

import numpy as np

SAMPLE_RATE = 16000


@dataclass(frozen=True)
class SpeechWindow:
    start_sample: int
    end_sample: int
    voiced_samples: int

    @property
    def start_ms(self) -> int:
        return round(self.start_sample * 1000 / SAMPLE_RATE)

    @property
    def end_ms(self) -> int:
        return round(self.end_sample * 1000 / SAMPLE_RATE)


def read_mono_pcm16_wav(path: str | Path) -> np.ndarray:
    with wave.open(str(path), "rb") as wav:
        if wav.getnchannels() != 1:
            raise ValueError("audio_must_be_mono")
        if wav.getsampwidth() != 2:
            raise ValueError("audio_must_be_pcm16")
        if wav.getframerate() != SAMPLE_RATE:
            raise ValueError("audio_must_be_16khz")
        frames = wav.readframes(wav.getnframes())
    if not frames:
        return np.zeros(0, dtype=np.int16)
    return np.frombuffer(frames, dtype="<i2").copy()


def _frame_activity(samples: np.ndarray, frame_ms: int = 30) -> np.ndarray:
    frame = max(1, round(SAMPLE_RATE * frame_ms / 1000))
    count = math.ceil(len(samples) / frame)
    active = np.zeros(count, dtype=bool)
    for index in range(count):
        chunk = samples[index * frame : min(len(samples), (index + 1) * frame)]
        if chunk.size == 0:
            continue
        normalized = chunk.astype(np.float32) / 32768.0
        rms = float(np.sqrt(np.mean(normalized * normalized)))
        peak = float(np.max(np.abs(normalized)))
        active[index] = rms >= 0.012 and peak >= 0.04
    return active


def speech_windows(
    samples: np.ndarray,
    *,
    target_seconds: float,
    max_seconds: float,
    min_voiced_seconds: float = 1.5,
) -> list[SpeechWindow]:
    if samples.size == 0:
        return []

    frame_ms = 30
    frame_samples = round(SAMPLE_RATE * frame_ms / 1000)
    active = _frame_activity(samples, frame_ms=frame_ms)
    target_frames = max(1, round(target_seconds * 1000 / frame_ms))
    max_frames = max(target_frames, round(max_seconds * 1000 / frame_ms))
    min_voiced_frames = max(1, round(min_voiced_seconds * 1000 / frame_ms))

    windows: list[SpeechWindow] = []
    start = 0
    while start < len(active):
        end = min(len(active), start + max_frames)
        preferred = min(end, start + target_frames)

        if preferred < end:
            search_lo = max(start + 1, preferred - round(1000 / frame_ms))
            search_hi = min(end, preferred + round(1000 / frame_ms))
            silent = np.flatnonzero(~active[search_lo:search_hi])
            if silent.size:
                preferred = search_lo + int(silent[-1])
        end = max(start + 1, preferred)

        voiced_frames = int(np.count_nonzero(active[start:end]))
        if voiced_frames >= min_voiced_frames:
            windows.append(
                SpeechWindow(
                    start_sample=start * frame_samples,
                    end_sample=min(len(samples), end * frame_samples),
                    voiced_samples=voiced_frames * frame_samples,
                )
            )
        start = end
    return windows


def write_segment_wav(samples: np.ndarray, path: str | Path) -> None:
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(samples.astype("<i2", copy=False).tobytes())
