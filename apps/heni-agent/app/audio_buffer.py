from __future__ import annotations

import os
import tempfile
import wave
from pathlib import Path


class PatientAudioBuffer:
    """Call-scoped patient-only PCM16 buffer that spills to disk when needed."""

    sample_rate = 16000
    channels = 1
    sample_width = 2
    bytes_per_second = sample_rate * channels * sample_width

    def __init__(self, *, spool_limit_bytes: int = 4 * 1024 * 1024) -> None:
        self._file = tempfile.SpooledTemporaryFile(
            max_size=spool_limit_bytes,
            mode="w+b",
        )
        self._bytes = 0
        self._closed = False

    def append(self, pcm_bytes: bytes) -> None:
        if self._closed or not pcm_bytes:
            return
        self._file.write(pcm_bytes)
        self._bytes += len(pcm_bytes)

    @property
    def byte_length(self) -> int:
        return self._bytes

    def duration_seconds(self) -> float:
        return self._bytes / self.bytes_per_second

    def finalize_wav_file(self) -> Path:
        if self._closed:
            raise RuntimeError("audio_buffer_closed")
        self._file.flush()
        self._file.seek(0)

        handle = tempfile.NamedTemporaryFile(
            prefix="hani-patient-",
            suffix=".wav",
            delete=False,
        )
        path = Path(handle.name)
        handle.close()

        try:
            with wave.open(str(path), "wb") as wav:
                wav.setnchannels(self.channels)
                wav.setsampwidth(self.sample_width)
                wav.setframerate(self.sample_rate)
                while True:
                    chunk = self._file.read(256 * 1024)
                    if not chunk:
                        break
                    wav.writeframes(chunk)
            return path
        except Exception:
            path.unlink(missing_ok=True)
            raise

    def clear(self) -> None:
        if self._closed:
            return
        self._file.seek(0)
        self._file.truncate(0)
        self._bytes = 0

    def close(self) -> None:
        if self._closed:
            return
        self._closed = True
        self._file.close()

    def __enter__(self) -> "PatientAudioBuffer":
        return self

    def __exit__(self, *_args: object) -> None:
        self.close()


def delete_temp_audio(path: str | os.PathLike[str] | None) -> None:
    if not path:
        return
    try:
        Path(path).unlink(missing_ok=True)
    except OSError:
        pass
