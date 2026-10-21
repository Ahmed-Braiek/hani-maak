# Interoperability and Clinical Data — Reviewer Guide

**Status:** Draft foundation for discussion, updated 21 October 2026.  
**Audience:** Lloyd Williams, Aditya Ayyagari, Hani Maak clinical and technical contributors.  
**Scope:** Alzheimer's family caregiver information, openEHR modeling assessment and potential FHIR exchange. **No hospital integration or clinical approval is claimed.**

## Suggested advisor reading package

**Read first (the three primary links to include in the follow-up email):**

1. [Executive Summary](EXECUTIVE_SUMMARY.md) — brief overview of what exists, completed research, open choices and questions
2. [Advisor Brief](ADVISOR_BRIEF.md) — technical framing, initial standards direction and requested guidance
3. [Integrated Action Plan](ACTION_PLAN_v0.1.md) — proposed responsibilities, milestones and dependencies (still provisional)

**Supporting technical material (available for deeper review, not required first reading):**

| Document | Scope |
|---|---|
| [Current Architecture](../architecture/CURRENT_ARCHITECTURE.md) | Current observed application and service boundaries |
| [Clinical-Data and Provenance Matrix](CLINICAL_DATA_PROVENANCE_MATRIX.md) | All 48 live public tables, source and privacy gaps |
| [openEHR Archetype Landscape](openehr/ARCHETYPE_LANDSCAPE.md) | Sixteen published/development CKM candidates and reuse caveats |
| [FHIR Use Cases](fhir/USE_CASES.md) | Seven proposed exchange scenarios |
| [FHIR Mapping v0.1](fhir/FHIR_MAPPING_v0.1.md) | Candidate source-field-to-FHIR R4 resource mapping |
| [Current Schema Audit](CURRENT_SCHEMA_AUDIT.md) | Normalized versus legacy demonstration state |
| [Clinical Validation Audit](openehr/CLINICAL_VALIDATION_AUDIT.md) | Clinical evidence and review gaps |
| [Repository QA Audit](../REPOSITORY_QA_AUDIT_2026-10-20.md) | Internal security/repository observations; not external clearance |

**Important:** Documents are currently on **draft PR #60's** `docs/interoperability-foundation` branch, not merged into `main`. The full external-sharing/privacy audit in Phase 3 is still required before sending links. PR #61 demo hardening and PR #62 public README updates are separate, unmerged work.

## Three questions to resolve first

1. **Clinical scope:** What is the smallest medically meaningful *Alzheimer's caregiver information model* and what requires qualified clinician verification? Review existing openEHR archetypes before proposing custom content.
2. **Exchange use case:** Should the first synthetic FHIR proof of concept cover verified patient context, medication reconciliation, or caregiver/proxy authorization? Which hospital interfaces and profiles actually exist?
3. **Privacy:** What is the appropriate boundary between the patient's clinical record and the caregiver's personal conversations, distress and wellbeing? No default export of private caregiver material.

## Current evidence and limitations

- Flutter caregiver app and Next.js API deployed on Vercel; Hani FastAPI agent handles configured conversational and live voice flows.
- Supabase currently contains normalized caregiver-domain tables **and** a legacy demo-state singleton; the canonical data mapping is not finalized.
- The checked agent reported emotion analysis disabled despite a separate online experimental inference service.
- Ten dilemma scenarios were labeled validated without corresponding database clinical-content reviews. This is not proof of clinician sign-off.
- The team has not verified a formal hospital pilot, implemented FHIR/openEHR exchange, or a Carefluence platform agreement.
- Demo authentication/public repository cleanup are handled separately in draft PRs [#61](https://github.com/Ahmed-Braiek/hani-maak/pull/61) and [#62](https://github.com/Ahmed-Braiek/hani-maak/pull/62).

## Next 14-day checkpoint

The integrated plan defines a **provisional, relative 14-day review cycle** based on the Thursday sprint and team responses. Salma reported accepting openEHR co-coordination at approximately 8 hours/week; Hela/Eya/Emna/Ahmed participation in new assignments requires confirmation. The first email requests **early scope feedback**—not an assertion that the Day-14 outputs or hospital discovery are complete.

## Proposed review gate

**Before selecting a standards implementation:** confirm workstream owners and availability, a small clinical dataset, two or three use cases, caregiver/proxy access requirements, and the evidence expected from hospital discovery. Only then proceed to a *synthetic* prototype. Avoid patient data, real hospital write-back and diagnostic claims at this stage.

## Ownership and communication

- **Adam:** coordination, technical architecture, consolidated review materials.
- **Salma and Hela:** clinical-data/openEHR investigation and hospital communication.
- **Eya:** clinical, privacy and safety review (subject to confirmation).
- **Ahmed:** proposed FHIR technical lead; implementation capacity to confirm.
- **Emna:** proposed engineering/QA contribution; participation to confirm.

This review package is designed to solicit feedback, not to imply endorsement by the named advisors. No files in this PR should be used as production migrations or treatment guidance.
