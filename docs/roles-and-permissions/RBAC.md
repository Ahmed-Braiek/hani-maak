# Roles and Permissions

Hani Maak uses explicit capabilities rather than treating a role label as a UI-only decoration.

## Patient

Patients use the patient journey and do not enter the staff RBAC console. Patient data access must eventually be scoped to the authenticated patient/caregiver relationship in production.

## Doctor

Doctors require the clinical context needed for care. Current capabilities include general/medical patient viewing, medical edits, appointments, clinical notes, medical documents, service viewing and schedule viewing.

## Administration

Administration handles patient operations without full clinical access. Current capabilities include general patient information, appointment create/edit/cancel, services/schedules management, notifications and analytics. Clinical notes and full medical data are intentionally excluded.

## Super Admin

Super Admin manages the platform: accounts, roles, permissions, AI/platform configuration, maps, translations, white label, integrations, notifications, analytics, audit and system settings. Super Admin does **not** automatically receive clinical patient access merely because the role is powerful operationally.

## Enforcement

`apps/web/src/lib/access.ts` defines capabilities and default role grants. `apps/web/src/lib/staff-auth.ts` resolves the current competition staff identity and provides `requirePermission` / `requireRole` server guards.

Protected server operations should call permission guards. Hiding a navigation item is not authorization.

## Production identity gap

Competition role switching uses a secure-ish HTTP-only role cookie as a demo shortcut. It is not real authentication. Before real patient/clinical data is used, replace the demo identity mechanism with production authentication, bind identities to provider/tenant memberships, enforce tenant/object scope and add database-level policies where appropriate.

## Testing expectations

High-risk tests should prove that:

- Administration cannot read/write clinical notes;
- Super Admin cannot read medical records by default;
- Doctor clinical actions require doctor permissions;
- role switching cannot become a production authorization bypass;
- object ownership/tenant boundaries are checked as well as capability names.
