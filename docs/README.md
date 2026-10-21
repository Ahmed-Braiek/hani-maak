# Hani Maak Documentation Guide

This index separates the **current Alzheimer caregiver-first application** from the **historical Future Health Connectathon patient-journey prototype**. A documented feature is not automatically deployed, clinically validated or ready for real patient data.

## Current caregiver project

- [Root README](../README.md) — project purpose, capabilities and maturity, architecture, setup, demo, testing and contributor information
- [Current architecture](https://github.com/Ahmed-Braiek/hani-maak/blob/main/docs/architecture/CURRENT_ARCHITECTURE.md) — observed Flutter / Next.js / FastAPI / Supabase architecture
- [Current schema audit](https://github.com/Ahmed-Braiek/hani-maak/blob/main/docs/interoperability/CURRENT_SCHEMA_AUDIT.md) — normalized caregiver schema, demo-state legacy and privacy gaps
- [Integrated interoperability action plan](https://github.com/Ahmed-Braiek/hani-maak/blob/main/docs/interoperability/ACTION_PLAN_v0.1.md) — team workstreams and proposed review gates
- [Clinical validation audit](https://github.com/Ahmed-Braiek/hani-maak/blob/main/docs/interoperability/openehr/CLINICAL_VALIDATION_AUDIT.md) — gaps requiring qualified clinical review
- [Initial FHIR use cases](https://github.com/Ahmed-Braiek/hani-maak/blob/main/docs/interoperability/fhir/USE_CASES.md) — proposed data exchange scenarios, **not a working hospital integration**
- [Security and synthetic-demo changes — merged PR #61](https://github.com/Ahmed-Braiek/hani-maak/pull/61) — hardening and authenticated synthetic demo-account flow; browser sign-in/dashboard verified, other E2E and isolation checks pending

The linked research files are now available on `main`: [PR #60](https://github.com/Ahmed-Braiek/hani-maak/pull/60), [PR #61](https://github.com/Ahmed-Braiek/hani-maak/pull/61) and [PR #62](https://github.com/Ahmed-Braiek/hani-maak/pull/62) were merged on 21 October 2026. The dedicated synthetic Auth demo account was subsequently provisioned; complete E2E and security verification remain outstanding.

## Developing and testing

- [Contribution guidelines](../CONTRIBUTING.md) — branch/PR conventions and quality expectations
- [Security reporting](../SECURITY.md) — private vulnerability reporting
- [Hani agent service](../apps/heni-agent/README.md) — FastAPI runtime, chat/voice/OCR interfaces and server-side configuration; check historical descriptions
- [Local development for the earlier competition application](setup/LOCAL_DEVELOPMENT.md) — **legacy** setup and data-reset instructions; do not run shared demo resets in production
- [Testing strategy for competition code](testing/TESTING_STRATEGY.md) — currently documented test categories; additional caregiver E2E testing needed
- [License status](../LICENSE.md) — no open-source license currently granted

For the Flutter caregiver application, start in `apps/mobile/` and follow the commands in the root README. The compiled Flutter production web bundle is a build artifact; source changes must be compiled before a preview reflects them.

## Historical competition documents

The following reference an earlier patient/staff appointment and hospital-navigation application and **should not be used as current caregiver product specifications**:

| Document | Historical focus |
|---|---|
| [Repository guide](REPOSITORY_GUIDE.md) | Patient/staff journey and competition walkthrough |
| [Architecture overview](architecture/OVERVIEW.md) | Next.js patient/staff UI, scheduling and legacy voice bridge |
| [Heni AI](ai/HENI.md) and [voice](ai/VOICE.md) | Administrative patient-journey assistant / previous voice model |
| [RBAC roles](roles-and-permissions/RBAC.md) | Competition Doctor / Administration / Super Admin permissions |
| [Feature matrix](FEATURE_MATRIX.md) | Historical feature inventory |
| [Build status](BUILD_STATUS.md) | Old competition packaging, not current GitHub CI |
| [Known limitations](KNOWN_LIMITATIONS.md) | Historical competition limitations |
| [Production path](PRODUCTION_PATH.md) | Earlier evolution proposal |
| [Competition runbook](COMPETITION_RUNBOOK.md) | Historical presentation workflow |

We retain these files for provenance and engineering context; do not silently delete or reinterpret them as current facts.

## Safety and documentation policy

- Use synthetic examples; never commit identifiable medical content or private contact details.
- Distinguish implemented routes from demonstrated behavior and from clinically reviewed features.
- Never claim operational emergency triage, clinical approval, a hospital pilot or a live FHIR/openEHR interface without traceable evidence.
- Treat PRs as drafts until reviewed and merged by the maintainer.
