import test from "node:test";
import assert from "node:assert/strict";
import { hasPermission, type StaffIdentity } from "../apps/web/src/lib/access.ts";

const doctor: StaffIdentity = { id: "d", name: "Doctor", role: "doctor" };
const admin: StaffIdentity = { id: "a", name: "Administration", role: "administration" };
const superAdmin: StaffIdentity = { id: "s", name: "Super Admin", role: "super_admin" };

test("doctor can access clinical information and administration cannot", () => {
  assert.equal(hasPermission(doctor, "patients.view_medical"), true);
  assert.equal(hasPermission(admin, "patients.view_medical"), false);
  assert.equal(hasPermission(admin, "clinical_notes.create"), false);
});

test("super admin manages platform settings without receiving clinical access by default", () => {
  assert.equal(hasPermission(superAdmin, "system_settings.manage"), true);
  assert.equal(hasPermission(superAdmin, "roles.manage"), true);
  assert.equal(hasPermission(superAdmin, "patients.view_medical"), false);
});

test("permission overrides can only affect the explicit capability", () => {
  const scoped: StaffIdentity = { ...admin, permissionOverrides: { "services.manage": false } };
  assert.equal(hasPermission(scoped, "services.manage"), false);
  assert.equal(hasPermission(scoped, "appointments.view"), true);
});
