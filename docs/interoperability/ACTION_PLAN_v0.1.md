# Hani Maak — Integrated Action Plan
### Clinical Data, openEHR, FHIR, Product Development and Research

**Version:** v0.1 — draft for technical review  
**Originally drafted:** 16 October 2026 · **Timeline reconciled:** 21 October 2026  
**Prepared for review by:** Lloyd Williams and Aditya Ayyagari  
**Coordinator:** Adam Ben Arbia  
**Status:** Workstream ownership, standards choices, proposed architecture and timelines are subject to review.

> **Purpose.** This is the integrated follow-up plan requested after our Hani Maak demonstration. It defines a clinical-data/openEHR group, a FHIR implementation group, and how both connect with existing engineering, clinical safety, research and potential hospital work. It identifies decisions where advisor guidance would be most valuable.

**Documentation progress (21 October 2026):** An initial read-only 48-table [clinical/provenance matrix](CLINICAL_DATA_PROVENANCE_MATRIX.md), a 16-candidate [openEHR CKM landscape](openehr/ARCHETYPE_LANDSCAPE.md), and a [FHIR source-to-resource mapping v0.1](fhir/FHIR_MAPPING_v0.1.md) are now **drafted for advisor review**. These are engineering/research inventories, **not clinical approval**, a finalized minimal dataset, a working FHIR interface, or completion of the proposed clinical team's workstream. The [executive summary](EXECUTIVE_SUMMARY.md) is the recommended entry point for the follow-up email.

**Schedule correction (21 October):** The follow-up previously promised for **Friday 16 October** was **not sent**. The revised target is **Wednesday 21 October**, **after Ahmed reviews and merges PRs #60, #61 and #62 into `main` and their combined state is checked**. This is a target, not a claim of completion. A new provisional internal 14-day window runs **22 October–4 November**, instead of treating 19 October–1 November as still on schedule. Actual advisor-response-dependent milestones will be recalculated after feedback, with no assumed reply date.

**Scope boundary:** the comprehensive **all-history personal-data/secret scan** is outside this email phase and remains a future security task. This does **not** clear known historical credential exposure. Check current material before sharing and do not claim that the demo login is ready. The expanded research package is retained as helpful context for Lloyd and Aditya.

**Navigate:** [Product](#1-product-and-current-state) · [Team assignments](#2-team-and-ownership) · [Workstreams](#3-integrated-workstreams) · [Architectures](#4-architecture-directions) · [Timeline](#5-integrated-roadmap) · [Review questions](#6-questions-for-lloyd-and-aditya)

## 1. Product and current state

**Hani Maak** is a multilingual caregiver-support companion for **family and informal caregivers of a person living with Alzheimer's disease**. The caregiver is the primary user. A care recipient may participate in familiar-activity or memory-recall experiences through the caregiver's device and account.

Hani supports text and real-time voice interaction in Tunisian Derja, Arabic, French and English. The evolving MVP also covers care tasks, reminders, medication tracking, incidents, Care Circle coordination, wellbeing and familiar-activity experiences. Features have different maturity levels; code presence is not equivalent to operational or clinical validation.

Hani Maak does **not** autonomously diagnose, prescribe, modify medication or replace healthcare professionals. The current demonstration uses synthetic data. A later extension to other dementia, neurodivergence, disability or dependent-care contexts is possible only after validating the Alzheimer's-specific product.

### Verified technical baseline — 20 October 2026

| Layer | Verified observation | Remaining validation |
|---|---|---|
| Caregiver interface | Flutter compiled web app served alongside Next.js on Vercel | Full authenticated end-to-end UI test |
| Application API | Next.js handles caregiver API routes and a demo-state path | Exact route-to-table map |
| Hani agent | FastAPI on Vercel; Next.js text-chat proxy; signed direct voice WebSocket path | Failover, retention and safety test |
| AI | Agent health reported Gemini text and Live voice models | Model/version can change with deployment |
| Database | Running Supabase has normalized caregiver tables **and** a separate older JSON demo-state singleton | Reconcile database, migrations and historical repository SQL |
| Emotion analysis | Railway v2 service online but checked Hani-agent feature **disabled** | Future clinical and language validation |
| Clinical governance | 10 dilemma scenarios marked “validated”; no clinical-review records found | Establish evidence and appropriate review status |
| Hospital exchange | No confirmed production FHIR/openEHR or Razi connection | Clinical and technical discovery |

The demonstration sign-in includes a shortcut; it must not be represented as production-grade patient identity verification. The full trace and constraints are in [Current Architecture](../architecture/CURRENT_ARCHITECTURE.md) and [Current Schema Audit](CURRENT_SCHEMA_AUDIT.md).

## 2. Team and ownership

**All six team members are actively involved and committed to continuing Hani Maak.** Exact next-task allocation, qualified clinical sign-off and schedules are separate coordination questions, not indications of reduced team commitment.

| Member | Working responsibility | Confirmation and constraints |
|---|---|---|
| **Adam Ben Arbia** | Coordination, technical architecture and source-of-truth verification, document integration, FHIR/research support | Coordination and final package editing established in the sprint brief. Does **not** own hospital outreach. |
| **Salma Ghorbel** | Co-coordinate clinical-data/openEHR; team hospital-contact owner; research exploration | **Explicitly accepted openEHR co-coordination at approximately 8 hours/week** in her response. Hospital/Digital Hospital status is still discovery, not a formal pilot. |
| **Hela Sellami** | Clinical-domain inventory, clinical and governance questions, Razi discovery with Salma | Actively engaged; specific next deliverables and dates to coordinate. |
| **Eya Sassi** | Clinical, caregiver privacy and safety review; candidate questionnaire and openEHR input | Actively engaged; review scheduling and independent clinician/institutional approval are distinct from team commitment. |
| **Ahmed Braiek** | Engineering, repository maintenance and GitHub merges; proposed technical lead for FHIR | Actively engaged; responsible for merging reviewed PRs. The old response packet lacked a standalone technical truth sheet; precise FHIR allocation and schedules remain to coordinate. |
| **Emna Fradi** | Engineering/QA and FHIR-group contribution to be scheduled | Actively engaged; specific FHIR review tasks and dates remain to coordinate. |

**Hospital communication:** Salma and Hela coordinate requests to Razi/Hôpital Numérique; Adam provides the technical questions and uses results for design, but does not initiate hospital outreach.

**Confirmed versus checked:** Team member statements are attributed reports, not independent institutional verification. Some deployment and database facts have since been directly checked and are separated in the current-state table above.

### Team-response provenance

The prior integrated revision dated 18 October drew on the original action plan, the Thursday follow-up sprint, and the Eya/Emna/Hela/Salma response packet. Its corrected points are preserved here:

- **Salma:** written continued-support statement from the Connectathon organizers was *reported*; a possible Digital Hospital implementation was discussed **verbally only**. Neither establishes an executed agreement. Hospital meeting not scheduled and proposed testing postponed. An Alzheimer's data-model **paper is exploratory and separate from her thesis**; the supervisor had not accepted that topic as her thesis.
- **Hela:** reported chat/voice, emotional check-ins, cognitive activities, peer-support, crisis protocols and doctor alerts; **reported features are not verified live clinical workflows**. She supplied focused hospital discovery questions.
- **Eya:** proposed review of caregiver burden tools (ZBI variants), mental-health screening suitability, wandering/nocturnal agitation, caregiver-versus-patient privacy and clinically governed escalation. These suggestions **are not adopted/validated tools or clinical sign-off**.
- **Emna:** initially flagged a public WhatsApp test number and did **not** complete a full history/secrets/synthetic-data review. A later GitHub-only cleanup is proposed in draft PR #62; historical content and deployment changes remain separate.

## 3. Integrated workstreams

### A. Clinical data and openEHR
**Leads:** Salma + Hela; **review:** Eya; **technical coordination:** Adam.

**Goal:** investigate whether existing openEHR archetypes/templates can support the relevant clinical data, and construct a minimum Alzheimer's and caregiver information model. openEHR is a direction to evaluate, **not** an adopted database architecture.

| Task | Owner(s) | Reviewable output and format | Phase |
|---|---|---|---|
| A1. Inventory current care recipient, caregiver, medication, behavior, activities, incidents, care plan, wellbeing and sharing concepts | Hela + Salma; Eya reviews | Clinical-domain matrix — Markdown/CSV | 1 |
| A2. Identify caregiver-entered, professionally verified, AI-generated and imported facts; distinguish caregiver privacy from patient data | Salma + Hela + Adam | Data-provenance and privacy matrix — Markdown | 1–2 |
| A3. Review clinical-content status, emergency/doctor-alert claims, check-ins and escalation ownership | Hela + Eya | Clinical validation register — Markdown | 1 |
| A4. Survey **existing** archetypes and templates, source identifiers and reuse gaps | Salma + Hela + Eya | Archetype landscape — linked Markdown | 2 |
| A5. Draft minimum dataset and identify what requires clinician verification | Clinical group + Adam | Dataset v0.1 and gap list — Markdown/CSV | 2 |

**Clinical safeguards:** A caregiver wellbeing check-in is not a diagnosis. Alzheimer's stage, cognitive measures, medication instructions, burden scales and emergency criteria require documented sources and qualified review. In particular, caregiver conversations, emotions and family conflicts must not be copied into a care recipient's hospital record by default.

Supporting initial audit: [Clinical Validation Audit](openehr/CLINICAL_VALIDATION_AUDIT.md). **Initial engineering inventory drafted:** [Clinical-Data and Provenance Matrix](CLINICAL_DATA_PROVENANCE_MATRIX.md), [openEHR Archetype Landscape](openehr/ARCHETYPE_LANDSCAPE.md); clinical verification, sign-off and archetype/template selection remain open.

### B. FHIR implementation
**Proposed technical lead:** Ahmed; **contributors:** Adam and Emna (specific FHIR tasks to schedule).

**Goal:** design a purpose-driven FHIR exchange boundary. First discover use cases, identity, consent and hospital capability; implement only after selecting a feasible, reviewable path.

| Task | Owner(s) | Reviewable output and format | Phase |
|---|---|---|---|
| B1. Rank two or three initial interoperability use cases and identify actor, data, direction and safety need | Adam + FHIR group | Use-case register — Markdown | 1 |
| B2. Reconcile relevant normalized Supabase tables and legacy demo-state dependencies | Adam + proposed technical group | Schema/use-case map — Markdown | 1–2 |
| B3. Investigate candidate resources and profiles (including Patient, RelatedPerson, Consent, Condition, MedicationRequest and DocumentReference as appropriate) | Proposed FHIR group | Preliminary mapping — Markdown table | 2 |
| B4. Specify proxy authority, access revocation, provenance, data minimization, audit and read/write policy | Adam + FHIR group | Identity/access decision draft — Markdown | 2 |
| B5. Prepare **synthetic** examples and contract tests after expert review | Technical group | FHIR JSON and test checklist | 3 |

The hospital FHIR version, implementation guides and authentication scheme are **not yet selected**. A **read-oriented first proof of concept** is the current hypothesis. Sharing reviewed incidents, caregiver summaries or questionnaires back to a hospital is a separate later possibility that needs consent and clinical governance.

See [Initial FHIR Use Cases](fhir/USE_CASES.md) and [preliminary field-to-resource mapping](fhir/FHIR_MAPPING_v0.1.md). Those documents provide initial candidate designs, **not approved FHIR implementation or clinical data exchange**.

### C. Product and engineering
**Owners:** Adam + Ahmed (proposed technical owner); **QA:** Emna (to confirm).

1. **Establish the current truth:** verify deployment and the specific routes using normalized caregiver tables versus the earlier Supabase-backed demo-state JSON; reconcile historical repository SQL and actual migrations.
2. **Document safe boundaries:** caregiver/care-recipient relationship, RLS and backend privileges, private Hani messages, voice/transcript retention and consent.
3. **Correct public documentation:** caregiver-first README positioning, distinguish current and historical modules, list all team contributors accurately.
4. **Repository QA:** check current shareable files for unnecessary test numbers and exposed values, verify relevant links/builds and record known limitations. The comprehensive **all-history privacy/secret audit is deferred outside this email phase**, not completed and not a safety clearance.
5. **Resolve clinical labeling:** do not treat database flags as independent clinician review. Establish approval evidence and impact assessment before changing production status or behavior.

**Outputs:** [Current Architecture](../architecture/CURRENT_ARCHITECTURE.md), [Schema Audit](CURRENT_SCHEMA_AUDIT.md), verified repository/QA notes (Markdown), and a later architecture decision record if needed. Neither a schema snapshot nor an illustrative FHIR mapping should be deployed as an unreviewed migration.

### D. Hospital discovery and validation opportunity
**Communication owners:** Salma + Hela. Technical questions are prepared with Adam and the FHIR group.

The potential Razi/Hôpital Numérique relationship is at **discovery stage**. No meeting, clinical testing, EHR integration, sandbox or formal pilot is confirmed. The team reported an unscheduled follow-up and postponed testing. Written continued support from organizers and a verbal discussion of possible Digital Hospital implementation are distinct.

| Inquiry | Output | Dependency |
|---|---|---|
| Clinical validation process and appropriate reviewers | Contact/outreach status and clinical questions — Markdown | Hospital response |
| Hospital DMI/EHR, API/FHIR/HL7/interface engine and test environment | Technical discovery matrix — Markdown | Hospital technical contact |
| Patient identity, caregiver proxy authority, consent, data residency, access/security, audit | Governance questions — Markdown | Hospital/legal/clinical stakeholders |
| Appropriate scope for potential evaluation of caregiver support | Conditional evaluation hypothesis — Markdown | Clinical owner and necessary approvals |

No automated hospital sharing or doctor-alert delivery should be described as functioning without verified endpoints, authorized recipients, acknowledgement/fallback behavior and clinical oversight.

### E. Research / potential publication
**Leads:** Salma + Adam; **input:** Hela, Eya and technical team.

Explore whether a standards-aligned **Alzheimer's caregiver information model** with provenance, caregiver privacy and an openEHR/FHIR pathway offers a useful research contribution. The AI integration dimension is also a possible research question; scope is not fixed.

**Outputs:** source-linked literature matrix (CSV/BibTeX/Markdown), existing-model comparison, evidence-based gap statement and a short research concept note. This is a separate exploratory publication direction, **not** an agreed thesis, accepted article or established authorship order.

## 4. Architecture directions

### 4.1 Present system (simplified)

~~~mermaid
flowchart LR
  Flutter["Flutter caregiver app"] --> Next["Next.js API"]
  Flutter -. "signed voice session" .-> Hani["FastAPI Hani agent"]
  Next --> Supabase[("Supabase caregiver tables + demo state")]
  Next --> Hani
  Hani --> Gemini["Gemini text / live voice"]
  Hani -. "optional; disabled at check" .-> Emotion["Railway emotion service"]
~~~

### 4.2 Candidate standards-aligned boundary

~~~mermaid
flowchart LR
  App["Hani Maak app"] --> Domain["Governed domain / API"]
  Domain --> Model["Caregiver + Alzheimer's information model"]
  Model -. "modeling evaluation" .-> OE["Existing openEHR content"]
  Domain -. "exchange design" .-> FHIR["Candidate FHIR boundary"]
  FHIR -. "interface unknown" .-> EHR["Hospital DMI / EHR"]
~~~

### 4.3 Illustrative Carefluence-based evaluation path

~~~mermaid
flowchart LR
  App["Hani Maak"] --> API["Domain / API"]
  API -. "candidate exchange" .-> FHIR["FHIR boundary"]
  FHIR -. "platform to evaluate" .-> Carefluence["Carefluence"]
  Carefluence -. "hospital fit unconfirmed" .-> Hospital["Potential hospital system"]
~~~

This last diagram is a **discussion option**, not a selected architecture, an agreed platform integration or proof that the hospital interface exists.

## 5. Corrected roadmap — 21 October delivery, then two-week coordination

**Missed commitment:** The email to Lloyd promised for **Friday 16 October 2026** was not sent. This revised plan targets **Wednesday 21 October** for the actual reply and GitHub package, after the required merges and verification. The original **19 October–1 November** planning assumption is replaced by **22 October–4 November** for remaining internal tasks; no advisor reply date is assumed. Prior work already completed is retained, not restarted.

**GitHub merge prerequisite:** Before today's email, **Ahmed merges PRs #61, #62 and #60 into `main`** after reviewing the latest checks, then verifies the combined state and main-branch documentation links. This is **GitHub integration, not a Supabase database migration**. A draft PR and a green isolated CI check are not proof of a successful merge. Merges remain planned until verified.

| Date / window | Workstream | Milestone or dependency |
|---|---|---|
| **21 Oct — before email** | Ahmed, supported by team review | Review and merge PRs **#61, #62, #60** into `main`; inspect resulting files and build status; project coordinator sends overdue reply to Lloyd after verification. No merge or email is recorded as completed in advance. |
| **22–26 Oct** | Engineering and QA | **Provision the dedicated Supabase Auth demo user, which does not currently exist.** Verify confirmed email, immutable user UID, allowlisted `DEMO_ACCOUNT_USER_ID`, opt-in `PUBLIC_SYNTHETIC_DEMO` only in an authorized preview, rebuilt Flutter bundle and positive/negative access tests. **Not required for a documentation-only email**; merged code alone is not a working account. |
| **22–28 Oct** | Salma, Hela, Eya; Adam documents | Review the clinical/provenance matrix and candidate openEHR archetypes; agree a clinically meaningful minimal dataset and sources. Qualified clinical verification is separate. |
| **22–30 Oct** | Ahmed, Emna, Adam | Agree a first read-oriented FHIR use case, source/consent/authorization conditions and standards questions, informed by advisor feedback if available. |
| **22 Oct onward** | Salma and Hela | Coordinate hospital discovery when external participants are available; no pilot meeting or approval date assumed. |
| **By 4 Nov — provisional internal checkpoint** | Committed Hani Maak team | Review actual advisor feedback **if received**, technical/clinical evidence and prototype/demo validation; reset advisor-dependent dates based on their real availability. |

**Outside the current email phase:** comprehensive history-wide privacy/secret and personal-data auditing is deferred to a **separate security workstream**. Known publicly exposed demo credentials are not considered cleared by this deferral. No real clinical exchange, Razi pilot or working FHIR/openEHR adapter is implied.

**Beyond this window:** any synthetic standards proof of concept, Carefluence technical assessment or hospital implementation is subject to advisor/clinical guidance, correct authorizations and independent validation.

### Readiness and dependency gates

1. Only claim a public page, feature, build or protection is **verified** when the applicable runtime/check evidence exists. Distinguish source-code presence from actual operation.
2. No clinical screening, crisis routing or doctor-alert claims without an accountable human response pathway and qualified clinical sign-off.
3. No mapping of raw/private caregiver chat or wellbeing into the patient's record by default; consent, minimization and provenance are required.
4. No automatic database migration or production change from this plan. OpenEHR and FHIR remain **evaluation tracks**, not a selected stack.
5. Verify implementation evidence and coordinate precise next-workstream scheduling before reporting milestones. **All six team members remain committed.**
6. **Ahmed handles the merges of PRs #60–#62 into `main` ahead of the revised 21 October email.** Verify combined main-branch state and links before sharing. The merge does not provision Supabase Auth or validate the hosted demo.

## 6. Questions for Lloyd and Aditya

1. Does our separation of **clinical data/openEHR** and **FHIR implementation** reflect the intended approach?
2. Which interoperability use cases should lead the first review?
3. Which existing openEHR archetypes, communities or clinical-data review processes should our group study?
4. Is a read-oriented synthetic proof of concept appropriate, and which FHIR resources/profiles should we investigate first?
5. What must be learned from Razi/Hôpital Numérique before planning a technical hospital connection?
6. What minimum documentation and mappings would be most useful for the next joint review?

## 7. Definition of done for this draft

The next advisor-facing package contains this plan, a verified architecture summary, a reconciled data-model status (including unknowns), prioritized interoperability use cases and outstanding clinical-review questions. It should clearly separate **implemented**, **experimentally configured**, **proposed** and **not yet confirmed** items.

**Next action:** complete and verify GitHub merges on 21 October, send the overdue advisor follow-up, then seek feedback on workstream design and the initial interoperability use case. Coordinate detailed future tasks within the already committed team and retain honest clinical/demo limitations.

### Decision and risk register

| ID | Open decision | Current evidence/status | Responsible follow-up |
|---|---|---|---|
| D01 | Which one or two FHIR use cases lead? | Seven candidates; first shortlist remains proposed | Adam, FHIR group, Lloyd/Aditya |
| D02 | openEHR archetype/community reuse? | Not selected or reviewed by an external modeler | Salma, Hela, Eya, advisors |
| D03 | Which schema/API path is authoritative? | Normalized and older demo-state storage **both observed** | Adam, proposed Ahmed/Emna review |
| D04 | Historical personal-data/secret audit? | **Out of scope for the 21 October email phase**; not performed or cleared. Known public demo-credential exposure and current-file checks remain distinct | Separate future security workstream |
| D05 | Clinical approval for dilemmas, burden scales or alerts? | No clinical-content review records in checked DB; external sign-off **unverified** | Clinical group and qualified clinicians |
| D06 | Hospital capability, contact, pilot approval, recipient for alerts? | Unconfirmed; **Razi engagement is discovery only** | Salma/Hela and institution |
| D07 | Carefluence integration needed? | Architectural evaluation option only, no agreed integration | Lloyd/Aditya and Adam |
| D08 | Exact next workstream schedules and responsibilities? | **All six members are active and committed**; individual technical/clinical approval tasks and dates are being coordinated. Salma's reported openEHR capacity is ~8h/week. | Adam + team |
| D09 | Is Alzheimer data modeling an approved thesis? | **No**; separate exploratory paper possible | Salma and research team |
| D10 | Demo identity and review readiness? | **Dedicated Supabase Auth demo user not yet provisioned**. PR #61 code merge, Auth setup, preview config and end-to-end validation are separate milestones | Engineering / QA after merge |

### Evidence provenance and revision notes

- **Sources for team statements:** 16 October initial plan, Thursday follow-up sprint plan, 18 October revised plan and Eya/Emna/Hela/Salma response packet. These were not independent technical or institutional certifications.
- **Technical observations updated 20 October:** read-only live deployment, code and Supabase checks recorded in linked current architecture/schema/clinical audit files.
- **No endorsement implied:** Lloyd, Aditya, Carefluence, Razi, Hôpital Numérique and the study authors did not approve this plan merely by being referenced.

