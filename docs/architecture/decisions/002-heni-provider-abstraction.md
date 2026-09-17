# ADR 002 - Heni Provider Abstraction

**Status:** Accepted

## Context

Heni needs to support a deterministic competition mode, general hosted models, a future fine-tuned model and potentially different speech providers without forcing product UI rewrites.

## Decision

Centralize Heni configuration, system behavior, safety and orchestration behind application-owned modules. Select model IDs through server-side environment configuration. Keep provider-specific HTTP/realtime code in adapters.

## Consequences

- `HENI_FINE_TUNED_MODEL_ID` can promote a validated specialized model without changing patient components.
- Provider credentials remain server-side.
- Vendor-specific capabilities may still require adapter changes, but the product/domain contract remains stable.
- Fine-tuned-model readiness is not represented as evidence that a fine-tuned model has already been trained.
