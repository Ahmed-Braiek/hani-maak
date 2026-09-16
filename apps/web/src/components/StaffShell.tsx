import Link from "next/link";
import {Logo} from "./Logo";

const links=[
  ["/staff","Overview","⌂"],
  ["/staff/appointments","Appointments","◷"],
  ["/staff/calls","Calls & AI agent","◉"],
  ["/staff/patients","Patients","♙"],
  ["/staff/journeys","Journeys / follow-up","✓"],
  ["/staff/services","Services & schedules","▦"],
  ["/staff/map","Navigation map","⌖"],
  ["/staff/content","Content & instructions","≡"],
  ["/staff/analytics","Analytics","⌁"],
  ["/staff/settings","Settings","⚙"]
];

export function StaffShell({children}:{children:React.ReactNode}){
  return <div className="app-shell">
    <aside className="sidebar">
      <Logo/>
      <div className="staff-mode-chip"><span/> DEMO OPERATIONS</div>
      <nav className="side-nav">{links.map(([href,label,icon])=><Link key={href} className="side-link" href={href}><span>{icon}</span>{label}</Link>)}</nav>
      <div className="sidebar-proof"><strong>Shared patient state</strong><small>Mobile · Heni · voice · staff</small></div>
      <div className="sidebar-foot">Hani Maak competition tenant<br/>Synthetic data · demo mode</div>
    </aside>
    <main className="main">
      <div className="staff-mobile-head"><Logo compact/><div><span className="map-live-dot"/> Demo operations</div></div>
      {children}
    </main>
  </div>
}
