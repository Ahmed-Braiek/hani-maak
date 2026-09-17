import { timingSafeEqual } from "node:crypto";

function safeEqual(left: string, right: string) {
  const a = Buffer.from(left);
  const b = Buffer.from(right);
  return a.length === b.length && timingSafeEqual(a, b);
}

export function assertVoiceBridgeSecret(req: Request) {
  const expected = process.env.VOICE_BRIDGE_SHARED_SECRET?.trim();
  if (!expected) {
    if (process.env.NODE_ENV === "production") throw new Error("VOICE_BRIDGE_SHARED_SECRET is required in production");
    return;
  }
  const supplied = req.headers.get("x-hani-voice-secret") ?? "";
  if (!safeEqual(supplied, expected)) throw new Error("Unauthorized voice bridge request");
}
