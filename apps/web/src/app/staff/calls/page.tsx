import {StaffShell} from "@/components/StaffShell";
import {staffSnapshot} from "@/lib/operations";
import {Badge} from "@/components/Badge";

export const dynamic="force-dynamic";

type TranscriptItem={role?:string;text?:string;at?:string};

export default async function Calls(){
  const x=await staffSnapshot();
  return <StaffShell>
    <div className="page-head">
      <div>
        <div className="eyebrow">Voice & AI</div>
        <h1>Calls, conversations and tool activity</h1>
        <div className="muted">Every demo conversation uses the same scheduling and journey engine. State-changing actions are traceable.</div>
      </div>
      <a className="btn btn-primary" href="/voice-lab">Run voice lab</a>
    </div>

    <div className="voice-admin-summary">
      <div className="card metric"><div className="value">{x.calls.length}</div><div className="label">demo sessions</div></div>
      <div className="card metric"><div className="value">{x.toolEvents.length}</div><div className="label">recorded tool calls</div></div>
      <div className="card metric"><div className="value">{x.calls.filter(c=>c.outcome==="escalated").length}</div><div className="label">human escalations</div></div>
    </div>

    <div className="stack">
      {x.calls.map(c=>{
        const p=x.patients.find(v=>v.id===c.patientId);
        const tools=x.toolEvents.filter(t=>t.callSessionId===c.id).sort((a,b)=>a.createdAt.localeCompare(b.createdAt));
        const transcript=(Array.isArray((c.context as any)?.transcript)?(c.context as any).transcript:[]) as TranscriptItem[];
        const source=String((c.context as any)?.source??(c.externalCallId?"phone":"demo"));
        return <section className="card call-review" key={c.id}>
          <div className="row call-review-head">
            <div>
              <div className="eyebrow">{p?`${p.firstName} ${p.lastName}`:c.caller}</div>
              <h3 style={{marginTop:5}}>{c.summary??"Active Hani conversation"}</h3>
              <div className="muted tiny">{new Intl.DateTimeFormat("fr-TN",{dateStyle:"medium",timeStyle:"medium",timeZone:"Africa/Tunis"}).format(new Date(c.startedAt))} · {c.locale.toUpperCase()} · {source} · state {c.state}</div>
            </div>
            <Badge tone={c.outcome==="completed"?"good":c.outcome==="escalated"?"warn":"info"}>{c.outcome}</Badge>
          </div>

          <div className="call-review-grid">
            <div>
              <div className="eyebrow">Conversation saved for demo</div>
              {transcript.length?<div className="staff-transcript">
                {transcript.map((m,i)=><div key={i} className={`staff-transcript-line ${m.role==="user"?"user":"assistant"}`}>
                  <strong>{m.role==="user"?"Patient":"Heni"}</strong>
                  <span>{m.text}</span>
                </div>)}
              </div>:<div className="empty compact">No transcript retained for this seeded session. Tool activity remains available.</div>}
            </div>

            <div>
              <div className="eyebrow">MCP / tool timeline</div>
              {tools.length>0?<div className="staff-tool-list">{tools.map(t=><div className="staff-tool-row" key={t.id}>
                <span className={`badge ${t.status==="success"?"good":"danger"}`}>{t.status}</span>
                <div style={{minWidth:0}}>
                  <strong className="code">{t.toolName}</strong>
                  <div className="muted tiny" style={{marginTop:5,wordBreak:"break-word"}}>args {JSON.stringify(t.arguments)}</div>
                  <div className="muted tiny" style={{wordBreak:"break-word"}}>result {JSON.stringify(t.result)} · {t.latencyMs} ms</div>
                </div>
              </div>)}</div>:<div className="empty compact">No tool action yet.</div>}
            </div>
          </div>
        </section>
      })}
    </div>
  </StaffShell>
}
