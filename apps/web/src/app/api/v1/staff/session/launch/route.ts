import {NextResponse} from "next/server";
import {validStaffRole} from "@/lib/staff-auth";

function safeNext(value:string|null){
  if(!value||!value.startsWith("/")||value.startsWith("//"))return "/staff";
  return value;
}

export async function GET(req:Request){
  const url=new URL(req.url);
  const role=url.searchParams.get("role");
  if(!validStaffRole(role))return NextResponse.redirect(new URL("/staff",url));
  const next=safeNext(url.searchParams.get("next"));
  const response=NextResponse.redirect(new URL(next,url));
  response.cookies.set("hani_staff_role",role,{httpOnly:true,sameSite:"lax",secure:process.env.NODE_ENV==="production",path:"/",maxAge:60*60*8});
  return response;
}
