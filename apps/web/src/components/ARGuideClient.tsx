"use client";

import Link from "next/link";
import { useEffect, useMemo, useRef, useState } from "react";
import { HeniAvatar } from "./HeniAvatar";

type RouteNode={id:string;label:{fr:string;ar?:string};type:string};
type RouteEdge={instruction:{fr:string;ar?:string};distanceM:number};
type RouteData={service:{name:{fr:string;ar?:string}};route:{nodes:RouteNode[];edges:RouteEdge[];distanceM:number}};

export function ARGuideClient({serviceId="svc-imaging"}:{serviceId?:string}){
  const videoRef=useRef<HTMLVideoElement>(null);
  const streamRef=useRef<MediaStream|null>(null);
  const [data,setData]=useState<RouteData|null>(null);
  const [idx,setIdx]=useState(0);
  const [cameraState,setCameraState]=useState<"loading"|"live"|"fallback">("loading");
  const [note,setNote]=useState("Initialisation du guidage…");
  const [voice,setVoice]=useState(true);

  useEffect(()=>{
    let cancelled=false;
    async function boot(){
      try{
        const response=await fetch(`/api/v1/navigation/route?serviceId=${encodeURIComponent(serviceId)}&from=node-main-gate&accessible=true`,{cache:"no-store"});
        const payload=await response.json();
        if(!response.ok)throw new Error(payload.error??"Route unavailable");
        if(!cancelled)setData(payload);
      }catch(e){if(!cancelled)setNote(e instanceof Error?e.message:"Route unavailable")}

      if(typeof navigator==="undefined"||!navigator.mediaDevices?.getUserMedia){
        if(!cancelled){setCameraState("fallback");setNote("Caméra non disponible: mode AR simulé actif.")}
        return;
      }
      try{
        const stream=await navigator.mediaDevices.getUserMedia({video:{facingMode:{ideal:"environment"}},audio:false});
        if(cancelled){stream.getTracks().forEach(t=>t.stop());return}
        streamRef.current=stream;
        if(videoRef.current){videoRef.current.srcObject=stream;await videoRef.current.play().catch(()=>undefined)}
        setCameraState("live");setNote("Caméra active. Les flèches sont une couche AR de démonstration.");
      }catch{
        if(!cancelled){setCameraState("fallback");setNote("Permission caméra non accordée: mode AR simulé actif.")}
      }
    }
    void boot();
    return()=>{cancelled=true;streamRef.current?.getTracks().forEach(t=>t.stop())};
  },[serviceId]);

  const instruction=useMemo(()=>{
    if(!data)return "Chargement du parcours…";
    if(idx===0)return "Entrez par l'entrée principale et avancez vers l'accueil.";
    return data.route.edges[Math.min(idx-1,data.route.edges.length-1)]?.instruction?.fr??"Continuez tout droit.";
  },[data,idx]);

  const current=data?.route.nodes[idx];
  const remaining=data?Math.max(0,data.route.distanceM-Math.round((data.route.distanceM*idx)/Math.max(1,data.route.nodes.length-1))):0;
  const arrived=Boolean(data&&idx>=data.route.nodes.length-1);

  function speakText(text:string){
    if(!voice||typeof window==="undefined"||!("speechSynthesis" in window))return;
    window.speechSynthesis.cancel();
    const u=new SpeechSynthesisUtterance(text);
    u.lang="fr-FR";u.rate=.92;
    window.speechSynthesis.speak(u);
  }

  function next(){
    if(!data)return;
    const nextIdx=Math.min(idx+1,data.route.nodes.length-1);
    setIdx(nextIdx);
    const nextInstruction=nextIdx===0?"Entrez par l'entrée principale et avancez vers l'accueil.":data.route.edges[Math.min(nextIdx-1,data.route.edges.length-1)]?.instruction?.fr??"Continuez tout droit.";
    setTimeout(()=>speakText(nextInstruction),80);
  }

  return <div className="ar-experience">
    <div className={`ar-camera ${cameraState}`}>
      <video ref={videoRef} className="ar-video" muted playsInline/>
      <div className="ar-fallback-scene" aria-hidden="true"><div className="ar-wall left"/><div className="ar-wall right"/><div className="ar-floor"/></div>
      <div className="ar-vignette"/>
      <div className="ar-topbar">
        <Link href="/patient/map" className="ar-round-btn" aria-label="Retour">←</Link>
        <div className="ar-location-pill"><span className="map-live-dot"/> Charles Nicolle · prototype indoor</div>
        <button className={`ar-round-btn ${voice?"on":""}`} onClick={()=>setVoice(v=>!v)} aria-label="Activer ou désactiver la voix">♫</button>
      </div>

      <div className="ar-heni-corner"><HeniAvatar size={72}/><div><strong>Heni</strong><span>{arrived?"On y est!":"Je vous guide"}</span></div></div>

      {!arrived?<div className="ar-direction-layer">
        <div className="ar-arrow-wrap"><div className="ar-arrow">↑</div><div className="ar-distance">{remaining} m</div></div>
        <div className="ar-target-tag">{current?.label?.fr??"Prochaine étape"}</div>
      </div>:<div className="ar-arrival-burst"><div className="ar-check">✓</div><strong>Destination atteinte</strong><span>{data?.service.name.fr}</span></div>}

      <div className="ar-bottom-sheet">
        <div className="ar-sheet-handle"/>
        <div className="row">
          <div><div className="eyebrow">Guidage AR · étape {data?idx+1:0}/{data?.route.nodes.length??0}</div><h2>{arrived?"Vous êtes arrivé.":current?.label?.fr??"Chargement…"}</h2></div>
          <span className={`badge ${cameraState==="live"?"good":"warn"}`}>{cameraState==="live"?"caméra live":"simulation"}</span>
        </div>
        <p>{arrived?"Le parcours patient peut maintenant continuer vers l'accueil du service.":instruction}</p>
        <div className="ar-proof-row"><span>♿ Accessible</span><span>⌁ Route locale</span><span>◉ Sans LLM géographique</span></div>
        {!arrived?<button className="btn btn-primary btn-wide" onClick={next}>J'ai atteint ce repère →</button>:<Link className="btn btn-primary btn-wide" href="/patient/journey">Continuer mon parcours →</Link>}
        <small>{note}</small>
      </div>
    </div>
    <div className="notice info"><strong>Ce mode AR est une démo fonctionnelle.</strong> Il utilise réellement la caméra du téléphone quand le navigateur l'autorise, puis superpose les instructions issues du route graph Hani Maak. Il ne prétend pas localiser le patient automatiquement à l'intérieur de l'hôpital.</div>
  </div>;
}
