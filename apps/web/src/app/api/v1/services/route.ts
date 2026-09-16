import {NextResponse} from "next/server";import {readDb} from "@/lib/db";import {findService} from "@/lib/operations";
export const dynamic="force-dynamic";
export async function GET(req:Request){const db=await readDb();const url=new URL(req.url);const q=url.searchParams.get("q")?.trim();const locale=(url.searchParams.get("locale")??"fr") as any;if(q){const hit=findService(db,q,locale);return NextResponse.json({services:hit?[hit]:[]})}return NextResponse.json({services:db.services.filter(s=>s.active)});}
