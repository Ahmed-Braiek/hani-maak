# Hani Maak — Executive Summary for Interoperability Advisors

**Prepared for:** Lloyd Williams and Aditya Ayyagari  
**Updated:** 21 October 2026 · **Status:** Initial technical research and scope discussion, **not** a deployment proposal  
**Project:** Hani Maak (هاني معاك) — a multilingual companion for family and informal caregivers supporting someone living with Alzheimer's disease

> **Our request:** We would appreciate your guidance on a **minimal clinically meaningful information model**, which **openEHR archetypes to investigate**, and which **single FHIR exchange use case** should become a carefully governed, synthetic first proof of concept.

## The system today

The evolving Hani Maak prototype includes a **Flutter caregiver application**, a **Next.js application API**, a **FastAPI Hani conversational agent** with configured text/voice paths, and **Supabase/PostgreSQL**. Its product concepts include care coordination, medication reminders, incidents, familiar activities, caregiver wellbeing and conversations.

Source and service inspection confirms the architecture and database structures, **not** complete end-to-end reliability, authorized clinical use or validated AI behavior. The database contains normalized caregiver-related tables **alongside older demonstration JSON state**, which requires reconciliation before a production data contract is selected.

## Work prepared since our demonstration

| Reviewable deliverable | What it contributes | Important limit |
|---|---|---|
| [Integrated Action Plan](ACTION_PLAN_v0.1.md) | Proposed clinical/openEHR, FHIR, engineering, hospital-discovery and research workstreams | Assignments and 14-day checkpoints remain provisional |
| [Current Architecture](../architecture/CURRENT_ARCHITECTURE.md) | Observed Flutter, Next.js, Hani agent and database boundaries | Authentication, integrations and flows still need E2E testing |
| [Clinical-Data & Provenance Matrix](CLINICAL_DATA_PROVENANCE_MATRIX.md) | Read-only mapping of **all 48** current public Supabase tables; identifies who/what each field may concern, origin and privacy gaps | Schema metadata does not prove clinical validity or consent |
| [openEHR Archetype Landscape](openehr/ARCHETYPE_LANDSCAPE.md) | **16** catalogued CKM candidates with lifecycle and version considerations; reuse ideas for patient history, diagnosis, medication and social context | No reviewed/openEHR template or locally validated clinical model yet |
| [FHIR Mapping v0.1](fhir/FHIR_MAPPING_v0.1.md) | Field-level **candidate** mappings for three priority use cases, with explicit non-mappings for unverified and caregiver-private data | R4 is a reference vocabulary only; no API, profiles or hospital endpoint |

**Important findings:** An Alzheimer stage text field is not a verified diagnosis. A medication `verified` flag is not an authenticated prescription. A caregiver relationship is not an automatically valid hospital proxy authorization. Ten local dilemma scenarios are labelled `validated` but the inspected clinical-review registry had no rows; this is **not evidence of independent clinician approval**.

## Proposed first research direction

We propose **separating clinical information modeling from exchange mechanics**:

- **Clinical data/openEHR track:** select a very small, meaningful Alzheimer/caregiving dataset; distinguish *caregiver-reported*, *professionally attested*, and *AI-generated* information; examine existing openEHR archetypes before drafting a new template. An explicitly attributed, **synthetic patient symptom/history report** may be a useful first modeling exercise.
- **FHIR/interoperability track:** narrow the exchange to **one** agreed, read-oriented use case: (UC-01) authorized patient context; (UC-02) professionally sourced medication information; or (UC-03) caregiver/proxy identity and authorization. Confirm version, profiles, identifiers, consent, audit and access failures **before** building a connector.

Caregiver-private conversations, wellbeing, family conflicts and experimental emotion inferences must **not** enter the care recipient's clinical record by default.

## Four questions for your guidance

1. **Scope:** What is the smallest clinically meaningful Alzheimer-related dataset and which openEHR archetypes/templates should we review first?
2. **Use case:** Which one of UC-01/02/03 would make the best initial *synthetic, read-oriented* FHIR exercise—and what source evidence is required?
3. **Privacy and authority:** How should we distinguish the care recipient from the reporting caregiver, verify proxy rights, manage consent/revocation and record provenance?
4. **Next review:** What would be most useful for a short follow-up review—an agreed dataset, a single source-to-archetype draft, or a synthetic FHIR example? We welcome corrections to the direction.

## Next step and review status

Our immediate next deliverables would be an **advisor-selected minimum dataset**, a documented review of the selected CKM archetype(s), an approved first exchange scenario and a **synthetic** mapping/test plan. A hospital pilot, live exchange, clinical approval, Carefluence integration or research publication is **not** agreed or implemented.

This summary and its linked materials are **draft GitHub branch documents** (PR #60), not yet merged into `main`. **External sharing is subject to the remaining repository/privacy check (Phase 3) and user approval.** The preliminary repo audit identified issues in historical/current public materials, so do not interpret the existence of this page as external-sharing clearance.

**Next read:** [Advisor Brief](ADVISOR_BRIEF.md) (context and requested decisions) · [Action Plan](ACTION_PLAN_v0.1.md) (proposed ownership and follow-up). Full research navigation: [Documentation Guide](README.md).
