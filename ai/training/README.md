# Heni Training Workspace

This directory defines how future Heni fine-tuning work should be organized without putting private health data into Git.

```text
training/
├── datasets/     # synthetic examples + private/raw ignore rules
├── schemas/      # versioned example schemas
└── README.md
```

## Workflow

1. Define the behavior being improved and an evaluation that can detect improvement/regression.
2. Prepare authorized data outside Git; anonymize/redact before any training use.
3. Convert records into the versioned schema.
4. Keep a non-sensitive dataset manifest/version identifier.
5. Split train/validation/held-out evaluation sets before optimization.
6. Train/fine-tune using the selected provider's controlled environment.
7. Run multilingual, hallucination, privacy and medical-safety evaluations.
8. Record model ID, base model, dataset version and results.
9. Promote by setting `HENI_FINE_TUNED_MODEL_ID` only after the model passes the agreed release gate.

Fine-tuning should specialize Heni's language/behavior. Appointment truth, patient data, provider instructions and route state stay dynamic in the application backend.
