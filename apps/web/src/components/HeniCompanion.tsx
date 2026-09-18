"use client";

import {useCallback,useEffect,useRef,useState} from "react";
import {HeniAvatar} from "./HeniAvatar";
import {usePersistentLocale} from "@/lib/locale-client";
import {tx} from "@/lib/i18n-namespaces";

type Message={role:"heni"|"user";text:string;tool?:string};
type VoiceState="idle"|"connecting"|"live";
type VoiceControl={type?:string;sessionId?:string;role?:"user"|"model";text?:string;name?:string;message?:string};

async function safeJson(res:Response){const text=await res.text();if(!text)return{};try{return JSON.parse(text)}catch{throw new Error("invalid_json_response")}}

function pcm16FromFloat(input:Float32Array,inputRate:number,outputRate=16000){
  if(outputRate>=inputRate){const direct=new Int16Array(input.length);for(let i=0;i<input.length;i++){const sample=Math.max(-1,Math.min(1,input[i]));direct[i]=sample<0?sample*32768:sample*32767}return direct}
  const ratio=inputRate/outputRate;const length=Math.max(1,Math.round(input.length/ratio));const out=new Int16Array(length);
  for(let i=0;i<length;i++){const start=Math.floor(i*ratio);const end=Math.min(input.length,Math.floor((i+1)*ratio));let sum=0,count=0;for(let j=start;j<end;j++){sum+=input[j];count++}const sample=Math.max(-1,Math.min(1,count?sum/count:input[Math.min(start,input.length-1)]||0));out[i]=sample<0?sample*32768:sample*32767}
  return out;
}

export function HeniCompanion(){
  const {locale,rtl}=usePersistentLocale();const tr=(key:string)=>tx(locale,key);const prompts=[tr("heni.prompt1"),tr("heni.prompt2"),tr("heni.prompt3"),tr("heni.prompt4")];
  const [open,setOpen]=useState(false);const [sessionId,setSessionId]=useState("");const [confirmationToken,setConfirmationToken]=useState("");const [messages,setMessages]=useState<Message[]>([{role:"heni",text:tr("heni.hello")}]);const [input,setInput]=useState("");const [busy,setBusy]=useState(false);const [speaking,setSpeaking]=useState(false);const [voiceState,setVoiceState]=useState<VoiceState>("idle");const [micSupported,setMicSupported]=useState(true);
  const endRef=useRef<HTMLDivElement>(null);const mountedRef=useRef(true);const busyRef=useRef(false);const wsRef=useRef<WebSocket|null>(null);const streamRef=useRef<MediaStream|null>(null);const audioContextRef=useRef<AudioContext|null>(null);const sourceNodeRef=useRef<MediaStreamAudioSourceNode|null>(null);const processorRef=useRef<ScriptProcessorNode|null>(null);const silentGainRef=useRef<GainNode|null>(null);const playbackSourcesRef=useRef(new Set<AudioBufferSourceNode>());const nextPlaybackRef=useRef(0);const lastTranscriptRoleRef=useRef<"user"|"heni"|null>(null);const liveToolRef=useRef<string|undefined>(undefined);
  const listening=voiceState==="live";
  const liveLabel=locale==="ar"?"محادثة صوتية مباشرة":locale==="en"?"Live voice":"Voix en direct";
  const connectingLabel=locale==="ar"?"نربط هاني…":locale==="en"?"Connecting Heni…":"Connexion à Heni…";
  const liveError=locale==="ar"?"الصوت المباشر موش متوفر توّا. تنجم تكتبلي هنا.":locale==="en"?"Live voice is unavailable right now. You can still type to me here.":"La voix en direct n’est pas disponible pour le moment. Vous pouvez toujours m’écrire ici.";

  const stopPlayback=useCallback(()=>{for(const source of playbackSourcesRef.current){try{source.stop()}catch{}}playbackSourcesRef.current.clear();nextPlaybackRef.current=0;if(mountedRef.current)setSpeaking(false)},[]);
  const cleanupVoice=useCallback((closeSocket=true)=>{
    const ws=wsRef.current;wsRef.current=null;
    if(closeSocket&&ws&&ws.readyState===WebSocket.OPEN){try{ws.send(JSON.stringify({type:"audio_stream_end"}))}catch{}try{ws.close(1000,"client_stop")}catch{}}
    processorRef.current?.disconnect();sourceNodeRef.current?.disconnect();silentGainRef.current?.disconnect();processorRef.current=null;sourceNodeRef.current=null;silentGainRef.current=null;
    streamRef.current?.getTracks().forEach(track=>track.stop());streamRef.current=null;stopPlayback();
    const context=audioContextRef.current;audioContextRef.current=null;if(context&&context.state!=="closed")void context.close().catch(()=>undefined);
    lastTranscriptRoleRef.current=null;liveToolRef.current=undefined;if(mountedRef.current)setVoiceState("idle");
  },[stopPlayback]);

  useEffect(()=>{mountedRef.current=true;setMicSupported(Boolean(typeof window!=="undefined"&&navigator.mediaDevices&&"WebSocket" in window&&"AudioContext" in window));return()=>{mountedRef.current=false;cleanupVoice(true);if(typeof window!=="undefined"&&"speechSynthesis" in window)window.speechSynthesis.cancel()}},[cleanupVoice]);
  useEffect(()=>{setSessionId("");setConfirmationToken("");setMessages([{role:"heni",text:tx(locale,"heni.hello")}]);setInput("");cleanupVoice(true)},[locale,cleanupVoice]);
  useEffect(()=>{if(open)endRef.current?.scrollIntoView({behavior:"smooth",block:"nearest"})},[messages,open,busy,voiceState]);

  function speak(text:string){if(typeof window==="undefined"||!("speechSynthesis" in window)||voiceState!=="idle")return;window.speechSynthesis.cancel();const utterance=new SpeechSynthesisUtterance(text);utterance.lang=locale==="ar"?"ar-TN":locale==="fr"?"fr-FR":"en-GB";utterance.rate=.93;const voices=window.speechSynthesis.getVoices();const masculineNames=locale==="ar"?["Majed","Maged","Tarik","Hamed"]:locale==="fr"?["Thomas","Henri","Paul","Nicolas"]:["Daniel","Alex","George","David","Mark"];const languageVoices=voices.filter(v=>v.lang.toLowerCase().startsWith(utterance.lang.toLowerCase().slice(0,2)));const wanted=masculineNames.map(name=>languageVoices.find(v=>v.name.toLowerCase().includes(name.toLowerCase()))).find(Boolean)??languageVoices.find(v=>/male|masculin|man/i.test(v.name))??languageVoices[0];if(wanted)utterance.voice=wanted;utterance.onstart=()=>mountedRef.current&&setSpeaking(true);utterance.onend=()=>mountedRef.current&&setSpeaking(false);utterance.onerror=()=>mountedRef.current&&setSpeaking(false);window.speechSynthesis.speak(utterance)}

  const send=useCallback(async(rawText?:string)=>{const text=(rawText??input).trim();if(!text||busyRef.current)return;busyRef.current=true;setBusy(true);setInput("");setMessages(current=>[...current,{role:"user",text}]);try{const history=messages.slice(-10).map(message=>({role:message.role==="user"?"user":"assistant",content:message.text}));const res=await fetch("/api/v1/heni/chat",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({message:text,locale,patientId:"patient-amal",role:"patient",source:"floating_heni",sessionId:sessionId||undefined,confirmationToken:confirmationToken||undefined,history})});const payload=await safeJson(res);if(!res.ok)throw new Error(String(payload?.error||"heni_chat_failed"));if(payload.sessionId&&mountedRef.current)setSessionId(String(payload.sessionId));if(mountedRef.current)setConfirmationToken(typeof payload.confirmationToken==="string"?payload.confirmationToken:"");const answer=String(payload.message??tx(locale,"heni.chat_error"));if(mountedRef.current)setMessages(current=>[...current,{role:"heni",text:answer,tool:payload.tool}]);speak(answer)}catch{if(mountedRef.current)setMessages(current=>[...current,{role:"heni",text:tx(locale,"heni.chat_error")}])}finally{busyRef.current=false;if(mountedRef.current)setBusy(false)}},[input,locale,messages,sessionId,confirmationToken,voiceState]);

  const appendTranscript=useCallback((role:"user"|"heni",raw:string)=>{const text=raw.trim();if(!text)return;setMessages(current=>{const last=current[current.length-1];if(last&&last.role===role&&lastTranscriptRoleRef.current===role){const replacement=text.startsWith(last.text)?text:`${last.text}${/[\s.,!?،؟]$/.test(last.text)?"":" "}${text}`;return [...current.slice(0,-1),{...last,text:replacement,tool:last.tool??(role==="heni"?liveToolRef.current:undefined)}]}return [...current,{role,text,tool:role==="heni"?liveToolRef.current:undefined}]});lastTranscriptRoleRef.current=role},[]);

  const playPcm=useCallback((data:ArrayBuffer)=>{const context=audioContextRef.current;if(!context||!data.byteLength)return;const pcm=new Int16Array(data);const buffer=context.createBuffer(1,pcm.length,24000);const channel=buffer.getChannelData(0);for(let i=0;i<pcm.length;i++)channel[i]=pcm[i]/(pcm[i]<0?32768:32767);const source=context.createBufferSource();source.buffer=buffer;source.connect(context.destination);const startAt=Math.max(context.currentTime+.02,nextPlaybackRef.current||0);nextPlaybackRef.current=startAt+buffer.duration;playbackSourcesRef.current.add(source);source.onended=()=>{playbackSourcesRef.current.delete(source);if(!playbackSourcesRef.current.size&&mountedRef.current)setSpeaking(false)};if(mountedRef.current)setSpeaking(true);source.start(startAt)},[]);

  async function startLiveVoice(){
    if(voiceState!=="idle")return;if(!micSupported){setMessages(current=>[...current,{role:"heni",text:tr("heni.mic_unsupported")}]);return}
    setOpen(true);setVoiceState("connecting");if(typeof window!=="undefined"&&"speechSynthesis" in window)window.speechSynthesis.cancel();
    try{
      const stream=await navigator.mediaDevices.getUserMedia({audio:{channelCount:1,echoCancellation:true,noiseSuppression:true,autoGainControl:true}});streamRef.current=stream;
      const AudioContextCtor=window.AudioContext;const context=new AudioContextCtor();audioContextRef.current=context;await context.resume();
      const tokenResponse=await fetch("/api/v1/heni/voice-token",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({locale}),cache:"no-store"});const tokenPayload=await safeJson(tokenResponse);if(!tokenResponse.ok||!tokenPayload.token||!tokenPayload.wsUrl)throw new Error("voice_token_failed");
      const ws=new WebSocket(`${String(tokenPayload.wsUrl)}?token=${encodeURIComponent(String(tokenPayload.token))}`);ws.binaryType="arraybuffer";wsRef.current=ws;
      await new Promise<void>((resolve,reject)=>{const timer=window.setTimeout(()=>reject(new Error("voice_connect_timeout")),8000);ws.onopen=()=>{window.clearTimeout(timer);resolve()};ws.onerror=()=>{window.clearTimeout(timer);reject(new Error("voice_socket_failed"))}});
      if(wsRef.current!==ws)throw new Error("voice_cancelled");
      const source=context.createMediaStreamSource(stream);const processor=context.createScriptProcessor(4096,1,1);const gain=context.createGain();gain.gain.value=0;source.connect(processor);processor.connect(gain);gain.connect(context.destination);sourceNodeRef.current=source;processorRef.current=processor;silentGainRef.current=gain;
      processor.onaudioprocess=event=>{if(ws.readyState!==WebSocket.OPEN)return;const pcm=pcm16FromFloat(event.inputBuffer.getChannelData(0),context.sampleRate,16000);if(pcm.byteLength)ws.send(pcm.buffer)};
      ws.onmessage=event=>{if(event.data instanceof ArrayBuffer){playPcm(event.data);return}if(typeof event.data!=="string")return;try{const message=JSON.parse(event.data) as VoiceControl;if(message.type==="session"&&message.sessionId)setSessionId(message.sessionId);else if(message.type==="transcript"&&message.text)appendTranscript(message.role==="user"?"user":"heni",message.text);else if(message.type==="tool_call"&&message.name)liveToolRef.current=message.name;else if(message.type==="turn_complete"){lastTranscriptRoleRef.current=null;liveToolRef.current=undefined}else if(message.type==="interrupted"){stopPlayback();lastTranscriptRoleRef.current=null}else if(message.type==="error")setMessages(current=>[...current,{role:"heni",text:liveError}])}catch{}};
      ws.onclose=()=>{if(wsRef.current===ws)cleanupVoice(false)};ws.onerror=()=>{if(wsRef.current===ws)setMessages(current=>[...current,{role:"heni",text:liveError}])};
      setVoiceState("live");
    }catch{cleanupVoice(true);if(mountedRef.current)setMessages(current=>[...current,{role:"heni",text:liveError}])}
  }

  async function toggleLiveVoice(){if(voiceState==="live"||voiceState==="connecting"){cleanupVoice(true);return}await startLiveVoice()}

  return <div className={`heni-companion ${open?"is-open":""} ${rtl?"rtl":""}`} dir={rtl?"rtl":"ltr"}>
    {open&&<section className="heni-panel" aria-label={tr("heni.title")}>
      <header className="heni-panel-head"><div className="row-start"><HeniAvatar size={58} speaking={speaking} listening={listening}/><div><div className="eyebrow">Heni · هاني</div><strong>{tr("heni.title")}</strong><div className="heni-online"><span/> {voiceState==="connecting"?connectingLabel:voiceState==="live"?liveLabel:tr("heni.online")}</div></div></div><button className="icon-btn" onClick={()=>{setOpen(false);cleanupVoice(true)}} aria-label={tr("heni.close")}>×</button></header>
      <div className="heni-chat-log" aria-live="polite">{messages.map((m,i)=><div className={`heni-message ${m.role}`} key={`${m.role}-${i}`}>{m.text}{m.tool&&<div className="heni-tool">✓ {m.tool}</div>}</div>)}{busy&&<div className="heni-thinking"><span/><span/><span/></div>}{voiceState==="connecting"&&<div className="heni-recording-state"><span/> {connectingLabel}</div>}{listening&&<div className="heni-recording-state"><span/> {liveLabel}</div>}<div ref={endRef}/></div>
      <div className="heni-quick-row">{prompts.map(prompt=><button key={prompt} onClick={()=>void send(prompt)} disabled={busy||voiceState!=="idle"}>{prompt}</button>)}</div>
      <div className="heni-compose"><button className={`heni-mic ${voiceState!=="idle"?"active":""}`} onClick={()=>void toggleLiveVoice()} disabled={busy} aria-label={tr(voiceState!=="idle"?"heni.stop":"heni.talk")}>{voiceState==="connecting"?"…":voiceState==="live"?"■":"🎙"}</button><input value={input} onChange={e=>setInput(e.target.value)} onKeyDown={e=>{if(e.key==="Enter"&&!e.shiftKey){e.preventDefault();void send()}}} placeholder={voiceState==="live"?liveLabel:tr(micSupported?"heni.placeholder":"heni.typed")} disabled={voiceState!=="idle"}/><button className="heni-send" onClick={()=>void send()} disabled={busy||voiceState!=="idle"||!input.trim()} aria-label={tr("heni.send")}>→</button></div>
      <div className="heni-safety">{tr("heni.safety")}</div>
    </section>}
    <button className="heni-fab" onClick={()=>setOpen(v=>!v)} aria-expanded={open} aria-label={tr("heni.open")}><HeniAvatar size={74} speaking={speaking} listening={listening}/>{!open&&<span className="heni-fab-label"><strong>Heni</strong><small>{voiceState==="live"?liveLabel:tr("heni.with_you")}</small></span>}</button>
  </div>;
}
