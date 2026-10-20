import test from "node:test";
import assert from "node:assert/strict";
import {
  allowLocalDemoAccess,
  isDemoIdentity,
  isLegacyEndpoint,
} from "../apps/web/src/lib/demo-access-policy.ts";

test("demo mode must not authorize production or hosted preview builds", () => {
  assert.equal(allowLocalDemoAccess({ NODE_ENV: "production", DEMO_MODE: "true" } as NodeJS.ProcessEnv), false);
  assert.equal(allowLocalDemoAccess({ NODE_ENV: "production" } as NodeJS.ProcessEnv), false);
  assert.equal(allowLocalDemoAccess({ NODE_ENV: "development", DEMO_MODE: "false" } as NodeJS.ProcessEnv), false);
  assert.equal(allowLocalDemoAccess({ NODE_ENV: "development", DEMO_MODE: "true" } as NodeJS.ProcessEnv), true);
});

test("all competition state, staff and mutation endpoints are protected", () => {
  for (const url of [
    "/api/v1/demo/state",
    "/api/v1/demo/reset",
    "/api/v1/demo/notifications/dispatch",
    "/api/v1/appointments",
    "/api/v1/appointments/1/cancel",
    "/api/v1/agent/tools",
    "/api/v1/staff/session/login",
    "/api/v1/voice/live/start",
    "/api/v1/escalations",
    "/api/v1/waitlist",
    "/api/webhooks/telephony/incoming",
  ]) assert.equal(isLegacyEndpoint(url), true, url);
});

test("caregiver-first and Hani agent endpoints are not globally disabled", () => {
  for (const url of [
    "/api/v1/caregiver-app",
    "/api/v1/caregiver-agent/tools",
    "/api/v1/heni/chat",
    "/api/v1/heni/voice-token",
    "/api/v1/heni/ocr-prescription",
    "/api/v1/system/status",
  ]) assert.equal(isLegacyEndpoint(url), false, url);
});

test("only the exact synthetic demo pair is identified as demo", () => {
  assert.equal(isDemoIdentity("10000000-0000-0000-0000-000000000001", "30000000-0000-0000-0000-000000000001"), true);
  assert.equal(isDemoIdentity("10000000-0000-0000-0000-000000000001", "other"), false);
});
