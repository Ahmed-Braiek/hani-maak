import Fastify from "fastify";
import formbody from "@fastify/formbody";
import websocket from "@fastify/websocket";
import WebSocket from "ws";
import "dotenv/config";

const PORT = Number(process.env.VOICE_BRIDGE_PORT || 8787);
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const MODEL = process.env.OPENAI_LIVE_MODEL || "gpt-live-1";
const DELEGATED_MODEL = process.env.OPENAI_DELEGATED_MODEL || "gpt-5.6-terra";
const VOICE = process.env.OPENAI_VOICE || "marin";
const WEB = process.env.HANI_WEB_BASE_URL || "http://localhost:3000";
const USER_AGENT = "hani-maak/Node 2.0.0";

const app = Fastify({ logger: true });
await app.register(formbody);
await app.register(websocket);

const VOICE_PROMPT = `You are Hani Maak, an automated administrative assistant for a healthcare provider in Tunisia.
Speak in short, warm Tunisian Arabic by default; French code-switching is acceptable.
You may help with service discovery, appointment availability, booking, cancellation, rescheduling, provider-approved preparation, directions, and human escalation.
Never diagnose, prescribe, change a dose, determine clinical urgency, or claim a medicine is safe. For any clinical-boundary request, say you cannot make that decision and offer human escalation.
Never invent availability, appointment identifiers, routes, or provider instructions. Use tools.
Before any state-changing action, restate service/date/time/action and ask the caller for explicit confirmation. Only call the write tool after an affirmative confirmation.
If a tool fails, never claim success. Keep turns brief and repeat dates and times clearly.`;
const BACKEND_PROMPT = `Use only the provided Hani Maak administrative tools. Appointment truth comes from tool results, not memory. Do not make clinical decisions.`;
const OPENING = "عسلامة، أنا هاني معاك، مساعد آلي للإدارة. شنوة نجم نعاونك؟";

const TOOLS = [
  {type:"function",name:"search_services",description:"Find a provider service from a patient's words.",parameters:{type:"object",properties:{query:{type:"string"},locale:{type:"string",enum:["ar","fr","en"]}},required:["query"],additionalProperties:false}},
  {type:"function",name:"get_available_slots",description:"Return real valid slots from the Hani Maak scheduling engine.",parameters:{type:"object",properties:{serviceId:{type:"string"},fromDate:{type:"string"},toDate:{type:"string"},preferredPeriod:{type:"string",enum:["morning","afternoon"]}},required:["serviceId","fromDate","toDate"],additionalProperties:false}},
  {type:"function",name:"create_appointment",description:"Create an appointment ONLY after the caller explicitly confirms the exact service/date/time.",parameters:{type:"object",properties:{patientId:{type:"string"},serviceId:{type:"string"},startAt:{type:"string"},explicitConfirmation:{type:"boolean"}},required:["patientId","serviceId","startAt","explicitConfirmation"],additionalProperties:false}},
  {type:"function",name:"cancel_appointment",description:"Cancel a confirmed appointment ONLY after explicit caller confirmation.",parameters:{type:"object",properties:{appointmentId:{type:"string"},explicitConfirmation:{type:"boolean"},reason:{type:"string"}},required:["appointmentId","explicitConfirmation"],additionalProperties:false}},
  {type:"function",name:"reschedule_appointment",description:"Move a confirmed appointment ONLY after explicit caller confirmation.",parameters:{type:"object",properties:{appointmentId:{type:"string"},replacementSlotStart:{type:"string"},explicitConfirmation:{type:"boolean"}},required:["appointmentId","replacementSlotStart","explicitConfirmation"],additionalProperties:false}},
  {type:"function",name:"get_service_instructions",description:"Get only provider-published preparation/instruction content for a service.",parameters:{type:"object",properties:{serviceId:{type:"string"}},required:["serviceId"],additionalProperties:false}},
  {type:"function",name:"get_navigation_route",description:"Get a deterministic facility route; never invent directions.",parameters:{type:"object",properties:{serviceId:{type:"string"},from:{type:"string"},accessible:{type:"boolean"}},required:["serviceId"],additionalProperties:false}},
  {type:"function",name:"create_staff_escalation",description:"Create a human help request, especially for clinical-boundary or explicit human requests.",parameters:{type:"object",properties:{patientId:{type:"string"},summary:{type:"string"},category:{type:"string"}},required:["summary"],additionalProperties:false}}
];

async function jsonFetch(path:string, init?:RequestInit){
  const r=await fetch(`${WEB}${path}`,init); const body=await r.json().catch(()=>({error:`HTTP ${r.status}`})); if(!r.ok) throw new Error(body.error||`HTTP ${r.status}`); return body;
}
function ymd(days:number){const d=new Date();d.setUTCDate(d.getUTCDate()+days);return d.toISOString().slice(0,10)}
async function executeTool(name:string,args:any){
  switch(name){
    case "search_services": return jsonFetch(`/api/v1/services?q=${encodeURIComponent(args.query)}&locale=${encodeURIComponent(args.locale||"ar")}`);
    case "get_available_slots": return jsonFetch("/api/v1/availability/query",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({serviceId:args.serviceId,fromDate:args.fromDate||ymd(1),toDate:args.toDate||ymd(14),preferredPeriod:args.preferredPeriod})});
    case "create_appointment": return jsonFetch("/api/v1/appointments",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({...args,channel:"voice",idempotencyKey:`live-${args.serviceId}-${args.startAt}`})});
    case "cancel_appointment": return jsonFetch(`/api/v1/appointments/${encodeURIComponent(args.appointmentId)}/cancel`,{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({reason:args.reason,channel:"voice",explicitConfirmation:args.explicitConfirmation})});
    case "reschedule_appointment": return jsonFetch(`/api/v1/appointments/${encodeURIComponent(args.appointmentId)}/reschedule`,{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({replacementSlotStart:args.replacementSlotStart,channel:"voice",explicitConfirmation:args.explicitConfirmation,idempotencyKey:`live-reschedule-${args.appointmentId}-${args.replacementSlotStart}`})});
    case "get_service_instructions": return jsonFetch(`/api/v1/services/${encodeURIComponent(args.serviceId)}`);
    case "get_navigation_route": return jsonFetch(`/api/v1/navigation/route?serviceId=${encodeURIComponent(args.serviceId)}&from=${encodeURIComponent(args.from||"node-main-gate")}&accessible=${args.accessible!==false}`);
    case "create_staff_escalation": return jsonFetch("/api/v1/escalations",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({patientId:args.patientId||"patient-hedi",summary:args.summary,category:args.category})});
    default: throw new Error(`Unknown tool: ${name}`);
  }
}

app.get("/",async()=>({ok:true,service:"Hani Maak GPT-Live/Twilio bridge",webBase:WEB,model:MODEL}));
app.all("/incoming-call",async(req,reply)=>{const host=(req.headers["x-forwarded-host"] as string)||req.headers.host;reply.type("text/xml").send(`<?xml version="1.0" encoding="UTF-8"?><Response><Connect><Stream url="wss://${host}/media-stream" /></Connect></Response>`)});

app.register(async fastify=>{
  fastify.get("/media-stream",{websocket:true},connection=>{
    if(!OPENAI_API_KEY){connection.send(JSON.stringify({event:"error",message:"OPENAI_API_KEY missing"}));connection.close();return;}
    let streamSid:string|null=null, sessionRequested=false, sessionReady=false;
    const openai=new WebSocket("wss://api.openai.com/v1/live/sessions",{headers:{Authorization:`Bearer ${OPENAI_API_KEY}`,"User-Agent":USER_AGENT}});
    const send=(event:any)=>{if(openai.readyState===WebSocket.OPEN)openai.send(JSON.stringify(event));};
    const close=()=>{sessionReady=false;if(connection.readyState===WebSocket.OPEN)connection.close();if(openai.readyState===WebSocket.OPEN)openai.close();};
    const startSession=()=>{if(sessionRequested||!streamSid||openai.readyState!==WebSocket.OPEN)return;sessionRequested=true;send({type:"session.start",session:{model:MODEL,instructions:VOICE_PROMPT,audio:{format:{type:"audio/pcmu",rate:8000},output:{voice:VOICE}},delegation:{type:"responses",responses:{model:DELEGATED_MODEL,instructions:BACKEND_PROMPT,tools:TOOLS}}}})};
    openai.on("open",startSession);
    openai.on("message",async raw=>{try{const ev=JSON.parse(raw.toString());if(ev.type==="session.started"){sessionReady=true;app.log.info({sessionId:ev.session?.id},"GPT-Live session started");send({type:"session.instructions.append",delegation_id:null,content:`Your first spoken line is exactly: ${OPENING}`});send({type:"session.commentary.append",delegation_id:null,content:OPENING});}
      else if(ev.type==="session.output_audio.delta"&&streamSid&&connection.readyState===WebSocket.OPEN){connection.send(JSON.stringify({event:"media",streamSid,media:{payload:ev.delta}}));}
      else if(ev.type==="response.event"&&ev.event?.type==="response.output_item.done"&&ev.event.item?.type==="function_call"&&ev.event.item.status==="completed"){const {call_id,name,arguments:argText}=ev.event.item;let output:any;try{output=await executeTool(name,JSON.parse(argText||"{}"));}catch(e:any){output={error:e.message};}send({type:"response.item.create",item:{type:"function_call_output",call_id,output:JSON.stringify(output)}});send({type:"response.create"});}
      else if(ev.type==="error")app.log.error(ev.error,"GPT-Live error");}catch(e){app.log.error(e,"OpenAI message parse error")}});
    connection.on("message",raw=>{try{const data=JSON.parse(raw.toString());if(data.event==="start"){streamSid=data.start.streamSid;startSession();}else if(data.event==="media"&&sessionReady)send({type:"session.input_audio.append",audio:data.media.payload});else if(data.event==="stop")close();}catch(e){app.log.error(e,"Twilio message parse error")}});
    connection.on("close",close);connection.on("error",close);openai.on("close",close);openai.on("error",e=>{app.log.error(e,"OpenAI socket error");close()});
  });
});

await app.listen({port:PORT,host:"0.0.0.0"});
