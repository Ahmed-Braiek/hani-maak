import {NextResponse} from "next/server";import {createAppointment} from "@/lib/operations";import {readDb} from "@/lib/db";
export const dynamic="force-dynamic";
export async function GET(){const db=await readDb();return NextResponse.json({appointments:db.appointments});}
export async function POST(req:Request){try{const body=await req.json();if(!body.serviceId||!body.startAt)return NextResponse.json({error:"serviceId and startAt are required"},{status:400});const appointment=await createAppointment({...body,channel:body.channel??"app"});return NextResponse.json({appointment},{status:201})}catch(e:any){return NextResponse.json({error:e.message},{status:409})}}
