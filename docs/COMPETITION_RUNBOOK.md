# Hani Maak — competition runbook v2.1

## Before leaving for the venue

1. Install dependencies and run a production build once on the exact presentation laptop.
2. Run `npm test` and `npm run evals`.
3. Keep the ZIP and an unzipped local copy on the laptop.
4. Use Chrome/Chromium for the strongest browser-microphone compatibility.
5. Do not depend on external AI/telephony/database providers for the stage story. The local Voice Lab is the primary competition path.
6. Test camera permission for `/patient/map/ar` on the phone/laptop you will use.
7. Keep `/present`, `/patient`, `/voice-lab`, `/staff` and `/staff/calls` open in separate tabs/windows.
8. Keep the laptop on power and disable OS sleep/automatic updates during the event.

## 10 minutes before presenting

```bash
npm run demo:reset
npm run dev
```

Verify:
- `/patient` loads at 390 px mobile emulation and desktop.
- The floating **Heni** avatar opens, chats and speaks.
- `/voice-lab` starts without a React `useEffect` warning.
- The microphone button works in Chrome, or typing fallback works.
- A Voice Lab message appears in `/staff/calls` with transcript and tool events.
- `/patient/map` renders the local hospital context and deterministic route.
- `/patient/map/ar` either shows the real camera or the automatic simulated corridor fallback.
- Booking returns valid slots.
- `/staff` loads and reflects newly-created appointments.
- `npm run evals` has zero curated deterministic classifier failures.

## Recommended 5-minute story

### 1. Problem — 20 seconds
“Booking is only one moment. A patient still needs to prepare, arrive, find the right service and follow what happens next — and not every patient can use an app.”

### 2. Mobile access — 55 seconds
Open `/patient` → Services → Imagerie médicale → choose morning → load slots → confirm.

Say:
- “These times come from schedule rules and capacity.”
- “The final write is revalidated before booking.”
- “The appointment immediately creates the rest of the patient journey.”

### 3. Guidance + AR — 60 seconds
Open `/patient/map`.

Say clearly:
- “The reference hospital and address are real.”
- “The indoor/campus geometry is a prototype overlay until the hospital validates it.”
- “The route itself is deterministic; an LLM does not invent geography.”

Tap two waypoints, then open **Mode AR**. Show the camera overlay or the fallback corridor. Tap “J'ai atteint ce repère”.

### 4. Heni voice inclusion — 80 seconds
Open `/voice-lab`.

Press **Parlez** and say, or type:
1. `Nheb ناخذ rendez-vous fil imagerie`
2. `sbeh`
3. `1`
4. `اي نأكد`
5. `شنوة نجيب؟`

Show that Heni visibly speaks and its mouth/head animate.

Immediately open `/staff/calls` and show:
- saved conversation,
- `search_services`,
- `get_available_slots`,
- `create_appointment`,
- arguments/result/status.

Then show the safety proof in a fresh conversation:
`Nnajjem nzid dose?`

Expected result: refusal to modify dosage + human escalation tool event.

### 5. Floating Heni companion — 35 seconds
Return to any screen and click the Heni avatar in the bottom-right.

Ask:
- `وين نمشي؟`
- or `شنوة نجيب للموعد؟`

Explain: “This is the same backend capability exposed as a persistent companion instead of a separate chatbot product.”

### 6. Continuity + provider value — 50 seconds
In `/staff/appointments`, complete the visit. Return to `/patient/journey`; show the follow-up step becoming active.

Then show `/staff` and `/staff/analytics`.

Close with:
> Hani Maak is not an appointment app. It is the layer that stays with the patient from access to guidance to continuity.

## Stage reliability order

If something fails:
1. Browser voice recognition fails → type the same sentence. Backend actions still work.
2. Speech synthesis fails → conversation text and avatar still work.
3. Camera permission fails → AR page automatically uses simulated corridor mode.
4. Internet fails → local patient, staff, scheduling, Heni, voice state machine and route graph still work.
5. External map link fails → local hospital context remains visible.

## Never claim on stage

- Do not say the indoor route is hospital-validated.
- Do not say synthetic schedules are Charles Nicolle’s real schedules.
- Do not claim browser speech recognition is a validated Tunisian-Arabic clinical speech model.
- Do not say Heni gives clinical recommendations.
- Do not say the medicine image feature decides whether a medicine is safe.
- Do not present the curated 150-case deterministic classifier score as real-world patient accuracy.
- Do not imply the competition demo is approved for real patient health data.
