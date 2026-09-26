from __future__ import annotations

from typing import Any

from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

load_dotenv()

from .chat_handler import run_chat_turn
from .config import settings, validate_settings
from .security import verify_internal_key
from .voice_handler import handle_voice_connection
from .medication_ocr import MedicationOcrResult, analyze_medication_image

validate_settings()

app = FastAPI(title="Heni Agent", version="2.0.0", docs_url=None if settings.is_production else "/docs")
app.add_middleware(
    CORSMiddleware,
    allow_origins=list(settings.allowed_origins),
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["content-type", "x-heni-agent-key"],
)


class ChatMessage(BaseModel):
    role: str
    content: str = Field(max_length=4000)


class MedicationOcrRequest(BaseModel):
    imageDataUrl: str = Field(min_length=32, max_length=10_500_000)
    mode: str = Field(default="prescription", max_length=40)


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=2000)
    locale: str = "ar"
    patientId: str = Field(min_length=1, max_length=120)
    caregiverId: str | None = Field(default=None, max_length=120)
    source: str = "website"
    sessionId: str | None = None
    confirmationToken: str | None = Field(default=None, max_length=12000)
    history: list[ChatMessage] = Field(default_factory=list, max_length=20)


@app.get("/health")
async def health() -> dict[str, Any]:
    return {
        "status": "ok",
        "service": "heni-agent",
        "mode": "caregiver-ready",
        "textModel": settings.text_model,
        "liveModel": settings.live_model,
    }


@app.post("/v1/chat")
async def chat(body: ChatRequest, x_heni_agent_key: str | None = Header(default=None)) -> dict[str, Any]:
    if not verify_internal_key(x_heni_agent_key):
        raise HTTPException(status_code=401, detail="unauthorized")
    return await run_chat_turn(
        message=body.message.strip(),
        patient_id=body.patientId,
        caregiver_id=body.caregiverId,
        locale=body.locale,
        source=body.source,
        session_id=body.sessionId,
        history=[item.model_dump() for item in body.history],
        confirmation_token=body.confirmationToken,
    )


@app.post("/v1/ocr/medication", response_model=MedicationOcrResult)
async def medication_ocr(
    body: MedicationOcrRequest,
    x_heni_agent_key: str | None = Header(default=None),
) -> MedicationOcrResult:
    if not verify_internal_key(x_heni_agent_key):
        raise HTTPException(status_code=401, detail="unauthorized")
    try:
        return await analyze_medication_image(
            image_data_url=body.imageDataUrl,
            mode=body.mode,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@app.websocket("/ws/voice")
async def voice(ws: WebSocket) -> None:
    await handle_voice_connection(ws)


@app.get("/")
async def root() -> dict[str, str]:
    return {"service": "Heni Agent", "status": "online"}
