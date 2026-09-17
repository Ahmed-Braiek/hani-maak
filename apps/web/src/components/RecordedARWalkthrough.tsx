"use client";

import Link from "next/link";
import {useEffect,useMemo,useRef,useState} from "react";
import {HeniAvatar} from "./HeniAvatar";
import {usePersistentLocale} from "@/lib/locale-client";

type Localized={fr:string;ar:string;en:string};
type Cue={start:number;x:number;y:number;angle:number;label:Localized;instruction:Localized};

const cues:Cue[]=[
  {start:0,x:51,y:69,angle:0,label:{fr:"Entrée principale",ar:"المدخل الرئيسي",en:"Main entrance"},instruction:{fr:"On entre par l'entrée principale. Continuez tout droit vers le hall.",ar:"ندخلو من المدخل الرئيسي. كمّل على طول للقاعة.",en:"Enter through the main entrance and continue straight toward the hall."}},
  {start:6,x:52,y:57,angle:0,label:{fr:"Hall d'accueil",ar:"قاعة الاستقبال",en:"Reception hall"},instruction:{fr:"Continuez tout droit dans le hall. Heni garde le prochain repère devant vous.",ar:"كمّل على طول في القاعة. هاني يوريك العلامة الجاية قدّامك.",en:"Continue straight through the hall. Heni keeps the next marker ahead of you."}},
  {start:17,x:58,y:55,angle:0,label:{fr:"Couloir vers le passage",ar:"الممرّ",en:"Connector corridor"},instruction:{fr:"Suivez ce couloir vers la sortie lumineuse.",ar:"اتبع الممرّ هذا للخرجة المضيئة.",en:"Follow this corridor toward the bright exit."}},
  {start:28,x:55,y:60,angle:-5,label:{fr:"Passage extérieur",ar:"الممر الخارجي",en:"Outdoor connector"},instruction:{fr:"Traversez le passage extérieur puis entrez dans le bloc en face.",ar:"عدّي الممر الخارجي وادخل للبلوك اللي قدّامك.",en:"Cross the outdoor connector and enter the block in front of you."}},
  {start:38,x:56,y:52,angle:0,label:{fr:"Hall secondaire",ar:"القاعة الثانية",en:"Second hall"},instruction:{fr:"Continuez tout droit. Cherchez l'enseigne rouge Médecine nucléaire.",ar:"كمّل على طول ودوّر على لافتة الطب النووي الحمراء.",en:"Continue straight and look for the red Nuclear Medicine sign."}},
  {start:45,x:50,y:43,angle:0,label:{fr:"Entrée Médecine nucléaire",ar:"مدخل الطب النووي",en:"Nuclear Medicine entrance"},instruction:{fr:"Voilà l'entrée Médecine nucléaire. Entrez dans ce couloir.",ar:"هاذي مدخل الطب النووي. ادخل للممر هذا.",en:"This is the Nuclear Medicine entrance. Enter this corridor."}},
  {start:51,x:52,y:54,angle:0,label:{fr:"Couloir Médecine nucléaire",ar:"ممر الطب النووي",en:"Nuclear Medicine corridor"},instruction:{fr:"Continuez tout droit dans le couloir bleu.",ar:"كمّل على طول في الممر الأزرق.",en:"Continue straight through the blue corridor."}},
  {start:62,x:54,y:55,angle:0,label:{fr:"Dernier couloir",ar:"آخر ممر",en:"Final corridor"},instruction:{fr:"Gardez le cap. Le bloc est au bout de ce couloir.",ar:"كمّل في نفس الاتجاه. البلوك في آخر الممر.",en:"Stay on course. The block is at the end of this corridor."}},
  {start:71,x:53,y:57,angle:0,label:{fr:"Bloc Médecine nucléaire",ar:"بلوك الطب النووي",en:"Nuclear Medicine block"},instruction:{fr:"Vous arrivez au bloc de Médecine nucléaire. Suivez maintenant l'accueil du service.",ar:"وصلت لبلوك الطب النووي. توّا اتبع استقبال المصلحة.",en:"You have reached the Nuclear Medicine block. Follow the service reception from here."}}
];

const PROJECT_URL="https://lhrngmuxmjpigycgonnh.supabase.co";
const PUBLIC_VIDEO_URL=`${PROJECT_URL}/storage/v1/object/public/demo-assets/hani-nuclear-walk.mp4`;
const LEGACY_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxocm5nbXV4bWpwaWd5Y2dvbm5oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk2Mzg5MDYsImV4cCI6MjEwNTIxNDkwNn0.sQW4iZ4F1O_Rq0L3RODNQQHnIFf0j5yoZOD7bsxFhEI";
const VIDEO_DURATION=77.05;

function cueIndexFor(time:number){let index=0;for(let i=0;i<cues.length;i++)if(time>=cues[i].start)index=i;return index}

export function RecordedARWalkthrough(){
  const {locale,rtl}=usePersistentLocale();
  const videoRef=useRef<HTMLVideoElement>(null);
  const lastTime=useRef(0);
  const lastSpoken=useRef(-1);
  const fileRef=useRef<HTMLInputElement>(null);
  const [time,setTime]=useState(0);
  const [cueIndex,setCueIndex]=useState(0);
  const [voiceEnabled,setVoiceEnabled]=useState(true);
  const [voiceStarted,setVoiceStarted]=useState(false);
  const [speaking,setSpeaking]=useState(false);
  const [playing,setPlaying]=useState(false);
  const [videoReady,setVideoReady]=useState(false);
  const [videoMissing,setVideoMissing]=useState(false);
  const [uploading,setUploading]=useState(false);
  const [uploadError,setUploadError]=useState("");

  useEffect(()=>()=>{if(typeof window!=="undefined"&&"speechSynthesis" in window)window.speechSynthesis.cancel()},[]);

  const cue=cues[cueIndex];
  const nextCue=cues[Math.min(cueIndex+1,cues.length-1)];
  const target=useMemo(()=>{if(cueIndex===cues.length-1)return{x:cue.x,y:cue.y};const span=Math.max(1,nextCue.start-cue.start);const p=Math.max(0,Math.min(1,(time-cue.start)/span));return{x:cue.x+(nextCue.x-cue.x)*p,y:cue.y+(nextCue.y-cue.y)*p}},[cue,nextCue,time,cueIndex]);
  const progress=Math.min(100,Math.max(0,time/VIDEO_DURATION*100));
  const phrase=(item:Cue)=>item.instruction[locale];
  const label=(item:Cue)=>item.label[locale];

  function speak(index:number,force=false){
    if((!voiceEnabled&&!force)||typeof window==="undefined"||!("speechSynthesis" in window))return;
    const item=cues[index];window.speechSynthesis.cancel();const utterance=new SpeechSynthesisUtterance(phrase(item));
    utterance.lang=locale==="ar"?"ar-TN":locale==="en"?"en-GB":"fr-FR";utterance.rate=.92;
    const voices=window.speechSynthesis.getVoices();const preferred=voices.find(v=>v.lang.toLowerCase().startsWith(utterance.lang.slice(0,2).toLowerCase()));if(preferred)utterance.voice=preferred;
    utterance.onstart=()=>setSpeaking(true);utterance.onend=()=>setSpeaking(false);utterance.onerror=()=>setSpeaking(false);lastSpoken.current=index;window.speechSynthesis.speak(utterance);
  }

  function onTimeUpdate(){
    const video=videoRef.current;if(!video)return;const current=video.currentTime;if(current+2<lastTime.current)lastSpoken.current=-1;lastTime.current=current;setTime(current);const index=cueIndexFor(current);if(index!==cueIndex)setCueIndex(index);if(voiceStarted&&voiceEnabled&&lastSpoken.current!==index)speak(index);
  }

  async function startVoiceWalk(){
    const video=videoRef.current;if(!video||!videoReady)return;setVoiceEnabled(true);setVoiceStarted(true);lastSpoken.current=-1;video.currentTime=0;setTime(0);setCueIndex(0);await video.play().catch(()=>undefined);speak(0,true);
  }
  async function togglePlay(){const video=videoRef.current;if(!video)return;if(video.paused)await video.play().catch(()=>undefined);else video.pause()}
  function restart(){const video=videoRef.current;if(!video)return;lastSpoken.current=-1;video.currentTime=0;setTime(0);setCueIndex(0);void video.play();if(voiceStarted&&voiceEnabled)speak(0)}

  async function uploadVideo(file:File){
    if(file.type!=="video/mp4"){setUploadError(locale==="ar"?"اختار فيديو MP4.":locale==="en"?"Choose an MP4 video.":"Choisissez une vidéo MP4.");return}
    setUploading(true);setUploadError("");
    try{
      const response=await fetch(`${PROJECT_URL}/storage/v1/object/demo-assets/hani-nuclear-walk.mp4`,{method:"POST",headers:{apikey:LEGACY_ANON_KEY,Authorization:`Bearer ${LEGACY_ANON_KEY}`,"Content-Type":"video/mp4","x-upsert":"false"},body:file});
      if(!response.ok){const body=await response.text();if(response.status!==409)throw new Error(body||"upload_failed")}
      setVideoMissing(false);setVideoReady(false);
      const video=videoRef.current;if(video){video.src=`${PUBLIC_VIDEO_URL}?v=${Date.now()}`;video.load();await video.play().catch(()=>undefined)}
    }catch{setUploadError(locale==="ar"?"ما نجّمش نرفع الفيديو. عاود حاول.":locale==="en"?"Video upload failed. Please try again.":"Échec du chargement de la vidéo. Réessayez.")}
    finally{setUploading(false)}
  }

  return <div className={`ar-recorded-shell ${rtl?"rtl":""}`} dir={rtl?"rtl":"ltr"}>
    <div className="ar-recorded-phone">
      <video ref={videoRef} src={PUBLIC_VIDEO_URL} className="ar-recorded-video" autoPlay muted loop playsInline preload="auto" onLoadedData={()=>{setVideoReady(true);setVideoMissing(false)}} onError={()=>{setVideoReady(false);setVideoMissing(true)}} onTimeUpdate={onTimeUpdate} onPlay={()=>setPlaying(true)} onPause={()=>setPlaying(false)}/>
      {(!videoReady||videoMissing)&&<div className="ar-recorded-loading"><HeniAvatar size={92}/>{videoMissing?<><strong>{locale==="ar"?"حمّل فيديو المستشفى باش نبدأو الجولة":locale==="en"?"Load the hospital video to start the AR walk":"Chargez la vidéo de l'hôpital pour démarrer la visite AR"}</strong><p>{locale==="ar"?"بعد الرفع، الفيديو يبقى جاهز للجولة ويعاود تلقائيًا.":locale==="en"?"Once uploaded, the walkthrough stays ready and loops automatically.":"Après l’envoi, le parcours reste prêt et se relance automatiquement."}</p><input ref={fileRef} type="file" accept="video/mp4" hidden onChange={event=>{const file=event.target.files?.[0];if(file)void uploadVideo(file)}}/><button className="btn btn-primary" onClick={()=>fileRef.current?.click()} disabled={uploading}>{uploading?(locale==="ar"?"نرفع…":locale==="en"?"Uploading…":"Envoi…"):(locale==="ar"?"اختار فيديو المستشفى":locale==="en"?"Choose hospital video":"Choisir la vidéo de l'hôpital")}</button>{uploadError&&<small className="ar-upload-error">{uploadError}</small>}</>:<strong>{locale==="ar"?"نحضّر مسار الفيديو…":locale==="en"?"Preparing the walkthrough…":"Préparation du parcours vidéo…"}</strong>}</div>}
      <div className="ar-recorded-shade"/>
      <div className="ar-recorded-top"><Link className="ar-recorded-round" href="/" aria-label="Home">⌂</Link><div className="ar-recorded-destination"><span/><div><small>{locale==="ar"?"الوجهة":locale==="en"?"Destination":"Destination"}</small><strong>{locale==="ar"?"بلوك الطب النووي":locale==="en"?"Nuclear Medicine block":"Bloc Médecine nucléaire"}</strong></div></div><Link className="ar-recorded-round" href="/patient/map" aria-label="Map">⌖</Link></div>
      <div className="ar-recorded-heni"><HeniAvatar size={70} speaking={speaking}/><div><strong>Heni · هاني</strong><span>{speaking?(locale==="ar"?"نحكي معاك…":locale==="en"?"Guiding you…":"Je vous guide…"):label(cue)}</span></div></div>
      <div className="ar-recorded-target" style={{left:`${target.x}%`,top:`${target.y}%`}} aria-hidden="true"><div className="ar-recorded-reticle"><i/><i/><i/><i/></div><div className="ar-recorded-arrow" style={{transform:`rotate(${cue.angle}deg)`}}>↑</div><b>{label(cue)}</b></div>
      <div className="ar-recorded-bottom"><div className="ar-recorded-progress"><span style={{width:`${progress}%`}}/></div><div className="ar-recorded-step"><span>{String(cueIndex+1).padStart(2,"0")} / {String(cues.length).padStart(2,"0")}</span><strong>{label(cue)}</strong></div><p>{phrase(cue)}</p>{!voiceStarted?<button className="btn btn-primary btn-wide ar-start-voice" onClick={()=>void startVoiceWalk()} disabled={!videoReady}>▶ {locale==="ar"?"ابدأ الجولة مع صوت هاني":locale==="en"?"Start the walk with Heni voice":"Démarrer la visite avec la voix de Heni"}</button>:<div className="ar-recorded-controls"><button onClick={()=>void togglePlay()}>{playing?"Ⅱ":"▶"}</button><button onClick={restart}>↻</button><button className={voiceEnabled?"active":""} onClick={()=>{setVoiceEnabled(v=>!v);if(voiceEnabled&&typeof window!=="undefined"&&"speechSynthesis" in window){window.speechSynthesis.cancel();setSpeaking(false)}}}>{voiceEnabled?"♫":"♩"}</button></div>}</div>
    </div>
  </div>
}
