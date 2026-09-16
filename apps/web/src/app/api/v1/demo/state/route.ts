import {NextResponse} from "next/server";import {readDb} from "@/lib/db";export const dynamic="force-dynamic";export async function GET(){return NextResponse.json(await readDb())}
