import {NextResponse} from "next/server";import {routeTo} from "@/lib/operations";
export const dynamic="force-dynamic";
export async function GET(req:Request){try{const u=new URL(req.url);const serviceId=u.searchParams.get("serviceId")??"svc-imaging";const from=u.searchParams.get("from")??"node-main-gate";const accessible=u.searchParams.get("accessible")!=="false";return NextResponse.json(await routeTo(serviceId,from,accessible))}catch(e:any){return NextResponse.json({error:e.message},{status:400})}}
