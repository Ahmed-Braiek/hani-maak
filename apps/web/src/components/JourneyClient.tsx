"use client";
import {useState} from "react";
import {useRouter} from "next/navigation";
import type {Journey} from "@/lib/types";

export function JourneyClient({journey}:{journey:Journey}){
  const [busy,setBusy]=useState<string>();
  const router=useRouter();

  async function ack(id:string){
    setBusy(id);
    await fetch(`/api/v1/journey-steps/${id}/acknowledge`,{method:"POST"});
    setBusy(undefined);
    router.refresh();
  }

  return <div className="journey-list">
    {journey.steps.map(step=>{
      const acknowledgeable=step.payload?.acknowledgeable===true;
      return <div className="journey-step" key={step.id}>
        <div className={`step-dot ${step.state}`}>{step.state==="completed"?"✓":step.sequence}</div>
        <div>
          <div className="row">
            <strong>{step.title.fr}</strong>
            <span className={`badge ${step.state==="completed"?"good":step.state==="active"?"warn":""}`}>{step.state}</span>
          </div>
          {step.body?.fr&&<p className="muted" style={{lineHeight:1.55,margin:"6px 0 10px"}}>{step.body.fr}</p>}
          {step.state==="active"&&acknowledgeable&&<button className="btn btn-secondary" onClick={()=>ack(step.id)} disabled={busy===step.id}>{busy===step.id?"Mise à jour…":"J'ai compris"}</button>}
          {step.type==="navigation"&&step.state!=="completed"&&<a className="btn btn-secondary" href="/patient/map">Ouvrir le guidage</a>}
        </div>
      </div>;
    })}
  </div>;
}
