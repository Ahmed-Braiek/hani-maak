# Known limitations — competition build

- The local JSON store is single-process and not suitable for horizontal scaling or real patient data.
- Staff/patient authentication is intentionally demo-shortcut based. Production authentication is represented by the Supabase schema/path but is not enabled in the zero-setup competition mode.
- Facility indoor coordinates are synthetic and visibly labeled unvalidated.
- The geographic map uses an external OpenStreetMap embed; the local route layer remains usable if it is unavailable.
- Live PSTN calling requires Twilio/OpenAI credentials, a public WSS endpoint and provider provisioning. The browser Voice Lab is the deterministic stage fallback.
- The GPT-Live bridge relies on third-party APIs and must be re-tested against current provider schemas immediately before the competition.
- Medicine vision can fail on glare, blur, damaged packages, small print or multilingual labels. Visible text extraction is never treated as professional treatment instruction.
- SMS/email are opt-in adapters; default competition behavior is simulated delivery.
- External HIS/EHR/FHIR integration is not enabled because no provider authorization/API has been supplied.
- The included evaluation score is for the deterministic pre-agent classifier over 150 synthetic text cases; it is not a measured PSTN speech-model accuracy score.
