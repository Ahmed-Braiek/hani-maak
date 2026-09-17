export type ClinicalNote={id:string;authorId:string;authorName:string;text:string;createdAt:string};export type ClinicalRecord={patientId:string;history:string[];notes:ClinicalNote[]};
export function ensureClinicalRecords(db:any):ClinicalRecord[]{if(!Array.isArray(db.clinicalRecords))db.clinicalRecords=[];return db.clinicalRecords}
export function getClinicalRecord(db:any,patientId:string):ClinicalRecord{const records=Array.isArray(db.clinicalRecords)?db.clinicalRecords:[];return records.find((r:ClinicalRecord)=>r.patientId===patientId)??{patientId,history:[],notes:[]}}
