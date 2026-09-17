# Database and Persistence

Hani Maak currently supports two persistence modes for different purposes.

## Competition / local demo

The local JSON repository provides a deterministic, zero-provider demo with synthetic data. Writes are serialized within one Node process. This mode is intentionally simple and is not suitable for horizontal scaling or real patient data.

## Supabase / Postgres path

`supabase/schema.sql` contains the production-oriented relational direction, while `supabase/competition-state.sql` supports a simple shared JSON state for the competition deployment.

The competition singleton state is an operational convenience, not the final normalized concurrency architecture.

## Production database requirements

Before storing real patient information, the database layer should include:

- authenticated tenant/user identities;
- database-enforced tenant isolation/RLS where appropriate;
- normalized entities with foreign keys and constraints;
- transactional booking/capacity checks and concurrency protection;
- explicit indexes for common appointment/patient/audit access paths;
- immutable or append-oriented audit semantics for sensitive operations;
- migration/versioning discipline rather than manual schema edits;
- backup, recovery, retention and deletion procedures;
- least-privilege credentials and rotation.

## Secret handling

Use server-only `SUPABASE_SECRET_KEY` (or the documented legacy service-role fallback) for privileged server operations. Never expose a privileged key through a `NEXT_PUBLIC_` variable or commit it to Git.

## Sensitive data

Production schemas should minimize duplication of health information and keep administrative, clinical and platform-management access aligned with the RBAC model. Audit/log tables should contain enough metadata for accountability without copying full sensitive payloads unnecessarily.
