"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { HeniAvatar } from "./HeniAvatar";

type Msg = { role: "bot" | "user"; text: string; tool?: string; at?: string };

type RecognitionConstructor = new () => any;

function recognitionConstructor(): RecognitionConstructor | null {
  if (typeof window === "undefined") return null;
  const w = window as typeof window & {
    SpeechRecognition?: RecognitionConstructor;
    webkitSpeechRecognition?: RecognitionConstructor;
  };
  return w.SpeechRecognition ?? w.webkitSpeechRecognition ?? null;
}

const quick = [
  "Nheb ناخذ rendez-vous fil imagerie",
  "sbeh",
  "1",
  "اي نأكد",
  "شنوة نجيب؟",
  "وين نمشي؟",
  "Nnajjem nzid dose?",
  "نحب نحكي مع موظف",
];

export function VoiceLabClient() {
  const [sessionId, setSessionId] = useState("");
  const [msgs, setMsgs] = useState<Msg[]>([]);
  const [input, setInput] = useState("");
  const [busy, setBusy] = useState(false);
  const [listening, setListening] = useState(false);
  const [speaking, setSpeaking] = useState(false);
  const [started, setStarted] = useState(false);
  const [micSupported, setMicSupported] = useState(true);
  const [autoSpeak, setAutoSpeak] = useState(true);
  const bottom = useRef<HTMLDivElement>(null);
  const mounted = useRef(false);
  const recognitionRef = useRef<any>(null);

  const start = useCallback(async () => {
    setBusy(true);
    try {
      const response = await fetch("/api/v1/voice/session", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ locale: "ar", patientId: "patient-hedi", source: "voice_lab" }),
      });
      const payload = await response.json();
      if (!response.ok) throw new Error(payload.error ?? "Impossible de démarrer la conversation");
      if (!mounted.current) return;
      setSessionId(payload.session.id);
      setMsgs([{ role: "bot", text: payload.message, at: new Date().toISOString() }]);
      setStarted(true);
    } catch (error) {
      const message = error instanceof Error ? error.message : "Erreur inconnue";
      if (mounted.current) setMsgs([{ role: "bot", text: `Erreur de démarrage: ${message}` }]);
    } finally {
      if (mounted.current) setBusy(false);
    }
  }, []);

  useEffect(() => {
    mounted.current = true;
    setMicSupported(Boolean(recognitionConstructor()));

    async function bootstrap() {
      await start();
    }

    void bootstrap();

    return () => {
      mounted.current = false;
      recognitionRef.current?.stop?.();
      if (typeof window !== "undefined" && "speechSynthesis" in window) window.speechSynthesis.cancel();
    };
  }, [start]);

  useEffect(() => {
    bottom.current?.scrollIntoView({ behavior: "smooth", block: "nearest" });
    return undefined;
  }, [msgs]);

  function speak(text: string) {
    if (typeof window === "undefined" || !("speechSynthesis" in window)) return;
    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = /[\u0600-\u06ff]/.test(text) ? "ar-TN" : "fr-FR";
    utterance.rate = 0.92;
    utterance.pitch = 1;
    const voices = window.speechSynthesis.getVoices();
    const preferred = voices.find(v => v.lang.toLowerCase().startsWith(utterance.lang.slice(0, 2).toLowerCase()));
    if (preferred) utterance.voice = preferred;
    utterance.onstart = () => mounted.current && setSpeaking(true);
    utterance.onend = () => mounted.current && setSpeaking(false);
    utterance.onerror = () => mounted.current && setSpeaking(false);
    window.speechSynthesis.speak(utterance);
  }

  const send = useCallback(async (provided?: string) => {
    const text = (provided ?? input).trim();
    if (!text || !sessionId || busy) return;
    setMsgs(current => [...current, { role: "user", text, at: new Date().toISOString() }]);
    setInput("");
    setBusy(true);
    try {
      const response = await fetch(`/api/v1/voice/session/${sessionId}/turn`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ text }),
      });
      const payload = await response.json();
      if (!response.ok) throw new Error(payload.error ?? "Erreur de conversation");
      const message = String(payload.message ?? "Je suis avec vous.");
      if (!mounted.current) return;
      setMsgs(current => [...current, { role: "bot", text: message, tool: payload.tool, at: new Date().toISOString() }]);
      if (autoSpeak) speak(message);
    } catch (error) {
      const message = error instanceof Error ? error.message : "Erreur inconnue";
      if (mounted.current) setMsgs(current => [...current, { role: "bot", text: `Je n'ai pas pu terminer cette action: ${message}` }]);
    } finally {
      if (mounted.current) setBusy(false);
    }
  }, [autoSpeak, busy, input, sessionId]);

  function listen() {
    const Recognition = recognitionConstructor();
    if (!Recognition) {
      setMicSupported(false);
      setMsgs(current => [...current, { role: "bot", text: "La reconnaissance vocale du navigateur n'est pas disponible ici. Tapez votre phrase: le même flux et les mêmes outils restent actifs." }]);
      return;
    }
    if (listening) {
      recognitionRef.current?.stop?.();
      return;
    }
    const recognition = new Recognition();
    recognitionRef.current = recognition;
    recognition.lang = "ar-TN";
    recognition.interimResults = true;
    recognition.continuous = false;
    recognition.maxAlternatives = 1;
    recognition.onstart = () => mounted.current && setListening(true);
    recognition.onend = () => mounted.current && setListening(false);
    recognition.onerror = (event: any) => {
      if (!mounted.current) return;
      setListening(false);
      setMsgs(current => [...current, { role: "bot", text: `Micro: ${event?.error ?? "reconnaissance interrompue"}. Vous pouvez continuer au clavier.` }]);
    };
    recognition.onresult = (event: any) => {
      const result = event.results?.[event.results.length - 1];
      const transcript = String(result?.[0]?.transcript ?? "").trim();
      if (!transcript) return;
      setInput(transcript);
      if (result.isFinal) void send(transcript);
    };
    recognition.start();
  }

  async function restart() {
    if (typeof window !== "undefined" && "speechSynthesis" in window) window.speechSynthesis.cancel();
    recognitionRef.current?.stop?.();
    setSpeaking(false);
    setListening(false);
    setSessionId("");
    setMsgs([]);
    setStarted(false);
    await start();
  }

  return (
    <div className="voice-lab-layout">
      <section className="voice-stage">
        <div className="voice-stage-top">
          <div>
            <div className="eyebrow">Conversation live · local demo</div>
            <h2>Parlez naturellement à Heni.</h2>
            <p>Aucun fournisseur externe n'est requis pour ce mode. Le navigateur gère micro et synthèse vocale quand il les supporte; le moteur Hani Maak gère les actions.</p>
          </div>
          <div className="voice-state-badge">
            <span className={listening ? "live" : busy ? "busy" : "ready"} />
            {listening ? "j'écoute" : busy ? "je traite" : speaking ? "je parle" : started ? "prêt" : "connexion"}
          </div>
        </div>

        <div className="voice-character-zone">
          <div className={`voice-rings ${listening ? "listen" : speaking ? "speak" : ""}`}>
            <HeniAvatar size={156} speaking={speaking} listening={listening} />
          </div>
          <div className="voice-character-copy">
            <strong>Heni · هاني</strong>
            <span>Assistant patient administratif</span>
          </div>
          <div className="waveform" aria-hidden="true">
            {Array.from({ length: 22 }).map((_, i) => <i key={i} style={{ animationDelay: `${i * 35}ms` }} />)}
          </div>
        </div>

        <div className="voice-conversation" aria-live="polite">
          {msgs.map((message, index) => (
            <div className={`voice-turn ${message.role}`} key={`${message.role}-${index}`}>
              <div className="voice-turn-label">{message.role === "bot" ? "Heni" : "Vous"}</div>
              <div className="voice-turn-text">{message.text}</div>
              {message.tool && <div className="voice-tool-event">✓ action enregistrée · {message.tool}</div>}
            </div>
          ))}
          {busy && <div className="voice-turn bot"><div className="voice-turn-label">Heni</div><div className="typing"><span/><span/><span/></div></div>}
          <div ref={bottom} />
        </div>

        <div className="voice-controls">
          <button className={`talk-button ${listening ? "active" : ""}`} onClick={listen} disabled={busy}>
            <span>{listening ? "■" : "🎙"}</span>
            <strong>{listening ? "Arrêter" : "Parlez"}</strong>
            <small>{micSupported ? "Tunisien / Français" : "Micro non supporté"}</small>
          </button>
          <label className="switch-line">
            <input type="checkbox" checked={autoSpeak} onChange={event => setAutoSpeak(event.target.checked)} />
            <span>Réponse vocale automatique</span>
          </label>
        </div>

        <div className="chat-input voice-text-input">
          <input
            className="input"
            value={input}
            onChange={event => setInput(event.target.value)}
            onKeyDown={event => {
              if (event.key === "Enter") void send();
            }}
            placeholder="اكتب أو احكي… / Écrivez ou parlez…"
          />
          <button className="btn btn-primary" onClick={() => void send()} disabled={busy || !input.trim()}>Envoyer</button>
        </div>
      </section>

      <aside className="voice-demo-rail">
        <div className="card voice-proof-card">
          <div className="eyebrow">Ce que cette démo prouve</div>
          <h3>La voix utilise le même moteur que l'app.</h3>
          <div className="proof-list">
            <div><span>1</span><p>La phrase est comprise par le moteur de conversation de démonstration.</p></div>
            <div><span>2</span><p>Les créneaux viennent du moteur de planning, jamais d'une réponse inventée.</p></div>
            <div><span>3</span><p>Une écriture exige une confirmation explicite.</p></div>
            <div><span>4</span><p>L'action et son outil apparaissent dans la console staff.</p></div>
          </div>
        </div>

        <div className="card card-flat">
          <div className="row"><strong>Scénario guidé</strong><span className="badge info">8 étapes</span></div>
          <p className="muted tiny">Cliquez une phrase pour la placer dans la zone de saisie, puis envoyez-la. Vous pouvez aussi la dire au micro.</p>
          <div className="voice-shortcuts">
            {quick.map((phrase, index) => (
              <button key={phrase} onClick={() => setInput(phrase)}>
                <span>{index + 1}</span><b>{phrase}</b>
              </button>
            ))}
          </div>
        </div>

        <div className="card card-flat voice-safety-card">
          <div className="eyebrow">Safety proof</div>
          <strong>Essayez: “Nnajjem nzid dose?”</strong>
          <p>Heni doit refuser de modifier le traitement et créer une escalade humaine. La compétition peut montrer cette trace dans la console.</p>
        </div>

        <div className="stack">
          <button className="btn btn-secondary btn-wide" onClick={() => void restart()}>↻ Nouvelle conversation</button>
          <a className="btn btn-primary btn-wide" href="/staff/calls">Voir la trace outils + conversation →</a>
        </div>
      </aside>
    </div>
  );
}
