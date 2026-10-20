/**
 * Restrict competition-era API endpoints to local, explicitly enabled demos.
 * This module deliberately has no Next.js dependencies so it can be unit tested.
 */
const LEGACY_PREFIXES = [
  "/api/v1/demo",
  "/api/v1/appointments",
  "/api/v1/availability",
  "/api/v1/caregivers",
  "/api/v1/escalations",
  "/api/v1/journey-steps",
  "/api/v1/journeys",
  "/api/v1/medicine",
  "/api/v1/navigation",
  "/api/v1/services",
  "/api/v1/staff",
  "/api/v1/voice",
  "/api/v1/waitlist",
  "/api/v1/agent",
  "/api/webhooks/telephony",
] as const;

export function isLegacyEndpoint(pathname: string): boolean {
  return LEGACY_PREFIXES.some(
    (prefix) => pathname === prefix || pathname.startsWith(prefix + "/"),
  );
}

export function allowLocalDemoAccess(env: NodeJS.ProcessEnv = process.env): boolean {
  return env.NODE_ENV !== "production" && env.DEMO_MODE === "true";
}

export function isDemoIdentity(caregiverId: string, patientId: string): boolean {
  return caregiverId === "10000000-0000-0000-0000-000000000001" &&
    patientId === "30000000-0000-0000-0000-000000000001";
}
