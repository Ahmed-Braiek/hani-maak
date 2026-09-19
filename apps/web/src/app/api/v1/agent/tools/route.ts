import {timingSafeEqual} from "node:crypto";
import {NextResponse} from "next/server";
import {mutateDb,readDb} from "@/lib/db";
import {cancelAppointment,createAppointment,patientSnapshot,rescheduleAppointment,routeTo} from "@/lib/operations";
import {getAvailableSlots,tunisDateString} from "@/lib/scheduling";
import {TENANT_ID} from "@/lib/seed";
import {hospitalAccess,patientAppHelp,publicHospitalKnowledge,searchPublicHospitalDirectory} from "@/lib/public-knowledge";
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

    const serviceContext=(serviceId:string)=>{
      const service=db.services.find(item=>item.id===serviceId);
      if(!service)return null;
      const prep=service.preparationTemplateId?db.contentTemplates.find(item=>item.id===service.preparationTemplateId&&item.published):undefined;
      const follow=service.followupTemplateId?db.contentTemplates.find(item=>item.id===service.followupTemplateId&&item.published):undefined;
      return {
        id:service.id,
        name:localized(service.name,locale),
        description:localized(service.description,locale),
        department:service.department,
        bookingMode:service.bookingMode,
        slotDurationMin:service.slotDurationMin,
        documents:service.documents,
        preparation:prep?{title:localized(prep.title,locale),body:localized(prep.body,locale)}:null,
        followUp:follow?{title:localized(follow.title,locale),body:localized(follow.body,locale)}:null
      };
    };

    if(tool==="get_patient_context"){
      const snapshot=await patientSnapshot(patientId);
      const ownAppointments=snapshot.appointments.map(appointment=>({
        id:appointment.id,
        state:appointment.state,
        startAt:appointment.startAt,
        endAt:appointment.endAt,
        serviceId:appointment.serviceId,
        service:serviceContext(appointment.serviceId),
        channel:appointment.channel,
        cancellationReason:appointment.cancellationReason??null
      }));
      const ownJourneys=db.journeys
        .filter(item=>item.patientId===patientId)
        .map(journey=>({
          id:journey.id,
          appointmentId:journey.appointmentId,
          serviceId:journey.serviceId,
          state:journey.state,
          steps:journey.steps.map(step=>({
            id:step.id,
            type:step.type,
            sequence:step.sequence,
            state:step.state,
            title:localized(step.title,locale),
            body:step.body?localized(step.body,locale):undefined,
            dueAt:step.dueAt??null,
            completedAt:step.completedAt??null
          }))
        }));
      const now=Date.now();
      const upcomingAppointments=ownAppointments
        .filter(item=>item.state==="confirmed"&&new Date(item.startAt).getTime()>=now)
        .sort((a,b)=>a.startAt.localeCompare(b.startAt));
      const recentAppointments=[...ownAppointments].sort((a,b)=>b.startAt.localeCompare(a.startAt)).slice(0,8);
      const active=snapshot.activeAppointment;
      const activeJourney=active?ownJourneys.find(item=>item.appointmentId===active.id)??null:null;
      const nextStep=activeJourney?.steps.find(step=>step.state==="active")??activeJourney?.steps.find(step=>step.state==="upcoming")??null;
      const notifications=snapshot.notifications
        .slice()
        .sort((a,b)=>a.scheduledAt.localeCompare(b.scheduledAt))
        .slice(0,10)
        .map(item=>({id:item.id,channel:item.channel,message:item.message,state:item.state,scheduledAt:item.scheduledAt}));

      return NextResponse.json({
        success:true,
        timezone:"Africa/Tunis",
        currentTime:new Date().toISOString(),
        patient:{
          id:snapshot.patient.id,
          firstName:snapshot.patient.firstName,
          lastName:snapshot.patient.lastName,
          displayName:`${snapshot.patient.firstName} ${snapshot.patient.lastName}`,
          age:snapshot.patient.age??null,
          preferredLocale:snapshot.patient.preferredLocale,
          preferredChannel:snapshot.patient.preferredChannel,
          consentStatus:snapshot.patient.consentStatus
        },
        appointmentSummary:{
          total:ownAppointments.length,
          confirmed:ownAppointments.filter(item=>item.state==="confirmed").length,
          completed:ownAppointments.filter(item=>item.state==="completed").length,
          cancelled:ownAppointments.filter(item=>item.state==="cancelled").length,
          next:upcomingAppointments[0]??null
        },
        appointments:ownAppointments,
        upcomingAppointments,
        recentAppointments,
        activeAppointment:active?{
          id:active.id,
          state:active.state,
          startAt:active.startAt,
          endAt:active.endAt,
          serviceId:active.serviceId,
          service:serviceContext(active.serviceId),
          channel:active.channel
        }:null,
        nextStep,
        activeJourney,
        journeys:ownJourneys,
        notifications,
        caregiverDelegations:snapshot.caregiverDelegations.map(item=>({
          id:item.id,caregiverName:item.caregiverName,scopes:item.scopes,expiresAt:item.expiresAt??null,revokedAt:item.revokedAt??null
        })),
        waitlistEntries:snapshot.waitlistEntries.map(item=>({
          id:item.id,serviceId:item.serviceId,service:serviceContext(item.serviceId),preferredPeriod:item.preferredPeriod??null,
          fromDate:item.fromDate,toDate:item.toDate,state:item.state,currentAppointmentId:item.currentAppointmentId??null
        }))
      });
    }

    if(tool==="get_public_hospital_info"){
      return NextResponse.json({success:true,...publicHospitalKnowledge(locale)});
    }

    if(tool==="get_hospital_access"){
      return NextResponse.json({success:true,...hospitalAccess(locale)});
    }

    if(tool==="search_hospital_directory"){
      const query=text(args.query,160);
      const departments=searchPublicHospitalDirectory(query,locale,query?12:30);
      return NextResponse.json({
        success:true,
        query,
        departments,
        note:locale==="ar"
          ?"الدليل يساعدك تلقى الاختصاص. الحجز متوفر كان للخدمات اللي مبيّنة Bookable في هاني معاك."
          :locale==="en"
            ?"The directory helps identify the department. Booking is available only for services explicitly configured in Hani Maak."
            :"L’annuaire aide à identifier le service. La réservation n’est disponible que pour les services configurés dans Hani Maak."
      });
    }

    if(tool==="get_app_help"){
      return NextResponse.json({success:true,...patientAppHelp(text(args.topic,120),locale)});
    }

    if(tool==="list_my_appointments"){
      const includePast=args.includePast===true;
      const appointments=db.appointments
        .filter(item=>item.patientId===patientId)
        .filter(item=>includePast||!["cancelled","completed"].includes(item.state))
        .sort((a,b)=>a.startAt.localeCompare(b.startAt))
        .map(appointment=>({
          id:appointment.id,state:appointment.state,startAt:appointment.startAt,endAt:appointment.endAt,
          serviceId:appointment.serviceId,service:serviceContext(appointment.serviceId),channel:appointment.channel
        }));
      return NextResponse.json({success:true,appointments,timezone:"Africa/Tunis"});
    }

    if(tool==="find_services"){
      const query=text(args.query,120).toLocaleLowerCase();
      const services=db.services.filter(service=>service.active).filter(service=>{
        if(!query)return true;
        const values=[...Object.values(service.name),...Object.values(service.description),...service.aliases.fr,...service.aliases.ar,...service.aliases.en];
        return values.some(value=>value.toLocaleLowerCase().includes(query)||query.includes(value.toLocaleLowerCase()));
      }).slice(0,8).map(service=>({
        id:service.id,
        name:localized(service.name,locale),
        description:localized(service.description,locale),
        department:service.department,
        bookingMode:service.bookingMode,
        documents:service.documents,
        bookableInHaniMaak:true
      }));
      const directoryMatches=searchPublicHospitalDirectory(query,locale,8).filter(item=>!item.platformServiceId);
      return NextResponse.json({success:true,services,directoryMatches});
    }

    if(tool==="get_service_details"){
      const serviceId=text(args.serviceId,120);
      const service=db.services.find(item=>item.id===serviceId&&item.active);
      if(!service)return NextResponse.json({success:false,error:"service_not_found"},{status:404});
      return NextResponse.json({success:true,service:serviceContext(serviceId)});
    }

    if(tool==="check_appointment_availability"){
      const serviceId=text(args.serviceId,120);
      if(!db.services.some(item=>item.id===serviceId&&item.active))return NextResponse.json({success:false,error:"service_not_found"},{status:404});
      const requested=text(args.date,10);
      const fromDate=requested||tunisDateString(new Date());
      if(!/^\d{4}-\d{2}-\d{2}$/.test(fromDate))return NextResponse.json({success:false,error:"invalid_date"},{status:400});
      const toDate=requested?requested:plusDays(fromDate,14);
      const slots=getAvailableSlots(db,serviceId,fromDate,toDate,undefined,8);
      return NextResponse.json({success:true,serviceId,fromDate,toDate,timezone:"Africa/Tunis",slots});
    }

    if(tool==="create_appointment"){
      const serviceId=text(args.serviceId,120);
      const startAt=localStart(args.date,args.time);
      const appointment=await createAppointment({
        patientId,serviceId,startAt,channel:source,explicitConfirmation:true,
        sourceSessionId:text(context.sessionId,120)||undefined,
        idempotencyKey:text(args.idempotencyKey,160)||undefined
      });
      return NextResponse.json({success:true,appointment,journeyCreated:true});
    }

    if(tool==="reschedule_appointment"){
      const appointmentId=text(args.appointmentId,120);
      const existing=db.appointments.find(item=>item.id===appointmentId&&item.patientId===patientId);
      if(!existing)return NextResponse.json({success:false,error:"appointment_not_found"},{status:404});
      const appointment=await rescheduleAppointment(appointmentId,{
        replacementSlotStart:localStart(args.date,args.time),channel:source,explicitConfirmation:true,
        idempotencyKey:text(args.idempotencyKey,160)||undefined
      });
      return NextResponse.json({success:true,appointment});
    }

    if(tool==="cancel_appointment"){
      const appointmentId=text(args.appointmentId,120);
      const existing=db.appointments.find(item=>item.id===appointmentId&&item.patientId===patientId);
      if(!existing)return NextResponse.json({success:false,error:"appointment_not_found"},{status:404});
      const appointment=await cancelAppointment(appointmentId,{reason:text(args.reason,240)||undefined,channel:source,explicitConfirmation:true});
      return NextResponse.json({success:true,appointment});
    }

    if(tool==="get_appointment"){
      const appointmentId=text(args.appointmentId,120);
      const appointment=db.appointments.find(item=>item.id===appointmentId&&item.patientId===patientId);
      if(!appointment)return NextResponse.json({success:false,error:"appointment_not_found"},{status:404});
      return NextResponse.json({success:true,appointment:{...appointment,service:serviceContext(appointment.serviceId)}});
    }

    if(tool==="get_journey_status"){
      const appointmentId=text(args.appointmentId,120);
      const appointment=db.appointments.find(item=>item.id===appointmentId&&item.patientId===patientId);
      if(!appointment)return NextResponse.json({success:false,error:"appointment_not_found"},{status:404});
      const journey=db.journeys.find(item=>item.appointmentId===appointmentId&&item.patientId===patientId);
      if(!journey)return NextResponse.json({success:true,journey:null});
      const nextStep=journey.steps.find(step=>step.state==="active")??journey.steps.find(step=>step.state==="upcoming")??null;
      return NextResponse.json({
        success:true,
        service:serviceContext(appointment.serviceId),
        journey:{
          id:journey.id,state:journey.state,
          nextStep:nextStep?{id:nextStep.id,type:nextStep.type,state:nextStep.state,title:localized(nextStep.title,locale),body:nextStep.body?localized(nextStep.body,locale):undefined,dueAt:nextStep.dueAt??null}:null,
          steps:journey.steps.map(step=>({
            id:step.id,type:step.type,sequence:step.sequence,state:step.state,title:localized(step.title,locale),
            body:step.body?localized(step.body,locale):undefined,dueAt:step.dueAt??null,completedAt:step.completedAt??null
          }))
        }
      });
    }

    if(tool==="get_navigation_context"){
      const serviceId=text(args.serviceId,120);
      const navigation=await routeTo(serviceId,"node-main-gate",true);
      return NextResponse.json({
        success:true,
        service:{id:navigation.service.id,name:localized(navigation.service.name,locale)},
        distanceM:navigation.route.distanceM,
        appPath:`/patient/map?serviceId=${encodeURIComponent(serviceId)}`,
        steps:navigation.route.nodes.map((node,index)=>({
          id:node.id,label:localized(node.label,locale),floor:node.floor,
          instruction:index>0&&navigation.route.edges[index-1]?localized(navigation.route.edges[index-1].instruction,locale):undefined
        }))
      });
    }

    if(tool==="get_approved_instructions"){
      const serviceId=text(args.serviceId,120);
      const service=db.services.find(item=>item.id===serviceId&&item.active);
      if(!service)return NextResponse.json({success:false,error:"service_not_found"},{status:404});
      const templateIds=[service.preparationTemplateId,service.followupTemplateId].filter(Boolean);
      const instructions=db.contentTemplates
        .filter(item=>templateIds.includes(item.id)&&item.published)
        .map(item=>({type:item.type,title:localized(item.title,locale),body:localized(item.body,locale),version:item.version,reviewedBy:item.reviewedBy??null}));
      return NextResponse.json({success:true,service:serviceContext(serviceId),instructions});
    }

    if(tool==="request_human_help"){
      const reason=text(args.reasonCategory,80).toLowerCase();
      const summary=text(args.summary,240)||"Patient requested help";
      const clinical=/clinical|medical|medicine|medication|dose|symptom|doctor|urgence|emergency|دواء|جرعة|طبيب|استعجال/.test(`${reason} ${summary.toLowerCase()}`);
      const directHuman=/human|staff|person|agent|employee|موظف|إنسان|humain/.test(reason);
      const urgent=/emergency|urgence|استعجال|urgent/.test(`${reason} ${summary.toLowerCase()}`);
      const escalation=await mutateDb(current=>{
        const createdAt=new Date().toISOString();
        const row={
          id:id("esc"),tenantId:TENANT_ID,patientId,source:source as "app"|"voice",
          category:clinical?"clinical_boundary" as const:directHuman?"human_requested" as const:"other" as const,
          summary,priority:urgent?"high" as const:"normal" as const,state:"open" as const,createdAt
        };
        current.escalations.unshift(row);
        current.auditLog.unshift({
          id:id("audit"),tenantId:TENANT_ID,actorType:"ai",actorId:"heni-agent",
          action:"ai.escalation.created",resourceType:"escalation",resourceId:row.id,
          metadata:{category:row.category,source},createdAt
        });
        return row;
      });
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
