# ADR 001 - Deterministic Core, Probabilistic Interface

**Status:** Accepted

## Context

Hani Maak uses AI for natural-language access but manages safety-sensitive workflow state such as appointments, permissions and routes.

## Decision

Keep workflow truth in deterministic application/domain services. AI may interpret requests and request allowlisted tools, but cannot directly own availability, authorization, route calculation or journey state.

## Consequences

- AI/provider outages do not invalidate the core product.
- Actions can be audited and tested independently from model output.
- More explicit tool/context plumbing is required, but hallucinations cannot become workflow truth merely because the model said so.
