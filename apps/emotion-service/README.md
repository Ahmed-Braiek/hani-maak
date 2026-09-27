# Hani Maak Emotion Service

Dedicated post-call vocal-emotion inference service for Hani Maak.

Current Railway Hobby runtime:

- Model: `onnx-community/wav2vec2-base-Speech_Emotion_Recognition-ONNX`
- Runtime: ONNX Runtime CPU
- Quantized graph: `onnx/model_quantized.onnx`
- Approximate model file size: 95 MB
- Input: patient-only mono PCM16 WAV at 16 kHz
- API: `POST /v1/emotions/analyze`
- Auth: `Authorization: Bearer $EMOTION_SERVICE_SECRET`
- Health: `GET /health`
- Readiness: `GET /ready`

The source model exposes six classes: sad, angry, disgust, fear, happy, and neutral. Hani Maak maps those to its canonical non-diagnostic
vocal-emotion labels.

This lightweight ONNX deployment is used specifically to stay inside the
current Railway Hobby 1 GB RAM ceiling. It is trained primarily on English
emotion datasets, so Arabic, French, Tunisian Derja, and code-switching
performance must be validated on Hani Maak call samples before the signal is
used for caregiver decisions.

The service loads the graph once at process startup and remains outside the
Gemini Live realtime path.

## Required environment

```env
EMOTION_SERVICE_SECRET=
EMOTION_MODEL_ID=onnx-community/wav2vec2-base-Speech_Emotion_Recognition-ONNX
EMOTION_MODEL_FILENAME=onnx/model_quantized.onnx
EMOTION_MODEL_CACHE_DIR=/tmp/hf
EMOTION_ONNX_THREADS=2
EMOTION_MIN_SPEECH_SECONDS=3
EMOTION_TARGET_SEGMENT_SECONDS=6
EMOTION_MAX_SEGMENT_SECONDS=10
EMOTION_MIN_CONFIDENCE=0.45
```

Raw uploaded audio is written only to a temporary file and deleted after
inference.
