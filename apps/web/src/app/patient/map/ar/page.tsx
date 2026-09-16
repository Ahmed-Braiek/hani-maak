import {PatientShell} from "@/components/PatientShell";
import {ARGuideClient} from "@/components/ARGuideClient";
import {patientSnapshot} from "@/lib/operations";

export const dynamic="force-dynamic";

export default async function ARPage({searchParams}:{searchParams:Promise<{serviceId?:string}>}){
  const params=await searchParams;
  const x=await patientSnapshot();
  const serviceId=params.serviceId??x.activeAppointment?.serviceId??"svc-imaging";
  return <PatientShell>
    <div className="eyebrow">Guidage augmenté</div>
    <h1 className="mobile-title">Heni vous montre le chemin.</h1>
    <p className="muted">Caméra réelle si disponible, flèches AR de démonstration et instructions calculées par le route graph.</p>
    <ARGuideClient serviceId={serviceId}/>
  </PatientShell>;
}
