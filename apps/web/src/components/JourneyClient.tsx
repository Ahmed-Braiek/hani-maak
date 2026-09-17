"use client";

import {useState} from "react";
import {useRouter} from "next/navigation";
import type {Journey} from "@/lib/types";
import {usePersistentLocale} from "@/lib/locale-client";
import {t,statusText} from "@/lib/i18n";

export function JourneyClient({journey}:{journey:Journey}){
  const [busy,setBusy]=useState<string>();
  const router=useRouter();
  const {locale}=usePersistentLocale();
  const allDone=journey.steps.every(step=>step.state==="completed");

  const waitingStaff=locale==="ar"?"يتم تأكيد الزيارة من طرف موظف المستشفى.":locale==="en"?"Hospital staff will confirm the visit when it is finished.":"La visite sera confirmée par le personnel de l’hôpital lorsqu’elle sera terminée.";
  const afterVisitLocked=locale==="ar"?"تتفتح تعليمات ما بعد الزيارة بعد ما يؤكد الموظف نهاية الزيارة.":locale==="en"?"After-visit instructions unlock once staff confirms the visit is complete.":"Les instructions après la visite seront disponibles dès que le personnel confirme la fin de la visite.";
  const refreshLabel=locale==="ar"?"تحديث":locale==="en"?"Refresh":"Actualiser";
  const doneTitle=locale==="ar"?"تمّ إكمال مسارك":locale==="en"?"Journey completed":"Parcours terminé";
  const doneCopy=locale==="ar"?"كل الخطوات تمّت. تنجم ترجع للتعليمات في أي وقت.":locale==="en"?"All steps are complete. You can come back to these instructions at any time.":"Toutes les étapes sont terminées. Vous pouvez revenir à ces instructions à tout moment.";
  const followDone=locale==="ar"?"قريت التعليمات":locale==="en"?"I’ve read these instructions":"J’ai lu ces instructions";

  async function ack(id:string){
    setBusy(id);
    await fetch(`/api/v1/journey-steps/${id}/acknowledge`,{method:"POST"});
    setBusy(undefined);
    router.refresh();
  }

  return <div className="journey-experience">
    <div className="journey-toolbar-simple">
      <div><strong>{allDone?doneTitle:(locale==="ar"?"مسارك اليوم":locale==="en"?"Your journey":"Votre parcours")}</strong><small>{allDone?doneCopy:(locale==="ar"?"هاني معاك خطوة بخطوة":locale==="en"?"Heni stays with you step by step":"Heni vous accompagne étape par étape")}</small></div>
      <button className="btn btn-secondary compact" type="button" onClick={()=>router.refresh()}>↻ {refreshLabel}</button>
    </div>

    {allDone&&<div className="journey-complete-banner"><span>✓</span><div><strong>{doneTitle}</strong><small>{doneCopy}</small></div></div>}

    <div className="journey-list journey-list-clean">{journey.steps.map(step=>{
      const acknowledgeable=step.payload?.acknowledgeable===true||step.type==="follow_up";
      const lockedVisit=step.type==="human_action"&&step.state==="upcoming";
      const lockedFollow=step.type==="follow_up"&&step.state==="upcoming";
      return <article className={`journey-step journey-step-clean state-${step.state}`} key={step.id}>
        <div className={`step-dot ${step.state}`}>{step.state==="completed"?"✓":step.sequence}</div>
        <div className="journey-step-content">
          <div className="journey-step-head"><div><strong>{step.title[locale]??step.title.fr}</strong><span className={`badge ${step.state==="completed"?"good":step.state==="active"?"warn":""}`}>{statusText(locale,step.state)}</span></div></div>
          {step.body?.[locale]&&<p className="muted journey-step-copy">{step.body[locale]}</p>}
          {lockedVisit&&<div className="journey-lock-note"><span>◷</span><small>{waitingStaff}</small></div>}
          {lockedFollow&&<div className="journey-lock-note"><span>⌁</span><small>{afterVisitLocked}</small></div>}
          <div className="journey-step-actions">
            {step.state==="active"&&acknowledgeable&&<button className="btn btn-primary" onClick={()=>void ack(step.id)} disabled={busy===step.id}>{busy===step.id?t(locale,"journey.updating"):(step.type==="follow_up"?followDone:t(locale,"journey.understood"))}</button>}
            {step.type==="navigation"&&step.state!=="completed"&&<a className="btn btn-primary" href="/patient/map">⌖ {t(locale,"journey.open_guidance")}</a>}
          </div>
        </div>
      </article>})}</div>
  </div>;
}
