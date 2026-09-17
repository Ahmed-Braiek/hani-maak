import Link from "next/link";
import {Logo} from "@/components/Logo";
import {HeniAvatar} from "@/components/HeniAvatar";

export default function Landing(){return <>
  <section className="hero competition-hero"><div className="container">
    <div className="topbar"><Logo/><div className="nav-actions"><Link className="btn btn-secondary" href="/present">Presentation</Link><Link className="btn btn-secondary" href="/staff">Staff console</Link><Link className="btn btn-primary" href="/patient">Start journey →</Link></div></div>
    <div className="hero-grid">
      <div className="hero-copy">
        <div className="eyebrow">Hani Maak · هاني معاك</div>
        <h1 className="h1">From “I need care” to “I know what comes next.”</h1>
        <p><strong>Hani Maak — هاني معاك</strong> is the patient-journey infrastructure that connects access, hospital guidance and continuity — through a mobile experience, voice conversation and the same operational backend.</p>
        <div className="hero-ctas"><Link className="btn btn-primary" href="/patient">Start patient journey</Link><Link className="btn btn-secondary" href="/voice-lab">Talk to Heni</Link><Link className="btn btn-secondary" href="/patient/map">See hospital guidance</Link></div>
        <div className="pill-row"><span className="pill">Access</span><span className="pill">Guidance + AR</span><span className="pill">Continuity</span><span className="pill">Tunisian Arabic voice</span><span className="pill">Auditable tools</span><span className="pill">White-label SaaS</span></div>
      </div>

      <div className="hero-product-stack">
        <div className="phone-frame" aria-label="Patient app preview"><div className="phone-screen"><div className="status"><span>9:41</span><span>● ● ●</span></div><Logo/><div style={{marginTop:34}}><div className="muted tiny">Bonjour Amel</div><div style={{fontSize:"1.8rem",fontWeight:850,letterSpacing:"-.04em"}}>Je suis avec vous.</div></div><div className="next-card"><div className="eyebrow">Votre prochaine étape</div><h3 style={{fontSize:"1.45rem",margin:"8px 0"}}>Préparez votre visite</h3><p style={{margin:0}}>Imagerie médicale · 09:30</p><div className="btn">Continuer le parcours →</div></div><div className="mini-card"><div className="row"><strong>Parcours</strong><span className="badge good">2 / 5</span></div><div className="progress-line"><span className="dot on"/><span className="dot on"/><span className="dot"/><span className="dot"/><span className="dot"/></div></div><div className="mini-card"><strong>Pas de smartphone ?</strong><p className="muted tiny">Parlez à Heni. Le même moteur peut organiser le rendez-vous par conversation.</p></div></div></div>
        <div className="hero-heni-card"><HeniAvatar size={88}/><div><div className="eyebrow">Heni · هاني</div><strong>One companion, every step.</strong><p>Ask, book, prepare, find the service, continue care.</p></div><Link href="/voice-lab">Parlez →</Link></div>
      </div>
    </div>
  </div></section>

  <section className="section section-soft"><div className="container"><div className="eyebrow">One journey · multiple interfaces</div><h2 className="h2">Not another appointment app.</h2><div className="grid-3"><article className="feature"><div className="feature-icon">◷</div><h3>Access</h3><p>Rule-derived slots, confirmation, cancellation and rescheduling through mobile or conversation.</p></article><article className="feature"><div className="feature-icon">⌖</div><h3>Guidance</h3><p>Preparation, route guidance and camera-assisted AR cues that accompany the patient toward the service.</p></article><article className="feature"><div className="feature-icon">✓</div><h3>Continuity</h3><p>Provider-authored instructions, reminders, next steps and staff visibility after the appointment.</p></article></div></div></section>

  <section className="section"><div className="container"><div className="proof-strip"><div><span>01</span><strong>Patient books</strong><small>shared journey state</small></div><i>→</i><div><span>02</span><strong>Heni guides</strong><small>map + AR</small></div><i>→</i><div><span>03</span><strong>Voice acts</strong><small>guided actions</small></div><i>→</i><div><span>04</span><strong>Staff sees it</strong><small>action timeline</small></div><i>→</i><div><span>05</span><strong>Journey continues</strong><small>follow-up</small></div></div><div className="demo-band" style={{marginTop:22}}><div><div className="eyebrow" style={{color:"#8de0d3"}}>Connected journey</div><h2 style={{margin:"7px 0"}}>One patient journey. One shared operational flow.</h2><div style={{color:"#bad5d0"}}>Book on mobile → walk the route → talk in Tunisian Arabic → follow the same action in operations.</div></div><Link className="btn" style={{background:"white",color:"#143d38"}} href="/present">Open presentation →</Link></div></div></section>
  <footer className="footer">Hani Maak · Access · Guidance · Continuity</footer>
</>}
