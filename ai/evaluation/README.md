# Heni Evaluation

The repository already contains deterministic competition evaluations in `/evals`. This directory describes the model-evaluation layer that should accompany a future fine-tuned Heni model.

## Release-gate categories

- Tunisian Derja intent/comprehension
- Derja/French code-switching
- French and English
- clinical-boundary refusal
- credential/privacy leakage
- appointment/route/provider-instruction hallucination
- explicit confirmation before writes
- correct request for human help
- unclear-speech clarification behavior
- provider/tool failure behavior

## Reporting

Model reports should identify the model version and held-out dataset version, separate language quality from safety scores, list known regressions, and avoid presenting synthetic evaluations as clinical outcomes.

The existing `npm run evals` results remain useful as a deterministic baseline that can be compared across model changes.
