import { NextResponse } from "next/server";
import {
  caregiverAuthStatus,
  DEMO_CAREGIVER_ID,
  DEMO_PATIENT_ID,
  verifyCaregiverAccess,
} from "@/lib/caregiver-access";

export const dynamic = "force-dynamic";

const supabaseUrl = (
  process.env.SUPABASE_URL ||
  process.env.NEXT_PUBLIC_SUPABASE_URL
)?.replace(/\/$/, "");
const supabaseKey =
  process.env.SUPABASE_SECRET_KEY ||
  process.env.SUPABASE_SERVICE_ROLE_KEY;

function headers() {
  if (!supabaseKey) throw new Error("supabase_secret_missing");
  const value: Record<string, string> = {
    apikey: supabaseKey,
    "content-type": "application/json",
  };
  if (
    !supabaseKey.startsWith("sb_secret_") &&
    !supabaseKey.startsWith("sb_publishable_")
  ) {
    value.Authorization = `Bearer ${supabaseKey}`;
  }
  return value;
}

async function sb(path: string) {
  if (!supabaseUrl || !supabaseKey) throw new Error("supabase_not_configured");
  const response = await fetch(`${supabaseUrl}/rest/v1/${path}`, {
    headers: headers(),
    cache: "no-store",
  });
  const raw = await response.text();
  const body = raw ? JSON.parse(raw) : null;
  if (!response.ok) {
    throw new Error(body?.message || body?.error || `supabase_http_${response.status}`);
  }
  return body;
}

export async function GET(
  req: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params;
  const url = new URL(req.url);
  const caregiverId =
    url.searchParams.get("caregiverId") || DEMO_CAREGIVER_ID;
  const patientId =
    url.searchParams.get("patientId") || DEMO_PATIENT_ID;

  try {
    await verifyCaregiverAccess(req, caregiverId, patientId);

    const conversations = await sb(
      `hani_conversations?select=id,ended_at,started_at,channel&id=eq.${encodeURIComponent(id)}&caregiver_profile_id=eq.${encodeURIComponent(caregiverId)}&patient_id=eq.${encodeURIComponent(patientId)}&limit=1`,
    );
    const conversation = Array.isArray(conversations)
      ? conversations[0] ?? null
      : null;
    if (!conversation || conversation.channel !== "voice") {
      return NextResponse.json({ error: "voice_conversation_not_found" }, { status: 404 });
    }

    const rows = await sb(
      `voice_emotion_analyses?select=*&conversation_id=eq.${encodeURIComponent(id)}&caregiver_profile_id=eq.${encodeURIComponent(caregiverId)}&patient_id=eq.${encodeURIComponent(patientId)}&limit=1`,
    );
    const analysis = Array.isArray(rows) ? rows[0] ?? null : null;

    if (!analysis) {
      return NextResponse.json({
        conversationId: id,
        status: conversation.ended_at ? "not_started" : "processing",
        analysis: null,
      });
    }

    const segmentRows = await sb(
      `voice_emotion_segments?select=segment_index,start_ms,end_ms,voiced_duration_ms,dominant_emotion,confidence,distribution&analysis_id=eq.${encodeURIComponent(analysis.id)}&order=segment_index.asc`,
    );

    return NextResponse.json({
      conversationId: id,
      status: analysis.status,
      analysis: {
        dominantEmotion: analysis.dominant_emotion,
        confidence: analysis.confidence,
        distribution: analysis.distribution,
        timeline: (Array.isArray(segmentRows) ? segmentRows : []).map((segment: any) => ({
          segmentIndex: segment.segment_index,
          startMs: segment.start_ms,
          endMs: segment.end_ms,
          voicedDurationMs: segment.voiced_duration_ms,
          dominantEmotion: segment.dominant_emotion,
          confidence: segment.confidence,
          distribution: segment.distribution,
        })),
        audioDurationMs: analysis.audio_duration_ms,
        analyzedSpeechMs: analysis.analyzed_speech_ms,
        model: analysis.model_name,
        modelVersion: analysis.model_version,
        analysisVersion: analysis.analysis_version,
        failureCode: analysis.failure_code,
        failureMessage: analysis.failure_message,
        emotionalSummary: analysis.emotional_summary,
        resultSource: analysis.result_source,
        createdAt: analysis.created_at,
        completedAt: analysis.completed_at,
      },
    });
  } catch (error) {
    return NextResponse.json(
      {
        error: error instanceof Error ? error.message : "emotion_result_failed",
      },
      { status: caregiverAuthStatus(error) },
    );
  }
}
