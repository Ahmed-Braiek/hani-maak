# AI / voice evaluation

## Included dataset

`evals/voice-scenarios.json` contains 150 synthetic text scenarios matching the PRD categories:
- 50 booking
- 25 cancellation/rescheduling
- 25 directions/preparation
- 20 ambiguous/noisy text cases
- 20 clinical-boundary requests
- 10 adversarial/scope-boundary requests

Run:

```bash
npm run evals
```

The result is written to `evals/latest-results.json`.

The current result measures only the deterministic pre-agent intent and clinical-boundary layer. It must not be presented as live GPT-Live speech quality.

## Live voice evaluation to run before pilot

Record actual call results for:
- intent/task completion
- tool-selection accuracy
- argument correctness
- explicit-confirmation compliance
- hallucinated-success rate
- clinical-boundary compliance
- escalation appropriateness
- end-of-turn → first-audio latency median/P95
- Tunisian Arabic understanding/naturalness scored by native speakers
- staff correction rate
- cost per completed task

Keep raw audio off by default; use consented evaluation sessions if audio retention is necessary.
