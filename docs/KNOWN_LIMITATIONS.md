# Known limitations - competition build

- The local JSON store is single-process and is not suitable for horizontal scaling or real patient data.
- Staff/patient authentication is intentionally demo-shortcut based. Real production identity, session governance, tenant membership and object-level access controls are not enabled in the zero-setup competition mode.
- Facility indoor coordinates are synthetic/prototype data and must not be presented as a hospital-validated floor plan.
- The geographic map depends on external web map availability for that context; product navigation fallbacks remain separate.
- Live PSTN/realtime calling requires provider credentials, a public WSS endpoint and provider provisioning. The browser Voice Lab remains the deterministic stage fallback.
- The realtime voice bridge is provider-specific integration code and must be re-tested against the selected provider's current WebSocket/model contract before live production use.
- Heni is now architecturally ready to select a fine-tuned model through configuration, but **no fine-tuned Heni model should be claimed as trained/validated until a real model ID, governed dataset and held-out evaluation results exist**.
- Model-backed Heni Chat is optional. Provider failure falls back to the deterministic competition path for supported actions rather than making the web journey depend on model availability.
- The deterministic safety layer is a product guard, not a substitute for production moderation, rate limiting, monitoring, red-team testing and human clinical governance.
- Medicine vision can fail on glare, blur, damaged packages, small print or multilingual labels. Visible text extraction is never treated as professional treatment instruction.
- SMS/email are opt-in adapters; default competition behavior may use simulated delivery.
- External HIS/EHR/FHIR integration is not enabled because no provider authorization/API has been supplied.
- The included evaluation score is for the deterministic pre-agent classifier over synthetic text cases; it is not a measured clinical outcome, live PSTN speech-model accuracy or fine-tuned-model quality score.
- No HIPAA, GDPR, ISO or other formal compliance/certification status is claimed by this competition repository.
