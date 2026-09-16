# Hani Maak architecture

## Principle: deterministic core, probabilistic interface

The mobile UI, staff console and voice front all operate on the same domain state. AI can interpret language and request a tool, but it does not own appointment availability, route calculation, authorization or journey state.

```text
Patient PWA ───────────────────┐
                              ├── Next.js /api/v1 ── Domain services ── Repository
Staff console ─────────────────┤                          │                ├ JSON demo store
                              │                          │                └ Supabase/Postgres path
Browser Voice Lab ─────────────┤                          ├ Scheduling rules + capacity
                              │                          ├ Journey engine
PSTN → Twilio → GPT-Live bridge┘                          ├ Facility graph + Dijkstra
                                                         ├ Notifications
                                                         └ Audit/product events
```

## Why this split

1. **Scheduling is deterministic.** Availability is generated from weekly rules, exceptions, slot duration and current confirmed/requested capacity. Final booking revalidates the chosen slot.
2. **Navigation is deterministic.** The route engine uses facility nodes/edges and shortest-path calculation. LLMs never generate coordinates or decide the route.
3. **Clinical responsibility remains human/provider-authored.** The agent can retrieve published provider content but cannot create treatment advice.
4. **Channel parity.** Mobile and voice call the same application logic, avoiding a separate “AI database”.
5. **Provider adapters remain replaceable.** The competition JSON repository can become Supabase/Postgres; Twilio can be replaced by another CPaaS; a map provider can be switched without changing journeys.

## Repository map

- `apps/web` — Next.js App Router patient application, staff operations console, API and competition Voice Lab.
- `apps/voice-bridge` — optional Twilio Media Streams ↔ OpenAI GPT-Live WebSocket bridge.
- `apps/web/src/lib/scheduling.ts` — slot generation/capacity rules.
- `apps/web/src/lib/routing.ts` — shortest-path facility graph.
- `apps/web/src/lib/voice.ts` — deterministic intent/safety helpers used by competition fallback.
- `apps/web/src/lib/operations.ts` — domain mutations and audit/product events.
- `apps/web/src/lib/notifications.ts` — notification provider adapters.
- `apps/web/src/lib/vision.ts` — optional bounded multimodal package-text extraction.
- `supabase/schema.sql` — production-oriented relational schema and initial RLS policies.
- `evals` — 150-case synthetic voice/safety dataset and measured deterministic pre-agent results.

## Demo data boundary

The competition repository uses synthetic patients and schedules. Facility indoor/campus nodes are manually authored and `demo_seeded`. The UI explicitly labels them as an unvalidated prototype route.

## Server tool boundary

The browser Voice Lab follows a constrained state machine. The live GPT-Live bridge exposes only an allowlist of administrative functions. State-changing API endpoints reject voice mutations if `explicitConfirmation !== true`.

Production hardening should add a server-issued confirmation token tied to call/session/action content so a model cannot self-assert confirmation.

## Failure isolation

- Voice unavailable → patient/staff scheduling still works.
- External vision unavailable → deterministic seeded vision fallback remains demonstrable.
- SMS/email unavailable → in-app + simulated delivery state remains demonstrable.
- OSM network unavailable → local indoor graph and text route steps remain available.
- External database unavailable → local competition JSON store works for stage/demo use.

## Demo-store concurrency note

The JSON repository serializes writes inside one Node process. It is appropriate for a single-machine competition demo, not multi-instance deployment. Production uses Postgres transactions/locking and provider authentication.
