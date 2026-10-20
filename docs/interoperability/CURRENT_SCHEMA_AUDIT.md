# Current Supabase Schema Audit
**Read-only findings, 20 October 2026.** No database records were modified or exported.

## Data model

The running Supabase project contains normalized tables for caregiver profiles, care recipients, relationship permissions, Care Circles, professionals, medications, care tasks, incidents, wellbeing, questionnaires, Hani conversations, consent, disclosure, summaries, documents, memory activities, notifications and experimental emotion signals.

A separate **hani_demo_state** JSON singleton exists alongside these tables. The repository's older supabase/schema.sql represents a historical patient-journey model. The running normalized schema and legacy paths therefore need reconciliation before openEHR/FHIR mapping.

## Count-only observations

| Data group | Observed |
|---|---:|
| Demo profiles / demo care recipients | 3 / 1 |
| Hani chat / voice conversations | 32 / 55 |
| Hani messages | 385 |
| Dilemma scenarios labeled validated | 10 |
| Clinical-content review records | 0 |
| Dilemma question / guidance / red-flag rows | 0 / 0 / 0 |
| Emotion analyses / saved support signals | 0 / 0 |
| Handoff summaries / consents / summary deliveries | 0 / 0 / 0 |

The demonstration data labels do not independently establish that every string or contact detail is fictitious.

## Privacy and access

Owner-scoped RLS policies exist for private conversations, messages and caregiver wellbeing. Other tables need access testing. Supabase identified nine RLS-enabled tables **without policies**: care_documents, clinical_content_reviews, device_push_tokens, hani_demo_state, medication_events, medication_schedules, patient_activity_sessions, patient_memory_items and summary_deliveries. A table with RLS but no policy normally denies direct client access; service-role routes must be reviewed before altering permissions.

Private caregiver wellbeing, journal, family conflict and conversation content must not automatically be exported into a care recipient's clinical record.

## Next tasks

1. Establish authoritative running DDL and migration history.
2. Identify normalized versus demo-state API consumers.
3. Map data origin (caregiver, professional, AI, imported), verification, timestamp and permitted sharing.
4. Review clinically unsupported validation flags.
5. Test synthetic user authorization and consent/revocation.
6. Map prioritized FHIR use cases rather than every database field.

This is a structural audit, not a privacy, security or clinical compliance certification.