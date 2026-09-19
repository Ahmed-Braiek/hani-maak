import type {Locale} from "./types";

type Localized = Record<Locale,string>;
type DirectoryCategory = "medical"|"surgical"|"diagnostic"|"support"|"emergency";

export interface PublicHospitalDirectoryEntry{
  id:string;
  category:DirectoryCategory;
  name:Localized;
  aliases:string[];
  platformServiceId?:string;
  referenceLevel:"platform_verified"|"public_reference";
}

export const CHARLES_NICOLLE_PUBLIC_KNOWLEDGE = {
  hospital: {
    name: "Hôpital Charles Nicolle",
    address: "Boulevard 9 Avril 1938, Tunis 1006, Tunisie",
    mainPhone: "+216 71 262 740",
    emergencyPhones: ["+216 71 578 007", "+216 71 578 346"],
    website: "http://www.chucharlesnicolle.tn",
    coordinates:{lat:36.802254,lon:10.161104}
  },
  verifiedOn: "2026-09-19",
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

const directory:PublicHospitalDirectoryEntry[]=[
  {id:"imaging",category:"diagnostic",name:{fr:"Imagerie médicale / Radiologie",ar:"التصوير الطبي / الأشعة",en:"Medical imaging / Radiology"},aliases:["imagerie","radiologie","radio","scanner","irm","échographie","echographie","تصوير","أشعة","سكانار","radiology","imaging"],platformServiceId:"svc-imaging",referenceLevel:"platform_verified"},
  {id:"nuclear-medicine",category:"diagnostic",name:{fr:"Médecine nucléaire",ar:"الطب النووي",en:"Nuclear medicine"},aliases:["médecine nucléaire","medecine nucleaire","nucléaire","nucleaire","radio-isotopes","radio isotopes","الطب النووي","nuclear medicine"],referenceLevel:"public_reference"},
  {id:"rheumatology",category:"medical",name:{fr:"Rhumatologie",ar:"أمراض الروماتيزم",en:"Rheumatology"},aliases:["rhumatologie","rhumato","روماتيزم","rheumatology"],platformServiceId:"svc-rheum",referenceLevel:"platform_verified"},
  {id:"cardiology",category:"medical",name:{fr:"Cardiologie",ar:"أمراض القلب",en:"Cardiology"},aliases:["cardio","cardiologie","قلب","cardiology"],referenceLevel:"public_reference"},
  {id:"dermatology",category:"medical",name:{fr:"Dermatologie",ar:"الأمراض الجلدية",en:"Dermatology"},aliases:["dermatologie","dermato","جلدية","dermatology"],referenceLevel:"public_reference"},
  {id:"gastroenterology",category:"medical",name:{fr:"Gastro-entérologie",ar:"أمراض الجهاز الهضمي",en:"Gastroenterology"},aliases:["gastro","gastro-entérologie","gastroenterologie","digestif","جهاز هضمي","gastroenterology"],referenceLevel:"public_reference"},
  {id:"internal-nephrology",category:"medical",name:{fr:"Médecine interne / Néphrologie",ar:"الطب الباطني / أمراض الكلى",en:"Internal medicine / Nephrology"},aliases:["médecine interne","medecine interne","néphrologie","nephrologie","rein","reins","كلى","باطني","nephrology","internal medicine"],referenceLevel:"public_reference"},
  {id:"endocrinology",category:"medical",name:{fr:"Endocrinologie",ar:"أمراض الغدد والسكري",en:"Endocrinology"},aliases:["endocrinologie","endocrino","diabète","diabete","غدد","سكري","endocrinology","diabetes"],referenceLevel:"public_reference"},
  {id:"neurology",category:"medical",name:{fr:"Neurologie",ar:"طب الأعصاب",en:"Neurology"},aliases:["neurologie","neuro","أعصاب","neurology"],referenceLevel:"public_reference"},
  {id:"pediatrics",category:"medical",name:{fr:"Pédiatrie",ar:"طب الأطفال",en:"Pediatrics"},aliases:["pédiatrie","pediatrie","enfant","طفل","أطفال","pediatrics","children"],referenceLevel:"public_reference"},
  {id:"neonatology",category:"medical",name:{fr:"Néonatologie",ar:"طب حديثي الولادة",en:"Neonatology"},aliases:["néonatologie","neonatologie","nouveau né","nouveau-ne","رضيع","حديثي الولادة","neonatology"],referenceLevel:"public_reference"},
  {id:"pneumology",category:"medical",name:{fr:"Pneumologie",ar:"أمراض الرئة",en:"Pulmonology"},aliases:["pneumologie","pneumo","poumon","رئة","pulmonology"],referenceLevel:"public_reference"},
  {id:"gynecology",category:"medical",name:{fr:"Gynécologie-obstétrique",ar:"أمراض النساء والتوليد",en:"Gynecology and obstetrics"},aliases:["gynécologie","gynecologie","obstétrique","obstetrique","نساء","ولادة","gynecology","obstetrics"],referenceLevel:"public_reference"},
  {id:"general-surgery",category:"surgical",name:{fr:"Chirurgie générale",ar:"الجراحة العامة",en:"General surgery"},aliases:["chirurgie générale","chirurgie generale","جراحة","general surgery"],referenceLevel:"public_reference"},
  {id:"orthopedics",category:"surgical",name:{fr:"Orthopédie",ar:"جراحة العظام",en:"Orthopedics"},aliases:["orthopédie","orthopedie","os","عظام","orthopedics"],referenceLevel:"public_reference"},
  {id:"urology",category:"surgical",name:{fr:"Urologie",ar:"جراحة المسالك البولية",en:"Urology"},aliases:["urologie","urinaire","مسالك","urology"],referenceLevel:"public_reference"},
  {id:"ent",category:"surgical",name:{fr:"ORL",ar:"الأنف والأذن والحنجرة",en:"ENT"},aliases:["orl","oto-rhino","oreille","nez","gorge","أنف","أذن","حنجرة","ent"],referenceLevel:"public_reference"},
  {id:"ophthalmology",category:"surgical",name:{fr:"Ophtalmologie",ar:"طب العيون",en:"Ophthalmology"},aliases:["ophtalmologie","ophtalmo","œil","oeil","عيون","ophthalmology"],referenceLevel:"public_reference"},
  {id:"maxillofacial",category:"surgical",name:{fr:"Chirurgie maxillo-faciale",ar:"جراحة الوجه والفكين",en:"Maxillofacial surgery"},aliases:["maxillo","maxillo-faciale","mâchoire","machoire","وجه","فك","maxillofacial"],referenceLevel:"public_reference"},
  {id:"anesthesia-reanimation",category:"emergency",name:{fr:"Anesthésie-réanimation",ar:"التخدير والإنعاش",en:"Anesthesia and intensive care"},aliases:["anesthésie","anesthesie","réanimation","reanimation","إنعاش","تخدير","anesthesia","intensive care"],referenceLevel:"public_reference"},
  {id:"emergency",category:"emergency",name:{fr:"Urgences",ar:"الاستعجالي",en:"Emergency department"},aliases:["urgence","urgences","استعجالي","طوارئ","emergency"],referenceLevel:"public_reference"},
  {id:"occupational-medicine",category:"support",name:{fr:"Médecine du travail",ar:"طب الشغل",en:"Occupational medicine"},aliases:["médecine du travail","medecine du travail","طب الشغل","occupational medicine"],referenceLevel:"public_reference"},
  {id:"forensic-medicine",category:"support",name:{fr:"Médecine légale",ar:"الطب الشرعي",en:"Forensic medicine"},aliases:["médecine légale","medecine legale","شرعي","forensic medicine"],referenceLevel:"public_reference"},
  {id:"dental",category:"support",name:{fr:"Médecine dentaire",ar:"طب الأسنان",en:"Dental medicine"},aliases:["dentaire","dent","أسنان","dental"],referenceLevel:"public_reference"},
  {id:"pathology",category:"diagnostic",name:{fr:"Anatomie pathologique",ar:"التشريح المرضي",en:"Pathology"},aliases:["anatomie pathologique","anapath","تشريح مرضي","pathology"],referenceLevel:"public_reference"},
  {id:"clinical-biology",category:"diagnostic",name:{fr:"Biologie clinique / Laboratoires",ar:"التحاليل والبيولوجيا السريرية",en:"Clinical biology / Laboratories"},aliases:["laboratoire","labo","biochimie","immunologie","microbiologie","hématologie","hematologie","تحاليل","مخبر","laboratory","clinical biology"],referenceLevel:"public_reference"},
  {id:"pharmacovigilance",category:"support",name:{fr:"Centre national de pharmacovigilance",ar:"المركز الوطني لليقظة الدوائية",en:"National pharmacovigilance center"},aliases:["pharmacovigilance","médicament","medicament","دواء","يقظة دوائية"],referenceLevel:"public_reference"},
  {id:"blood-bank",category:"support",name:{fr:"Banque du sang",ar:"بنك الدم",en:"Blood bank"},aliases:["banque du sang","sang","دم","blood bank"],referenceLevel:"public_reference"},
  {id:"psychiatry-consultation",category:"medical",name:{fr:"Consultation de psychiatrie",ar:"استشارة الطب النفسي",en:"Psychiatry consultation"},aliases:["psychiatrie","psy","نفسي","psychiatry"],referenceLevel:"public_reference"}
];

const copy:Record<Locale,{kind:string;scope:string;emergency:string;arrival:string;mapLabel:string}> = {
  ar:{
    kind:"مستشفى عمومي جامعي متعدّد الاختصاصات",
    scope:"هاني ينجم يجاوب على معلومات المستشفى العامة، يلقى المصلحة المناسبة، ويتبع معاك الرحلة من قبل الموعد حتى بعد الزيارة. المواعيد والمسارات الداخلية الدقيقة تتأكد من بيانات المنصة.",
    emergency:"إذا الحالة استعجالية طبياً، اتصل بالاستعجالي أو توجّه مباشرةً لطاقم صحي.",
    arrival:"للوصول للمستشفى، افتح الاتجاهات في تطبيق الخرائط. وقت توصل، هاني ينجم يوجّهك للمصلحة إذا المسار موجود في المنصة.",
    mapLabel:"افتح الاتجاهات إلى المستشفى"
  },
  fr:{
    kind:"Hôpital public universitaire polyvalent",
    scope:"Heni peut répondre aux informations générales de l’hôpital, trouver le bon service et accompagner le parcours avant, pendant et après le rendez-vous. Les rendez-vous et parcours intérieurs précis restent liés aux données de la plateforme.",
    emergency:"En cas d’urgence médicale, contactez les urgences ou adressez-vous immédiatement au personnel de santé.",
    arrival:"Pour venir à l’hôpital, ouvrez l’itinéraire dans votre application de cartes. Une fois sur place, Heni peut vous guider vers le service lorsque le parcours est disponible dans la plateforme.",
    mapLabel:"Ouvrir l’itinéraire vers l’hôpital"
  },
  en:{
    kind:"General public university hospital",
    scope:"Heni can answer general hospital questions, help find the right department and support the journey before, during and after an appointment. Exact appointments and indoor routes remain tied to platform data.",
    emergency:"For a medical emergency, contact emergency services or on-site healthcare staff immediately.",
    arrival:"To reach the hospital, open directions in your maps app. Once you arrive, Heni can guide you to the department when that route is available in the platform.",
    mapLabel:"Open directions to the hospital"
  }
};

const APP_HELP:Record<string,Localized>={
  home:{fr:"Depuis l’accueil patient, vous pouvez voir votre prochain rendez-vous, vos étapes et ouvrir Heni.",ar:"من الصفحة الرئيسية للمريض تنجم تشوف موعدك الجاي، خطوات الرحلة، وتفتح هاني.",en:"From the patient home you can see your next appointment, journey steps and open Heni."},
  services:{fr:"Ouvrez Services pour rechercher une spécialité, lire les informations disponibles et commencer une demande de rendez-vous.",ar:"افتح الخدمات باش تفتّش على اختصاص، تشوف المعلومات، وتبدأ طلب موعد.",en:"Open Services to search for a specialty, read available information and start an appointment request."},
  appointments:{fr:"Rendez-vous affiche vos rendez-vous confirmés. Heni peut aussi vérifier, déplacer ou annuler un rendez-vous après votre confirmation.",ar:"صفحة المواعيد توريك المواعيد المؤكدة. هاني ينجم زادة يثبت، يبدّل أو يلغي موعد بعد تأكيدك.",en:"Appointments shows your confirmed visits. Heni can also check, reschedule or cancel after your confirmation."},
  journey:{fr:"Parcours rassemble les étapes avant la visite, le guidage le jour J et les instructions après la visite.",ar:"الرحلة تجمع التحضير قبل الزيارة، التوجيه نهار الموعد، والتعليمات بعد الزيارة.",en:"Journey brings together preparation before the visit, guidance on the day and follow-up instructions after the visit."},
  map:{fr:"Carte affiche l’hôpital, votre localisation et l’accès au guidage disponible.",ar:"الخريطة توري المستشفى، موقعك، والدخول للتوجيه المتوفر.",en:"Map shows the hospital, your location and available guidance."},
  ar:{fr:"Le mode AR affiche le parcours vidéo de démonstration vers la Médecine nucléaire avec les indications de Heni.",ar:"وضع AR يوري مسار الفيديو نحو الطب النووي مع توجيهات هاني.",en:"AR mode shows the video walkthrough toward Nuclear Medicine with Heni guidance."},
  medicine:{fr:"Le module médicament peut lire le texte visible d’un emballage et retrouver uniquement des instructions déjà validées; il ne change jamais une dose.",ar:"ميزة الدواء تنجم تقرى الكتابة الظاهرة على العلبة وتلقى كان تعليمات مصادق عليها؛ ما تبدّلش الجرعة.",en:"The medicine feature can read visible package text and retrieve only approved instructions; it never changes a dose."},
  language:{fr:"Vous pouvez changer entre tunisien/arabe, français et anglais. Heni suit aussi la langue utilisée dans la conversation.",ar:"تنجم تبدّل بين التونسي/العربي، الفرنسي والإنجليزي. هاني زادة يتبع اللغة اللي تحكي بيها.",en:"You can switch between Tunisian/Arabic, French and English. Heni also follows the language you use in conversation."},
  voice:{fr:"Appuyez sur le micro de Heni pour parler naturellement. Vous pouvez l’interrompre, changer de langue et continuer la même tâche.",ar:"اضغط على ميكرو هاني واحكي عادي. تنجم تقاطعو، تبدّل اللغة، وتكمّل نفس الطلب.",en:"Tap Heni’s microphone to speak naturally. You can interrupt, switch language and continue the same task."}
};

function normalize(value:string){
  return value.normalize("NFD").replace(/[\u0300-\u036f]/g,"").toLowerCase().trim();
}

export function publicHospitalKnowledge(locale:Locale){
  const language=copy[locale]??copy.fr;
  return {
    ...CHARLES_NICOLLE_PUBLIC_KNOWLEDGE,
    description:language.kind,
    scope:language.scope,
    emergencyGuidance:language.emergency,
    serviceDirectoryCount:directory.length
  };
}

export function hospitalAccess(locale:Locale){
  const language=copy[locale]??copy.fr;
  const {hospital}=CHARLES_NICOLLE_PUBLIC_KNOWLEDGE;
  const destination=`${hospital.coordinates.lat},${hospital.coordinates.lon}`;
  return {
    hospitalName:hospital.name,
    address:hospital.address,
    coordinates:hospital.coordinates,
    mainPhone:hospital.mainPhone,
    emergencyPhones:hospital.emergencyPhones,
    instructions:language.arrival,
    uiAction:{
      kind:"open_url",
      label:language.mapLabel,
      url:`https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(destination)}`
    },
    openStreetMapUrl:`https://www.openstreetmap.org/?mlat=${hospital.coordinates.lat}&mlon=${hospital.coordinates.lon}#map=18/${hospital.coordinates.lat}/${hospital.coordinates.lon}`
  };
}

export function searchPublicHospitalDirectory(query:string,locale:Locale,limit=12){
  const q=normalize(query);
  const scored=directory.map(entry=>{
    const values=[entry.name.fr,entry.name.ar,entry.name.en,...entry.aliases].map(normalize);
    const exact=values.some(value=>value===q);
    const includes=!q||values.some(value=>value.includes(q)||q.includes(value));
    return {entry,score:exact?3:includes?2:0};
  }).filter(item=>item.score>0||!q).sort((a,b)=>b.score-a.score||a.entry.name[locale].localeCompare(b.entry.name[locale]));
  return scored.slice(0,Math.max(1,Math.min(limit,30))).map(({entry})=>({
    id:entry.id,
    name:entry.name[locale]||entry.name.fr,
    category:entry.category,
    platformServiceId:entry.platformServiceId??null,
    bookableInHaniMaak:Boolean(entry.platformServiceId),
    referenceLevel:entry.referenceLevel
  }));
}

export function patientAppHelp(topic:string,locale:Locale){
  const q=normalize(topic);
  const aliases:Record<string,string[]>={
    home:["home","accueil","الرئيسية"],
    services:["service","services","خدمة","مصلحة"],
    appointments:["rendez","appointment","موعد"],
    journey:["journey","parcours","رحلة"],
    map:["map","carte","خريطة","location","localisation"],
    ar:["ar","réalité augmentée","realite augmentee","واقع معزز"],
    medicine:["medicine","médicament","medicament","دواء"],
    language:["language","langue","لغة"],
    voice:["voice","voix","micro","صوت"]
  };
  const key=Object.keys(APP_HELP).find(item=>item===q||(aliases[item]??[]).some(alias=>q.includes(normalize(alias))));
  if(key)return {topic:key,instruction:APP_HELP[key][locale]};
  return {topics:Object.keys(APP_HELP).map(item=>({topic:item,instruction:APP_HELP[item][locale]}))};
}
