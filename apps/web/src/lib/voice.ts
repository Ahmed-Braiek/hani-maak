import { isClinicalBoundary } from "./heni/safety.ts";

export type VoiceIntent = "book" | "cancel" | "reschedule" | "directions" | "instructions" | "next_steps" | "human_help" | "unknown";
export type ConversationLocale = "ar" | "fr" | "en";

const norm = (s: string) => s.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
const has = (text: string, terms: string[]) => terms.some(term => text.includes(norm(term)));

export function detectClinicalBoundary(text: string) {
  return isClinicalBoundary(text);
}

export function detectRequestedLocale(text: string): ConversationLocale | undefined {
  const x = norm(text);
  if (has(x, [
    "parle en arabe","parlez en arabe","parle arabe","parlez arabe","en arabe","arabic",
    "tunisian","tunisien","tunisienne","derja","darija","تونسي","تونسية","بالدارجة","بالتونسي","بالعربي","عربي"
  ])) return "ar";
  if (has(x, ["parle francais","parlez francais","en francais","français","french","بالفرنسي"])) return "fr";
  if (has(x, ["speak english","in english","anglais","english","بالانجليزي","بالإنجليزي"])) return "en";
}

export function detectLikelyLocale(text: string): ConversationLocale | undefined {
  const requested = detectRequestedLocale(text);
  if (requested) return requested;
  if (/[\u0600-\u06ff]/.test(text)) return "ar";
  const x = norm(text);
  if (has(x, [
    "nheb","naamel","na3mel","najem","najjem","chnowa","chnoua","chneya","win","winek","sbeh","l3chiya",
    "andi","3andi","aandy","ghodwa","tawa","barra","ey","ena","mouch","ma najemch","rendez vous fil"
  ])) return "ar";
  if (has(x, ["bonjour","je veux","je voudrais","rendez-vous","avec plaisir","s'il vous plait","merci","docteur","medecin","médecin"])) return "fr";
  if (has(x, ["hello","hi ","i want","please","doctor","appointment","english"])) return "en";
}

export function isLanguageSwitchOnly(text: string) {
  const x = norm(text).trim();
  if (!detectRequestedLocale(text)) return false;
  const actionWords = ["rendez","appointment","annul","cancel","deplac","resched","direction","ou est","where","document","prepare","aide","human","humain","doctor","docteur","medecin","médecin"];
  return x.length <= 70 && !has(x, actionWords);
}

export function isDoctorNameQuestion(text: string) {
  const x = norm(text);
  const mentionsDoctor = has(x, ["doctor","docteur","medecin","médecin","tabib","toubib","طبيب","الدكتور","دكتور"]);
  const asksIdentity = has(x, ["nom","name","qui","who","شنو اسمو","شنية اسم","اسم الطبيب","شكون"]);
  return mentionsDoctor && asksIdentity;
}

export function detectIntent(text: string): VoiceIntent {
  if (detectClinicalBoundary(text)) return "unknown";
  const x = norm(text);
  if (has(x, [
    "human","humain","humaine","aide humaine","aide humain","personne","parler a quelqu'un","parler à quelqu'un",
    "agent","staff","employee","موظف","انسان","إنسان","نحكي مع حد","نحب موظف","responsable"
  ])) return "human_help";
  if (has(x, ["cancel", "annul", "الغاء", "إلغاء", "نلغي", "الغيه", "نلغي الموعد"])) return "cancel";
  if (has(x, ["resched", "deplac", "changer rendez", "changer mon rendez", "modifier mon rendez", "بدل الموعد", "نبدل", "نغير الموعد", "نغيّر الموعد"])) return "reschedule";
  if (has(x, ["my appointment", "mon rendez-vous", "mon prochain rendez", "3andi rendez", "andi rendez", "aandy rendez", "عندي موعد", "موعدي", "وقتاش الموعد", "شنو موعدي", "prochaine etape", "next step", "شنوة بعد", "شنو بعد", "بعد الموعد"])) return "next_steps";
  if (has(x, ["where", "direction", "ou est", "où est", "adresse", "hospital", "hopital", "hôpital", "وين", "كيفاش نمشي", "كيف نمشي", "كيف نوصل", "فين"])) return "directions";
  if (has(x, ["bring", "prepare", "preparation", "préparation", "document", "شنوة نجيب", "ماذا احضر", "التحضير", "تحضير", "شنو نجيب"])) return "instructions";
  if (has(x, ["next", "apres", "après", "بعد"])) return "next_steps";
  if (has(x, ["rendez", "appointment", "book", "reserve", "réserve", "موعد", "نحب ناخذ", "نحب نعمل", "نحجز", "nheb naamel", "nheb na3mel"])) return "book";
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
