import {NextResponse} from "next/server";
import {newVoiceSession} from "@/lib/operations";

export async function POST(req:Request){
  const b=await req.json().catch(()=>({}));
  return NextResponse.json(
    await newVoiceSession(b.locale??"ar",b.patientId??"patient-hedi",String(b.source??"voice_lab")),
    {status:201}
  );
}
