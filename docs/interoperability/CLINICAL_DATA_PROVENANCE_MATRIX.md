# Hani Maak — Clinical-Data and Provenance Matrix

**Observed:** live Supabase `public` schema, 20 October 2026 (read-only).  
**Version:** v0.1, draft for Hani Maak clinical/technical review and feedback from Lloyd Williams and Aditya Ayyagari.  
**Coverage:** **48/48 public base tables**, current columns and structural constraints, PostgreSQL RLS policy metadata and limited count-only queries. No content of patient records, conversations, medication records, documents or contact details was read, exported or modified.

> **Key distinction:** Table and column existence, FK and CHECK constraints, RLS definitions and aggregate counts are **verified schema metadata**. Intended author, clinical meaning, data quality, lawful proxy authority and recommended sharing are **hypotheses or review proposals**, never facts automatically guaranteed by a field. A `verified` boolean, `validated` string or non-null `verified_at` is **not** independent clinician sign-off. This is *not* a clinical data export, approved FHIR model, openEHR archetype, security certification or operational health-system integration.

## 1. Purpose and boundaries

Hani Maak supports family and informal caregivers of people living with Alzheimer's disease. The running schema separates caregiver profiles, care recipients, medication/routine support, incidents, professional coordination, private caregiver discussions, wellbeing and experimental inferences. Before designing a clinical information model or hospital exchange, we must determine **who made each assertion**, **who (if anyone) clinically confirmed it**, **who is authorized to see it**, and **which system owns the underlying fact**.

The table coverage below is comprehensive for the 48 tables; it does **not** mean all application routes, policies, providers or sample data have been audited. Suggested categories (not current database labels): **P** = care-recipient context; **C** = caregiver-private; **R** = professional/clinical reference needing approval; **X** = conditional external exchange; **O** = operational or historical only.

## 2. Field-level provenance and clinical-readiness matrix

| Candidate information | Observed live schema evidence | What it establishes / does not establish | Proposed classification and gate |
|---|---|---|---|
| Care recipient identity and Alzheimer's stage | `patients.display_name`, `date_of_birth`, `sex`, `alzheimer_stage`, `created_by_profile_id` | Care-recipient record and creator link; **no recorded source of diagnosis, diagnostic code, assessment date or verified clinician** | P; no confirmed `Condition` from raw stage text |
| Caregiver identity and delegated access | `profiles.auth_user_id`, `role`; `caregiver_patient_relationships.caregiver_role`, `access_status`, `consent_basis`, `can_*` flags | User/relationship/permission metadata, **not independent proof of lawful proxy authority** | P/X; verify institutional scope/revocation |
| Medication list and directions | `patient_medications.medication_name`, `dose_text`, `schedule_text`, `verified`, `prescribing_professional_id` | Optional professional FK and boolean; prescribing/evidence verification not required | P/X; distinguish caregiver list from confirmed professional prescription |
| Medication event | `medication_events.caregiver_profile_id`, `source`, `scheduled_for`, `actual_at`, `status` | Actor/source/times and user-entered status; **does not confirm ingestion** | P; caregiver-reported event |
| Scanned document / OCR | `care_documents.uploaded_by_profile_id`, `document_type`, `extracted_text`, `reviewed` | Uploader and reviewed marker, but **no required reviewer or professional signature field** | P/X; restrict, review, validate source |
| Incident report | `incidents.reported_by_profile_id`, `occurred_at`, `summary`, `visibility`, `approved_to_share_by_profile_id` | Reporter/time and sharing marker; not a medical diagnosis or confirmed urgency | P/C/X; private-first and consented minimum summary |
| Observation / professional review | `incident_observations.observed_by_profile_id`, `observed_at`, `professional_verified`, `verified_by_professional_id` | Observer and structured verification fields; evidence of review not independently checked | P/X; candidate reviewed observation only if qualified evidence exists |
| Professional instruction | `professional_instructions.professional_id`, `status`, `verified_at`, `external_ids` | Professional link + timestamp, not verified authorship or currency | R/P; qualified source/evidence required |
| Professional directory | `professional_profiles.is_verified`, `verification_note`, `profile_id` | Verification flag/note, not confirmed professional licensure | R; external identity review |
| Care task / AI suggestion | `care_tasks.source`, `requested_by_profile_id`, `assigned_to_profile_id` | `source` constrained to `manual`, `routine`, `hani_suggestion` | O/P; not a medical order |
| Timeline lineage | `timeline_events.source_type`, `source_id`, `created_by_profile_id` | Optional generic source and creator ID; referenced fact may be unverified | P/X; resolve each reference before sharing |
| Memory or familiar activity | `patient_memory_items`; `patient_activity_sessions.response_label`, `caregiver_profile_id` | Familiar items and participation notes, **not validated cognition testing** | P; supportive content, not diagnostic assessment |
| Hani chat and assistant memory | `hani_messages.sender`, `hani_conversations.private_to_caregiver`, `hani_memory_items.memory_scope`, `source_type` | Sender and private/shared markers, **not clinician authorship** | C; exclude raw caregiver chat from patient EHR by default |
| Caregiver wellbeing | `wellbeing_checkins.caregiver_profile_id`, `source`, mood, sleep, energy, free-text | Source constrained to `manual`/`hani`/`questionnaire_followup`; not clinical screening | C; no implicit sharing with family/hospital |
| Questionnaires | `questionnaire_versions.validation_status`, `validation_reference`, `questionnaire_results.raw_score` | Validation/score metadata exist, but not an independently approved scale | C/R; clinical, licensing and translation review |
| Dilemma/alert clinical content | `dilemma_scenarios.validation_status`, `clinical_content_reviews.entity_id`, `reviewer_name`, `review_status` | Status markers and a review registry; no required review FK or qualified reviewer identity | R; evidence-linked clinical sign-off before claim |
| Experimental distress/emotion | `support_signals.experimental`, `confidence`; `voice_emotion_analyses.model_version`, `distribution` | AI/model metadata, not proven clinical findings | C; experimental; exclude from initial export |
| Sharing authorization | `consents.actor_profile_id`, `scope`, `revoked_at`; `disclosure_events.consent_id`, `data_categories` | Declared consent/lifecycle and disclosure trail, not independent legal sufficiency | X; verify proxy, recipient, purpose, revoke |
| Handoff and outbound delivery | `handoff_summaries.consent_id`, `approved_at`, `sent_at`; `summary_deliveries.status` | Local workflow/provider status, not acceptance by clinician | X; reviewed minimum necessary and actual receipt |

**Every classification and clinical/export gate above is a *recommendation*, not an existing tested system rule.**

## 3. Complete live schema coverage — 48 tables

Each **exact** table name below was compared to the live `public` table listing. “Source signal” describes stored metadata—not confirmed real-world authorship. “Review direction” describes our proposed policy, not a deployed data-sharing feature.

### Identity and caregiver authority

| Existing table | Subject | Provenance / verification columns | Interpretation of evidence | Review direction |
|---|---|---|---|---|
| `profiles` | Caregiver / professional | `auth_user_id`, `role`, `is_demo`, `metadata` | Auth link and role; not clinical accreditation | Identity only; authenticated actor match |
| `patients` | Care recipient | `created_by_profile_id`, `is_demo`, `external_ids`; `alzheimer_stage` free text | Creator/demo state; stage author and medical source absent | Do not treat stage as confirmed diagnosis |
| `caregiver_patient_relationships` | Both | `caregiver_role`, `access_status`, `consent_basis`, `can_*`, validity dates | Asserted caregiver role and permissions | Verify legal proxy authority and revocation |
| `care_circles` | Family / recipient | `created_by_profile_id`, `patient_id` | Creator and family grouping | Coordination, not a hospital CareTeam |
| `care_circle_members` | Family / caregiver | `profile_id`, `member_role`, `status`, `joined_at` | Member identity and status | Family coordination only |

### Medication, clinical-adjacent care and professional links

| Existing table | Subject | Provenance / verification columns | Interpretation of evidence | Review direction |
|---|---|---|---|---|
| `patient_medications` | Care recipient | `prescribing_professional_id`, `verified`, `external_ids`, dates | Optional prescriber FK and boolean, no required proof | Caregiver-maintained until reconciled with source |
| `medication_schedules` | Care recipient | `created_by_profile_id`, `patient_medication_id`, times | Schedule creator; no professional approval field | Reminder, not a prescription |
| `medication_events` | Care recipient / caregiver | `caregiver_profile_id`, `source`, `scheduled_for`, `actual_at`, `status` | Actor/source/time; not objective ingestion confirmation | Caregiver-reported event |
| `care_documents` | Care recipient | `uploaded_by_profile_id`, `document_type`, `extracted_text`, `reviewed` | Uploader/OCR and reviewed boolean; no reviewer ID | Sensitive; manual review and explicit consent |
| `incidents` | Care recipient / reporter | `reported_by_profile_id`, `occurred_at`, `visibility`, `support_level`, `approved_to_share_by_profile_id` | Reporter/time/share markers, not clinical diagnosis | Private first; reviewed summary with authorization |
| `incident_observations` | Care recipient / observer | `observed_by_profile_id`, `observed_at`, `professional_verified`, `verified_by_professional_id` | Observer and explicit optional verification metadata | Professional-review evidence before clinical use |
| `caregiver_appointments` | Care recipient | `requested_by_profile_id`, `professional_id`, `scheduled_for`, `status` | Local appointment request/status | Not proof of hospital booking |
| `professional_profiles` | Professional directory | `profile_id`, `is_verified`, `verification_note`, `external_ids` | Verification flag/note, not verified license | Confirm external practitioner identity |
| `professional_connections` | Care recipient / professional | `authorized_by_profile_id`, `status`, `connection_type` | Local authorization/status label | Not an approved clinical endpoint |
| `professional_instructions` | Care recipient | `professional_id`, `status`, `verified_at`, `external_ids` | Optional professional link and verification timestamp | Confirm provenance, current status and clinical scope |
| `professional_contact_requests` | Caregiver / care recipient | `caregiver_profile_id`, `professional_id`, `handoff_summary_id`, `channel`, `status` | Initiator/request/status | Not proof of delivered clinician communication |

### Care coordination, familiar activities and timeline

| Existing table | Subject | Provenance / verification columns | Interpretation of evidence | Review direction |
|---|---|---|---|---|
| `care_tasks` | Family / recipient | `requested_by_profile_id`, `assigned_to_profile_id`, `source`, timestamps | Source CHECK: manual / routine / hani_suggestion | No AI suggestions as medical orders |
| `care_task_requests` | Care-circle actors | `requester_profile_id`, `recipient_profile_id`, `responded_at` | Request/response actor links | Private coordination record |
| `timeline_events` | Care recipient | `source_type`, `source_id`, `created_by_profile_id`, `visible_to_care_circle` | Polymorphic source and visibility markers | Resolve underlying evidence before sharing |
| `patient_memory_items` | Care recipient | `item_type`, `metadata`, `image_url`, `media_url` | No explicit author/reviewer field | Memory aid, not cognitive assessment |
| `patient_activity_sessions` | Care recipient / caregiver | `caregiver_profile_id`, `memory_item_id`, `response_label`, timing | Optional recorder and response | Supportive activity, not diagnostic |

### Caregiver-private speech, wellbeing and derived AI

| Existing table | Subject | Provenance / verification columns | Interpretation of evidence | Review direction |
|---|---|---|---|---|
| `hani_conversations` | Caregiver | `caregiver_profile_id`, `patient_id`, `private_to_caregiver`, `channel` | Ownership and privacy markers | Private caregiver record by default |
| `hani_messages` | Caregiver / Hani | `conversation_id`, `sender`, `locale`, `metadata` | Sender user/hani/system, not clinical authority | No automatic transcript-to-patient export |
| `hani_memory_items` | Caregiver / possible shared patient | `memory_scope`, `source_type`, `source_id`, `valid_until` | Explicit private_caregiver/shared_patient scope | Check actual source and sharing rights |
| `wellbeing_checkins` | Caregiver | `caregiver_profile_id`, `source`, mood/energy/sleep, `free_text` | Source: manual / hani / questionnaire_followup | Private caregiver wellbeing |
| `support_signals` | Caregiver | `signal_type`, `severity`, `confidence`, `evidence`, `experimental` | Experimental inferred signals and evidence JSON | Not a validated clinical measure |
| `voice_emotion_analyses` | Caregiver / voice | `conversation_id`, `model_name`, `model_version`, `confidence`, `distribution` | Model version/score, not diagnostic evidence | Experimental; exclude from EHR exchange |
| `voice_emotion_segments` | Caregiver / voice | `analysis_id`, `start_ms`, `end_ms`, `dominant_emotion`, `confidence` | Segment-level model inference | Experimental; exclude from EHR exchange |

### Questionnaires and clinical-content governance

| Existing table | Subject | Provenance / verification columns | Interpretation of evidence | Review direction |
|---|---|---|---|---|
| `questionnaire_definitions` | Instrument catalogue | `code`, `purpose`, `owner` | Owner text, not licensed/validated instrument | Qualified instrument review |
| `questionnaire_versions` | Instrument version | `version_label`, `language`, `validation_status`, `validation_reference` | Declared version and validation marker | Evidence of license, clinical and language review |
| `questionnaire_questions` | Instrument item | `version_id`, `scoring_rule`, `response_type` | Scoring metadata, not validated algorithm | No claim of approved screening |
| `questionnaire_sessions` | Caregiver / optional recipient | `caregiver_profile_id`, `patient_id`, `trigger_type`, timing | Responder and optional patient link | Keep caregiver-private unless authorized |
| `questionnaire_answers` | Respondent | `session_id`, `question_id`, `answer` | Question/session link only | Sensitive raw response |
| `questionnaire_results` | Respondent | `raw_score`, `interpretation_key`, `requires_professional_support` | Recorded score/flag, reviewer not identified | No diagnosis or automatic referral claim |
| `dilemma_scenarios` | Guidance catalogue | `scenario_key`, `version`, `validation_status` | Status field; clinical reviewer not enforced | Review evidence before 'validated' claim |
| `dilemma_questions` | Guidance item | `scenario_id`, `prompt_i18n`, `response_type` | Scenario link, not qualified validation | Unreviewed question bank |
| `dilemma_guidance` | Guidance item | `scenario_id`, `validation_status`, `condition_json` | Optional review label, no evidence FK | No treatment guidance without sign-off |
| `dilemma_red_flags` | Escalation content | `scenario_id`, `escalation_level`, `recommended_route`, `validation_status` | Label/routing idea, not real response pathway | No guaranteed emergency alerts |
| `clinical_content_reviews` | Review log | `entity_type`, `entity_id`, `reviewer_name`, `reviewer_role`, `review_status`, `reviewed_at` | Polymorphic reference; free-text reviewer; no required FK | Evidence registry requires qualified identity/version |

### Consent, disclosure and outbound summaries

| Existing table | Subject | Provenance / verification columns | Interpretation of evidence | Review direction |
|---|---|---|---|---|
| `consents` | Caregiver / optional patient | `actor_profile_id`, `scope`, `recipient_id`, grant/revoke/expiry timestamps | Consent event fields, not established legal authority | Require purpose, recipient, proxy proof |
| `disclosure_events` | Caregiver / optional patient | `actor_profile_id`, `consent_id`, `data_categories`, `purpose`, `payload_reference` | Declared disclosure trail and consent link | Verify true payload and receipt |
| `handoff_summaries` | Caregiver / care recipient | `caregiver_profile_id`, `patient_id`, `professional_id`, `consent_id`, approval/sent dates | Actor/consent/status, not clinician acceptance | Minimum necessary, reviewed, consented |
| `summary_deliveries` | Caregiver / care recipient | `caregiver_profile_id`, `channel`, `recipient`, `status`, `provider_response` | Transport outcome markers, not verified receipt | Private contact/delivery data |

### Audit, notifications and historical demo state

| Existing table | Subject | Provenance / verification columns | Interpretation of evidence | Review direction |
|---|---|---|---|---|
| `caregiver_audit_events` | Actor / system | `actor_profile_id`, `event_type`, `entity_type`, `entity_id` | Action lineage, audit completeness unknown | Operational provenance support |
| `caregiver_notifications` | Caregiver | `caregiver_profile_id`, `category`, `delivered_at`, `opened_at` | Delivery markers, not guarantee | Private operational data |
| `notification_preferences` | Caregiver | `caregiver_profile_id`, reminder flags and quiet hours | Owner-scoped preferences | Exclude from clinical interchange |
| `device_push_tokens` | Device / caregiver | `caregiver_profile_id`, `platform`, `token`, `last_seen_at` | Delivery token metadata | Keep confidential; never export |
| `hani_demo_state` | Legacy demo singleton | `id`, `payload`, `revision`, `updated_at` | Opaque JSON, no normalized clinical lineage | Exclude until reconciled |


## 4. Structural relationships and existing access-policy evidence

Confirmed FK or CHECK relationships (schema metadata only):

- `profiles.auth_user_id` references `auth.users.id`; `caregiver_patient_relationships.caregiver_profile_id` references `profiles.id` and `patient_id` references `patients.id`. Relationship `access_status` permits invited/active/suspended/revoked but does not itself establish recognized hospital proxy rights.
- `patient_medications.patient_id` references `patients.id` and optional `prescribing_professional_id` references `professional_profiles.id`. `medication_events.patient_medication_id` references `patient_medications.id`.
- `incidents.reported_by_profile_id` references `profiles.id`, while `incident_observations.verified_by_professional_id` optionally references `professional_profiles.id`.
- `hani_messages.conversation_id` references `hani_conversations.id`. `hani_memory_items.memory_scope` has a CHECK allowing `private_caregiver` or `shared_patient`.
- `questionnaire_answers` links to questionnaire sessions/questions and `questionnaire_results` links to sessions. `handoff_summaries.consent_id` and `disclosure_events.consent_id` link to `consents.id`.

**RLS metadata (not an end-to-end authorization test):** RLS was enabled on all **48** current public base tables. Many policies permit authenticated, actor- or relationship-scoped selection (e.g., `patients`, `patient_medications`, `hani_conversations`, `wellbeing_checkins`).

**Nine RLS-enabled tables had no defined `pg_policies` entries:** `care_documents`, `clinical_content_reviews`, `device_push_tokens`, `hani_demo_state`, `medication_events`, `medication_schedules`, `patient_activity_sessions`, `patient_memory_items`, `summary_deliveries`. For normal clients, no granting policy generally means denied; privileged server roles may bypass RLS. **This is not evidence that data is publicly exposed or that these workflows fail.** It does call for scoped API/client access tests.

The emotion SELECT policies specify role `public`, yet their `USING` expressions still require `auth.uid()` matching a caregiver profile and active patient relationship. Role name **alone** does not mean that emotion rows are anonymously readable. Verify positive/negative authenticated test cases and service-role routes.

## 5. Count-only reality check at inspection

| Aggregate count (no row content accessed) | Result |
|---|---:|
| Public base tables | **48** |
| `clinical_content_reviews` records | **0** |
| `dilemma_scenarios` records / records marked `validated` | **10 / 10** |
| `questionnaire_versions` records | **0** |
| `incident_observations` with `professional_verified = true` | **0** |
| `professional_instructions` with `verified_at` populated | **1** |

The ten `validated` scenario flags are **not independent clinical approval** when the clinical review registry is empty. Likewise, a single `verified_at` value is not proof of qualified reviewer identity. No live subject/content was retrieved to make clinical conclusions.

## 6. Minimum model for clinical review — proposed, not implemented

Before converting source data into openEHR/FHIR, the team should define (per statement/observation):

| Required notion | Proposed minimum | Gap relative to current schema |
|---|---|---|
| Subject | Care recipient **or** caregiver, distinguish explicitly | Some data is linked to patient even when private to caregiver |
| Asserter / actor | Named authenticated caregiver, verified professional, system or model | Optional `source`/actor fields vary across tables |
| Record origin | Caregiver report, professional record, imported data, OCR, or AI hypothesis | No uniform explicit origin/evidence reference |
| Event time | Clinical effective/observed time and recorded/reviewed time | Fields vary; many only include `created_at` |
| Validation | Qualified reviewer, verified date, source document, version and status | Booleans and status strings rarely establish evidence chain |
| Confidentiality | Patient context vs caregiver-private vs explicit care-circle share | Scopes exist in some tables, not universal |
| Consent/proxy | Authorizer identity, purpose, exact categories, recipient, expiry/revocation | Stored `consents` useful, legal/clinical scope not independently proven |
| Exchange audit | What exact minimum payload, to whom, when, success/rejection | Delivery and disclosure fields require end-to-end verification |

### Candidate FHIR use cases (research hypotheses)

| Use case | Candidate source tables | Possible FHIR concepts | Hard stop |
|---|---|---|---|
| **UC-01** Patient context | `patients`, `caregiver_patient_relationships` | `Patient`; `Condition`/`Observation` only where verified | No automatic diagnostic `Condition` from free-text stage |
| **UC-02** Professional medication context | `patient_medications`, `professional_instructions`, `medication_events` | `MedicationRequest`, `MedicationStatement`, possibly `AllergyIntolerance` only with suitable evidence | No authoritative prescribing/reconciliation or allergy source yet established |
| **UC-03** Caregiver/proxy authority | `profiles`, `caregiver_patient_relationships`, `consents`, `disclosure_events` | `RelatedPerson`, `CareTeam`, `Consent`, `Provenance`, `AuditEvent` | Verify legal authority, consent, recipient and revocation |
| **Later** Reviewed incident/handoff | `incidents`, `incident_observations`, `handoff_summaries` | `Observation`, `DocumentReference`, `Communication` | No raw private chats or unreviewed AI content; qualified human approval |

Mapping is deliberately **conceptual**: no FHIR version, implementation guide, hospital interface, validated profile, openEHR archetype/template or clinical exchange partner is confirmed. For openEHR, review existing archetype identifiers, licenses, language/version and clinician-approved datasets *before* proposing a custom template.

## 7. Review priorities and advisor questions

1. **Clinical source of truth:** What minimum Alzheimer's/caregiver data model is clinically meaningful, and which existing openEHR archetypes would be an appropriate basis?
2. **Provenance rule:** How should we distinguish caregiver-reported observations, clinically verified statements and Hani-generated hypotheses? Should `clinical_content_reviews` be linked to a versioned review evidence registry?
3. **Identity/consent:** What is the minimum legal and technical evidence that a caregiver is authorized as proxy, and how should revocation work across systems?
4. **Privacy boundary:** Which caregiver wellbeing, conversations, questionnaires and emotion inference should **never** enter the patient's hospital record without an explicit individualized governance decision?
5. **First proof of concept:** Should we prioritize read-only patient context, professional medication reconciliation, or validated proxy/consent (UC-01/02/03)? What test evidence would make the answer credible?

**Immediate work needed:** source-of-truth reconciliation with legacy `hani_demo_state`, actual API actor/source tracing, reviewer qualification/version references, a tiny synthetic mapping with negative access tests, and clinical/hospital questions prepared by the team. **Do not** modify clinical flags or add a new migration merely to fill this matrix.

## 8. Inspection method and reproducibility

**Read-only inputs:** `information_schema.tables` and `information_schema.columns`; `pg_constraint` for foreign keys/CHECKs; `pg_class.relrowsecurity` and `pg_policies` for access-policy metadata; count-only aggregate SQL for the six operational counts above. No clinical records, identifiers, message bodies, emails, media, prescription text or credentials were retrieved for this document, and **no database mutations occurred**.

~~~sql
-- Field names and data types; metadata only
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;

-- Defined client role policy intent; this is NOT a runtime authorization test
SELECT tablename, policyname, cmd, roles, qual, with_check
FROM pg_policies WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Field relationships/check constraints; metadata only
SELECT conrelid::regclass::text AS table_name, contype,
       pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE connamespace = 'public'::regnamespace AND contype IN ('f','c')
ORDER BY 1,2;
~~~

**Limitations:** This snapshot is current as of 20 October 2026, not a permanent data dictionary. Schema descriptions cannot establish real data provenance, completeness of API security, medical appropriateness, data protection compliance, or ready-to-run exchange. Clinical and advisor review are required before extending beyond synthetic information.

**Related work:** [integrated action plan](ACTION_PLAN_v0.1.md) · [schema audit](CURRENT_SCHEMA_AUDIT.md) · [clinical validation audit](openehr/CLINICAL_VALIDATION_AUDIT.md) · [FHIR use cases](fhir/USE_CASES.md) · [advisor brief](ADVISOR_BRIEF.md).
