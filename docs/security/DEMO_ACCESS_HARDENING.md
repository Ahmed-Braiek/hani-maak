# Demo and legacy API access after hardening

**Security branch:** `security/harden-demo-access`

## Deployment contract

- In deployed Next.js builds (`NODE_ENV=production`), **all competition-era `/api/v1/demo`, patient journey, staff, voice-bridge and similar endpoints are disabled** at the edge via `src/proxy.ts`. They must not return or mutate the shared Supabase demo-state singleton.
- Hardcoded demo caregiver/patient UUIDs are **not credentials**. Caregiver-first APIs refuse them in deployed builds. Other caregiver IDs require a valid Supabase Bearer token and an active caregiver-patient relationship.
- Real authenticated caregiver access remains through existing Supabase authorization and relationship checks. Hani agent-to-backend tools remain protected by the shared server-side agent key.
- In **local development only**, opt into legacy demo flows with `DEMO_MODE=true` while using local fixture data. This is not a secure production identity scheme.
- `DEMO_MODE=true` in a Vercel production/preview build does **not** override the production restrictions.
- Existing public Flutter demo login is a **UI shortcut**; it does not establish a server session. A public user may still view locally bundled demonstration content, but calls requiring caregiver API identity can now fail with 401 until a proper limited demo-account design is implemented.

## Follow-up before enabling hosted demos

1. Establish a separate, time-limited, authenticated **demo account** (Supabase Auth or scoped demo sessions), with an isolated demo tenant and zero real patient data.
2. Scope **every** demo read/write to that demo tenant; do not use fixed IDs as a privilege bypass.
3. Explicitly whitelist safe demo operations (and disable reset/mass export for public users).
4. Require CSRF protection or CSRF-resistant bearer-only access for state-changing operations. Enforce CORS allowlists, rate limits and audit logging.
5. Test cross-user, cross-care-recipient and unauthenticated requests end to end; confirm documented behavior in preview before merge.
6. Review the legacy telephony webhook contract independently before any production telephony exposure.

This change is a **fail-closed containment patch**, not a complete production authentication migration. It intentionally prioritizes preventing access to shared state over preserving the public demo backend experience.
