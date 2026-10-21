# Shared Demo Account — PR #61 (Merged)

## Goal

One email and password, shared by the Hani Maak team with invited reviewers. This account is **a real Supabase Auth user**, not a client-side password shortcut. It accesses the **existing, synthetic Mariem Ben Salah / Fatma Ben Salah caregiver/patient dataset** through the app's normal authenticated APIs (care tasks, medication tracking, Hani text/voice, activity, wellbeing, summaries, and configured OCR).

No usernames, passwords, Supabase secret keys or bearer tokens belong in GitHub, Flutter, or documentation. The account email and password are set **privately in Supabase Auth** and distributed securely by the project team.

**Status update (21 October 2026):** [PR #61](https://github.com/Ahmed-Braiek/hani-maak/pull/61) has been merged. The dedicated synthetic Supabase Auth account was subsequently provisioned and linked to the existing Mariem/Fatma scenario. The project coordinator confirmed browser login and the correct dashboard; this does **not** validate all feature paths or cross-user isolation.

## Setup and validation record

1. **Completed:** A dedicated email-confirmed Supabase Auth demo user was created separately from PR #61. Reuse this account; do not create a replacement or use a team member's personal account.
2. **Reported configured:** The approved UUID is allowlisted server-side via `DEMO_ACCOUNT_USER_ID`, with `PUBLIC_SYNTHETIC_DEMO=true` for the intended deployment. Recheck live settings during production validation. Neither value is an account password.
3. Build or rebuild Flutter with the matching demo API base, Supabase URL and **publishable** key after changes. The hosted Flutter bundle was built following integration, but a successful build alone is not an E2E test.
4. **Browser-verified:** The configured account successfully logged in and opened the Mariem/Fatma dashboard. The approved Auth UUID is linked to the existing synthetic Mariem profile; backend access enforcement and additional feature behavior still need negative and E2E testing.
5. Keep existing legacy demo-state and unauthenticated patient/staff routes disabled. The fixed historical UUIDs never authorize any request.
6. Verify dashboard, medication actions, tasks, memory activities, Hani chat/voice, OCR and profile data using preview only. External WhatsApp delivery is intentionally simulated for the synthetic account.
7. Plan periodic demo reset and credential rotation before distributing to new external reviewers.

## Important boundaries

- All people, clinician labels, medication instructions and events in the seeded account are fictional and not clinically verified.
- **Everyone using the same credentials shares the same workspace and can see changes made by other invited testers.** It is not private per reviewer.
- The demo is isolated by dedicated authenticated caregiver/patient IDs and server access checks **within the existing Supabase database**. It is not physically separated in a different database; that requires an independent Supabase project.
- Password authentication and seeded data do not prove full production security, healthcare compliance, validated clinical advice or working hospital exchange.
- Voice/AI features may incur usage fees; do not share the credentials publicly without usage limits.
- Do not enter genuine medical data or use real WhatsApp numbers in the demo.
- The provisioning endpoint is opt-in and refuses any user other than the configured demo Auth UID.
- [PR #61](https://github.com/Ahmed-Braiek/hani-maak/pull/61) is merged, but a merge and successful browser login do not establish full production security, feature reliability or clinical readiness.

## Acceptance checks

- [x] GitHub combined CI and post-merge Flutter web build passed at the recorded 21 October integration milestone; recheck subsequent commits independently.
- [x] The approved demo account authenticated through browser login and linked to the existing synthetic Mariem/Fatma scenario without replacing those records (coordinator confirmation).
- [ ] Unapproved accounts receive 403 from the demo bootstrap endpoint.
- [x] The approved account is linked to the synthetic Mariem profile and Fatma patient (integration handoff and browser confirmation).
- [ ] It can exercise the app's intended features on a preview deployment.
- [ ] A second regular account cannot access its patient data.
- [ ] No demo password/credential is committed anywhere.
- [ ] Legacy unauthenticated endpoints remain denied.
- [ ] Reviewer acknowledges shared-account behavior and data reset policy.

The dedicated account is **provisioned and browser login/dashboard verified**, but the unchecked acceptance tests above still require independent execution. This is not a fully verified demo/security release.

## Phase 3 security review findings (21 October 2026)

- The caregiver-app API now observes medication-view, task-management and shared-incident relationship flags. Medication/document edits are conservatively limited to the primary caregiver where the schema lacks specific write grants. This policy requires real multi-user permission integration tests before release.
- The Hani backend tool that previously generated professional-contact consent and a handoff in `approved` state from agent arguments is **temporarily blocked**, returning `explicit_caregiver_approval_required`. A separate authenticated human approval workflow and clinician-verification evidence are required before reopening it.
- The authenticated demo client now fails on caregiver-context API errors rather than displaying canned offline records, and the old WhatsApp test-number text is removed from the summary UI.
- **At the original PR review, not tested end to end:** Supabase Auth provisioning, shared login, feature paths, revocation and cross-patient access. The account, login/dashboard and post-merge Flutter bundle were subsequently confirmed; complete feature and negative authorization testing remain outstanding.
- **Historical exposure remains:** prior hardcoded demo credentials exist in Git history. PR #61 has since merged; it does not erase historical commits or substitute for a history-wide privacy/secret audit. Treat exposed historical credentials as public.
- The unused fixture generator/test file describes an older per-user Amina demo variant and is not invoked by the current Mariem/Fatma bootstrap; do not assume that test exercises the actual bootstrap path.

## Existing scenario and credential handling

- Original public-demo Flutter sign-in was **a hardcoded UI shortcut**, not a Supabase Auth account. Read-only Supabase check found no Auth user with the previously used demo email.
- The existing demo caregiver is **Mariem Ben Salah** with a primary active relationship to **Fatma Ben Salah**. The scenario also includes Sami and synthetic caregiver history.
- **Completed separately from the PR:** a confirmed synthetic Supabase Auth account was created and its approved UUID configured for hosted demo use; do not recreate or overwrite the linked account solely to fix automated tests.
- A previous hardcoded password appeared in historical public Flutter source. Treat historically exposed passwords as compromised; never add current login credentials to GitHub files, logs or Vercel environment variables.
- `PUBLIC_SYNTHETIC_DEMO=true` is reported configured for the approved demo deployment. Recheck current deployment configuration and verify that bootstrap rejects every user other than the allowlisted authenticated identity.
- Bootstrap performs a one-time `auth_user_id` link only if the Mariem demo profile is unlinked, verifies the existing Fatma patient and active relationship, and refuses to override a different owner. The link happens **only when explicitly enabled on the preview**, not from opening the PR.
- The same shared account means all invited reviewers can modify the same synthetic demo history. Arrange a reset procedure for presentations; do not let public testers enter real medical data.
- The Auth-account and deployment configuration work occurred separately after the original code PR; merging PR #61 alone did not carry out those operational steps.
