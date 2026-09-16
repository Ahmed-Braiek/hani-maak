import {NextResponse} from "next/server";import {readDb} from "@/lib/db";
export const dynamic="force-dynamic";
export async function GET(_:Request,{params}:{params:Promise<{id:string}>}){const {id}=await params;const db=await readDb();const appointment=db.appointments.find(a=>a.id===id);if(!appointment)return NextResponse.json({error:"Not found"},{status:404});return NextResponse.json({appointment,journey:db.journeys.find(j=>j.appointmentId===id)});}
