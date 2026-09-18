import {NextResponse} from "next/server";
import {getStaffIdentity,signStaffRole,staffSessionCookie,staffSessionCookieOptions,validStaffRole} from "@/lib/staff-auth";

export async function GET(){
  const identity=await getStaffIdentity();
  return NextResponse.json({role:identity?.role??null,name:identity?.name??null});
}

export async function POST(req:Request){
  const identity=await getStaffIdentity();
  if(!identity)return NextResponse.json({error:"unauthorized"},{status:401});
  if(process.env.DEMO_MODE!=="true"&&process.env.NODE_ENV==="production"){
    return NextResponse.json({error:"role_switch_disabled"},{status:403});
  }
  const body=await req.json().catch(()=>null);
  const role=body?.role;
  if(!validStaffRole(role))return NextResponse.json({error:"invalid_role"},{status:400});
  const response=NextResponse.json({ok:true,role});
  response.cookies.set(staffSessionCookie(),signStaffRole(role),staffSessionCookieOptions());
  return response;
}

export async function DELETE(){
  const response=NextResponse.json({ok:true});
  response.cookies.set(staffSessionCookie(),"",{...staffSessionCookieOptions(),maxAge:0});
  response.cookies.set("hani_staff_role","",{httpOnly:true,sameSite:"lax",secure:process.env.NODE_ENV==="production",path:"/",maxAge:0});
  return response;
}
