import {cookies} from "next/headers";
import {hasPermission,type Permission,type StaffIdentity,type StaffRole} from "./access";

const DEMO_IDENTITIES:Record<StaffRole,StaffIdentity>={
  doctor:{id:"staff-doctor-demo",name:"Dr. Leila Mansouri",role:"doctor",department:"Imagerie"},
  administration:{id:"staff-admin-demo",name:"Salma Ben Amor",role:"administration",department:"Admissions"},
  super_admin:{id:"staff-super-demo",name:"Hani Maak Platform",role:"super_admin",department:"Platform"}
};

export function validStaffRole(value:string|null|undefined):value is StaffRole{return value==="doctor"||value==="administration"||value==="super_admin"}

export async function getStaffIdentity():Promise<StaffIdentity|undefined>{
  const store=await cookies();
  const raw=store.get("hani_staff_role")?.value;
  return validStaffRole(raw)?DEMO_IDENTITIES[raw]:undefined;
}

export async function requireStaff(){
  const identity=await getStaffIdentity();
  if(!identity)throw Object.assign(new Error("FORBIDDEN"),{status:403});
  return identity;
}

export async function requirePermission(permission:Permission){
  const identity=await requireStaff();
  if(!hasPermission(identity,permission))throw Object.assign(new Error("FORBIDDEN"),{status:403});
  return identity;
}

export async function requireRole(role:StaffRole){
  const identity=await requireStaff();
  if(identity.role!==role)throw Object.assign(new Error("FORBIDDEN"),{status:403});
  return identity;
}
