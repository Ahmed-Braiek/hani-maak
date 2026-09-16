# Hani Maak — هاني معاك

Competition-ready Next.js prototype for the Future Health Connectathon 2026. Hani Maak is a patient-journey layer — **Access → Guidance → Continuity** — rather than a standalone appointment screen.

This package is intentionally designed to remain impressive **without requiring paid or external AI/telephony/database providers on competition day**. The deterministic demo backend, browser voice mode, animated Heni companion, route engine, AR-style camera guidance, patient app and staff console all run from the repository.

## 1. Run locally

Prerequisites: Node.js 20.9+ and npm 10+.

```bash
cp .env.example .env.local
npm install
npm run clean
npm run demo:reset
npm run dev
```

Open <http://localhost:3000>.

Recommended competition browser: current Chrome/Chromium. It provides the best chance of browser SpeechRecognition support. Typing always remains available if microphone recognition is not supported.

Demo shortcuts:
- `/` — competition landing page
- `/present` — presentation sequence
- `/patient` — patient mobile journey (synthetic patient Amel)
- `/patient/services` — service discovery and booking entry
- `/patient/map` — deterministic hospital guidance demo
- `/patient/map/ar` — camera-based AR guidance prototype
- `/patient/medicine` — bounded medicine-package clarification prototype
- `/voice-lab` — working browser voice conversation with Heni
- `/staff` — operations console
- `/staff/calls` — saved conversation + MCP/tool activity
- `/ar` — Arabic/RTL patient home

## 2. Competition demo mode

The default app runs without external credentials. It uses a JSON-backed repository under `apps/web/data/demo-db.json` with synthetic identities, generated schedule rules, an auditable tool log, saved demo conversations and a manually-authored facility route graph.

After replacing an older copy of the project, clear the previous Next.js cache once:

```bash
npm run clean
```

Before every presentation:

```bash
npm run demo:reset
```

The hospital demo uses **Hôpital Charles Nicolle, Tunis** as the real geographic reference context. The indoor/campus geometry is explicitly labeled **Prototype route — not validated by the hospital**. Do not present the demo route as an authoritative hospital floor plan.

## 3. Heni — floating assistant

Heni appears at the bottom-right across the application. It is implemented locally as an animated SVG avatar with:
- idle breathing and blinking,
- listening state,
- speaking/head/hand movement,
- mouth animation while browser speech synthesis is active,
- typed chat,
- optional browser microphone input,
- spoken replies,
- the same constrained server-side administrative tools used by the Voice Lab.

Heni is not a clinical agent. Questions that cross the clinical boundary create a staff escalation instead of generating treatment advice.

## 4. Voice Lab — no provider required

`/voice-lab` is the competition-safe voice demonstration.

It uses:
1. Browser SpeechRecognition when supported.
2. Browser SpeechSynthesis for Heni's audible reply.
3. The Hani Maak deterministic conversation state machine.
4. Real application tools for schedule lookup, booking, instructions, navigation and escalation.
5. Saved call sessions and tool events visible in `/staff/calls`.

If browser speech recognition is unavailable, type exactly the same phrases: all backend actions still work and are saved.

The React `useEffect` initialization was rewritten using an inner async bootstrap function plus cleanup, avoiding Promise-returning effects under React 19 / Next.js 16.

## 5. Hospital guidance and AR prototype

`/patient/map` contains a fully local hospital-route presentation:
- real Charles Nicolle reference address and coordinates,
- locally rendered campus-style context,
- deterministic route graph,
- numbered waypoints,
- remaining-distance estimate,
- accessibility metadata,
- manual waypoint progression,
- optional browser geolocation,
- optional link to external OpenStreetMap context when Internet exists.

`/patient/map/ar` uses the phone/browser camera via `getUserMedia()` when permission is granted. It overlays Heni, route instructions, direction arrow, distance and waypoint progression over the camera view. If the camera is unavailable, it automatically switches to a simulated corridor so the presentation remains functional.

Camera access works on `localhost` and HTTPS origins. It normally will not work on an insecure remote HTTP URL.

## 6. Optional providers later

The core competition story does not require them, but the repository keeps integration paths for:
- Supabase/Postgres (`supabase/schema.sql` and `supabase/competition-state.sql`),
- real telephony / realtime AI through the separate voice bridge,
- external notifications,
- external map services.

The local JSON repository is the default source of truth so provider provisioning cannot block the demo.

## 7. Architecture

```text
Patient UI ──────────────────┐
Floating Heni chat ──────────┤
Browser Voice Lab ───────────┼─ Next.js API ─ Domain services ─ Demo repository
Staff Console ────────────────┘                   │
                                                  ├ scheduling engine
                                                  ├ journey engine
                                                  ├ deterministic route graph
                                                  ├ safety/intent policy
                                                  └ audited tool gateway
```

The conversational layer never owns appointment truth. A state-changing action must pass through the deterministic domain layer and voice actions require explicit confirmation.

## 8. Safety boundary

Hani Maak automates administrative tasks and exposes provider-authored information. It does not diagnose, prescribe, change doses, determine urgency, or certify medication safety. Clinical-boundary questions generate a human escalation.

## 9. Tests and evaluation

```bash
npm test
npm run evals
```

Current packaged QA:
- 4/4 domain tests pass.
- 150-case deterministic voice intent/safety evaluation: 100% intent classification and 100% clinical-boundary classification on the curated synthetic dataset.
- TypeScript/TSX source syntax parsed successfully in packaging QA.

These are prototype test metrics, not claims about clinical outcomes or live Tunisian-Arabic speech-recognition accuracy.

## 10. Source specification

The source PRD is included at `docs/Hani-Maak-PRD-v2.0.pdf`.
Read:
- `docs/COMPETITION_RUNBOOK.md` before presenting,
- `docs/ARCHITECTURE.md` for technical jury questions,
- `docs/KNOWN_LIMITATIONS.md` for truthful prototype boundaries,
- `docs/FEATURE_MATRIX.md` for implementation coverage.
