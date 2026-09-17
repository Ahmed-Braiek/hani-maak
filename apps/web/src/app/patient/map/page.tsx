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
  const lead=locale==="ar"?"خريطة المستشفى، موقعك، وإرشاد هاني.":locale==="en"?"Hospital map, your location and Heni guidance.":"Carte de l’hôpital, votre localisation et le guidage Heni.";
  const arKicker=locale==="ar"?"إرشاد AR":locale==="en"?"AR guidance":"Guidage AR";
  const arTitle=locale==="ar"?"امشِ مع هاني إلى بلوك الطب النووي":locale==="en"?"Walk with Heni to Nuclear Medicine":"Marchez avec Heni jusqu’à la Médecine nucléaire";
  const arCopy=locale==="ar"?"شوف مسار المستشفى، وهاني يوجّهك بالصوت مع هدف AR يتحرّك خطوة بخطوة.":locale==="en"?"Follow the hospital walkthrough while Heni guides you by voice with a moving AR target, step by step.":"Suivez le parcours dans l’hôpital pendant que Heni vous guide à la voix avec une cible AR mobile, étape par étape.";
  const arButton=locale==="ar"?"ابدأ إرشاد AR":locale==="en"?"Start AR guidance":"Démarrer le guidage AR";
  const videoChip=locale==="ar"?"مسار المستشفى":locale==="en"?"Hospital walkthrough":"Parcours hôpital";
  const voiceChip=locale==="ar"?"صوت هاني":locale==="en"?"Heni voice":"Voix de Heni";
  const targetChip=locale==="ar"?"هدف متحرك":locale==="en"?"Moving target":"Cible mobile";
  const note=locale==="ar"?"إرشاد خطوة بخطوة":locale==="en"?"Step-by-step guidance":"Guidage étape par étape";

  return <PatientShell locale={locale}>
    <div className="eyebrow">{t(locale,"map.eyebrow")}</div>
    <h1 className="mobile-title">{t(locale,"map.title")}</h1>
    <p className="muted">{lead}</p>

    <MapClient serviceId={serviceId}/>

    <section className="map-ar-spotlight" aria-label={arTitle}>
      <div className="map-ar-copy">
        <span className="map-ar-kicker"><i/>{arKicker}</span>
        <h2>{arTitle}</h2>
        <p>{arCopy}</p>
        <div className="map-ar-proof" aria-label="AR guidance features">
          <span>◉ {videoChip}</span>
          <span>◌ {voiceChip}</span>
          <span>◎ {targetChip}</span>
        </div>
      </div>
      <div className="map-ar-actions">
        <div className="map-ar-target-visual" aria-hidden="true"><span>AR</span></div>
        <Link className="map-ar-cta-button" href="/patient/map/ar?demo=nuclear-medicine"><span>▶</span><span>{arButton}</span><b>→</b></Link>
        <small className="map-ar-note">{note}</small>
      </div>
    </section>
  </PatientShell>;
}
