from __future__ import annotations

import tempfile
import time
from pathlib import Path

from .aggregation import aggregate_segments, normalize_distribution
from .audio import SAMPLE_RATE, read_mono_pcm16_wav, speech_windows, write_segment_wav
from .config import settings
from .model import infer_file
from .schemas import EmotionAnalysisResponse, EmotionSegment


def analyze_wav(path: str | Path, conversation_id: str) -> EmotionAnalysisResponse:
    started = time.perf_counter()
    samples = read_mono_pcm16_wav(path)
    audio_duration_ms = round(len(samples) * 1000 / SAMPLE_RATE)

    windows = speech_windows(
        samples,
        target_seconds=settings.target_segment_seconds,
        max_seconds=settings.max_segment_seconds,
    )
    total_voiced_samples = sum(window.voiced_samples for window in windows)
    analyzed_speech_ms = round(total_voiced_samples * 1000 / SAMPLE_RATE)

    if analyzed_speech_ms < round(settings.min_speech_seconds * 1000):
        return EmotionAnalysisResponse(
            conversation_id=conversation_id,
            model=settings.model_id.split("/")[-1],
            status="insufficient_audio",
            audio_duration_ms=audio_duration_ms,
            analyzed_speech_ms=analyzed_speech_ms,
            processing_ms=round((time.perf_counter() - started) * 1000),
        )

    segments: list[EmotionSegment] = []
    with tempfile.TemporaryDirectory(prefix="hani-emotion-") as temp_dir:
        for index, window in enumerate(windows):
            segment_path = Path(temp_dir) / f"segment-{index:03d}.wav"
            segment_samples = samples[window.start_sample : window.end_sample]
            write_segment_wav(segment_samples, segment_path)
            scores = normalize_distribution(infer_file(segment_path))
            dominant = max(scores, key=scores.get)
            confidence = float(scores[dominant])
            segments.append(
                EmotionSegment(
                    segment_index=index,
                    start_ms=window.start_ms,
                    end_ms=window.end_ms,
                    duration_ms=window.end_ms - window.start_ms,
                    voiced_duration_ms=round(window.voiced_samples * 1000 / SAMPLE_RATE),
                    dominant_emotion=dominant,
                    confidence=confidence,
                    scores=scores,
                )
            )

    dominant, confidence, distribution = aggregate_segments(segments)
    return EmotionAnalysisResponse(
        conversation_id=conversation_id,
        model=settings.model_id.split("/")[-1],
        status="completed",
        dominant_emotion=dominant,
        confidence=confidence,
        distribution=distribution,
        segments=segments,
        audio_duration_ms=audio_duration_ms,
        analyzed_speech_ms=analyzed_speech_ms,
        processing_ms=round((time.perf_counter() - started) * 1000),
    )
