import test from "node:test";
import assert from "node:assert/strict";
import { approvedDemoUser } from "../apps/web/src/lib/public-demo-access.ts";

const demo = "11111111-1111-4111-8111-111111111111";
const another = "22222222-2222-4222-8222-222222222222";

test("only the configured, password-authenticated demo UUID is allowed", () => {
  assert.equal(approvedDemoUser({ id: demo, is_anonymous: false }, demo), true);
  assert.equal(approvedDemoUser({ id: another, is_anonymous: false }, demo), false);
  assert.equal(approvedDemoUser({ id: demo, is_anonymous: true }, demo), false);
  assert.equal(approvedDemoUser({ id: demo }, ""), false);
  assert.equal(approvedDemoUser({ id: demo }, undefined), false);
  assert.equal(approvedDemoUser(null, demo), false);
  assert.equal(approvedDemoUser({ id: demo }, "demo@example.invalid"), false);
});
