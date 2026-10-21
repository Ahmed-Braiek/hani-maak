# Hani Maak | هاني معاك

**A multilingual, caregiver-first companion for families supporting someone living with Alzheimer's disease.**

Hani Maak brings everyday caregiving information, coordination and supportive conversation into one experience. It is designed primarily for **family and informal caregivers**; the person receiving care can also take part in familiar-memory and activity experiences through the caregiver's device.

> **Project status — October 2026:** Active research and engineering **prototype**, demonstrated with synthetic caregiver data. It is **not** a medical device, clinical diagnostic/triage service, guaranteed emergency-response system, or connected hospital record. Features are at different maturity levels and require additional quality, security and clinical review before real-world deployment.

[Caregiver demo](https://hani-maak.vercel.app/flutter/index.html) · [Documentation](docs/README.md) · [Contributing](CONTRIBUTING.md) · [Security](SECURITY.md) · [License status](LICENSE.md)

## Contents

- [Why Hani Maak](#why-hani-maak)
- [Who it supports](#who-it-supports)
- [Features and maturity](#features-and-maturity)
- [System architecture](#system-architecture)
- [Repository structure](#repository-structure)
- [Try the demo](#try-the-demo)
- [Develop locally](#develop-locally)
- [Configuration](#configuration)
- [Testing and quality](#testing-and-quality)
- [Privacy and clinical safety](#privacy-and-clinical-safety)
- [Interoperability and roadmap](#interoperability-and-roadmap)
- [Project team and contribution](#project-team-and-contribution)

## Why Hani Maak

Caring for a person living with Alzheimer's disease often means tracking medication instructions, daily activities, changes in behavior, appointments, responsibilities and the caregiver's own wellbeing across several disconnected tools. Hani Maak explores how an accessible, multilingual digital companion can help caregivers coordinate these **non-diagnostic** tasks and prepare better information for discussions with qualified professionals.

Our initial focus is **Alzheimer's family caregiving**. Possible extension to other caregiving contexts is future research, not the current validated scope.

## Who it supports

| Person or role | Intended experience |
|---|---|
| **Primary caregiver** | Daily overview, assistance from Hani, care notes, tasks, medication tracking, wellbeing and private conversations |
| **Care recipient** | Familiar activities and memory prompts facilitated by the caregiver; **not** formal cognitive testing |
| **Family / Care Circle** | Shared responsibilities, permissions and coordination where supported and authorized |
| **Healthcare professional (future governed workflow)** | Potentially receive an explicit, reviewed, minimal-necessary care summary with appropriate permission; **no confirmed hospital integration** |

Caregiver information and the care recipient's clinical information have different privacy boundaries. Family membership does not automatically authorize access to clinical records.

## Features and maturity

**Legend:** *Implemented* means code and/or data-model evidence exists; it does **not** establish full end-to-end reliability. *Experimental* is a prototype requiring validation. *Exploratory* is a proposal, not an integration.

| Area | Current implementation evidence | Important limit |
|---|---|---|
| Caregiver dashboard and context | Flutter views, caregiver-patient relationship model and synthetic data | Browser/mobile E2E and full access tests pending |
| **Hani text chat** | Flutter client, Next.js proxy, FastAPI agent and conversation/message persistence | AI quality, safeguarding and multilingual evaluation ongoing |
| **Hani live voice** | Signed voice-session path and Gemini Live agent deployed | Real device/audio and provider failure testing pending |
| Daily care and Care Circle | Care tasks, assignments, task requests, reminders and permissions modeled | Some multi-user flows and alert delivery need verification |
| Medication support | Caregiver-entered lists, schedules, event tracking, reviewed OCR workflow code | Not prescribing or dose advice; OCR accuracy requires human review |
| Incidents and dilemmas | Incident records and scenario-based support concepts | Clinical sign-off evidence incomplete; never assume automatic urgent escalation |
| Memory and activities | Familiar people, places, routines, music and activity records | Supportive engagement only, not a diagnostic assessment |
| Caregiver wellbeing | Private check-ins and questionnaire-oriented schema | Screening instruments and referrals not clinically validated |
| Professional handoff and summaries | UI, data model and partial delivery workflows | Delivery/consent and actual clinician integration unproven |
| Notifications and WhatsApp | UI, local reminder paths and optional provider adapters | Server push/provider setup may be absent; no delivery guarantee |
| Emotion inference | Separate experimental Railway service | **Disabled in the inspected Hani agent**; no approved clinical use |
| FHIR / openEHR / hospital EHR | Initial research and documentation | **Not implemented or approved** |

An implemented route, screen or database table does not prove a production-ready feature. [Current limitations](docs/KNOWN_LIMITATIONS.md) primarily describe the **historical competition system**; the current caregiver audit is in [Draft PR #60](https://github.com/Ahmed-Braiek/hani-maak/pull/60).

## System architecture

The current caregiver-focused implementation spans **Flutter**, a **Next.js application API**, a separate **FastAPI Hani agent**, **Supabase/PostgreSQL** and external AI services.

~~~mermaid
flowchart TD
    User["Family caregiver"] --> App["Flutter application / web bundle"]
    App --> Auth["Supabase Auth + demonstration sign-in"]
    App --> API["Next.js caregiver API on Vercel"]
    App -. "signed real-time voice session" .-> Agent["FastAPI Hani agent on Vercel"]
    API --> DB[("Supabase: normalized caregiver data")]
    API --> Legacy[("Supabase: legacy demo-state JSON")]
    API --> Agent
    Agent --> AI["Gemini text / Live voice"]
    Agent -. "optional, not enabled at last check" .-> Emotion["Experimental Railway emotion service"]
~~~

This is a **logical overview** of observed code and deployment paths, not a proof that every request traverses every service. The running Supabase database contains both normalized caregiver records and an older single-record demo-state path. The repository's historical SQL does **not** fully represent the running normalized schema.

**How it works:** Flutter requests approved context/actions from Next.js; the Hani agent handles conversational text and voice with tightly scoped backend tools. Caregiver authorization, underlying application facts and sensitive data boundaries must remain server responsibilities—not model-generated assumptions.

- Current-state architecture and schema analysis: [Draft interoperability documentation PR #60](https://github.com/Ahmed-Braiek/hani-maak/pull/60).
- Demo authentication hardening and synthetic shared-account work: [Draft security PR #61](https://github.com/Ahmed-Braiek/hani-maak/pull/61).

## Repository structure

~~~text
hani-maak/
├── apps/
│   ├── mobile/           Flutter caregiver application (mobile + web source)
│   ├── web/              Next.js backend and compiled Flutter web host
│   ├── heni-agent/       Python/FastAPI chat, voice and OCR service
│   ├── emotion-service/  Experimental independent inference service
│   └── voice-bridge/     Older competition/PSTN voice integration
├── docs/                 Product, architecture, technical and clinical notes
├── supabase/             Historical SQL and migrations; reconcile with live DB
├── tests/                TypeScript domain and API tests
├── evals/                Synthetic deterministic evaluation scenarios
├── scripts/              Development/competition utilities
└── .github/workflows/    CI and build workflows
~~~

The repository also retains an **earlier Future Health Connectathon patient-journey prototype** (patient/doctor/staff appointment workflows, indoor navigation and AR). That code and older documentation provide historical context. They should not be confused with the present caregiver-first roadmap or presented as integrated hospital functionality.

## Try the demo

**Web entry:** [Hani Maak caregiver demonstration](https://hani-maak.vercel.app/flutter/index.html).

- Use **synthetic information only**. Never enter real patient records, prescription photographs, private telephone numbers or identifiable medical details.
- The currently deployed build and the unmerged security PR can behave differently. **Do not treat a UI demo login as an authenticated clinical account.**
- [PR #61](https://github.com/Ahmed-Braiek/hani-maak/pull/61) is preparing a dedicated email/password Supabase demo account backed by the **existing fictional Mariem/Fatma scenario**. At this stage, that account still needs provisioning and end-to-end validation. **No working credentials are published here.**
- The demo is not a real care service. Hani is not qualified to give medical diagnoses or handle emergencies.

## Develop locally

### 1. Prerequisites

- **Node.js 22.6+** and npm (the repository test runner uses Node's TypeScript type-stripping).
- **Flutter SDK** compatible with the constraints in [apps/mobile/pubspec.yaml](apps/mobile/pubspec.yaml).
- **Python 3** and pip for the optional Hani agent.
- Optional, separately configured **Supabase project** for authenticated caregiver workflows.

### 2. Next.js API / legacy web host

~~~bash
git clone https://github.com/Ahmed-Braiek/hani-maak.git
cd hani-maak
npm ci
npm run dev
~~~

The Next.js host should start on [http://localhost:3000](http://localhost:3000). Its root pages include older competition-era experiences; the caregiver-first Flutter app is maintained under `apps/mobile/` and compiled into `apps/web/public/flutter/` by the web build workflow.

For local environment configuration, copy the **variable names** from [.env.example](.env.example) into `apps/web/.env.local` or follow the specific subsystem documentation. Do **not** copy production secrets into your workstation or commit any `.env.local`.

**Do not run `npm run demo:reset` or `npm run fresh` against shared/production data.** These scripts belong to the historical competition demo and may reset state.

### 3. Flutter caregiver application

~~~bash
cd apps/mobile
flutter pub get
flutter analyze
flutter run -d chrome \
  --dart-define=HANI_API_BASE=http://localhost:3000 \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLIC_KEY
~~~

Use **a test Supabase project and publishable key**, never a secret/service-role key. Replace example values with your own test configuration. Authenticated flows also depend on a correctly configured backend, account, profile and caregiver-patient relationship. Without those, sign-in and data changes may fail even if Flutter builds successfully.

If the Flutter `web/` platform folder is missing, see the commands used by [.github/workflows/flutter-production-web.yml](.github/workflows/flutter-production-web.yml) to generate it. The deployed compiled bundle must be **rebuilt** after Flutter source changes; a Next.js-only preview does not automatically update that bundle.

### 4. Optional Hani agent

~~~bash
cd apps/heni-agent
python -m venv .venv
# Activate .venv using your operating system's instructions
pip install -r requirements.txt
# Configure the required server-side values in .env
python -m uvicorn app.main:app --host 127.0.0.1 --port 8080
~~~

The agent requires correctly configured model/backend settings for full AI functionality. Its [README](apps/heni-agent/README.md) documents endpoints, model selection and safety limitations; older patient-journey wording in that file is historical and should be reviewed separately.

## Configuration

Never commit credentials, use real patient information in fixtures, or expose server-only keys through Flutter / `NEXT_PUBLIC_*` variables.

| Variable | Used by | Purpose |
|---|---|---|
| `HANI_API_BASE` | Flutter build | URL of the matching Next.js API |
| `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` | Flutter build | Public Supabase client configuration |
| `NEXT_PUBLIC_SUPABASE_URL` | Next.js | Public project URL |
| `SUPABASE_SECRET_KEY` | Next.js **server only** | Privileged data access, subject to authorization |
| `HENI_AGENT_BASE_URL`, `HENI_AGENT_WSS_URL` | Next.js | Text/voice agent connection |
| `HENI_AGENT_SHARED_SECRET` | Next.js and agent **server only** | Trusted service-to-service calls |
| `GEMINI_API_KEY` | Hani agent **server only** | Model access |
| `DEMO_ACCOUNT_USER_ID`, `PUBLIC_SYNTHETIC_DEMO` | **Proposed by PR #61**, Next.js | Limit provisioning to an approved synthetic demo account |

Availability varies by deployment and branch. The [root environment example](.env.example) contains older competition flags as well as the Next.js settings. The Hani agent documents its **own** settings separately.

## Testing and quality

The root package scripts are implemented and used in GitHub CI:

~~~bash
npm ci
npm run typecheck
npm test
npm run evals
npm run voice:check
npm run build
# Or run the aggregated check:
npm run verify
~~~

For Flutter, use `flutter analyze` and `flutter build web --release --base-href /flutter/` with appropriate **test** configuration. PR #61 adds a separate Flutter validation workflow; it is not yet part of `main`.

**What CI proves:** source builds, static checks, deterministic tests and selected agent safety tests. **What it does not prove:** secure end-to-end patient-data handling, clinical safety or language validity, live-device speech reliability, hospital interoperability or completed privacy review.

## Privacy and clinical safety

- **Synthetic data only** in public demos, screenshots, issue reports, evaluations and shared examples.
- The caregiver's private conversations, emotional wellbeing, and family situations must not automatically be shared into the care recipient's clinical record.
- Clinical information should identify its source and distinguish caregiver-reported from professionally verified facts.
- Hani cannot diagnose Alzheimer's stage, prescribe drugs, adjust dosages, or guarantee urgent-response escalation.
- Medication OCR is for **review assistance**, not an authoritative prescription.
- Production use requires verified authentication, authorization, consent, retention policies, safety oversight and applicable legal review.
- Responsible vulnerability reporting: [SECURITY.md](SECURITY.md). Please do not open public issues containing sensitive data.

## Interoperability and roadmap

The team is evaluating **openEHR** for clinical information modeling and **FHIR** for possible future authorized information exchange. The first goal is a small, clinically reviewed dataset and several concrete use cases, **not** an unapproved hospital integration.

| Workstream | Next step | Current status |
|---|---|---|
| Engineering | Reconcile normalized Supabase data, historical demo state and access rules | Audit/review in progress |
| Demo experience | Complete authenticated, synthetic Mariem/Fatma showcase | [Draft PR #61](https://github.com/Ahmed-Braiek/hani-maak/pull/61) |
| Public repository | Accurate documentation, attribution and removal of unnecessary test data | [Draft PR #62](https://github.com/Ahmed-Braiek/hani-maak/pull/62) |
| Clinical data / openEHR | Clinical inventory, provenance, review evidence and reusable archetype study | [Draft PR #60](https://github.com/Ahmed-Braiek/hani-maak/pull/60) |
| FHIR | Prioritize use cases, proxy identity, consent, resource mapping and synthetic POC | Exploratory |
| Hospital engagement | Technical and clinical discovery through authorized channels | No formally approved pilot or live EHR exchange |

The team may explore relationships with hospitals and technical advisors, but no clinical trial, formal hospital pilot or Carefluence integration is confirmed by this repository.

## Project team and contribution

Hani Maak is developed by a multidisciplinary team. Current contributor attribution and responsibilities are listed in [AUTHORS.md](AUTHORS.md); repository ownership alone does not determine academic or legal authorship.

See [CONTRIBUTING.md](CONTRIBUTING.md) for development and review standards, [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for collaboration expectations, and [SUPPORT.md](SUPPORT.md) for issue reporting.

**License:** This public repository is **not currently open-source licensed**. Read [LICENSE.md](LICENSE.md) before copying, redistributing or reusing its contents. Publishing source code does not waive the contributors' rights.

---

*Hani Maak is built to support caregivers—not to replace clinicians, emergency services, or patients' formal care relationships.*