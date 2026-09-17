import { isClinicalBoundary } from "./heni/safety.ts";

export type VoiceIntent = "book" | "cancel" | "reschedule" | "directions" | "instructions" | "next_steps" | "human_help" | "unknown";

const norm = (s: string) => s.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
const has = (text: string, terms: string[]) => terms.some(term => text.includes(norm(term)));

export function detectClinicalBoundary(text: string) {
  return isClinicalBoundary(text);
}

export function detectIntent(text: string): VoiceIntent {
  if (detectClinicalBoundary(text)) return "unknown";
  const x = norm(text);
  if (has(x, ["human", "personne", "agent", "موظف", "انسان", "إنسان", "نحكي مع حد", "responsable"])) return "human_help";
  if (has(x, ["cancel", "annul", "الغاء", "إلغاء", "نلغي", "الغيه", "نلغي الموعد"])) return "cancel";
  if (has(x, ["resched", "deplac", "changer rendez", "changer mon rendez", "modifier mon rendez", "بدل الموعد", "نبدل", "نغير الموعد", "نغيّر الموعد"])) return "reschedule";
  if (has(x, ["my appointment", "mon rendez-vous", "mon prochain rendez", "موعدي", "وقتاش الموعد", "شنو موعدي", "prochaine etape", "next step", "شنوة بعد", "شنو بعد", "بعد الموعد"])) return "next_steps";
  if (has(x, ["where", "direction", "ou est", "où est", "adresse", "hospital", "hopital", "hôpital", "وين", "كيفاش نمشي", "كيف نمشي", "كيف نوصل", "فين"])) return "directions";
  if (has(x, ["bring", "prepare", "preparation", "préparation", "document", "شنوة نجيب", "ماذا احضر", "التحضير", "تحضير", "شنو نجيب"])) return "instructions";
  if (has(x, ["next", "apres", "après", "بعد"])) return "next_steps";
  if (has(x, ["rendez", "appointment", "book", "reserve", "réserve", "موعد", "نحب ناخذ", "نحب نعمل", "نحجز"])) return "book";
  return "unknown";
}

export function detectPeriod(text: string): "morning" | "afternoon" | undefined {
  const x = norm(text);
  if (has(x, ["morning", "matin", "sbeh", "sbah", "صباح", "الصباح"])) return "morning";
  if (has(x, ["afternoon", "apres-midi", "après-midi", "l3chiya", "العشية", "مساء", "بعد الظهر"])) return "afternoon";
}

export function isAffirmative(text: string) {
  const x = norm(text).trim();
  return ["yes", "oui", "ok", "d'accord", "daccord", "confirm", "confirme", "اي", "إي", "نعم", "ايه", "إيه", "نأكد", "نؤكد", "اكيد", "أكيد"].some(k => x === norm(k) || x.includes(norm(k)));
}

export function choiceIndex(text: string) {
  const x = norm(text);
  if (/\b(1|one|premier|awel)\b/.test(x) || x.includes("الاول") || x.includes("الأول") || x.includes("لول")) return 0;
  if (/\b(2|two|deuxieme|deuxième|theni)\b/.test(x) || x.includes("الثاني") || x.includes("ثاني")) return 1;
  if (/\b(3|three|troisieme|troisième|theleth)\b/.test(x) || x.includes("الثالث") || x.includes("ثالث")) return 2;
  return undefined;
}
