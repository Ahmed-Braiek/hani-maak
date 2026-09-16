import Link from "next/link";
import {Logo} from "@/components/Logo";
import {VoiceLabClient} from "@/components/VoiceLabClient";

export default function VoiceLab(){
  return <div className="container" style={{padding:"24px 0 90px",maxWidth:1180}}>
    <div className="topbar"><Logo/><div className="nav-actions"><Link className="btn btn-secondary" href="/staff/calls">Staff trace</Link><Link className="btn btn-secondary" href="/">← Demo home</Link></div></div>
    <div style={{margin:"50px 0 24px"}}>
      <div className="eyebrow">Voice accessibility front · working local demo</div>
      <h1 className="h2" style={{marginBottom:10,maxWidth:900}}>A real conversation experience without waiting for a telephony provider.</h1>
      <p className="muted" style={{maxWidth:850,lineHeight:1.65,fontSize:"1rem"}}>Use the microphone in a compatible browser or type the same phrases. Heni speaks back using the browser, performs appointment actions through the Hani Maak server tools, and saves the conversation and tool timeline for the staff console. Clinical questions stay outside its authority.</p>
    </div>
    <VoiceLabClient/>
  </div>;
}
