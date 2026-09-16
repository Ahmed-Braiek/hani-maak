import Link from "next/link";
import {Logo} from "@/components/Logo";

const scenes=[
  ["01","Problem","Booking is only one moment. The real friction lives between access, arrival, guidance and follow-up.","/patient","Patient journey"],
  ["02","Access","Book a valid slot from deterministic scheduling rules and capacity — not from an AI-generated calendar.","/patient/services","Working booking"],
  ["03","Guidance + AR","Use the Charles Nicolle reference context, deterministic indoor prototype route and camera-overlay guidance.","/patient/map","Route + camera"],
  ["04","Heni voice","Speak Tunisian Arabic or type. Heni performs constrained administrative actions and speaks back.","/voice-lab","Local voice demo"],
  ["05","Auditable AI","Open the staff trace and show the saved conversation, tools, arguments, result and safety escalation.","/staff/calls","MCP/tool proof"],
  ["06","Continuity","Complete the visit from staff operations and watch the patient journey move into follow-up.","/staff/appointments","Shared state"],
  ["07","Provider value","Show operations, analytics and white-label configuration — one backend across every patient channel.","/staff","B2B SaaS"],
  ["08","Persistent companion","Click Heni in the bottom-right from any screen and ask for directions, preparation or administrative help.","/patient","Always available"]
];

export default function Present(){return <div className="container" style={{padding:"24px 0 90px"}}>
  <div className="topbar"><Logo/><div className="nav-actions"><Link className="btn btn-secondary" href="/voice-lab">Voice proof</Link><Link className="btn btn-secondary" href="/">← Home</Link></div></div>
  <div style={{padding:"68px 0 28px"}}>
    <div className="eyebrow">Presentation mode · national competition</div>
    <h1 className="h1" style={{fontSize:"clamp(2.8rem,7vw,5.2rem)",maxWidth:1050}}>One patient story. Eight proof points.</h1>
    <p className="muted" style={{fontSize:"1.08rem",maxWidth:800,lineHeight:1.7}}>Every card links to a working surface. The strongest sequence is access → route → AR → voice → staff trace → continuity. Keep the story simple and let the live state prove the engineering.</p>
  </div>

  <div className="grid-3 presentation-grid">{scenes.map(([n,title,body,href,proof])=><Link href={href} key={n} className="feature presentation-card">
    <div className="row"><div className="eyebrow">Scene {n}</div><span className="badge">{proof}</span></div>
    <h2>{title}</h2><p>{body}</p><div className="presentation-open">Open working surface <span>↗</span></div>
  </Link>)}</div>

  <div className="demo-band" style={{marginTop:28}}><div><div className="eyebrow" style={{color:"#8de0d3"}}>Closing line</div><h2 style={{maxWidth:940,margin:"6px 0"}}>“Hani Maak is not an appointment app. It is the layer that stays with the patient from access to guidance to continuity.”</h2></div></div>

  <div className="notice info" style={{marginTop:18}}><strong>Truthfulness note for the jury:</strong> the hospital reference location is real; the indoor route geometry and schedules are competition demo data and are visibly marked as such. The AR layer demonstrates the interaction architecture, not validated indoor positioning.</div>
</div>}
