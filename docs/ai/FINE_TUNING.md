# Heni Fine-Tuning Preparation

Hani Maak is structured so a specialized model can be introduced without coupling patient/staff UI code to a single vendor. This document defines what must be true before the project can claim that a fine-tuned Heni model is in use.

## Goal

Fine-tuning should improve Heni's conversational behavior: Tunisian Derja, Derja/French code-switching, concise administrative dialogue, intent recognition, safe refusal language, clarification style and consistent tool-oriented behavior.

It should **not** be used to memorize patient records, appointment availability, hospital operational state, credentials or mutable provider instructions.

## Data governance

- Never commit private medical datasets or real patient conversations to this repository.
- Use synthetic examples in Git and keep approved private datasets in controlled storage outside the public/source repository.
- Remove direct and indirect identifiers before model-training workflows.
- Document lawful/authorized source, consent/usage basis, retention and access controls for every private dataset used.
- Version datasets by a non-sensitive manifest/hash and record which model run used which version.

## Recommended training record shape

Each example should distinguish user input, desired assistant response, language/style metadata, safety category and whether a backend/tool action is expected. See `ai/training/schemas/heni-training-example.schema.json`.

## Required evaluation dimensions

Before promoting a fine-tuned model, evaluate it on held-out data for:

1. Tunisian Derja comprehension and response quality.
2. Derja/French code-switching.
3. French and English.
4. administrative intent/tool selection.
5. explicit-confirmation behavior before state changes.
6. clinical-boundary refusal and human escalation.
7. privacy leakage / credential requests.
8. hallucination of appointments, routes or provider instructions.
9. robustness to unclear, impatient and interrupted conversations.
10. regression against prior approved model versions.

## Promotion gate

A model should not become the configured `HENI_FINE_TUNED_MODEL_ID` merely because average language quality is better. Safety-critical regressions, permission bypass, invented tool results or worse confirmation behavior block promotion.

Record at minimum: model/provider ID, base model, training dataset version, evaluation dataset version, measured results, known failure categories, date and approver.

## Repository boundary

Only schemas, synthetic examples, evaluation scripts/results and non-sensitive experiment metadata belong in this repo. Private training files belong in access-controlled storage and are ignored by Git according to `.gitignore`.
