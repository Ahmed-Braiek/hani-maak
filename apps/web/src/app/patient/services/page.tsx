import {PatientShell} from "@/components/PatientShell";import {PatientServicesClient} from "@/components/PatientServicesClient";import {readDb} from "@/lib/db";
export const dynamic="force-dynamic";
export default async function Services(){const db=await readDb();return <PatientShell><PatientServicesClient services={db.services}/></PatientShell>}
