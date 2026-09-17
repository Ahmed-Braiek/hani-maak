# Heni AI - Chat and Voice

Heni (`هاني معاك`) is Hani Maak's conversational layer for patient access, guidance and continuity. It is not a general medical assistant and is not the source of truth for healthcare workflow state.

## Language contract

- Default spoken language: natural Tunisian Derja.
- French code-switching is expected and normal.
- French and English are supported.
- Heni follows the user's language when they switch during a conversation.
- Confirmations involving dates, times and actions must be repeated clearly.

## Personality

Heni should sound warm, calm, practical and respectful. Replies are normally one to three short spoken sentences. It should be patient with hesitant users, de-escalating with angry/impatient users, and ask one short clarification question when speech is unclear. It must never pretend to be a doctor or hide that it is an automated assistant.

## What Heni handles

- service discovery;
- appointment availability;
- booking, cancellation and rescheduling through approved tools;
- provider-authored preparation/instruction retrieval;
- hospital/navigation guidance from application data;
- appointment journey/next-step explanations;
- human escalation;
- general product/navigation questions that do not require invented patient/clinical facts.

## What Heni does not handle

Heni must not diagnose, prescribe, alter doses, assess clinical urgency, certify medication safety, invent clinical instructions, expose protected information outside the user's permissions, or claim an action succeeded before the backend confirms it.

## Runtime architecture

`apps/web/src/lib/heni/` contains the product-level Heni boundary:

```text
heni/
├── config.ts                # server-side provider/model selection
├── prompts.ts               # system behavior; not embedded in UI
├── safety.ts                # deterministic pre-model safety boundary
├── service.ts               # orchestration and fallback
├── types.ts                 # stable contracts
└── providers/
    ├── types.ts             # provider interface
    └── openai-responses.ts  # current optional server provider adapter
```

The floating Heni UI calls `/api/v1/heni/chat`. Known administrative intents remain on the existing deterministic application flow. A configured model is used only for safe conversational turns that do not already map to a deterministic action. Provider failure falls back instead of breaking patient workflows.

## Fine-tuned model readiness

`HENI_FINE_TUNED_MODEL_ID` is the selection point for a future validated fine-tuned model. The UI and application domain do not need to know the vendor-specific model ID. Until an actual model artifact has been trained/evaluated, this is architecture readiness rather than a claim that fine-tuning is complete.

See [`FINE_TUNING.md`](FINE_TUNING.md).

## State-changing actions

Booking/cancel/reschedule require explicit user confirmation before the write occurs. Model text cannot self-declare that the caller confirmed an action. Production hardening should bind confirmation to a server-issued action/session token so the confirmation is independently verifiable.

## Dynamic knowledge

The following should come from backend/domain tools rather than prompt text or training memory:

- patient identity and role;
- appointment records and availability;
- service status and provider instructions;
- hospital route/navigation state;
- journey state;
- account permissions;
- current platform configuration.

Fine-tuning should improve language/style/intent behavior, not memorize mutable patient or hospital operational data.

## Evaluation

Keep deterministic safety/intent evaluations, plus future model evaluations for Tunisian Derja, Derja/French code-switching, French, English, hallucination, clinical-boundary refusal, tool selection, explicit confirmation, privacy leakage and regression by model version.
