# Testing Strategy

Hani Maak prioritizes deterministic tests for workflow truth and safety boundaries, then adds provider/live tests where external systems are required.

## Current automated checks

### Domain tests

`tests/domain.test.ts` covers scheduling/capacity, deterministic routing and core voice intent/safety behavior.

### Heni safety tests

`tests/heni-safety.test.ts` verifies clinical-boundary behavior across supported language styles, credential-request refusal and allowed administrative scenarios.

### RBAC tests

`tests/rbac.test.ts` verifies the intentional separation between Doctor clinical access, Administration operations and Super Admin platform access.

### Deterministic Heni evaluations

`evals/voice-scenarios.json` is the synthetic intent/safety evaluation set. `npm run evals` measures the deterministic classifier/boundary behavior. These results are engineering checks, not clinical-outcome or live speech-recognition accuracy claims.

## Repository verification

```bash
npm run verify
```

runs type checking, tests, deterministic evaluations, voice-bridge syntax validation and the production web build.

## Next production-focused test layers

1. **API integration:** authorization, validation, error contracts, idempotency and write confirmation.
2. **Database integration:** tenant isolation, transactions, RLS/policies, concurrent booking capacity.
3. **E2E:** patient booking -> preparation -> navigation -> visit completion -> follow-up; staff role restrictions; mobile responsiveness.
4. **Security:** IDOR, CSRF, rate limits, upload validation, secret leakage, prompt/tool injection.
5. **AI:** held-out multilingual/fine-tuned model evaluation, hallucination, tool-use and refusal regression.
6. **Voice:** real speech latency, interruptions, STT/TTS errors and provider outage behavior.

## Test data

Automated tests and examples must use synthetic data. Real patient information must not be committed as fixtures or model-evaluation examples.
