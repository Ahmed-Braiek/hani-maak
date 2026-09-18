import type {Locale} from "./types";

export const CHARLES_NICOLLE_PUBLIC_KNOWLEDGE = {
  hospital: {
    name: "Hôpital Charles Nicolle",
    address: "Boulevard 9 Avril 1938, Tunis 1006, Tunisie",
    mainPhone: "+216 71 262 740",
    emergencyPhones: ["+216 71 578 007", "+216 71 578 346"],
    website: "http://www.chucharlesnicolle.tn"
  },
  verifiedOn: "2026-09-18",
  sources: [
    {
      label: "Ministère de la Santé publique — établissements publics de santé",
      url: "https://santetunisie.rns.tn/fr/component/eps/?idg=100",
      authority: "Tunisian Ministry of Health"
    },
    {
      label: "Ministère de la Santé publique — établissements sous tutelle",
      url: "https://santetunisie.rns.tn/fr/presentations/etablissements-sous-tutelle",
      authority: "Tunisian Ministry of Health"
    }
  ]
} as const;

const copy:Record<Locale,{kind:string;scope:string;emergency:string}> = {
  ar:{
    kind:"مستشفى عمومي جامعي متعدّد الاختصاصات",
    scope:"هاني ينجم يعطي معلومات عامة ومعلومات على الخدمات الموجودة في هاني معاك. التفاصيل التشغيلية والمواعيد والمسارات الداخلية لازم تجي من بيانات المنصة.",
    emergency:"في حالة استعجالية صحية، اتصل بخدمات الاستعجالي أو توجّه مباشرةً إلى الطاقم الصحي."
  },
  fr:{
    kind:"Hôpital public universitaire polyvalent",
    scope:"Heni peut fournir les informations publiques générales et les services présents dans Hani Maak. Les détails opérationnels, disponibilités et parcours intérieurs doivent venir des données de la plateforme.",
    emergency:"En cas d'urgence médicale, contactez les services d'urgence ou adressez-vous immédiatement au personnel de santé."
  },
  en:{
    kind:"General public university hospital",
    scope:"Heni may provide general public information and services available in Hani Maak. Operational details, availability and indoor routes must come from platform data.",
    emergency:"For a medical emergency, contact emergency services or on-site healthcare staff immediately."
  }
};

export function publicHospitalKnowledge(locale:Locale){
  const language=copy[locale]??copy.fr;
  return {
    ...CHARLES_NICOLLE_PUBLIC_KNOWLEDGE,
    description:language.kind,
    scope:language.scope,
    emergencyGuidance:language.emergency
  };
}
