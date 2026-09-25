import {NextResponse} from "next/server";
import {chatWithHeni} from "@/lib/heni/service";
import {getStaffIdentity} from "@/lib/staff-auth";
import type {HeniRole} from "@/lib/heni/types";

export const dynamic="force-dynamic";

async function resolveRole(requested:unknown):Promise<HeniRole>{
  if(requested!=="doctor"&&requested!=="administration"&&requested!=="super_admin")return "patient";
  const identity=await getStaffIdentity();
  if(!identity)return "patient";
  return identity.role;
}

async function externalPatientTurn(body:any){
  const base=process.env.HENI_AGENT_BASE_URL?.trim().replace(/\/$/,"");
  const secret=process.env.HENI_AGENT_SHARED_SECRET;
  if(!base||!secret)return null;
  const controller=new AbortController();
  const timeout=setTimeout(()=>controller.abort(),15_000);
  try{
    const response=await fetch(`${base}/v1/chat`,{
      method:"POST",
      headers:{"content-type":"application/json","x-heni-agent-key":secret},
      body:JSON.stringify({
        message:String(body.message??"").trim(),
        locale:body.locale==="fr"||body.locale==="en"||body.locale==="ar"?body.locale:"ar",
        patientId:String(body.patientId||"30000000-0000-0000-0000-000000000001"),
        caregiverId:String(body.caregiverId||"10000000-0000-0000-0000-000000000001"),
        source:String(body.source||"website"),
        sessionId:body.sessionId||undefined,
        confirmationToken:typeof body.confirmationToken==="string"?body.confirmationToken:undefined,
        history:Array.isArray(body.history)?body.history.slice(-16):[]
      }),
      cache:"no-store",
      signal:controller.signal
    });
    const text=await response.text();
    let payload:any={};
    try{payload=text?JSON.parse(text):{}}catch{payload={error:"invalid_agent_response"}}
    if(!response.ok)throw new Error(String(payload?.detail||payload?.error||`agent_${response.status}`));
    return payload;
  }finally{clearTimeout(timeout)}
}

export async function OPTIONS(){return new Response(null,{status:204});}\n\nexport async function POST(req:Request){
  try{
    const body=await req.json().catch(()=>({}));
    const message=String(body?.message??"").trim();
    if(!message)return NextResponse.json({error:"message_required"},{status:400});
    if(message.length>2000)return NextResponse.json({error:"message_too_long"},{status:413});
    const role=await resolveRole(body?.role);
    if(role==="patient"&&process.env.HENI_AGENT_BASE_URL&&process.env.HENI_AGENT_SHARED_SECRET){
      try{
        const result=await externalPatientTurn({...body,message});
        if(result)return NextResponse.json(result);
      }catch(error){
        console.error("External Heni agent unavailable; using deterministic fallback",error instanceof Error?error.message:"unknown");
      }
    }
    const result=await chatWithHeni({
      message,
      locale:body?.locale,
      patientId:body?.patientId||"30000000-0000-0000-0000-000000000001",
      role,
      source:body?.source,
      sessionId:body?.sessionId,
      history:Array.isArray(body?.history)?body.history:[]
    });
    return NextResponse.json(result);
  }catch(error){
    console.error("Heni chat failed",error instanceof Error?error.message:"unknown");
    return NextResponse.json({error:"heni_chat_unavailable"},{status:503});
  }
}
