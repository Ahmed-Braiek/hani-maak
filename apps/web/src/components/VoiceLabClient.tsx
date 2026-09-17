"use client";

import {useCallback,useEffect,useMemo,useRef,useState} from "react";
import {HeniAvatar} from "./HeniAvatar";
import {usePersistentLocale} from "@/lib/locale-client";

type CallState="idle"|"connecting"|"live"|"ended"|"error";
type TranscriptRole="user"|"heni";
type TranscriptLine={role:TranscriptRole;text:string};
type ToolEvent={name:string;at:number};
type VoiceControl={
  type?:string;
  sessionId?:string;
  role?:"user"|"model";
  text?:string;
  name?:string;
  args?:Record<string,unknown>;
  message?:string;
};

type Copy={
  eyebrow:string;
  title:string;
  intro:string;
  start:string;
  connecting:string;
  live:string;
  listening:string;
  speaking:string;
  muted:string;
  mute:string;
  unmute:string;
  end:string;
  again:string;
  ready:string;
  transcript:string;
  transcriptEmpty:string;
  actions:string;
  actionsEmpty:string;
  privacy:string;
  unavailable:string;
  permission:string;
  ended:string;
  you:string;
  heni:string;
};

const COPY:Record<"ar"|"fr"|"en",Copy>={
  ar:{
    eyebrow:"مكالمة مباشرة مع هاني",
    title:"إحكي مع هاني كيما في مكالمة حقيقية",
    intro:"إضغط إبدأ المكالمة وإحكي عادي. هاني يسمعك، يجاوبك بالصوت في نفس اللحظة، وينجم ينفّذ الخدمات المسموح بها بعد التأكيد.",
    start:"إبدأ المكالمة",
    connecting:"نربط هاني…",
    live:"المكالمة شغّالة",
    listening:"هاني يسمع فيك",
    speaking:"هاني يحكي",
    muted:"الميكروفون مسكّر",
    mute:"سكّر الميكروفون",
    unmute:"حلّ الميكروفون",
    end:"إنهي المكالمة",
    again:"عاود إتصل",
    ready:"جاهز وقت اللي إنت جاهز",
    transcript:"النص المباشر",
    transcriptEmpty:"الكلام يبان هنا وقت تبدأ تحكي.",
    actions:"شنوة عمل هاني",
    actionsEmpty:"الإجراءات كيف الحجز أو التوجيه يبانوا هنا.",
    privacy:"هاني للمساعدة الإدارية والتوجيه. الأسئلة الطبية يلزمها مهني صحي.",
    unavailable:"المكالمة المباشرة موش متوفرة توّا. يلزم خدمة Heni Agent تكون مربوطة ومفعّلة.",
    permission:"يلزم تسمح باستعمال الميكروفون باش تبدأ المكالمة.",
    ended:"المكالمة وفات",
    you:"إنت",
    heni:"هاني"
  },
  fr:{
    eyebrow:"Appel Heni en direct",
    title:"Parlez à Heni comme dans un vrai appel",
    intro:"Appuyez sur démarrer puis parlez naturellement. Heni vous écoute, répond immédiatement à voix haute et peut exécuter les actions autorisées après confirmation.",
    start:"Démarrer l’appel",
    connecting:"Connexion à Heni…",
    live:"Appel en direct",
    listening:"Heni vous écoute",
    speaking:"Heni parle",
    muted:"Micro coupé",
    mute:"Couper le micro",
    unmute:"Réactiver le micro",
    end:"Terminer l’appel",
    again:"Rappeler Heni",
    ready:"Prêt quand vous l’êtes",
    transcript:"Transcription en direct",
    transcriptEmpty:"La conversation apparaîtra ici pendant l’appel.",
    actions:"Actions de Heni",
    actionsEmpty:"Les actions comme la réservation ou le guidage apparaîtront ici.",
    privacy:"Heni aide pour l’administratif et le parcours patient. Les décisions médicales restent avec les professionnels de santé.",
    unavailable:"La voix en direct n’est pas disponible pour le moment. Le service Heni Agent doit être déployé et connecté.",
    permission:"Autorisez l’accès au microphone pour démarrer l’appel.",
    ended:"Appel terminé",
    you:"Vous",
    heni:"Heni"
  },
  en:{
    eyebrow:"Live Heni call",
    title:"Talk to Heni like a real phone call",
    intro:"Tap start and speak naturally. Heni listens continuously, answers out loud in real time, and can perform approved actions after confirmation.",
    start:"Start live call",
    connecting:"Connecting Heni…",
    live:"Live call",
    listening:"Heni is listening",
    speaking:"Heni is speaking",
    muted:"Microphone muted",
    mute:"Mute microphone",
    unmute:"Unmute microphone",
    end:"End call",
    again:"Call Heni again",
    ready:"Ready when you are",
    transcript:"Live transcript",
    transcriptEmpty:"Your conversation will appear here while you speak.",
    actions:"Heni actions",
    actionsEmpty:"Actions such as booking or guidance will appear here.",
    privacy:"Heni handles administrative help and patient navigation. Medical decisions remain with healthcare professionals.",
    unavailable:"Live voice is unavailable right now. The Heni Agent service must be deployed and connected.",
    permission:"Allow microphone access to start the live call.",
    ended:"Call ended",
    you:"You",
    heni:"Heni"
  }
};

const TOOL_LABELS:Record<string,{ar:string;fr:string;en:string}>={
  get_patient_context:{ar:"راجع مسارك",fr:"Parcours consulté",en:"Journey checked"},
  find_services:{ar:"لقّى المصلحة",fr:"Service recherché",en:"Service found"},
  get_service_details:{ar:"جاب معلومات المصلحة",fr:"Informations du service",en:"Service details"},
  check_appointment_availability:{ar:"ثبت المواعيد",fr:"Disponibilités vérifiées",en:"Availability checked"},
  create_appointment:{ar:"حجز موعد",fr:"Rendez-vous réservé",en:"Appointment booked"},
  reschedule_appointment:{ar:"بدّل الموعد",fr:"Rendez-vous déplacé",en:"Appointment rescheduled"},
  cancel_appointment:{ar:"لغى الموعد",fr:"Rendez-vous annulé",en:"Appointment cancelled"},
  get_appointment:{ar:"راجع الموعد",fr:"Rendez-vous consulté",en:"Appointment checked"},
  get_journey_status:{ar:"راجع المرحلة",fr:"Étape du parcours consultée",en:"Journey status checked"},
  get_navigation_context:{ar:"حضّر التوجيه",fr:"Guidage préparé",en:"Guidance prepared"},
  get_approved_instructions:{ar:"جاب التعليمات",fr:"Instructions récupérées",en:"Instructions retrieved"},
  request_human_help:{ar:"طلب مساعدة بشرية",fr:"Aide humaine demandée",en:"Human help requested"}
};

function safeJson(response:Response){
  return response.text().then(text=>{
    if(!text)return {};
    try{return JSON.parse(text)}catch{return {error:"invalid_json_response"}}
  });
}

function pcm16FromFloat(input:Float32Array,inputRate:number,outputRate=16000){
  if(outputRate>=inputRate){
    const direct=new Int16Array(input.length);
    for(let i=0;i<input.length;i++){
      const sample=Math.max(-1,Math.min(1,input[i]));
      direct[i]=sample<0?sample*32768:sample*32767;
    }
    return direct;
  }
  const ratio=inputRate/outputRate;
  const length=Math.max(1,Math.round(input.length/ratio));
  const out=new Int16Array(length);
  for(let i=0;i<length;i++){
    const start=Math.floor(i*ratio);
    const end=Math.min(input.length,Math.floor((i+1)*ratio));
    let sum=0,count=0;
    for(let j=start;j<end;j++){sum+=input[j];count++}
    const fallback=input[Math.min(start,input.length-1)]??0;
    const sample=Math.max(-1,Math.min(1,count?sum/count:fallback));
    out[i]=sample<0?sample*32768:sample*32767;
  }
  return out;
}

function formatDuration(seconds:number){
  const mins=Math.floor(seconds/60);
  const secs=seconds%60;
  return `${String(mins).padStart(2,"0")}:${String(secs).padStart(2,"0")}`;
}

export function VoiceLabClient(){
  const {locale,rtl}=usePersistentLocale();
  const language=locale==="fr"?"fr":locale==="en"?"en":"ar";
  const c=COPY[language];

  const [state,setState]=useState<CallState>("idle");
  const [sessionId,setSessionId]=useState("");
  const [transcript,setTranscript]=useState<TranscriptLine[]>([]);
  const [tools,setTools]=useState<ToolEvent[]>([]);
  const [muted,setMuted]=useState(false);
  const [speaking,setSpeaking]=useState(false);
  const [seconds,setSeconds]=useState(0);
  const [error,setError]=useState("");
  const [micSupported,setMicSupported]=useState(true);

  const mounted=useRef(false);
  const wsRef=useRef<WebSocket|null>(null);
  const streamRef=useRef<MediaStream|null>(null);
  const audioContextRef=useRef<AudioContext|null>(null);
  const sourceNodeRef=useRef<MediaStreamAudioSourceNode|null>(null);
  const processorRef=useRef<ScriptProcessorNode|null>(null);
  const silentGainRef=useRef<GainNode|null>(null);
  const playbackSourcesRef=useRef(new Set<AudioBufferSourceNode>());
  const nextPlaybackRef=useRef(0);
  const lastTranscriptRoleRef=useRef<TranscriptRole|null>(null);
  const transcriptEndRef=useRef<HTMLDivElement|null>(null);

  const callActive=state==="connecting"||state==="live";

  const stateLabel=useMemo(()=>{
    if(state==="connecting")return c.connecting;
    if(state==="ended")return c.ended;
    if(state==="error")return c.unavailable;
    if(muted&&state==="live")return c.muted;
    if(speaking&&state==="live")return c.speaking;
    if(state==="live")return c.listening;
    return c.ready;
  },[c,state,muted,speaking]);

  const stopPlayback=useCallback(()=>{
    for(const source of playbackSourcesRef.current){
      try{source.stop()}catch{}
    }
    playbackSourcesRef.current.clear();
    nextPlaybackRef.current=0;
    if(mounted.current)setSpeaking(false);
  },[]);

  const cleanupAudio=useCallback((closeSocket=true)=>{
    const ws=wsRef.current;
    wsRef.current=null;
    if(closeSocket&&ws){
      if(ws.readyState===WebSocket.OPEN){
        try{ws.send(JSON.stringify({type:"audio_stream_end"}))}catch{}
        try{ws.close(1000,"call_ended")}catch{}
      }else if(ws.readyState===WebSocket.CONNECTING){
        try{ws.close()}catch{}
      }
    }

    processorRef.current?.disconnect();
    sourceNodeRef.current?.disconnect();
    silentGainRef.current?.disconnect();
    processorRef.current=null;
    sourceNodeRef.current=null;
    silentGainRef.current=null;

    streamRef.current?.getTracks().forEach(track=>track.stop());
    streamRef.current=null;

    stopPlayback();

    const context=audioContextRef.current;
    audioContextRef.current=null;
    if(context&&context.state!=="closed")void context.close().catch(()=>undefined);

    lastTranscriptRoleRef.current=null;
  },[stopPlayback]);

  useEffect(()=>{
    mounted.current=true;
    const supported=typeof window!=="undefined"&&Boolean(navigator.mediaDevices)&&("WebSocket" in window)&&("AudioContext" in window);
    setMicSupported(supported);
    return()=>{
      mounted.current=false;
      cleanupAudio(true);
    };
  },[cleanupAudio]);

  useEffect(()=>{
    if(state!=="live")return;
    const timer=window.setInterval(()=>setSeconds(value=>value+1),1000);
    return()=>window.clearInterval(timer);
  },[state]);

  useEffect(()=>{
    transcriptEndRef.current?.scrollIntoView({behavior:"smooth",block:"nearest"});
  },[transcript]);

  const appendTranscript=useCallback((role:TranscriptRole,raw:string)=>{
    const text=raw.trim();
    if(!text)return;
    setTranscript(current=>{
      const last=current[current.length-1];
      if(last&&last.role===role&&lastTranscriptRoleRef.current===role){
        const merged=text.startsWith(last.text)
          ? text
          : `${last.text}${/[\s.,!?،؟]$/.test(last.text)?"":" "}${text}`;
        return [...current.slice(0,-1),{...last,text:merged}];
      }
      return [...current,{role,text}];
    });
    lastTranscriptRoleRef.current=role;
  },[]);

  const playPcm=useCallback((data:ArrayBuffer)=>{
    const context=audioContextRef.current;
    if(!context||!data.byteLength)return;
    const pcm=new Int16Array(data);
    if(!pcm.length)return;

    const buffer=context.createBuffer(1,pcm.length,24000);
    const channel=buffer.getChannelData(0);
    for(let i=0;i<pcm.length;i++){
      channel[i]=pcm[i]/(pcm[i]<0?32768:32767);
    }

    const source=context.createBufferSource();
    source.buffer=buffer;
    source.connect(context.destination);
    const startAt=Math.max(context.currentTime+0.015,nextPlaybackRef.current||0);
    nextPlaybackRef.current=startAt+buffer.duration;
    playbackSourcesRef.current.add(source);
    source.onended=()=>{
      playbackSourcesRef.current.delete(source);
      if(!playbackSourcesRef.current.size&&mounted.current)setSpeaking(false);
    };
    if(mounted.current)setSpeaking(true);
    source.start(startAt);
  },[]);

  const endCall=useCallback((nextState:CallState="ended")=>{
    cleanupAudio(true);
    if(mounted.current){
      setState(nextState);
      setMuted(false);
      setSpeaking(false);
    }
  },[cleanupAudio]);

  async function startCall(){
    if(callActive)return;
    if(!micSupported){
      setError(c.permission);
      setState("error");
      return;
    }

    setError("");
    setState("connecting");
    setTranscript([]);
    setTools([]);
    setSeconds(0);
    setMuted(false);
    setSpeaking(false);
    setSessionId("");

    try{
      const stream=await navigator.mediaDevices.getUserMedia({
        audio:{
          channelCount:1,
          echoCancellation:true,
          noiseSuppression:true,
          autoGainControl:true
        }
      });
      streamRef.current=stream;

      const context=new AudioContext();
      audioContextRef.current=context;
      await context.resume();

      const tokenResponse=await fetch("/api/v1/heni/voice-token",{
        method:"POST",
        headers:{"content-type":"application/json"},
        body:JSON.stringify({locale:language}),
        cache:"no-store"
      });
      const tokenPayload=await safeJson(tokenResponse) as {token?:string;wsUrl?:string;sessionId?:string;error?:string};
      if(!tokenResponse.ok||!tokenPayload.token||!tokenPayload.wsUrl){
        throw new Error(tokenPayload.error||"voice_token_failed");
      }

      if(tokenPayload.sessionId)setSessionId(tokenPayload.sessionId);

      const ws=new WebSocket(`${tokenPayload.wsUrl}?token=${encodeURIComponent(tokenPayload.token)}`);
      ws.binaryType="arraybuffer";
      wsRef.current=ws;

      ws.onmessage=event=>{
        if(event.data instanceof ArrayBuffer){
          playPcm(event.data);
          return;
        }
        if(typeof event.data!=="string")return;
        try{
          const message=JSON.parse(event.data) as VoiceControl;
          if(message.type==="session"&&message.sessionId)setSessionId(message.sessionId);
          if(message.type==="transcript"&&message.text){
            appendTranscript(message.role==="user"?"user":"heni",message.text);
          }
          if(message.type==="tool_call"&&message.name){
            setTools(current=>[...current,{name:message.name!,at:Date.now()}].slice(-8));
          }
          if(message.type==="turn_complete"){
            lastTranscriptRoleRef.current=null;
          }
          if(message.type==="interrupted"){
            stopPlayback();
            lastTranscriptRoleRef.current=null;
          }
          if(message.type==="error"){
            setError(c.unavailable);
          }
        }catch{}
      };

      await new Promise<void>((resolve,reject)=>{
        const timer=window.setTimeout(()=>reject(new Error("voice_connect_timeout")),10000);
        ws.onopen=()=>{
          window.clearTimeout(timer);
          resolve();
        };
        ws.onerror=()=>{
          window.clearTimeout(timer);
          reject(new Error("voice_socket_failed"));
        };
      });

      if(wsRef.current!==ws)throw new Error("voice_cancelled");

      ws.onclose=()=>{
        if(wsRef.current===ws){
          cleanupAudio(false);
          if(mounted.current&&state!=="error")setState("ended");
        }
      };
      ws.onerror=()=>{
        if(wsRef.current===ws&&mounted.current){
          setError(c.unavailable);
        }
      };

      const source=context.createMediaStreamSource(stream);
      const processor=context.createScriptProcessor(2048,1,1);
      const gain=context.createGain();
      gain.gain.value=0;
      source.connect(processor);
      processor.connect(gain);
      gain.connect(context.destination);
      sourceNodeRef.current=source;
      processorRef.current=processor;
      silentGainRef.current=gain;

      processor.onaudioprocess=event=>{
        if(ws.readyState!==WebSocket.OPEN)return;
        const pcm=pcm16FromFloat(event.inputBuffer.getChannelData(0),context.sampleRate,16000);
        if(pcm.byteLength)ws.send(pcm.buffer);
      };

      setState("live");
    }catch(err){
      cleanupAudio(true);
      if(!mounted.current)return;
      const message=err instanceof Error?err.message:"voice_failed";
      setError(message==="NotAllowedError"?c.permission:c.unavailable);
      setState("error");
    }
  }

  function toggleMute(){
    const stream=streamRef.current;
    if(!stream)return;
    const next=!muted;
    stream.getAudioTracks().forEach(track=>{track.enabled=!next});
    setMuted(next);
  }

  const toolLabel=(name:string)=>{
    const label=TOOL_LABELS[name];
    return label?label[language]:name.replaceAll("_"," ");
  };

  return <div className={`live-call-shell ${rtl?"rtl":""}`} dir={rtl?"rtl":"ltr"}>
    <section className="live-call-stage">
      <div className="live-call-statusbar">
        <div>
          <div className="eyebrow">{c.eyebrow}</div>
          <strong>{stateLabel}</strong>
        </div>
        <div className={`live-call-pill ${state==="live"?"online":state==="connecting"?"connecting":""}`}>
          <span/>
          {state==="live"?c.live:state==="connecting"?c.connecting:state==="ended"?c.ended:c.ready}
        </div>
      </div>

      <div className="live-call-center">
        <div className={`live-call-avatar-wrap ${state==="live"?"active":""} ${speaking?"speaking":""}`}>
          <div className="live-call-ring ring-one"/>
          <div className="live-call-ring ring-two"/>
          <HeniAvatar size={184} speaking={speaking} listening={state==="live"&&!muted}/>
        </div>
        <div className="live-call-identity">
          <h2>Heni · هاني</h2>
          <p>{state==="live"?formatDuration(seconds):c.ready}</p>
        </div>

        {state==="idle"&&<button className="live-call-start" onClick={()=>void startCall()}>
          <span>☎</span>
          <strong>{c.start}</strong>
        </button>}

        {state==="connecting"&&<button className="live-call-start connecting" disabled>
          <span className="live-call-loader"/>
          <strong>{c.connecting}</strong>
        </button>}

        {(state==="ended"||state==="error")&&<div className="live-call-restart">
          {error&&<p>{error}</p>}
          <button className="live-call-start" onClick={()=>void startCall()}>
            <span>☎</span>
            <strong>{c.again}</strong>
          </button>
        </div>}

        {state==="live"&&<div className="live-call-controls">
          <button className={muted?"is-muted":""} onClick={toggleMute}>
            <span>{muted?"🔇":"🎙"}</span>
            <small>{muted?c.unmute:c.mute}</small>
          </button>
          <button className="hangup" onClick={()=>endCall("ended")}>
            <span>×</span>
            <small>{c.end}</small>
          </button>
        </div>}

        <div className="live-call-wave" aria-hidden="true">
          {Array.from({length:28}).map((_,index)=><i key={index} className={state==="live"&&!muted?"active":""} style={{animationDelay:`${index*28}ms`}}/>)}
        </div>
      </div>

      <div className="live-call-caption">
        <span>{speaking?c.speaking:state==="live"&&!muted?c.listening:stateLabel}</span>
        <strong>{transcript.length?transcript[transcript.length-1].text:c.intro}</strong>
      </div>
    </section>

    <aside className="live-call-side">
      <div className="live-call-panel">
        <div className="live-call-panel-head">
          <div><span className="live-call-panel-icon">≋</span><strong>{c.transcript}</strong></div>
          {sessionId&&<small>{sessionId.slice(0,8)}</small>}
        </div>
        <div className="live-call-transcript">
          {!transcript.length&&<p className="live-call-empty">{c.transcriptEmpty}</p>}
          {transcript.map((line,index)=><div className={`live-caption-line ${line.role}`} key={`${line.role}-${index}`}>
            <span>{line.role==="user"?c.you:c.heni}</span>
            <p>{line.text}</p>
          </div>)}
          <div ref={transcriptEndRef}/>
        </div>
      </div>

      <div className="live-call-panel compact">
        <div className="live-call-panel-head">
          <div><span className="live-call-panel-icon">✓</span><strong>{c.actions}</strong></div>
        </div>
        <div className="live-tool-list">
          {!tools.length&&<p className="live-call-empty">{c.actionsEmpty}</p>}
          {tools.map((event,index)=><div className="live-tool-item" key={`${event.name}-${event.at}-${index}`}>
            <span>✓</span>
            <strong>{toolLabel(event.name)}</strong>
          </div>)}
        </div>
      </div>

      <div className="live-call-safety">{c.privacy}</div>
    </aside>
  </div>;
}
