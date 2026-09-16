# PRD feature / acceptance matrix — competition build v2.1

This matrix separates **working competition-demo behavior** from **future provider deployment gates**.

| PRD criterion | Competition build | Notes / production gate |
|---|---|---|
| AC-01 Responsive patient UI | Implemented | Mobile-first from 360 px; persistent patient nav and floating Heni companion. |
| AC-02 French + Arabic / RTL | Implemented core | French patient flows, Arabic/RTL home, Arabic voice/chat responses; full copy translation remains iterative. |
| AC-03 Service search + rule-derived availability | Implemented | Controlled aliases + deterministic schedule rules. |
| AC-04 Capacity-safe booking | Implemented in demo repository | Final slot revalidation + serialized writes; production DB transaction/locking required. |
| AC-05 Appointment appears in staff console | Implemented | Mobile, Heni and voice actions share the same repository/domain state. |
| AC-06 Journey created on booking | Implemented | Appointment, preparation, navigation, visit, follow-up. |
| AC-07 Reminder state | Implemented | Local/in-app/simulated notification path; external providers optional. |
| AC-08 Real hospital context + labeled demo indoor graph | Implemented | Real Charles Nicolle reference address/coordinates; locally rendered prototype campus geometry with visible disclaimer. |
| AC-09 Deterministic route | Implemented | Dijkstra route engine + local visual route + waypoint progression. |
| AC-10 Ordinary phone reaches AI | Browser substitute implemented; PSTN not active without provider | `/voice-lab` provides a real browser speech conversation for the competition. A real telephone number still requires a telephony provider and public deployment. |
| AC-11 Voice lookup/book/cancel/reschedule via tools | Implemented | Deterministic conversation state machine calls application domain tools. |
| AC-12 Explicit confirmation before voice writes | Implemented | Server-side write guard + conversation state. |
| AC-13 Voice tool actions visible to staff | Implemented | Saved transcript + call/tool event timeline in `/staff/calls`. |
| AC-14 Clinical dosage-change boundary | Implemented | Refuse/escalate; no dosage generation. |
| AC-15 Staff completes visit → patient follow-up | Implemented | Journey state updates. |
| AC-16 Medication package clarification | Implemented bounded prototype | Deterministic safe fallback; no autonomous clinical decision. |
| AC-17 White-label configuration | Implemented demo | Tenant colors/name configurable without component edits. |
| AC-18 Demo reset | Implemented | `npm run demo:reset`. |
| AC-19 Critical automated tests | Implemented | Domain tests + 150-case deterministic evaluation harness. |
| AC-20 Measured AI evaluation report | Implemented for deterministic classifier | Curated synthetic result only; not live speech-model accuracy. |

## Additional competition differentiators implemented

### Heni persistent companion
- Global bottom-right assistant.
- Animated SVG human avatar.
- Idle breathing and eye blinking.
- Listening animation.
- Mouth/head/hand movement during browser speech output.
- Typed and microphone interaction.
- Same constrained backend tool flow as Voice Lab.
- Clinical-boundary escalation.

### Voice Lab v2
- React 19-safe async bootstrap inside `useEffect`.
- Browser microphone input with typed fallback.
- Browser speech synthesis.
- Tunisian-Arabic/French dialogue state machine.
- Saved conversation transcript.
- Saved tool events.
- Explicit booking confirmation.
- Safety-demo prompt.

### Hospital guidance v2
- Local provider-independent campus visual.
- Real hospital reference location/address.
- Prototype-route provenance label.
- Deterministic route graph.
- Accessibility metadata.
- Waypoint progress and remaining-distance estimate.
- Optional browser geolocation.
- Optional external real-world map link only when Internet exists.

### AR guidance prototype
- Real device/browser camera via `getUserMedia()` on localhost/HTTPS.
- Camera-overlay direction arrow, waypoint name and distance.
- Heni overlay.
- Manual waypoint confirmation.
- Automatic simulated-corridor fallback if camera permission/device support fails.
- No false claim of automatic indoor localization.

## Production gates deliberately not faked

Real staff/patient authentication, provider-validated indoor geometry, HIS/EHR integration, Tunisia telecom provisioning, legal/privacy sign-off, real patient data governance, live-SMS sender registration and measured live Tunisian-Arabic speech accuracy remain pilot/production work.
