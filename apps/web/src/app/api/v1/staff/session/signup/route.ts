import {NextResponse} from "next/server";
import {mutateDb} from "@/lib/db";
import {TENANT_ID} from "@/lib/seed";
import {validStaffRole} from "@/lib/staff-auth";

export async function POST(req:Request){
  const body=await req.json().catch(()=>null);
  const displayName=String(body?.displayName??"").trim();
  const username=String(body?.username??"").trim();
  const password=String(body?.password??"");
  const role=body?.role;

  if(!displayName||displayName.length<2)return NextResponse.json({error:"display_name_required"},{status:400});
  if(!validStaffRole(role))return NextResponse.json({error:"invalid_role"},{status:400});
  if(!/^[a-zA-Z0-9._-]{4,40}$/.test(username))return NextResponse.json({error:"invalid_username"},{status:400});
  if(password.length<8)return NextResponse.json({error:"weak_password"},{status:400});

  // Security rule: self-signup never grants a privileged role automatically.
  // The password is deliberately NOT persisted in this competition workflow.
  await mutateDb(db=>{
    db.auditLog.unshift({
      id:`audit-access-${Date.now().toString(36)}`,
      tenantId:TENANT_ID,
      actorType:"system",
      action:"staff.access_requested",
      resourceType:"staff_access_request",
      resourceId:username,
      metadata:{displayName,username,requestedRole:role,status:"pending_approval"},
      createdAt:new Date().toISOString()
    });
  });

  return NextResponse.json({ok:true,status:"pending_approval"},{status:202});
}
