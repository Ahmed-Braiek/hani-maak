"use client";

import {useCallback,useEffect,useMemo,useRef,useState} from "react";
import {HeniAvatar} from "./HeniAvatar";
import {Logo} from "./Logo";
import {usePersistentLocale} from "@/lib/locale-client";

type Mode="call"|"chat";
type CallState="idle"|"connecting"|"live"|"ended"|"error";
type TranscriptRole="user"|"heni";
type TranscriptLine={role:TranscriptRole;text:string};
type ToolEvent={name:string;at:number};
type ChatMessage={role:"user"|"heni";text:string;tool?:string};
type RecognitionLike={
  lang:string;
  continuous:boolean;
  interimResults:boolean;
  onstart:(()=>void)|null;
  onend:(()=>void)|null;
  onerror:((event:any)=>void)|null;
  onresult:((event:any)=>void)|null;
  start:()=>void;
  stop:()=>void;
  abort?:()=>void;
};
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
  eyebrow:string; title:string; intro:string;
  choose:string; callMode:string; callHint:string; chatMode:string; chatHint:string;
  start:string; connecting:string; live:string; listening:string; speaking:string; muted:string; mute:string; unmute:string; end:string; again:string; ready:string;
  transcript:string; transcriptEmpty:string; actions:string; actionsEmpty:string; privacy:string; unavailable:string; permission:string; ended:string; you:string; heni:string;
  chatWelcome:string; chatPlaceholder:string; send:string; voiceMessage:string; recording:string; voiceUnsupported:string; chatError:string; quickTitle:string;
  quick:string[];
};

const COPY:Record<"ar"|"fr"|"en",Copy>={
  ar:{
    eyebrow:"هاني معاك بالصوت والكتابة",title:"اختار كيفاش تحب تحكي مع هاني",intro:"مكالمة مباشرة كيما التليفون، ولا شات سريع بالكتابة أو برسالة صوتية. نفس هاني، نفس المسار، ونفس الحماية.",
    choose:"طريقة التواصل",callMode:"إتصل بهاني",callHint:"محادثة صوت بصوت مباشرة",chatMode:"شات مع هاني",chatHint:"كتابة أو رسالة صوتية",
    start:"إبدأ المكالمة",connecting:"نربط هاني…",live:"المكالمة شغّالة",listening:"هاني يسمع فيك",speaking:"هاني يحكي",muted:"الميكروفون مسكّر",mute:"سكّر الميكروفون",unmute:"حلّ الميكروفون",end:"إنهي المكالمة",again:"عاود إتصل",ready:"جاهز وقت اللي إنت جاهز",
    transcript:"النص المباشر",transcriptEmpty:"الكلام يبان هنا وقت تبدأ تحكي.",actions:"شنوة عمل هاني",actionsEmpty:"الإجراءات كيف الحجز أو التوجيه يبانوا هنا.",privacy:"هاني يساعدك في المواعيد، التوجيه، التحضير والمتابعة. القرارات الطبية تبقى عند مهني الصحة.",unavailable:"المكالمة المباشرة موش متوفرة توّا. تنجم تستعمل الشات.",permission:"يلزم تسمح باستعمال الميكروفون.",ended:"المكالمة وفات",you:"إنت",heni:"هاني",
    chatWelcome:"عسلامة 👋 أنا هاني. تنجم تكتبلي، ولا تضغط على الميكروفون وتحكيلي. نعاونك في الموعد، المصلحة، التوجيه والتحضير.",chatPlaceholder:"أكتب شنوة تحب تعمل…",send:"إبعث",voiceMessage:"رسالة صوتية",recording:"نسمع فيك… إحكي عادي",voiceUnsupported:"الرسالة الصوتية موش مدعومة في المتصفح هذا. تنجم تكتبلي.",chatError:"صار مشكل صغير. عاود جرّب بعد شوية.",quickTitle:"شنوة نجم نعاونك فيه؟",
    quick:["نحب نحجز موعد","وين نلقى المصلحة؟","شنوة نجيب معايا؟","نحب نحكي مع موظف"]
  },
  fr:{
    eyebrow:"Heni en voix et en chat",title:"Choisissez simplement comment parler à Heni",intro:"Lancez un vrai appel vocal en temps réel, ou utilisez le chat avec texte ou message vocal. Même assistant, même parcours, mêmes règles de sécurité.",
    choose:"Mode de conversation",callMode:"Appeler Heni",callHint:"Conversation voix-à-voix en direct",chatMode:"Chatter avec Heni",chatHint:"Texte ou message vocal",
    start:"Démarrer l’appel",connecting:"Connexion à Heni…",live:"Appel en direct",listening:"Heni vous écoute",speaking:"Heni parle",muted:"Micro coupé",mute:"Couper le micro",unmute:"Réactiver le micro",end:"Terminer l’appel",again:"Rappeler Heni",ready:"Prêt quand vous l’êtes",
    transcript:"Conversation en direct",transcriptEmpty:"La conversation apparaîtra ici pendant l’appel.",actions:"Actions de Heni",actionsEmpty:"Les réservations, vérifications ou guidages apparaîtront ici.",privacy:"Heni aide pour les rendez-vous, le guidage, la préparation et le suivi. Les décisions médicales restent avec les professionnels de santé.",unavailable:"La voix en direct n’est pas disponible pour le moment. Vous pouvez utiliser le chat.",permission:"Autorisez l’accès au microphone.",ended:"Appel terminé",you:"Vous",heni:"Heni",
    chatWelcome:"Bonjour 👋 Je suis Heni. Écrivez-moi ou touchez le micro pour m’envoyer votre demande à la voix. Je peux vous aider avec les rendez-vous, les services, le guidage et la préparation.",chatPlaceholder:"Écrivez ce dont vous avez besoin…",send:"Envoyer",voiceMessage:"Message vocal",recording:"Je vous écoute… parlez naturellement",voiceUnsupported:"Le message vocal n’est pas disponible sur ce navigateur. Vous pouvez toujours écrire.",chatError:"Je n’ai pas pu répondre cette fois. Réessayez dans un instant.",quickTitle:"Je peux vous aider avec",
    quick:["Je veux prendre rendez-vous","Où se trouve mon service ?","Que dois-je apporter ?","Je veux parler à un agent"]
  },
  en:{
    eyebrow:"Heni by voice or chat",title:"Choose the easiest way to talk to Heni",intro:"Start a real-time voice call, or use chat with text or a voice message. Same assistant, same patient journey, same safety rules.",
    choose:"Conversation mode",callMode:"Call Heni",callHint:"Live speech-to-speech conversation",chatMode:"Chat with Heni",chatHint:"Text or voice message",
    start:"Start live call",connecting:"Connecting Heni…",live:"Live call",listening:"Heni is listening",speaking:"Heni is speaking",muted:"Microphone muted",mute:"Mute microphone",unmute:"Unmute microphone",end:"End call",again:"Call Heni again",ready:"Ready when you are",
    transcript:"Live conversation",transcriptEmpty:"Your conversation will appear here while you speak.",actions:"Heni actions",actionsEmpty:"Bookings, checks and guidance will appear here.",privacy:"Heni helps with appointments, guidance, preparation and follow-up. Medical decisions remain with healthcare professionals.",unavailable:"Live voice is unavailable right now. You can still use chat.",permission:"Allow microphone access.",ended:"Call ended",you:"You",heni:"Heni",
    chatWelcome:"Hi 👋 I’m Heni. Type to me or tap the microphone to send your request by voice. I can help with appointments, services, directions and preparation.",chatPlaceholder:"Tell Heni what you need…",send:"Send",voiceMessage:"Voice message",recording:"Listening… speak naturally",voiceUnsupported:"Voice messages are not available in this browser. You can still type.",chatError:"I couldn’t answer that time. Please try again in a moment.",quickTitle:"I can help you with",
    quick:["I want to book an appointment","Where is my service?","What should I bring?","I want to speak to a person"]
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

function recognitionConstructor(){
  if(typeof window==="undefined")return null;
  const w=window as typeof window&{
    SpeechRecognition?:new()=>RecognitionLike;
    webkitSpeechRecognition?:new()=>RecognitionLike;
  };
  return w.SpeechRecognition??w.webkitSpeechRecognition??null;
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

  const [mode,setMode]=useState<Mode>("call");
  const [state,setState]=useState<CallState>("idle");
  const [sessionId,setSessionId]=useState("");
  const [transcript,setTranscript]=useState<TranscriptLine[]>([]);
  const [tools,setTools]=useState<ToolEvent[]>([]);
  const [muted,setMuted]=useState(false);
  const [speaking,setSpeaking]=useState(false);
  const [seconds,setSeconds]=useState(0);
  const [error,setError]=useState("");
  const [micSupported,setMicSupported]=useState(true);

  const [chatSessionId,setChatSessionId]=useState("");
  const [chatMessages,setChatMessages]=useState<ChatMessage[]>([{role:"heni",text:c.chatWelcome}]);
  const [chatInput,setChatInput]=useState("");
  const [chatBusy,setChatBusy]=useState(false);
  const [dictating,setDictating]=useState(false);

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
  const chatEndRef=useRef<HTMLDivElement|null>(null);
  const recognitionRef=useRef<RecognitionLike|null>(null);

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
    for(const source of playbackSourcesRef.current){try{source.stop()}catch{}}
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
      }else if(ws.readyState===WebSocket.CONNECTING){try{ws.close()}catch{}}
    }
    processorRef.current?.disconnect();
    sourceNodeRef.current?.disconnect();
    silentGainRef.current?.disconnect();
    processorRef.current=null;sourceNodeRef.current=null;silentGainRef.current=null;
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
      recognitionRef.current?.abort?.();
    };
  },[cleanupAudio]);

  useEffect(()=>{
    if(state!=="live")return;
    const timer=window.setInterval(()=>setSeconds(value=>value+1),1000);
    return()=>window.clearInterval(timer);
  },[state]);

  useEffect(()=>{transcriptEndRef.current?.scrollIntoView({behavior:"smooth",block:"nearest"})},[transcript]);
  useEffect(()=>{chatEndRef.current?.scrollIntoView({behavior:"smooth",block:"nearest"})},[chatMessages,chatBusy]);

  useEffect(()=>{
    setChatMessages([{role:"heni",text:c.chatWelcome}]);
    setChatInput("");
    setChatSessionId("");
  },[language,c.chatWelcome]);

  const appendTranscript=useCallback((role:TranscriptRole,raw:string)=>{
    const text=raw.trim();
    if(!text)return;
    setTranscript(current=>{
      const last=current[current.length-1];
      if(last&&last.role===role&&lastTranscriptRoleRef.current===role){
        const merged=text.startsWith(last.text)?text:`${last.text}${/[\s.,!?،؟]$/.test(last.text)?"":" "}${text}`;
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
    for(let i=0;i<pcm.length;i++)channel[i]=pcm[i]/(pcm[i]<0?32768:32767);
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
    if(mounted.current){setState(nextState);setMuted(false);setSpeaking(false)}
  },[cleanupAudio]);

  async function startCall(){
    if(callActive)return;
    if(!micSupported){setError(c.permission);setState("error");return}
    setError("");setState("connecting");setTranscript([]);setTools([]);setSeconds(0);setMuted(false);setSpeaking(false);setSessionId("");
    try{
      const stream=await navigator.mediaDevices.getUserMedia({audio:{channelCount:1,echoCancellation:true,noiseSuppression:true,autoGainControl:true}});
      streamRef.current=stream;
      const context=new AudioContext();
      audioContextRef.current=context;
      await context.resume();
      const tokenResponse=await fetch("/api/v1/heni/voice-token",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({locale:language}),cache:"no-store"});
      const tokenPayload=await safeJson(tokenResponse) as {token?:string;wsUrl?:string;sessionId?:string;error?:string};
      if(!tokenResponse.ok||!tokenPayload.token||!tokenPayload.wsUrl)throw new Error(tokenPayload.error||"voice_token_failed");
      if(tokenPayload.sessionId)setSessionId(tokenPayload.sessionId);
      const ws=new WebSocket(`${tokenPayload.wsUrl}?token=${encodeURIComponent(tokenPayload.token)}`);
      ws.binaryType="arraybuffer";
      wsRef.current=ws;
      ws.onmessage=event=>{
        if(event.data instanceof ArrayBuffer){playPcm(event.data);return}
        if(typeof event.data!=="string")return;
        try{
          const message=JSON.parse(event.data) as VoiceControl;
          if(message.type==="session"&&message.sessionId)setSessionId(message.sessionId);
          if(message.type==="transcript"&&message.text)appendTranscript(message.role==="user"?"user":"heni",message.text);
          if(message.type==="tool_call"&&message.name)setTools(current=>[...current,{name:message.name!,at:Date.now()}].slice(-8));
          if(message.type==="turn_complete")lastTranscriptRoleRef.current=null;
          if(message.type==="interrupted"){stopPlayback();lastTranscriptRoleRef.current=null}
          if(message.type==="error")setError(c.unavailable);
        }catch{}
      };
      await new Promise<void>((resolve,reject)=>{
        const timer=window.setTimeout(()=>reject(new Error("voice_connect_timeout")),10000);
        ws.onopen=()=>{window.clearTimeout(timer);resolve()};
        ws.onerror=()=>{window.clearTimeout(timer);reject(new Error("voice_socket_failed"))};
      });
      if(wsRef.current!==ws)throw new Error("voice_cancelled");
      ws.onclose=()=>{
        if(wsRef.current===ws){
          cleanupAudio(false);
          if(mounted.current)setState(current=>current==="error"?"error":"ended");
        }
      };
      ws.onerror=()=>{if(wsRef.current===ws&&mounted.current)setError(c.unavailable)};
      const source=context.createMediaStreamSource(stream);
      const processor=context.createScriptProcessor(2048,1,1);
      const gain=context.createGain();
      gain.gain.value=0;
      source.connect(processor);processor.connect(gain);gain.connect(context.destination);
      sourceNodeRef.current=source;processorRef.current=processor;silentGainRef.current=gain;
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

  async function sendChat(provided?:string){
    const text=(provided??chatInput).trim();
    if(!text||chatBusy)return;
    setChatInput("");
    setChatBusy(true);
    setChatMessages(current=>[...current,{role:"user",text}]);
    try{
      const history=chatMessages.slice(-12).map(item=>({role:item.role==="user"?"user":"assistant",content:item.text}));
      const response=await fetch("/api/v1/heni/chat",{
        method:"POST",
        headers:{"content-type":"application/json"},
        body:JSON.stringify({message:text,locale:language,patientId:"patient-amal",role:"patient",source:"voice_lab_chat",sessionId:chatSessionId||undefined,history})
      });
      const payload=await safeJson(response) as {message?:string;sessionId?:string;tool?:string;error?:string};
      if(!response.ok)throw new Error(payload.error||"chat_failed");
      if(payload.sessionId)setChatSessionId(payload.sessionId);
      setChatMessages(current=>[...current,{role:"heni",text:String(payload.message||c.chatError),tool:payload.tool}]);
    }catch{
      setChatMessages(current=>[...current,{role:"heni",text:c.chatError}]);
    }finally{
      if(mounted.current)setChatBusy(false);
    }
  }

  async function toggleDictation(){
    if(dictating){recognitionRef.current?.stop();return}
    const Recognition=recognitionConstructor();
    if(!Recognition){
      setChatMessages(current=>[...current,{role:"heni",text:c.voiceUnsupported}]);
      return;
    }
    try{
      if(navigator.mediaDevices?.getUserMedia){
        const stream=await navigator.mediaDevices.getUserMedia({audio:true});
        stream.getTracks().forEach(track=>track.stop());
      }
      const recognition=new Recognition();
      recognitionRef.current=recognition;
      recognition.lang=language==="ar"?"ar-TN":language==="fr"?"fr-FR":"en-GB";
      recognition.continuous=false;
      recognition.interimResults=true;
      recognition.onstart=()=>setDictating(true);
      recognition.onend=()=>{setDictating(false);recognitionRef.current=null};
      recognition.onerror=()=>{setDictating(false);recognitionRef.current=null;setChatMessages(current=>[...current,{role:"heni",text:c.voiceUnsupported}])};
      recognition.onresult=event=>{
        const result=event.results?.[event.results.length-1];
        const text=String(result?.[0]?.transcript??"").trim();
        if(text)setChatInput(text);
        if(text&&result?.isFinal)void sendChat(text);
      };
      recognition.start();
    }catch{
      setDictating(false);
      setChatMessages(current=>[...current,{role:"heni",text:c.permission}]);
    }
  }

  function changeMode(next:Mode){
    if(next===mode)return;
    if(callActive)endCall("ended");
    recognitionRef.current?.abort?.();
    setDictating(false);
    setMode(next);
  }

  const toolLabel=(name:string)=>{
    const label=TOOL_LABELS[name];
    return label?label[language]:name.replaceAll("_"," ");
  };

  return <div className={`heni-hub ${rtl?"rtl":""}`} dir={rtl?"rtl":"ltr"}>
    <section className="heni-hub-intro">
      <div>
        <div className="eyebrow">{c.eyebrow}</div>
        <h1>{c.title}</h1>
        <p>{c.intro}</p>
      </div>
      <div className="heni-hub-avatar"><HeniAvatar size={92} speaking={speaking} listening={state==="live"&&!muted||dictating}/><span>Heni · هاني</span></div>
    </section>

    <div className="heni-mode-picker" aria-label={c.choose}>
      <button type="button" className={mode==="call"?"active":""} onClick={()=>changeMode("call")}>
        <span className="heni-mode-icon">☎</span>
        <span><strong>{c.callMode}</strong><small>{c.callHint}</small></span>
        <b>→</b>
      </button>
      <button type="button" className={mode==="chat"?"active":""} onClick={()=>changeMode("chat")}>
        <span className="heni-mode-icon">✦</span>
        <span><strong>{c.chatMode}</strong><small>{c.chatHint}</small></span>
        <b>→</b>
      </button>
    </div>

    {mode==="call"?<div className="live-call-shell">
      <section className="live-call-stage">
        <div className="live-call-statusbar">
          <div className="live-call-brand">
            <span className="live-call-brand-logo"><Logo compact/></span>
            <div className="live-call-brand-copy"><div className="eyebrow">{c.callMode}</div><strong>{stateLabel}</strong></div>
          </div>
          <div className={`live-call-pill ${state==="live"?"online":state==="connecting"?"connecting":""}`}><span/>{state==="live"?c.live:state==="connecting"?c.connecting:state==="ended"?c.ended:c.ready}</div>
        </div>

        <div className="live-call-center">
          <div className={`live-call-avatar-wrap ${state==="live"?"active":""} ${speaking?"speaking":""}`}>
            <div className="live-call-ring ring-one"/><div className="live-call-ring ring-two"/>
            <HeniAvatar size={184} speaking={speaking} listening={state==="live"&&!muted}/>
          </div>
          <div className="live-call-identity"><h2>Heni · هاني</h2><p>{state==="live"?formatDuration(seconds):c.callHint}</p></div>

          {state==="idle"&&<button className="live-call-start" onClick={()=>void startCall()}><span>☎</span><strong>{c.start}</strong></button>}
          {state==="connecting"&&<button className="live-call-start connecting" disabled><span className="live-call-loader"/><strong>{c.connecting}</strong></button>}
          {(state==="ended"||state==="error")&&<div className="live-call-restart">{error&&<p>{error}</p>}<button className="live-call-start" onClick={()=>void startCall()}><span>☎</span><strong>{c.again}</strong></button></div>}
          {state==="live"&&<div className="live-call-controls">
            <button className={muted?"is-muted":""} onClick={toggleMute}><span>{muted?"🔇":"🎙"}</span><small>{muted?c.unmute:c.mute}</small></button>
            <button className="hangup" onClick={()=>endCall("ended")}><span>×</span><small>{c.end}</small></button>
          </div>}
          <div className="live-call-wave" aria-hidden="true">{Array.from({length:28}).map((_,index)=><i key={index} className={state==="live"&&!muted?"active":""} style={{animationDelay:`${index*28}ms`}}/>)}</div>
        </div>

        <div className="live-call-caption"><span>{speaking?c.speaking:state==="live"&&!muted?c.listening:stateLabel}</span><strong>{transcript.length?transcript[transcript.length-1].text:c.callHint}</strong></div>
      </section>

      <aside className="live-call-side">
        <div className="live-call-panel">
          <div className="live-call-panel-head"><div><span className="live-call-panel-icon">≋</span><strong>{c.transcript}</strong></div>{sessionId&&<small>{sessionId.slice(0,8)}</small>}</div>
          <div className="live-call-transcript">
            {!transcript.length&&<p className="live-call-empty">{c.transcriptEmpty}</p>}
            {transcript.map((line,index)=><div className={`live-caption-line ${line.role}`} key={`${line.role}-${index}`}><span>{line.role==="user"?c.you:c.heni}</span><p>{line.text}</p></div>)}
            <div ref={transcriptEndRef}/>
          </div>
        </div>
        <div className="live-call-panel compact">
          <div className="live-call-panel-head"><div><span className="live-call-panel-icon">✓</span><strong>{c.actions}</strong></div></div>
          <div className="live-tool-list">{!tools.length&&<p className="live-call-empty">{c.actionsEmpty}</p>}{tools.map((event,index)=><div className="live-tool-item" key={`${event.name}-${event.at}-${index}`}><span>✓</span><strong>{toolLabel(event.name)}</strong></div>)}</div>
        </div>
        <div className="live-call-safety">{c.privacy}</div>
      </aside>
    </div>:<section className="heni-chat-experience">
      <div className="heni-chat-main">
        <div className="heni-chat-head">
          <div className="heni-chat-person"><HeniAvatar size={56}/><div><strong>Heni · هاني</strong><small><span/> {c.ready}</small></div></div>
          <div className="heni-chat-channel">✦ {c.chatMode}</div>
        </div>

        <div className="heni-chat-feed" aria-live="polite">
          {chatMessages.map((message,index)=><div className={`heni-chat-bubble ${message.role}`} key={`${message.role}-${index}`}>
            {message.role==="heni"&&<div className="heni-chat-mini-avatar"><HeniAvatar size={30}/></div>}
            <div><span>{message.role==="heni"?c.heni:c.you}</span><p>{message.text}</p>{message.tool&&<small>✓ {toolLabel(message.tool)}</small>}</div>
          </div>)}
          {chatBusy&&<div className="heni-chat-bubble heni"><div className="heni-chat-mini-avatar"><HeniAvatar size={30}/></div><div className="heni-chat-typing"><i/><i/><i/></div></div>}
          {dictating&&<div className="heni-chat-listening"><span>🎙</span><strong>{c.recording}</strong></div>}
          <div ref={chatEndRef}/>
        </div>

        <div className="heni-chat-compose">
          <button type="button" className={`heni-voice-note ${dictating?"recording":""}`} onClick={()=>void toggleDictation()} disabled={chatBusy} aria-label={c.voiceMessage}>
            <span>{dictating?"■":"🎙"}</span><small>{dictating?c.recording:c.voiceMessage}</small>
          </button>
          <div className="heni-chat-input-wrap">
            <input value={chatInput} onChange={event=>setChatInput(event.target.value)} onKeyDown={event=>{if(event.key==="Enter"){event.preventDefault();void sendChat()}}} placeholder={c.chatPlaceholder} disabled={chatBusy||dictating}/>
            <button type="button" onClick={()=>void sendChat()} disabled={chatBusy||!chatInput.trim()} aria-label={c.send}>➤</button>
          </div>
        </div>
      </div>

      <aside className="heni-chat-quick">
        <div className="heni-chat-quick-head"><span>✦</span><div><strong>{c.quickTitle}</strong><small>{c.chatHint}</small></div></div>
        <div className="heni-chat-quick-list">{c.quick.map((prompt,index)=><button type="button" key={prompt} onClick={()=>void sendChat(prompt)} disabled={chatBusy}><span>{index+1}</span><strong>{prompt}</strong><b>→</b></button>)}</div>
        <div className="heni-chat-privacy"><span>✓</span><p>{c.privacy}</p></div>
      </aside>
    </section>}
  </div>;
}
