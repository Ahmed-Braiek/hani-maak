import { getHeniConfig } from "../config";
import type { HeniModelReply } from "../types";
import type { HeniAIProvider, HeniProviderInput } from "./types";

function extractText(payload: any) {
  const parts: string[] = [];
  for (const item of Array.isArray(payload?.output) ? payload.output : []) {
    for (const content of Array.isArray(item?.content) ? item.content : []) {
      if (content?.type === "output_text" && typeof content.text === "string") parts.push(content.text);
    }
  }
  return parts.join("\n").trim();
}

function transcript(input: HeniProviderInput) {
  const history = input.history.slice(-10).map(message => `${message.role === "user" ? "User" : "Heni"}: ${message.content}`);
  return [...history, `User: ${input.message}`].join("\n");
}

export class OpenAIResponsesProvider implements HeniAIProvider {
  readonly name = "openai" as const;

  async generate(input: HeniProviderInput): Promise<HeniModelReply> {
    const config = getHeniConfig();
    if (!config.apiKey || !config.model) throw new Error("heni_model_not_configured");
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), config.timeoutMs);
    try {
      const response = await fetch(`${config.baseUrl}/responses`, {
        method: "POST",
        headers: {
          authorization: `Bearer ${config.apiKey}`,
          "content-type": "application/json"
        },
        body: JSON.stringify({
          model: config.model,
          instructions: input.systemPrompt,
          input: transcript(input),
          max_output_tokens: config.maxOutputTokens
        }),
        signal: controller.signal
      });
      const payload = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(`heni_provider_http_${response.status}`);
      const text = extractText(payload);
      if (!text) throw new Error("heni_provider_empty_response");
      return { text, provider: "openai", model: config.model };
    } finally {
      clearTimeout(timer);
    }
  }

  async healthCheck() {
    const config = getHeniConfig();
    if (!config.apiKey) return { ok: false, model: config.model || undefined, reason: "missing_api_key" };
    if (!config.model) return { ok: false, reason: "missing_model" };
    return { ok: true, model: config.model };
  }
}
