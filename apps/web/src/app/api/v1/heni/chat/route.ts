import { NextResponse } from "next/server";
import { chatWithHeni } from "@/lib/heni/service";
import { getStaffIdentity } from "@/lib/staff-auth";
import type { HeniRole } from "@/lib/heni/types";

async function resolveRole(requested: unknown): Promise<HeniRole> {
  if (requested !== "doctor" && requested !== "administration" && requested !== "super_admin") return "patient";
  const identity = await getStaffIdentity();
  if (!identity) return "patient";
  return identity.role;
}

export async function POST(req: Request) {
  try {
    const body = await req.json().catch(() => ({}));
    const message = String(body?.message ?? "").trim();
    if (!message) return NextResponse.json({ error: "message_required" }, { status: 400 });
    if (message.length > 2000) return NextResponse.json({ error: "message_too_long" }, { status: 413 });
    const role = await resolveRole(body?.role);
    const result = await chatWithHeni({
      message,
      locale: body?.locale,
      patientId: body?.patientId,
      role,
      source: body?.source,
      sessionId: body?.sessionId,
      history: Array.isArray(body?.history) ? body.history : []
    });
    return NextResponse.json(result);
  } catch (error) {
    console.error("Heni chat failed", error instanceof Error ? error.message : "unknown");
    return NextResponse.json({ error: "heni_chat_unavailable" }, { status: 503 });
  }
}
