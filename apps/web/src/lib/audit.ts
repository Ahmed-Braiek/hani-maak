import {mutateDb} from "./db";
import type {StaffIdentity} from "./access";

export async function recordStaffAudit(identity:StaffIdentity,action:string,resourceType:string,resourceId?:string,metadata:Record<string,unknown>={}){
  return mutateDb(db=>{
    const event={id:`audit-${Date.now()}-${Math.random().toString(36).slice(2,8)}`,tenantId:db.tenant.id,actorType:"staff" as const,actorId:identity.id,action,resourceType,resourceId,metadata:{role:identity.role,...metadata},createdAt:new Date().toISOString()};
    db.auditLog.unshift(event);
    if(db.auditLog.length>500)db.auditLog.length=500;
    return event;
  });
}
