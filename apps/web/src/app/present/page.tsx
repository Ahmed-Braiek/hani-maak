import Link from "next/link";
import {Logo} from "@/components/Logo";

const scenes=[
  ["01","Problem","Booking is only one moment. The real friction lives between access, arrival, guidance and follow-up.","/patient","Patient journey"],
  ["02","Access","Book a valid slot from deterministic scheduling rules and capacity — not from an AI-generated calendar.","/patient/services","Working booking"],
  ["03","AR walkthrough","Walk through the hospital route toward the Médecine nucléaire block while Heni speaks and a moving target guides each step.","/patient/map/ar?demo=nuclear-medicine","Route + voice"],
  ["04","Heni voice","Speak Tunisian Arabic or type. Heni performs constrained administrative actions and speaks back.","/voice-lab","Voice assistance"],
  ["05","Auditable AI","Open the staff action trace with Super Admin access already selected.","/api/v1/staff/session/launch?role=super_admin&next=/staff/calls","Action trace"],
  ["06","Continuity","Open appointment operations with Administration access, complete the visit and watch follow-up state change.","/api/v1/staff/session/launch?role=administration&next=/staff/appointments","Shared state"],
  ["07","Provider value","Open the Super Admin workspace with the correct permissions for platform, analytics and white-label controls.","/api/v1/staff/session/launch?role=super_admin&next=/staff/super-admin","B2B SaaS"],
  ["08","Persistent companion","Click Heni from the patient experience and ask for directions, preparation or administrative help.","/patient","Always available"]
];

export default function Present(){return <div className="container presentation-page" style={{padding:"24px 0 90px"}}>
  <div className="topbar presentation-topbar"><Logo/><div className="nav-actions"><Link className="btn btn-secondary" href="/">⌂ Home</Link><Link className="btn btn-secondary" href="/staff">▣ Staff</Link><Link className="btn btn-primary" href="/patient/map/ar?demo=nuclear-medicine">▶ AR guidance</Link></div></div>
  <div className="presentation-hero" style={{padding:"68px 0 28px"}}>
    <div className="eyebrow">Hani Maak · guided patient journey</div>
    <h1 className="h1" style={{fontSize:"clamp(2.8rem,7vw,5.2rem)",maxWidth:1050}}>One patient story. Eight proof points.</h1>
    <p className="muted" style={{fontSize:"1.08rem",maxWidth:800,lineHeight:1.7}}>Open each surface in sequence: booking → AR walk → Heni voice → staff trace → continuity.</p>
  </div>

  <div className="grid-3 presentation-grid">{scenes.map(([n,title,body,href,proof])=><Link href={href} key={n} className={`feature presentation-card ${n==="03"?"presentation-card-featured":""}`}>
    <div className="row"><div className="eyebrow">Scene {n}</div><span className="badge">{proof}</span></div>
    <h2>{title}</h2><p>{body}</p><div className="presentation-open">Open working surface <span>↗</span></div>
  </Link>)}</div>

  <div className="demo-band" style={{marginTop:28}}><div><div className="eyebrow" style={{color:"#8de0d3"}}>Closing line</div><h2 style={{maxWidth:940,margin:"6px 0"}}>“Hani Maak is not an appointment app. It is the layer that stays with the patient from access to guidance to continuity.”</h2></div><Link className="btn" style={{background:"white",color:"#143d38"}} href="/">⌂ Home</Link></div>
</div>}
