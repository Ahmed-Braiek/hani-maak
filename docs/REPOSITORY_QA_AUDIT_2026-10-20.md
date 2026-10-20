# Repository QA and Readiness Audit — Hani Maak

**Reviewed:** 20 October 2026  
**Scope:** Public GitHub repository (main at 598697cdf), PR #60, documentation, GitHub Actions, source-level access paths, and public demo endpoints.  
**Method:** Read-only source/history inspection and safe GET checks for documented public landing/health URLs. No production database operations, credential retrieval, destructive endpoint calls, or unauthorized account testing.  
**Status:** Open findings; not clearance for real patient data or external pilot.

## Executive summary

**External-sharing gate: NOT PASSED.** The root documentation describes an older patient-journey product rather than the current caregiver-first Hani Maak app. A real-looking WhatsApp test recipient remains in public handoff documentation. Source review also identified **public demo API routes with insufficient route-level access checks**; a responsible maintainer must assess and restrict them before further public demonstration or any real-data use.

The PR adds useful interoperability documentation and its latest examined GitHub CI passed, but that does not establish privacy, data provenance, real-user authorization or clinical readiness.

## Findings and evidence

| ID | Severity | Status | Finding | Evidence | Action |
|---|---|---|---|---|---|
| QA-01 | **High** | Confirmed in source | Demo state and reset API route handlers lack explicit authentication/authorization checks before returning or resetting stored demonstration state. **Live exploitability was not tested.** | Demo route handlers and their database helpers | Block production/public exposure, require authenticated/authorized access or disable routes outside a fully isolated demo, add negative tests; review access logs |
| QA-02 | **High** | Confirmed in source | The caregiver application API includes a fixed demo caregiver/care-recipient identifier exception in authorization logic. | Caregiver API authorization path | Ensure no privileged production operation accepts only demo identifiers; isolate demo tenant and validate with negative integration tests |
| QA-03 | **High** | Confirmed | A real-looking WhatsApp test recipient number appears in a public handoff document. | TEAM_HANDOFF.md around line 56 | Replace with a fictional placeholder, inspect related source and Git history, obtain confirmation that the number is synthetic or consented; do not duplicate it in reports |
| QA-04 | **High** | Confirmed in DB metadata | Ten dilemma scenarios marked validated had zero associated clinical-content review records. | Supabase read-only aggregate inspection | Audit actual clinical evidence, then plan and test status/wording corrections; do not automatically change production records |
| QA-05 | **Medium** | Confirmed | README, architecture overview, reviewer guide and runbook focus on legacy patient journey, doctor/admin workflows and hospital navigation. | README.md lines 3–27; docs/architecture/OVERVIEW.md; RUN_ME_FIRST.md | Add a prominent caregiver-first entrypoint and explain older prototype scope; correct product/clinical integration claims |
| QA-06 | **Medium** | Confirmed from metadata | Supabase reported nine tables with RLS enabled but no policies; the access design for direct users versus backend/service-role calls requires verification. | Supabase security advisor | Review effective access and server authorization; RLS with no policy is normally deny-by-default, not proof of exposure |
| QA-07 | **Medium** | Confirmed in source | Demonstration staff and Flutter login credentials are committed as explicit demo shortcuts. | Staff demo-account module, Flutter sign-in | Label as intentionally public demo-only; prevent their use for real authentication; review demo boundaries |
| QA-08 | **Medium** | Unverified | Seed fixtures and stored demonstration data are labeled synthetic but not independently checked field by field. | apps/web/src/lib/seed.ts, stored demo state, Emna preliminary QA | Inventory fixtures and history; verify no personal data, transcripts or contact details from real people |
| QA-09 | **Medium** | Confirmed | Current normalized caregiver data and legacy demo-state JSON coexist; older schema documentation is not authoritative. | Supabase metadata, backend persistence implementation | Document route-to-table ownership and migrations before FHIR mapping |
| QA-10 | **Medium** | Pending | Repo-wide and all-history secret scan not completed. Initial inspected .env examples have empty secret slots; no confirmed credential exposure. | .env.example, .gitignore, selected files, recent path history | Run full offline/history-aware scanning with tools such as gitleaks/trufflehog; rotate any real exposed credential |
| QA-11 | **Medium** | Partially verified | Relative Markdown links checked across key docs and PR plan resolve to existing paths; external navigation and every demo interaction not fully tested. | Structural link verification; safe GET of web, Flutter and agent health | Check remaining external links and logged-in routes in browser |
| QA-12 | **Info** | Verified / limited | Latest examined PR CI passed (typecheck, tests, agent tests and web build via workflow); it does not run Flutter UI end-to-end checks or cover privacy issues. | GitHub Actions run 39416685764, CI workflow | Record check results, add targeted auth/security tests and Flutter integration coverage |
| QA-13 | **Medium** | Pending | Public-facing docs may imply completed safety gates even where only code/schema exists (alerts, summaries, clinical guidance). | TEAM_HANDOFF.md, clinical audit, Supabase use counts | Separate implemented code, enabled runtime, clinically reviewed and integrated-with-hospital statuses |

## CI and link verification

- GitHub Actions CI for PR #60 at 079ef6b completed **successfully** (run 39416685764). Workflow config runs npm install, typecheck, tests, deterministic evaluations, voice checks, Python agent tests, and Next.js build.
- The latest production smoke workflow located for main at 5fe2af237 was successful on 8 October. That check is narrower than a complete caregiver end-to-end or security test.
- The structural relative-link check covered **37 links** across the core main-branch docs and the revised action plan; no missing repository paths were found in the checked set. This does **not** prove all external URLs, anchors and login workflows work.
- Safe read-only GET checks returned HTTP 200 for the main web host, Flutter index and Hani agent health. One alternate web domain redirected.

## Prioritized remediation

1. **Before broader public demo:** restrict or disable unauthenticated demo API paths and fixed demo-identity privileges. Review backend access logs and add unauthorized-user regression tests. No destructive testing was done in this audit.
2. **Before external repository sharing:** remove the test phone number from current tracked content, check history and perform a full secret/personal-data scan.
3. **Before advisor presentation:** make README/current architecture caregiver-first, clearly marking legacy patient journey and demonstrative features.
4. **Before clinical review claims:** reconcile dilemma validation flags with actual human review records and release gates.
5. **Before any real-data or hospital integration:** verify consent/RLS/object ownership/retention, schema source of truth, synthetic-data provenance, and clinical escalation responsibility.

**Guardrail:** Do not treat this report as authorization to reset demonstration state, change the database, modify production settings, or claim a hospital pilot. It is an audit and remediation checklist only.
