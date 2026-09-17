# Heni Voice Architecture

Heni Voice serves the same product role as Heni Chat through a speech interface. The preferred experience is natural Tunisian Derja with normal French code-switching; French and English remain supported.

## Channels

### Browser competition fallback

The web app already offers microphone capture through browser speech recognition where supported and browser speech synthesis for replies. Typed input remains available when microphone recognition is unavailable. Administrative actions use the same deterministic domain behavior as the app.

### Optional realtime / PSTN bridge

`apps/voice-bridge` is a separate Fastify/WebSocket application for provider media streaming and realtime AI. It exposes a constrained administrative tool set and can use the same fine-tuned/delegated model configuration as Heni Chat.

## Voice behavior requirements

- stop/listen when interrupted;
- ask for a short clarification instead of guessing unclear speech;
- keep spoken turns concise;
- repeat dates/times/actions before confirmation;
- switch language when the user switches;
- never claim a mutation succeeded without the backend result;
- escalate clinical-boundary or explicit human-help requests.

## Tool security

The bridge can attach `x-hani-voice-secret` to trusted internal tool requests using `VOICE_BRIDGE_SHARED_SECRET`. Production must use a strong secret, TLS, provider webhook/signature verification where applicable, rate limiting and server-issued confirmation semantics for write actions.

## Provider independence

Voice controls and application domain logic should not depend directly on one speech vendor. Provider-specific realtime protocol code is isolated in the bridge. The current bridge is an integration path, not a claim that every provider/model protocol version has been production-validated.

## Production validation checklist

Before real calling is enabled:

- verify the current realtime provider WebSocket contract/model identifier;
- validate telephony webhook/media-stream signatures;
- verify audio codec/rate behavior end to end;
- validate interruption/barge-in behavior;
- measure latency across Derja/French/English;
- confirm transcript/audio retention policy;
- verify redacted observability and rate limits;
- test tool failures and safe fallback;
- run clinical-boundary and prompt-injection evaluations over voice input.
