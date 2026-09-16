import { mutateDb, readDb } from "./db";
import { DEMO_PATIENT_ID, TENANT_ID } from "./seed";
import { appointmentEnd, assertSlotAvailable, getAvailableSlots, tunisDateString } from "./scheduling";
import { shortestRoute } from "./routing";
import { choiceIndex, detectClinicalBoundary, detectIntent, detectPeriod, isAffirmative, type VoiceIntent } from "./voice";
import type { Appointment, AuditEvent, CallSession, DemoDb, Journey, Locale, ProductEvent, Service } from "./types";

const id=(p:string)=>`${p}-${Date.now().toString(36)}-${Math.random().toString(36).slice(2,7)}`;
const now=()=>new Date().toISOString();
const dateIn=(days:number)=>{const d=new Date();d.setDate(d.getDate()+days);return tunisDateString(d)};
function audit(db:DemoDb, action:string, resourceType:string, resourceId?:string, actorType:AuditEvent["actorType"]="system",actorId?:string,metadata:Record<string,unknown>={}){db.auditLog.unshift({id:id("audit"),tenantId:TENANT_ID,actorType,actorId,action,resourceType,resourceId,metadata,createdAt:now()});}
function event(db:DemoDb,eventName:string,properties:Record<string,unknown>={}){const row:ProductEvent={id:id("evt"),tenantId:TENANT_ID,eventName,properties,createdAt:now()};db.productEvents.unshift(row);}

export function findService(db:DemoDb, query:string, locale:Locale="fr"):Service|undefined{
  const q=query.toLowerCase().trim();
  return db.services.filter(s=>s.active).find(s=>[s.name[locale],s.name.fr,s.name.ar,s.name.en,...s.aliases.fr,...s.aliases.ar,...s.aliases.en].some(v=>v.toLowerCase().includes(q)||q.includes(v.toLowerCase())));
}

function buildJourney(db:DemoDb, appointment:Appointment):Journey{
  const service=db.services.find(s=>s.id===appointment.serviceId)!; const prep=db.contentTemplates.find(c=>c.id===service.preparationTemplateId); const follow=db.contentTemplates.find(c=>c.id===service.followupTemplateId); const created=now();
  return {id:id("journey"),tenantId:appointment.tenantId,patientId:appointment.patientId,appointmentId:appointment.id,serviceId:appointment.serviceId,state:"active",createdAt:created,updatedAt:created,steps:[
    {id:id("step"),type:"appointment",sequence:1,state:"completed",title:{fr:"Rendez-vous confirmé",ar:"تم تأكيد الموعد",en:"Appointment confirmed"},body:{fr:`${service.name.fr} — ${new Intl.DateTimeFormat("fr-TN",{dateStyle:"medium",timeStyle:"short",timeZone:"Africa/Tunis"}).format(new Date(appointment.startAt))}`,ar:service.name.ar,en:service.name.en},completedAt:created},
    {id:id("step"),type:"checklist",sequence:2,state:"active",title:prep?.title??{fr:"Préparation",ar:"التحضير",en:"Preparation"},body:prep?.body,dueAt:appointment.startAt,payload:{contentTemplateId:prep?.id,acknowledgeable:true}},
    {id:id("step"),type:"navigation",sequence:3,state:"upcoming",title:{fr:"Trouver le service",ar:"الوصول إلى المصلحة",en:"Find the service"},body:{fr:"Utilisez le guidage Hani Maak le jour du rendez-vous.",ar:"استعمل إرشادات هاني معاك يوم الموعد.",en:"Use Hani Maak guidance on appointment day."},payload:{destinationNodeId:service.locationNodeId,prototype:true}},
    {id:id("step"),type:"human_action",sequence:4,state:"upcoming",title:{fr:"Visite",ar:"الزيارة",en:"Visit"},body:{fr:"Le personnel confirmera la fin de la visite.",ar:"سيؤكد الموظف انتهاء الزيارة.",en:"Staff will mark the visit complete."}},
    {id:id("step"),type:"follow_up",sequence:5,state:"upcoming",title:follow?.title??{fr:"Suivi",ar:"المتابعة",en:"Follow-up"},body:follow?.body,payload:{contentTemplateId:follow?.id}}
  ]};
}

export async function createAppointment(input:{patientId?:string;serviceId:string;startAt:string;channel?:Appointment["channel"];sourceSessionId?:string;idempotencyKey?:string;explicitConfirmation?:boolean}){
  return mutateDb(db=>{
    const patientId=input.patientId??DEMO_PATIENT_ID; if(!db.patients.some(p=>p.id===patientId)) throw new Error("Unknown patient");
    if(input.channel==="voice" && input.explicitConfirmation!==true) throw new Error("Voice booking rejected: explicit confirmation required.");
    if(input.idempotencyKey){const existing=db.auditLog.find(a=>a.action==="appointment.created"&&a.metadata.idempotencyKey===input.idempotencyKey);if(existing?.resourceId){const apt=db.appointments.find(a=>a.id===existing.resourceId);if(apt)return apt;}}
    assertSlotAvailable(db,input.serviceId,input.startAt); const ts=now(); const apt:Appointment={id:id("apt"),tenantId:TENANT_ID,patientId,serviceId:input.serviceId,startAt:input.startAt,endAt:appointmentEnd(db,input.serviceId,input.startAt),state:"confirmed",channel:input.channel??"app",sourceSessionId:input.sourceSessionId,provenance:"user_entered",version:1,createdAt:ts,updatedAt:ts};
    db.appointments.unshift(apt); const journey=buildJourney(db,apt);db.journeys.unshift(journey);
    db.notifications.unshift({id:id("not"),tenantId:TENANT_ID,patientId,journeyStepId:journey.steps[1].id,channel:"in_app",message:"Rappel: préparez les documents demandés avant votre rendez-vous.",state:"queued",scheduledAt:new Date(new Date(apt.startAt).getTime()-24*60*60_000).toISOString(),createdAt:ts});
    audit(db,"appointment.created","appointment",apt.id,input.channel==="voice"?"ai":"patient",patientId,{serviceId:input.serviceId,idempotencyKey:input.idempotencyKey??null,channel:apt.channel}); event(db,"booking_confirmed",{serviceId:input.serviceId,channel:apt.channel}); return apt;
  });
}

export async function cancelAppointment(appointmentId:string, input:{reason?:string;channel?:Appointment["channel"];explicitConfirmation?:boolean}={}){
  return mutateDb(db=>{if(input.channel==="voice"&&input.explicitConfirmation!==true)throw new Error("Voice cancellation rejected: explicit confirmation required.");const a=db.appointments.find(x=>x.id===appointmentId);if(!a)throw new Error("Appointment not found");if(a.state!=="confirmed")throw new Error("Only confirmed appointments can be cancelled");a.state="cancelled";a.cancellationReason=input.reason;a.version++;a.updatedAt=now();const j=db.journeys.find(x=>x.appointmentId===a.id);if(j){j.state="cancelled";j.updatedAt=now()}audit(db,"appointment.cancelled","appointment",a.id,input.channel==="voice"?"ai":"patient",a.patientId,{reason:input.reason??null});event(db,"appointment_cancelled",{channel:input.channel??"app"});return a;});
}

export async function rescheduleAppointment(appointmentId:string,input:{replacementSlotStart:string;channel?:Appointment["channel"];explicitConfirmation?:boolean;idempotencyKey?:string}){
  return mutateDb(db=>{if(input.channel==="voice"&&input.explicitConfirmation!==true)throw new Error("Voice reschedule rejected: explicit confirmation required.");const a=db.appointments.find(x=>x.id===appointmentId);if(!a||a.state!=="confirmed")throw new Error("Confirmed appointment not found");assertSlotAvailable(db,a.serviceId,input.replacementSlotStart);a.startAt=input.replacementSlotStart;a.endAt=appointmentEnd(db,a.serviceId,input.replacementSlotStart);a.version++;a.updatedAt=now();const j=db.journeys.find(x=>x.appointmentId===a.id);if(j){j.updatedAt=now();const prep=j.steps.find(s=>s.type==="checklist");if(prep)prep.dueAt=a.startAt;}audit(db,"appointment.rescheduled","appointment",a.id,input.channel==="voice"?"ai":"patient",a.patientId,{startAt:a.startAt,idempotencyKey:input.idempotencyKey??null});event(db,"appointment_rescheduled",{channel:input.channel??"app"});return a;});
}

export async function completeVisit(appointmentId:string){return mutateDb(db=>{const a=db.appointments.find(x=>x.id===appointmentId);if(!a)throw new Error("Appointment not found");a.state="completed";a.version++;a.updatedAt=now();const j=db.journeys.find(x=>x.appointmentId===a.id);if(j){for(const s of j.steps){if(s.type==="human_action"){s.state="completed";s.completedAt=now()}if(s.type==="follow_up")s.state="active";if(s.type==="navigation"&&s.state!=="completed")s.state="completed";}j.updatedAt=now()}audit(db,"visit.completed","appointment",a.id,"staff","staff-demo");event(db,"visit_completed",{serviceId:a.serviceId});return a;});}
export async function acknowledgeStep(stepId:string){return mutateDb(db=>{for(const j of db.journeys){const step=j.steps.find(s=>s.id===stepId);if(step){if(step.type==="human_action")throw new Error("This step requires staff action");step.state="completed";step.completedAt=now();const next=j.steps.find(s=>s.sequence===step.sequence+1);if(next&&next.state==="upcoming")next.state="active";j.updatedAt=now();audit(db,"journey.step_acknowledged","journey_step",step.id,"patient",j.patientId);return step;}}throw new Error("Step not found")});}

export async function patientSnapshot(patientId=DEMO_PATIENT_ID){const db=await readDb();const patient=db.patients.find(p=>p.id===patientId)!;const appointments=db.appointments.filter(a=>a.patientId===patientId).sort((a,b)=>a.startAt.localeCompare(b.startAt));const active=appointments.find(a=>a.state==="confirmed")??appointments.find(a=>a.state==="completed");const journey=active?db.journeys.find(j=>j.appointmentId===active.id):undefined;return{tenant:db.tenant,patient,services:db.services,appointments,activeAppointment:active,journey,notifications:db.notifications.filter(n=>n.patientId===patientId),escalations:db.escalations.filter(e=>e.patientId===patientId),contentTemplates:db.contentTemplates,caregiverDelegations:db.caregiverDelegations.filter(c=>c.patientId===patientId),waitlistEntries:db.waitlistEntries.filter(w=>w.patientId===patientId)};}
export async function staffSnapshot(){const db=await readDb();const today=tunisDateString(new Date());return{tenant:db.tenant,appointments:db.appointments,patients:db.patients,services:db.services,journeys:db.journeys,calls:db.callSessions,toolEvents:db.toolEvents,escalations:db.escalations,notifications:db.notifications,contentTemplates:db.contentTemplates,nodes:db.facilityNodes,edges:db.facilityEdges,auditLog:db.auditLog.slice(0,30),productEvents:db.productEvents.slice(0,100),scheduleRules:db.scheduleRules,scheduleExceptions:db.scheduleExceptions,caregiverDelegations:db.caregiverDelegations,waitlistEntries:db.waitlistEntries,staff:db.staff,metrics:{appointmentsToday:db.appointments.filter(a=>a.startAt.slice(0,10)===today&&a.state!=="cancelled").length,confirmed:db.appointments.filter(a=>a.state==="confirmed").length,completed:db.appointments.filter(a=>a.state==="completed").length,openEscalations:db.escalations.filter(e=>e.state==="open").length,voiceCalls:db.callSessions.length,toolSuccess:db.toolEvents.filter(t=>t.status==="success").length,journeyCompletion:db.journeys.length?Math.round(100*db.journeys.filter(j=>j.state==="completed").length/db.journeys.length):0}};}
export async function routeTo(serviceId:string,from="node-main-gate",accessible=true){const db=await readDb();const service=db.services.find(s=>s.id===serviceId);if(!service)throw new Error("Service not found");return{service,route:shortestRoute(db.facilityNodes,db.facilityEdges,from,service.locationNodeId,accessible),nodes:db.facilityNodes,edges:db.facilityEdges,provenance:"demo_seeded" as const};}

function tool(db:DemoDb,callId:string,name:string,args:Record<string,unknown>,result:Record<string,unknown>,status:"success"|"error"|"rejected"="success",latencyMs=90){db.toolEvents.unshift({id:id("tool"),tenantId:TENANT_ID,callSessionId:callId,toolName:name,arguments:args,result,status,latencyMs,createdAt:now()});audit(db,`ai.tool.${name}`,"call_session",callId,"ai",callId,{status});}
function replyAr(fr:string, ar:string, locale:Locale){return locale==="ar"?ar:fr;}
export async function newVoiceSession(locale:Locale="ar",patientId="patient-hedi",source="voice_lab"){return mutateDb(db=>{const p=db.patients.find(x=>x.id===patientId);const greeting=replyAr("Bonjour, je suis Hani Maak, l'assistant automatisé. Comment puis-je vous aider ?","عسلامة، أنا هاني معاك، مساعد آلي للإدارة. شنوة نجم نعاونك؟",locale);const c:CallSession={id:id("call"),tenantId:TENANT_ID,patientId,caller:p?.phone??"demo-browser",locale,startedAt:now(),outcome:"active",state:"INTENT_CAPTURE",context:{source,transcript:[{role:"assistant",text:greeting,at:now()}]},transcriptConsent:false};db.callSessions.unshift(c);event(db,"voice_call_started",{channel:source});return{session:c,message:greeting};});}

export async function recordCallExchange(callSessionId:string,userText:string,assistantText:string){return mutateDb(db=>{const c=db.callSessions.find(x=>x.id===callSessionId);if(!c)throw new Error("Call session not found");const current=Array.isArray((c.context as any).transcript)?(c.context as any).transcript:[];const transcript=[...current,{role:"user",text:userText.slice(0,500),at:now()},{role:"assistant",text:assistantText.slice(0,800),at:now()}].slice(-40);c.context={...c.context,transcript};return transcript;});}

export async function voiceTurn(callSessionId:string,userText:string){
  if(!userText.trim())throw new Error("Empty message");
  return mutateDb(db=>{
    const c=db.callSessions.find(x=>x.id===callSessionId);if(!c)throw new Error("Call session not found");const locale=c.locale; const ctx=c.context as Record<string,any>;
    if(detectClinicalBoundary(userText)){const esc={id:id("esc"),tenantId:TENANT_ID,patientId:c.patientId,source:"voice" as const,category:"clinical_boundary" as const,summary:`Clinical-boundary request: ${userText.slice(0,120)}`,priority:"high" as const,state:"open" as const,createdAt:now()};db.escalations.unshift(esc);tool(db,c.id,"create_staff_escalation",{category:"clinical_boundary"},{escalationId:esc.id});c.state="HUMAN_HELP";c.outcome="escalated";return{session:c,message:replyAr("Je ne peux pas modifier un traitement ou une dose. Je peux transmettre votre demande à un professionnel de santé.","ما نجمش نبدّل العلاج ولا الجرعة. نجم نبعث طلبك لمهني صحي باش يعاونك.",locale),tool:"create_staff_escalation"};}
    const intent=detectIntent(userText);
    if(intent==="human_help"){const esc={id:id("esc"),tenantId:TENANT_ID,patientId:c.patientId,source:"voice" as const,category:"human_requested" as const,summary:"Caller requested a human.",priority:"normal" as const,state:"open" as const,createdAt:now()};db.escalations.unshift(esc);tool(db,c.id,"create_staff_escalation",{category:"human_requested"},{escalationId:esc.id});c.state="HUMAN_HELP";c.outcome="escalated";return{session:c,message:replyAr("D'accord. J'ai créé une demande pour qu'un membre de l'équipe vous aide.","حاضر. عملت طلب باش موظف يعاونك.",locale),tool:"create_staff_escalation"};}
    if(c.state==="INTENT_CAPTURE"){
      if(intent==="unknown")return{session:c,message:replyAr("Je peux prendre, annuler ou déplacer un rendez-vous, donner des instructions approuvées ou vous guider dans l'établissement.","نجم نحجز، نلغي ولا نبدّل موعد، نعطيك التعليمات المعتمدة ولا نوجّهك داخل المؤسسة.",locale)};
      ctx.intent=intent;c.state=intent==="book"?"SERVICE_RESOLUTION":intent.toUpperCase();
    }
    if(c.state==="SERVICE_RESOLUTION"){
      const s=findService(db,userText,locale);if(!s){return{session:c,message:replyAr("Quel service cherchez-vous ? Par exemple imagerie, rhumatologie ou consultation générale.","شنية المصلحة اللي تحب عليها؟ مثلاً التصوير الطبي، الروماتيزم ولا استشارة عامة.",locale)}}ctx.serviceId=s.id;tool(db,c.id,"search_services",{query:userText,locale},{serviceId:s.id,name:s.name[locale]});c.state="PREFERENCE_CAPTURE";return{session:c,message:replyAr(`Très bien, ${s.name.fr}. Vous préférez le matin ou l'après-midi ?`,`${s.name.ar}. تحب الموعد صباح ولا العشية؟`,locale),tool:"search_services"};
    }
    if(c.state==="PREFERENCE_CAPTURE"){
      const period=detectPeriod(userText);if(!period)return{session:c,message:replyAr("Dites-moi simplement: matin ou après-midi.","قلي برك: صباح ولا العشية.",locale)};ctx.period=period;const slots=getAvailableSlots(db,ctx.serviceId,dateIn(1),dateIn(14),period,3);ctx.slots=slots;tool(db,c.id,"get_available_slots",{serviceId:ctx.serviceId,period},{slots:slots.map(s=>s.startAt)});c.state="SLOT_CHOICE";if(!slots.length)return{session:c,message:replyAr("Je n'ai pas trouvé de créneau disponible dans cette période. Je peux essayer une autre période.","ما لقيتش موعد متوفر في الفترة هاذي. نجم نجرب فترة أخرى.",locale),tool:"get_available_slots"};const options=slots.map((s,i)=>`${i+1}) ${s.label}`).join(" · ");return{session:c,message:replyAr(`J'ai ${options}. Dites 1, 2 ou 3.`,`لقيت ${options}. اختار 1 ولا 2 ولا 3.`,locale),tool:"get_available_slots",slots};
    }
    if(c.state==="SLOT_CHOICE"){
      const n=choiceIndex(userText);const slots=ctx.slots??[];if(n==null||!slots[n])return{session:c,message:replyAr("Choisissez le créneau 1, 2 ou 3.","اختار الموعد 1 ولا 2 ولا 3.",locale)};ctx.selectedSlot=slots[n].startAt;c.state="CONFIRM_ACTION";const s=db.services.find(x=>x.id===ctx.serviceId)!;return{session:c,message:replyAr(`Je vais réserver ${s.name.fr}, ${slots[n].label}. Confirmez-vous ?`, `باش نحجز ${s.name.ar}، ${slots[n].label}. تأكد؟`,locale)};
    }
    if(c.state==="CONFIRM_ACTION"){
      if(!isAffirmative(userText))return{session:c,message:replyAr("Je n'ai rien modifié. Dites oui pour confirmer ou demandez un autre créneau.","ما بدّلت حتى شي. قول إي باش تأكد ولا اطلب موعد آخر.",locale)};
      const patientId=c.patientId??DEMO_PATIENT_ID;const startAt=ctx.selectedSlot;assertSlotAvailable(db,ctx.serviceId,startAt);const ts=now();let apt:Appointment;let toolName="create_appointment";
      if(ctx.rescheduleAppointmentId){const existing=db.appointments.find(a=>a.id===ctx.rescheduleAppointmentId&&a.patientId===patientId&&a.state==="confirmed");if(!existing)throw new Error("Original appointment is no longer available to reschedule");existing.serviceId=ctx.serviceId;existing.startAt=startAt;existing.endAt=appointmentEnd(db,ctx.serviceId,startAt);existing.version++;existing.updatedAt=ts;apt=existing;toolName="reschedule_appointment";const j=db.journeys.find(j=>j.appointmentId===apt.id);if(j){j.serviceId=ctx.serviceId;j.updatedAt=ts;const nav=j.steps.find(s=>s.type==="navigation");const svc=db.services.find(s=>s.id===ctx.serviceId);if(nav&&svc)nav.payload={...(nav.payload??{}),destinationNodeId:svc.locationNodeId};}audit(db,"appointment.rescheduled","appointment",apt.id,"ai",c.id,{channel:"voice",startAt});event(db,"voice_call_task_completed",{intent:"reschedule"});}
      else{apt={id:id("apt"),tenantId:TENANT_ID,patientId,serviceId:ctx.serviceId,startAt,endAt:appointmentEnd(db,ctx.serviceId,startAt),state:"confirmed",channel:"voice",sourceSessionId:c.id,provenance:"user_entered",version:1,createdAt:ts,updatedAt:ts};db.appointments.unshift(apt);db.journeys.unshift(buildJourney(db,apt));audit(db,"appointment.created","appointment",apt.id,"ai",c.id,{channel:"voice"});event(db,"voice_call_task_completed",{intent:"book"});}
      tool(db,c.id,toolName,{patientRef:patientId,appointmentId:ctx.rescheduleAppointmentId??undefined,serviceId:ctx.serviceId,slotStart:startAt,explicitConfirmation:true},{appointmentId:apt.id,state:apt.state,startAt:apt.startAt});c.state="INSTRUCTIONS_OPTION";ctx.appointmentId=apt.id;return{session:c,message:replyAr(`C'est confirmé. Votre rendez-vous est ${new Intl.DateTimeFormat("fr-TN",{dateStyle:"full",timeStyle:"short",timeZone:"Africa/Tunis"}).format(new Date(apt.startAt))}. Voulez-vous les instructions de préparation ?`,`تمّ التأكيد. موعدك ${new Intl.DateTimeFormat("fr-TN",{dateStyle:"full",timeStyle:"short",timeZone:"Africa/Tunis"}).format(new Date(apt.startAt))}. تحب تعليمات التحضير؟`,locale),tool:toolName,appointment:apt};
    }
    if(c.state==="INSTRUCTIONS_OPTION"){
      const svc=db.services.find(x=>x.id===ctx.serviceId)!;const content=db.contentTemplates.find(x=>x.id===svc.preparationTemplateId&&x.published);tool(db,c.id,"get_service_instructions",{serviceId:svc.id},{contentId:content?.id??null});c.state="CLOSING";c.outcome="completed";c.endedAt=now();c.summary=`${ctx.intent??"request"} — ${svc.name.fr} — ${ctx.appointmentId??"no write"}`;return{session:c,message:content?.body[locale]??replyAr("Les instructions ne sont pas disponibles. Je peux demander à l'équipe.","التعليمات موش متوفرة. نجم نطلب من الفريق.",locale),tool:"get_service_instructions"};
    }
    if(c.state==="DIRECTIONS"||intent==="directions"){
      const patientId=c.patientId??DEMO_PATIENT_ID;const apt=db.appointments.find(a=>a.patientId===patientId&&a.state==="confirmed");const svc=apt?db.services.find(s=>s.id===apt.serviceId):db.services.find(s=>s.id==="svc-imaging")!;const route=shortestRoute(db.facilityNodes,db.facilityEdges,"node-main-gate",svc!.locationNodeId,true);tool(db,c.id,"get_navigation_route",{from:"node-main-gate",to:svc!.locationNodeId},{distanceM:route.distanceM,nodeIds:route.nodeIds});c.state="CLOSING";return{session:c,message:replyAr(`Depuis l'entrée principale, passez par l'accueil. Le trajet prototype vers ${svc!.name.fr} fait environ ${route.distanceM} m. Ouvrez la carte Hani Maak pour les étapes.`,`من المدخل الرئيسي امشي للاستقبال. المسار التجريبي نحو ${svc!.name.ar} حوالي ${route.distanceM} متر. افتح خريطة هاني معاك للخطوات.`,locale),tool:"get_navigation_route"};
    }
    if(c.state==="INSTRUCTIONS"||intent==="instructions"){
      const patientId=c.patientId??DEMO_PATIENT_ID;const apt=db.appointments.find(a=>a.patientId===patientId&&a.state==="confirmed");const svc=(ctx.serviceId?db.services.find(s=>s.id===ctx.serviceId):undefined)??(apt?db.services.find(s=>s.id===apt.serviceId):undefined)??db.services.find(s=>s.id==="svc-imaging")!;const content=db.contentTemplates.find(x=>x.id===svc.preparationTemplateId&&x.published);tool(db,c.id,"get_service_instructions",{serviceId:svc.id},{contentId:content?.id??null});return{session:c,message:content?.body[locale]??replyAr("Les instructions approuvées ne sont pas encore disponibles. Je peux demander à l'équipe.","التعليمات المعتمدة موش متوفرة توّا. نجم نطلبها من الفريق.",locale),tool:"get_service_instructions"};
    }
    if(c.state==="NEXT_STEPS"||intent==="next_steps"){
      const patientId=c.patientId??DEMO_PATIENT_ID;const apt=db.appointments.find(a=>a.patientId===patientId&&a.state==="confirmed")??db.appointments.find(a=>a.patientId===patientId&&a.state==="completed");if(!apt){tool(db,c.id,"get_patient_next_steps",{patientRef:patientId},{steps:[]});return{session:c,message:replyAr("Vous n'avez pas de parcours actif dans cette démonstration. Je peux vous aider à prendre un rendez-vous.","ما عندكش مسار نشط في التجربة هاذي. نجم نعاونك تحجز موعد.",locale),tool:"get_patient_next_steps"};}const svc=db.services.find(s=>s.id===apt.serviceId);const journey=db.journeys.find(j=>j.appointmentId===apt.id);const step=journey?.steps.find(s=>s.state==="active")??journey?.steps.find(s=>s.state==="upcoming");tool(db,c.id,"get_patient_next_steps",{patientRef:patientId},{appointmentId:apt.id,stepId:step?.id??null,stepType:step?.type??null});if(step){return{session:c,message:replyAr(`Votre prochaine étape est: ${step.title.fr}. ${step.body?.fr??""}`,`خطوتك الجاية: ${step.title.ar}. ${step.body?.ar??""}`,locale),tool:"get_patient_next_steps"};}return{session:c,message:replyAr(`Votre rendez-vous ${svc?.name.fr??""} est enregistré. L'équipe peut compléter les prochaines étapes.`,`موعدك ${svc?.name.ar??""} مسجّل. الفريق ينجم يكمل الخطوات الجاية.`,locale),tool:"get_patient_next_steps"};
    }
    if(c.state==="CANCEL"||intent==="cancel"){
      const apt=db.appointments.find(a=>a.patientId===c.patientId&&a.state==="confirmed");if(!apt)return{session:c,message:replyAr("Je ne trouve pas de rendez-vous confirmé à annuler.","ما لقيتش موعد مؤكد باش نلغيه.",locale)};if(!ctx.cancelPending){ctx.cancelPending=apt.id;return{session:c,message:replyAr(`Je trouve le rendez-vous ${new Intl.DateTimeFormat("fr-TN",{dateStyle:"medium",timeStyle:"short",timeZone:"Africa/Tunis"}).format(new Date(apt.startAt))}. Voulez-vous vraiment l'annuler ?`,`لقيت الموعد ${new Intl.DateTimeFormat("fr-TN",{dateStyle:"medium",timeStyle:"short",timeZone:"Africa/Tunis"}).format(new Date(apt.startAt))}. متأكد تحب تلغيه؟`,locale)}}if(!isAffirmative(userText))return{session:c,message:replyAr("Aucune annulation effectuée.","ما لغيت حتى موعد.",locale)};apt.state="cancelled";apt.updatedAt=now();apt.version++;tool(db,c.id,"cancel_appointment",{appointmentId:apt.id,explicitConfirmation:true},{state:"cancelled"});c.state="CLOSING";c.outcome="completed";return{session:c,message:replyAr("Le rendez-vous est annulé.","تم إلغاء الموعد.",locale),tool:"cancel_appointment"};
    }
    if(c.state==="RESCHEDULE"||intent==="reschedule"){ctx.intent="book";c.state="SERVICE_RESOLUTION";const apt=db.appointments.find(a=>a.patientId===c.patientId&&a.state==="confirmed");ctx.rescheduleAppointmentId=apt?.id;return{session:c,message:replyAr("D'accord. Pour le prototype, choisissons d'abord le service puis une nouvelle heure.","حاضر. في النموذج التجريبي نختاروا المصلحة وبعد موعد جديد.",locale)};}
    return{session:c,message:replyAr("Je suis prêt. Vous pouvez demander un rendez-vous, des directions ou de l'aide humaine.","أنا حاضر. تنجم تطلب موعد، إرشادات، ولا مساعدة من موظف.",locale)};
  });
}

export async function medicineAnalyze(patientId:string,fileName:string){return mutateDb(db=>{const lower=fileName.toLowerCase();const demo=lower.includes("paracetamol")||lower.includes("doliprane")||lower.includes("demo");const expiry=lower.includes("expired")?"2025-03-31":"2027-12-31";const row={id:id("med"),tenantId:TENANT_ID,patientId,fileName,extracted:{detectedName:demo?"Paracetamol — DEMO":"Visible package text needs confirmation",detectedStrengthText:demo?"500 mg — detected text":undefined,expiryText:expiry,expiryDateISO:expiry,lotText:"DEMO-LOT",confidenceNotes:[demo?"High confidence on seeded demo filename mapping.":"Prototype extraction is uncertain; confirm manually.","Expiry date alone cannot determine medicine suitability or package condition."]},confirmed:false,linkedInstructionId:demo?"content-med-demo":undefined,outcome:"needs_confirmation" as const,createdAt:now()};db.medicineSessions.unshift(row);event(db,"medicine_clarification_started",{hasSeedMatch:demo});return{session:row,instruction:demo?db.contentTemplates.find(c=>c.id==="content-med-demo"):undefined,expired:new Date(expiry)<new Date(),safety:"Hani Maak does not diagnose, prescribe, change dosage, or certify that a medicine is safe to take. Ask a pharmacist or clinician when uncertain."};});}

export async function addCaregiverDelegation(input:{patientId?:string;caregiverName:string;caregiverPhone:string;scopes?:string[]}){return mutateDb(db=>{const row={id:id("caregiver"),tenantId:TENANT_ID,patientId:input.patientId??DEMO_PATIENT_ID,caregiverName:input.caregiverName.slice(0,100),caregiverPhone:input.caregiverPhone.slice(0,40),scopes:(input.scopes?.filter(s=>["appointments","journey","reminders"].includes(s)) as any)??["appointments","journey"],createdAt:now()};db.caregiverDelegations.unshift(row);audit(db,"caregiver.delegated","caregiver_delegation",row.id,"patient",row.patientId,{scopes:row.scopes});return row;});}
export async function joinWaitlist(input:{patientId?:string;serviceId:string;currentAppointmentId?:string;preferredPeriod?:"morning"|"afternoon";fromDate:string;toDate:string}){return mutateDb(db=>{if(!db.services.some(s=>s.id===input.serviceId))throw new Error("Unknown service");const existing=db.waitlistEntries.find(w=>w.patientId===(input.patientId??DEMO_PATIENT_ID)&&w.serviceId===input.serviceId&&w.state==="active");if(existing)return existing;const row={id:id("wait"),tenantId:TENANT_ID,patientId:input.patientId??DEMO_PATIENT_ID,serviceId:input.serviceId,currentAppointmentId:input.currentAppointmentId,preferredPeriod:input.preferredPeriod,fromDate:input.fromDate,toDate:input.toDate,state:"active" as const,createdAt:now()};db.waitlistEntries.unshift(row);audit(db,"waitlist.joined","waitlist",row.id,"patient",row.patientId,{serviceId:row.serviceId});event(db,"waitlist_joined",{serviceId:row.serviceId});return row;});}
export async function updateMedicineExtraction(sessionId:string, extracted:any){return mutateDb(db=>{const s=db.medicineSessions.find(v=>v.id===sessionId);if(!s)throw new Error("Medicine session not found");s.extracted={...s.extracted,...extracted,confidenceNotes:Array.isArray(extracted.confidenceNotes)?extracted.confidenceNotes:s.extracted.confidenceNotes};s.outcome="needs_confirmation";audit(db,"medicine.vision_extracted","medicine_image_session",s.id,"ai",undefined,{provider:"configured_multimodal_model"});return s;});}

export async function startLiveCall(input:{externalCallId?:string;caller?:string;locale?:Locale}){
  return mutateDb(db=>{
    const caller=input.caller??"unknown";
    const patient=db.patients.find(p=>p.phone.replace(/\s/g,"")===caller.replace(/\s/g,""))??db.patients.find(p=>p.id==="patient-hedi");
    const c:CallSession={
      id:id("call-live"),tenantId:TENANT_ID,patientId:patient?.id,externalCallId:input.externalCallId,
      caller,locale:input.locale??patient?.preferredLocale??"ar",startedAt:now(),outcome:"active",state:"LIVE_CONNECTED",
      context:{source:"twilio_realtime"},transcriptConsent:false
    };
    db.callSessions.unshift(c);
    audit(db,"voice.live.started","call_session",c.id,"system",undefined,{externalCallId:input.externalCallId??null});
    event(db,"voice_call_started",{channel:"phone"});
    return c;
  });
}

export async function recordLiveToolEvent(input:{callSessionId:string;toolName:string;arguments?:Record<string,unknown>;result?:Record<string,unknown>;status?:"success"|"error"|"rejected";latencyMs?:number}){
  return mutateDb(db=>{
    const call=db.callSessions.find(c=>c.id===input.callSessionId);
    if(!call)throw new Error("Call session not found");
    tool(db,call.id,input.toolName,input.arguments??{},input.result??{},input.status??"success",input.latencyMs??0);
    call.context={...call.context,lastTool:input.toolName,lastToolAt:now()};
    return db.toolEvents[0];
  });
}

export async function finishLiveCall(input:{callSessionId:string;outcome?:CallSession["outcome"];summary?:string;state?:string}){
  return mutateDb(db=>{
    const call=db.callSessions.find(c=>c.id===input.callSessionId);
    if(!call)throw new Error("Call session not found");
    call.endedAt=now();
    call.outcome=input.outcome??(call.outcome==="active"?"completed":call.outcome);
    call.state=input.state??"CLOSING";
    if(input.summary)call.summary=input.summary.slice(0,500);
    audit(db,"voice.live.finished","call_session",call.id,"system",undefined,{outcome:call.outcome});
    event(db,"voice_call_finished",{outcome:call.outcome});
    return call;
  });
}
