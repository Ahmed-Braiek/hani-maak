# Hani Maak — Interoperability Advisor Brief

**For discussion with:** Lloyd Williams and Aditya Ayyagari  
**Prepared by:** Hani Maak team, coordinated by Adam Ben Arbia  
**Status:** Technical review draft, updated 21 October 2026  
**Purpose:** Present our current Alzheimer's caregiver prototype, explain a proposed clinical-data/openEHR and FHIR research direction, and request targeted feedback before choosing an implementation path.

> **Scope and maturity:** Hani Maak is a caregiver-support research prototype using synthetic demonstration records. We are **not** claiming clinically validated decision support, real hospital access, an implemented FHIR/openEHR interface, a pilot agreement, or a confirmed integration/partnership with Carefluence.

**Start here:** [One-page Executive Summary](EXECUTIVE_SUMMARY.md) → this brief → [Integrated Action Plan](ACTION_PLAN_v0.1.md). Detailed mappings are supporting references, not required first reading.

## 1. What Hani Maak currently is

Hani Maak (**هاني معاك**) is a multilingual companion for family and informal caregivers of people living with Alzheimer's disease. The evolving application offers caregiver context, care tasks and shared responsibilities, medications and reminders, incident notes, familiar activities, wellbeing support, and interactions with **Hani** in text and live voice. Implemented features have different levels of operational and clinical verification.

**Verified technical direction:**

- **Caregiver app:** Flutter (web/mobile source).
- **API and hosting:** Next.js caregiver API on Vercel; existing older competition-era routes are being isolated in [security PR #61](https://github.com/Ahmed-Braiek/hani-maak/pull/61).
- **Conversational service:** Python/FastAPI Hani agent with configured Gemini text and live-voice paths.
- **Data:** Supabase/PostgreSQL with normalized caregiver tables, alongside older demonstration JSON state. The relationship between these needs explicit mapping.
- **Clinical safeguards:** AI-generated suggestions are not verified treatment instructions; human review, provenance, consent and appropriate escalation ownership are still design requirements.
- **Demo access:** a dedicated synthetic Mariem/Fatma account is being prepared on PR #61; account provisioning and integrated demonstration remain pending.

See the [current architecture](../architecture/CURRENT_ARCHITECTURE.md), [48-table clinical-data/provenance matrix](CLINICAL_DATA_PROVENANCE_MATRIX.md), [schema audit](CURRENT_SCHEMA_AUDIT.md), and [public repository README under PR #62](https://github.com/Ahmed-Braiek/hani-maak/blob/chore/public-repository-cleanup/README.md) for the detailed baseline.

## 2. Why we are considering clinical-data standards

We want to avoid building a bespoke, poorly evidenced medical-data schema or treating caregiver-entered observations as clinician-authored records.

**Initial research completed:** a [48-table source/provenance matrix](CLINICAL_DATA_PROVENANCE_MATRIX.md) and a [16-candidate openEHR CKM archetype landscape](openehr/ARCHETYPE_LANDSCAPE.md). We now seek clinical guidance on which patient-relevant, source-verifiable fields and published models to prioritize. No locally approved openEHR template has been produced.

**Initial research completed:** [seven candidate FHIR use cases](fhir/USE_CASES.md) and a [field-level preliminary FHIR mapping](fhir/FHIR_MAPPING_v0.1.md) covering three first-review cases. We recommend selecting only **one** read-oriented synthetic use case before building an adapter. Leading options are:

| Proposed use case | Candidate FHIR concepts | Critical question |
|---|---|---|
| Authorized care-recipient context | Patient, Condition, Observation | Who may access which clinically verified facts? |
| Professional medication context | MedicationStatement (reported use), MedicationRequest (genuine order); AllergyIntolerance only if verified allergy data exists | How is professionally sourced medication information distinguished from caregiver reports? |
| Caregiver/proxy access | RelatedPerson, Consent; CareTeam conditional on appropriate care context | How is proxy authority established, scoped and revoked? |

These concepts are **candidates**, not committed FHIR profiles. Neither a hospital's technical capability nor its exchange authorization has been verified. Later consideration may include reviewed incident summaries, provenance/audit and explicitly consented clinical handoffs.

See the [clinical validation audit](openehr/CLINICAL_VALIDATION_AUDIT.md), [FHIR use-case register](fhir/USE_CASES.md) and the [preliminary source-to-resource mapping](fhir/FHIR_MAPPING_v0.1.md). FHIR R4 is used for reference terminology only, not selected as our implementation standard.

## 3. Proposed workstreams

| Workstream | Proposed contributors | First reviewable output |
|---|---|---|
| Clinical data and openEHR | Salma and Hela, with Eya's review as available | **Prepared:** technical matrix and archetype shortlist. **Next:** qualified clinical evaluation and minimal field set |
| FHIR and backend architecture | Adam; Ahmed as proposed technical lead; Emna subject to confirmation | **Prepared:** use cases and draft field mapping. **Next:** select one exchange and authorization contract |
| Product, demo and repository quality | Adam and engineering contributors | Verified current-state diagram, synthetic demo, CI and explicit known limitations |
| Hospital discovery | Salma and Hela | Questions about institutional process, EHR/API capability and governance — **not a formal pilot** |
| Research direction | Salma and Adam, with clinical and technical contributors | Source-linked literature survey and a bounded research concept |

Assignments and the provisional relative 14-day review cycle are further described in the [integrated action plan](ACTION_PLAN_v0.1.md). Not all individual availability or task ownership has been confirmed.

## 4. The guidance we request

We would appreciate Lloyd's and Aditya's perspective on:

1. **A minimal clinical information model:** Which Alzheimer/caregiver concepts need to be represented first, and which existing openEHR archetypes/templates are useful starting points?
2. **The first exchange scenario:** Is a read-oriented synthetic FHIR proof of concept sensible, and which of the three candidate use cases should be prioritized?
3. **Caregiver-to-patient data boundaries:** How should we model informal caregiver roles, revocable proxy permissions, the origin of observations, and the privacy of caregiver wellbeing/conversations?
4. **Learning and validation sequence:** What technical and clinical evidence should we prepare before seeking access to hospital interfaces or involving hospital reviewers?
5. **Practical next collaboration step:** Would a brief follow-up review of the proposed minimum dataset and use-case mapping be useful? We are seeking **advice**, not asserting a partnership.

## 5. What we propose to deliver next

1. **Seek clinical feedback** on the completed [48-table provenance matrix](CLINICAL_DATA_PROVENANCE_MATRIX.md) and [16-candidate openEHR inventory](openehr/ARCHETYPE_LANDSCAPE.md).
2. **Select a minimal dataset** and verify subject, asserter, clinical evidence and caregiver-private boundaries with qualified reviewers.
3. **Review the completed preliminary FHIR mapping**, prioritize **one** read-oriented use case and agree identity, proxy authority, consent and revocation assumptions.
4. Record the **architecture and scope decisions** after advisor feedback, including proposed workstream owners and capacity.
5. **Only after review**, prepare a strictly synthetic draft archetype/template exercise or FHIR example with negative authorization tests; no live hospital write-back.

This is an initial feedback request. **We do not need the proof of concept completed before seeking scope guidance**.

## 6. Navigation

- [Executive summary — recommended first read](EXECUTIVE_SUMMARY.md)
- [Integrated work plan](ACTION_PLAN_v0.1.md)
- [Current system](../architecture/CURRENT_ARCHITECTURE.md)
- [Clinical-data and provenance matrix — all 48 tables](CLINICAL_DATA_PROVENANCE_MATRIX.md)
- [Running schema findings](CURRENT_SCHEMA_AUDIT.md)
- [Clinical validation gaps](openehr/CLINICAL_VALIDATION_AUDIT.md)
- [openEHR archetype landscape — 16 CKM candidates](openehr/ARCHETYPE_LANDSCAPE.md)
- [Candidate FHIR use cases](fhir/USE_CASES.md)
- [Preliminary FHIR field mapping v0.1](fhir/FHIR_MAPPING_v0.1.md)
- [Documentation index](README.md)
- [Repository QA risks](../REPOSITORY_QA_AUDIT_2026-10-20.md)

**We welcome corrections to our assumptions, particularly around clinical-data boundaries and the feasible order of openEHR/FHIR research.** This brief is an invitation to review, not a commitment to implement a hospital interface.
