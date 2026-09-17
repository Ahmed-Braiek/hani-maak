import Link from "next/link";
import {Logo} from "@/components/Logo";
import {VoiceLabClient} from "@/components/VoiceLabClient";
import "./voice-live.css";

export default function VoiceLab(){
  return <div className="voice-live-page">
    <div className="voice-live-topbar">
      <Logo/>
      <div className="voice-live-nav">
        <Link className="btn btn-secondary" href="/patient">Patient app</Link>
        <Link className="btn btn-secondary" href="/">← Home</Link>
      </div>
    </div>
    <VoiceLabClient/>
  </div>;
}
