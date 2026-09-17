# Local Development

## Requirements

- Node.js 20.9 or newer
- npm 10 or newer
- Current Chrome/Chromium recommended for browser microphone demonstrations

## Setup

```bash
git clone https://github.com/Ahmed-Braiek/hani-maak.git
cd hani-maak
cp .env.example .env.local
npm install
npm run demo:reset
npm run dev
```

The web application starts at `http://localhost:3000`.

## Zero-external-service mode

For the safest competition setup:

```text
DEMO_MODE=true
NEXT_PUBLIC_DEMO_MODE=true
HANI_DATA_BACKEND=file
HENI_AI_PROVIDER=development
```

This keeps scheduling, journeys, staff operations, deterministic Heni actions, browser voice fallback and route logic inside the repository.

## Shared Supabase state

If the competition deployment uses Supabase persistence, configure `NEXT_PUBLIC_SUPABASE_URL` and the server-only `SUPABASE_SECRET_KEY` after applying the documented competition state table. Never expose the server secret with a `NEXT_PUBLIC_` prefix.

## Heni model-backed chat

A model provider is optional. Configure server-side values only:

```text
HENI_AI_PROVIDER=openai
HENI_CHAT_MODEL=<validated model id>
HENI_AI_API_KEY=<server secret>
```

If a validated fine-tuned model exists, set `HENI_FINE_TUNED_MODEL_ID`; it takes precedence over the general chat model. Do not claim that a fine-tuned model is active until the model ID, dataset governance and evaluation have actually been completed.

## Verification

```bash
npm run typecheck
npm test
npm run evals
npm run voice:check
npm run build
```

Or:

```bash
npm run verify
```

## Demo reset

`npm run demo:reset` restores deterministic synthetic competition data. Do not run it against a production patient-data environment.
