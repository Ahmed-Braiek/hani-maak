import {PatientShell} from "@/components/PatientShell";
import {ARGuideClient} from "@/components/ARGuideClient";
import {RecordedARWalkthrough} from "@/components/RecordedARWalkthrough";
import {patientSnapshot} from "@/lib/operations";

export const dynamic="force-dynamic";

export default async function ARPage({searchParams}:{searchParams:Promise<{serviceId?:string;demo?:string}>}){
  const params=await searchParams;
  const recorded=params.demo==="nuclear-medicine";
  if(recorded)return <PatientShell><RecordedARWalkthrough/></PatientShell>;
  const x=await patientSnapshot();
  const serviceId=params.serviceId??x.activeAppointment?.serviceId??"svc-imaging";
  return <PatientShell>
    <div className="eyebrow">Guidage augmenté</div>
    <h1 className="mobile-title">Heni vous montre le chemin.</h1>
    <p className="muted">Activez la caméra si disponible et suivez les repères visuels et les instructions de Heni.</p>
    <ARGuideClient serviceId={serviceId}/>
  </PatientShell>;
}
