import {NextResponse} from "next/server";import {readDb} from "@/lib/db";
export const dynamic="force-dynamic";
export async function GET(_:Request,{params}:{params:Promise<{id:string}>}){const {id}=await params;const db=await readDb();const service=db.services.find(s=>s.id===id&&s.active);if(!service)return NextResponse.json({error:"Service not found"},{status:404});const preparation=db.contentTemplates.find(c=>c.id===service.preparationTemplateId&&c.published);return NextResponse.json({service,preparation});}
