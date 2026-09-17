import {cookies,headers} from "next/headers";
import {hasPermission,type Permission,type StaffIdentity,type StaffRole} from "./access";

const DEMO_IDENTITIES:Record<StaffRole,StaffIdentity>={
  doctor:{id:"staff-doctor-demo",name:"Dr. Leila Mansouri",role:"doctor",department:"Imagerie"},
  administration:{id:"staff-admin-demo",name:"Salma Ben Amor",role:"administration",department:"Admissions"},
  super_admin:{id:"staff-super-demo",name:"Hani Maak Platform",role:"super_admin",department:"Platform"}
};

function validRole(value:string|null|undefined):value is StaffRole{return value==="doctor"||value==="administration"||value==="super_admin"}

export async function getStaffIdentity():Promise<StaffIdentity|undefined>{
  const cookieStore=await cookies();
  const headerStore=await headers();
  const raw=headerStore.get("x-hani-role")??cookieStore.get("hani_staff_role")?.value;
  const role=validRole(raw)?raw:"administration";
  return DEMO_IDENTITIES[role];
}

export async function requirePermission(permission:Permission){
  const identity=await getStaffIdentity();
  if(!identity||!hasPermission(identity,permission)){
    const error=new Error("FORBIDDEN");
    (error as Error&{status?:number}).status=403;
    throw error;
  }
  return identity;
}

export async function requireRole(role:StaffRole){
  const identity=await getStaffIdentity();
  if(!identity||identity.role!==role){
    const error=new Error("FORBIDDEN");
    (error as Error&{status?:number}).status=403;
    throw error;
  }
  return identity;
}
