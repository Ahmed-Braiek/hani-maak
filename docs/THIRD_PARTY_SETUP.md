# Third-party setup

The core web demo intentionally requires no external provider. Add external services only after the local story is stable.

## Live telephone agent — Twilio + OpenAI GPT-Live

Current implementation is in `apps/voice-bridge` and follows the current 2026 GPT-Live/Twilio Media Streams pattern.

Environment:

```bash
OPENAI_API_KEY=...
OPENAI_LIVE_MODEL=gpt-live-1
OPENAI_DELEGATED_MODEL=gpt-5.6-terra
OPENAI_VOICE=marin
HANI_WEB_BASE_URL=http://localhost:3000
VOICE_BRIDGE_PORT=8787
```

Run the web app and bridge separately:

```bash
npm run dev
npm run voice
```

Expose port 8787 with an HTTPS/WSS tunnel, then point a Twilio voice-enabled number’s incoming-call webhook to:

```text
https://YOUR_PUBLIC_HOST/incoming-call
```

The bridge proxies Twilio’s PCMU 8 kHz media to GPT-Live and executes allowlisted Hani Maak application functions through the web API.

Before a real pilot, add Twilio webhook/signature validation, a server-issued confirmation token for write actions, identity verification appropriate to the provider workflow, call retention policy, telecom compliance review and rate limits.

## Optional image extraction

Set:

```bash
OPENAI_API_KEY=...
OPENAI_VISION_MODEL=gpt-5.6-terra
```

`/patient/medicine` will send an image to the Responses API with `store:false` and a structured extraction schema limited to visible package text. If the provider is absent/fails, the app falls back to a deterministic seeded demo.

## Notifications

External sending is off by default.

```bash
ENABLE_EXTERNAL_NOTIFICATIONS=true
TWILIO_ACCOUNT_SID=...
TWILIO_AUTH_TOKEN=...
TWILIO_SMS_FROM=...
RESEND_API_KEY=...
RESEND_FROM=...
```

Adapters live in `apps/web/src/lib/notifications.ts`. Competition mode can mark reminders simulated without sending anything.

## Supabase

The competition build uses a local JSON repository. `supabase/schema.sql` defines the production-oriented relational model and baseline RLS policies. A real migration should replace `db.ts` with repository interfaces that execute the same domain operations on Postgres.
