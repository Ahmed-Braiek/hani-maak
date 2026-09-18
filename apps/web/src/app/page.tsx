import Link from "next/link";
import {Logo} from "@/components/Logo";
import {HeniAvatar} from "@/components/HeniAvatar";

export default function Landing(){return <>
  <section className="hero competition-hero"><div className="container">
    <div className="topbar">
      <Link href="/" aria-label="Heni Maak home"><Logo/></Link>
      <div className="nav-actions">
        <Link className="btn btn-secondary" href="/present">Presentation</Link>
        <Link className="btn btn-secondary" href="/staff">Staff console</Link>
        <Link className="btn btn-primary" href="/patient">Start journey →</Link>
      </div>
    </div>

    <div className="hero-grid">
      <div className="hero-copy">
        <div className="brand-hero-badge">Access · Guidance · Continuity</div>
        <h1 className="h1">Care feels easier when the next step is always clear.</h1>
        <p><strong>Heni Maak — هاني معاك</strong> keeps the patient journey connected before, during and after a hospital visit — through mobile, voice assistance, on-site guidance and the same operational workflow for staff.</p>
        <div className="hero-ctas">
          <Link className="btn btn-primary" href="/patient">Start patient journey</Link>
          <Link className="btn btn-secondary" href="/voice-lab">Talk to Heni</Link>
          <Link className="btn btn-secondary" href="/patient/map">Open guidance</Link>
        </div>
        <div className="pill-row">
          <span className="pill">Appointments</span>
          <span className="pill">Hospital map + AR</span>
          <span className="pill">Tunisian Derja voice</span>
          <span className="pill">Follow-up journey</span>
          <span className="pill">Role-based staff console</span>
        </div>
      </div>

      <div className="hero-product-stack">
        <div className="phone-frame" aria-label="Patient app preview"><div className="phone-screen">
          <div className="status"><span>9:41</span><span>● ● ●</span></div>
          <Logo/>
          <div style={{marginTop:34}}><div className="muted tiny">Bonjour Amel</div><div style={{fontSize:"1.8rem",fontWeight:850,letterSpacing:"-.04em"}}>Je suis avec vous.</div></div>
          <div className="next-card"><div className="eyebrow">Votre prochaine étape</div><h3 style={{fontSize:"1.45rem",margin:"8px 0"}}>Préparez votre visite</h3><p style={{margin:0}}>Imagerie médicale · 09:30</p><div className="btn">Continuer le parcours →</div></div>
          <div className="mini-card"><div className="row"><strong>Parcours</strong><span className="badge good">2 / 5</span></div><div className="progress-line"><span className="dot on"/><span className="dot on"/><span className="dot"/><span className="dot"/><span className="dot"/></div></div>
          <div className="mini-card"><strong>Besoin d'aide ?</strong><p className="muted tiny">Parlez à Heni pour vos rendez-vous, votre préparation ou votre orientation.</p></div>
        </div></div>
        <div className="hero-heni-card"><HeniAvatar size={88}/><div><div className="eyebrow">Heni · هاني</div><strong>One companion, every step.</strong><p>Ask, book, prepare, find the service and continue the journey.</p></div><Link href="/voice-lab">Parlez →</Link></div>
      </div>
    </div>
  </div></section>

  <section className="section section-soft"><div className="container">
    <div className="eyebrow">One journey · multiple interfaces</div>
    <h2 className="h2">More than booking. A connected patient journey.</h2>
    <div className="grid-3">
      <article className="feature"><div className="feature-icon">◷</div><h3>Access</h3><p>Find a service, see valid availability, confirm an appointment and manage it from mobile or conversation.</p></article>
      <article className="feature"><div className="feature-icon">⌖</div><h3>Guidance</h3><p>Preparation, patient location, hospital map and camera-assisted AR guidance toward the service.</p></article>
      <article className="feature"><div className="feature-icon">✓</div><h3>Continuity</h3><p>Keep preparation, visit status, approved follow-up instructions and reminders in one understandable journey.</p></article>
    </div>
  </div></section>

  <section className="section"><div className="container">
    <div className="proof-strip">
      <div><span>01</span><strong>Patient books</strong><small>shared journey state</small></div><i>→</i>
      <div><span>02</span><strong>Heni guides</strong><small>map + AR</small></div><i>→</i>
      <div><span>03</span><strong>Voice helps</strong><small>guided actions</small></div><i>→</i>
      <div><span>04</span><strong>Staff follows</strong><small>role-aware workspace</small></div><i>→</i>
      <div><span>05</span><strong>Journey continues</strong><small>follow-up</small></div>
    </div>
    <div className="demo-band" style={{marginTop:22}}>
      <div><div className="eyebrow">Connected journey</div><h2 style={{margin:"7px 0"}}>One patient journey. One shared operational flow.</h2><div>Book on mobile → navigate the hospital → talk to Heni → continue with the care team's next steps.</div></div>
      <Link className="btn" style={{background:"white",color:"#0849b4"}} href="/present">Open presentation →</Link>
    </div>
  </div></section>

  <footer className="brand-footer"><Logo compact/><span>Access · Guidance · Continuity</span></footer>
</>}
