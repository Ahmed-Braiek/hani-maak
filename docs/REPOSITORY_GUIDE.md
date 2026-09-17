# Repository Reading Guide

This is the fastest path through Hani Maak for a technical reviewer.

## 1. Understand the product

Read the root [`README.md`](../README.md). Hani Maak is an appointment-to-completion patient-journey layer: **Access -> Guidance -> Continuity**.

## 2. Run the product

```bash
cp .env.example .env.local
npm install
npm run demo:reset
npm run dev
```

Open `http://localhost:3000`.

Recommended routes:

1. `/patient` - patient experience.
2. `/patient/services` - booking flow.
3. `/patient/journey` - preparation through follow-up.
4. `/patient/map` and `/patient/map/ar?demo=nuclear-medicine` - navigation/AR demo.
5. `/staff` - role-oriented staff console.
6. `/voice-lab` - deterministic browser voice fallback.
7. `/present` - presentation sequence.

## 3. Read the architecture

- `apps/web/src/lib/operations.ts` - existing domain mutations, journey and audit behavior.
- `apps/web/src/lib/scheduling.ts` - deterministic slot/capacity calculation.
- `apps/web/src/lib/routing.ts` - deterministic facility path calculation.
- `apps/web/src/lib/access.ts` + `staff-auth.ts` - permissions and server-side staff guards.
- `apps/web/src/lib/heni/` - Heni prompt/safety/provider/orchestration boundary.
- `apps/voice-bridge/` - optional realtime/PSTN voice adapter.
- `supabase/` - database-oriented production path and competition persistence adapter.

## 4. Understand the AI boundary

Heni may interpret language and request approved administrative actions, but appointment availability, authorization, routing and workflow state remain deterministic application responsibilities. Clinical decisions remain human responsibilities.

The competition fallback does not depend on an external model. A server-side model can be enabled for safe conversational turns, and a validated fine-tuned model can later be selected through configuration without rewriting the UI.

## 5. Review security and tests

Read:

- [`security/SECURITY_ARCHITECTURE.md`](security/SECURITY_ARCHITECTURE.md)
- [`roles-and-permissions/RBAC.md`](roles-and-permissions/RBAC.md)
- [`testing/TESTING_STRATEGY.md`](testing/TESTING_STRATEGY.md)
- [`KNOWN_LIMITATIONS.md`](KNOWN_LIMITATIONS.md)

Then run:

```bash
npm run verify
```

## What is deliberately a prototype

The zero-setup demo uses synthetic patients and may use a local JSON store. Demo staff identity switching is not production authentication. Indoor route geometry is not a validated hospital floor plan. Live provider speech must be validated against the selected provider contract before production use. No compliance certification is claimed.
