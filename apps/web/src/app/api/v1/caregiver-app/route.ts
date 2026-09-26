import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

type Json = Record<string, any>;

const supabaseUrl = (process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL)?.replace(/\/$/, "");
const supabaseKey = process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;
const DEMO_CAREGIVER = "10000000-0000-0000-0000-000000000001";
const DEMO_PATIENT = "30000000-0000-0000-0000-000000000001";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
  "Access-Control-Allow-Headers": "authorization,content-type",
  "Access-Control-Max-Age": "86400",
};

function json(body: unknown, init?: ResponseInit) {
  const response = NextResponse.json(body, init);
  Object.entries(cors).forEach(([k, v]) => response.headers.set(k, v));
  return response;
}

export async function OPTIONS() {
  return new Response(null, { status: 204, headers: cors });
}

function clean(value: unknown, max = 1200) {
  return String(value ?? "").trim().slice(0, max);
}

function restHeaders(extra: Record<string, string> = {}) {
  if (!supabaseKey) throw new Error("supabase_secret_missing");
  const h: Record<string, string> = {
    apikey: supabaseKey,
    "content-type": "application/json",
    ...extra,
  };
  if (!supabaseKey.startsWith("sb_secret_") && !supabaseKey.startsWith("sb_publishable_")) {
    h.Authorization = `Bearer ${supabaseKey}`;
  }
  return h;
}

async function sb(path: string, init: RequestInit = {}) {
  if (!supabaseUrl || !supabaseKey) throw new Error("supabase_not_configured");
  const response = await fetch(`${supabaseUrl}/rest/v1/${path}`, {
    ...init,
    headers: {
      ...restHeaders(),
      ...(init.headers as Record<string, string> | undefined),
    },
    cache: "no-store",
  });
  const raw = await response.text();
  const body = raw ? JSON.parse(raw) : null;
  if (!response.ok) throw new Error(body?.message || body?.error || `supabase_http_${response.status}`);
  return body;
}

async function first(path: string) {
  const rows = await sb(path);
  return Array.isArray(rows) ? rows[0] ?? null : null;
}

async function verifyIdentity(req: Request, caregiverId: string, patientId: string) {
  if (caregiverId === DEMO_CAREGIVER && patientId === DEMO_PATIENT) return;

  const auth = req.headers.get("authorization") || "";
  if (!auth.startsWith("Bearer ")) throw new Error("authentication_required");
  if (!supabaseUrl || !supabaseKey) throw new Error("supabase_not_configured");

  const userResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: { apikey: supabaseKey, Authorization: auth },
    cache: "no-store",
  });
  if (!userResponse.ok) throw new Error("invalid_session");
  const user = await userResponse.json();

  const profile = await first(
    `profiles?select=id&auth_user_id=eq.${encodeURIComponent(user.id)}&id=eq.${encodeURIComponent(caregiverId)}&limit=1`,
  );
  if (!profile) throw new Error("caregiver_identity_mismatch");
  const relationship = await first(
    `caregiver_patient_relationships?select=id&caregiver_profile_id=eq.${encodeURIComponent(caregiverId)}&patient_id=eq.${encodeURIComponent(patientId)}&access_status=eq.active&limit=1`,
  );
  if (!relationship) throw new Error("caregiver_patient_access_denied");
}

async function professionalRoutes(patientId: string) {
  const connections = await sb(
    `professional_connections?select=id,professional_id,connection_type,status&patient_id=eq.${encodeURIComponent(patientId)}&status=eq.active`,
  ) as Json[];
  const ids = connections.map((x) => x.professional_id).filter(Boolean);
  if (!ids.length) return [];
  const people = await sb(
    `professional_profiles?select=id,full_name,specialty,facility_name,phone,whatsapp,booking_url,is_verified&id=in.(${ids.join(",")})`,
  ) as Json[];
  const map = new Map(people.map((p) => [p.id, p]));
  return connections
    .map((c) => ({ connection: c, professional: map.get(c.professional_id) }))
    .filter((x) => x.professional?.is_verified === true);
}

async function loadContext(caregiverId: string, patientId: string) {
  const relationship = await first(
    `caregiver_patient_relationships?select=*&caregiver_profile_id=eq.${encodeURIComponent(caregiverId)}&patient_id=eq.${encodeURIComponent(patientId)}&access_status=eq.active&limit=1`,
  );
  if (!relationship) throw new Error("caregiver_patient_access_denied");

  const [
    caregiver,
    patient,
    medications,
    instructions,
    incidentRows,
    tasks,
    wellbeing,
    circle,
    notifications,
    preferences,
    timeline,
    appointments,
    supportSignals,
    incomingRequests,
    outgoingRequests,
    questionnaireDefinitions,
  ] = await Promise.all([
    first(`profiles?select=id,full_name,preferred_language,timezone,role,avatar_url,metadata&id=eq.${encodeURIComponent(caregiverId)}&limit=1`),
    first(`patients?select=id,display_name,preferred_name,date_of_birth,sex,alzheimer_stage,primary_language,important_notes,photo_url,is_demo&id=eq.${encodeURIComponent(patientId)}&limit=1`),
    sb(`patient_medications?select=id,medication_name,dose_text,schedule_text,instructions,verified,active&patient_id=eq.${encodeURIComponent(patientId)}&active=eq.true`),
    sb(`professional_instructions?select=id,instruction_type,title,body,status,verified_at,professional_id,created_at&patient_id=eq.${encodeURIComponent(patientId)}&status=eq.active&order=created_at.desc`),
    sb(`incidents?select=id,reported_by_profile_id,scenario_id,title,summary,occurred_at,support_level,visibility,created_at,shared_at,resolved_at&patient_id=eq.${encodeURIComponent(patientId)}&order=created_at.desc&limit=30`),
    sb(`care_tasks?select=id,title,description,source,status,effort_weight,difficulty,starts_at,due_at,overnight,requested_by_profile_id,assigned_to_profile_id,created_at&patient_id=eq.${encodeURIComponent(patientId)}&order=due_at.asc.nullslast&limit=50`),
    sb(`wellbeing_checkins?select=id,mood_label,energy_label,sleep_label,free_text,created_at&caregiver_profile_id=eq.${encodeURIComponent(caregiverId)}&order=created_at.desc&limit=30`),
    first(`care_circles?select=id,name&patient_id=eq.${encodeURIComponent(patientId)}&limit=1`),
    sb(`caregiver_notifications?select=id,category,title,body,action_type,action_payload,scheduled_for,delivered_at,opened_at,created_at&caregiver_profile_id=eq.${encodeURIComponent(caregiverId)}&order=created_at.desc&limit=30`),
    first(`notification_preferences?select=*&caregiver_profile_id=eq.${encodeURIComponent(caregiverId)}&limit=1`),
    sb(`timeline_events?select=id,event_type,title,summary,occurred_at,source_type,source_id,visible_to_care_circle,created_at&patient_id=eq.${encodeURIComponent(patientId)}&visible_to_care_circle=eq.true&order=occurred_at.desc&limit=50`),
    sb(`caregiver_appointments?select=id,patient_id,requested_by_profile_id,professional_id,scheduled_for,reason,status,created_at&patient_id=eq.${encodeURIComponent(patientId)}&order=created_at.desc&limit=20`),
    sb(`support_signals?select=id,signal_type,severity,confidence,evidence,experimental,created_at&caregiver_profile_id=eq.${encodeURIComponent(caregiverId)}&order=created_at.desc&limit=20`),
    sb(`care_task_requests?select=id,task_id,requester_profile_id,recipient_profile_id,status,message,alternative_note,alternative_starts_at,responded_at,created_at&recipient_profile_id=eq.${encodeURIComponent(caregiverId)}&order=created_at.desc&limit=20`),
    sb(`care_task_requests?select=id,task_id,requester_profile_id,recipient_profile_id,status,message,alternative_note,alternative_starts_at,responded_at,created_at&requester_profile_id=eq.${encodeURIComponent(caregiverId)}&order=created_at.desc&limit=20`),
    sb("questionnaire_definitions?select=id,code,name,purpose,owner,active&active=eq.true&order=created_at.desc"),
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
    const ids = memberRows.map((m) => m.profile_id).filter(Boolean);
    if (ids.length) {
      const profiles = await sb(`profiles?select=id,full_name,avatar_url&id=in.(${ids.join(",")})`) as Json[];
      const map = new Map(profiles.map((p) => [p.id, p]));
      members = memberRows.map((m) => ({ ...m, profile: map.get(m.profile_id) ?? null }));
    }
  }

  const questionnaires: Json[] = [];
  for (const definition of questionnaireDefinitions as Json[]) {
    const versions = await sb(
      `questionnaire_versions?select=id,version_label,language,validation_status,validation_reference,active&questionnaire_id=eq.${definition.id}&active=eq.true&validation_status=eq.validated`,
    ) as Json[];
    questionnaires.push(...versions.map((version) => ({ ...version, definition })));
  }

  const taskById = new Map((tasks as Json[]).map((t) => [t.id, t]));
  const allRequests = [...(incomingRequests as Json[]), ...(outgoingRequests as Json[])];
  const requests = allRequests.map((r) => ({ ...r, task: taskById.get(r.task_id) ?? null }));

  const patterns: Json[] = [];
  const recentSeven = incidents.filter((i) => {
    const d = new Date(i.occurred_at || i.created_at || 0).getTime();
    return d > Date.now() - 7 * 24 * 60 * 60 * 1000;
  });
  const byScenario = new Map<string, number>();
  for (const item of recentSeven) {
    const key = String(item.scenario_id || item.title || "incident");
    byScenario.set(key, (byScenario.get(key) || 0) + 1);
  }
  for (const [key, count] of byScenario) {
    if (count >= 2) patterns.push({ type: "repeated_incident", key, count, windowDays: 7 });
  }
  const recentWellbeing = (wellbeing as Json[]).slice(0, 5);
  const heavy = recentWellbeing.filter((w) =>
    ["low", "poor", "tired", "overwhelmed", "exhausted"].includes(String(w.energy_label || w.sleep_label || w.mood_label || "").toLowerCase()),
  ).length;
  if (heavy >= 2) patterns.push({ type: "caregiver_strain", count: heavy, windowCount: recentWellbeing.length });

  const now = Date.now();
  const visibleNotifications = (notifications as Json[]).filter((n) => {
    if (!n.scheduled_for) return true;
    const scheduled = new Date(n.scheduled_for).getTime();
    return Number.isNaN(scheduled) || scheduled <= now;
  });
  const followUp = visibleNotifications.find((n) =>
    n.category === "incident_followup" && !n.opened_at,
  ) ?? null;

  return {
    caregiver,
    patient,
    relationship,
    medications,
    professionalInstructions: instructions,
    recentIncidents: incidents,
    careTasks: tasks,
    privateWellbeing: wellbeing,
    careCircle: circle ? { ...circle, members } : null,
    professionalRoutes: await professionalRoutes(patientId),
    notifications: visibleNotifications,
    notificationPreferences: preferences,
    questionnaires,
    timeline,
    appointments,
    supportSignals,
    taskRequests: requests,
    patterns,
    followUp,
  };
}

async function createCareTask(
  caregiverId: string,
  patientId: string,
  args: Json,
) {
  const title = clean(args.title, 200);
  if (!title) throw new Error("task_title_required");

  const source = ["manual", "routine"].includes(clean(args.source, 40))
    ? clean(args.source, 40)
    : "manual";
  const difficulty = ["light", "moderate", "heavy"].includes(clean(args.difficulty, 40))
    ? clean(args.difficulty, 40)
    : "moderate";
  const effort = Number(args.effortWeight);
  const effortWeight = Number.isFinite(effort) && effort > 0
    ? Math.min(10, effort)
    : 1;
  const recipientProfileId = clean(args.recipientProfileId, 120) || null;

  if (recipientProfileId) {
    const circle = await first(
      `care_circles?select=id&patient_id=eq.${encodeURIComponent(patientId)}&limit=1`,
    );
    if (!circle) throw new Error("care_circle_not_found");
    const member = await first(
      `care_circle_members?select=id&care_circle_id=eq.${circle.id}&profile_id=eq.${encodeURIComponent(recipientProfileId)}&status=eq.active&limit=1`,
    );
    if (!member) throw new Error("recipient_not_in_care_circle");
  }

  const taskRows = await sb("care_tasks", {
    method: "POST",
    headers: { Prefer: "return=representation" },
    body: JSON.stringify({
      patient_id: patientId,
      title,
      description: clean(args.description, 1000) || null,
      source,
      requested_by_profile_id: caregiverId,
      assigned_to_profile_id: recipientProfileId ? null : caregiverId,
      status: recipientProfileId ? "requested" : "open",
      effort_weight: effortWeight,
      difficulty,
      due_at: args.dueAt || null,
      overnight: args.overnight === true,
      metadata: {
        createdBy: "caregiver_app",
        caregiverAdjustedEffort: true,
      },
    }),
  });
  const task = taskRows?.[0] ?? null;
  if (!task?.id) throw new Error("task_creation_failed");

  let request = null;
  if (recipientProfileId) {
    const requestRows = await sb("care_task_requests", {
      method: "POST",
      headers: { Prefer: "return=representation" },
      body: JSON.stringify({
        task_id: task.id,
        requester_profile_id: caregiverId,
        recipient_profile_id: recipientProfileId,
        status: "pending",
        message: clean(args.message, 500) || title,
      }),
    });
    request = requestRows?.[0] ?? null;

    const preferences = await first(
      `notification_preferences?select=enabled,care_circle_requests&caregiver_profile_id=eq.${encodeURIComponent(recipientProfileId)}&limit=1`,
    );
    if (preferences?.enabled !== false && preferences?.care_circle_requests !== false) {
      await sb("caregiver_notifications", {
        method: "POST",
        headers: { Prefer: "return=minimal" },
        body: JSON.stringify({
          caregiver_profile_id: recipientProfileId,
          category: "care_circle_request",
          title: "Care Circle request",
          body: title,
          action_type: "open_care_circle",
          action_payload: {
            requestId: request?.id ?? null,
            taskId: task.id,
          },
          scheduled_for: new Date().toISOString(),
        }),
      });
    }
  }

  return { task, request };
}

async function respondTask(caregiverId: string, requestId: string, args: Json) {
  const request = await first(
    `care_task_requests?select=*&id=eq.${encodeURIComponent(requestId)}&recipient_profile_id=eq.${encodeURIComponent(caregiverId)}&limit=1`,
  );
  if (!request) throw new Error("task_request_not_found");
  if (request.status !== "pending") throw new Error("task_request_already_resolved");

  const response = clean(args.response, 40);
  if (!["accepted", "declined", "alternative"].includes(response)) throw new Error("invalid_task_response");

  const storedStatus = response === "alternative" ? "alternative_proposed" : response;
  const patch: Json = {
    status: storedStatus,
    responded_at: new Date().toISOString(),
  };
  if (response === "alternative") {
    patch.alternative_note = clean(args.alternativeNote, 500) || "Alternative proposed";
    patch.alternative_starts_at = args.alternativeStartsAt || null;
  }

  const rows = await sb(`care_task_requests?id=eq.${encodeURIComponent(requestId)}`, {
    method: "PATCH",
    headers: { Prefer: "return=representation" },
    body: JSON.stringify(patch),
  });

  if (response === "accepted") {
    await sb(`care_tasks?id=eq.${encodeURIComponent(request.task_id)}`, {
      method: "PATCH",
      headers: { Prefer: "return=minimal" },
      body: JSON.stringify({ status: "accepted", assigned_to_profile_id: caregiverId, updated_at: new Date().toISOString() }),
    });
  }

  return rows?.[0] ?? null;
}

function scoreQuestion(answer: unknown, rule: Json) {
  const scores = (rule?.scores || rule?.option_scores || rule?.optionScores) as Json | undefined;
  if (scores && answer != null && Object.prototype.hasOwnProperty.call(scores, String(answer))) {
    const value = Number(scores[String(answer)]);
    return Number.isFinite(value) ? value : 0;
  }
  if (typeof answer === "number" && Number.isFinite(answer)) {
    const multiplier = Number(rule?.multiplier ?? 1);
    return answer * (Number.isFinite(multiplier) ? multiplier : 1);
  }
  if (typeof answer === "boolean") {
    const trueScore = Number(rule?.true ?? rule?.true_score ?? 1);
    const falseScore = Number(rule?.false ?? rule?.false_score ?? 0);
    return answer
      ? (Number.isFinite(trueScore) ? trueScore : 1)
      : (Number.isFinite(falseScore) ? falseScore : 0);
  }
  return 0;
}

function interpretScore(score: number, config: Json) {
  const bands = Array.isArray(config?.bands) ? config.bands : [];
  for (const band of bands) {
    const min = Number(band?.min ?? Number.NEGATIVE_INFINITY);
    const max = Number(band?.max ?? Number.POSITIVE_INFINITY);
    if (score >= min && score <= max) {
      return {
        key: clean(band?.key, 120) || null,
        text: clean(band?.text, 1200) || null,
        trendLabel: clean(band?.trend_label ?? band?.trendLabel, 120) || null,
        requiresProfessionalSupport: band?.requires_professional_support === true ||
          band?.requiresProfessionalSupport === true,
      };
    }
  }
  return {
    key: null,
    text: null,
    trendLabel: null,
    requiresProfessionalSupport: false,
  };
}

async function getQuestionnaire(versionId: string) {
  const version = await first(
    `questionnaire_versions?select=id,questionnaire_id,version_label,language,validation_status,validation_reference,scoring_config,interpretation_config,active&id=eq.${encodeURIComponent(versionId)}&active=eq.true&validation_status=eq.validated&limit=1`,
  );
  if (!version) throw new Error("validated_questionnaire_not_found");
  const definition = await first(
    `questionnaire_definitions?select=id,code,name,purpose,owner,active&id=eq.${encodeURIComponent(version.questionnaire_id)}&active=eq.true&limit=1`,
  );
  const questions = await sb(
    `questionnaire_questions?select=id,display_order,prompt,response_type,options,scoring_rule,required&version_id=eq.${encodeURIComponent(versionId)}&order=display_order.asc`,
  );
  return { version, definition, questions };
}

async function submitQuestionnaire(
  caregiverId: string,
  patientId: string,
  versionId: string,
  answers: Json[],
) {
  const questionnaire = await getQuestionnaire(versionId);
  const questions = questionnaire.questions as Json[];
  const answerMap = new Map(answers.map((a) => [clean(a.questionId, 120), a.answer]));

  for (const question of questions) {
    if (question.required === true && !answerMap.has(String(question.id))) {
      throw new Error("required_question_missing");
    }
  }

  const sessionRows = await sb("questionnaire_sessions", {
    method: "POST",
    headers: { Prefer: "return=representation" },
    body: JSON.stringify({
      version_id: versionId,
      caregiver_profile_id: caregiverId,
      patient_id: patientId,
      trigger_type: "manual",
      status: "in_progress",
      started_at: new Date().toISOString(),
    }),
  });
  const session = sessionRows?.[0];
  if (!session?.id) throw new Error("questionnaire_session_failed");

  const answerRows = questions
    .filter((q) => answerMap.has(String(q.id)))
    .map((q) => ({
      session_id: session.id,
      question_id: q.id,
      answer: { value: answerMap.get(String(q.id)) },
    }));
  if (answerRows.length) {
    await sb("questionnaire_answers", {
      method: "POST",
      headers: { Prefer: "return=minimal" },
      body: JSON.stringify(answerRows),
    });
  }

  let score = 0;
  let hasScoring = false;
  for (const question of questions) {
    if (!answerMap.has(String(question.id))) continue;
    const rule = question.scoring_rule && typeof question.scoring_rule === "object"
      ? question.scoring_rule
      : {};
    if (Object.keys(rule).length) hasScoring = true;
    score += scoreQuestion(answerMap.get(String(question.id)), rule);
  }

  const interpretation = hasScoring
    ? interpretScore(score, questionnaire.version.interpretation_config || {})
    : {
        key: null,
        text: null,
        trendLabel: null,
        requiresProfessionalSupport: false,
      };

  const resultRows = await sb("questionnaire_results", {
    method: "POST",
    headers: { Prefer: "return=representation" },
    body: JSON.stringify({
      session_id: session.id,
      raw_score: hasScoring ? score : null,
      interpretation_key: interpretation.key,
      interpretation_text: interpretation.text,
      trend_label: interpretation.trendLabel,
      requires_professional_support: interpretation.requiresProfessionalSupport,
    }),
  });

  await sb(`questionnaire_sessions?id=eq.${encodeURIComponent(session.id)}`, {
    method: "PATCH",
    headers: { Prefer: "return=minimal" },
    body: JSON.stringify({
      status: "completed",
      completed_at: new Date().toISOString(),
    }),
  });

  return {
    session: { ...session, status: "completed" },
    result: resultRows?.[0] ?? null,
    interpretationOnly: true,
  };
}

async function updateAppPreferences(caregiverId: string, args: Json) {
  const current = await first(
    `profiles?select=id,preferred_language,metadata&id=eq.${encodeURIComponent(caregiverId)}&limit=1`,
  );
  if (!current) throw new Error("caregiver_profile_not_found");

  const metadata = current.metadata && typeof current.metadata === "object"
    ? { ...current.metadata }
    : {};
  const existing = metadata.app_preferences && typeof metadata.app_preferences === "object"
    ? { ...metadata.app_preferences }
    : {};

  const requested = clean(args.language, 20).toLowerCase();
  const preferredLanguage =
    requested === "tn" ? "derja" :
    ["ar", "fr", "en"].includes(requested) ? requested :
    current.preferred_language || "derja";

  metadata.app_preferences = {
    ...existing,
    language: requested || existing.language || preferredLanguage,
    show_hani_widget: args.showHaniWidget !== false,
    show_patient_widget: args.showPatientWidget !== false,
    show_care_load_widget: args.showCareLoadWidget !== false,
    show_wellbeing_widget: args.showWellbeingWidget !== false,
  };

  const rows = await sb(
    `profiles?id=eq.${encodeURIComponent(caregiverId)}`,
    {
      method: "PATCH",
      headers: { Prefer: "return=representation" },
      body: JSON.stringify({
        preferred_language: preferredLanguage,
        metadata,
        updated_at: new Date().toISOString(),
      }),
    },
  );
  return rows?.[0] ?? null;
}

async function updatePreferences(caregiverId: string, args: Json) {
  const payload: Json = {
    caregiver_profile_id: caregiverId,
    enabled: args.enabled !== false,
    incident_followup: args.incidentFollowup !== false,
    wellbeing_checkin: args.wellbeingCheckin !== false,
    care_circle_requests: args.careCircleRequests !== false,
    appointments: args.appointments !== false,
    hydration: args.hydration === true,
    nutrition: args.nutrition === true,
    sleep: args.sleep === true,
    movement: args.movement === true,
    breathing: args.breathing === true,
    social_connection: args.socialConnection === true,
    quiet_hours_start: args.quietHours === false ? null : clean(args.quietHoursStart, 8) || "22:00",
    quiet_hours_end: args.quietHours === false ? null : clean(args.quietHoursEnd, 8) || "07:00",
    updated_at: new Date().toISOString(),
  };
  const rows = await sb("notification_preferences?on_conflict=caregiver_profile_id", {
    method: "POST",
    headers: { Prefer: "resolution=merge-duplicates,return=representation" },
    body: JSON.stringify(payload),
  });
  return rows?.[0] ?? null;
}

export async function GET(req: Request) {
  try {
    const url = new URL(req.url);
    const caregiverId = clean(url.searchParams.get("caregiverId"), 120);
    const patientId = clean(url.searchParams.get("patientId"), 120);
    if (!caregiverId || !patientId) return json({ error: "caregiver_and_patient_required" }, { status: 400 });
    await verifyIdentity(req, caregiverId, patientId);
    return json({ success: true, data: await loadContext(caregiverId, patientId) });
  } catch (error) {
    const message = error instanceof Error ? error.message : "caregiver_context_failed";
    const status = /authentication|session|identity|access_denied/.test(message) ? 401 : /not_found/.test(message) ? 404 : 500;
    console.error("Caregiver app context failed", message);
    return json({ success: false, error: message }, { status });
  }
}

export async function POST(req: Request) {
  try {
    const body = await req.json().catch(() => ({}));
    const caregiverId = clean(body.caregiverId, 120);
    const patientId = clean(body.patientId, 120);
    const action = clean(body.action, 80);
    const args = (body.args && typeof body.args === "object" ? body.args : {}) as Json;
    if (!caregiverId || !patientId) return json({ error: "caregiver_and_patient_required" }, { status: 400 });
    await verifyIdentity(req, caregiverId, patientId);

    if (action === "get_questionnaire") {
      const versionId = clean(args.versionId, 120);
      if (!versionId) return json({ error: "questionnaire_version_required" }, { status: 400 });
      return json({ success: true, questionnaire: await getQuestionnaire(versionId) });
    }
    if (action === "submit_questionnaire") {
      const versionId = clean(args.versionId, 120);
      const answers = Array.isArray(args.answers) ? args.answers as Json[] : [];
      if (!versionId) return json({ error: "questionnaire_version_required" }, { status: 400 });
      return json({
        success: true,
        ...(await submitQuestionnaire(caregiverId, patientId, versionId, answers)),
      });
    }
    if (action === "record_wellbeing_checkin") {
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
          source: "manual",
        }),
      });
      return json({ success: true, checkin: rows?.[0] ?? null, private: true });
    }
    if (action === "create_care_task") {
      return json({
        success: true,
        ...(await createCareTask(caregiverId, patientId, args)),
      });
    }
    if (action === "respond_task_request") {
      return json({ success: true, request: await respondTask(caregiverId, clean(args.requestId, 120), args) });
    }
    if (action === "update_notification_preferences") {
      return json({ success: true, preferences: await updatePreferences(caregiverId, args) });
    }
    if (action === "update_app_preferences") {
      return json({ success: true, profile: await updateAppPreferences(caregiverId, args) });
    }
    if (action === "open_notification") {
      const id = clean(args.notificationId, 120);
      const rows = await sb(
        `caregiver_notifications?id=eq.${encodeURIComponent(id)}&caregiver_profile_id=eq.${encodeURIComponent(caregiverId)}`,
        {
          method: "PATCH",
          headers: { Prefer: "return=representation" },
          body: JSON.stringify({ opened_at: new Date().toISOString() }),
        },
      );
      return json({ success: true, notification: rows?.[0] ?? null });
    }

    return json({ error: "unsupported_action" }, { status: 400 });
  } catch (error) {
    const message = error instanceof Error ? error.message : "caregiver_action_failed";
    const status = /authentication|session|identity|access_denied/.test(message) ? 401 : /not_found/.test(message) ? 404 : /invalid|already/.test(message) ? 400 : 500;
    console.error("Caregiver app action failed", message);
    return json({ success: false, error: message }, { status });
  }
}
