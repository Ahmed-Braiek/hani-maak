import { NextResponse } from "next/server";
import { assertVoiceBridgeSecret } from "@/lib/internalAuth";
import { finishLiveCall } from "@/lib/operations";

export async function POST(req: Request) {
  try {
    assertVoiceBridgeSecret(req);
    const body = await req.json();
    const session = await finishLiveCall(body);
    return NextResponse.json({ session });
  } catch (error) {
    return NextResponse.json({ error: error instanceof Error ? error.message : "Unknown error" }, { status: 400 });
  }
}
