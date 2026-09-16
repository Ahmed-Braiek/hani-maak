import {NextResponse} from "next/server";import {acknowledgeStep} from "@/lib/operations";
export async function POST(_:Request,{params}:{params:Promise<{id:string}>}){try{const {id}=await params;return NextResponse.json({step:await acknowledgeStep(id)})}catch(e:any){return NextResponse.json({error:e.message},{status:400})}}
