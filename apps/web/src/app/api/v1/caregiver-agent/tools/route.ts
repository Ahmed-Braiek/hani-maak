import { timingSafeEqual } from "node:crypto";
import dns from "node:dns";
import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

if (process.env.NODE_ENV !== "production") {
  dns.setDefaultResultOrder("ipv4first");
}

type Json = Record<string, any>;

const supabaseUrl = (process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL)?.replace(/\/$/, "");
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

type InteractionQuestion = {
  question_key: string;
  prompt_i18n: Record<string, string>;
  response_type: string;
  required: boolean;
  display_order: number;
};

const SAFE_INTERACTION_SHELLS: Record<string, InteractionQuestion[]> = {
  refusal_to_eat: [
    {
      question_key: "what_changed",
      prompt_i18n: {
        derja: "شنوّة تبدّل في الأكل اليوم؟",
        ar: "ما الذي تغير في الأكل اليوم؟",
        fr: "Qu’est-ce qui a changé autour du repas aujourd’hui ?",
        en: "What changed around eating today?",
      },
      response_type: "text",
      required: true,
      display_order: 1,
    },
    {
      question_key: "how_long",
      prompt_i18n: {
        derja: "من وقتاش صار الرفض؟",
        ar: "منذ متى بدأ الرفض؟",
        fr: "Depuis quand ce refus a-t-il commencé ?",
        en: "When did the refusal start?",
      },
      response_type: "text",
      required: false,
      display_order: 2,
    },
  ],
  refusal_to_bathe: [
    {
      question_key: "what_happens",
      prompt_i18n: {
        derja: "شنوّة يصير بالضبط كي تقترح الحمّام؟",
        ar: "ماذا يحدث بالضبط عندما تقترح الاستحمام؟",
        fr: "Que se passe-t-il exactement quand vous proposez la toilette ?",
        en: "What happens exactly when you suggest bathing?",
      },
      response_type: "text",
      required: true,
      display_order: 1,
    },
  ],
  agitation_aggression: [
    {
      question_key: "immediate_safety",
      prompt_i18n: {
        derja: "توا فما خطر مباشر على أي شخص؟",
        ar: "هل يوجد خطر مباشر على أي شخص الآن؟",
        fr: "Y a-t-il un danger immédiat pour quelqu’un maintenant ?",
        en: "Is anyone in immediate danger right now?",
      },
      response_type: "boolean",
      required: true,
      display_order: 1,
    },
    {
      question_key: "before_it_started",
      prompt_i18n: {
        derja: "شنوّة صار قبل ما يبدأ التوتر؟",
        ar: "ماذا حدث قبل أن يبدأ التوتر؟",
        fr: "Que s’est-il passé juste avant l’agitation ?",
        en: "What happened just before the agitation started?",
      },
      response_type: "text",
      required: false,
      display_order: 2,
    },
  ],
  repeated_questions: [
    {
      question_key: "question_pattern",
      prompt_i18n: {
        derja: "شنوّة السؤال اللي يتعاود، ووقتاش أكثر حاجة؟",
        ar: "ما السؤال الذي يتكرر ومتى يحدث غالبًا؟",
        fr: "Quelle question se répète et à quel moment surtout ?",
        en: "What question repeats, and when does it happen most?",
      },
      response_type: "text",
      required: true,
      display_order: 1,
    },
  ],
  sleep_problems: [
    {
      question_key: "night_pattern",
      prompt_i18n: {
        derja: "شنوّة صار في الليل وشنوّة تبدّل على العادة؟",
        ar: "ماذا حدث ليلًا وما الذي تغير عن المعتاد؟",
        fr: "Que s’est-il passé cette nuit et qu’est-ce qui diffère de l’habitude ?",
        en: "What happened overnight, and what was different from usual?",
      },
      response_type: "text",
      required: true,
      display_order: 1,
    },
  ],
  wandering: [
    {
      question_key: "located_now",
      prompt_i18n: {
        derja: "الشخص موجود ومأمون توا؟",
        ar: "هل الشخص موجود وفي أمان الآن؟",
        fr: "La personne est-elle localisée et en sécurité maintenant ?",
        en: "Is the person located and safe right now?",
      },
      response_type: "boolean",
      required: true,
      display_order: 1,
    },
  ],
  refusing_medication: [
    {
      question_key: "what_was_refused",
      prompt_i18n: {
        derja: "شنوّة الدواء أو التعليمات اللي ترفضت؟",
        ar: "ما الدواء أو التعليمات التي تم رفضها؟",
        fr: "Quel médicament ou quelle instruction a été refusé ?",
        en: "Which medication or existing instruction was refused?",
      },
      response_type: "text",
      required: true,
      display_order: 1,
    },
  ],
  sudden_confusion_worsening: [
    {
      question_key: "sudden_change",
      prompt_i18n: {
        derja: "التبدّل صار فجأة مقارنة بالعادة؟",
        ar: "هل حدث التغير فجأة مقارنة بالمعتاد؟",
        fr: "Le changement est-il apparu soudainement par rapport à l’habitude ?",
        en: "Did the change happen suddenly compared with usual?",
      },
      response_type: "boolean",
      required: true,
      display_order: 1,
    },
    {
      question_key: "immediate_safety",
      prompt_i18n: {
        derja: "فما خطر مباشر توا؟",
        ar: "هل يوجد خطر مباشر الآن؟",
        fr: "Y a-t-il un risque immédiat maintenant ?",
        en: "Is there an immediate safety concern right now?",
      },
      response_type: "boolean",
      required: true,
      display_order: 2,
    },
  ],
  is_this_normal: [
    {
      question_key: "describe_change",
      prompt_i18n: {
        derja: "احكيلي شنوّة لاحظت بالضبط وشنوّة الجديد فيه.",
        ar: "صف ما لاحظته بالضبط وما الجديد فيه.",
        fr: "Décrivez exactement ce que vous avez remarqué et ce qui est nouveau.",
        en: "Describe exactly what you noticed and what is new about it.",
      },
      response_type: "text",
      required: true,
      display_order: 1,
    },
  ],
  caregiver_cannot_take_anymore: [
    {
      question_key: "need_now",
      prompt_i18n: {
        derja: "توا تحبني نسمعك، نعاونك بخطوة عملية، ولا نوصلك بإنسان؟",
        ar: "هل تريد الآن أن أستمع، أساعدك بخطوة عملية، أم أوصلك بإنسان؟",
        fr: "Vous voulez que je vous écoute, que je vous aide avec une étape pratique, ou que je vous mette en relation avec une personne ?",
        en: "Do you want listening, one practical next step, or help reaching a person?",
      },
      response_type: "single_choice",
      required: true,
      display_order: 1,
    },
  ],
};

function notificationLanguage(value: unknown) {
  const lang = clean(value, 20).toLowerCase();
  if (lang === "tn" || lang === "tounsi" || lang === "derja") return "tn";
  if (lang === "ar" || lang === "arabic") return "ar";
  if (lang === "fr" || lang === "french") return "fr";
  return "en";
}

function followUpCopy(language: string) {
  if (language === "tn") {
    return {
      title: "كيفاش مشات؟",
      body: "هاني يتفكر الموقف وتنجم تكمل من وين وقفت كي تكون حاضر.",
    };
  }
  if (language === "ar") {
    return {
      title: "كيف سارت الأمور؟",
      body: "يتذكر هاني هذا الموقف ويمكنك المتابعة من حيث توقفت عندما تكون مستعدًا.",
    };
  }
  if (language === "fr") {
    return {
      title: "Comment cela s’est passé ?",
      body: "Hani se souvient de ce moment de soin. Reprenez quand vous êtes prêt.",
    };
  }
  return {
    title: "How did it go?",
    body: "Hani remembers this care moment. Continue when you are ready.",
  };
}

function careCircleCopy(language: string, fallbackBody: string) {
  if (language === "tn") {
    return {
      title: "طلب من دائرة العائلة",
      body: fallbackBody || "فما شخص في دائرة الرعاية طلب منك تعاون في مهمّة.",
    };
  }
  if (language === "ar") {
    return {
      title: "طلب من دائرة الرعاية",
      body: fallbackBody || "طلب منك أحد أفراد دائرة الرعاية المساعدة في مهمة.",
    };
  }
  if (language === "fr") {
    return {
      title: "Demande du Cercle de soins",
      body: fallbackBody || "Un membre du Cercle vous demande de prendre une responsabilité.",
    };
  }
  return {
    title: "Care Circle request",
    body: fallbackBody || "A caregiver asked you to cover a responsibility.",
  };
}

function afterQuietHours(date: Date, preference: Json | null) {
  const startRaw = clean(preference?.quiet_hours_start, 8);
  const endRaw = clean(preference?.quiet_hours_end, 8);
  if (!startRaw || !endRaw) return date;

  const parse = (raw: string) => {
    const parts = raw.split(":").map(Number);
    return parts.length >= 2 &&
      Number.isFinite(parts[0]) &&
      Number.isFinite(parts[1])
      ? parts[0] * 60 + parts[1]
      : null;
  };

  const start = parse(startRaw);
  const end = parse(endRaw);
  if (start == null || end == null || start === end) return date;

  const tunis = new Date(date.getTime() + 60 * 60 * 1000);
  const minute = tunis.getUTCHours() * 60 + tunis.getUTCMinutes();
  const overnight = start > end;
  const inQuiet = overnight
    ? minute >= start || minute < end
    : minute >= start && minute < end;

  if (!inQuiet) return date;
  if (overnight && minute >= start) tunis.setUTCDate(tunis.getUTCDate() + 1);
  tunis.setUTCHours(Math.floor(end / 60), end % 60, 0, 0);
  return new Date(tunis.getTime() - 60 * 60 * 1000);
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

  const url = `${supabaseUrl}/rest/v1/${path}`;
  let lastError: unknown = null;

  for (let attempt = 1; attempt <= 2; attempt++) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 12_000);

    try {
      const response = await fetch(url, {
        ...init,
        headers: {
          ...headers(),
          ...(init.headers as Record<string, string> | undefined),
        },
        cache: "no-store",
        signal: controller.signal,
      });

      const raw = await response.text();
      const body = raw ? JSON.parse(raw) : null;

      if (!response.ok) {
        throw new Error(
          body?.message || body?.error || `supabase_http_${response.status}`,
        );
      }

      return body;
    } catch (error) {
      lastError = error;

      const cause =
        error instanceof Error &&
        "cause" in error &&
        (error as Error & { cause?: unknown }).cause
          ? (error as Error & { cause?: any }).cause
          : null;

      console.error("Supabase REST fetch failed", {
        attempt,
        host: (() => {
          try {
            return new URL(url).host;
          } catch {
            return "invalid_url";
          }
        })(),
        message: error instanceof Error ? error.message : String(error),
        causeCode: cause?.code,
        causeMessage: cause?.message,
      });

      if (attempt < 2) {
        await new Promise((resolve) => setTimeout(resolve, 350));
      }
    } finally {
      clearTimeout(timeout);
    }
  }

  if (lastError instanceof Error) throw lastError;
  throw new Error("supabase_fetch_failed");
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

function storageLocale(value: unknown) {
  const locale = clean(value, 20).toLowerCase();
  if (locale === "tn" || locale === "tounsi" || locale === "derja") {
    return "derja";
  }
  if (["ar", "fr", "en"].includes(locale)) return locale;
  return "derja";
}

function validUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
    value,
  );
}

async function recentHaniMessages(
  caregiverId: string,
  patientId: string,
) {
  const conversations = await sb(
    `hani_conversations?select=id,channel,locale,purpose,started_at&caregiver_profile_id=eq.${encodeURIComponent(caregiverId)}&patient_id=eq.${encodeURIComponent(patientId)}&private_to_caregiver=eq.true&order=started_at.desc&limit=3`,
  ) as Json[];
  const ids = conversations.map((row) => row.id).filter(Boolean);
  if (!ids.length) return [];

  const messages = await sb(
    `hani_messages?select=id,conversation_id,sender,content,locale,created_at&conversation_id=in.(${ids.join(",")})&order=created_at.desc&limit=16`,
  ) as Json[];

  return messages.reverse();
}

async function recordHaniTurn(
  caregiverId: string,
  patientId: string,
  args: Json,
) {
  const sessionId = clean(args.sessionId, 120);
  if (!validUuid(sessionId)) throw new Error("valid_hani_session_required");

  const channel = args.channel === "voice" ? "voice" : "chat";
  const locale = storageLocale(args.locale);
  const purpose = ["general", "dilemma", "wellbeing", "care_circle", "handoff"].includes(
    clean(args.purpose, 40),
  )
    ? clean(args.purpose, 40)
    : "general";
  const userText = clean(args.userText, 4000);
  const haniText = clean(args.haniText, 4000);

  let conversation = await first(
    `hani_conversations?select=id&id=eq.${encodeURIComponent(sessionId)}&caregiver_profile_id=eq.${encodeURIComponent(caregiverId)}&patient_id=eq.${encodeURIComponent(patientId)}&limit=1`,
  );

  if (!conversation) {
    const rows = await sb("hani_conversations", {
      method: "POST",
      headers: { Prefer: "return=representation" },
      body: JSON.stringify({
        id: sessionId,
        caregiver_profile_id: caregiverId,
        patient_id: patientId,
        channel,
        locale,
        purpose,
        private_to_caregiver: true,
        metadata: {
          source: clean(args.source, 80) || channel,
          durableContext: true,
        },
      }),
    });
    conversation = rows?.[0] ?? null;
  }

  if (!conversation?.id) throw new Error("hani_conversation_persist_failed");

  const latest = await sb(
    `hani_messages?select=sender,content&conversation_id=eq.${encodeURIComponent(sessionId)}&order=created_at.desc&limit=2`,
  ) as Json[];
  const duplicate =
    latest.length >= 2 &&
    latest[0]?.sender === "hani" &&
    clean(latest[0]?.content, 4000) === haniText &&
    latest[1]?.sender === "user" &&
    clean(latest[1]?.content, 4000) === userText;

  if (!duplicate) {
    const rows = [];
    if (userText) {
      rows.push({
        conversation_id: sessionId,
        sender: "user",
        content: userText,
        locale,
        metadata: { source: clean(args.source, 80) || channel },
      });
    }
    if (haniText) {
      rows.push({
        conversation_id: sessionId,
        sender: "hani",
        content: haniText,
        locale,
        metadata: { source: clean(args.source, 80) || channel },
      });
    }
    if (rows.length) {
      await sb("hani_messages", {
        method: "POST",
        headers: { Prefer: "return=minimal" },
        body: JSON.stringify(rows),
      });
    }
  }

  return {
    conversationId: sessionId,
    stored: !duplicate,
    private: true,
  };
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

async function caregiverContext(caregiverId: string, patientId: string) {
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
  const [supportSignals, timeline, notifications] = await Promise.all([
    sb(`support_signals?select=id,signal_type,severity,confidence,evidence,experimental,created_at&caregiver_profile_id=eq.${encodeURIComponent(caregiverId)}&order=created_at.desc&limit=10`),
    sb(`timeline_events?select=id,event_type,title,summary,occurred_at,source_type,source_id&patient_id=eq.${encodeURIComponent(patientId)}&visible_to_care_circle=eq.true&order=occurred_at.desc&limit=20`),
    sb(`caregiver_notifications?select=id,category,title,body,action_type,action_payload,scheduled_for,opened_at,created_at&caregiver_profile_id=eq.${encodeURIComponent(caregiverId)}&order=created_at.desc&limit=12`),
  ]);

  const patterns: Json[] = [];
  const recentSeven = incidents.filter((i) => {
    const when = new Date(i.occurred_at || i.created_at || 0).getTime();
    return when > Date.now() - 7 * 24 * 60 * 60 * 1000;
  });
  const groups = new Map<string, number>();
  for (const incident of recentSeven) {
    const key = String(incident.scenario_id || incident.title || "incident");
    groups.set(key, (groups.get(key) || 0) + 1);
  }
  for (const [key, count] of groups) {
    if (count >= 2) {
      patterns.push({
        type: "repeated_incident",
        key,
        count,
        windowDays: 7,
        diagnostic: false,
      });
    }
  }
  const recentWellbeing = (wellbeing as Json[]).slice(0, 5);
  const heavier = recentWellbeing.filter((w) =>
    ["low", "poor", "tired", "overwhelmed", "exhausted"].includes(
      String(w.energy_label || w.sleep_label || w.mood_label || "").toLowerCase(),
    ),
  ).length;
  if (heavier >= 2) {
    patterns.push({
      type: "caregiver_strain",
      count: heavier,
      windowCount: recentWellbeing.length,
      diagnostic: false,
    });
  }

  const now = Date.now();
  const visibleNotifications = (notifications as Json[]).filter((n) => {
    if (!n.scheduled_for) return true;
    const scheduled = new Date(n.scheduled_for).getTime();
    return Number.isNaN(scheduled) || scheduled <= now;
  });

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
    supportSignals,
    timeline,
    recentHaniMessages: await recentHaniMessages(caregiverId, patientId),
    patterns,
    followUp: visibleNotifications.find((n) =>
      n.category === "incident_followup" && !n.opened_at
    ) ?? null,
  };
}

async function recordDemoWellbeing(caregiverId: string, patientId: string, input: Json) {
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

async function shareDemoIncident(caregiverId: string, patientId: string, incidentId: string) {
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

async function requestDemoCareTask(caregiverId: string, patientId: string, input: Json) {
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

async function caregiverSupplement(caregiverId: string, patientId: string) {
  await requireRelationship(caregiverId, patientId);
  const [notifications, preferences, definitions] = await Promise.all([
    sb(`caregiver_notifications?select=id,category,title,body,action_type,action_payload,scheduled_for,delivered_at,opened_at,created_at&caregiver_profile_id=eq.${encodeURIComponent(caregiverId)}&order=created_at.desc&limit=20`),
    first(`notification_preferences?select=*&caregiver_profile_id=eq.${encodeURIComponent(caregiverId)}&limit=1`),
    sb("questionnaire_definitions?select=id,code,name,purpose,owner,active&active=eq.true&order=created_at.desc"),
  ]);

  const questionnaires: Json[] = [];
  for (const definition of definitions as Json[]) {
    const versions = await sb(
      `questionnaire_versions?select=id,version_label,language,validation_status,validation_reference,active&questionnaire_id=eq.${definition.id}&active=eq.true&validation_status=eq.validated`,
    ) as Json[];
    questionnaires.push(...versions.map((version) => ({ ...version, definition })));
  }

  return {
    notifications,
    notificationPreferences: preferences,
    questionnaires,
  };
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

    if (tool === "record_hani_turn") {
      return NextResponse.json({
        success: true,
        ...(await recordHaniTurn(caregiverId, patientId, {
          ...args,
          source: context.source || args.source,
        })),
      });
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
      const [storedQuestions, guidance, redFlags] = await Promise.all([
        sb(`dilemma_questions?select=question_key,prompt_i18n,response_type,options,required,display_order&scenario_id=eq.${scenario.id}&active=eq.true&order=display_order.asc`),
        sb(`dilemma_guidance?select=guidance_key,guidance_i18n,condition_json,display_order&scenario_id=eq.${scenario.id}&active=eq.true&validation_status=eq.validated&order=display_order.asc`),
        sb(`dilemma_red_flags?select=red_flag_key,description_i18n,trigger_json,escalation_level,recommended_route&scenario_id=eq.${scenario.id}&active=eq.true&validation_status=eq.validated`),
      ]);
      const questions = Array.isArray(storedQuestions) && storedQuestions.length
        ? storedQuestions
        : (SAFE_INTERACTION_SHELLS[key] || []);
      const contentStatus = guidance.length || redFlags.length
        ? "validated_content_available"
        : "interaction_shell_only";
      return NextResponse.json({
        success: true,
        scenario,
        questions,
        guidance,
        redFlags,
        contentStatus,
        safeBoundary: contentStatus === "interaction_shell_only"
          ? "Use these questions only to understand context. Do not invent clinical guidance or red flags. Offer supportive, low-risk orientation and route to a human professional when clinical stakes or uncertainty are meaningful."
          : null,
      });
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
      const incident = rows?.[0] ?? null;

      const [preferences, caregiverProfile] = await Promise.all([
        first(
          `notification_preferences?select=enabled,incident_followup,quiet_hours_start,quiet_hours_end&caregiver_profile_id=eq.${encodeURIComponent(caregiverId)}&limit=1`,
        ),
        first(
          `profiles?select=preferred_language&id=eq.${encodeURIComponent(caregiverId)}&limit=1`,
        ),
      ]);
      if (incident && preferences?.enabled !== false && preferences?.incident_followup !== false) {
        const target = new Date(Date.now() + 12 * 60 * 60 * 1000);
        const scheduled = afterQuietHours(target, preferences).toISOString();
        const copy = followUpCopy(
          notificationLanguage(caregiverProfile?.preferred_language),
        );
        await sb("caregiver_notifications", {
          method: "POST",
          headers: { Prefer: "return=minimal" },
          body: JSON.stringify({
            caregiver_profile_id: caregiverId,
            category: "incident_followup",
            title: copy.title,
            body: copy.body,
            action_type: "open_hani_followup",
            action_payload: { incidentId: incident.id, scenarioKey: scenarioKey || null },
            scheduled_for: scheduled,
          }),
        });
      }

      return NextResponse.json({ success: true, incident, shared: false });
    }

    if (tool === "share_incident") {
      const incidentId = clean(args.incidentId, 120);
      const incident = await first(
        `incidents?select=*&id=eq.${encodeURIComponent(incidentId)}&reported_by_profile_id=eq.${encodeURIComponent(caregiverId)}&patient_id=eq.${encodeURIComponent(patientId)}&limit=1`,
      );
      if (!incident) return NextResponse.json({ error: "incident_not_found_or_not_owned" }, { status: 404 });
      const circle = await first(
        `care_circles?select=id&patient_id=eq.${encodeURIComponent(patientId)}&limit=1`,
      );
      const consentRows = await sb("consents", {
        method: "POST",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({
          actor_profile_id: caregiverId,
          patient_id: patientId,
          consent_type: "share_incident_to_care_circle",
          scope: {
            minimumNecessary: true,
            incidentId,
            dataCategories: ["patient_incident"],
          },
          recipient_type: "care_circle",
          recipient_id: circle?.id ?? null,
          status: "granted",
        }),
      });
      const consent = consentRows?.[0] ?? null;

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

      const timelineRows = await sb("timeline_events", {
        method: "POST",
        headers: { Prefer: "return=representation" },
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
      const timelineEvent = timelineRows?.[0] ?? null;

      await sb("disclosure_events", {
        method: "POST",
        headers: { Prefer: "return=minimal" },
        body: JSON.stringify({
          consent_id: consent?.id ?? null,
          actor_profile_id: caregiverId,
          patient_id: patientId,
          recipient_type: "care_circle",
          recipient_id: circle?.id ?? null,
          data_categories: ["patient_incident"],
          purpose: "shared_care_coordination",
          payload_reference: {
            incidentId,
            timelineEventId: timelineEvent?.id ?? null,
          },
        }),
      });

      return NextResponse.json({
        success: true,
        incident: rows?.[0],
        timelineEvent,
        consent,
        shared: true,
      });
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

      const [recipientPreferences, recipientProfile] = await Promise.all([
        first(
          `notification_preferences?select=enabled,care_circle_requests,quiet_hours_start,quiet_hours_end&caregiver_profile_id=eq.${encodeURIComponent(recipientProfileId)}&limit=1`,
        ),
        first(
          `profiles?select=preferred_language&id=eq.${encodeURIComponent(recipientProfileId)}&limit=1`,
        ),
      ]);
      if (recipientPreferences?.enabled !== false && recipientPreferences?.care_circle_requests !== false) {
        const copy = careCircleCopy(
          notificationLanguage(recipientProfile?.preferred_language),
          clean(args.message, 500) || clean(args.title, 200),
        );
        await sb("caregiver_notifications", {
          method: "POST",
          headers: { Prefer: "return=minimal" },
          body: JSON.stringify({
            caregiver_profile_id: recipientProfileId,
            category: "care_circle_request",
            title: copy.title,
            body: copy.body,
            action_type: "open_care_circle",
            action_payload: { requestId: requestRows?.[0]?.id ?? null, taskId: task.id },
            scheduled_for: afterQuietHours(new Date(), recipientPreferences).toISOString(),
          }),
        });
      }

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

    if (tool === "record_support_signal") {
      const signalType = clean(args.signalType, 120);
      const severity = ["low", "moderate", "elevated"].includes(args.severity)
        ? args.severity
        : "low";
      if (!signalType) {
        return NextResponse.json({ error: "support_signal_type_required" }, { status: 400 });
      }

      const confidenceValue = Number(args.confidence);
      const confidence = Number.isFinite(confidenceValue)
        ? Math.max(0, Math.min(1, confidenceValue))
        : null;

      const rows = await sb("support_signals", {
        method: "POST",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({
          caregiver_profile_id: caregiverId,
          patient_id: patientId,
          conversation_id: null,
          signal_type: signalType,
          severity,
          confidence,
          evidence: args.evidence && typeof args.evidence === "object"
            ? args.evidence
            : {},
          experimental: args.experimental === true,
        }),
      });

      return NextResponse.json({
        success: true,
        signal: rows?.[0] ?? null,
        private: true,
        diagnostic: false,
      });
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
      const contactRequest = requestRows?.[0] ?? null;

      if (handoff?.id && consent?.id) {
        await sb("disclosure_events", {
          method: "POST",
          headers: { Prefer: "return=minimal" },
          body: JSON.stringify({
            consent_id: consent.id,
            actor_profile_id: caregiverId,
            patient_id: patientId,
            recipient_type: "professional",
            recipient_id: professionalId,
            data_categories: [
              "handoff_summary",
              ...(args.incidentId ? ["patient_incident"] : []),
            ],
            purpose: "professional_handoff",
            payload_reference: {
              handoffSummaryId: handoff.id,
              incidentId: args.incidentId || null,
              contactRequestId: contactRequest?.id ?? null,
              channel,
            },
          }),
        });
      }

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
        request: contactRequest,
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
