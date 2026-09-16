import {NextResponse} from "next/server";import {readDb} from "@/lib/db";
export const dynamic="force-dynamic";
export async function GET(_:Request,{params}:{params:Promise<{id:string}>}){const {id}=await params;const db=await readDb();const journey=db.journeys.find(j=>j.id===id);return journey?NextResponse.json({journey}):NextResponse.json({error:"Not found"},{status:404});}
