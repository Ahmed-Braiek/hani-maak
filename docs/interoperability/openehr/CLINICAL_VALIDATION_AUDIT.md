# Clinical Validation Audit — Hani Maak
**Initial findings:** 20 October 2026. **Co-leads:** Salma Ghorbel and Hela Sellami; clinical review: Eya Sassi. Qualified external clinicians will be needed for safety-critical approval.

## Highest priority inconsistency

The live database has ten dilemma scenarios marked **validated**, but no clinical_content_reviews records. Dedicated dilemma guidance, question and red-flag tables have no rows. A validation flag without evidence is not a clinician sign-off.

Do not automatically edit statuses in the production database. First examine dependencies, verify whether evidence exists elsewhere, prepare a reviewed correction, then test resulting functionality.

## Topics requiring independent clinical review

| Area | Review needed |
|---|---|
| Hani support advice and dilemmas | Evidence source, approved scenarios, uncertainty and escalation |
| Emergency/doctor alerts | Real trigger, response owner, false alerts, delivery and fallback |
| Caregiver check-ins | Supportive vs clinical screening, referral and translations |
| Memory-recall activities | Suitability, distress and stop conditions |
| Medications | Verified instructions, no autonomous prescribing or dose changes |
| Burden assessment | Appropriate locally validated scales, licensing and trained reviewers |
| Emotion inference | Experimental language validity and consent |
| Professional summaries | Human approval, data minimization, explicit consent |

Clinical group inputs highlight wandering, nighttime agitation, caregiver burden, permissions and the distinction between caregiver distress and patient clinical information.

## Intended privacy boundary

| Data | Default external clinical sharing |
|---|---|
| Clinically relevant care-recipient symptoms | Only where appropriately authorized and needed |
| Private caregiver chats, voice, journals or family conflicts | No |
| Caregiver burden summary | Only with explicit, appropriate consent and review |
| Incident report | Only minimum relevant reviewed information with authorization |
| Suspected emergency | No automatic disclosure without a validated safety/legal workflow |

## Next outputs

1. Clinical-domain inventory (Markdown/CSV), with source and verification status.
2. Clinical content register with review evidence, version and status.
3. Qualified review protocol for guidance, red flags and escalation.
4. Existing openEHR archetype/template landscape.
5. Minimum Alzheimer/caregiver dataset and provenance boundaries.

This document does not assert hospital integration, certified screening, clinically validated alerts or clinician-approved guidance.