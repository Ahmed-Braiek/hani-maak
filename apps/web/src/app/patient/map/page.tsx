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
  const lead=locale==="ar"?"خريطة المستشفى، موقعك وديمو AR بالفيديو.":locale==="en"?"Hospital map, your location and the recorded AR demo.":"Carte de l’hôpital, votre localisation et la démo AR vidéo.";
  const arKicker=locale==="ar"?"ديمو AR":locale==="en"?"AR demo":"Démo AR";
  const arTitle=locale==="ar"?"امشِ مع هاني إلى بلوك الطب النووي":locale==="en"?"Walk with Heni to Nuclear Medicine":"Marchez avec Heni jusqu’à la Médecine nucléaire";
  const arCopy=locale==="ar"?"شوف الفيديو الحقيقي من المستشفى، وهاني يوجّهك بالصوت مع هدف AR يتحرّك خطوة بخطوة.":locale==="en"?"Follow real hospital footage while Heni guides you by voice with a moving AR target, step by step.":"Suivez la vidéo réelle de l’hôpital pendant que Heni vous guide à la voix avec une cible AR mobile, étape par étape.";
  const arButton=locale==="ar"?"ابدأ الجولة AR":locale==="en"?"Start AR walk":"Démarrer le guidage AR";
  const videoChip=locale==="ar"?"فيديو حقيقي":locale==="en"?"Real hospital video":"Vidéo réelle";
  const voiceChip=locale==="ar"?"صوت هاني":locale==="en"?"Heni voice":"Voix de Heni";
  const targetChip=locale==="ar"?"هدف متحرك":locale==="en"?"Moving target":"Cible mobile";
  const note=locale==="ar"?"فيديو المسار داخل المستشفى":locale==="en"?"Recorded hospital walkthrough":"Parcours vidéo dans l’hôpital";

  return <PatientShell locale={locale}>
    <div className="eyebrow">{t(locale,"map.eyebrow")}</div>
    <h1 className="mobile-title">{t(locale,"map.title")}</h1>
    <p className="muted">{lead}</p>

    <section className="map-ar-spotlight" aria-label={arTitle}>
      <div className="map-ar-copy">
        <span className="map-ar-kicker"><i/>{arKicker}</span>
        <h2>{arTitle}</h2>
        <p>{arCopy}</p>
        <div className="map-ar-proof" aria-label="AR demo features">
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

    <MapClient serviceId={serviceId}/>
  </PatientShell>;
}
