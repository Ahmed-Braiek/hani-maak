# Hani Maak — Preliminary FHIR Source-to-Resource Mapping (v0.1)

**Prepared:** 21 October 2026  
**Status:** Advisor-review draft; **not an implemented adapter, adopted specification, valid export, certified profile, or hospital integration.**  
**Scope:** Alzheimer's care-recipient context, caregiver/proxy relationships, medication provenance, and limited later-stage clinical sharing.  
**Evidence:** Read-only reinspection of current Hani Maak Supabase `public` columns and constraints on 21 October 2026; cross-checked against [the 48-table clinical data and provenance matrix](../CLINICAL_DATA_PROVENANCE_MATRIX.md), the [FHIR use-case register](USE_CASES.md) and official HL7 documentation linked below.

> **FHIR version convention:** Element names below use **FHIR R4 (4.0.1) as a *reference vocabulary*** so the proposals can be discussed precisely. **No target FHIR version, hospital implementation guide, profiles, server, authorization protocol, terminology service, or exchange direction has been agreed.** An R4-based table is not a decision to implement R4. Re-evaluate all element names, cardinalities and conformance against the eventual target version and implementation guide.

## 1. Executive decision

**Recommendation for advisor review:** select **one read-oriented synthetic use case** and validate clinical meaning, identity/proxy authorization, source and consent **before** writing a FHIR adapter.

- **UC-01:** read verified care-recipient identity/context; potential `Patient` plus separate `Condition` / `Observation` *only when backed by authoritative clinical sources*. `patients.alzheimer_stage` alone is insufficient to establish diagnosis.
- **UC-02:** read/understand professional medication information; distinguish a **caregiver medication-use assertion** (`MedicationStatement` in R4) from a **clinician's order** (`MedicationRequest`). The existing `patient_medications.verified` Boolean does not substantiate a prescription.
- **UC-03:** establish caregiver/proxy identity, roles, scope, consent and revocation. `RelatedPerson` describes the relationship; **it does not independently confer a legal right to access records**. Local `consents` entries cannot simply be converted to enforceable hospital `Consent` directives.

Initial FHIR data should be **synthetic**. No application code, Supabase schema, FHIR server, patient records, OAuth/SMART flow, or production access changes are proposed in this PR.

## 2. Coverage, readiness and notation

| Label | Meaning |
|---|---|
| **Candidate** | A plausible FHIR representation if the missing clinical source, semantics and permissions are established |
| **Conditional** | Possible only in a reviewed, sufficiently sourced and authorized workflow |
| **Not yet derivable** | Required clinical facts / statuses / identifiers cannot be derived from the current local fields |
| **Excluded** | Outside the first patient-context exchange or explicitly caregiver-private/experimental |

A local field name can describe **application state**, not a clinical claim. For example, `active` in a local medication table is **not automatically** `MedicationStatement.status`, and `is_verified` in a professional directory is **not** proof of licensure. FHIR `CareTeam` **can include informal/family participants**, but Hani Maak's Care Circle is not automatically a clinically governed CareTeam or permission grant.

### Resource-level conceptual crosswalk

| Supabase source (observed) | Candidate FHIR R4 resource | Readiness | Critical missing information / restriction |
|---|---|---|---|
| `patients` | [`Patient`](https://hl7.org/fhir/R4/patient.html) | **Candidate** | Validated identifiers; correct subject matching; no stage-as-diagnosis |
| `profiles` + `caregiver_patient_relationships` | [`RelatedPerson`](https://hl7.org/fhir/R4/relatedperson.html) | **Candidate** | Relationship meaning vs operational care role; identity and proxy evidence |
| `care_circles` / `care_circle_members` | [`CareTeam`](https://hl7.org/fhir/R4/careteam.html) | **Not yet derivable** | FHIR CareTeam may include family and informal participants, but local membership alone does not establish a **clinically managed team** or authorized sharing |
| `patients.alzheimer_stage` | [`Condition`](https://hl7.org/fhir/R4/condition.html) | **Not yet derivable** | No structured diagnosis, code, clinical source, onset/recording verification |
| `incidents` / `incident_observations` | [`Observation`](https://hl7.org/fhir/R4/observation.html) | **Conditional** | Clinical code/meaning, reporter vs performer, status, consent and review |
| `patient_medications` | [`MedicationStatement`](https://hl7.org/fhir/R4/medicationstatement.html) | **Conditional** | Asserter, medication identity/coding, actual-use status/as-of date, source verification |
| `patient_medications` / `professional_instructions` | [`MedicationRequest`](https://hl7.org/fhir/R4/medicationrequest.html) | **Not yet derivable** | Verified prescriber, order status/intent, authored time, dosage instruction and source |
| No verified allergy source identified | [`AllergyIntolerance`](https://hl7.org/fhir/R4/allergyintolerance.html) | **Not yet derivable** | Neither allergy history nor allergy verification is established |
| `medication_events` | [`MedicationAdministration`](https://hl7.org/fhir/R4/medicationadministration.html) | **Not yet derivable** | A caregiver's `taken` flag is not verified administered dose/performer |
| `caregiver_appointments` | [`Appointment`](https://hl7.org/fhir/R4/appointment.html) | **Conditional** | Local request ≠ confirmed external hospital appointment |
| `care_tasks` / `timeline_events` | [`Task`](https://hl7.org/fhir/R4/task.html), potentially [`CarePlan`](https://hl7.org/fhir/R4/careplan.html) | **Conditional** | Home tasks ≠ clinician-authored, accepted care plan |
| `consents` | [`Consent`](https://hl7.org/fhir/R4/consent.html) | **Conditional** | Institutional legal validity, grantor identity, patient, policy, scope and status mapping |
| `care_documents` | [`DocumentReference`](https://hl7.org/fhir/R4/documentreference.html) | **Conditional** | Source document access, MIME/attachment, reviewed author/context and authorization |
| `handoff_summaries` / `summary_deliveries` | [`Communication`](https://hl7.org/fhir/R4/communication.html) and/or `DocumentReference` | **Conditional** | Real recipient, transport proof, clinician review, privacy/purpose; no fake sent status |
| `questionnaire_sessions` / `questionnaire_answers` | [`QuestionnaireResponse`](https://hl7.org/fhir/R4/questionnaireresponse.html) | **Excluded initially** | Most relevant data concerns **caregiver** (different subject); no validated instrument profile |
| `disclosure_events` / `caregiver_audit_events` | [`AuditEvent`](https://hl7.org/fhir/R4/auditevent.html) | **Conditional** | Actual FHIR transaction/access activity, actor, outcome, destination; not an exact retrospective conversion |
| Cross-cutting source/author evidence | [`Provenance`](https://hl7.org/fhir/R4/provenance.html) | **Conditional** | Asserter/author, source entity, recorded time, version and genuine review evidence |

**Additional explicit exclusions:** `hani_conversations`, `hani_messages`, `hani_memory_items` (when private), `wellbeing_checkins`, `support_signals`, `voice_emotion_analyses`, `voice_emotion_segments` and the legacy `hani_demo_state` JSON blob are **not** automatically patient clinical records. Do not map Hani-generated assumptions into clinical assertions.

## 3. UC-01 — Care-recipient context (read, conditional)

### 3.1 Patient resource: candidate field-level map

| Local field / join | Candidate FHIR R4 element | Transformation / meaning | Verification gate |
|---|---|---|---|
| `patients.id` | `Patient.identifier` (with agreed identifier namespace) or internal linkage key | Internal UUID does not itself establish a valid hospital MRN; never assume local `id` == remote FHIR `Patient.id` | Verified cross-system identity / duplicate protection |
| `patients.external_ids` (JSONB) | `Patient.identifier[]` | Use **only** known, verified values with an explicit `Identifier.system`; do not propagate arbitrary JSON | Trusted issuer, scope and matching algorithm |
| `patients.display_name`, `preferred_name` | `Patient.name[]` | Name text/use require agreed parsing; no inventing given/family from display string | Identity consistency; privacy |
| `patients.date_of_birth` | `Patient.birthDate` | Direct date if reliable, permitted and relevant | Date provenance and minimization |
| `patients.sex` | `Patient.gender` (administrative gender) **only if definitions align** | A local `sex` field is not automatically FHIR **administrative gender**: `Patient.gender` allows male/female/other/unknown but represents a different concept | Confirm semantic meaning and target IG |
| `patients.primary_language` | `Patient.communication.language`, possible | Local language may reflect preferred UI language rather than patient language; do not infer language mastery | Confirm meaning/coding; multilingual terminology |
| `patients.alzheimer_stage` | **No automatic `Patient` or `Condition` mapping** | Free text describing stage cannot be promoted to a coded diagnosis | Clinical evidence, diagnostic coding, clinician and assessment time |
| `patients.is_demo` | Internal environment/fixture classification | Never turn demo data into real hospital identity or flags implying a clinical assertion | Test-only routing and synthetic tagging |
| `patients.created_by_profile_id` | **Not** `Patient.generalPractitioner` or `Patient.managingOrganization` | This is a local record creator, not the patient's treating clinician | Keep in local provenance/audit |

**UC-01 blocker:** There is no validated encounter, clinical diagnosis source, medical problem code, qualified examiner, or hospital patient crosswalk in these columns. **Do not create `Condition` or diagnostic `Observation` from a free-text Alzheimer stage**, even if its content appears plausible.

### 3.2 Later, qualified observations

If clinical experts identify an appropriate code and source, `incident_observations` might yield a **caregiver-reported** patient `Observation`, with an explicit report and verifier distinction:

| Local field | Potential FHIR R4 field | Critical caveat |
|---|---|---|
| `incidents.patient_id` joined via `incident_observations.incident_id` | `Observation.subject = Reference(Patient/...)` | Resolve a verified patient reference |
| `incident_observations.observed_at` | `Observation.effectiveDateTime` | Occurrence/observation time; do not confuse with record creation |
| `incident_observations.observation` | `Observation.valueString` or `Observation.note` *only under an agreed observation code and resource status* | Unstructured caregiver text alone may belong in a reviewed narrative document instead |
| `incident_observations.observed_by_profile_id` | Potential `Observation.performer` (RelatedPerson/Practitioner) or associated `Provenance.agent` | The informant is **not automatically** a clinician |
| `professional_verified`, `verified_by_professional_id` | **No automatic “clinically verified” FHIR property** | Verify actual reviewer evidence; `verified_by_professional_id` points to a local directory entry, not guaranteed credentialing |
| `incidents.visibility` / `approved_to_share_by_profile_id` | **Not** resource-level proof of exchange permission | Check current authorization, consent, revocation and minimum necessary |

FHIR R4 `Observation.status` and `Observation.code` are **required**, while `subject`, `effective[x]`, `performer`, and `value[x]` are optional at the base-resource level but may be required by a selected profile; clinical design must determine which elements are necessary. This table **does not form a valid Observation JSON object** and is not an implemented exporter.

## 4. UC-02 — Medication information: three distinct assertions

FHIR deliberately separates **orders**, **reported medication use**, and **medication administration**. [R4 MedicationStatement](https://hl7.org/fhir/R4/medicationstatement.html) can be sourced from a caregiver; [R4 MedicationRequest](https://hl7.org/fhir/R4/medicationrequest.html) is an order. They must not be treated as equivalent.

| Local source | Potential output | What would be mapped | Why it remains conditional |
|---|---|---|---|
| `patient_medications.patient_id` | `MedicationStatement.subject` | Link to authorized `Patient` | Patient crosswalk and use claim must be established |
| `patient_medications.medication_name` | `MedicationStatement.medicationCodeableConcept` **as text initially**, only where permitted by target profile | User-entered name is not coded medication identity | Terminology, language, substance and strength need reconciliation |
| `patient_medications.dose_text` / `instructions` / `schedule_text` | `MedicationStatement.dosage[].text` (unstructured) | Retain literal historical statement, **not** computed dosing instruction | Human safety review; no automated prescribing |
| `patient_medications.starts_on` / `ends_on` | `MedicationStatement.effectivePeriod`, *if they describe period of actual use* | Local scheduling dates may instead reflect reminder validity | Confirm meaning; no invented ingestion |
| `patient_medications.active` / `verified` | **Do not copy directly** to `MedicationStatement.status` or order status | Local app flags do not prove use, cessation or clinical source | Explicit statement/assertion status + verification provenance required |
| `patient_medications.prescribing_professional_id` | Possible `MedicationRequest.requester` or `Provenance.agent` **only with authoritative order evidence** | Optional local professional reference | No order can be produced solely from an optional FK |
| `medication_events.status` / `actual_at` / `source` / `caregiver_profile_id` | Separate caregiver-reported adherence/event information | `taken`, `skipped`, `delayed`, `pending` are app statuses | **Not `MedicationAdministration`** without verified administered dose, actor and evidence |

**Explicit data gap:** `patient_medications` has no required original prescription document/source, `MedicationRequest.status`/`intent`, order time, clinically validated dose/route, or verified prescriber signature. The `professional_instructions` table has optional professional association and `verified_at` but is not an authoritative order repository just by existing.

**Allergies:** No verified allergy table, coded substance, clinical status or source was identified in the existing schema. `AllergyIntolerance` is a *future discovery question*, not a placeholder record or a required implementation in this draft.

## 5. UC-03 — Caregiver relationship, proxy rights and consent

### 5.1 `RelatedPerson` is a relationship, not an access token

| Current Hani Maak field | Candidate R4 element | Important boundary |
|---|---|---|
| `caregiver_patient_relationships.patient_id` | `RelatedPerson.patient` | Requires validated patient matching |
| `caregiver_patient_relationships.caregiver_profile_id` + `profiles.full_name` | `RelatedPerson.name` (and controlled identifier, if needed) | Verify natural person identity; local app profile is not a clinical identity credential |
| `caregiver_patient_relationships.relationship_label` | `RelatedPerson.relationship` if semantics and coding verified | Free text is not automatically a standard kinship code |
| `caregiver_role` (primary/secondary/paid_aide) | **Internal role**, not automatically kinship | 'Primary caregiver' does not say daughter/son/legal guardian |
| `access_status` and `started_at`/`ended_at` | Candidate `RelatedPerson.active` / `RelatedPerson.period` **only after agreed interpretation** | Relationship record does not prove legal proxy authorization |
| `can_view_medications`, `can_manage_tasks`, etc. | **Internal application permissions** | Must not be emitted as authoritative hospital grants |
| `care_circles` + `care_circle_members` | **Not automatically `CareTeam`** | FHIR CareTeam can represent informal participants; verify clinical care context, role, members and authority |

### 5.2 `Consent` must represent a verifiable directive

| Current field | Possible R4 concern | Decision required |
|---|---|---|
| `consents.patient_id` | `Consent.patient` | The subject of the decision must be known; nullable locally |
| `consents.actor_profile_id` | Potential grantor / recorded actor; not necessarily `Consent.performer` | Prove capacity, patient/proxy role and valid identity |
| `consents.consent_type`, `scope` JSONB | `Consent.scope`, `category`, `provision` as appropriate | Agree legal purpose, data categories, recipient and policy representation |
| `recipient_type` / `recipient_id` | `Consent.provision.actor` where a permitted recipient is verifiable | No default entity mapping from arbitrary local IDs |
| `status` (granted/revoked/expired) | `Consent.status` **requires a reviewed state mapping** | R4 codes include `draft`, `proposed`, `active`, `rejected`, `inactive` and `entered-in-error`; local `granted`/`revoked`/`expired` are not one-to-one equivalents |
| `granted_at`, `revoked_at`, `expires_at` | `Consent.dateTime` / `provision.period` as appropriate | Effective time, latest revocation and policy precedence need resolution |
| `disclosure_events.data_categories`, `purpose`, `payload_reference` | Disclosure-audit evidence, not `Consent` by itself | Confirm the actual outbound content and legal basis |

**Authorization is enforced externally to these data models.** A valid-looking `RelatedPerson` or `Consent` resource **does not** make an HTTP caller authorized to read hospital patient data. Hospital/IAM policies, identity proofing, authentication, consent decision logic, scope, revocation and audit must be explicitly agreed and **tested**.

## 6. Later use cases and deliberate non-mappings

| Hani Maak data | Possible later FHIR R4 representation | Why deferred |
|---|---|---|
| `caregiver_appointments` | `Appointment` | Internal requested booking, not hospital scheduling truth |
| `care_tasks`, `care_task_requests` | `Task`; `CarePlan` only with an actual clinical plan | Family routines are not clinician-authored plans |
| `care_documents` | `DocumentReference` | No verified accessible document content/attachment/MIME/source chain; OCR alone is not a prescription |
| `handoff_summaries` | `DocumentReference` or `Communication` depending on artifact and actual exchange | `approved_at`/`sent_at` do not establish clinician acceptance or delivered payload |
| `summary_deliveries` | `Communication` (if actual recipient, content and transmission are proved) | App/provider status is not a guarantee of successful external care handoff |
| `questionnaire_sessions`/`answers`/`results` | `QuestionnaireResponse` in a separate, explicitly authorized caregiver-related context | Caregiver is the respondent/possible subject; not the care recipient by default |
| `timeline_events` | Perhaps `Provenance` for a *specific* action or `Observation` if clinically interpreted | Timeline labels alone do not prove clinical meaning or origin |
| `hani_conversations`, `hani_messages`, `wellbeing_checkins` | **No default export** | Caregiver private information; no implied patient-EHR membership |
| `support_signals`, `voice_emotion_analyses`/`segments` | **No export** | Experimental AI inference; not validated medical findings |
| `hani_demo_state` | **No direct mapping** | Legacy opaque JSON state, not authoritative normalized clinical data |

**Base R4 resource requirements to validate in a future proof of concept:** `MedicationStatement.status`, `MedicationStatement.medication[x]` and `MedicationStatement.subject` are required; `MedicationRequest.status`, `intent`, `medication[x]` and `subject` are required. `Observation.status` and `code` are required. A mapping table is **not** a valid resource instance and cannot be implemented without resolving these requirements and any selected implementation-guide constraints.

**Provenance versus security audit:** R4 `Provenance` documents who or what created/changed/influenced a particular FHIR resource. R4 `AuditEvent` records actual system access/exchange events. Existing `disclosure_events` and `caregiver_audit_events` can inform design, but **neither should be presented as a complete retrospective FHIR audit trail**, especially if no actual FHIR transactions occurred.

## 7. Candidate information contract and mapping gates

**Minimum per-assertion contract (proposed, not a database migration):**

| Required question | Current field candidates | Missing / decision |
|---|---|---|
| **Who is the subject?** | `patient_id` in patient-related tables; `caregiver_profile_id` for caregiver-private entries | Verified foreign identity and distinguish patient vs caregiver |
| **Who asserted it?** | `reported_by_profile_id`, `observed_by_profile_id`, `source`, `prescribing_professional_id` | Consistent information-source type and verified identity |
| **What kind of fact?** | `incident_observations.observation`, `patient_medications.medication_name`, `patients.alzheimer_stage` | Clinical concept code/units, terminology, asserted-vs-confirmed classification |
| **When true and when recorded?** | `occurred_at`, `observed_at`, `actual_at`, `created_at`, `verified_at` | Time semantics per resource, update history and timezone |
| **Who verified it?** | `professional_verified`, `verified_by_professional_id`, `verified_at`, `verified` | Actual clinician credentials, review evidence and version |
| **What is the source artifact?** | `external_ids`, `care_documents`, `source_id` | Versioned evidence, actual document ID/URL/hash and data controller |
| **Who may receive it?** | `consents.scope`, `recipient_id`, `revoked_at`, relationship permissions | Legal authority and current revocation check per recipient/purpose |
| **How is sharing recorded?** | `disclosure_events`, `handoff_summaries`, `summary_deliveries` | Immutable exchange audit, outcomes, actual payload scope |
| **AI involvement?** | `hani_messages.sender`, `care_tasks.source`, `support_signals.experimental` | Explicitly label and normally exclude synthetic/AI unverified content |

**Proposed deterministic blockers:** never export a local stage as a diagnosed `Condition`, an app medication as an ordered `MedicationRequest`, a caregiver 'taken' click as verified `MedicationAdministration`, a Care Circle membership as hospital proxy consent, or a private Hani message as patient `Observation`.

## 8. Minimal synthetic mapping exercise (no generated FHIR instances)

Proposed **read-only paper exercise** for Lloyd and Aditya to choose/adjust:

1. Start from a **fictional** patient ID in a test dataset and a **fictional** caregiver relationship. Distinguish the patient's synthetic identifier from the local database key; do not copy real data or FHIR server IDs.
2. Map only `patients.display_name` and `patients.date_of_birth`, if populated, into **draft Patient field candidates**. Put `patients.alzheimer_stage` in a *quarantine/unverified* column, **not** in `Condition`.
3. Model `profiles` / `caregiver_patient_relationships` as **candidate RelatedPerson elements**, with a note that role/status is app-local and **not a permission grant**. Identify a separate consent/policy check before any remote retrieval.
4. If clinical reviewers prefer an incident use case, add an explicitly fictitious `incident_observations` narrative with distinct *observer* and *verified clinician* metadata, but do not construct a complete `Observation` until clinical code, status, source evidence and privacy approvals are resolved.
5. Record decision and exclusions in the review log. Only then, after HL7 version and target IG selection, create FHIR JSON examples and run a validator plus negative authorization tests.

This section intentionally **does not claim valid R4 resource instances** or fabricate an external clinician, hospital, code system, patient identifier or prescription.

## 9. Acceptance criteria and questions for advisors

Before even a synthetic adapter POC:

- [ ] Select exactly **one** first use case and define explicit actors, data owner, source/destination and direction.
- [ ] Confirm **FHIR version and implementation guide**, which hospital/partner environment (if any), terminology and patient-identity workflow.
- [ ] Review resource semantics and any must-support fields for the selected profile; document non-mappable sources.
- [ ] Confirm caregiver/proxy identity proofing, consent purpose/scope, revocation rules and access-denial tests.
- [ ] Require clinically evidenced asserter vs verifier status; no false diagnoses/orders/administrations.
- [ ] Keep caregiver-private wellbeing/chats and experimental emotion outputs excluded by default.
- [ ] Document provenance for resulting resource versions and audit actual attempts/access without retroactive fabrication.
- [ ] Test with synthetic data, including mismatched patient, revoked permission, unverified medication, unknown identity, unavailable source and duplicate identifier cases.
- [ ] Do not enable any hospital write-back or production export based on this document.

**Specific questions for Lloyd and Aditya:**
1. Which of UC-01 (authorized patient context), UC-02 (professional medicines), and UC-03 (proxy authority) is the most useful *and feasible* first synthetic read-oriented proof of concept?
2. What local caregiver information should remain application-only, and what evidence is necessary to count as *clinically reviewed*?
3. Should our first architecture use a small authorization-aware application boundary around FHIR rather than represent caregiver access entirely within patient resources?
4. Which FHIR version, profile/IG and identifier/consent convention should be explored based on a realistic hospital or advisor evaluation environment?
5. What minimum tests and governance decisions should precede a working adapter?

## 10. Traceability and source limits

**Live source (read-only):** `information_schema.columns` and `pg_constraint` for the referenced `public` tables, queried 21 October 2026; cross-checked against [`CLINICAL_DATA_PROVENANCE_MATRIX.md`](../CLINICAL_DATA_PROVENANCE_MATRIX.md). No patient or caregiver row values were inspected for this document; no SQL mutations or outbound data transmission occurred.

**Existing Hani Maak documentation:** [Use cases](USE_CASES.md) · [openEHR archetype landscape](../openehr/ARCHETYPE_LANDSCAPE.md) · [Clinical validation audit](../openehr/CLINICAL_VALIDATION_AUDIT.md) · [Advisor brief](../ADVISOR_BRIEF.md).

**Official reference (R4.0.1, used as vocabulary rather than implementation decision):** [Patient](https://hl7.org/fhir/R4/patient.html), [RelatedPerson](https://hl7.org/fhir/R4/relatedperson.html), [Observation](https://hl7.org/fhir/R4/observation.html), [MedicationStatement](https://hl7.org/fhir/R4/medicationstatement.html), [MedicationRequest](https://hl7.org/fhir/R4/medicationrequest.html), [Consent](https://hl7.org/fhir/R4/consent.html), [DocumentReference](https://hl7.org/fhir/R4/documentreference.html), [Communication](https://hl7.org/fhir/R4/communication.html), [Provenance](https://hl7.org/fhir/R4/provenance.html), [AuditEvent](https://hl7.org/fhir/R4/auditevent.html).

**Limitations:** This is **not** a completed HL7 conformance assessment, no R4 JSON example has been validated, target FHIR release remains undecided, mappings are not signed off by clinicians or the advisors, and clinical assertions require their own source and consent review. The separate [openEHR inventory](../openehr/ARCHETYPE_LANDSCAPE.md) is a different semantic-modeling workstream; **no automatic openEHR↔FHIR field equivalence has been demonstrated**.

**Next output:** secure advisor feedback on the selected UC and evidence gates; implement nothing until that decision.
