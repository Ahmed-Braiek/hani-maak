# Hani Maak — Integrated Action Plan
### Clinical Data, openEHR, FHIR, Product Development and Research

**Version:** v0.1 — draft for technical review  
**Prepared:** 16 October 2026 · **Revised:** 20 October 2026  
**Prepared for review by:** Lloyd Williams and Aditya Ayyagari  
**Coordinator:** Adam Ben Arbia  
**Status:** Workstream ownership, standards choices, proposed architecture and timelines are subject to review.

> **Purpose.** This is the integrated follow-up plan requested after our Hani Maak demonstration. It defines a clinical-data/openEHR group, a FHIR implementation group, and how both connect with existing engineering, clinical safety, research and potential hospital work. It identifies decisions where advisor guidance would be most valuable.

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

The following are **functional workstream assignments**, not executive titles. Unconfirmed participation is noted as proposed.

| Member | Proposed responsibility | Primary output |
|---|---|---|
| **Adam Ben Arbia** | Coordination, technical architecture, document integration, FHIR/research support | Integrated plan, architecture and consolidated review package |
| **Salma Ghorbel** | Research lead; clinical-data/openEHR co-lead; hospital contact coordination | Research survey, domain review, hospital discovery |
| **Hela Sellami** | Clinical-data/openEHR co-lead; clinical concepts; hospital communication | Clinical-domain inventory, validation questions, Razi discovery |
| **Eya Sassi** | Clinical review and literature support; participation expected, to confirm | Privacy/safety review, clinical gaps |
| **Ahmed Braiek** | **Proposed** technical lead for FHIR and engineering; availability not confirmed | Code/schema truth, implementation mapping |
| **Emna Fradi** | **Proposed** FHIR contributor and QA lead; confirmation pending | Repo audit, test evidence, technical mapping |

**Hospital communication is assigned to Salma and Hela, not Adam.** Adam uses their findings for engineering and planning but does not initiate or manage outreach.

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

Supporting initial audit: [Clinical Validation Audit](openehr/CLINICAL_VALIDATION_AUDIT.md).

### B. FHIR implementation
**Proposed lead:** Ahmed; **contributors:** Adam, Emna (to confirm).

**Goal:** design a purpose-driven FHIR exchange boundary. First discover use cases, identity, consent and hospital capability; implement only after selecting a feasible, reviewable path.

| Task | Owner(s) | Reviewable output and format | Phase |
|---|---|---|---|
| B1. Rank two or three initial interoperability use cases and identify actor, data, direction and safety need | Adam + FHIR group | Use-case register — Markdown | 1 |
| B2. Reconcile relevant normalized Supabase tables and legacy demo-state dependencies | Adam + proposed technical group | Schema/use-case map — Markdown | 1–2 |
| B3. Investigate candidate resources and profiles (including Patient, RelatedPerson, Consent, Condition, MedicationRequest and DocumentReference as appropriate) | Proposed FHIR group | Preliminary mapping — Markdown table | 2 |
| B4. Specify proxy authority, access revocation, provenance, data minimization, audit and read/write policy | Adam + FHIR group | Identity/access decision draft — Markdown | 2 |
| B5. Prepare **synthetic** examples and contract tests after expert review | Technical group | FHIR JSON and test checklist | 3 |

The hospital FHIR version, implementation guides and authentication scheme are **not yet selected**. A **read-oriented first proof of concept** is the current hypothesis. Sharing reviewed incidents, caregiver summaries or questionnaires back to a hospital is a separate later possibility that needs consent and clinical governance.

See [Initial FHIR Use Cases](fhir/USE_CASES.md).

### C. Product and engineering
**Owners:** Adam + Ahmed (proposed technical owner); **QA:** Emna (to confirm).

1. **Establish the current truth:** verify deployment and the specific routes using normalized caregiver tables versus the earlier Supabase-backed demo-state JSON; reconcile historical repository SQL and actual migrations.
2. **Document safe boundaries:** caregiver/care-recipient relationship, RLS and backend privileges, private Hani messages, voice/transcript retention and consent.
3. **Correct public documentation:** caregiver-first README positioning, distinguish current and historical modules, list all team contributors accurately.
4. **Repository QA:** remove unnecessary public test numbers, review tracked files **and Git history** for secrets/personal details, validate synthetic-data provenance and check links/build/test results.
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

## 5. Integrated roadmap

| When | Focus | Completion evidence |
|---|---|---|
| **Phase 1 — Week 1** | Current truth and safety | Deployment/schema reconciliation, initial clinical inventory, review-status audit, prioritized FHIR use cases, repo QA findings |
| **Phase 2 — Weeks 2–3** | Standards assessment | openEHR landscape, candidate minimal dataset, FHIR mapping, consent/provenance design, research literature comparison |
| **Review gate — end of Week 3** | Request expert guidance | Architecture, current schema decisions, preliminary mappings, clinical gaps and specific questions |
| **Phase 3 — after review** | Conditional, limited POC | Synthetic payloads, implementation boundary and security tests; hospital-specific design only if relevant access is clarified |

Phases are relative to team confirmation, not fixed calendar commitments. Hospital discussions can continue in parallel. **The initial action plan and current architecture are shared earlier**; the Week 3 gate concerns the more substantive technical outputs.

**Dependencies:** clinical inventory before archetype gap claims; prioritized use cases and reconciled persistence before FHIR mapping; identity/consent rules before any sensitive-data exchange; qualified clinical review before safety-related deployment or public validation claims.

## 6. Questions for Lloyd and Aditya

1. Does our separation of **clinical data/openEHR** and **FHIR implementation** reflect the intended approach?
2. Which interoperability use cases should lead the first review?
3. Which existing openEHR archetypes, communities or clinical-data review processes should our group study?
4. Is a read-oriented synthetic proof of concept appropriate, and which FHIR resources/profiles should we investigate first?
5. What must be learned from Razi/Hôpital Numérique before planning a technical hospital connection?
6. What minimum documentation and mappings would be most useful for the next joint review?

## 7. Definition of done for this draft

The next advisor-facing package contains this plan, a verified architecture summary, a reconciled data-model status (including unknowns), prioritized interoperability use cases and outstanding clinical-review questions. It should clearly separate **implemented**, **experimentally configured**, **proposed** and **not yet confirmed** items.

**Next action:** obtain the team's confirmation of assignments, complete the repository's privacy/documentation cleanup, and request technical prioritization feedback before any hospital-facing interoperability implementation.
