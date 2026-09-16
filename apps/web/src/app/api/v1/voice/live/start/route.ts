import { NextResponse } from "next/server";
import { assertVoiceBridgeSecret } from "@/lib/internalAuth";
import { startLiveCall } from "@/lib/operations";

export async function POST(req: Request) {
  try {
    assertVoiceBridgeSecret(req);
    const body = await req.json().catch(() => ({}));
    const session = await startLiveCall({ externalCallId: body.externalCallId, caller: body.caller, locale: body.locale ?? "ar" });
    return NextResponse.json({ session }, { status: 201 });
  } catch (error) {
    return NextResponse.json({ error: error instanceof Error ? error.message : "Unknown error" }, { status: 401 });
  }
}
