import { timingSafeEqual } from "node:crypto";
import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

type Json = Record<string, any>;

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL?.replace(/\/$/, "");
const supabaseKey = process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;

function secureEqual(left: string | undefined, right: string | undefined) {
  if (!left || !right) return false;
  const a = Buffer.from(left);
  const b = Buffer.from(right);
  return a.length === b.length && timingSafeEqual(a, b);
}

function clean(value: unknown, max = 1000) {
  return String(value ?? "").trim().slice(0, max);
}

function headers(extra: Record<string, string> = {}) {
  if (!supabaseKey) throw new Error("supabase_secret_missing");
  const base: Record<string, string> = {
    apikey: supabaseKey,
    "content-type": "application/json",
  };
  if (!supabaseKey.startsWith("sb_secret_") && !supabaseKey.startsWith("sb_publishable_")) {
    base.Authorization = `Bearer ${supabaseKey}`;
  }
  return { ...base, ...extra };
}

async function sb(path: string, init: RequestInit = {}) {
  if (!supabaseUrl || !supabaseKey) throw new Error("supabase_not_configured");
  const response = await fetch(`${supabaseUrl}/rest/v1/${path}`, {
    ...init,
    headers: { ...headers(), ...(init.headers as Record<string, string> | undefined) },
    cache: "no-store",
  });
  const raw = await response.text();
  const body = raw ? JSON.parse(raw) : null;
  if (!response.ok) {
    throw new Error(body?.message || body?.error || `supabase_http_${response.status}`);
  }
  return body;
}

async function first(path: string) {
  const rows = await sb(path);
  return Array.isArray(rows) ? rows[0] ?? null : null;
}

async function requireRelationship(caregiverId: string, patientId: string) {
  const row = await first(
    `caregiver_patient_relationships?select=*&caregiver_profile_id=eq.${encodeURIComponent(caregiverId)}&patient_id=eq.${encodeURIComponent(patientId)}&access_status=eq.active&limit=1`,
  );
  if (!row) throw new Error("caregiver_patient_access_denied");
  return row;
}

async function getProfessionalRoutes(patientId: string) {
  const connections = await sb(
    `professional_connections?select=id,professional_id,connection_type,status&patient_id=eq.${encodeURIComponent(patientId)}&status=eq.active`,
  ) as Json[];
  const ids = connections.map((x) => x.professional_id).filter(Boolean);
  if (!ids.length) return [];
  const inList = ids.join(",");
  const professionals = await sb(
    `professional_profiles?select=id,full_name,specialty,facility_name,phone,whatsapp,booking_url,is_verified&id=in.(${inList})`,
  ) as Json[];
  const map = new Map(professionals.map((p) => [p.id, p]));
  return connections
    .map((c) => ({ connection: c, professional: map.get(c.professional_id) }))
    .filter((x) => x.professional?.is_verified === true);
}

export async function caregiverContext(caregiverId: string, patientId: string) {
  const relationship = await requireRelationship(caregiverId, patientId);
  const [caregiver, patient, meds, instructions, incidentRows, tasks, wellbeing, circle] = await Promise.all([
    first(`profiles?select=id,full_name,preferred_language,timezone,role&id=eq.${encodeURIComponent(caregiverId)}&limit=1`),
    first(`patients?select=id,display_name,preferred_name,date_of_birth,sex,alzheimer_stage,primary_language,important_notes,is_demo&id=eq.${encodeURIComponent(patientId)}&limit=1`),
    sb(`patient_medications?select=id,medication_name,dose_text,schedule_text,instructions,verified,active&patient_id=eq.${encodeURIComponent(patientId)}&active=eq.true`),
    sb(`professional_instructions?select=id,instruction_type,title,body,status,verified_at,professional_id&patient_id=eq.${encodeURIComponent(patientId)}&status=eq.active`),
    sb(`incidents?select=id,reported_by_profile_id,scenario_id,title,summary,occurred_at,support_level,visibility,created_at&patient_id=eq.${encodeURIComponent(patientId)}&order=created_at.desc&limit=20`),
    sb(`care_tasks?select=id,title,description,status,effort_weight,difficulty,starts_at,due_at,overnight,requested_by_profile_id,assigned_to_profile_id&patient_id=eq.${encodeURIComponent(patientId)}&order=due_at.asc.nullslast&limit=30`),
    sb(`wellbeing_checkins?select=id,mood_label,energy_label,sleep_label,free_text,created_at&caregiver_profile_id=eq.${encodeURIComponent(caregiverId)}&order=created_at.desc&limit=7`),
    first(`care_circles?select=id,name&patient_id=eq.${encodeURIComponent(patientId)}&limit=1`),
  ]);

  if (!patient) throw new Error("patient_not_found");

  const incidents = (incidentRows as Json[]).filter(
    (i) => i.reported_by_profile_id === caregiverId || i.visibility === "shared_care_timeline",
  );

  let members: Json[] = [];
  if (circle?.id) {
    const memberRows = await sb(
      `care_circle_members?select=id,profile_id,member_role,status,joined_at&care_circle_id=eq.${encodeURIComponent(circle.id)}&status=eq.active`,
    ) as Json[];
    const memberIds = memberRows.map((m) => m.profile_id).filter(Boolean);
    if (memberIds.length) {
      const inList = memberIds.join(",");
      const people = await sb(
        `profiles?select=id,full_name,avatar_url&id=in.(${inList})`,
      ) as Json[];
      const peopleMap = new Map(people.map((p) => [p.id, p]));
      members = memberRows.map((m) => ({ ...m, profile: peopleMap.get(m.profile_id) ?? null }));
    }
  }

  const professionals = await getProfessionalRoutes(patientId);

  return {
    caregiver,
    patient,
    relationship,
    medications: meds,
    professionalInstructions: instructions,
    recentIncidents: incidents.slice(0, 10),
    careTasks: tasks,
    privateWellbeing: wellbeing,
    careCircle: circle ? { ...circle, members } : null,
    professionalRoutes: professionals,
  };
}

export async function recordDemoWellbeing(caregiverId: string, patientId: string, input: Json) {
  await requireRelationship(caregiverId, patientId);
  const rows = await sb("wellbeing_checkins", {
    method: "POST",
    headers: { Prefer: "return=representation" },
    body: JSON.stringify({
      caregiver_profile_id: caregiverId,
      patient_id: patientId,
      mood_label: clean(input.moodLabel, 80) || null,
      energy_label: clean(input.energyLabel, 80) || null,
      sleep_label: clean(input.sleepLabel, 80) || null,
      free_text: clean(input.freeText, 1200) || null,
      source: "manual",
    }),
  });
  return rows?.[0] ?? null;
}

export async function shareDemoIncident(caregiverId: string, patientId: string, incidentId: string) {
  await requireRelationship(caregiverId, patientId);
  const incident = await first(
    `incidents?select=*&id=eq.${encodeURIComponent(incidentId)}&reported_by_profile_id=eq.${encodeURIComponent(caregiverId)}&patient_id=eq.${encodeURIComponent(patientId)}&limit=1`,
  );
  if (!incident) throw new Error("incident_not_found_or_not_owned");

  const rows = await sb(`incidents?id=eq.${encodeURIComponent(incidentId)}`, {
    method: "PATCH",
    headers: { Prefer: "return=representation" },
    body: JSON.stringify({
      visibility: "shared_care_timeline",
      approved_to_share_by_profile_id: caregiverId,
      shared_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }),
  });

  await sb("timeline_events", {
    method: "POST",
    headers: { Prefer: "return=minimal" },
    body: JSON.stringify({
      patient_id: patientId,
      event_type: "incident",
      title: incident.title || "Care incident",
      summary: incident.summary,
      occurred_at: incident.occurred_at || incident.created_at || new Date().toISOString(),
      source_type: "incident",
      source_id: incident.id,
      created_by_profile_id: caregiverId,
      visible_to_care_circle: true,
    }),
  });

  return rows?.[0] ?? null;
}

export async function requestDemoCareTask(caregiverId: string, patientId: string, input: Json) {
  await requireRelationship(caregiverId, patientId);
  const recipientProfileId = clean(input.recipientProfileId, 120);
  const circle = await first(`care_circles?select=id&patient_id=eq.${encodeURIComponent(patientId)}&limit=1`);
  if (!circle) throw new Error("care_circle_not_found");

  const recipient = await first(
    `care_circle_members?select=id&care_circle_id=eq.${circle.id}&profile_id=eq.${encodeURIComponent(recipientProfileId)}&status=eq.active&limit=1`,
  );
  if (!recipient) throw new Error("recipient_not_in_care_circle");

  const taskRows = await sb("care_tasks", {
    method: "POST",
    headers: { Prefer: "return=representation" },
    body: JSON.stringify({
      patient_id: patientId,
      title: clean(input.title, 200) || "Care support",
      description: clean(input.description, 1000) || null,
      source: "manual",
      requested_by_profile_id: caregiverId,
      assigned_to_profile_id: null,
      status: "requested",
      effort_weight: Number(input.effortWeight) > 0 ? Number(input.effortWeight) : 1,
      difficulty: ["light", "moderate", "heavy"].includes(input.difficulty) ? input.difficulty : "moderate",
      due_at: input.dueAt || null,
      overnight: false,
      metadata: { source: "flutter-demo" },
    }),
  });
  const task = taskRows?.[0];

  const requestRows = await sb("care_task_requests", {
    method: "POST",
    headers: { Prefer: "return=representation" },
    body: JSON.stringify({
      task_id: task.id,
      requester_profile_id: caregiverId,
      recipient_profile_id: recipientProfileId,
      status: "pending",
      message: clean(input.message, 500) || null,
    }),
  });

  return { task, request: requestRows?.[0] ?? null };
}

export async function POST(req: Request) {
  const configured = process.env.HENI_AGENT_SHARED_SECRET;
  if (!configured) return NextResponse.json({ error: "agent_bridge_not_configured" }, { status: 503 });
  if (!secureEqual(req.headers.get("x-heni-agent-key") ?? undefined, configured)) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  try {
    const body = await req.json().catch(() => ({}));
    const tool = clean(body?.tool, 80);
    const args = (body?.args && typeof body.args === "object" ? body.args : {}) as Json;
    const context = (body?.context && typeof body.context === "object" ? body.context : {}) as Json;
    const caregiverId = clean(context.caregiverId, 120);
    const patientId = clean(context.patientId, 120);

    if (!caregiverId || !patientId) {
      return NextResponse.json({ error: "caregiver_and_patient_context_required" }, { status: 400 });
    }

    await requireRelationship(caregiverId, patientId);

    if (tool === "get_caregiver_context") {
      return NextResponse.json({ success: true, ...(await caregiverContext(caregiverId, patientId)) });
    }

    if (tool === "list_dilemma_scenarios") {
      const scenarios = await sb(
        "dilemma_scenarios?select=id,scenario_key,title_i18n,short_description_i18n,version,display_order&active=eq.true&validation_status=eq.validated&order=display_order.asc",
      );
      return NextResponse.json({ success: true, scenarios });
    }

    if (tool === "get_dilemma_scenario") {
      const key = clean(args.scenarioKey, 120);
      const scenario = await first(
        `dilemma_scenarios?select=*&scenario_key=eq.${encodeURIComponent(key)}&active=eq.true&validation_status=eq.validated&limit=1`,
      );
      if (!scenario) return NextResponse.json({ success: false, error: "scenario_not_found" }, { status: 404 });
      const [questions, guidance, redFlags] = await Promise.all([
        sb(`dilemma_questions?select=question_key,prompt_i18n,response_type,options,required,display_order&scenario_id=eq.${scenario.id}&active=eq.true&order=display_order.asc`),
        sb(`dilemma_guidance?select=guidance_key,guidance_i18n,condition_json,display_order&scenario_id=eq.${scenario.id}&active=eq.true&validation_status=eq.validated&order=display_order.asc`),
        sb(`dilemma_red_flags?select=red_flag_key,description_i18n,trigger_json,escalation_level,recommended_route&scenario_id=eq.${scenario.id}&active=eq.true&validation_status=eq.validated`),
      ]);
      return NextResponse.json({ success: true, scenario, questions, guidance, redFlags });
    }

    if (tool === "create_incident_draft") {
      const scenarioKey = clean(args.scenarioKey, 120);
      const scenario = scenarioKey
        ? await first(`dilemma_scenarios?select=id&scenario_key=eq.${encodeURIComponent(scenarioKey)}&limit=1`)
        : null;
      const payload = {
        patient_id: patientId,
        reported_by_profile_id: caregiverId,
        scenario_id: scenario?.id ?? null,
        title: clean(args.title, 180) || null,
        summary: clean(args.summary, 1600),
        occurred_at: new Date().toISOString(),
        support_level: ["routine_support", "professional_input_recommended", "possible_urgent_concern"].includes(args.supportLevel)
          ? args.supportLevel
          : "routine_support",
        visibility: "private_draft",
        metadata: { source: "hani" },
      };
      if (!payload.summary) return NextResponse.json({ error: "incident_summary_required" }, { status: 400 });
      const rows = await sb("incidents", {
        method: "POST",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify(payload),
      });
      return NextResponse.json({ success: true, incident: rows?.[0], shared: false });
    }

    if (tool === "share_incident") {
      const incidentId = clean(args.incidentId, 120);
      const incident = await first(
        `incidents?select=*&id=eq.${encodeURIComponent(incidentId)}&reported_by_profile_id=eq.${encodeURIComponent(caregiverId)}&patient_id=eq.${encodeURIComponent(patientId)}&limit=1`,
      );
      if (!incident) return NextResponse.json({ error: "incident_not_found_or_not_owned" }, { status: 404 });
      const rows = await sb(`incidents?id=eq.${encodeURIComponent(incidentId)}`, {
        method: "PATCH",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({
          visibility: "shared_care_timeline",
          approved_to_share_by_profile_id: caregiverId,
          shared_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        }),
      });
      await sb("timeline_events", {
        method: "POST",
        headers: { Prefer: "return=minimal" },
        body: JSON.stringify({
          patient_id: patientId,
          event_type: "incident",
          title: incident.title || "Care incident",
          summary: incident.summary,
          occurred_at: incident.occurred_at || incident.created_at || new Date().toISOString(),
          source_type: "incident",
          source_id: incident.id,
          created_by_profile_id: caregiverId,
          visible_to_care_circle: true,
        }),
      });
      return NextResponse.json({ success: true, incident: rows?.[0], shared: true });
    }

    if (tool === "get_care_circle") {
      const contextData = await caregiverContext(caregiverId, patientId);
      return NextResponse.json({
        success: true,
        careCircle: contextData.careCircle,
        careTasks: contextData.careTasks,
      });
    }

    if (tool === "request_care_task") {
      const recipientProfileId = clean(args.recipientProfileId, 120);
      const circle = await first(`care_circles?select=id&patient_id=eq.${encodeURIComponent(patientId)}&limit=1`);
      if (!circle) return NextResponse.json({ error: "care_circle_not_found" }, { status: 404 });
      const recipient = await first(
        `care_circle_members?select=id&care_circle_id=eq.${circle.id}&profile_id=eq.${encodeURIComponent(recipientProfileId)}&status=eq.active&limit=1`,
      );
      if (!recipient) return NextResponse.json({ error: "recipient_not_in_care_circle" }, { status: 400 });

      const taskRows = await sb("care_tasks", {
        method: "POST",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({
          patient_id: patientId,
          title: clean(args.title, 200),
          description: clean(args.description, 1000) || null,
          source: "hani_suggestion",
          requested_by_profile_id: caregiverId,
          assigned_to_profile_id: null,
          status: "requested",
          effort_weight: Number(args.effortWeight) > 0 ? Number(args.effortWeight) : 1,
          difficulty: ["light", "moderate", "heavy"].includes(args.difficulty) ? args.difficulty : null,
          due_at: args.dueAt || null,
          overnight: false,
          metadata: { createdBy: "hani" },
        }),
      });
      const task = taskRows?.[0];
      const requestRows = await sb("care_task_requests", {
        method: "POST",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({
          task_id: task.id,
          requester_profile_id: caregiverId,
          recipient_profile_id: recipientProfileId,
          status: "pending",
          message: clean(args.message, 500) || null,
        }),
      });
      return NextResponse.json({ success: true, task, request: requestRows?.[0] });
    }

    if (tool === "record_wellbeing_checkin") {
      const rows = await sb("wellbeing_checkins", {
        method: "POST",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({
          caregiver_profile_id: caregiverId,
          patient_id: patientId,
          mood_label: clean(args.moodLabel, 80) || null,
          energy_label: clean(args.energyLabel, 80) || null,
          sleep_label: clean(args.sleepLabel, 80) || null,
          free_text: clean(args.freeText, 1200) || null,
          source: "hani",
        }),
      });
      return NextResponse.json({ success: true, checkin: rows?.[0], private: true });
    }

    if (tool === "get_professional_routes" || tool === "request_human_help") {
      const routes = await getProfessionalRoutes(patientId);
      return NextResponse.json({ success: true, routes });
    }

    if (tool === "create_professional_contact_request") {
      const professionalId = clean(args.professionalId, 120);
      const channel = clean(args.channel, 40);
      if (!["call", "whatsapp", "appointment"].includes(channel)) {
        return NextResponse.json({ error: "invalid_contact_channel" }, { status: 400 });
      }
      const connection = await first(
        `professional_connections?select=id&patient_id=eq.${encodeURIComponent(patientId)}&professional_id=eq.${encodeURIComponent(professionalId)}&status=eq.active&limit=1`,
      );
      if (!connection) return NextResponse.json({ error: "professional_not_connected" }, { status: 400 });

      const professional = await first(
        `professional_profiles?select=id,full_name,specialty,phone,whatsapp,booking_url,is_verified&id=eq.${encodeURIComponent(professionalId)}&is_verified=eq.true&limit=1`,
      );
      if (!professional) return NextResponse.json({ error: "professional_not_verified" }, { status: 400 });

      const consentRows = await sb("consents", {
        method: "POST",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({
          actor_profile_id: caregiverId,
          patient_id: patientId,
          consent_type: "professional_handoff",
          scope: { minimumNecessary: true, incidentId: args.incidentId || null },
          recipient_type: "professional",
          recipient_id: professionalId,
          status: "granted",
        }),
      });
      const consent = consentRows?.[0];

      let handoff = null;
      const summary = clean(args.summary, 1800);
      if (summary) {
        const rows = await sb("handoff_summaries", {
          method: "POST",
          headers: { Prefer: "return=representation" },
          body: JSON.stringify({
            caregiver_profile_id: caregiverId,
            patient_id: patientId,
            professional_id: professionalId,
            incident_id: args.incidentId || null,
            consent_id: consent?.id ?? null,
            summary,
            status: "approved",
            approved_at: new Date().toISOString(),
          }),
        });
        handoff = rows?.[0] ?? null;
      }

      const requestRows = await sb("professional_contact_requests", {
        method: "POST",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({
          caregiver_profile_id: caregiverId,
          patient_id: patientId,
          professional_id: professionalId,
          handoff_summary_id: handoff?.id ?? null,
          channel,
          status: "requested",
        }),
      });

      let uiAction: Json | null = null;
      if (channel === "call" && professional.phone) {
        uiAction = { type: "open_url", label: "Call", url: `tel:${professional.phone}` };
      } else if (channel === "whatsapp" && professional.whatsapp) {
        const digits = String(professional.whatsapp).replace(/\D/g, "");
        uiAction = { type: "open_url", label: "WhatsApp", url: `https://wa.me/${digits}` };
      } else if (channel === "appointment" && professional.booking_url) {
        uiAction = { type: "open_url", label: "Request appointment", url: professional.booking_url };
      }

      return NextResponse.json({
        success: true,
        request: requestRows?.[0],
        handoff,
        professional,
        uiAction,
      });
    }

    return NextResponse.json({ error: "unsupported_caregiver_agent_tool" }, { status: 400 });
  } catch (error) {
    const message = error instanceof Error ? error.message : "caregiver_agent_tool_failed";
    console.error("Caregiver Hani tool failed", message);
    const status = /not_found|denied/.test(message) ? 404 : /required|invalid|not_connected/.test(message) ? 400 : 500;
    return NextResponse.json({ success: false, error: message.slice(0, 180) }, { status });
  }
}
