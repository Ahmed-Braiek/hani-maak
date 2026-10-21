import test from "node:test";
import assert from "node:assert/strict";
import {
  canPerformCaregiverAction,
  canSeeIncident,
  mayRequestProfessionalHelp,
  mayViewMedications,
  mayViewSharedIncidents,
} from "../apps/web/src/lib/caregiver-permissions.ts";

const primary = {
  caregiver_role: "primary",
  can_view_medications: true,
  can_view_shared_incidents: true,
  can_manage_tasks: true,
  can_request_professional_help: true,
};
const limited = {
  caregiver_role: "secondary",
  can_view_medications: false,
  can_view_shared_incidents: false,
  can_manage_tasks: false,
  can_request_professional_help: false,
};
test("relationship flags must be explicitly true to authorize sensitive reads", () => {
  assert.equal(mayViewMedications(primary), true);
  assert.equal(mayViewMedications(limited), false);
  assert.equal(mayViewMedications({}), false);
  assert.equal(mayViewSharedIncidents(limited), false);
  assert.equal(mayRequestProfessionalHelp(limited), false);
});
test("a caregiver sees own incident but not another caregiver's without sharing permission", () => {
  const own = { reported_by_profile_id: "current", visibility: "private_draft" };
  const anotherShared = { reported_by_profile_id: "different", visibility: "shared_care_timeline" };
  const anotherPrivate = { reported_by_profile_id: "different", visibility: "private_draft" };
  assert.equal(canSeeIncident(limited, "current", own), true);
  assert.equal(canSeeIncident(limited, "current", anotherShared), false);
  assert.equal(canSeeIncident(primary, "current", anotherShared), true);
  assert.equal(canSeeIncident(primary, "current", anotherPrivate), false);
});
test("medication and document edits require primary role, task edits require explicit grant", () => {
  for (const action of ["create_medication", "record_medication_event"]) {
    assert.equal(canPerformCaregiverAction(primary, action), true);
    assert.equal(canPerformCaregiverAction(limited, action), false);
    assert.equal(canPerformCaregiverAction({ caregiver_role: "secondary", can_view_medications: true }, action), false);
  }
  assert.equal(canPerformCaregiverAction(primary, "save_care_document"), true);
  assert.equal(canPerformCaregiverAction(limited, "save_care_document"), false);
  assert.equal(canPerformCaregiverAction(limited, "create_care_task"), false);
  assert.equal(canPerformCaregiverAction(primary, "record_patient_activity"), true);
});
