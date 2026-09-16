export function assertVoiceBridgeSecret(req: Request) {
  const expected = process.env.VOICE_BRIDGE_SHARED_SECRET;
  if (!expected) {
    if (process.env.NODE_ENV === "production") throw new Error("VOICE_BRIDGE_SHARED_SECRET is required in production");
    return;
  }
  const supplied = req.headers.get("x-hani-voice-secret");
  if (supplied !== expected) throw new Error("Unauthorized voice bridge request");
}
