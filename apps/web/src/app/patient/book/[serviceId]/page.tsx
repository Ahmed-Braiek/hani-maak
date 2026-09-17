import {notFound} from "next/navigation";import {PatientShell} from "@/components/PatientShell";import {BookingClient} from "@/components/BookingClient";import {readDb} from "@/lib/db";
export const dynamic="force-dynamic";
export default async function Book({params}:{params:Promise<{serviceId:string}>}){const {serviceId}=await params;const db=await readDb();const s=db.services.find(x=>x.id===serviceId);if(!s)notFound();return <PatientShell><BookingClient service={s}/></PatientShell>}
