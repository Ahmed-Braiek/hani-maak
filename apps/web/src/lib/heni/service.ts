import { newVoiceSession, recordCallExchange, voiceTurn } from "../operations";
import { detectIntent } from "../voice";
import { getHeniConfig, heniModelEnabled } from "./config";
import { buildHeniSystemPrompt } from "./prompts";
import { evaluateHeniSafety } from "./safety";
import { OpenAIResponsesProvider } from "./providers/openai-responses";
import type { HeniChatRequest, HeniChatResponse, HeniLocale, HeniRole } from "./types";

const fallbackPatient = "patient-amal";

function safeLocale(value: string | undefined): HeniLocale {
  return value === "en" || value === "fr" || value === "ar" ? value : "ar";
}

function safeRole(value: string | undefined): HeniRole {
  return value === "doctor" || value === "administration" || value === "super_admin" ? value : "patient";
}

function privacyReply(locale: HeniLocale) {
  if (locale === "ar") return "ما نجمش نعرض ولا نطلب كلمات سرّ أو مفاتيح سرّية. نجم نعاونك في الخدمة من غير ما تشارك معلومات حسّاسة.";
  if (locale === "en") return "I cannot request or reveal passwords, secret keys, or credentials. I can help without you sharing sensitive secrets.";
  return "Je ne peux pas demander ni révéler de mots de passe, clés secrètes ou identifiants sensibles. Je peux vous aider sans ces informations.";
}

async function createSession(locale: HeniLocale, patientId: string, source: string) {
  const created = await newVoiceSession(locale, patientId, source);
  return created.session.id;
}

async function runDeterministic(sessionId: string, message: string): Promise<any> {
  return voiceTurn(sessionId, message);
}

export async function chatWithHeni(input: HeniChatRequest): Promise<HeniChatResponse> {
  const locale = safeLocale(input.locale);
  const role = safeRole(input.role);
  const patientId = input.patientId || fallbackPatient;
  const source = input.source || "heni_chat";
  const message = String(input.message || "").trim();
  const safety = evaluateHeniSafety(message);
  let sessionId = input.sessionId || await createSession(locale, patientId, source);

  if (safety.category === "privacy") {
    const reply = privacyReply(locale);
    await recordCallExchange(sessionId, message, reply);
    return { message: reply, sessionId, provider: "deterministic", safety };
  }

  const intent = detectIntent(message);
  const config = getHeniConfig();
  const useModel = safety.allowed && intent === "unknown" && heniModelEnabled(config);

  if (useModel) {
    try {
      const provider = new OpenAIResponsesProvider();
      const result = await provider.generate({
        message,
        locale,
        role,
        history: Array.isArray(input.history) ? input.history.slice(-10) : [],
        systemPrompt: buildHeniSystemPrompt({ locale, role })
      });
      await recordCallExchange(sessionId, message, result.text);
      return { message: result.text, sessionId, provider: result.provider, model: result.model, safety };
    } catch {
      // Provider failure must not take down the patient journey. Fall back to the tested deterministic path.
    }
  }

  try {
    const result = await runDeterministic(sessionId, message);
    await recordCallExchange(sessionId, message, String(result.message || ""));
    return {
      message: String(result.message || ""),
      sessionId,
      provider: "deterministic",
      tool: result.tool,
      escalated: result.session?.outcome === "escalated",
      safety
    };
  } catch (error) {
    const text = String((error as Error)?.message || "");
    if (!text.toLowerCase().includes("not found")) throw error;
    sessionId = await createSession(locale, patientId, source);
    const result = await runDeterministic(sessionId, message);
    await recordCallExchange(sessionId, message, String(result.message || ""));
    return {
      message: String(result.message || ""),
      sessionId,
      provider: "deterministic",
      tool: result.tool,
      escalated: result.session?.outcome === "escalated",
      safety
    };
  }
}
