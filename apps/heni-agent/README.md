# Heni Agent — realtime voice + chat for Hani Maak

`heni-agent` is the AI runtime for **Hani Maak — هاني معاك**. It provides the multilingual Heni assistant in Tunisian Derja, French and English, with real-time Gemini Live speech-to-speech plus text chat. It intentionally does **not** own appointment or patient truth: those facts and actions are delegated to the Hani Maak backend through constrained tools.

## Runtime contract

- `POST /v1/chat` — server-to-server Heni text turn. Requires `x-heni-agent-key`.
- `WS /ws/voice?token=...` — real-time PCM16 speech-to-speech. The browser receives a short-lived signed token from the Hani Maak website; the Google key never reaches the browser.
- `GET /health` — deployment health check.

## Safety architecture

- Heni is administrative/navigation-only; no diagnosis, prescribing, dose changes or autonomous clinical triage.
- Current availability, appointments, navigation and provider instructions must come from tools.
- Appointment create/reschedule/cancel uses **two-phase confirmation** enforced by code. The first write attempt creates a pending action; the second matching attempt executes only if the latest user turn contains an explicit confirmation.
- Browser voice identity is carried in a short-lived HMAC token signed by the Hani Maak server.
- The agent calls Hani Maak with a server-only shared secret. No Gemini or backend secret belongs in frontend JavaScript.

## Google models

Defaults are current stable model IDs as of September 2026:

```text
HENI_TEXT_MODEL=gemini-3.8-flash
HENI_LIVE_MODEL=gemini-3.8-live
```

The model IDs are configuration, so the backend team can replace the text model with a validated tuned/custom model without changing the website integration. The Live model remains optimized for low-latency speech-to-speech.

## Local setup

```bash
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\\Scripts\\activate
pip install -r requirements.txt
cp .env.example .env
python -m uvicorn app.main:app --host 0.0.0.0 --port 8080
```

## Required production environment

```text
HENI_ENV=production
GEMINI_API_KEY=...
HENI_TEXT_MODEL=gemini-3.8-flash
HENI_LIVE_MODEL=gemini-3.8-live
HENI_VOICE_NAME=Kore
HANI_BACKEND_BASE_URL=https://hani-maak.vercel.app
HENI_AGENT_SHARED_SECRET=<same long random value configured on the web project>
HENI_ALLOWED_ORIGINS=https://hani-maak.vercel.app
```

If the model is hosted through Vertex AI, use `GOOGLE_GENAI_USE_VERTEXAI=true`, `GOOGLE_CLOUD_PROJECT`, `GOOGLE_CLOUD_LOCATION` and proper Google Cloud workload identity/ADC instead of exposing a service-account file.

## Vercel

The repository includes a root `index.py` exporting the FastAPI app and a Python 3.12 project manifest, so it is Vercel-ready. Vercel's current Python runtime supports FastAPI; WebSocket support is a 2026 public beta and should be verified on the target Vercel account before the final competition rehearsal.

## Audio protocol

Browser → service: raw little-endian PCM16 mono audio, 16 kHz, binary WebSocket frames.

Service → browser: raw PCM16 mono audio, 24 kHz, binary frames. JSON control frames include:

```json
{"type":"session","sessionId":"..."}
{"type":"transcript","role":"user","text":"..."}
{"type":"transcript","role":"model","text":"..."}
{"type":"tool_call","name":"find_services","args":{}}
{"type":"turn_complete"}
{"type":"error","message":"voice_session_unavailable"}
```

The Live configuration enables both input and output audio transcription so the Hani Maak UI can display what the patient said and what Heni answered while native audio is playing.
