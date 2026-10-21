# Hani Maak — openEHR Archetype Landscape and Reuse Inventory

**Prepared:** 21 October 2026  
**Scope:** Focused research for the Alzheimer caregiver-support **clinical-data and provenance matrix**, not a hospital implementation.  
**Status:** v0.1 review candidate for Lloyd Williams, Aditya Ayyagari, Salma Ghorbel, Hela Sellami and clinical advisors.  
**Inputs:** [Live Supabase matrix](../CLINICAL_DATA_PROVENANCE_MATRIX.md) (48/48 `public` tables inspected read-only, 20 October 2026); published model descriptions, identifiers and available lifecycle information from the [openEHR International Clinical Knowledge Manager (CKM)](https://ckm.openehr.org/ckm/), checked 21 October 2026.

> **Critical distinction:** CKM model **presence** and CKM lifecycle **published** do not mean that the model is appropriate for Hani Maak, clinically approved for Tunisia, implemented in our software, or validated for Alzheimer care. The **openEHR reference model**, an **archetype**, a **template** and a **FHIR resource** are different layers. We have not built an ADL archetype, operational template (OPT), openEHR CDR, AQL query or FHIR interface.

## 1. Summary and decision

**Do not create a custom 'Alzheimer caregiver archetype' yet.** Reuse and assess existing openEHR models **for a very small, reviewable patient-level dataset** after clinical provenance is established.

- **Best published starting points** for discussion: `EVALUATION.problem_diagnosis.v1` (only a verified clinical diagnosis), `OBSERVATION.story.v1` (explicitly sourced patient history, including a carer report), `COMPOSITION.medication_list.v1` and `ACTION.medication.v1` (clinician-reviewed medication information and clearly differentiated actual actions), and `EVALUATION.social_summary.v1` (patient-relevant social context).
- **Important draft candidates:** `OBSERVATION.medication_statement.v0` (particularly relevant to current use *reported by a carer*), `OBSERVATION.functional_ability.v0` and `EVALUATION.functional_support_requirements.v0`; CKM lists these as **in development**, not published models.
- **Never automatically include:** raw caregiver chats, wellbeing, family conflict, Hani-created hypotheses or experimental emotion predictions in the care recipient's EHR.
- **Operational identity and permissions** (the person who logs in, informal caregiver/proxy role, consent and revocation) require a separate governed identity/authorization specification. Do not treat `caregiver_patient_relationships` as a clinically verified diagnosis or institutional consent.

**Evidence categories below:** `published` = CKM lifecycle observed as `published`; `in_development` = CKM lifecycle observed as `in_development`; `not independently verified` = current release metadata could not be checked. The 16 candidates below have CKM records with independently inspected lifecycle and revision information. The parenthetical revision is CKM's *asset revision* (where observed), distinct from its archetype ID suffix `.vN`. CKM entries can change; check lifecycle and revisions again before building a template. **The same archetype ID can occur in different CKM records/revisions, so link and revision must be tracked together.**

## 2. Verified candidate archetypes and gaps (16 models)

| # | CKM archetype ID and primary-source link | CKM lifecycle (revision) | Intended clinical scope | Current Supabase source / candidate | Evidence or use restriction | Priority |
|---:|---|---|---|---|---|---|
| 1 | [`openEHR-EHR-EVALUATION.problem_diagnosis.v1`](https://ckm.openehr.org/ckm/archetypes/1013.1.169) | **published** (1.7.4) | Diagnosed problem / Alzheimer disease | `patients.alzheimer_stage` (not enough evidence) | Condition label needs coded diagnosis, clinician and evidence; do not populate from free-text stage | P0: review if hospital provides verified condition |
| 2 | [`openEHR-EHR-CLUSTER.problem_qualifier.v2`](https://ckm.openehr.org/ckm/archetypes/1013.1.6653) | **published** (2.1.1) | Diagnostic status or clinical context | No equivalent verified schema fields | Used with problem/diagnosis, not to invent diagnostic certainty | P1: follow condition-source confirmation |
| 3 | [`openEHR-EHR-OBSERVATION.story.v1`](https://ckm.openehr.org/ckm/archetypes/1013.1.68) | **published** (1.3.3) | Patient's reported history (including carer-reported episodes) | `incidents.summary`, `incident_observations.observation` | Narrative must be about the patient's health, with explicit reporter; excludes raw Hani chat | P0: narrow synthetic history demo |
| 4 | [`openEHR-EHR-CLUSTER.symptom_sign.v2`](https://ckm.openehr.org/ckm/archetypes/1013.1.6769) | **published** (2.1.4) | Specific carer-reported symptom/sign episode | `incidents`, `incident_observations` | Consider within OBSERVATION.story; clinical applicability, context and terminology still require review | P1: research only |
| 5 | [`openEHR-EHR-OBSERVATION.symptom_sign_screening.v1`](https://ckm.openehr.org/ckm/archetypes/1013.1.4432) | **published** (1.0.7) | Structured symptom/sign questionnaire | `questionnaire_*`, but no validated versions observed | Questionnaire template semantics must be clinically reviewed, not a generic burden scale | P1: conditional |
| 6 | [`openEHR-EHR-COMPOSITION.medication_list.v1`](https://ckm.openehr.org/ckm/archetypes/1013.1.286) | **published** (1.0.4) | Clinically maintained current medicines list | `patient_medications` | CKM warns exchange-safe lists need clinician curation; Hani caregiver list not yet reconciled | P0: only after verified source |
| 7 | [`openEHR-EHR-ACTION.medication.v1`](https://ckm.openehr.org/ckm/archetypes/1013.1.123) | **published** (1.6.0) | Actual medication management/administration activity | `medication_events`, `medication_schedules` | Caregiver status `taken` is a report, not independent witnessed administration | P1: possible only with provenance |
| 8 | [`openEHR-EHR-CLUSTER.medication.v2`](https://ckm.openehr.org/ckm/archetypes/1013.1.5947) | **published** (2.0.6) | Medication item/details, ingredients/strength/form | `patient_medications.medication_name`, `dose_text` | Not a standalone order or dose instruction; coded substance/details absent | P1: paired with clinical medication entry |
| 9 | [`openEHR-EHR-OBSERVATION.medication_statement.v0`](https://ckm.openehr.org/ckm/archetypes/1013.1.4949) | **in_development** (0.0.1-alpha) | Snapshot assertion of current medication use; can be carer-reported | `patient_medications`, `medication_events` | Most semantically similar to caregiver statement; draft archetype and as-of-time uncertainty | P1: prototype only, review status |
| 10 | [`openEHR-EHR-INSTRUCTION.medication_order.v2`](https://ckm.openehr.org/ckm/archetypes/1013.1.5812) | **in_development** (2.0.5-alpha) | Professional medication order/prescription | `professional_instructions`, `patient_medications` | Do not fabricate medication orders from caregiver entries or OCR | P1: source-verified hospital data only |
| 11 | [`openEHR-EHR-EVALUATION.social_summary.v1`](https://ckm.openehr.org/ckm/archetypes/1013.1.2378) | **published** (1.1.1) | Patient social circumstances/supports relevant to health | `caregiver_patient_relationships`, `care_circles` | Only patient-relevant reviewed/consented summary; not private caregiver family conflict | P1: structured social-context discussion |
| 12 | [`openEHR-EHR-EVALUATION.clinical_synopsis.v1`](https://ckm.openehr.org/ckm/archetypes/1013.1.409) | **published** (1.0.5) | Clinician-authored overview for a clinical event | `handoff_summaries`, `professional_instructions` | CKM describes healthcare-provider viewpoint; automated Hani summary is not clinician-authored | P1: after clinician review |
| 13 | [`openEHR-EHR-OBSERVATION.functional_ability.v0`](https://ckm.openehr.org/ckm/archetypes/1013.1.5017) | **in_development** (0.0.1-alpha) | Structured assessment of ability in ADLs/iADLs | `patient_activity_sessions`, `patient_memory_items` (not assessment) | Existing memory activities are not structured functional independence assessments | P2: exploratory; needs instrument and clinician |
| 14 | [`openEHR-EHR-EVALUATION.functional_support_requirements.v0`](https://ckm.openehr.org/ckm/archetypes/1013.1.8348) | **in_development** (0.0.1-alpha) | Needed human/device/environmental support by activity | `care_tasks`, `caregiver_patient_relationships` | Tasks/roles do not establish assessed support needs | P2: clinician and caregiver consensus needed |
| 15 | [`openEHR-EHR-EVALUATION.goal.v1`](https://ckm.openehr.org/ckm/archetypes/1013.1.124) | **published** (1.1.2) | Health-related goal and measured target | `care_tasks` (operational, not clinical goal) | A completed household task is not a clinical goal/outcome | P2: only if formal care plan introduced |
| 16 | [`openEHR-EHR-ACTION.care_plan.v0`](https://ckm.openehr.org/ckm/archetypes/1013.1.1655) | **in_development** (0.0.1-alpha) | Planning/execution state of a whole care plan | `care_tasks`, `timeline_events` | Do not substitute task list for approved multidisciplinary clinical plan | P2: research only |

**CKM revision reconciliations (21 October 2026):** the earlier [Problem/Diagnosis archived revision 34](https://ckm.openehr.org/ckm/archetypes/1013.1.169/34) is **1.0.11**, whereas the linked main CKM record is **1.7.4**. The earlier [Goal draft record](https://ckm.openehr.org/ckm/archetypes/1013.1.5012/) is **1.1.1-alpha / in_development**, but a [published Goal 1.1.2](https://ckm.openehr.org/ckm/archetypes/1013.1.124) exists under the same archetype ID. The original listing failed to verify `CLUSTER.symptom_sign.v2`; its CKM record is **published 2.1.4**. We now cite the applicable current/published entries rather than implying draft-only availability. Neither revision history nor publication is clinical approval of this proposed local use.

**Priority meaning:** **P0** = immediately relevant to advisor scope discussions, **P1** = conditional/research candidate, **P2** = longer-term assessment. Priority is **not** an implementation decision. Names and existing table fields come from the live schema matrix; **the proposed connections are our analysis**, not official openEHR/FHIR mappings.

### Clinical interpretation of this inventory

**A. Confirmed diagnosis is different from an Alzheimer's stage label.** CKM `EVALUATION.problem_diagnosis.v1` is a problem/diagnosis construct, and `CLUSTER.problem_qualifier.v2` can add specific context. The current Hani Maak `patients.alzheimer_stage` free-text field lacks a diagnosed-by identity, coded diagnostic basis, and verified assessment date. It must not be promoted to a confirmed openEHR diagnosis. Review [problem/diagnosis](https://ckm.openehr.org/ckm/archetypes/1013.1.169), [qualifier](https://ckm.openehr.org/ckm/archetypes/1013.1.6653).

**B. Caregiver-reported behavior is a narrated history, not automatically a measured observation.** `OBSERVATION.story.v1` explicitly permits a clinician to record a story as related by a caregiver; `CLUSTER.symptom_sign.v2` is published and may provide more structure once clinical applicability and template context are reviewed. Hani Maak's `incidents.summary` and `incident_observations.observation` can be evaluated **only** after the author, patient, observed time, reported-vs-verified status and clinical purpose are determined. Merely importing raw incident narratives can leak private caregiver material. Review [Story/History](https://ckm.openehr.org/ckm/archetypes/1013.1.68) and [Symptom/Sign](https://ckm.openehr.org/ckm/archetypes/1013.1.6769).

**C. Distinguish medication orders, use statements and actual actions.** Published `COMPOSITION.medication_list.v1` expects a curated list; the `INSTRUCTION.medication_order.v2` CKM item is an *in-development* model for an order, `OBSERVATION.medication_statement.v0` is an *in-development* snapshot assertion about current use, and published `ACTION.medication.v1` models medication-management activities. A caregiver clicking 'taken' is **not** evidence that a clinician ordered the medication or that administration was independently observed. CKM explicitly distinguishes these contexts; `patient_medications.verified` does not by itself prove a reconciled list. Review [list](https://ckm.openehr.org/ckm/archetypes/1013.1.286), [current-use statement](https://ckm.openehr.org/ckm/archetypes/1013.1.4949), [order](https://ckm.openehr.org/ckm/archetypes/1013.1.5812), [medication management](https://ckm.openehr.org/ckm/archetypes/1013.1.123).

**D. Daily activities are not ADL assessment.** The in-development `functional_ability` and `functional_support_requirements` models are useful for discussing assistance with daily living, but `patient_activity_sessions` currently captures familiar activities and informal responses, not a standardized cognitive or functional evaluation. Do not calculate Alzheimer severity or independence scores from these logs. Review [functional ability](https://ckm.openehr.org/ckm/archetypes/1013.1.5017) and [support requirements](https://ckm.openehr.org/ckm/archetypes/1013.1.8348).

**E. Private caregiver information is a different subject.** `wellbeing_checkins`, `hani_conversations`, `hani_messages`, `questionnaire_answers` and `voice_emotion_analyses` should default to the **caregiver's private context**, even if a `patient_id` happens to be present. The published `social_summary` archetype captures social circumstances **of the subject of care**; it is not permission to copy another person's private journal into the patient's record. CKM `clinical_synopsis` is expressly written **from a healthcare-provider perspective** and cannot be equated to an unreviewed AI summary. Review [Social summary](https://ckm.openehr.org/ckm/archetypes/1013.1.2378), [Clinical synopsis](https://ckm.openehr.org/ckm/archetypes/1013.1.409).

## 3. Coverage against the Hani Maak domains

| Local domain / verified table fields | Most relevant catalogued model | What we *can* say now | What is still missing |
|---|---|---|---|
| `patients.alzheimer_stage` | `EVALUATION.problem_diagnosis` + optional qualifier | Candidate if a clinical source can verify the diagnosis and stage | Coding/assessment criteria; professional author; evidence and date |
| `incidents`, `incident_observations` | `OBSERVATION.story`; possible `CLUSTER.symptom_sign` | Carer-report can have clinical-history value **if reviewed and consented** | Reporter vs clinician distinction, context, validity, sharing consent |
| `patient_medications`, `medication_events` | `COMPOSITION.medication_list`, `ACTION.medication`, draft `OBSERVATION.medication_statement` | Different information models exist for order, actual activity and reported medication use | Clinician reconciliation, terminology, original prescription and observed-vs-reported status |
| `care_tasks`, `timeline_events` | In-development `EVALUATION.goal` or `ACTION.care_plan` only if a formal clinical plan is introduced | Routine task coordination remains app domain data | Clinician-signed plan, goal/outcome measures and plan version |
| `caregiver_patient_relationships`, `consents`, `disclosure_events` | **No directly selected clinical archetype for authorization** | Local relationship and consent tables can inform a separate policy service | Proxy legality, recipient, purpose, revocation and institution rules |
| `patient_activity_sessions`, `patient_memory_items` | In-development `OBSERVATION.functional_ability` only if a separate assessment is designed | Familiar activities are **not** diagnostic ADL tests | Clinically defined assessment and validated instruments |
| `wellbeing_checkins`, `questionnaire_*` | No validated Alzheimer-caregiver-burden archetype selected in this **focused** inventory | Keep caregiver-private and instrument-specific | Qualified scale, instrument license, language validation, respondent identity |
| `handoff_summaries`, `professional_instructions` | Published `EVALUATION.clinical_synopsis` *if clinician authored* | A summary is not a complete discharge document, and AI text is not clinical attestation | Reviewer, author, patient context, consent, status and verified external recipient |
| `support_signals`, `voice_emotion_analyses` | **None proposed** | Experimental inferences do not establish medical observations | Independent evidence, privacy/legal and scientific validation; exclude for now |

This is **not exhaustive** CKM search coverage. In particular, no dedicated **Alzheimer-specific caregiver burden instrument archetype** or approved **Alzheimer-only template** has been verified in this focused search; **that is not proof none exists**. Salma/Hela/Eya should extend CKM searches and record relevant national/local libraries if the hospital provides them.

## 4. Proposed *synthetic template design discussion*, not an OPT

An openEHR **archetype** defines reusable constraints on reference-model information, while a **template** combines/constrains archetypes for a purpose such as a clinical encounter, form or summary. See the [openEHR archetypes specification overview](https://github.com/openEHR/specifications-BASE/blob/master/docs/architecture_overview/master10-archetypes.adoc). The following are **conceptual design directions only**—no ADL2/OPT/template has been generated.

### Option A — caregiver-reported patient symptom/history (preferred first discussion)

- **Patient subject:** *synthetic* care recipient ID with explicit pseudonymization; not the caregiver's private profile.
- **Potential content:** published `OBSERVATION.story.v1`; possibly `CLUSTER.symptom_sign.v2` after lifecycle review.
- **Source:** `incident_observations` or **explicitly approved** minimum from `incidents`; flag `reported_by_profile_id` vs `verified_by_professional_id`.
- **Documentation requirements:** author/information provider, observed time, report time, wording/language, evidence reference, sharing consent and status.
- **Must not contain:** unreviewed AI advice, caregiver wellbeing, private chat/voice, family conflicts, or a clinical diagnosis inferred from the narrative.

### Option B — professionally reconciled medication snapshot

- **Potential content:** published `COMPOSITION.medication_list.v1` plus correctly sourced medication entries. `OBSERVATION.medication_statement.v0` may be evaluated for a **caregiver-reported** current-use snapshot but is still in development.
- **Source:** only records with a verified, authoritative clinician/medication source; treat Hani Maak `patient_medications` as caregiver-maintained until reconciled.
- **Required metadata:** drug coding, strength, actual/current regimen, as-of timestamp, author and reviewer, evidence, source system and change history.
- **Do not invent:** a clinician order from a reminder or 'taken' event. Do not copy OCR text as a prescription without manual validation.

### Option C — governed patient social/functional support context

- **Potential content:** published `EVALUATION.social_summary.v1`; in-development functional ability/support requirements only **after qualified clinical review**.
- **Source:** limited approved patient-related support needs, not every care task and not the caregiver's confidential check-ins.
- **Required metadata:** assenter, needs vs observed capability, patient consent/proxy scope, review and update date.
- **Guardrail:** no formal functional or cognitive score inferred from memory-recall games.

## 5. Explicit provenance and privacy requirements

For **any** future clinical-template instance, require at minimum:

1. **Subject-of-care vs information provider:** `patients.id` identifies the care recipient in local data, but the person reporting may be `incidents.reported_by_profile_id`, `incident_observations.observed_by_profile_id` or a professionally verified third party. Conflating them changes meaning.
2. **Author/clinician:** separate caregiver text from reviewed/authorized professional statements; the presence of `is_verified`, `verified` or `verified_at` is insufficient on its own.
3. **Time and evidence:** distinguish occurrence/recording/review/as-of dates, a source record or document link, and whether source material is primary, OCR-derived or AI-generated.
4. **Code and language:** agree appropriate coding systems/licensing and validate terminology and translations for Tunisian Derja, Arabic, French and English; narrative alone is not interoperable terminology.
5. **Consent and legal proxy:** `consents` and relationship tables represent *local records*; external exchange requires validated authority, recipient, purpose and revocation handling. Never assume family status confers a clinical access right.
6. **Minimization:** caregiver-private conversations, journals, distress, questionnaire answers and voice/emotion inference do **not** become patient clinical data through a technical mapping.
7. **Version and lifecycle:** record CKM archetype ID, current revision, license and lifecycle, template version, reviewer and any local constraints; recheck before deployment.

CKM's [GitHub mirror](https://github.com/openEHR/CKM-mirror) contains the CKM authoring trunk, including **unpublished/in-development assets**. Do not interpret existence in that mirror as a published or clinically approved release. Archetype reuse and licensing must be reviewed per asset and incorporated licenses/terminologies (e.g., SNOMED CT may require independent authorization).

## 6. Review decisions for Lloyd, Aditya and the clinical group

| Question | Reason | Requested decision |
|---|---|---|
| Is **a synthetic, explicitly caregiver-reported symptom/history** the best initial modeling exercise? | It avoids pretending current user-input medication or disease-stage text is clinician-authored | Choose Option A/B/C, with rationale |
| Which **existing CKM archetypes/revisions** should be preferred and why? | CKM includes both `published` and `in_development` assets | Approve an initial review shortlist; capture version |
| How should **caregiver proxy identity and private information** be represented? | Current relation/consent tables are not legal or hospital access policies | Specify information-provider, proxy, consent and exclusion rules |
| What is an appropriate **minimum Alzheimer-relevant dataset** before any template? | The current schema has mixed operational and caregiver-private information | Clinical sign-off on field/domain list |
| What are the **paper/research outputs** worth pursuing? | A focused modeling comparison may be publishable *only after* method, literature and evaluation are agreed | Choose method and review metrics, not publication/partnership promises |

## 7. Next reviewable deliverables (no production work)

- **Clinical group:** verify clinical scenarios/needs and source evidence; identify disease-stage/medication/document risks; research validated measures and CKM models including version/lifecycle; review licensing and language.
- **Technical group:** propose a minimal **synthetic** source-to-archetype mapping for just *one* advisor-selected scenario (patient symptom history likely lowest assertion risk); maintain source ID, actor, time, verification and exclusions.
- **Advisor review:** select acceptable archetype set, version, information-provider convention and the minimum data quality threshold; only then consider building a draft template.
- **Separate FHIR group:** choose an actual exchange use case before binding archetype elements to any FHIR resources. openEHR and FHIR are complementary approaches, **not automatically interchangeable**.

**Review status:** no hospital, Carefluence platform or qualified clinician has approved any model listed here. This file is a **literature/CKM landscape**, safe to review as a proposal without sharing private caregiver/patient data.

## 8. Primary sources and traceability

- [openEHR Clinical Knowledge Manager (CKM)](https://ckm.openehr.org/ckm/): model records and lifecycle tags; individual CKM record links in section 2.
- [openEHR International CKM mirror](https://github.com/openEHR/CKM-mirror): authoring trunk **also includes non-published assets**, so recheck lifecycle.
- [openEHR archetypes and templates architecture](https://github.com/openEHR/specifications-BASE/blob/master/docs/architecture_overview/master10-archetypes.adoc): archetype/template distinction.
- [Live Hani Maak 48-table provenance matrix](../CLINICAL_DATA_PROVENANCE_MATRIX.md): current data structure, explicit origin fields, privacy classification proposals.
- [Clinical validation audit](CLINICAL_VALIDATION_AUDIT.md) and [FHIR use-case research](../fhir/USE_CASES.md): independent review boundaries.

**Limitations of this study:** focused CKM retrieval rather than an exhaustive catalogue search; not a validation of archetype internals or AQL/OPT compiling, not an inventory of every national CKM, and not a clinical decision. Asset status or versions can change after this check. No records or database schema were modified.
