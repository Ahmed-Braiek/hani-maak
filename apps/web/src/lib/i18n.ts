import type { Locale } from "./types";
export const text={
  fr:{home:"Accueil",journey:"Parcours",map:"Plan",profile:"Profil",next:"Votre prochaine étape",book:"Prendre un rendez-vous",guide:"Guide-moi",call:"Appeler Hani Maak",help:"Besoin d'aide",prototype:"Itinéraire prototype — non validé par l'hôpital"},
  ar:{home:"الرئيسية",journey:"مساري",map:"الخريطة",profile:"حسابي",next:"خطوتك القادمة",book:"احجز موعداً",guide:"دلّني",call:"اتصل بهاني معاك",help:"تحتاج مساعدة؟",prototype:"مسار تجريبي — غير معتمد من المستشفى"},
  en:{home:"Home",journey:"Journey",map:"Map",profile:"Profile",next:"Your next step",book:"Book an appointment",guide:"Guide me",call:"Call Hani Maak",help:"Need help",prototype:"Prototype route — not validated by the hospital"}
} satisfies Record<Locale,Record<string,string>>;
export const t=(locale:Locale,key:keyof typeof text.fr)=>text[locale][key];
