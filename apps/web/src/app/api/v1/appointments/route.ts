import {NextResponse} from "next/server";
import {createAppointment} from "@/lib/operations";
import {readDb} from "@/lib/db";

export const dynamic="force-dynamic";

export async function GET(){
  try{
    const db=await readDb();
    return NextResponse.json({appointments:db.appointments});
  }catch(error){
    console.error("appointments.GET failed",error);
    return NextResponse.json({error:"appointments_unavailable"},{status:503});
  }
}

export async function POST(req:Request){
  try{
    const body=await req.json().catch(()=>null);
    if(!body?.serviceId||!body?.startAt)return NextResponse.json({error:"invalid_request"},{status:400});
    const appointment=await createAppointment({...body,channel:body.channel??"app"});
    return NextResponse.json({appointment},{status:201});
  }catch(error){
    console.error("appointments.POST failed",error);
    const message=error instanceof Error?error.message:"";
    const storageUnavailable=message.includes("Persistent storage")||message.includes("Supabase backend selected");
    return NextResponse.json({error:storageUnavailable?"persistent_storage_unavailable":"appointment_conflict"},{status:storageUnavailable?503:409});
  }
}
