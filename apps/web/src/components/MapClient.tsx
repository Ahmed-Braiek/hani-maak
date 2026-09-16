"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";

type RouteNode={id:string;code?:string;label:{fr:string;ar?:string;en?:string};x:number;y:number;type:string;floor:number};
type RouteEdge={from:string;to:string;distanceM:number;instruction:{fr:string;ar?:string;en?:string}};
type RoutePayload={
  service:{id:string;name:{fr:string;ar?:string};department:string};
  route:{nodes:RouteNode[];edges:RouteEdge[];distanceM:number};
  provenance:string;
};

export function MapClient({serviceId="svc-imaging"}:{serviceId?:string}){
  const [data,setData]=useState<RoutePayload|null>(null);
  const [idx,setIdx]=useState(0);
  const [error,setError]=useState("");
  const [locating,setLocating]=useState(false);
  const [geoNote,setGeoNote]=useState("Point de départ: entrée principale du scénario");

  useEffect(()=>{
    let cancelled=false;
    async function loadRoute(){
      try{
        setError("");
        const response=await fetch(`/api/v1/navigation/route?serviceId=${encodeURIComponent(serviceId)}&from=node-main-gate&accessible=true`,{cache:"no-store"});
        const payload=await response.json();
        if(!response.ok)throw new Error(payload.error??"Impossible de calculer l'itinéraire");
        if(!cancelled){setData(payload);setIdx(0)}
      }catch(e){if(!cancelled)setError(e instanceof Error?e.message:"Erreur de guidage")}
    }
    void loadRoute();
    return()=>{cancelled=true};
  },[serviceId]);

  const current=useMemo(()=>data?.route?.nodes?.[idx],[data,idx]);
  const edge=useMemo(()=>data?.route?.edges?.[Math.min(Math.max(0,idx-1),Math.max(0,(data?.route?.edges?.length??1)-1))],[data,idx]);

  function useLocation(){
    if(typeof navigator==="undefined"||!navigator.geolocation){setGeoNote("La géolocalisation n'est pas disponible. Le mode démo utilise l'entrée principale.");return}
    setLocating(true);
    navigator.geolocation.getCurrentPosition(
      pos=>{
        const dLat=Math.abs(pos.coords.latitude-36.802254);
        const dLon=Math.abs(pos.coords.longitude-10.161104);
        if(dLat<0.01&&dLon<0.01)setGeoNote("Position détectée près du site. L'étape intérieure démarre à l'entrée principale validée du scénario.");
        else setGeoNote("Vous n'êtes pas sur le site de démonstration. Pour la compétition, le parcours démarre à l'entrée principale de Charles Nicolle.");
        setLocating(false);
      },
      ()=>{setGeoNote("Position non autorisée. Aucun problème: le scénario démarre à l'entrée principale.");setLocating(false)},
      {enableHighAccuracy:true,timeout:5000,maximumAge:30000}
    );
  }

  if(error)return <div className="notice"><strong>Guidage indisponible.</strong><br/>{error}</div>;
  if(!data)return <div className="card map-loading"><div className="skeleton wide"/><div className="skeleton"/><div className="skeleton short"/></div>;

  const pts=data.route.nodes.map(n=>`${n.x},${n.y}`).join(" ");
  const completedPts=data.route.nodes.slice(0,idx+1).map(n=>`${n.x},${n.y}`).join(" ");
  const progress=Math.round(((idx+1)/data.route.nodes.length)*100);

  return <div className="stack">
    <div className="map-proof-bar">
      <div><span className="map-live-dot"/> <strong>Contexte réel:</strong> Hôpital Charles Nicolle · Tunis</div>
      <span>36.802254, 10.161104</span>
    </div>

    <div className="notice info"><strong>Route prototype — campus intérieur non validé par l'hôpital.</strong><br/>L'adresse et le contexte géographique sont réels. Les couloirs et waypoints ci-dessous sont une couche de démonstration remplaçable par des données hospitalières validées.</div>

    <div className="hospital-map-shell">
      <div className="hospital-map-toolbar">
        <div>
          <div className="eyebrow">Hôpital Charles Nicolle · site de démonstration</div>
          <strong>{data.service.name.fr}</strong>
        </div>
        <div className="map-actions">
          <button className="btn btn-secondary compact" onClick={useLocation} disabled={locating}>{locating?"Localisation…":"◎ Ma position"}</button>
          <Link className="btn btn-primary compact" href={`/patient/map/ar?serviceId=${encodeURIComponent(serviceId)}`}>◈ Mode AR</Link>
        </div>
      </div>

      <div className="hospital-campus-map" role="img" aria-label="Prototype map of the hospital journey">
        <svg className="campus-base" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true">
          <defs>
            <linearGradient id="campusGreen" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stopColor="#edf8f4"/><stop offset="1" stopColor="#dcece7"/></linearGradient>
            <filter id="buildingShadow" x="-30%" y="-30%" width="160%" height="160%"><feDropShadow dx="0" dy="2" stdDeviation="2" floodColor="#17312d" floodOpacity=".09"/></filter>
          </defs>
          <rect x="0" y="0" width="100" height="100" fill="url(#campusGreen)"/>
          <path d="M0 86 C24 80 45 91 100 80" stroke="#c7d8d3" strokeWidth="8" fill="none"/>
          <path d="M0 86 C24 80 45 91 100 80" stroke="#fff" strokeWidth="4" fill="none"/>
          <path d="M18 77 L35 64 L48 58 L62 43 L86 26" stroke="#c7d8d3" strokeWidth="7" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          <path d="M18 77 L35 64 L48 58 L62 43 L86 26" stroke="#f8fbfa" strokeWidth="4" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          <g filter="url(#buildingShadow)" fill="#fff" stroke="#c7dcd6" strokeWidth=".7">
            <rect x="18" y="48" width="18" height="14" rx="2"/>
            <rect x="37" y="34" width="22" height="14" rx="2"/>
            <rect x="61" y="18" width="26" height="16" rx="2"/>
            <rect x="64" y="53" width="24" height="16" rx="2"/>
            <rect x="28" y="17" width="19" height="11" rx="2"/>
          </g>
          <g fill="#59716c" fontSize="3" fontFamily="system-ui,sans-serif" fontWeight="700">
            <text x="20" y="56">Accueil</text>
            <text x="39" y="42">Bloc central</text>
            <text x="66" y="27">Imagerie</text>
            <text x="68" y="62">Rhumatologie</text>
            <text x="30" y="24">Consultations</text>
            <text x="3" y="94">Boulevard 9 Avril 1938</text>
          </g>
          <polyline points={pts} fill="none" stroke="#94c6bd" strokeWidth="2.7" strokeLinecap="round" strokeLinejoin="round" strokeDasharray="2 2"/>
          <polyline points={completedPts} fill="none" stroke="#0f766e" strokeWidth="3.4" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
        {data.route.nodes.map((n,i)=><div title={n.label.fr} key={n.id} className={`route-node ${i===data.route.nodes.length-1?"dest":""} ${i===idx?"current":""} ${i<idx?"done":""}`} style={{left:`${n.x}%`,top:`${n.y}%`}}><span>{i+1}</span></div>)}
        <div className="map-compass">N<br/><span>↑</span></div>
        <div className="map-floor-chip">Niveau {current?.floor??0}</div>
      </div>

      <div className="map-progress-strip"><span style={{width:`${progress}%`}}/></div>

      <div className="map-bottom enhanced">
        <div className="row">
          <div>
            <div className="eyebrow">Étape {idx+1} / {data.route.nodes.length}</div>
            <h3>{current?.label?.fr}</h3>
          </div>
          <span className="badge info">≈ {idx===0?data.route.distanceM:Math.max(0,data.route.distanceM-Math.round((data.route.distanceM*idx)/(data.route.nodes.length-1)))} m restants</span>
        </div>
        <p className="map-instruction">{idx===0?"Commencez à l'entrée principale puis suivez la ligne Hani Maak.":edge?.instruction?.fr??"Continuez vers la destination."}</p>
        <div className="map-waypoint-meta"><span>♿ Parcours accessible</span><span>◷ ~{Math.max(1,Math.ceil(data.route.distanceM/70))} min</span><span>✓ Guidage déterministe</span></div>
        {idx<data.route.nodes.length-1?<button className="btn btn-primary btn-wide map-next" onClick={()=>setIdx(x=>Math.min(x+1,data.route.nodes.length-1))}>Je suis arrivé à ce point <span>→</span></button>:<div className="notice safe arrival"><strong>✓ Destination atteinte.</strong><br/>Vous êtes arrivé au service dans le parcours prototype. Vous pouvez maintenant montrer l'étape suivante du patient journey.</div>}
      </div>
    </div>

    <div className="card card-flat location-card">
      <div className="row-start"><div className="location-icon">◎</div><div><strong>Point de départ intelligent</strong><p className="muted tiny">{geoNote}</p></div></div>
    </div>

    <div className="card card-flat external-map-card">
      <div className="row">
        <div><div className="eyebrow">Contexte extérieur réel</div><strong>Hôpital Charles Nicolle · Boulevard 9 Avril 1938, Tunis</strong></div>
        <span className="badge">optionnel</span>
      </div>
      <p className="muted tiny">Le cœur de la démo ne dépend d'aucun fournisseur de carte. Si Internet est disponible, vous pouvez ouvrir le contexte OpenStreetMap dans un nouvel onglet.</p>
      <a className="btn btn-secondary btn-wide" target="_blank" rel="noreferrer" href="https://www.openstreetmap.org/?mlat=36.802254&mlon=10.161104#map=17/36.802254/10.161104">Voir le contexte extérieur ↗</a>
    </div>
  </div>;
}
