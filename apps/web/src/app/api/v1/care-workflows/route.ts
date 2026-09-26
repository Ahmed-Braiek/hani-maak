import { createSign } from "node:crypto";
import { NextResponse } from "next/server";
import {
  caregiverAuthStatus,
  DEMO_CAREGIVER_ID,
  DEMO_PATIENT_ID,
  verifyCaregiverAccess,
} from "@/lib/caregiver-access";

export const dynamic = "force-dynamic";
export const maxDuration = 60;

type Json = Record<string, any>;

const supabaseUrl = (
  process.env.SUPABASE_URL ||
  process.env.NEXT_PUBLIC_SUPABASE_URL
)?.replace(/\/$/, "");
const supabaseKey =
  process.env.SUPABASE_SECRET_KEY ||
  process.env.SUPABASE_SERVICE_ROLE_KEY;

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST,OPTIONS",
  "Access-Control-Allow-Headers": "authorization,content-type",
  "Access-Control-Max-Age": "86400",
};

function response(body: unknown, init?: ResponseInit) {
  const result = NextResponse.json(body, init);
  for (const [key, value] of Object.entries(cors)) {
    result.headers.set(key, value);
  }
  return result;
}

export async function OPTIONS() {
  return new Response(null, { status: 204, headers: cors });
}

function clean(value: unknown, max = 1400) {
  return String(value ?? "").trim().slice(0, max);
}

function headers(extra: Record<string, string> = {}) {
  if (!supabaseKey) throw new Error("supabase_secret_missing");
  const result: Record<string, string> = {
    apikey: supabaseKey,
    "content-type": "application/json",
    ...extra,
  };
  if (
    !supabaseKey.startsWith("sb_secret_") &&
    !supabaseKey.startsWith("sb_publishable_")
  ) {
    result.Authorization = `Bearer ${supabaseKey}`;
  }
  return result;
}

async function sb(path: string, init: RequestInit = {}) {
  if (!supabaseUrl || !supabaseKey) {
    throw new Error("supabase_not_configured");
  }
  const res = await fetch(`${supabaseUrl}/rest/v1/${path}`, {
    ...init,
    headers: {
      ...headers(),
      ...(init.headers as Record<string, string> | undefined),
    },
    cache: "no-store",
  });
  const raw = await res.text();
  const body = raw ? JSON.parse(raw) : null;
  if (!res.ok) {
    throw new Error(
      body?.message || body?.error || `supabase_http_${res.status}`,
    );
  }
  return body;
}

async function first(path: string) {
  const rows = await sb(path);
  return Array.isArray(rows) ? rows[0] ?? null : null;
}

async function analyzeMedicationImage(args: Json) {
  const base = process.env.HENI_AGENT_BASE_URL?.trim().replace(/\/$/, "");
  const secret = process.env.HENI_AGENT_SHARED_SECRET;
  if (!base || !secret) {
    throw new Error("medication_ocr_not_configured");
  }

  const imageDataUrl = clean(args.imageDataUrl, 10_500_000);
  if (!imageDataUrl.startsWith("data:image/")) {
    throw new Error("medication_image_required");
  }

  const res = await fetch(`${base}/v1/ocr/medication`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-heni-agent-key": secret,
    },
    body: JSON.stringify({
      imageDataUrl,
      mode:
        args.mode === "medication_box"
          ? "medication_box"
          : "prescription",
    }),
    cache: "no-store",
    signal: AbortSignal.timeout(50_000),
  });

  const raw = await res.text();
  const body = raw ? JSON.parse(raw) : null;
  if (!res.ok) {
    throw new Error(
      body?.detail || body?.error || `medication_ocr_http_${res.status}`,
    );
  }
  return body;
}

async function saveMedication(
  caregiverId: string,
  patientId: string,
  args: Json,
) {
  const medicationName = clean(args.medicationName, 180);
  if (!medicationName) throw new Error("medication_name_required");

  const existingId = clean(args.medicationId, 120);
  const payload = {
    patient_id: patientId,
    medication_name: medicationName,
    dose_text: clean(args.doseText, 180) || null,
    schedule_text: clean(args.frequencyText, 240) || null,
    instructions: clean(args.instructions, 900) || null,
    verified: false,
    active: true,
    starts_on: clean(args.startsOn, 20) || null,
    ends_on: clean(args.endsOn, 20) || null,
    external_ids: {
      source: clean(args.source, 60) || "manual",
      reviewedByCaregiver: true,
      caregiverProfileId: caregiverId,
      durationText: clean(args.durationText, 180) || null,
    },
    updated_at: new Date().toISOString(),
  };

  let medication: Json | null = null;
  if (existingId) {
    const rows = await sb(
      `patient_medications?id=eq.${encodeURIComponent(existingId)}&patient_id=eq.${encodeURIComponent(patientId)}`,
      {
        method: "PATCH",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify(payload),
      },
    );
    medication = rows?.[0] ?? null;
  } else {
    const rows = await sb("patient_medications", {
      method: "POST",
      headers: { Prefer: "return=representation" },
      body: JSON.stringify(payload),
    });
    medication = rows?.[0] ?? null;
  }

  if (!medication?.id) throw new Error("medication_save_failed");

  const times = Array.isArray(args.times)
    ? args.times.map((value: unknown) => clean(value, 8)).filter(Boolean)
    : [];
  const scheduledTimes = Array.isArray(args.scheduledTimes)
    ? args.scheduledTimes
        .map((value: unknown) => clean(value, 40))
        .filter(Boolean)
        .slice(0, 42)
    : [];

  let schedule: Json | null = null;
  if (times.length) {
    const oldSchedules = (await sb(
      `medication_schedules?select=id&patient_medication_id=eq.${encodeURIComponent(medication.id)}&active=eq.true`,
    )) as Json[];

    if (oldSchedules.length) {
      await sb(
        `medication_schedules?patient_medication_id=eq.${encodeURIComponent(medication.id)}&active=eq.true`,
        {
          method: "PATCH",
          headers: { Prefer: "return=minimal" },
          body: JSON.stringify({
            active: false,
            updated_at: new Date().toISOString(),
          }),
        },
      );
    }

    const scheduleRows = await sb("medication_schedules", {
      method: "POST",
      headers: { Prefer: "return=representation" },
      body: JSON.stringify({
        patient_medication_id: medication.id,
        patient_id: patientId,
        created_by_profile_id: caregiverId,
        timezone: clean(args.timezone, 80) || "Africa/Tunis",
        times,
        reminder_minutes_before:
          Number.isFinite(Number(args.reminderMinutesBefore))
            ? Math.max(0, Math.min(240, Number(args.reminderMinutesBefore)))
            : 0,
        starts_on: clean(args.startsOn, 20) || null,
        ends_on: clean(args.endsOn, 20) || null,
        notes: clean(args.scheduleNotes, 500) || null,
      }),
    });
    schedule = scheduleRows?.[0] ?? null;
  }

  if (scheduledTimes.length) {
    await sb(
      `medication_events?patient_medication_id=eq.${encodeURIComponent(medication.id)}&status=eq.pending`,
      { method: "DELETE", headers: { Prefer: "return=minimal" } },
    );

    await sb("medication_events", {
      method: "POST",
      headers: { Prefer: "return=minimal" },
      body: JSON.stringify(
        scheduledTimes.map((scheduledFor: string) => ({
          patient_medication_id: medication.id,
          patient_id: patientId,
          caregiver_profile_id: caregiverId,
          scheduled_for: scheduledFor,
          status: "pending",
          source: "caregiver_app",
        })),
      ),
    });
  }

  return { medication, schedule };
}

async function recordMedicationEvent(
  caregiverId: string,
  patientId: string,
  args: Json,
) {
  const eventId = clean(args.eventId, 120);
  const status = clean(args.status, 30);
  if (!eventId) throw new Error("medication_event_required");
  if (!["taken", "skipped", "delayed"].includes(status)) {
    throw new Error("invalid_medication_event_status");
  }

  const event = await first(
    `medication_events?select=id,patient_id,patient_medication_id,scheduled_for,status&id=eq.${encodeURIComponent(eventId)}&patient_id=eq.${encodeURIComponent(patientId)}&limit=1`,
  );
  if (!event) throw new Error("medication_event_not_found");

  const rows = await sb(
    `medication_events?id=eq.${encodeURIComponent(eventId)}`,
    {
      method: "PATCH",
      headers: { Prefer: "return=representation" },
      body: JSON.stringify({
        caregiver_profile_id: caregiverId,
        status,
        actual_at: status === "delayed" ? null : new Date().toISOString(),
        note: clean(args.note, 500) || null,
        updated_at: new Date().toISOString(),
      }),
    },
  );

  await sb("timeline_events", {
    method: "POST",
    headers: { Prefer: "return=minimal" },
    body: JSON.stringify({
      patient_id: patientId,
      event_type: "medication",
      title:
        status === "taken"
          ? "Medication marked taken"
          : status === "skipped"
            ? "Medication marked skipped"
            : "Medication delayed",
      summary: clean(args.note, 500) || null,
      occurred_at: new Date().toISOString(),
      source_type: "medication_event",
      source_id: eventId,
      created_by_profile_id: caregiverId,
      visible_to_care_circle: true,
    }),
  });

  return rows?.[0] ?? null;
}

async function saveDocument(
  caregiverId: string,
  patientId: string,
  args: Json,
) {
  const documentType = clean(args.documentType, 40);
  if (
    !["prescription", "medication_box", "lab", "care_plan", "other"].includes(
      documentType,
    )
  ) {
    throw new Error("invalid_document_type");
  }

  const rows = await sb("care_documents", {
    method: "POST",
    headers: { Prefer: "return=representation" },
    body: JSON.stringify({
      patient_id: patientId,
      uploaded_by_profile_id: caregiverId,
      document_type: documentType,
      title: clean(args.title, 200) || "Care document",
      original_file_name: clean(args.fileName, 260) || null,
      extracted_text: clean(args.extractedText, 8000) || null,
      extraction_json:
        args.extraction && typeof args.extraction === "object"
          ? args.extraction
          : {},
      reviewed: args.reviewed === true,
    }),
  });
  return rows?.[0] ?? null;
}

async function recordActivity(
  caregiverId: string,
  patientId: string,
  args: Json,
) {
  const activityType = clean(args.activityType, 80) || "reminiscence";
  const memoryItemId = clean(args.memoryItemId, 120) || null;
  const rows = await sb("patient_activity_sessions", {
    method: "POST",
    headers: { Prefer: "return=representation" },
    body: JSON.stringify({
      patient_id: patientId,
      caregiver_profile_id: caregiverId,
      memory_item_id: memoryItemId,
      activity_type: activityType,
      started_at: clean(args.startedAt, 40) || new Date().toISOString(),
      ended_at: clean(args.endedAt, 40) || new Date().toISOString(),
      response_label: clean(args.responseLabel, 80) || null,
      note: clean(args.note, 800) || null,
      metadata:
        args.metadata && typeof args.metadata === "object"
          ? args.metadata
          : {},
    }),
  });
  return rows?.[0] ?? null;
}

async function registerDeviceToken(caregiverId: string, args: Json) {
  const token = clean(args.token, 4096);
  const platform = clean(args.platform, 20);
  if (!token) throw new Error("device_token_required");
  if (!["android", "ios", "web"].includes(platform)) {
    throw new Error("invalid_device_platform");
  }

  const rows = await sb("device_push_tokens?on_conflict=caregiver_profile_id,token", {
    method: "POST",
    headers: { Prefer: "resolution=merge-duplicates,return=representation" },
    body: JSON.stringify({
      caregiver_profile_id: caregiverId,
      platform,
      token,
      enabled: true,
      last_seen_at: new Date().toISOString(),
      metadata:
        args.metadata && typeof args.metadata === "object"
          ? args.metadata
          : {},
    }),
  });
  return rows?.[0] ?? null;
}

function b64url(value: string | Buffer) {
  return Buffer.from(value).toString("base64url");
}

async function googleAccessToken() {
  const clientEmail = process.env.FCM_CLIENT_EMAIL;
  const privateKey = process.env.FCM_PRIVATE_KEY?.replace(/\\n/g, "\n");
  if (!clientEmail || !privateKey) return null;

  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = b64url(
    JSON.stringify({
      iss: clientEmail,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }),
  );
  const unsigned = `${header}.${claim}`;
  const signer = createSign("RSA-SHA256");
  signer.update(unsigned);
  signer.end();
  const assertion = `${unsigned}.${signer.sign(privateKey, "base64url")}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  const body = await res.json();
  if (!res.ok || !body.access_token) {
    throw new Error("fcm_oauth_failed");
  }
  return String(body.access_token);
}

async function sendPush(
  caregiverId: string,
  args: Json,
) {
  const projectId = process.env.FCM_PROJECT_ID;
  const accessToken = await googleAccessToken();
  if (!projectId || !accessToken) {
    return {
      status: "configuration_required",
      missing: [
        !projectId ? "FCM_PROJECT_ID" : null,
        !process.env.FCM_CLIENT_EMAIL ? "FCM_CLIENT_EMAIL" : null,
        !process.env.FCM_PRIVATE_KEY ? "FCM_PRIVATE_KEY" : null,
      ].filter(Boolean),
    };
  }

  const tokens = (await sb(
    `device_push_tokens?select=token,platform&caregiver_profile_id=eq.${encodeURIComponent(caregiverId)}&enabled=eq.true&order=last_seen_at.desc&limit=10`,
  )) as Json[];
  if (!tokens.length) {
    return { status: "no_registered_device" };
  }

  const title = clean(args.title, 140) || "Hani Maak";
  const body = clean(args.body, 700);
  const route = clean(args.route, 200) || "/today";

  const deliveries = [];
  for (const item of tokens) {
    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(projectId)}/messages:send`,
      {
        method: "POST",
        headers: {
          authorization: `Bearer ${accessToken}`,
          "content-type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token: item.token,
            notification: { title, body },
            data: { route },
            android: {
              priority: "high",
              notification: {
                channel_id: "hani_care",
                click_action: "FLUTTER_NOTIFICATION_CLICK",
              },
            },
          },
        }),
      },
    );
    const result = await res.json();
    deliveries.push({
      tokenSuffix: String(item.token).slice(-8),
      ok: res.ok,
      result,
    });
  }
  return { status: "sent", deliveries };
}

async function buildSummary(
  caregiverId: string,
  patientId: string,
  summaryType: string,
) {
  const patient = await first(
    `patients?select=display_name,preferred_name&id=eq.${encodeURIComponent(patientId)}&limit=1`,
  );
  const [medEvents, appointments, tasks, timeline] = await Promise.all([
    sb(
      `medication_events?select=status,scheduled_for,actual_at,patient_medication_id&patient_id=eq.${encodeURIComponent(patientId)}&scheduled_for=gte.${encodeURIComponent(new Date(Date.now() - 7 * 86400000).toISOString())}&order=scheduled_for.desc&limit=50`,
    ),
    sb(
      `caregiver_appointments?select=scheduled_for,reason,status&patient_id=eq.${encodeURIComponent(patientId)}&order=scheduled_for.asc&limit=10`,
    ),
    sb(
      `care_tasks?select=title,status,due_at,difficulty&patient_id=eq.${encodeURIComponent(patientId)}&order=due_at.asc.nullslast&limit=20`,
    ),
    sb(
      `timeline_events?select=event_type,title,summary,occurred_at&patient_id=eq.${encodeURIComponent(patientId)}&visible_to_care_circle=eq.true&order=occurred_at.desc&limit=10`,
    ),
  ]);

  const events = medEvents as Json[];
  const taken = events.filter((item) => item.status === "taken").length;
  const skipped = events.filter((item) => item.status === "skipped").length;
  const delayed = events.filter((item) => item.status === "delayed").length;
  const openTasks = (tasks as Json[]).filter(
    (item) => !["completed", "cancelled"].includes(item.status),
  );
  const upcomingAppointments = (appointments as Json[]).filter(
    (item) => new Date(item.scheduled_for).getTime() >= Date.now(),
  );

  const name =
    patient?.preferred_name ||
    patient?.display_name ||
    "Patient";

  const lines = [
    `Hani Maak · ${summaryType === "weekly" ? "Weekly" : "Daily"} care summary for ${name}`,
    "",
    `Medication activity: ${taken} taken · ${skipped} skipped · ${delayed} delayed in the recorded period.`,
    upcomingAppointments[0]
      ? `Next appointment: ${new Date(upcomingAppointments[0].scheduled_for).toLocaleString("en-GB", { timeZone: "Africa/Tunis" })} · ${upcomingAppointments[0].reason || "Follow-up"}.`
      : "Next appointment: none currently scheduled.",
    `Open care tasks: ${openTasks.length}.`,
    ...(timeline as Json[]).slice(0, 3).map(
      (item) =>
        `Update: ${clean(item.title, 180)}${item.summary ? ` — ${clean(item.summary, 260)}` : ""}`,
    ),
    "",
    "This summary contains shared care information only. Private caregiver wellbeing and private Hani conversations are excluded.",
  ];

  return lines.join("\n");
}

async function createSummaryDelivery(
  caregiverId: string,
  patientId: string,
  args: Json,
) {
  const summaryType =
    clean(args.summaryType, 20) === "weekly" ? "weekly" : "daily";
  const summary = await buildSummary(caregiverId, patientId, summaryType);
  const recipient = clean(args.recipient, 40).replace(/[^0-9+]/g, "");
  const send = args.send === true;

  if (!send) {
    const rows = await sb("summary_deliveries", {
      method: "POST",
      headers: { Prefer: "return=representation" },
      body: JSON.stringify({
        caregiver_profile_id: caregiverId,
        patient_id: patientId,
        channel: "preview",
        recipient: recipient || null,
        summary_type: summaryType,
        status: "prepared",
        summary_text: summary,
      }),
    });
    return {
      delivery: rows?.[0] ?? null,
      summary,
      status: "prepared",
    };
  }

  if (!/^\+?[1-9]\d{7,14}$/.test(recipient)) {
    throw new Error("valid_whatsapp_recipient_required");
  }

  const accessToken = process.env.WHATSAPP_CLOUD_ACCESS_TOKEN;
  const phoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID;
  const graphVersion = process.env.WHATSAPP_GRAPH_VERSION || "v23.0";

  if (!accessToken || !phoneNumberId) {
    const rows = await sb("summary_deliveries", {
      method: "POST",
      headers: { Prefer: "return=representation" },
      body: JSON.stringify({
        caregiver_profile_id: caregiverId,
        patient_id: patientId,
        channel: "whatsapp",
        recipient,
        summary_type: summaryType,
        status: "configuration_required",
        summary_text: summary,
        error: "WhatsApp Business Cloud API credentials are not configured.",
      }),
    });
    return {
      delivery: rows?.[0] ?? null,
      summary,
      status: "configuration_required",
      missing: [
        !accessToken ? "WHATSAPP_CLOUD_ACCESS_TOKEN" : null,
        !phoneNumberId ? "WHATSAPP_PHONE_NUMBER_ID" : null,
      ].filter(Boolean),
    };
  }

  const wa = await fetch(
    `https://graph.facebook.com/${graphVersion}/${encodeURIComponent(phoneNumberId)}/messages`,
    {
      method: "POST",
      headers: {
        authorization: `Bearer ${accessToken}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        messaging_product: "whatsapp",
        to: recipient.replace(/^\+/, ""),
        type: "text",
        text: {
          preview_url: false,
          body: summary,
        },
      }),
    },
  );
  const waBody = await wa.json();
  const sent = wa.ok && Array.isArray(waBody?.messages);

  const rows = await sb("summary_deliveries", {
    method: "POST",
    headers: { Prefer: "return=representation" },
    body: JSON.stringify({
      caregiver_profile_id: caregiverId,
      patient_id: patientId,
      channel: "whatsapp",
      recipient,
      summary_type: summaryType,
      status: sent ? "sent" : "failed",
      summary_text: summary,
      provider_message_id: waBody?.messages?.[0]?.id ?? null,
      provider_response: waBody ?? {},
      error: sent ? null : clean(waBody?.error?.message, 900) || "whatsapp_send_failed",
      sent_at: sent ? new Date().toISOString() : null,
    }),
  });

  return {
    delivery: rows?.[0] ?? null,
    summary,
    status: sent ? "sent" : "failed",
    provider: waBody,
  };
}

export async function POST(req: Request) {
  try {
    const body = await req.json().catch(() => ({}));
    const caregiverId = clean(body.caregiverId, 120) || DEMO_CAREGIVER_ID;
    const patientId = clean(body.patientId, 120) || DEMO_PATIENT_ID;
    const action = clean(body.action, 80);
    const args =
      body.args && typeof body.args === "object"
        ? (body.args as Json)
        : {};

    await verifyCaregiverAccess(req, caregiverId, patientId);

    if (action === "analyze_medication_image") {
      return response({
        success: true,
        extraction: await analyzeMedicationImage(args),
      });
    }
    if (action === "save_medication") {
      return response({
        success: true,
        ...(await saveMedication(caregiverId, patientId, args)),
      });
    }
    if (action === "record_medication_event") {
      return response({
        success: true,
        event: await recordMedicationEvent(
          caregiverId,
          patientId,
          args,
        ),
      });
    }
    if (action === "save_document") {
      return response({
        success: true,
        document: await saveDocument(caregiverId, patientId, args),
      });
    }
    if (action === "record_patient_activity") {
      return response({
        success: true,
        session: await recordActivity(caregiverId, patientId, args),
      });
    }
    if (action === "register_device_token") {
      return response({
        success: true,
        device: await registerDeviceToken(caregiverId, args),
      });
    }
    if (action === "send_push") {
      return response({
        success: true,
        push: await sendPush(caregiverId, args),
      });
    }
    if (
      action === "prepare_summary" ||
      action === "send_whatsapp_summary"
    ) {
      return response({
        success: true,
        ...(await createSummaryDelivery(
          caregiverId,
          patientId,
          {
            ...args,
            send: action === "send_whatsapp_summary",
          },
        )),
      });
    }

    return response({ error: "unsupported_action" }, { status: 400 });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "care_workflow_failed";
    const status = caregiverAuthStatus(error);
    console.error("Care workflow failed", message);
    return response(
      { success: false, error: message },
      {
        status:
          status !== 500
            ? status
            : /required|invalid|unsupported|too_large/.test(message)
              ? 400
              : /not_found/.test(message)
                ? 404
                : 500,
      },
    );
  }
}
