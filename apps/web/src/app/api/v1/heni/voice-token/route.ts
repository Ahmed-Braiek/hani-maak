import {createHmac,randomUUID} from "node:crypto";
import {NextResponse} from "next/server";

export const dynamic="force-dynamic";

function b64url(value:Buffer|string){return Buffer.from(value).toString("base64url")}
function websocketBase(){
  const explicit=process.env.HENI_AGENT_WSS_URL?.trim().replace(/\/$/,"");if(explicit)return explicit;
  const base=process.env.HENI_AGENT_BASE_URL?.trim().replace(/\/$/,"");if(!base)return "";
  if(base.startsWith("https://"))return `wss://${base.slice(8)}`;
  if(base.startsWith("http://"))return `ws://${base.slice(7)}`;
  return base;
}

export async function OPTIONS(){return new Response(null,{status:204});}\n\nexport async function POST(req:Request){
  const secret=process.env.HENI_AGENT_SHARED_SECRET;
  const wsBase=websocketBase();
  if(!secret||!wsBase)return NextResponse.json({error:"live_voice_not_configured"},{status:503});
  const body=await req.json().catch(()=>({}));
  const locale=body?.locale==="fr"||body?.locale==="en"||body?.locale==="ar"?body.locale:"ar";
  const now=Math.floor(Date.now()/1000);const exp=now+120;
  const caregiverId=String(body?.caregiverId||"10000000-0000-0000-0000-000000000001");
  const patientId=String(body?.patientId||"30000000-0000-0000-0000-000000000001");
  const payload={sid:randomUUID(),patientId,caregiverId,locale,iat:now,exp};
  const encoded=b64url(JSON.stringify(payload));
  const signature=createHmac("sha256",secret).update(encoded).digest("base64url");
  const token=`${encoded}.${signature}`;
  return NextResponse.json({token,wsUrl:`${wsBase}/ws/voice`,sessionId:payload.sid,expiresAt:new Date(exp*1000).toISOString()});
}
