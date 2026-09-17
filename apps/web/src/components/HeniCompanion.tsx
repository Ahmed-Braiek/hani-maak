"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { HeniAvatar } from "./HeniAvatar";
import { usePersistentLocale } from "@/lib/locale-client";
import { tx } from "@/lib/i18n-namespaces";

type Message = { role: "heni" | "user"; text: string; tool?: string };
type RecognitionLike = {
  lang: string;
  interimResults: boolean;
  continuous: boolean;
  onstart: (() => void) | null;
  onend: (() => void) | null;
  onerror: ((event: any) => void) | null;
  onresult: ((event: any) => void) | null;
  start: () => void;
  stop: () => void;
  abort?: () => void;
};

function browserSpeechRecognition() {
  if (typeof window === "undefined") return null;
  const w = window as typeof window & {
    SpeechRecognition?: new () => RecognitionLike;
    webkitSpeechRecognition?: new () => RecognitionLike;
  };
  return w.SpeechRecognition ?? w.webkitSpeechRecognition ?? null;
}

async function safeJson(res: Response) {
  const text = await res.text();
  if (!text) return {};
  try { return JSON.parse(text); } catch { throw new Error("invalid_json_response"); }
}

export function HeniCompanion() {
  const { locale, rtl } = usePersistentLocale();
  const tr = (key: string) => tx(locale, key);
  const prompts = [tr("heni.prompt1"), tr("heni.prompt2"), tr("heni.prompt3"), tr("heni.prompt4")];
  const [open, setOpen] = useState(false);
  const [sessionId, setSessionId] = useState("");
  const [messages, setMessages] = useState<Message[]>([{ role: "heni", text: tr("heni.hello") }]);
  const [input, setInput] = useState("");
  const [busy, setBusy] = useState(false);
  const [speaking, setSpeaking] = useState(false);
  const [listening, setListening] = useState(false);
  const [micSupported, setMicSupported] = useState(true);
  const endRef = useRef<HTMLDivElement>(null);
  const mountedRef = useRef(true);
  const recognitionRef = useRef<RecognitionLike | null>(null);
  const busyRef = useRef(false);

  useEffect(() => {
    mountedRef.current = true;
    setMicSupported(Boolean(browserSpeechRecognition()));
    return () => {
      mountedRef.current = false;
      recognitionRef.current?.abort?.();
      if (typeof window !== "undefined" && "speechSynthesis" in window) window.speechSynthesis.cancel();
    };
  }, []);

  useEffect(() => {
    setSessionId("");
    setMessages([{ role: "heni", text: tx(locale, "heni.hello") }]);
    setInput("");
    recognitionRef.current?.abort?.();
    setListening(false);
  }, [locale]);

  useEffect(() => {
    if (open) endRef.current?.scrollIntoView({ behavior: "smooth", block: "nearest" });
  }, [messages, open, busy]);

  function speak(text: string) {
    if (typeof window === "undefined" || !("speechSynthesis" in window)) return;
    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = locale === "ar" ? "ar-TN" : locale === "fr" ? "fr-FR" : "en-GB";
    utterance.rate = 0.93;
    const voices = window.speechSynthesis.getVoices();
    const wanted = voices.find(v => v.lang.toLowerCase().startsWith(utterance.lang.toLowerCase().slice(0, 2)));
    if (wanted) utterance.voice = wanted;
    utterance.onstart = () => mountedRef.current && setSpeaking(true);
    utterance.onend = () => mountedRef.current && setSpeaking(false);
    utterance.onerror = () => mountedRef.current && setSpeaking(false);
    window.speechSynthesis.speak(utterance);
  }

  const send = useCallback(async (rawText?: string) => {
    const text = (rawText ?? input).trim();
    if (!text || busyRef.current) return;
    busyRef.current = true;
    setBusy(true);
    setInput("");
    setMessages(current => [...current, { role: "user", text }]);
    try {
      const history = messages.slice(-10).map(message => ({
        role: message.role === "user" ? "user" : "assistant",
        content: message.text
      }));
      const res = await fetch("/api/v1/heni/chat", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          message: text,
          locale,
          patientId: "patient-amal",
          role: "patient",
          source: "floating_heni",
          sessionId: sessionId || undefined,
          history
        })
      });
      const payload = await safeJson(res);
      if (!res.ok) throw new Error(String(payload?.error || "heni_chat_failed"));
      if (payload.sessionId && mountedRef.current) setSessionId(String(payload.sessionId));
      const answer = String(payload.message ?? tx(locale, "heni.chat_error"));
      if (mountedRef.current) setMessages(current => [...current, { role: "heni", text: answer, tool: payload.tool }]);
      speak(answer);
    } catch {
      if (mountedRef.current) setMessages(current => [...current, { role: "heni", text: tx(locale, "heni.chat_error") }]);
    } finally {
      busyRef.current = false;
      if (mountedRef.current) setBusy(false);
    }
  }, [input, locale, messages, sessionId]);

  async function toggleListen() {
    if (listening) { recognitionRef.current?.stop(); return; }
    const Recognition = browserSpeechRecognition();
    if (!Recognition) {
      setMicSupported(false);
      setMessages(current => [...current, { role: "heni", text: tr("heni.mic_unsupported") }]);
      return;
    }
    try {
      if (navigator.mediaDevices?.getUserMedia) {
        const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        stream.getTracks().forEach(track => track.stop());
      }
      const recognition = new Recognition();
      recognitionRef.current = recognition;
      recognition.lang = locale === "ar" ? "ar-TN" : locale === "fr" ? "fr-FR" : "en-GB";
      recognition.interimResults = false;
      recognition.continuous = false;
      recognition.onstart = () => setListening(true);
      recognition.onend = () => { setListening(false); recognitionRef.current = null; };
      recognition.onerror = (event: any) => {
        setListening(false);
        recognitionRef.current = null;
        setMessages(current => [...current, { role: "heni", text: tr(event?.error === "not-allowed" ? "heni.mic_denied" : "heni.mic_empty") }]);
      };
      recognition.onresult = (event: any) => {
        const transcript = String(event.results?.[0]?.[0]?.transcript ?? "").trim();
        if (!transcript) {
          setMessages(current => [...current, { role: "heni", text: tr("heni.mic_empty") }]);
          return;
        }
        setInput(transcript);
        void send(transcript);
      };
      recognition.start();
    } catch {
      setListening(false);
      setMessages(current => [...current, { role: "heni", text: tr("heni.mic_denied") }]);
    }
  }

  return <div className={`heni-companion ${open ? "is-open" : ""} ${rtl ? "rtl" : ""}`} dir={rtl ? "rtl" : "ltr"}>
    {open && <section className="heni-panel" aria-label={tr("heni.title")}>
      <header className="heni-panel-head">
        <div className="row-start"><HeniAvatar size={58} speaking={speaking} listening={listening}/><div><div className="eyebrow">Heni · هاني</div><strong>{tr("heni.title")}</strong><div className="heni-online"><span/> {tr("heni.online")}</div></div></div>
        <button className="icon-btn" onClick={() => setOpen(false)} aria-label={tr("heni.close")}>×</button>
      </header>
      <div className="heni-chat-log" aria-live="polite">
        {messages.map((m, i) => <div className={`heni-message ${m.role}`} key={`${m.role}-${i}`}>{m.text}{m.tool && <div className="heni-tool">tool · {m.tool}</div>}</div>)}
        {busy && <div className="heni-thinking"><span/><span/><span/></div>}
        {listening && <div className="heni-recording-state"><span/> {tr("heni.listening")}</div>}
        <div ref={endRef}/>
      </div>
      <div className="heni-quick-row">{prompts.map(prompt => <button key={prompt} onClick={() => void send(prompt)} disabled={busy}>{prompt}</button>)}</div>
      <div className="heni-compose">
        <button className={`heni-mic ${listening ? "active" : ""}`} onClick={() => void toggleListen()} disabled={busy} aria-label={tr(listening ? "heni.stop" : "heni.talk")}>{listening ? "■" : "🎙"}</button>
        <input value={input} onChange={e => setInput(e.target.value)} onKeyDown={e => { if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); void send(); } }} placeholder={tr(micSupported ? "heni.placeholder" : "heni.typed")}/>
        <button className="heni-send" onClick={() => void send()} disabled={busy || !input.trim()} aria-label={tr("heni.send")}>→</button>
      </div>
      <div className="heni-safety">{tr("heni.safety")}</div>
    </section>}
    <button className="heni-fab" onClick={() => setOpen(v => !v)} aria-expanded={open} aria-label={tr("heni.open")}>
      <HeniAvatar size={74} speaking={speaking} listening={listening}/>
      {!open && <span className="heni-fab-label"><strong>Heni</strong><small>{tr("heni.with_you")}</small></span>}
    </button>
  </div>;
}
