# Hani Maak — run this first

```bash
cp .env.example .env.local
npm install
npm run clean
npm run demo:reset
npm run dev
```

Open `http://localhost:3000`.

## Competition tabs to prepare

1. `http://localhost:3000/present`
2. `http://localhost:3000/patient`
3. `http://localhost:3000/voice-lab`
4. `http://localhost:3000/staff`
5. `http://localhost:3000/staff/calls`

Use Chrome/Chromium if you want browser microphone recognition. Typing is always a safe fallback.

For the AR demo, open `/patient/map/ar` on a phone or responsive browser. Camera access works on localhost or HTTPS.

Run `npm run demo:reset` immediately before going on stage.
