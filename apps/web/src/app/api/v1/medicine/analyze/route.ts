import {NextResponse} from "next/server";
import {medicineAnalyze,updateMedicineExtraction} from "@/lib/operations";
import {extractMedicinePackage} from "@/lib/vision";
import type {MedicineSession} from "@/lib/types";

export async function POST(req:Request){
  try{
    const b=await req.json();
    if(!b.fileName)return NextResponse.json({error:"fileName required"},{status:400});

    const base=await medicineAnalyze(b.patientId??"patient-amal",b.fileName);
    let session:MedicineSession=base.session;
    let providerUsed=false;
    let providerError:string|undefined;

    if(b.imageDataUrl&&process.env.OPENAI_API_KEY){
      try{
        const extracted=await extractMedicinePackage(b.imageDataUrl);
        session=await updateMedicineExtraction(session.id,extracted);
        providerUsed=true;
      }catch(e:any){
        providerError=e.message;
      }
    }

    const expiry=session.extracted.expiryDateISO;
    const expired=expiry?new Date(`${expiry}T23:59:59Z`)<new Date():false;
    return NextResponse.json({...base,session,expired,providerUsed,providerError});
  }catch(e:any){
    return NextResponse.json({error:e.message},{status:400});
  }
}
