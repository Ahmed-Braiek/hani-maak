# Hani Maak Emotion Service

Dedicated post-call speech-emotion inference service for Hani Maak.

- Model: `iic/emotion2vec_plus_base`
- Input: patient-only mono PCM16 WAV at 16 kHz
- API: `POST /v1/emotions/analyze`
- Auth: `Authorization: Bearer $EMOTION_SERVICE_SECRET`
- Health: `GET /health`
- Readiness: `GET /ready`

The service loads the model once at process startup. It does not participate in the realtime Gemini Live WebSocket path.

## Required environment

```env
EMOTION_SERVICE_SECRET=
EMOTION_MODEL_ID=iic/emotion2vec_plus_base
EMOTION_DEVICE=auto
EMOTION_MIN_SPEECH_SECONDS=3
EMOTION_TARGET_SEGMENT_SECONDS=6
EMOTION_MAX_SEGMENT_SECONDS=10
EMOTION_MIN_CONFIDENCE=0.45
```

Raw uploaded audio is written only to a temporary file and is deleted in a `finally` path after inference.
