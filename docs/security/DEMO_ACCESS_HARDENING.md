# Shared Demo Account — PR #61

## Goal

One email and password, shared by the Hani Maak team with invited reviewers. This account is **a real Supabase Auth user**, not a client-side password shortcut. It accesses the **existing, synthetic Mariem Ben Salah / Fatma Ben Salah caregiver/patient dataset** through the app's normal authenticated APIs (care tasks, medication tracking, Hani text/voice, activity, wellbeing, summaries, and configured OCR).

No usernames, passwords, Supabase secret keys or bearer tokens belong in GitHub, Flutter, or documentation. The account email and password are set **privately in Supabase Auth** and distributed securely by the project team.

## Setup required before preview testing (not performed in PR)

1. In Supabase Auth, create or invite a **dedicated email/password demo user** with email confirmed. Do not use a team member's personal account.
2. Copy **only its UUID user ID** into the server-side Vercel environment variable `DEMO_ACCOUNT_USER_ID`. This is an account identifier, not a password. Set `PUBLIC_SYNTHETIC_DEMO=true` on the intended preview environment, and verify existing server-only Supabase credentials.
3. Build Flutter with the matching demo API base, Supabase URL and **publishable** key. The existing committed Flutter bundle is not automatically rebuilt by the Node CI.
4. Log in normally with the configured email/password. The backend validates the Auth bearer token and approved user UUID, and **links the existing synthetic Mariem profile to that approved Auth user once**; all existing records (Fatma, Sami, tasks, medications, care history) remain intact. Subsequent use preserves edits.
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
- A GitHub PR only proposes the changes. Ahmed will merge later; no production rollout is implied.

## Acceptance checks

- [ ] GitHub CI and Flutter PR build pass.
- [ ] The approved demo account can authenticate via email/password and link to the existing Mariem/Fatma records without modifying them.
- [ ] Unapproved accounts receive 403 from the demo bootstrap endpoint.
- [ ] The approved account is linked to the existing demo-flagged Mariem profile and Fatma patient.
- [ ] It can exercise the app's intended features on a preview deployment.
- [ ] A second regular account cannot access its patient data.
- [ ] No demo password/credential is committed anywhere.
- [ ] Legacy unauthenticated endpoints remain denied.
- [ ] Reviewer acknowledges shared-account behavior and data reset policy.

Until the account is provisioned and these checks pass, **PR #61 is implementation-ready but not an operationally verified demo**.

## Existing scenario and credential handling

- Original public-demo Flutter sign-in was **a hardcoded UI shortcut**, not a Supabase Auth account. Read-only Supabase check found no Auth user with the previously used demo email.
- The existing demo caregiver is **Mariem Ben Salah** with a primary active relationship to **Fatma Ben Salah**. The scenario also includes Sami and synthetic caregiver history.
- Create a real Supabase Auth account using the desired demo email in the Supabase dashboard, **set a new password privately**, confirm its email, and configure the account's Auth UUID as `DEMO_ACCOUNT_USER_ID` in the Vercel Preview environment.
- The previous password was shared in chat and embedded in historical public Flutter source. **Do not reuse that password for the new Auth account; rotate it to a new one before sharing the login.** Never add it to GitHub, logs or Vercel environment variables.
- Set `PUBLIC_SYNTHETIC_DEMO=true` in the same Vercel Preview environment. The bootstrap refuses everyone except that allowlisted authenticated user.
- Bootstrap performs a one-time `auth_user_id` link only if the Mariem demo profile is unlinked, verifies the existing Fatma patient and active relationship, and refuses to override a different owner. The link happens **only when explicitly enabled on the preview**, not from opening the PR.
- The same shared account means all invited reviewers can modify the same synthetic demo history. Arrange a reset procedure for presentations; do not let public testers enter real medical data.
- No Auth account creation, Vercel variable changes, or production database writes were carried out as part of this code PR.
