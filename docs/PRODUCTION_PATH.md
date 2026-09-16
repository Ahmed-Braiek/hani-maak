# From competition build to provider pilot

## What can remain

- Next.js patient/staff information architecture.
- Typed `/api/v1` contracts.
- Scheduling/journey/route domain concepts.
- Voice tool allowlist and explicit confirmation behavior.
- Content-template boundary for provider-approved instructions.
- GeoJSON/facility graph route API.
- White-label tenant model.
- Audit/product event concepts.

## What must change before real patient use

1. Replace JSON datastore with Postgres/Supabase and transactional capacity enforcement.
2. Implement real patient/staff authentication, authorization and recovery flows.
3. Apply and test RLS plus server-side role checks; conduct IDOR/cross-tenant security testing.
4. Validate service directory, schedules, appointment rules and all facility geometry with the provider.
5. Define identity matching and caller verification for phone actions.
6. Perform Tunisian privacy/data-governance legal review: health data, consent/legal basis, transfers/hosting, retention, access rights, processors and breach processes.
7. Contract/approve telephony and messaging providers for Tunisia.
8. Validate Tunisian Arabic voice quality with native speakers, older adults and noisy calls.
9. Add production monitoring, backups, rate limiting, webhook verification, secret management and incident response.
10. Define a clinical governance workflow for publishing/reviewing patient instructions.
11. Validate accessibility with assistive technology and representative users.
12. Measure operational outcomes in a pilot instead of using hackathon assumptions.

## Incremental evolution

The application should not be rewritten. Replace adapters in this order:

`JsonRepository → PostgresRepository`

`DemoNotificationProvider → SMS/Email/Voice providers`

`Demo facility graph → provider-validated graph + optional QR/BLE positioning`

`Internal scheduling → provider scheduling/HIS/FHIR adapter where supported`

`Browser Voice Lab → live PSTN bridge`

This keeps user journeys and domain contracts stable while infrastructure becomes production-grade.
