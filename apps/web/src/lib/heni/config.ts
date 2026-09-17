import type { HeniProviderName } from "./types";

export type HeniConfig = {
  provider: HeniProviderName;
  model: string;
  fallbackModel?: string;
  apiKey?: string;
  baseUrl: string;
  maxOutputTokens: number;
  timeoutMs: number;
  fineTuned: boolean;
};

function positiveInt(value: string | undefined, fallback: number) {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed > 0 ? Math.floor(parsed) : fallback;
}

export function getHeniConfig(): HeniConfig {
  const provider = process.env.HENI_AI_PROVIDER === "openai" ? "openai" : "development";
  const fineTunedModel = process.env.HENI_FINE_TUNED_MODEL_ID?.trim();
  const standardModel = process.env.HENI_CHAT_MODEL?.trim() || process.env.OPENAI_DELEGATED_MODEL?.trim();
  return {
    provider,
    model: fineTunedModel || standardModel || "",
    fallbackModel: process.env.HENI_FALLBACK_MODEL?.trim() || undefined,
    apiKey: process.env.HENI_AI_API_KEY?.trim() || process.env.OPENAI_API_KEY?.trim() || undefined,
    baseUrl: (process.env.HENI_AI_BASE_URL?.trim() || "https://api.openai.com/v1").replace(/\/$/, ""),
    maxOutputTokens: positiveInt(process.env.HENI_MAX_OUTPUT_TOKENS, 220),
    timeoutMs: positiveInt(process.env.HENI_MODEL_TIMEOUT_MS, 12000),
    fineTuned: Boolean(fineTunedModel)
  };
}

export function heniModelEnabled(config = getHeniConfig()) {
  return config.provider === "openai" && Boolean(config.apiKey && config.model);
}
