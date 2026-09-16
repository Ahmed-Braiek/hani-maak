"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { HeniAvatar } from "./HeniAvatar";

type Message = { role: "heni" | "user"; text: string; tool?: string };

const quickPrompts = [
  "Je veux un rendez-vous en imagerie",
  "شنوة نجيب للموعد؟",
  "وين نمشي للإيمagerie؟",
  "نحب نحكي مع موظف",
];

function browserSpeechRecognition() {
  if (typeof window === "undefined") return null;
  const w = window as typeof window & {
    SpeechRecognition?: new () => any;
    webkitSpeechRecognition?: new () => any;
  };
  return w.SpeechRecognition ?? w.webkitSpeechRecognition ?? null;
}

export function HeniCompanion() {
  const [open, setOpen] = useState(false);
  const [sessionId, setSessionId] = useState("");
  const [messages, setMessages] = useState<Message[]>([
    { role: "heni", text: "عسلامة! أنا Heni. نعاونك في الموعد، التحضير، الطريق والمتابعة." },
  ]);
  const [input, setInput] = useState("");
  const [busy, setBusy] = useState(false);
  const [speaking, setSpeaking] = useState(false);
  const [listening, setListening] = useState(false);
  const [micSupported, setMicSupported] = useState(true);
  const endRef = useRef<HTMLDivElement>(null);
  const mountedRef = useRef(true);

  useEffect(() => {
    mountedRef.current = true;
    setMicSupported(Boolean(browserSpeechRecognition()));
    return () => {
      mountedRef.current = false;
      if (typeof window !== "undefined" && "speechSynthesis" in window) window.speechSynthesis.cancel();
    };
  }, []);

  useEffect(() => {
    if (!open) return;
    endRef.current?.scrollIntoView({ behavior: "smooth", block: "nearest" });
  }, [messages, open]);

  const ensureSession = useCallback(async () => {
    if (sessionId) return sessionId;
    const res = await fetch("/api/v1/voice/session", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ locale: "ar", patientId: "patient-amal", source: "floating_heni" }),
    });
    const payload = await res.json();
    if (!res.ok) throw new Error(payload.error ?? "Impossible de démarrer Heni");
    if (mountedRef.current) setSessionId(payload.session.id);
    return payload.session.id as string;
  }, [sessionId]);

  function speak(text: string) {
    if (typeof window === "undefined" || !("speechSynthesis" in window)) return;
    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = /[\u0600-\u06ff]/.test(text) ? "ar-TN" : "fr-FR";
    utterance.rate = 0.93;
    utterance.pitch = 1;
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
    if (!text || busy) return;
    setBusy(true);
    setInput("");
    setMessages(current => [...current, { role: "user", text }]);
    try {
      const id = await ensureSession();
      let res = await fetch(`/api/v1/voice/session/${id}/turn`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ text }),
      });
      let payload = await res.json();
      if (res.status === 404 || String(payload.error ?? "").includes("Call session not found")) {
        setSessionId("");
        const restart = await fetch("/api/v1/voice/session", {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({ locale: "ar", patientId: "patient-amal", source: "floating_heni" }),
        });
        const fresh = await restart.json();
        if (!restart.ok) throw new Error(fresh.error ?? "Impossible de redémarrer Heni");
        setSessionId(fresh.session.id);
        res = await fetch(`/api/v1/voice/session/${fresh.session.id}/turn`, {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({ text }),
        });
        payload = await res.json();
      }
      if (!res.ok) throw new Error(payload.error ?? "Erreur de conversation");
      const answer = String(payload.message ?? "Je suis avec vous.");
      if (mountedRef.current) setMessages(current => [...current, { role: "heni", text: answer, tool: payload.tool }]);
      speak(answer);
    } catch (error) {
      const message = error instanceof Error ? error.message : "Erreur inconnue";
      if (mountedRef.current) setMessages(current => [...current, { role: "heni", text: `Je n'ai pas pu terminer cette action: ${message}` }]);
    } finally {
      if (mountedRef.current) setBusy(false);
    }
  }, [busy, ensureSession, input]);

  function listen() {
    const Recognition = browserSpeechRecognition();
    if (!Recognition) {
      setMicSupported(false);
      setMessages(current => [...current, { role: "heni", text: "Le micro vocal n'est pas disponible dans ce navigateur. Vous pouvez écrire votre demande." }]);
      return;
    }
    const recognition = new Recognition();
    recognition.lang = "ar-TN";
    recognition.interimResults = false;
    recognition.continuous = false;
    recognition.onstart = () => setListening(true);
    recognition.onend = () => setListening(false);
    recognition.onerror = () => setListening(false);
    recognition.onresult = (event: any) => {
      const transcript = String(event.results?.[0]?.[0]?.transcript ?? "").trim();
      if (!transcript) return;
      setInput(transcript);
      void send(transcript);
    };
    recognition.start();
  }

  return (
    <div className={`heni-companion ${open ? "is-open" : ""}`}>
      {open && (
        <section className="heni-panel" aria-label="Chat with Heni">
          <header className="heni-panel-head">
            <div className="row-start">
              <HeniAvatar size={58} speaking={speaking} listening={listening} />
              <div>
                <div className="eyebrow">Heni · هاني</div>
                <strong>Votre compagnon de parcours</strong>
                <div className="heni-online"><span /> Démo locale · outils enregistrés</div>
              </div>
            </div>
            <button className="icon-btn" onClick={() => setOpen(false)} aria-label="Fermer Heni">×</button>
          </header>

          <div className="heni-chat-log" aria-live="polite">
            {messages.map((message, index) => (
              <div className={`heni-message ${message.role}`} key={`${message.role}-${index}`}>
                {message.text}
                {message.tool && <div className="heni-tool">MCP demo · {message.tool}</div>}
              </div>
            ))}
            {busy && <div className="heni-thinking"><span/><span/><span/></div>}
            <div ref={endRef} />
          </div>

          <div className="heni-quick-row">
            {quickPrompts.map(prompt => (
              <button key={prompt} onClick={() => void send(prompt)} disabled={busy}>{prompt}</button>
            ))}
          </div>

          <div className="heni-compose">
            <button className={`heni-mic ${listening ? "active" : ""}`} onClick={listen} disabled={busy} aria-label="Parler à Heni">
              {listening ? "●" : "🎙"}
            </button>
            <input
              value={input}
              onChange={event => setInput(event.target.value)}
              onKeyDown={event => {
                if (event.key === "Enter") void send();
              }}
              placeholder={micSupported ? "Écrivez ou parlez…" : "Écrivez votre demande…"}
              aria-label="Message pour Heni"
            />
            <button className="heni-send" onClick={() => void send()} disabled={busy || !input.trim()} aria-label="Envoyer">→</button>
          </div>
          <div className="heni-safety">Administratif & informationnel. Heni ne diagnostique pas et ne modifie aucun traitement.</div>
        </section>
      )}

      <button className="heni-fab" onClick={() => setOpen(value => !value)} aria-expanded={open} aria-label="Ouvrir Heni">
        <HeniAvatar size={74} speaking={speaking} listening={listening} />
        {!open && <span className="heni-fab-label"><strong>Heni</strong><small>Je suis avec vous</small></span>}
      </button>
    </div>
  );
}
