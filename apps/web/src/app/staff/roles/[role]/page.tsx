import {notFound} from "next/navigation";
import {RoleDetails} from "@/components/RoleDetails";
import type {StaffRole} from "@/lib/access";

export default async function RolePage({params}:{params:Promise<{role:string}>}){const {role}=await params;if(!["doctor","administration","super_admin"].includes(role))notFound();return <RoleDetails role={role as StaffRole}/>}
