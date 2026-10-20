# Preliminary FHIR Interoperability Use Cases
**Status:** Exploration for advisor review, 20 October 2026. **No FHIR implementation or hospital endpoint confirmed.**

**Proposed technical lead:** Ahmed Braiek. Adam Ben Arbia coordinates; Emna Fradi participation needs confirmation.

## Prioritized use cases

| ID | Scenario | Direction | Candidate FHIR concepts | Gate |
|---|---|---|---|---|
| UC-01 | Read authorized care-recipient context | Hospital to Hani Maak | Patient, Condition, Observation | Matching identity and permissions |
| UC-02 | Read professional medication list | Hospital to Hani Maak | MedicationRequest, MedicationStatement, AllergyIntolerance | Source verification, clinical reconciliation |
| UC-03 | Confirm caregiver/proxy authority | Access control | RelatedPerson, CareTeam, Consent | Authority, scope, revocation |
| UC-04 | Read appointments/care plan | Hospital to Hani Maak | Appointment, CarePlan | Hospital interfaces available |
| UC-05 | Share reviewed incident summary | Hani Maak to hospital; later | DocumentReference, Communication, Observation | Consent, human review, delivery |
| UC-06 | Share reviewed caregiver summary or questionnaire | Hani Maak to hospital; later | QuestionnaireResponse, DocumentReference | Explicit consent, data minimization |
| UC-07 | Audit exchange | Both | Provenance, AuditEvent | Defined governance and retention |

**First advisor discussion:** UC-01, UC-02 and UC-03. A read-oriented first proof of concept is a proposal, not an approved design.

## Core requirements

- Keep **caregiver-private wellbeing, conversations and family matters** separate from the care recipient's clinical record by default.
- Caregiver family relationships do not automatically grant clinical record access.
- Preserve who asserted a fact, whether it was professionally verified, when and from which system.
- Never infer a diagnosis or medication change from incomplete, caregiver-entered or AI-generated information.
- Use synthetic examples; no real caregiver/patient data in integration tests.

## Unknowns and decisions

Hospital DMI/EHR capabilities, any FHIR version and implementation guides, identity/proxy rules, read/write permissions, terminology, API authentication, auditing and the possible role of Carefluence are **undecided**.

The current Supabase schema and older demo-state JSON path need reconciliation before field mappings are treated as authoritative.

## Output sequence

1. Use-case and minimal data requirement sign-off.
2. Candidate resource / data provenance mapping (Markdown table).
3. Consent, identity, audit and revocation rules.
4. Advisor review of read/write direction and FHIR version.
5. Synthetic FHIR JSON examples and negative authorization tests.
6. Conditional interoperability proof of concept after technical and clinical review.