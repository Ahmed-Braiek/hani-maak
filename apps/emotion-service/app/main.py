from __future__ import annotations

import hmac
import shutil
import tempfile
from pathlib import Path
from typing import Annotated

from fastapi import FastAPI, File, Form, Header, HTTPException, UploadFile

from .config import settings, validate_settings
from .inference import analyze_wav
from .model import load_model, model_loaded, resolved_device
from .schemas import EmotionAnalysisResponse

validate_settings()

app = FastAPI(title="Hani Maak Emotion Service", version="1.0.0")


@app.on_event("startup")
def preload_model() -> None:
    load_model()


def _authorize(authorization: str | None) -> None:
    expected = f"Bearer {settings.service_secret}"
    if not authorization or not hmac.compare_digest(authorization, expected):
        raise HTTPException(status_code=401, detail="unauthorized")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": "hani-emotion-service"}


@app.get("/ready")
def ready() -> dict[str, object]:
    return {
        "status": "ready" if model_loaded() else "loading",
        "model_loaded": model_loaded(),
        "model": settings.model_id.split("/")[-1],
        "device": resolved_device(),
    }


@app.post("/v1/emotions/analyze", response_model=EmotionAnalysisResponse)
async def analyze(
    audio: Annotated[UploadFile, File(...)],
    conversation_id: Annotated[str, Form(...)],
    authorization: Annotated[str | None, Header()] = None,
) -> EmotionAnalysisResponse:
    _authorize(authorization)
    if not conversation_id.strip():
        raise HTTPException(status_code=400, detail="conversation_id_required")

    suffix = Path(audio.filename or "call.wav").suffix.lower()
    if suffix not in {".wav", ""}:
        raise HTTPException(status_code=400, detail="wav_required")

    path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(prefix="hani-call-", suffix=".wav", delete=False) as temp:
            path = Path(temp.name)
            shutil.copyfileobj(audio.file, temp)
        return analyze_wav(path, conversation_id.strip())
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    finally:
        await audio.close()
        if path is not None:
            path.unlink(missing_ok=True)
