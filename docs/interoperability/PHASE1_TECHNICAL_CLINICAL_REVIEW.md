# Phase 1 — Technical and Clinical Claims Review

**Date:** 21 October 2026  
**Scope:** Draft PR #60, especially `openehr/ARCHETYPE_LANDSCAPE.md`, `fhir/FHIR_MAPPING_v0.1.md`, `fhir/USE_CASES.md`, `CLINICAL_DATA_PROVENANCE_MATRIX.md`, `CURRENT_SCHEMA_AUDIT.md`, and `ADVISOR_BRIEF.md`.  
**Method:** Cross-check against the primary openEHR CKM catalogue, HL7 FHIR R4 definitions, and the read-only Supabase schema inventory. **No database edits, clinical record exports, API deployment, hospital exchange, or merge performed.**

## Decision and review status

**Suitable for advisor discussion as a clearly labeled research draft after the documented corrections. NOT clinical approval, FHIR/openEHR conformance certification, or evidence that the prototype is safe for real patient data.** The distinction between a *proposed* source-to-resource map and a *working* interface must remain explicit in any email to Lloyd and Aditya.

| Area | Review outcome | Action |
|---|---|---|
| CKM identifier/link consistency | **Corrections made** | Replace outdated Problem/Diagnosis revision link with current main record; verify previously uncertain Symptom/Sign lifecycle; distinguish published Goal from in-development Goal draft |
| CKM inventory comprehensiveness | **Scoped, not exhaustive** | 16 candidates, not proof that no other Alzheimer-specific archetypes exist |
| CKM publication / asset revision semantics | **Clarified** | Same archetype ID can occur in multiple CKM revision/asset records; track both lifecycle and CKM link |
| FHIR R4 resource semantics | **Corrections made** | Clarify informal CareTeam participation; R4 Consent status vs local status; required base fields for MedicationStatement, MedicationRequest and Observation |
| Source/clinical validation in Supabase | **Evidence gap remains** | Boolean flags, timestamps and local professional entries do not establish qualified clinician sign-off |
| Caregiver-private and patient-data separation | **Appropriate conceptual safeguard** | Avoid mapping raw chat, wellbeing, family conflict or unvalidated model-generated distress to a patient's EHR |
| Standards implementation and target hospital | **Not chosen** | FHIR R4 used as reference vocabulary only; profiles/IG, authorization and exchange destination await advisor/hospital discussion |

## 1. openEHR CKM model correction log

| CKM archetype | Previously written | Verified catalogue finding / correction | Primary source |
|---|---|---|---|
| `openEHR-EHR-EVALUATION.problem_diagnosis.v1` | CKM archived revision link `1013.1.169/34`, published `1.0.11` | Main CKM record `1013.1.169` currently published `1.7.4`. **Old link was not imaginary, but it selected an outdated revision.** | [Current Problem/Diagnosis](https://ckm.openehr.org/ckm/archetypes/1013.1.169) · [Archived revision](https://ckm.openehr.org/ckm/archetypes/1013.1.169/34) |
| `openEHR-EHR-CLUSTER.symptom_sign.v2` | Lifecycle/revision not checked | CKM identifies **published 2.1.4**, now recorded accurately. | [Symptom/Sign](https://ckm.openehr.org/ckm/archetypes/1013.1.6769) |
| `openEHR-EHR-EVALUATION.goal.v1` | CKM `1013.1.5012` draft `1.1.1-alpha` presented as only option | Distinct **published 1.1.2** CKM record `1013.1.124` exists for this archetype ID; the draft still exists separately. Changed primary inventory link to published asset, preserved draft history note. | [Published Goal](https://ckm.openehr.org/ckm/archetypes/1013.1.124) · [Draft record](https://ckm.openehr.org/ckm/archetypes/1013.1.5012/) |

**Other 13 catalogue entries:** Record-level identifiers and the previously displayed publication/draft categories were consulted without identifying an additional correction requiring a branch change during this pass. **This does not mean we reviewed the full ADL/OPT content, licenses, ontology terms, clinical suitability or all release histories.** Status is descriptive, not clinical endorsement. The corrected inventory distinguishes **11 published / 5 in development** *among the 16 selected CKM records*, not in the entire CKM catalogue.

Important editorial caution: `openEHR-EHR-EVALUATION.problem_diagnosis.v1` can represent a diagnosis when professionally supported; `patients.alzheimer_stage` is an unsupported free-text stage in the local data and **must not be turned into a coded diagnosis automatically**. Similarly, `OBSERVATION.story.v1` is a candidate for separately sourced care-recipient history, **not** a vehicle for indiscriminately exporting caregiver-private transcripts.

## 2. FHIR R4 corrections and terminology boundaries

This is a proposed **source-field crosswalk**, not an implementation or claim of FHIR compliance.

- **`CareTeam`**: FHIR CareTeam can include family members and informal participants. The original text sounded as though an institution must always have verified each participant before a CareTeam can exist. **Correction:** a family Care Circle is still not automatically a patient-linked, clinically appropriate CareTeam or an access-control grant.
- **`RelatedPerson`**: describes an identified person's relationship with a patient. It **does not prove lawful proxy status**, nor does it authorize access to data merely by being present.
- **`Consent`**: FHIR R4 status codes do not match Hani Maak local consent states `granted`, `revoked`, `expired` one-for-one. Mapping requires policy/legal review, actor qualification, effective dates, and revocation tests; do not simply copy the local string.
- **`Patient.gender`**: R4 administrative gender is not necessarily the same as a source field named `sex`. Although local and R4 allowed labels may look similar, an identity/semantic assessment is still required.
- **`Observation`**: R4 base requires `status` and `code`. Caregiver narrative alone does not supply a clinically agreed coded observation or professionally validated result; `value[x]`, `performer` and `effective[x]` require interpretation and may become mandatory under a selected profile.
- **`MedicationStatement` versus `MedicationRequest`**: a reported medication use assertion is not a prescription. R4 requires `MedicationStatement.status`, `medication[x]` and `subject`; a MedicationRequest additionally requires defined order `status` and `intent` together with `medication[x]` and `subject`. Hani Maak's boolean `verified` and optional professional FK cannot supply all of these safely.
- **`MedicationAdministration`**: clicking `taken` is caregiver-reported; it does not prove a clinically verified administered dose or performer.
- **`Provenance` versus `AuditEvent`**: source/author/resource-generation history is different from access/exchange audit. Hani Maak's current local disclosure entries cannot be retroactively represented as records of FHIR network events that did not occur.

Primary references: [R4 Patient](https://hl7.org/fhir/R4/patient.html), [R4 RelatedPerson](https://hl7.org/fhir/R4/relatedperson.html), [R4 CareTeam](https://hl7.org/fhir/R4/careteam.html), [R4 Consent](https://hl7.org/fhir/R4/consent.html), [R4 Observation](https://hl7.org/fhir/R4/observation.html), [R4 MedicationStatement](https://hl7.org/fhir/R4/medicationstatement.html), [R4 MedicationRequest](https://hl7.org/fhir/R4/medicationrequest.html), [R4 MedicationAdministration](https://hl7.org/fhir/R4/medicationadministration.html), [R4 Provenance](https://hl7.org/fhir/R4/provenance.html), [R4 AuditEvent](https://hl7.org/fhir/R4/auditevent.html).

## 3. Clinical safety and provenance consistency

| Topic | What repository / schema inspection supports | What we cannot claim |
|---|---|---|
| Alzheimer diagnosis/stage | The `patients` record has a text `alzheimer_stage` but lacks a mandatory professional diagnostic code/asserter/assessment evidence | That recorded stage is verified, dated, standardized or clinically valid |
| Clinical guidance | `dilemma_scenarios.validation_status` records a local label; previous read-only database count found 10 marked `validated` and 0 review-registry rows | Qualified independent clinical validation; the count alone may not reflect external evidence |
| Incident observation | `incident_observations` has observer and professional-verification fields | That a professional signed off every observation; earlier count was 0 marked professionally verified |
| Medication | `patient_medications` has text, `verified` and optional prescribing professional | Verified prescription, medication reconciliation or safe dosing instructions |
| Professional notes | `professional_instructions` has optional `professional_id` and `verified_at` | Independent authentication of the author or source document |
| Private caregiver data | `hani_conversations`, `hani_messages`, `wellbeing_checkins` and emotion inferences may be patient-linked | Permission or clinical justification to upload them to a patient's EHR |
| Consent and disclosure | `caregiver_patient_relationships`, `consents`, `disclosure_events`, `handoff_summaries` support local governance trails | Institutional recognized proxy authority, exact hospital sharing scopes, or externally confirmed delivery |
| Technical verification | GitHub CI can test source/compilation; schema review observes fields and RLS metadata | Privacy certification, clinical safety review, end-to-end access control or deployed interoperability |

**Claim rule for the email:** say **“we have drafted a reviewable clinical-data and standards mapping based on the existing prototype and read-only database schema”**, **not** “our Alzheimer clinical schema is standards-compliant,” “the scenarios are clinically validated,” or “FHIR integration is ready.”

## 4. Remaining questions for qualified review (not blockers for a feedback email)

1. Identify validated **Alzheimer/dementia and caregiver assessment instruments** and their licensed/translated use, if relevant.
2. Have a qualified reviewer select a **minimal clinically meaningful field set**, not merely approve a list of technical tables.
3. Confirm target FHIR version, implementation guide and profiles, and whether a hospital can provide a sandbox or test capability. R4 in our document is a vocabulary choice only.
4. Establish authoritative diagnosis and professional medication sources; separate caregiver reports, AI hypotheses and verified healthcare facts.
5. Agree a **caregiver-private vs patient-clinical** boundary and validate proxy authority/consent/revocation.
6. If proceeding to prototype, compile/validate a synthetic sample and test forbidden access, revoked caregiver permissions, mismatched patient identity and unverified statements.

## 5. Communication readiness and next steps

**Phase 1 outcome:** source/link/semantic corrections committed to PR #60; documentation retains draft/research disclaimers and no unsupported hospital-integration or clinical-certification claims. Remaining gaps belong to future advisor/clinical review, not a requirement for the first scope-discussion email.

**Proceed to Phase 2:** update the advisor brief to reflect the completed provenance matrix, openEHR shortlist and FHIR crosswalk; prepare an executive summary and select a small reading package. Do not imply a real Auth demo account or integrated live FHIR endpoint is operational.

**Still separate:** Phase 3 repository/link/sensitive-information audit, Ahmed's PR merge handoff; Phase 4 final email draft for user review/sending. These are not completed by this Phase 1 review.
