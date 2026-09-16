# Hani Maak v2.1 — competition hardening changelog

## React / Next.js fix
- Rewrote Voice Lab initialization to use a synchronous `useEffect` callback with an inner async bootstrap function.
- Added cleanup for browser speech recognition and synthesis.
- Pinned Next.js to 16.3.5 and React 19.2.0.
- Added `npm run clean` to remove stale `.next` output after replacing an older project copy.

## Heni companion
- Added a persistent bottom-right Heni assistant to the root layout.
- Added animated SVG avatar with blinking, breathing, listening pulse, head movement, hand movement and speaking mouth animation.
- Added typed chat, microphone input and browser speech output.
- Uses the same server conversation / tool boundary as Voice Lab.
- Clinical-boundary requests are escalated instead of answered.

## Voice Lab
- New competition-grade voice stage and conversation UI.
- Browser SpeechRecognition when supported; keyboard fallback always available.
- Browser SpeechSynthesis for audible replies.
- Saved synthetic-demo transcript and tool timeline.
- Clear proof panel explaining deterministic scheduling and confirmation guard.
- Script shortcuts for booking, preparation, navigation, clinical boundary and human escalation.

## Guidance
- Rebuilt hospital guidance UI around a local provider-independent campus visual.
- Keeps real Charles Nicolle reference context while visibly labeling the indoor graph as prototype data.
- Added deterministic route progress, waypoint numbers, remaining distance and accessibility metadata.
- Added optional browser geolocation to explain the start point.
- External map is now optional rather than required for the core screen.

## AR prototype
- Added `/patient/map/ar`.
- Uses browser camera through `getUserMedia()` when available.
- Overlays route arrow, next waypoint, remaining distance, Heni and route evidence.
- Automatically falls back to a simulated corridor if the camera is unavailable or permission is denied.
- Does not claim automatic indoor positioning.

## Staff operations
- `/staff/calls` now displays saved demo conversation alongside every recorded tool event.
- Added source/channel, tool arguments, result and status visibility.
- Updated staff navigation and demo-state visual hierarchy.

## Presentation polish
- Rebuilt landing narrative around one shared patient journey.
- Updated presentation mode to eight live proof points.
- Added local-first stage-failure fallbacks to the runbook.

## QA
- 4/4 deterministic domain tests passing.
- 150/150 curated voice intent / safety scenarios passing.
- 86 TypeScript/TSX files syntax-parsed with zero diagnostics in packaging QA.
