# Training Dataset Boundary

Only synthetic, redacted, non-sensitive examples belong in this directory.

## Never commit

- patient names, identifiers, phone numbers, emails or medical-record numbers;
- medical records, prescriptions, diagnoses or private clinical notes;
- raw voice recordings or call transcripts from real patients;
- staff credentials, tokens, API keys or secrets;
- partner/institutional datasets unless their license and governance explicitly allow repository publication.

`private/` and `raw/` are ignored by Git as an additional guard, but ignored folders are not a substitute for an approved secure storage/data-governance process.

## Synthetic examples

`example.synthetic.jsonl` demonstrates the expected conceptual fields for Tunisian Derja, French and English administrative scenarios. It is not a training corpus and does not represent real patients.

## Versioning

For approved private datasets, record a non-sensitive manifest identifier/hash, source authorization, preprocessing version and evaluation split outside the dataset itself. Never use mutable filenames alone as provenance.
