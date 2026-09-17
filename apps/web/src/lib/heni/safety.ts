import type { HeniSafetyDecision } from "./types";

const normalize = (value: string) => value.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");

const clinicalTerms = [
  "dose", "dosage", "augmenter", "diminuer", "diagnostic", "diagnosis", "diagnose", "prescrire", "prescribe",
  "urgence", "urgent", "emergency", "safe to take", "can i take", "interaction médicament", "allergie", "pregnant",
  "زيد الجرعة", "نزيد الجرعة", "نقص الجرعة", "تشخيص", "وصفة", "استعجالي", "حامل", "نجم ناخذ"
];

const sensitiveSecretTerms = ["password", "mot de passe", "api key", "secret key", "service role key", "token secret"];

export function isClinicalBoundary(text: string) {
  const value = normalize(text);
  return clinicalTerms.some(term => value.includes(normalize(term)));
}

export function evaluateHeniSafety(text: string): HeniSafetyDecision {
  const value = normalize(text.trim());
  if (!value) return { allowed: false, category: "unsupported", reason: "empty_message" };
  if (value.length > 2000) return { allowed: false, category: "unsupported", reason: "message_too_long" };
  if (sensitiveSecretTerms.some(term => value.includes(normalize(term)))) {
    return { allowed: false, category: "privacy", reason: "secret_or_credential_request" };
  }
  if (isClinicalBoundary(value)) {
    return { allowed: false, category: "clinical_boundary", reason: "requires_healthcare_professional" };
  }
  return { allowed: true };
}
