import Link from "next/link";
import {PatientShell} from "@/components/PatientShell";
import {MapClient} from "@/components/MapClient";
import {patientSnapshot} from "@/lib/operations";
import {getServerLocale} from "@/lib/i18n-server";
import {t} from "@/lib/i18n";

export const dynamic="force-dynamic";

export default async function MapPage(){
  const [x,locale]=await Promise.all([patientSnapshot(),getServerLocale()]);
  const serviceId=x.activeAppointment?.serviceId??"svc-imaging";
  const arTitle=locale==="ar"?"جرّب التوجيه بالفيديو إلى الطب النووي":locale==="en"?"Try the recorded AR walk to Nuclear Medicine":"Tester le guidage AR vidéo vers la Médecine nucléaire";
  const arCopy=locale==="ar"?"فيديو حقيقي من المستشفى مع هاني، صوت، هدف متحرك وتعليمات خطوة بخطوة.":locale==="en"?"Real hospital footage with Heni voice, a moving target and step-by-step guidance.":"Vidéo réelle de l’hôpital avec la voix de Heni, une cible mobile et des instructions étape par étape.";
  const arButton=locale==="ar"?"افتح ديمو AR":locale==="en"?"Open AR demo":"Ouvrir la démo AR";
  return <PatientShell locale={locale}>
    <div className="map-page-head">
      <div><div className="eyebrow">{t(locale,"map.eyebrow")}</div><h1 className="mobile-title">{t(locale,"map.title")}</h1><p className="muted">{t(locale,"map.lead")}</p></div>
      <Link className="map-ar-hero-button" href="/patient/map/ar?demo=nuclear-medicine"><span className="map-ar-hero-icon">◎</span><span><strong>{arTitle}</strong><small>{arCopy}</small></span><b>{arButton} →</b></Link>
    </div>
    <MapClient serviceId={serviceId}/>
  </PatientShell>;
}
