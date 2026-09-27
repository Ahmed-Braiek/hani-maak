# Hani Maak Emotion Service

Dedicated post-call speech-emotion inference service for Hani Maak.

- Model: `Aniemore/wavlm-emotion-v1-crosslingual`
- Quantization: `int4` by default for the Railway Hobby 1 GB RAM ceiling
- Input: patient-only mono PCM16 WAV at 16 kHz
- API: `POST /v1/emotions/analyze`
- Auth: `Authorization: Bearer $EMOTION_SERVICE_SECRET`
- Health: `GET /health`
- Readiness: `GET /ready`

The model predicts seven source labels: anger, disgust, enthusiasm, fear,
happiness, neutral, and sadness. Hani Maak maps these to its canonical
non-diagnostic vocal-emotion labels. `enthusiasm` is mapped to `happy`.
This is the audio-only cross-lingual WavLM variant, selected for the Railway
Hobby 1 GB memory ceiling; the INT4 weights are about 210 MiB.

The service loads the model once at process startup and is kept outside the
Gemini Live realtime path.

## Required environment

```env
EMOTION_SERVICE_SECRET=
EMOTION_MODEL_ID=Aniemore/wavlm-emotion-v1-crosslingual
EMOTION_MODEL_SUBFOLDER=int4
EMOTION_DEVICE=cpu
EMOTION_MIN_SPEECH_SECONDS=3
EMOTION_TARGET_SEGMENT_SECONDS=6
EMOTION_MAX_SEGMENT_SECONDS=10
EMOTION_MIN_CONFIDENCE=0.45
```

Raw uploaded audio is written only to a temporary file and deleted after
inference. This model is cross-lingual but has not been specifically validated
on Tunisian Derja, so Derja performance must be evaluated on Hani Maak data.
