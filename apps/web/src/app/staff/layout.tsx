import {redirect} from "next/navigation";
import {getStaffIdentity} from "@/lib/staff-auth";

export const dynamic="force-dynamic";

export default async function StaffProtectedLayout({children}:{children:React.ReactNode}){
  const identity=await getStaffIdentity();
  if(!identity)redirect("/staff-login");
  return children;
}
