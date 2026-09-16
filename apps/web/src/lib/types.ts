export type Locale = "fr" | "ar" | "en";
export type Provenance = "verified_public" | "provider_verified" | "demo_seeded" | "user_entered" | "ai_extracted";
export type AppointmentState = "requested" | "offered" | "confirmed" | "cancelled" | "completed" | "no_show" | "needs_assistance";
export type JourneyStepState = "upcoming" | "active" | "completed" | "skipped" | "blocked";
export type JourneyStepType = "info" | "checklist" | "reminder" | "navigation" | "appointment" | "document" | "follow_up" | "human_action";

export interface Tenant {
  id: string; slug: string; displayName: string; timezone: string; defaultLocale: Locale;
  supportedLocales: Locale[]; address: string; phone: string; demoMode: boolean;
  brand: { primary: string; accent: string; logoText: string };
}
export interface Patient {
  id: string; tenantId: string; firstName: string; lastName: string; age?: number; phone: string;
  email?: string; preferredLocale: Locale; preferredChannel: "app" | "phone" | "sms" | "email";
  consentStatus: "demo" | "granted" | "unknown"; dataProvenance: Provenance;
}
export interface StaffUser { id: string; tenantId: string; displayName: string; role: "receptionist" | "coordinator" | "clinician" | "manager" | "tenant_admin"; active: boolean; }
export interface Service {
  id: string; tenantId: string; code: string; name: Record<Locale,string>; description: Record<Locale,string>;
  department: string; aliases: Record<Locale,string[]>; bookingMode: "direct" | "request"; slotDurationMin: number;
  locationNodeId: string; documents: string[]; preparationTemplateId?: string; followupTemplateId?: string;
  accessibilityNotes?: string; active: boolean; dataProvenance: Provenance;
}
export interface ScheduleRule { id: string; tenantId: string; serviceId: string; dayOfWeek: number; startTime: string; endTime: string; capacity: number; slotDurationMin?: number; }
export interface ScheduleException { id: string; serviceId: string; date: string; startTime?: string; endTime?: string; closed?: boolean; capacityOverride?: number; reason?: string; }
export interface Appointment {
  id: string; tenantId: string; patientId: string; serviceId: string; startAt: string; endAt: string;
  state: AppointmentState; channel: "app" | "voice" | "staff"; sourceSessionId?: string;
  cancellationReason?: string; provenance: Provenance; version: number; createdAt: string; updatedAt: string;
}
export interface JourneyStep { id: string; type: JourneyStepType; sequence: number; state: JourneyStepState; title: Record<Locale,string>; body?: Record<Locale,string>; dueAt?: string; payload?: Record<string, unknown>; completedAt?: string; }
export interface Journey { id: string; tenantId: string; patientId: string; appointmentId: string; serviceId: string; state: "active" | "completed" | "cancelled"; createdAt: string; updatedAt: string; steps: JourneyStep[]; }
export interface Notification { id: string; tenantId: string; patientId: string; journeyStepId?: string; channel: "in_app" | "email" | "sms" | "voice"; message: string; state: "queued" | "sent" | "delivered" | "failed" | "simulated"; scheduledAt: string; createdAt: string; }
export interface FacilityNode { id: string; tenantId: string; code: string; label: Record<Locale,string>; type: "entrance" | "reception" | "corridor" | "elevator" | "stair" | "department" | "room"; floor: number; lat?: number; lon?: number; x: number; y: number; accessible: boolean; provenance: Provenance; }
export interface FacilityEdge { id: string; tenantId: string; from: string; to: string; distanceM: number; bidirectional: boolean; accessible: boolean; restricted: boolean; instruction: Record<Locale,string>; provenance: Provenance; }
export interface ContentTemplate { id: string; tenantId: string; type: "preparation" | "follow_up" | "medicine_instruction" | "general"; title: Record<Locale,string>; body: Record<Locale,string>; version: number; published: boolean; provenance: Provenance; reviewedBy?: string; }
export interface CallSession { id: string; tenantId: string; patientId?: string; externalCallId?: string; caller: string; locale: Locale; startedAt: string; endedAt?: string; outcome: "active" | "completed" | "escalated" | "failed"; state: string; context: Record<string, unknown>; summary?: string; transcriptConsent: boolean; }
export interface AgentToolEvent { id: string; tenantId: string; callSessionId: string; toolName: string; arguments: Record<string, unknown>; result: Record<string, unknown>; status: "success" | "error" | "rejected"; latencyMs: number; createdAt: string; }
export interface Escalation { id: string; tenantId: string; patientId?: string; journeyId?: string; source: "app" | "voice" | "staff"; category: "clinical_boundary" | "human_requested" | "ambiguous" | "technical" | "other"; summary: string; priority: "normal" | "high"; state: "open" | "assigned" | "resolved"; createdAt: string; }
export interface AuditEvent { id: string; tenantId: string; actorType: "patient" | "staff" | "ai" | "system"; actorId?: string; action: string; resourceType: string; resourceId?: string; metadata: Record<string, unknown>; createdAt: string; }
export interface ProductEvent { id: string; tenantId: string; eventName: string; properties: Record<string, unknown>; createdAt: string; }
export interface MedicineSession { id: string; tenantId: string; patientId: string; fileName: string; extracted: { detectedName?: string; detectedStrengthText?: string; expiryText?: string; expiryDateISO?: string; lotText?: string; confidenceNotes: string[] }; confirmed: boolean; linkedInstructionId?: string; outcome: "needs_confirmation" | "instruction_found" | "escalate"; createdAt: string; }

export interface CaregiverDelegation { id:string; tenantId:string; patientId:string; caregiverName:string; caregiverPhone:string; scopes:("appointments"|"journey"|"reminders")[]; createdAt:string; expiresAt?:string; revokedAt?:string; }
export interface WaitlistEntry { id:string; tenantId:string; patientId:string; serviceId:string; currentAppointmentId?:string; preferredPeriod?:"morning"|"afternoon"; fromDate:string; toDate:string; state:"active"|"matched"|"cancelled"; createdAt:string; }

export interface DemoDb {
  tenant: Tenant; patients: Patient[]; staff: StaffUser[]; services: Service[]; scheduleRules: ScheduleRule[]; scheduleExceptions: ScheduleException[];
  appointments: Appointment[]; journeys: Journey[]; notifications: Notification[]; facilityNodes: FacilityNode[]; facilityEdges: FacilityEdge[];
  contentTemplates: ContentTemplate[]; callSessions: CallSession[]; toolEvents: AgentToolEvent[]; escalations: Escalation[]; auditLog: AuditEvent[];
  productEvents: ProductEvent[]; medicineSessions: MedicineSession[]; caregiverDelegations: CaregiverDelegation[]; waitlistEntries: WaitlistEntry[]; meta: { seededAt: string; revision: number; };
}
