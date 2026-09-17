export function getVoiceBridgeConfig() {
  return {
    port: Number(process.env.VOICE_BRIDGE_PORT || 8787),
    openaiApiKey: process.env.OPENAI_API_KEY,
    realtimeModel: process.env.OPENAI_REALTIME_MODEL || process.env.OPENAI_LIVE_MODEL || "gpt-realtime-2.1",
    delegatedModel: process.env.HENI_FINE_TUNED_MODEL_ID || process.env.HENI_CHAT_MODEL || process.env.OPENAI_DELEGATED_MODEL || "gpt-5.6-terra",
    voice: process.env.OPENAI_VOICE || "marin",
    webBaseUrl: process.env.HANI_WEB_BASE_URL || "http://localhost:3000",
    sharedSecret: process.env.VOICE_BRIDGE_SHARED_SECRET || ""
  };
}
