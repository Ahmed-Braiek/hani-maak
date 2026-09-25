from __future__ import annotations

import os
from dataclasses import dataclass


def _bool(name: str, default: bool = False) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def _csv(name: str, default: str = "") -> tuple[str, ...]:
    raw = os.getenv(name, default)
    return tuple(item.strip().rstrip("/") for item in raw.split(",") if item.strip())


@dataclass(frozen=True)
class Settings:
    environment: str = os.getenv("HENI_ENV", "development")
    gemini_api_key: str = os.getenv("GEMINI_API_KEY", "")
    use_vertex_ai: bool = _bool("GOOGLE_GENAI_USE_VERTEXAI")
    google_cloud_project: str = os.getenv("GOOGLE_CLOUD_PROJECT", "")
    google_cloud_location: str = os.getenv("GOOGLE_CLOUD_LOCATION", "global")
    live_model: str = os.getenv("HENI_LIVE_MODEL", os.getenv("GEMINI_LIVE_MODEL", "gemini-3.8-live"))
    text_model: str = os.getenv("HENI_TEXT_MODEL", os.getenv("GEMINI_TEXT_MODEL", "gemini-3.8-flash"))
    voice_name: str = os.getenv("HENI_VOICE_NAME", "Gacrux")
    backend_base_url: str = os.getenv("HANI_BACKEND_BASE_URL", "").rstrip("/")
    shared_secret: str = os.getenv("HENI_AGENT_SHARED_SECRET", "")
    allowed_origins: tuple[str, ...] = _csv("HENI_ALLOWED_ORIGINS", "http://localhost:3000,https://hani-maak.vercel.app")
    debug_enabled: bool = _bool("HENI_DEBUG", False)
    session_ttl_seconds: int = int(os.getenv("HENI_SESSION_TTL_SECONDS", "1800"))
    backend_timeout_seconds: float = float(os.getenv("HENI_BACKEND_TIMEOUT_SECONDS", "12"))
    model_timeout_seconds: float = float(os.getenv("HENI_MODEL_TIMEOUT_SECONDS", "24"))

    @property
    def is_production(self) -> bool:
        return self.environment.lower() == "production"


settings = Settings()


def validate_settings() -> None:
    if settings.use_vertex_ai:
        if not settings.google_cloud_project:
            raise RuntimeError("GOOGLE_CLOUD_PROJECT is required when GOOGLE_GENAI_USE_VERTEXAI=true")
    elif not settings.gemini_api_key:
        raise RuntimeError("GEMINI_API_KEY is required unless Vertex AI mode is enabled")
    if not settings.shared_secret:
        raise RuntimeError("HENI_AGENT_SHARED_SECRET is required")
    if not settings.backend_base_url:
        raise RuntimeError("HANI_BACKEND_BASE_URL is required")
