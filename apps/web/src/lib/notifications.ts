export interface NotificationMessage { to:string; body:string; subject?:string; }
export interface NotificationResult { externalId?:string; state:"sent"|"simulated"|"failed"; error?:string; }
export interface NotificationProvider { send(message:NotificationMessage):Promise<NotificationResult>; }

export class InAppProvider implements NotificationProvider { async send(){ return {state:"sent" as const,externalId:`inapp-${Date.now()}`}; } }
export class SimulatedSmsProvider implements NotificationProvider { async send(){ return {state:"simulated" as const,externalId:`sim-sms-${Date.now()}`}; } }
export class TwilioSmsProvider implements NotificationProvider {
  async send(message:NotificationMessage):Promise<NotificationResult>{
    const sid=process.env.TWILIO_ACCOUNT_SID, token=process.env.TWILIO_AUTH_TOKEN, from=process.env.TWILIO_SMS_FROM;
    if(!sid||!token||!from||process.env.ENABLE_EXTERNAL_NOTIFICATIONS!=="true") return {state:"simulated",externalId:`sim-sms-${Date.now()}`};
    try{const body=new URLSearchParams({To:message.to,From:from,Body:message.body});const r=await fetch(`https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`,{method:"POST",headers:{authorization:`Basic ${Buffer.from(`${sid}:${token}`).toString("base64")}`,"content-type":"application/x-www-form-urlencoded"},body});const x=await r.json();if(!r.ok)return{state:"failed",error:x.message||`HTTP ${r.status}`};return{state:"sent",externalId:x.sid};}catch(e:any){return{state:"failed",error:e.message}}
  }
}
export class ResendEmailProvider implements NotificationProvider {
  async send(message:NotificationMessage):Promise<NotificationResult>{const key=process.env.RESEND_API_KEY,from=process.env.RESEND_FROM;if(!key||!from||process.env.ENABLE_EXTERNAL_NOTIFICATIONS!=="true")return{state:"simulated",externalId:`sim-email-${Date.now()}`};try{const r=await fetch("https://api.resend.com/emails",{method:"POST",headers:{authorization:`Bearer ${key}`,"content-type":"application/json"},body:JSON.stringify({from,to:[message.to],subject:message.subject||"Hani Maak reminder",text:message.body})});const x=await r.json();if(!r.ok)return{state:"failed",error:x.message||`HTTP ${r.status}`};return{state:"sent",externalId:x.id};}catch(e:any){return{state:"failed",error:e.message}}}
}
