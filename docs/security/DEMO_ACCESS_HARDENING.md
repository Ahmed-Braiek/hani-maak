# Shared Demo Account — PR #61

## Goal

One email and password, shared by the Hani Maak team with invited reviewers. This account is **a real Supabase Auth user**, not a client-side password shortcut. It accesses an **entirely synthetic caregiver/patient dataset** through the app's normal authenticated APIs (care tasks, medication tracking, Hani text/voice, activity, wellbeing, summaries, and configured OCR).

No usernames, passwords, Supabase secret keys or bearer tokens belong in GitHub, Flutter, or documentation. The account email and password are set **privately in Supabase Auth** and distributed securely by the project team.

## Setup required before preview testing (not performed in PR)

1. In Supabase Auth, create or invite a **dedicated email/password demo user** with email confirmed. Do not use a team member's personal account.
2. Copy **only its UUID user ID** into the server-side Vercel environment variable `DEMO_ACCOUNT_USER_ID`. This is an account identifier, not a password. Set `PUBLIC_SYNTHETIC_DEMO=true` on the intended preview environment, and verify existing server-only Supabase credentials.
3. Build Flutter with the matching demo API base, Supabase URL and **publishable** key. The existing committed Flutter bundle is not automatically rebuilt by the Node CI.
4. Log in normally with the configured email/password. The backend validates the Auth bearer token and approved user UUID, and creates a synthetic caregiver/patient dataset if absent. Subsequent use preserves edits.
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
- [ ] The approved demo account can authenticate via email/password and bootstrap.
- [ ] Unapproved accounts receive 403 from the demo bootstrap endpoint.
- [ ] The shared account has its own demo-flagged profile and patient.
- [ ] It can exercise the app's intended features on a preview deployment.
- [ ] A second regular account cannot access its patient data.
- [ ] No demo password/credential is committed anywhere.
- [ ] Legacy unauthenticated endpoints remain denied.
- [ ] Reviewer acknowledges shared-account behavior and data reset policy.

Until the account is provisioned and these checks pass, **PR #61 is implementation-ready but not an operationally verified demo**.
