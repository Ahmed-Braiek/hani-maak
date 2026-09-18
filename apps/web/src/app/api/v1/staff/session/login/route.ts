import {NextResponse} from "next/server";
import {authenticateDemoStaff,staffSessionSecret,staffSessionCookie,staffSessionCookieOptions} from "@/lib/staff-auth";
import {roleMeta} from "@/lib/access";

export async function POST(req:Request){
  const body=await req.json().catch(()=>null);
  const role=body?.role;
  const username=String(body?.username??"").trim();
  const password=String(body?.password??"");
  if(!role||!username||!password)return NextResponse.json({error:"credentials_required"},{status:400});

  const result=authenticateDemoStaff(role,username,password);
  if(!result)return NextResponse.json({error:"invalid_credentials"},{status:401});
  if(!staffSessionSecret())return NextResponse.json({error:"staff_session_not_configured"},{status:503});

  const response=NextResponse.json({ok:true,role:result.identity.role,name:result.identity.name,home:roleMeta[result.identity.role].home});
  response.cookies.set(staffSessionCookie(),result.token,staffSessionCookieOptions());
  response.cookies.set("hani_staff_role","",{httpOnly:true,sameSite:"lax",secure:process.env.NODE_ENV==="production",path:"/",maxAge:0});
  return response;
}
