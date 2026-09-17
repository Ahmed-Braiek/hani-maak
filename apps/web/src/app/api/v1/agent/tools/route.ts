import {timingSafeEqual} from "node:crypto";
import {NextResponse} from "next/server";
import {mutateDb,readDb} from "@/lib/db";
import {cancelAppointment,createAppointment,patientSnapshot,rescheduleAppointment,routeTo} from "@/lib/operations";
import {getAvailableSlots,tunisDateString} from "@/lib/scheduling";
import {TENANT_ID} from "@/lib/seed";
import type {Locale} from "@/lib/types";

export const dynamic="force-dynamic";

function secureEqual(left:string|undefined,right:string|undefined){
  if(!left||!right)return false;
  const a=Buffer.from(left);const b=Buffer.from(right);
  return a.length===b.length&&timingSafeEqual(a,b);
}
function localeOf(value:unknown):Locale{return value==="ar"||value==="en"||value==="fr"?value:"ar"}
function text(value:unknown,max=240){return String(value??"").trim().slice(0,max)}
function localStart(date:unknown,time:unknown){
  const d=text(date,10),t=text(time,5);
  if(!/^\d{4}-\d{2}-\d{2}$/.test(d)||!/^\d{2}:\d{2}$/.test(t))throw new Error("invalid_date_or_time");
  const value=new Date(`${d}T${t}:00+01:00`);
  if(Number.isNaN(value.getTime()))throw new Error("invalid_date_or_time");
  return value.toISOString();
}
function plusDays(ymd:string,days:number){const d=new Date(`${ymd}T12:00:00Z`);d.setUTCDate(d.getUTCDate()+days);return d.toISOString().slice(0,10)}
function localized<T extends Record<Locale,string>>(value:T,locale:Locale){return value[locale]||value.fr||value.en||value.ar}
function id(prefix:string){return `${prefix}-${Date.now().toString(36)}-${Math.random().toString(36).slice(2,8)}`}

export async function POST(req:Request){
  const configured=process.env.HENI_AGENT_SHARED_SECRET;
  if(!configured)return NextResponse.json({error:"agent_bridge_not_configured"},{status:503});
  if(!secureEqual(req.headers.get("x-heni-agent-key")??undefined,configured))return NextResponse.json({error:"unauthorized"},{status:401});

  try{
    const body=await req.json().catch(()=>({}));
    const tool=text(body?.tool,80);
    const args=(body?.args&&typeof body.args==="object"?body.args:{}) as Record<string,unknown>;
    const context=(body?.context&&typeof body.context==="object"?body.context:{}) as Record<string,unknown>;
    const patientId=text(context.patientId,120);
    const locale=localeOf(context.locale);
    const source=context.source==="voice"?"voice":"app";
    if(!patientId)return NextResponse.json({error:"patient_context_required"},{status:400});

    const db=await readDb();
    if(!db.patients.some(patient=>patient.id===patientId))return NextResponse.json({error:"patient_not_found"},{status:404});

    if(tool==="get_patient_context"){
      const snapshot=await patientSnapshot(patientId);
      const service=snapshot.activeAppointment?db.services.find(item=>item.id===snapshot.activeAppointment?.serviceId):undefined;
      return NextResponse.json({success:true,patient:{id:snapshot.patient.id,firstName:snapshot.patient.firstName,preferredLocale:snapshot.patient.preferredLocale},activeAppointment:snapshot.activeAppointment?{id:snapshot.activeAppointment.id,state:snapshot.activeAppointment.state,startAt:snapshot.activeAppointment.startAt,serviceId:snapshot.activeAppointment.serviceId,serviceName:service?localized(service.name,locale):undefined}:null,journey:snapshot.journey?{id:snapshot.journey.id,state:snapshot.journey.state,steps:snapshot.journey.steps.map(step=>({type:step.type,state:step.state,title:localized(step.title,locale),body:step.body?localized(step.body,locale):undefined}))}:null});
    }

    if(tool==="find_services"){
      const query=text(args.query,120).toLocaleLowerCase();
      const services=db.services.filter(service=>service.active).filter(service=>{
        if(!query)return true;
        const values=[...Object.values(service.name),...Object.values(service.description),...service.aliases.fr,...service.aliases.ar,...service.aliases.en];
        return values.some(value=>value.toLocaleLowerCase().includes(query)||query.includes(value.toLocaleLowerCase()));
      }).slice(0,6).map(service=>({id:service.id,name:localized(service.name,locale),description:localized(service.description,locale),department:service.department,bookingMode:service.bookingMode,documents:service.documents}));
      return NextResponse.json({success:true,services});
    }

    if(tool==="get_service_details"){
      const serviceId=text(args.serviceId,120);const service=db.services.find(item=>item.id===serviceId&&item.active);
      if(!service)return NextResponse.json({success:false,error:"service_not_found"},{status:404});
      const prep=service.preparationTemplateId?db.contentTemplates.find(item=>item.id===service.preparationTemplateId&&item.published):undefined;
      const follow=service.followupTemplateId?db.contentTemplates.find(item=>item.id===service.followupTemplateId&&item.published):undefined;
      return NextResponse.json({success:true,service:{id:service.id,name:localized(service.name,locale),description:localized(service.description,locale),department:service.department,bookingMode:service.bookingMode,slotDurationMin:service.slotDurationMin,documents:service.documents,preparation:prep?{title:localized(prep.title,locale),body:localized(prep.body,locale)}:null,followUp:follow?{title:localized(follow.title,locale),body:localized(follow.body,locale)}:null}});
    }

    if(tool==="check_appointment_availability"){
      const serviceId=text(args.serviceId,120);if(!db.services.some(item=>item.id===serviceId&&item.active))return NextResponse.json({success:false,error:"service_not_found"},{status:404});
      const requested=text(args.date,10);const fromDate=requested||tunisDateString(new Date());
      if(!/^\d{4}-\d{2}-\d{2}$/.test(fromDate))return NextResponse.json({success:false,error:"invalid_date"},{status:400});
      const toDate=requested?requested:plusDays(fromDate,14);
      const slots=getAvailableSlots(db,serviceId,fromDate,toDate,undefined,8);
      return NextResponse.json({success:true,serviceId,fromDate,toDate,timezone:"Africa/Tunis",slots});
    }

    if(tool==="create_appointment"){
      const serviceId=text(args.serviceId,120);const startAt=localStart(args.date,args.time);
      const appointment=await createAppointment({patientId,serviceId,startAt,channel:source,explicitConfirmation:true,sourceSessionId:text(context.sessionId,120)||undefined,idempotencyKey:text(args.idempotencyKey,160)||undefined});
      return NextResponse.json({success:true,appointment});
    }

    if(tool==="reschedule_appointment"){
      const appointmentId=text(args.appointmentId,120);const existing=db.appointments.find(item=>item.id===appointmentId&&item.patientId===patientId);
      if(!existing)return NextResponse.json({success:false,error:"appointment_not_found"},{status:404});
      const appointment=await rescheduleAppointment(appointmentId,{replacementSlotStart:localStart(args.date,args.time),channel:source,explicitConfirmation:true,idempotencyKey:text(args.idempotencyKey,160)||undefined});
      return NextResponse.json({success:true,appointment});
    }

    if(tool==="cancel_appointment"){
      const appointmentId=text(args.appointmentId,120);const existing=db.appointments.find(item=>item.id===appointmentId&&item.patientId===patientId);
      if(!existing)return NextResponse.json({success:false,error:"appointment_not_found"},{status:404});
      const appointment=await cancelAppointment(appointmentId,{reason:text(args.reason,240)||undefined,channel:source,explicitConfirmation:true});
      return NextResponse.json({success:true,appointment});
    }

    if(tool==="get_appointment"){
      const appointmentId=text(args.appointmentId,120);const appointment=db.appointments.find(item=>item.id===appointmentId&&item.patientId===patientId);
      if(!appointment)return NextResponse.json({success:false,error:"appointment_not_found"},{status:404});
      const service=db.services.find(item=>item.id===appointment.serviceId);
      return NextResponse.json({success:true,appointment:{...appointment,serviceName:service?localized(service.name,locale):undefined}});
    }

    if(tool==="get_journey_status"){
      const appointmentId=text(args.appointmentId,120);const appointment=db.appointments.find(item=>item.id===appointmentId&&item.patientId===patientId);
      if(!appointment)return NextResponse.json({success:false,error:"appointment_not_found"},{status:404});
      const journey=db.journeys.find(item=>item.appointmentId===appointmentId&&item.patientId===patientId);
      if(!journey)return NextResponse.json({success:true,journey:null});
      return NextResponse.json({success:true,journey:{id:journey.id,state:journey.state,steps:journey.steps.map(step=>({id:step.id,type:step.type,sequence:step.sequence,state:step.state,title:localized(step.title,locale),body:step.body?localized(step.body,locale):undefined,dueAt:step.dueAt}))}});
    }

    if(tool==="get_navigation_context"){
      const serviceId=text(args.serviceId,120);const navigation=await routeTo(serviceId,"node-main-gate",true);
      return NextResponse.json({success:true,service:{id:navigation.service.id,name:localized(navigation.service.name,locale)},distanceM:navigation.route.distanceM,steps:navigation.route.nodes.map((node,index)=>({id:node.id,label:localized(node.label,locale),floor:node.floor,instruction:index>0&&navigation.route.edges[index-1]?localized(navigation.route.edges[index-1].instruction,locale):undefined}))});
    }

    if(tool==="get_approved_instructions"){
      const serviceId=text(args.serviceId,120);const service=db.services.find(item=>item.id===serviceId&&item.active);
      if(!service)return NextResponse.json({success:false,error:"service_not_found"},{status:404});
      const templateIds=[service.preparationTemplateId,service.followupTemplateId].filter(Boolean);
      const instructions=db.contentTemplates.filter(item=>templateIds.includes(item.id)&&item.published).map(item=>({type:item.type,title:localized(item.title,locale),body:localized(item.body,locale),version:item.version,reviewedBy:item.reviewedBy??null}));
      return NextResponse.json({success:true,serviceId,instructions});
    }

    if(tool==="request_human_help"){
      const reason=text(args.reasonCategory,80).toLowerCase();const summary=text(args.summary,240)||"Patient requested help";
      const clinical=/clinical|medical|medicine|medication|dose|symptom|doctor|urgence|emergency|دواء|جرعة|طبيب|استعجال/.test(`${reason} ${summary.toLowerCase()}`);
      const directHuman=/human|staff|person|agent|employee|موظف|إنسان|humain/.test(reason);
      const urgent=/emergency|urgence|استعجال|urgent/.test(`${reason} ${summary.toLowerCase()}`);
      const escalation=await mutateDb(current=>{const createdAt=new Date().toISOString();const row={id:id("esc"),tenantId:TENANT_ID,patientId,source:source as "app"|"voice",category:clinical?"clinical_boundary" as const:directHuman?"human_requested" as const:"other" as const,summary,priority:urgent?"high" as const:"normal" as const,state:"open" as const,createdAt};current.escalations.unshift(row);current.auditLog.unshift({id:id("audit"),tenantId:TENANT_ID,actorType:"ai",actorId:"heni-agent",action:"ai.escalation.created",resourceType:"escalation",resourceId:row.id,metadata:{category:row.category,source},createdAt});return row});
      return NextResponse.json({success:true,escalation:{id:escalation.id,state:escalation.state,category:escalation.category,priority:escalation.priority}});
    }

    return NextResponse.json({error:"unsupported_agent_tool"},{status:400});
  }catch(error){
    const message=error instanceof Error?error.message:"agent_tool_failed";
    console.error("Heni agent tool failed",message);
    const status=/not found|unknown/i.test(message)?404:/invalid|required/i.test(message)?400:/available|conflict|confirmed/i.test(message)?409:500;
    return NextResponse.json({success:false,error:message.slice(0,160)},{status});
  }
}
