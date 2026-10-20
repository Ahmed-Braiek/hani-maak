# Public Demo Access — PR #61

## Intended result

**Explore Demo** launches a real, anonymous Supabase Auth session. The backend verifies its bearer token, provisions a **separate synthetic caregiver profile and care recipient for that anonymous user**, and attaches an active caregiver relationship. The app then uses the **same authenticated APIs** as regular caregiver accounts for context, Hani chat, voice-token creation, care tasks, medication events, wellbeing, notifications, memory activities, and other implemented workflows.

This is **functional demo data**, not a production patient, not an actual clinical care arrangement, and not an invitation to upload real medical information. The application does not become a clinically validated healthcare product.

## Required deployment settings — not changed by this PR

1. **Supabase Auth → Providers → Anonymous Sign-Ins:** enable *Allow anonymous sign-ins*. Confirm the user project's policy and bot protection/rate limits.
2. **Next.js/Vercel server environment:** set `PUBLIC_SYNTHETIC_DEMO=true` only on the intended demo/preview service. Do not expose Supabase service-role or secret keys to Flutter.
3. **Flutter build:** supply `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` and `HANI_API_BASE` for the matching demo API deployment. **Important:** the currently compiled Flutter web bundle points to the production API until rebuilt with a preview base URL. Merely deploying the Next.js preview does not rebuild the Flutter bundle.
4. **Isolation:** this first version creates a distinct profile/patient *inside the existing database*. For stronger isolation, deploy an independent demo Supabase project and matching Next.js/agent instances before broader public distribution.
5. **Cleanup:** schedule retirement/deletion of old anonymous identities and demo records; it is not automated in PR #61. Define quotas, CAPTCHA/Turnstile, token refresh and resource budgets for anonymous users.

No passwords are required and fixed demo IDs are not credentials.

## Normal authenticated behavior

- Users with real Supabase sessions still resolve their own profile and relationship.
- Anonymous demo sessions resolve unique demo records with a normal Supabase bearer token.
- Server checks each user ID against the requested caregiver profile and active patient relationship before privileged reads/writes.
- The old shared demo JSON-state APIs and historical patient/staff APIs remain denied in hosted builds.
- To prevent unexpected real contact, a demo caller cannot automatically send a WhatsApp summary; this action returns a preview/simulation.
- Clinical claims, AI behavior and integrations retain existing limits. Voice and OCR are no longer replaced by offline scripted demo-only stubs, but may fail if external services/configuration are unavailable.

## Known limitations

- Full deployment **not yet verified**; anonymous Auth must be enabled and Flutter rebuilt against the matching API.
- "Isolated" means unique synthetic caregiver and patient records enforced by application identity/relationship checks, **not** a separate database or verified tenant-wide security audit.
- Multiple visitors can still share globally available reference/catalogue data (e.g. dilemma scenarios). All visitor-owned writes must be scoped to the verified user.
- Some demo tasks cannot create a second Care Circle member without another authorized synthetic profile.
- Public free access can incur Gemini, database and voice processing costs. Quotas/abuse prevention are required before open public rollout.
- Existing photo/OCR controls allow a user to submit user-provided content; display a warning **not to upload real patient data** to the demo.
- Supabase anonymous session persistence/refresh and browser lifecycle need device-level tests.
- Source code does not prove clinical approval, privacy compliance, or end-to-end production readiness.

## Review gate for Ahmed

- [ ] GitHub typecheck/backend tests/build pass on this PR.
- [ ] Flutter analyze and web build pass on this branch with the correct preview API URL.
- [ ] Anonymous sign-in works against an approved test Supabase project.
- [ ] Two different demo visitors get different caregiver/patient IDs and cannot access each other's records.
- [ ] Demo can open dashboard, update tasks, medications, activities, wellbeing, Hani chat, voice and document/OCR flows, where services are configured.
- [ ] Disallowed legacy endpoints return 404 and fixed shared demo IDs without a bearer session return 401.
- [ ] Synthetic outbound WhatsApp actions cannot send to real contacts.
- [ ] Explicit privacy notice, rate limits, expiry and cleanup plan confirmed.
- [ ] Production and `main` remain unchanged until Ahmed's review and merge.

This is an implementation patch pending integration validation, not a security certification.
