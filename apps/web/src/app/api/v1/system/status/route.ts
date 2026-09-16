import { NextResponse } from "next/server";
import { getDataBackendStatus, readDb } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function GET() {
  const backend = getDataBackendStatus();
  try {
    const db = await readDb();
    return NextResponse.json({
      ok: true,
      backend,
      seededAt: db.meta.seededAt,
      revision: db.meta.revision,
      integrations: {
        openai: Boolean(process.env.OPENAI_API_KEY),
        voiceBridge: Boolean(process.env.VOICE_BRIDGE_WSS_URL),
        mapbox: Boolean(process.env.NEXT_PUBLIC_MAPBOX_TOKEN),
        supabase: backend.supabaseConfigured,
      },
    });
  } catch (error) {
    return NextResponse.json({ ok: false, backend, error: error instanceof Error ? error.message : "Unknown error" }, { status: 500 });
  }
}
