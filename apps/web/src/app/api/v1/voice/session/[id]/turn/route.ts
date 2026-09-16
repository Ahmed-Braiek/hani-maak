import {NextResponse} from "next/server";
import {recordCallExchange,voiceTurn} from "@/lib/operations";

export async function POST(req:Request,{params}:{params:Promise<{id:string}>}){
  try{
    const {id}=await params;
    const b=await req.json();
    const text=String(b.text??"");
    const result=await voiceTurn(id,text);
    await recordCallExchange(id,text,String(result.message??""));
    return NextResponse.json(result);
  }catch(e:any){
    return NextResponse.json({error:e.message},{status:400});
  }
}
