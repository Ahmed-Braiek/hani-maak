import type { DemoDb, Service, ScheduleRule, FacilityNode, FacilityEdge, ContentTemplate } from "./types";

const now = new Date();
const iso = (d: Date) => d.toISOString();
const afterDays = (days: number, hour: number, minute = 0) => { const d = new Date(now); d.setDate(d.getDate()+days); d.setHours(hour,minute,0,0); return iso(d); };

export const TENANT_ID = "tenant-hani-demo";
export const DEMO_PATIENT_ID = "patient-amal";

const services: Service[] = [
  {
    id:"svc-imaging", tenantId:TENANT_ID, code:"IMG", department:"Imagerie médicale", bookingMode:"direct", slotDurationMin:30, locationNodeId:"node-imaging", active:true, dataProvenance:"demo_seeded",
    name:{fr:"Imagerie médicale",ar:"التصوير الطبي",en:"Medical imaging"},
    description:{fr:"Examens d'imagerie avec préparation et guidage jusqu'au service.",ar:"مواعيد التصوير الطبي مع التحضير والإرشاد إلى المصلحة.",en:"Medical imaging appointments with preparation and on-site guidance."},
    aliases:{fr:["imagerie","radiologie","scanner","radio"],ar:["تصوير","أشعة","سكانار","راديو"],en:["imaging","radiology","scanner"]},
    documents:["Pièce d'identité / Identité","Ordonnance ou demande médicale si disponible"], preparationTemplateId:"content-img-prep", followupTemplateId:"content-img-follow", accessibilityNotes:"Parcours accessible disponible dans le prototype."
  },
  {
    id:"svc-rheum", tenantId:TENANT_ID, code:"RHE", department:"Rhumatologie", bookingMode:"direct", slotDurationMin:30, locationNodeId:"node-rheum", active:true, dataProvenance:"demo_seeded",
    name:{fr:"Rhumatologie",ar:"أمراض الروماتيزم",en:"Rheumatology"}, description:{fr:"Consultation de rhumatologie.",ar:"استشارة في أمراض الروماتيزم.",en:"Rheumatology consultation."},
    aliases:{fr:["rhumato","rhumatologie"],ar:["روماتيزم"],en:["rheumatology"]}, documents:["Pièce d'identité","Dossier médical si disponible"], preparationTemplateId:"content-general-prep", followupTemplateId:"content-general-follow"
  },
  {
    id:"svc-general", tenantId:TENANT_ID, code:"GEN", department:"Consultation générale", bookingMode:"direct", slotDurationMin:20, locationNodeId:"node-general", active:true, dataProvenance:"demo_seeded",
    name:{fr:"Consultation générale",ar:"استشارة عامة",en:"General consultation"}, description:{fr:"Flux général de démonstration.",ar:"مسار استشارة عامة للتجربة.",en:"General consultation demo workflow."},
    aliases:{fr:["général","consultation"],ar:["استشارة","عام"],en:["general","consultation"]}, documents:["Pièce d'identité"], preparationTemplateId:"content-general-prep", followupTemplateId:"content-general-follow"
  }
];

const rules: ScheduleRule[] = [];
for (const service of services) {
  for (const day of [1,2,3,4,5]) {
    rules.push({id:`rule-${service.id}-${day}-am`,tenantId:TENANT_ID,serviceId:service.id,dayOfWeek:day,startTime:"08:00",endTime:"12:00",capacity:service.id==="svc-imaging"?2:1,slotDurationMin:service.slotDurationMin});
    rules.push({id:`rule-${service.id}-${day}-pm`,tenantId:TENANT_ID,serviceId:service.id,dayOfWeek:day,startTime:"13:00",endTime:"15:30",capacity:service.id==="svc-imaging"?2:1,slotDurationMin:service.slotDurationMin});
  }
}

const nodes: FacilityNode[] = [
  {id:"node-main-gate",tenantId:TENANT_ID,code:"GATE",label:{fr:"Entrée principale",ar:"المدخل الرئيسي",en:"Main entrance"},type:"entrance",floor:0,lat:36.802254,lon:10.161104,x:8,y:82,accessible:true,provenance:"demo_seeded"},
  {id:"node-reception",tenantId:TENANT_ID,code:"REC",label:{fr:"Accueil",ar:"الاستقبال",en:"Reception"},type:"reception",floor:0,x:27,y:67,accessible:true,provenance:"demo_seeded"},
  {id:"node-corridor-a",tenantId:TENANT_ID,code:"COR-A",label:{fr:"Couloir A",ar:"الممر أ",en:"Corridor A"},type:"corridor",floor:0,x:49,y:58,accessible:true,provenance:"demo_seeded"},
  {id:"node-elevator",tenantId:TENANT_ID,code:"LIFT",label:{fr:"Ascenseur",ar:"المصعد",en:"Elevator"},type:"elevator",floor:0,x:62,y:42,accessible:true,provenance:"demo_seeded"},
  {id:"node-imaging",tenantId:TENANT_ID,code:"IMG",label:{fr:"Imagerie médicale",ar:"التصوير الطبي",en:"Medical imaging"},type:"department",floor:0,x:88,y:24,accessible:true,provenance:"demo_seeded"},
  {id:"node-rheum",tenantId:TENANT_ID,code:"RHE",label:{fr:"Rhumatologie",ar:"أمراض الروماتيزم",en:"Rheumatology"},type:"department",floor:0,x:82,y:64,accessible:true,provenance:"demo_seeded"},
  {id:"node-general",tenantId:TENANT_ID,code:"GEN",label:{fr:"Consultation générale",ar:"استشارة عامة",en:"General consultation"},type:"department",floor:0,x:41,y:27,accessible:true,provenance:"demo_seeded"}
];
const edges: FacilityEdge[] = [
  {id:"e1",tenantId:TENANT_ID,from:"node-main-gate",to:"node-reception",distanceM:45,bidirectional:true,accessible:true,restricted:false,instruction:{fr:"Entrez puis avancez jusqu'à l'accueil.",ar:"ادخل وتقدّم حتى الاستقبال.",en:"Enter and continue to reception."},provenance:"demo_seeded"},
  {id:"e2",tenantId:TENANT_ID,from:"node-reception",to:"node-corridor-a",distanceM:35,bidirectional:true,accessible:true,restricted:false,instruction:{fr:"Depuis l'accueil, suivez le couloir A.",ar:"من الاستقبال اتبع الممر أ.",en:"From reception, follow corridor A."},provenance:"demo_seeded"},
  {id:"e3",tenantId:TENANT_ID,from:"node-corridor-a",to:"node-elevator",distanceM:22,bidirectional:true,accessible:true,restricted:false,instruction:{fr:"Continuez jusqu'à l'ascenseur.",ar:"واصل حتى المصعد.",en:"Continue to the elevator."},provenance:"demo_seeded"},
  {id:"e4",tenantId:TENANT_ID,from:"node-elevator",to:"node-imaging",distanceM:48,bidirectional:true,accessible:true,restricted:false,instruction:{fr:"Tournez vers l'Imagerie médicale.",ar:"اتجه نحو مصلحة التصوير الطبي.",en:"Turn toward Medical imaging."},provenance:"demo_seeded"},
  {id:"e5",tenantId:TENANT_ID,from:"node-corridor-a",to:"node-rheum",distanceM:55,bidirectional:true,accessible:true,restricted:false,instruction:{fr:"Continuez à droite vers la rhumatologie.",ar:"واصل يميناً نحو الروماتيزم.",en:"Continue right toward Rheumatology."},provenance:"demo_seeded"},
  {id:"e6",tenantId:TENANT_ID,from:"node-corridor-a",to:"node-general",distanceM:38,bidirectional:true,accessible:true,restricted:false,instruction:{fr:"Prenez le couloir secondaire vers la consultation générale.",ar:"اسلك الممر الفرعي نحو الاستشارة العامة.",en:"Take the secondary corridor toward General consultation."},provenance:"demo_seeded"}
];

const content: ContentTemplate[] = [
  {id:"content-img-prep",tenantId:TENANT_ID,type:"preparation",title:{fr:"Préparer votre rendez-vous",ar:"حضّر موعدك",en:"Prepare for your appointment"},body:{fr:"Apportez votre pièce d'identité et la demande médicale si vous en avez une. Les consignes spécifiques à l'examen doivent venir du professionnel de santé.",ar:"أحضر بطاقة الهوية والطلب الطبي إن وُجد. التعليمات الخاصة بالفحص يجب أن تأتي من المهني الصحي.",en:"Bring your ID and medical request if available. Exam-specific instructions must come from the healthcare professional."},version:1,published:true,provenance:"demo_seeded",reviewedBy:"Demo content only"},
  {id:"content-img-follow",tenantId:TENANT_ID,type:"follow_up",title:{fr:"Après la visite",ar:"بعد الزيارة",en:"After the visit"},body:{fr:"Suivez uniquement les instructions données par l'équipe soignante. Hani Maak peut les afficher et vous les rappeler.",ar:"اتبع فقط تعليمات الفريق الصحي. هاني معاك يمكنه عرضها وتذكيرك بها.",en:"Follow only the instructions provided by the care team. Hani Maak can display and remind you of them."},version:1,published:true,provenance:"demo_seeded"},
  {id:"content-general-prep",tenantId:TENANT_ID,type:"preparation",title:{fr:"Avant votre visite",ar:"قبل الزيارة",en:"Before your visit"},body:{fr:"Préparez votre identité et les documents demandés par le service.",ar:"حضّر بطاقة الهوية والوثائق المطلوبة من المصلحة.",en:"Prepare your ID and any documents requested by the service."},version:1,published:true,provenance:"demo_seeded"},
  {id:"content-general-follow",tenantId:TENANT_ID,type:"follow_up",title:{fr:"Votre prochaine étape",ar:"خطوتك القادمة",en:"Your next step"},body:{fr:"Consultez les instructions ajoutées par l'équipe après la visite.",ar:"راجع التعليمات التي أضافها الفريق بعد الزيارة.",en:"Review the instructions added by the care team after the visit."},version:1,published:true,provenance:"demo_seeded"},
  {id:"content-med-demo",tenantId:TENANT_ID,type:"medicine_instruction",title:{fr:"Instruction professionnelle enregistrée",ar:"تعليمات مهنية محفوظة",en:"Saved professional instruction"},body:{fr:"Démonstration: prenez ce médicament uniquement selon l'instruction déjà donnée par votre médecin ou pharmacien. Hani Maak ne modifie pas la dose.",ar:"للتجربة: استعمل الدواء فقط حسب التعليمات التي أعطاها الطبيب أو الصيدلي. هاني معاك لا يغيّر الجرعة.",en:"Demo: use this medicine only according to the instruction already given by your doctor or pharmacist. Hani Maak does not change dosage."},version:1,published:true,provenance:"demo_seeded"}
];

export function createSeedDb(): DemoDb {
  const seededAt = new Date().toISOString();
  return {
    tenant:{id:TENANT_ID,slug:"charles-nicolle-demo",displayName:"Hani Maak — Charles Nicolle Demo",timezone:"Africa/Tunis",defaultLocale:"fr",supportedLocales:["fr","ar","en"],address:"Boulevard 9 Avril 1938, Tunis 1006",phone:"Demo",demoMode:true,brand:{primary:"#0f766e",accent:"#ef6c4d",logoText:"HM"}},
    patients:[
      {id:"patient-amal",tenantId:TENANT_ID,firstName:"Amel",lastName:"Ben Salah",age:61,phone:"+216 20 000 101",email:"amel.demo@example.com",preferredLocale:"fr",preferredChannel:"app",consentStatus:"demo",dataProvenance:"demo_seeded"},
      {id:"patient-hedi",tenantId:TENANT_ID,firstName:"Hédi",lastName:"Trabelsi",age:68,phone:"+216 20 000 102",preferredLocale:"ar",preferredChannel:"phone",consentStatus:"demo",dataProvenance:"demo_seeded"},
      {id:"patient-ines",tenantId:TENANT_ID,firstName:"Inès",lastName:"Mansour",age:34,phone:"+216 20 000 103",preferredLocale:"fr",preferredChannel:"app",consentStatus:"demo",dataProvenance:"demo_seeded"}
    ],
    staff:[
      {id:"staff-salma",tenantId:TENANT_ID,displayName:"Salma — Accueil",role:"receptionist",active:true},
      {id:"staff-youssef",tenantId:TENANT_ID,displayName:"Youssef — Coordinateur",role:"coordinator",active:true},
      {id:"staff-admin",tenantId:TENANT_ID,displayName:"Admin Hani Maak",role:"tenant_admin",active:true}
    ],
    services, scheduleRules:rules,
    scheduleExceptions:[{id:"exc-demo",serviceId:"svc-imaging",date:"2026-09-30",startTime:"13:00",endTime:"15:30",closed:true,reason:"Demo: maintenance block"}],
    appointments:[
      {id:"apt-seed-1",tenantId:TENANT_ID,patientId:"patient-ines",serviceId:"svc-rheum",startAt:afterDays(1,9,0),endAt:afterDays(1,9,30),state:"confirmed",channel:"app",provenance:"demo_seeded",version:1,createdAt:seededAt,updatedAt:seededAt},
      {id:"apt-seed-2",tenantId:TENANT_ID,patientId:"patient-hedi",serviceId:"svc-general",startAt:afterDays(2,10,20),endAt:afterDays(2,10,40),state:"confirmed",channel:"voice",provenance:"demo_seeded",version:1,createdAt:seededAt,updatedAt:seededAt}
    ],
    journeys:[], notifications:[], facilityNodes:nodes, facilityEdges:edges, contentTemplates:content,
    callSessions:[{id:"call-seed-1",tenantId:TENANT_ID,patientId:"patient-hedi",caller:"+216 20 000 102",locale:"ar",startedAt:seededAt,endedAt:seededAt,outcome:"completed",state:"CLOSING",context:{intent:"book",serviceId:"svc-general"},summary:"حجز موعد استشارة عامة عبر المساعد الصوتي — بيانات تجريبية.",transcriptConsent:false}],
    toolEvents:[{id:"tool-seed-1",tenantId:TENANT_ID,callSessionId:"call-seed-1",toolName:"create_appointment",arguments:{serviceId:"svc-general",explicitConfirmation:true},result:{appointmentId:"apt-seed-2",state:"confirmed"},status:"success",latencyMs:142,createdAt:seededAt}],
    escalations:[{id:"esc-seed-1",tenantId:TENANT_ID,patientId:"patient-amal",source:"app",category:"other",summary:"Demo: patient requested help finding the correct entrance.",priority:"normal",state:"open",createdAt:seededAt}],
    auditLog:[], productEvents:[], medicineSessions:[], caregiverDelegations:[], waitlistEntries:[], meta:{seededAt,revision:1}
  };
}
