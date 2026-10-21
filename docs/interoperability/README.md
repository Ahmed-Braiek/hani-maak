# Interoperability and Clinical Data — Reviewer Guide

**Status:** Draft foundation for discussion, 20 October 2026.  
**Audience:** Lloyd Williams, Aditya Ayyagari, Hani Maak clinical and technical contributors.  
**Scope:** Alzheimer's family caregiver information, openEHR modeling assessment and potential FHIR exchange. **No hospital integration or clinical approval is claimed.**

## Recommended reading order

| Sequence | Document | Reviewer focus |
|---|---|---|
| 1 | [Integrated Action Plan](ACTION_PLAN_v0.1.md) | Proposed team responsibilities, deliverables, dependencies and review questions |
| 2 | [Current Architecture](../architecture/CURRENT_ARCHITECTURE.md) | Verified components, demo/production distinctions and open engineering checks |
| 3 | [Clinical-Data and Provenance Matrix](CLINICAL_DATA_PROVENANCE_MATRIX.md) | All 48 live tables: source/verification fields, caregiver privacy and proposed sharing gates |
| 4 | [Current Schema Audit](CURRENT_SCHEMA_AUDIT.md) | Normalized caregiver data vs legacy JSON demo-state, access and provenance |
| 5 | [openEHR Archetype Landscape](openehr/ARCHETYPE_LANDSCAPE.md) | 16 CKM models, published vs in-development, caregiver/provenance gaps |
| 6 | [Clinical Validation Audit](openehr/CLINICAL_VALIDATION_AUDIT.md) | Clinical sign-off gap, boundaries, escalation responsibilities |
| 7 | [FHIR Use Cases](fhir/USE_CASES.md) | Candidate read-first use cases, identity, consent, source and authorization needs |
| 8 | [FHIR Source-to-Resource Mapping v0.1](fhir/FHIR_MAPPING_v0.1.md) | Observed field crosswalk, proposed FHIR R4 vocabulary, authorization and non-mapping gates |
| 9 | [Phase 1 Technical and Clinical Claims Review](PHASE1_TECHNICAL_CLINICAL_REVIEW.md) | CKM revision corrections, FHIR R4 semantic checks, remaining clinical evidence gaps |
| 10 | [Repository QA Audit](../REPOSITORY_QA_AUDIT_2026-10-20.md) | Read-only technical risks and remediation priorities |

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
