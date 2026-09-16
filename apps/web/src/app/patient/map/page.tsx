import {PatientShell} from "@/components/PatientShell";
import {MapClient} from "@/components/MapClient";
import {patientSnapshot} from "@/lib/operations";

export const dynamic="force-dynamic";

export default async function MapPage(){
  const x=await patientSnapshot();
  const serviceId=x.activeAppointment?.serviceId??"svc-imaging";
  return <PatientShell>
    <div className="eyebrow">Guidage · Charles Nicolle</div>
    <h1 className="mobile-title">Je vous guide jusqu'au service.</h1>
    <p className="muted">Le trajet est calculé par un route graph déterministe. La démo combine le contexte réel du site avec une couche intérieure explicitement prototype.</p>
    <MapClient serviceId={serviceId}/>
  </PatientShell>;
}
