# Hani Maak — هاني معاك

**A multilingual caregiver-support companion for families caring for people living with Alzheimer's disease.**

Hani Maak helps an informal or family caregiver organize day-to-day care, communicate with Hani by text or voice, coordinate tasks, manage reminders and access supportive resources. It is an evolving **demonstration and research prototype**, not a clinical decision system, an emergency response service or a hospital-integrated patient record.

## Start here

- **Current Flutter caregiver application:** [Public web demonstration](https://hani-maak.vercel.app/flutter/index.html). The publicly documented demo sign-in is a **local UI shortcut**, not a real authenticated caregiver account. Backend features may be unavailable on hardened deployments until a limited, authenticated demo identity is set up.
- **Agent service:** FastAPI Hani on Vercel for text and live voice. Real-time emotion analysis was disabled in the verified Hani runtime.
- **Data:** Supabase-backed normalized caregiver tables coexist with an older demonstration JSON-state system. Neither should be presented as a fully reconciled clinical record.
- **Safety:** no autonomous diagnosis, prescriptions, dosage modification, guaranteed emergency alerting or approved hospital exchange.

## What is demonstrated and what is not yet validated

| Area | State |
|---|---|
| Flutter caregiver experience and multilingual text/voice paths | Implemented; end-to-end reliability and multilingual clinical quality not yet certified |
| Caregiver/care-recipient relationships, care tasks, medications, incidents and wellbeing | Product/domain flows implemented at different maturity levels; synthetic demo |
| Caregiver chat and voice history | Database persistence observed; retention and permission behavior need further testing |
| Caregiver summaries, handoffs, notifications and questionnaires | Mixed implemented, partial and planned functionality; verify enabled deployment independently |
| Emotion analysis | Experimental separate service; disabled in the inspected Hani agent |
| Clinical guidance and dilemma scenarios | Clinical-review evidence incomplete; do not describe as independently validated |
| openEHR/FHIR / hospital DMI integration | Design exploration, **not implemented or approved** |

## Repository layout

- `apps/mobile/` — Flutter caregiver experience
- `apps/web/` — Next.js API and compiled Flutter web host; also contains older patient-journey competition routes
- `apps/heni-agent/` — Python/FastAPI Hani agent
- `apps/emotion-service/` — experimental independent service
- `apps/voice-bridge/` — earlier voice-bridge implementation, not assumed to be the current caregiver voice path
- `supabase/` — historical database definitions and migrations; running schema must be reconciled
- `docs/` — architecture, safety, review and interoperability documents

## Setup and security

Review [local development instructions](docs/setup/LOCAL_DEVELOPMENT.md), [security policy](SECURITY.md), and [current limitations](docs/KNOWN_LIMITATIONS.md). Never add real patient or caregiver information to demo fixtures, source control, build logs or model prompts.

Production credential values are not required to read or build the repo. Real authenticated deployment requires proper Supabase authorization, object ownership, data minimization and clinical/legal governance. **Do not use the public demo password as an actual service password.**

## Earlier competition implementation

The repository also retains a **historical patient-journey, appointments, staff, indoor-map and AR prototype** for the Future Health Connectathon. Its routes and documentation are retained as legacy context; they do not define the current caregiver-first product. See [historical repository guide](docs/REPOSITORY_GUIDE.md) and [original competition limitations](docs/KNOWN_LIMITATIONS.md). Avoid running legacy demo reset operations against shared state.

## Technical review and interoperability

The working clinical-data/openEHR and FHIR plan is maintained in [draft PR #60](https://github.com/Ahmed-Braiek/hani-maak/pull/60) until merged. The [security containment patch in draft PR #61](https://github.com/Ahmed-Braiek/hani-maak/pull/61) separately restricts legacy APIs and hardcoded demo identity access; **draft PRs are not deployed to production**.

Clinical collaboration and hospital discovery remain exploratory. No live FHIR endpoint, clinical pilot or formal Carefluence platform integration is confirmed.

## Contributors

See [AUTHORS.md](AUTHORS.md) for project participants and attribution notes. Contributions should be reviewed and credited based on team confirmation and Git history; account ownership alone is not authorship evidence.
