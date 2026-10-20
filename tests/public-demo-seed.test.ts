import test from "node:test";
import assert from "node:assert/strict";
import { demoFixtures, demoUuid } from "../apps/web/src/lib/public-demo-seed.ts";

test("each anonymous user gets a unique set of deterministic demo identities", () => {
  const first = demoFixtures("11111111-1111-4111-8111-111111111111", demoUuid("11111111-1111-4111-8111-111111111111", "profile"));
  const same = demoFixtures("11111111-1111-4111-8111-111111111111", demoUuid("11111111-1111-4111-8111-111111111111", "profile"));
  const other = demoFixtures("22222222-2222-4222-8222-222222222222", demoUuid("22222222-2222-4222-8222-222222222222", "profile"));
  assert.equal(first.patientId, same.patientId);
  assert.notEqual(first.patientId, other.patientId);
  assert.notEqual(demoUuid("one", "patient"), demoUuid("one", "profile"));
});

test("all fixtures are synthetic, bounded and owned by the guest", () => {
  const userId = "11111111-1111-4111-8111-111111111111";
  const caregiverId = demoUuid(userId, "profile");
  const { patientId, fixtures } = demoFixtures(userId, caregiverId);
  const tables = new Set(fixtures.map(f => f.table));
  assert.ok(tables.has("patients"));
  assert.ok(tables.has("caregiver_patient_relationships"));
  assert.ok(tables.has("care_tasks"));
  assert.ok(tables.has("patient_medications"));
  assert.ok(tables.has("patient_memory_items"));
  const patient = fixtures.find(f => f.table === "patients")?.rows[0];
  assert.equal(patient?.is_demo, true);
  assert.equal(patient?.created_by_profile_id, caregiverId);
  const relationship = fixtures.find(f => f.table === "caregiver_patient_relationships")?.rows[0];
  assert.equal(relationship?.caregiver_profile_id, caregiverId);
  assert.equal(relationship?.patient_id, patientId);
  assert.ok(fixtures.every(f => f.rows.length <= 3));
});
