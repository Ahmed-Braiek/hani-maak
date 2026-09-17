# Security Architecture

Hani Maak is a healthcare-adjacent platform. The competition build uses synthetic patient data, but the architecture treats authorization, AI actions and sensitive-data boundaries as first-class concerns.

## Security objectives

1. A user sees and changes only the data permitted by their role and scope.
2. Heni cannot bypass application authorization or turn model output into database truth.
3. Secrets remain server-side.
4. State-changing AI/voice actions require explicit confirmation and backend validation.
5. Sensitive information is not unnecessarily logged, published or placed in training data.
6. Security failures degrade safely rather than silently expanding privileges.

## Access control

The current permission map distinguishes Doctor, Administration and Super Admin capabilities. Protected staff routes/API operations use server-side guards. Administration is intentionally denied full clinical access; Super Admin manages platform configuration without receiving clinical access by default.

The role cookie in competition mode is a **demo identity shortcut**, not production authentication. Production must replace this with authenticated identities, secure session handling and database/tenant enforcement.

## Data boundary

The competition store contains synthetic patients. Production deployment should use transactional database persistence, tenant-aware access controls, least-privilege service credentials, backups/retention controls and encrypted transport. Database-level policies should complement application checks rather than relying on UI visibility.

## AI security

Heni uses deterministic pre-model safety checks plus system instructions and an allowlisted action layer. The model must not:

- authorize itself;
- invent patient/appointment state;
- call arbitrary infrastructure;
- receive credentials it does not need;
- decide clinical questions;
- make writes without explicit confirmation.

Prompt/tool injection should be tested as an authorization problem, not only as a wording problem. Provider/tool outputs should be treated as untrusted input and validated before use.

## Voice security

Trusted bridge-to-web requests can use a server-only shared secret. Production telephony must additionally validate the selected provider's webhook/media-stream authenticity and protect public streaming endpoints from replay/abuse.

## Web/API risks to validate before production

- authentication and session fixation/expiry;
- IDOR/object ownership on patient and appointment resources;
- CSRF for cookie-authenticated writes;
- XSS and unsafe rendering of AI/provider content;
- request/schema validation and injection resistance;
- file/image upload MIME, size and content validation;
- rate limiting for authentication, AI, booking and public endpoints;
- safe CORS/security headers;
- database/RLS tenant isolation;
- audit-log integrity and redaction;
- secret rotation and least-privilege keys.

## Logging and observability

Log action metadata needed for debugging/security, not full medical payloads by default. AI latency/provider errors, tool failures, permission denials and security events should be observable without exposing unnecessary patient content.

## Compliance

No formal compliance/certification status is claimed. If deployed with real patient data, the organization must establish the applicable legal basis, contracts, consent/notice, data-subject processes, retention/deletion, security governance and independent assurance required by the target jurisdiction/provider.
