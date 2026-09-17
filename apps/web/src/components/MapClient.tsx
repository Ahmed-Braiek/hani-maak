"use client";

import {useMemo,useState} from "react";
import {usePersistentLocale} from "@/lib/locale-client";

const HOSPITAL={lat:36.802254,lng:10.161104};

function distanceKm(lat1:number,lng1:number,lat2:number,lng2:number){
  const r=6371;const rad=(n:number)=>n*Math.PI/180;const dLat=rad(lat2-lat1);const dLng=rad(lng2-lng1);
  const a=Math.sin(dLat/2)**2+Math.cos(rad(lat1))*Math.cos(rad(lat2))*Math.sin(dLng/2)**2;
  return 2*r*Math.asin(Math.sqrt(a));
}

export function MapClient({_serviceId="svc-imaging"}:{serviceId?:string;_serviceId?:string}){
  const {locale}=usePersistentLocale();
  const [locating,setLocating]=useState(false);
  const [locationState,setLocationState]=useState<"idle"|"found"|"denied"|"unavailable">("idle");
  const [distance,setDistance]=useState<number|null>(null);

  const copy=useMemo(()=>({
    heading:locale==="ar"?"موقع المستشفى":locale==="en"?"Hospital location":"Localisation de l’hôpital",
    site:locale==="ar"?"مستشفى شارل نيكول - تونس":locale==="en"?"Charles Nicolle Hospital · Tunis":"Hôpital Charles Nicolle · Tunis",
    locate:locale==="ar"?"حدّد موقعي":locale==="en"?"Find my location":"Me localiser",
    locating:locale==="ar"?"نحدّد موقعك…":locale==="en"?"Locating…":"Localisation…",
    idle:locale==="ar"?"اضغط على «حدّد موقعي» باش نبيّنلك موقعك بالنسبة للمستشفى.":locale==="en"?"Tap “Find my location” to see where you are relative to the hospital.":"Appuyez sur « Me localiser » pour voir où vous êtes par rapport à l’hôpital.",
    denied:locale==="ar"?"الموقع موش مفعّل. تنجم تفعّلو من إعدادات المتصفح.":locale==="en"?"Location permission is off. You can enable it in your browser settings.":"La localisation est désactivée. Vous pouvez l’autoriser dans les réglages du navigateur.",
    unavailable:locale==="ar"?"الموقع موش متوفر على الجهاز هذا.":locale==="en"?"Location is not available on this device.":"La localisation n’est pas disponible sur cet appareil.",
    here:locale==="ar"?"موقعك":locale==="en"?"Your location":"Votre position",
    near:locale==="ar"?"أنت قريب من المستشفى.":locale==="en"?"You are close to the hospital.":"Vous êtes proche de l’hôpital.",
    away:locale==="ar"?"المسافة التقريبية للمستشفى":locale==="en"?"Approximate distance to the hospital":"Distance approximative jusqu’à l’hôpital"
  }),[locale]);

  function useLocation(){
    if(typeof navigator==="undefined"||!navigator.geolocation){setLocationState("unavailable");return}
    setLocating(true);
    navigator.geolocation.getCurrentPosition(pos=>{
      const km=distanceKm(pos.coords.latitude,pos.coords.longitude,HOSPITAL.lat,HOSPITAL.lng);
      setDistance(km);setLocationState("found");setLocating(false);
    },()=>{setLocationState("denied");setLocating(false)},{enableHighAccuracy:true,timeout:6000,maximumAge:30000});
  }

  const locationText=locationState==="found"?(distance!==null&&distance<.35?copy.near:`${copy.away} : ${distance?.toFixed(distance<10?1:0)} km`):locationState==="denied"?copy.denied:locationState==="unavailable"?copy.unavailable:copy.idle;
  const src="https://www.openstreetmap.org/export/embed.html?bbox=10.1532%2C36.7970%2C10.1690%2C36.8078&layer=mapnik&marker=36.802254%2C10.161104";

  return <section className="patient-map-simple">
    <div className="patient-map-simple-head">
      <div><div className="eyebrow">{copy.heading}</div><h2>{copy.site}</h2></div>
      <button className="btn btn-primary patient-locate-btn" type="button" onClick={useLocation} disabled={locating}>◎ {locating?copy.locating:copy.locate}</button>
    </div>
    <div className="patient-map-frame-wrap">
      <iframe className="patient-map-frame" title={copy.site} src={src} loading="lazy" referrerPolicy="no-referrer-when-downgrade"/>
      <div className={`patient-location-pill ${locationState==="found"?"found":""}`}><span>◎</span><div><strong>{copy.here}</strong><small>{locationText}</small></div></div>
    </div>
  </section>;
}
