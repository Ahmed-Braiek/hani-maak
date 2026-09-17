# AI Workspace

This directory contains **non-sensitive** model-training/evaluation documentation and synthetic examples for Heni.

Runtime Heni code lives with the application under `apps/web/src/lib/heni/` and `apps/voice-bridge/src/heni/`. The separation is intentional: application runtime code is deployable product code; this directory is the model-development/governance workspace.

## Rules

- Never commit real patient/medical data, raw call recordings, credentials or private provider data here.
- Synthetic examples must be clearly synthetic.
- Fine-tuning is not considered complete until an actual model artifact is trained, versioned and passes the documented held-out safety/language evaluations.
- Dynamic healthcare operational truth must come from application tools, not be memorized into a model.

See [`training/README.md`](training/README.md) and [`../docs/ai/FINE_TUNING.md`](../docs/ai/FINE_TUNING.md).
