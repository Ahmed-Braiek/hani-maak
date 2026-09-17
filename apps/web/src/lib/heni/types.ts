export type HeniLocale = "ar" | "fr" | "en";
export type HeniRole = "patient" | "doctor" | "administration" | "super_admin";
export type HeniProviderName = "development" | "openai";

export type HeniChatMessage = {
  role: "user" | "assistant";
  content: string;
};

export type HeniChatRequest = {
  message: string;
  locale?: HeniLocale;
  patientId?: string;
  role?: HeniRole;
  source?: string;
  sessionId?: string;
  history?: HeniChatMessage[];
};

export type HeniSafetyDecision = {
  allowed: boolean;
  category?: "clinical_boundary" | "privacy" | "unsupported";
  reason?: string;
};

export type HeniModelReply = {
  text: string;
  provider: HeniProviderName;
  model?: string;
};

export type HeniChatResponse = {
  message: string;
  sessionId: string;
  provider: HeniProviderName | "deterministic";
  model?: string;
  tool?: string;
  escalated?: boolean;
  safety?: HeniSafetyDecision;
};
