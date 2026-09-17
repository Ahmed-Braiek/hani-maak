# Contributing to Hani Maak

Thank you for helping improve Hani Maak. This repository contains a healthcare-adjacent product prototype, so changes should optimize for correctness, safety, clarity and maintainability rather than novelty.

## Local setup

```bash
git clone https://github.com/Ahmed-Braiek/hani-maak.git
cd hani-maak
cp .env.example .env.local
npm install
npm run demo:reset
npm run dev
```

Use Node.js 20.9+ and npm 10+.

## Branches

Create a short-lived branch from current `main`. Use descriptive names such as:

- `feature/heni-language-switching`
- `fix/staff-permission-guard`
- `docs/security-boundaries`

Avoid large unrelated changes in one pull request.

## Engineering expectations

- Preserve the deterministic application core for appointments, permissions, routes and journey state.
- Do not move clinical responsibility into Heni or another model.
- Keep secrets server-side and never commit credentials.
- Do not commit real patient information or private training data.
- Enforce permissions on the server/API boundary, not only in the UI.
- Reuse the existing localization system rather than adding duplicate language pages.
- Prefer small, typed modules over giant new utility files.
- Update documentation when behavior, configuration or architecture changes.

## Before opening a pull request

Run:

```bash
npm run typecheck
npm test
npm run evals
npm run voice:check
npm run build
```

`npm run verify` runs the full sequence.

If a check cannot be run because it requires an external provider, state that explicitly in the PR instead of implying it passed.

## AI/Heni changes

Changes to prompts, providers, tools, safety boundaries, language behavior or fine-tuned model selection must include deterministic evaluation/test coverage where practical. Do not add examples containing real patient data.

Model output must not become the source of truth for appointment availability, authorization, routing, clinical instructions or successful mutations.

## Pull requests

Use the repository PR template. Explain:

- what changed and why;
- affected user roles/modules;
- tests performed;
- security/privacy implications;
- migration or environment-variable changes;
- changes to Heni behavior;
- known limitations.

## Issues

Use the structured GitHub issue forms. Heni-specific failures have a dedicated form for language, safety, hallucination, transcription/TTS and latency issues.

Do not put confidential patient information, credentials or vulnerability exploit details into issues.

## Security reports

Follow [`SECURITY.md`](SECURITY.md). Security vulnerabilities must be reported privately rather than as public issues.
