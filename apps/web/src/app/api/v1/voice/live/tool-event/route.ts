import { NextResponse } from "next/server";
import { assertVoiceBridgeSecret } from "@/lib/internalAuth";
import { recordLiveToolEvent } from "@/lib/operations";

export async function POST(req: Request) {
  try {
    assertVoiceBridgeSecret(req);
    const body = await req.json();
    const event = await recordLiveToolEvent(body);
    return NextResponse.json({ event }, { status: 201 });
  } catch (error) {
    return NextResponse.json({ error: error instanceof Error ? error.message : "Unknown error" }, { status: 400 });
  }
}
