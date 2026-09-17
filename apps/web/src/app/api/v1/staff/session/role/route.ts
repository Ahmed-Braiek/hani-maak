import {NextResponse} from "next/server";
import type {StaffRole} from "@/lib/access";
const roles:StaffRole[]=["doctor","administration","super_admin"];
export async function POST(req:Request){const body=await req.json().catch(()=>null);const role=body?.role as StaffRole;if(!roles.includes(role))return NextResponse.json({error:"invalid_role"},{status:400});const response=NextResponse.json({ok:true,role});response.cookies.set("hani_staff_role",role,{httpOnly:true,sameSite:"lax",secure:process.env.NODE_ENV==="production",path:"/",maxAge:60*60*8});return response}
