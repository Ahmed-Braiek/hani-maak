# ADR 003 - Least-Privilege RBAC for Sensitive Data

**Status:** Accepted for the prototype architecture

## Context

Doctor, Administration and Super Admin responsibilities overlap operationally but should not imply the same access to clinical information.

## Decision

Use explicit capability checks on protected server operations. Doctor receives required clinical capabilities; Administration receives operational capabilities without full medical access; Super Admin receives platform-management capabilities without clinical access by default.

## Consequences

- UI navigation can reflect permissions but cannot replace server authorization.
- Production identity must bind users to tenant/provider membership and object scope.
- Database policies should complement application guards before real patient information is used.
