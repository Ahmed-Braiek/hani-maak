/**
 * Application-level access restrictions for a caregiver's active patient link.
 * This is a defense-in-depth companion to authenticated identity checks.
 * A service-role database client can bypass RLS; never infer these permissions
 * merely from a patient_id or from an active relationship.
 */
export type CaregiverGrants = {
  caregiver_role?: string | null;
  can_view_medications?: boolean | null;
  can_view_shared_incidents?: boolean | null;
  can_manage_tasks?: boolean | null;
  can_request_professional_help?: boolean | null;
};

export function mayViewMedications(grants: CaregiverGrants): boolean {
  return grants.can_view_medications === true;
}

export function mayViewSharedIncidents(grants: CaregiverGrants): boolean {
  return grants.can_view_shared_incidents === true;
}

export function mayRequestProfessionalHelp(grants: CaregiverGrants): boolean {
  return grants.can_request_professional_help === true;
}

export function canSeeIncident(
  grants: CaregiverGrants,
  viewerId: string,
  incident: { reported_by_profile_id?: string | null; visibility?: string | null },
): boolean {
  return (
    incident.reported_by_profile_id === viewerId ||
    (mayViewSharedIncidents(grants) && incident.visibility === "shared_care_timeline")
  );
}

/**
 * Conservatively gate sensitive mutations until dedicated, clinically
 * reviewed permissions for medication edits, documents and disclosure exist.
 */
export function canPerformCaregiverAction(grants: CaregiverGrants, action: string): boolean {
  switch (action) {
    case "create_medication":
    case "record_medication_event":
      return grants.caregiver_role === "primary" && mayViewMedications(grants);
    case "save_care_document":
      return grants.caregiver_role === "primary";
    case "create_care_task":
    case "record_patient_activity":
      return grants.can_manage_tasks === true;
    default:
      return true; // Other actions still require a verified authenticated relationship.
  }
}
