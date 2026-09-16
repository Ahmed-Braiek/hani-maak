export interface VisionExtraction {
  detectedName?: string;
  detectedStrengthText?: string;
  expiryText?: string;
  expiryDateISO?: string;
  lotText?: string;
  otherVisibleText?: string[];
  confidenceNotes: string[];
}

function outputText(body:any):string{
  if(typeof body.output_text==="string") return body.output_text;
  for(const item of body.output??[]) for(const c of item.content??[]) if(typeof c.text==="string") return c.text;
  return "";
}

export async function extractMedicinePackage(imageDataUrl:string):Promise<VisionExtraction>{
  const key=process.env.OPENAI_API_KEY; if(!key) throw new Error("OPENAI_API_KEY is not configured");
  if(!/^data:image\/(png|jpeg|jpg|webp);base64,/i.test(imageDataUrl)) throw new Error("Unsupported image data");
  const model=process.env.OPENAI_VISION_MODEL||"gpt-5.6-terra";
  const schema={type:"object",properties:{detectedName:{type:["string","null"]},detectedStrengthText:{type:["string","null"]},expiryText:{type:["string","null"]},expiryDateISO:{type:["string","null"]},lotText:{type:["string","null"]},otherVisibleText:{type:"array",items:{type:"string"}},confidenceNotes:{type:"array",items:{type:"string"}}},required:["detectedName","detectedStrengthText","expiryText","expiryDateISO","lotText","otherVisibleText","confidenceNotes"],additionalProperties:false};
  const r=await fetch("https://api.openai.com/v1/responses",{method:"POST",headers:{authorization:`Bearer ${key}`,"content-type":"application/json"},body:JSON.stringify({model,store:false,instructions:"Extract only text visibly present on the medicine package. Do not diagnose, infer dosage instructions, recommend use, or decide medication safety. Use null when a field is not clearly visible. For expiryDateISO, only convert a clearly visible date; otherwise null. Include uncertainty in confidenceNotes.",input:[{role:"user",content:[{type:"input_text",text:"Extract visible package information only."},{type:"input_image",image_url:imageDataUrl,detail:"high"}]}],text:{format:{type:"json_schema",name:"medicine_package_visible_text",strict:true,schema}}})});
  const body=await r.json(); if(!r.ok) throw new Error(body?.error?.message||`Vision provider HTTP ${r.status}`);
  const raw=outputText(body); if(!raw) throw new Error("Vision provider returned no structured text");
  const parsed=JSON.parse(raw); return {detectedName:parsed.detectedName??undefined,detectedStrengthText:parsed.detectedStrengthText??undefined,expiryText:parsed.expiryText??undefined,expiryDateISO:parsed.expiryDateISO??undefined,lotText:parsed.lotText??undefined,otherVisibleText:parsed.otherVisibleText??[],confidenceNotes:parsed.confidenceNotes??[]};
}
