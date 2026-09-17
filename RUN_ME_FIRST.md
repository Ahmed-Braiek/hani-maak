# Hani Maak - Run This First

## Local competition setup

```bash
cp .env.example .env.local
npm install
npm run clean
npm run demo:reset
npm run dev
```

Open `http://localhost:3000`.

For the zero-external-service demo, keep `HENI_AI_PROVIDER=development` and use the local/file data backend. Heni's deterministic administrative flow, typed fallback and browser voice demo continue to work without a paid model provider.

## Competition tabs

1. `/present`
2. `/patient`
3. `/patient/map`
4. `/patient/map/ar?demo=nuclear-medicine`
5. `/voice-lab`
6. `/staff`
7. `/staff/calls`

Use a current Chrome/Chromium browser for the best chance of microphone support. Typed interaction remains the fallback.

Run `npm run demo:reset` immediately before the presentation when using the synthetic local demo store.

## Verify before submission or demo

```bash
npm run verify
```

This checks TypeScript, tests, deterministic Heni evaluations, voice-bridge syntax and the production web build.

For the repository reading order, see [`docs/REPOSITORY_GUIDE.md`](docs/REPOSITORY_GUIDE.md).
