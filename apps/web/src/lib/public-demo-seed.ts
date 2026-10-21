import { createHash } from "node:crypto";

/** Stable IDs keep repeated bootstrap requests idempotent per guest. */
export function demoUuid(userId: string, part: string): string {
  const bytes = Buffer.from(createHash("sha256").update("hani-public-demo:" + part + ":" + userId).digest().subarray(0, 16));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = bytes.toString("hex");
  return [hex.slice(0, 8), hex.slice(8, 12), hex.slice(12, 16), hex.slice(16, 20), hex.slice(20)].join("-");
}

type DemoRow = Record<string, unknown>;
export type DemoFixture = { table: string; rows: DemoRow[] };

/** Only fictional names, events, data and contact details are seeded. */
export function demoFixtures(userId: string, caregiverId: string): {
  patientId: string;
  fixtures: DemoFixture[];
} {
  const id = (tag: string) => demoUuid(userId, tag);
  const patientId = id("patient");
  const circleId = id("circle");
  const medicationId = id("medication");
  const professionalId = id("professional");
  const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

  return {
    patientId,
    fixtures: [
      { table: "patients", rows: [{
        id: patientId, display_name: "Amina (synthetic demo)", preferred_name: "Amina",
        primary_language: "derja", alzheimer_stage: "mild", sex: "female",
        important_notes: "Entirely fictional patient profile for a public demonstration.",
        is_demo: true, created_by_profile_id: caregiverId,
      }] },
      { table: "caregiver_patient_relationships", rows: [{
        id: id("relationship"), caregiver_profile_id: caregiverId,
        patient_id: patientId, caregiver_role: "primary",
        relationship_label: "Synthetic family caregiver", access_status: "active",
        consent_basis: "public_synthetic_demo",
      }] },
      { table: "care_circles", rows: [{
        id: circleId, patient_id: patientId, name: "Demo Care Circle",
        created_by_profile_id: caregiverId,
      }] },
      { table: "care_circle_members", rows: [{
        id: id("circle-self"), care_circle_id: circleId,
        profile_id: caregiverId, member_role: "caregiver", status: "active",
      }] },
      { table: "patient_medications", rows: [{
        id: medicationId, patient_id: patientId,
        medication_name: "Example medication (not a prescription)",
        dose_text: "Follow the verified prescription", schedule_text: "09:00",
        instructions: "Synthetic demonstration. Hani does not prescribe or modify medication.",
        verified: false, active: true,
      }] },
      { table: "medication_schedules", rows: [{
        id: id("medication-schedule"), patient_medication_id: medicationId,
        patient_id: patientId, created_by_profile_id: caregiverId,
        timezone: "Africa/Tunis", times: ["09:00"], active: true,
      }] },
      { table: "care_tasks", rows: [{
        id: id("task-1"), patient_id: patientId, title: "Prepare a calm evening routine",
        description: "Fictional task to demonstrate care coordination.",
        requested_by_profile_id: caregiverId, assigned_to_profile_id: caregiverId,
        status: "open", source: "manual", difficulty: "light", effort_weight: 1,
      }, {
        id: id("task-2"), patient_id: patientId, title: "Review tomorrow's appointment",
        description: "Synthetic demonstration appointment checklist.",
        requested_by_profile_id: caregiverId, assigned_to_profile_id: caregiverId,
        status: "open", source: "manual", difficulty: "moderate", effort_weight: 1,
      }] },
      { table: "incidents", rows: [{
        id: id("incident"), patient_id: patientId,
        reported_by_profile_id: caregiverId,
        title: "Fictional dinner-time concern",
        summary: "Synthetic example: Amina became unsettled during dinner; caregiver noted what helped.",
        visibility: "private_draft", support_level: "routine_support",
        metadata: { synthetic: true },
      }] },
      { table: "patient_memory_items", rows: [{
        id: id("memory-1"), patient_id: patientId, item_type: "place",
        title: "Fictional family garden", subtitle: "A familiar place for gentle conversation",
        active: true, sort_order: 1, metadata: { synthetic: true },
      }, {
        id: id("memory-2"), patient_id: patientId, item_type: "music",
        title: "A favorite imaginary song", subtitle: "Discuss happy musical memories",
        active: true, sort_order: 2, metadata: { synthetic: true },
      }] },
      { table: "wellbeing_checkins", rows: [{
        id: id("wellbeing"), caregiver_profile_id: caregiverId, patient_id: patientId,
        mood_label: "okay", energy_label: "moderate", source: "manual",
        free_text: "Synthetic example of a caregiver check-in.",
      }] },
      { table: "notification_preferences", rows: [{
        id: id("preferences"), caregiver_profile_id: caregiverId,
        enabled: true, care_circle_requests: true, appointments: true,
      }] },
      { table: "caregiver_notifications", rows: [{
        id: id("notification"), caregiver_profile_id: caregiverId,
        category: "demo_notice", title: "Welcome to the synthetic demo",
        body: "Your activities are separate from other visitors and not connected to real patients.",
        action_type: "open_care_hub",
      }] },
      { table: "professional_profiles", rows: [{
        id: professionalId, full_name: "Dr Demo (fictional)",
        specialty: "Example care professional", facility_name: "Fictional Demo Clinic",
        is_verified: false, verification_note: "Synthetic only. Do not contact.",
      }] },
      { table: "professional_connections", rows: [{
        id: id("professional-link"), patient_id: patientId,
        professional_id: professionalId, connection_type: "care",
        status: "active", authorized_by_profile_id: caregiverId,
      }] },
      { table: "professional_instructions", rows: [{
        id: id("professional-instruction"), patient_id: patientId,
        professional_id: professionalId, instruction_type: "care",
        title: "Example routine note", body: "Fictional instruction for feature demonstration only.",
        status: "draft",
      }] },
      { table: "caregiver_appointments", rows: [{
        id: id("appointment"), patient_id: patientId,
        requested_by_profile_id: caregiverId, professional_id: professionalId,
        scheduled_for: tomorrow, reason: "Fictional follow-up appointment",
        status: "requested",
      }] },
    ],
  };
}
