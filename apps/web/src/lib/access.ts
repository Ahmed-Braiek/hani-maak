export type StaffRole="doctor"|"administration"|"super_admin";

export type Permission=
  |"patients.view_general"|"patients.edit_general"|"patients.view_medical"|"patients.edit_medical"
  |"appointments.view"|"appointments.create"|"appointments.edit"|"appointments.cancel"
  |"clinical_notes.view"|"clinical_notes.create"|"medical_documents.view"
  |"services.view"|"services.manage"|"schedules.view"|"schedules.manage"
  |"staff.view"|"staff.manage"|"roles.manage"|"ai.manage"|"maps.manage"
  |"translations.manage"|"white_label.manage"|"notifications.manage"|"integrations.manage"
  |"analytics.view"|"system_settings.manage"|"audit.view";

export type StaffIdentity={
  id:string;
  name:string;
  role:StaffRole;
  department?:string;
  permissionOverrides?:Partial<Record<Permission,boolean>>;
};

export const rolePermissions:Record<StaffRole,Permission[]>={
  doctor:[
    "patients.view_general","patients.view_medical","patients.edit_medical",
    "appointments.view","appointments.create","appointments.edit",
    "clinical_notes.view","clinical_notes.create","medical_documents.view",
    "services.view","schedules.view"
  ],
  administration:[
    "patients.view_general","patients.edit_general",
    "appointments.view","appointments.create","appointments.edit","appointments.cancel",
    "services.view","services.manage","schedules.view","schedules.manage",
    "notifications.manage","analytics.view"
  ],
  super_admin:[
    "patients.view_general","appointments.view","services.view","services.manage","schedules.view","schedules.manage",
    "staff.view","staff.manage","roles.manage","ai.manage","maps.manage","translations.manage","white_label.manage",
    "notifications.manage","integrations.manage","analytics.view","system_settings.manage","audit.view"
  ]
};

export function hasPermission(identity:StaffIdentity|undefined,permission:Permission){
  if(!identity)return false;
  const override=identity.permissionOverrides?.[permission];
  if(typeof override==="boolean")return override;
  return rolePermissions[identity.role].includes(permission);
}

export const roleMeta:Record<StaffRole,{labelKey:string;summaryKey:string;home:string;icon:string}>={
  doctor:{labelKey:"roles.doctor",summaryKey:"roles.doctor_summary",home:"/staff/doctor",icon:"⚕"},
  administration:{labelKey:"roles.administration",summaryKey:"roles.administration_summary",home:"/staff/administration",icon:"▦"},
  super_admin:{labelKey:"roles.super_admin",summaryKey:"roles.super_admin_summary",home:"/staff/super-admin",icon:"◇"}
};

export const permissionGroups:[string,Permission[]][]=[
  ["permissions.patient_data",["patients.view_general","patients.edit_general","patients.view_medical","patients.edit_medical","medical_documents.view"]],
  ["permissions.appointments",["appointments.view","appointments.create","appointments.edit","appointments.cancel"]],
  ["permissions.clinical",["clinical_notes.view","clinical_notes.create"]],
  ["permissions.operations",["services.view","services.manage","schedules.view","schedules.manage","notifications.manage","analytics.view"]],
  ["permissions.platform",["staff.view","staff.manage","roles.manage","ai.manage","maps.manage","translations.manage","white_label.manage","integrations.manage","system_settings.manage","audit.view"]]
];
