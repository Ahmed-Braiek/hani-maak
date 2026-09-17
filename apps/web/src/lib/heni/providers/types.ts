import type { HeniChatMessage, HeniLocale, HeniModelReply, HeniRole } from "../types";

export type HeniProviderInput = {
  message: string;
  locale: HeniLocale;
  role: HeniRole;
  history: HeniChatMessage[];
  systemPrompt: string;
};

export interface HeniAIProvider {
  name: "openai";
  generate(input: HeniProviderInput): Promise<HeniModelReply>;
  healthCheck(): Promise<{ ok: boolean; model?: string; reason?: string }>;
}
