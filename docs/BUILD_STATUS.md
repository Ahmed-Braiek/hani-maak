# Build and QA status — v2.1

Prepared as a local-first competition package for the Future Health Connectathon.

## Fixed in this revision

- Replaced the Voice Lab mount effect with a React 19-safe `useEffect` pattern: an inner async bootstrap function is invoked without returning its Promise, and the effect returns a real cleanup function.
- Added lifecycle cleanup for browser speech recognition/synthesis.
- Added persistent Heni animated companion.
- Added browser voice conversation mode with saved transcript/tool flow.
- Added local hospital-map visual and camera-based AR guidance route.
- Added staff conversation transcript review.
- Pinned Next.js to `16.3.5` and React/React DOM to `19.2.0` to match the reported local runtime and reduce install drift.

## Verified in the packaging environment

- Domain tests: **4/4 pass**.
- Deterministic pre-agent evaluation: **150/150 curated scenarios pass** for intent and clinical-boundary classification.
- TypeScript/TSX parser QA: **86 source files parsed with zero syntax diagnostics** after v2.1 changes.
- Core competition mode requires no external API credentials.
- ZIP integrity is checked during packaging.

## Packaging-environment limitation

Outbound npm registry access timed out in the artifact environment, so `npm install` and therefore `next build` could not be completed here. The user already reported running the project locally on Next.js 16.3.5; this revision pins that exact Next.js version.

Run the final machine-specific gate on the presentation laptop:

```bash
cp .env.example .env.local
npm install
npm run qa
npm run build
npm run demo:reset
npm run dev
```

Then verify:
- `/present`
- `/patient`
- floating Heni companion
- `/voice-lab`
- `/staff/calls`
- `/patient/map`
- `/patient/map/ar`
- `/patient/medicine`

## Demo truthfulness boundary

The real facility reference is Hôpital Charles Nicolle, Tunis. The indoor/campus route geometry is a demo dataset and remains visibly labeled as unvalidated. The AR page demonstrates camera-overlay UX and route progression; it does not claim automatic hospital indoor positioning.
