# Security Policy

Hani Maak is a health-tech prototype and is designed with security-sensitive boundaries even though the competition build uses synthetic data.

## Supported code

Security fixes are applied to the active `main` branch. Historical snapshots and competition artifacts should not be assumed to receive security updates.

## Reporting a vulnerability

**Do not open a public GitHub issue for a suspected vulnerability.**

Report security issues privately to the repository owner/maintainer through a private GitHub communication channel or another private contact channel agreed with the project team. If a private channel is not available to you, contact the maintainer first without including exploit details and request a secure reporting route.

Include, where possible:

- affected component and commit/version;
- impact and realistic attack scenario;
- minimal reproduction steps;
- required privileges or user role;
- whether sensitive data, authentication, authorization, AI, voice or file upload is involved;
- suggested remediation if known.

Never include real patient data, passwords, API keys, database secrets, access tokens or other credentials in the report.

## Handling process

The maintainer should acknowledge the report, reproduce/triage it privately, determine affected versions, prepare a fix and validation test, and only disclose technical details publicly when doing so no longer creates unnecessary risk.

## Security boundaries that matter most

Priority areas include authentication/session handling, RBAC and IDOR prevention, server-side authorization, Supabase/database policies, secret management, AI prompt/tool boundaries, explicit confirmation for state changes, telephony/webhook verification, upload validation, sensitive logging, rate limiting and audit integrity.

## Health and AI safety

Heni is an administrative/patient-journey assistant, not a clinician. A security or prompt-injection issue must not be allowed to make Heni diagnose, prescribe, change doses, override role permissions, invent appointment truth or bypass deterministic application tools.

## Compliance statement

The repository does not claim HIPAA, GDPR, ISO 27001 or other formal certification/compliance status. Production use with real patient information requires the relevant legal, contractual, organizational and technical controls to be established and independently validated for the deployment context.
