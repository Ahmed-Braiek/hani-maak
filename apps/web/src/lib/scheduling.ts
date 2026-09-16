import type { Appointment, DemoDb, ScheduleRule } from "./types";

export interface Slot { startAt:string; endAt:string; remaining:number; capacity:number; label:string; }
const mins = (t:string) => { const [h,m]=t.split(":").map(Number); return h*60+m; };
const hhmm = (m:number) => `${String(Math.floor(m/60)).padStart(2,"0")}:${String(m%60).padStart(2,"0")}`;
const isoTunis = (date:string,time:string) => new Date(`${date}T${time}:00+01:00`).toISOString();
const ymd = (d:Date) => d.toISOString().slice(0,10);
export function tunisDateString(d:Date){
  const parts=new Intl.DateTimeFormat("en",{timeZone:"Africa/Tunis",year:"numeric",month:"2-digit",day:"2-digit"}).formatToParts(d);
  const get=(type:string)=>parts.find(p=>p.type===type)?.value??"";
  return `${get("year")}-${get("month")}-${get("day")}`;
}


function ruleSlots(rule:ScheduleRule,date:string, duration:number) {
  const out:{start:string;end:string}[]=[];
  for(let m=mins(rule.startTime); m+duration<=mins(rule.endTime); m+=duration) out.push({start:hhmm(m),end:hhmm(m+duration)});
  return out.map(x=>({startAt:isoTunis(date,x.start),endAt:isoTunis(date,x.end)}));
}

export function getAvailableSlots(db:DemoDb, serviceId:string, fromDate:string, toDate:string, preferredPeriod?:"morning"|"afternoon", limit=12):Slot[] {
  const service=db.services.find(s=>s.id===serviceId && s.active); if(!service) return [];
  const out:Slot[]=[]; const from=new Date(`${fromDate}T12:00:00Z`); const to=new Date(`${toDate}T12:00:00Z`);
  for(let day=new Date(from); day<=to; day.setUTCDate(day.getUTCDate()+1)) {
    const date=ymd(day); const dow=day.getUTCDay();
    for(const rule of db.scheduleRules.filter(r=>r.serviceId===serviceId && r.dayOfWeek===dow)) {
      const period=mins(rule.startTime)<12*60?"morning":"afternoon"; if(preferredPeriod && preferredPeriod!==period) continue;
      const ex=db.scheduleExceptions.find(e=>e.serviceId===serviceId && e.date===date && e.closed && (!e.startTime || rule.startTime>=e.startTime) && (!e.endTime || rule.startTime<e.endTime));
      if(ex) continue;
      const capacity=db.scheduleExceptions.find(e=>e.serviceId===serviceId&&e.date===date&&e.capacityOverride!=null)?.capacityOverride ?? rule.capacity;
      for(const s of ruleSlots(rule,date,rule.slotDurationMin ?? service.slotDurationMin)) {
        if(new Date(s.startAt).getTime()<=Date.now()-60_000) continue;
        const used=db.appointments.filter(a=>a.serviceId===serviceId&&a.startAt===s.startAt&&["confirmed","requested"].includes(a.state)).length;
        if(used<capacity) out.push({...s,remaining:capacity-used,capacity,label:new Intl.DateTimeFormat("fr-TN",{weekday:"short",day:"2-digit",month:"short",hour:"2-digit",minute:"2-digit",timeZone:"Africa/Tunis"}).format(new Date(s.startAt))});
      }
    }
  }
  return out.sort((a,b)=>a.startAt.localeCompare(b.startAt)).slice(0,limit);
}

export function assertSlotAvailable(db:DemoDb, serviceId:string, startAt:string){
  const date=tunisDateString(new Date(startAt));
  const slots=getAvailableSlots(db,serviceId,date,date,undefined,200);
  const hit=slots.find(s=>s.startAt===startAt); if(!hit) throw new Error("This slot is no longer available. Please choose another time."); return hit;
}

export function appointmentEnd(db:DemoDb, serviceId:string, startAt:string){ const service=db.services.find(s=>s.id===serviceId); if(!service) throw new Error("Unknown service"); return new Date(new Date(startAt).getTime()+service.slotDurationMin*60_000).toISOString(); }
export function activeAppointments(rows:Appointment[]){return rows.filter(a=>a.state==="confirmed"||a.state==="requested");}
