import {redirect} from "next/navigation";
export const dynamic="force-dynamic";
export default async function ServiceDetail({params}:{params:Promise<{id:string}>}){const {id}=await params;redirect(`/patient/book/${encodeURIComponent(id)}`)}
