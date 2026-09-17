import { promises as fs } from "node:fs";
import path from "node:path";
import type { DemoDb } from "./types";
import { createSeedDb } from "./seed";

const dataPath = path.join(process.cwd(), "data", "demo-db.json");
const stateId = process.env.HANI_SUPABASE_STATE_ID || "competition-singleton";
let queue: Promise<unknown> = Promise.resolve();

const configuredBackend = (process.env.HANI_DATA_BACKEND || "auto").toLowerCase();
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL?.replace(/\/$/, "");
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const isVercel = Boolean(process.env.VERCEL || process.env.VERCEL_ENV);

function canUseSupabase(){return Boolean(supabaseUrl&&supabaseKey)}
function persistentStorageError(){return new Error("Persistent storage is not configured for this deployment. Configure NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.")}
function selectedBackend():"file"|"supabase"{if(configuredBackend==="supabase")return"supabase";if(configuredBackend==="file"&&!isVercel)return"file";if(canUseSupabase())return"supabase";return"file"}

async function ensureFileDb(){try{await fs.access(dataPath)}catch{await fs.mkdir(path.dirname(dataPath),{recursive:true});await fs.writeFile(dataPath,JSON.stringify(createSeedDb(),null,2),"utf8")}}
async function readFileDb():Promise<DemoDb>{if(isVercel){try{return JSON.parse(await fs.readFile(dataPath,"utf8")) as DemoDb}catch{return createSeedDb()}}await ensureFileDb();return JSON.parse(await fs.readFile(dataPath,"utf8")) as DemoDb}
async function writeFileDb(db:DemoDb){if(isVercel)throw persistentStorageError();db.meta.revision+=1;const tmp=`${dataPath}.tmp`;await fs.mkdir(path.dirname(dataPath),{recursive:true});await fs.writeFile(tmp,JSON.stringify(db,null,2),"utf8");await fs.rename(tmp,dataPath)}
function supabaseHeaders(extra:Record<string,string>={}){if(!supabaseKey)throw persistentStorageError();return{apikey:supabaseKey,Authorization:`Bearer ${supabaseKey}`,"Content-Type":"application/json",...extra}}
async function supabaseRequest(pathname:string,init:RequestInit={}){if(!supabaseUrl||!supabaseKey)throw persistentStorageError();const response=await fetch(`${supabaseUrl}/rest/v1/${pathname}`,{...init,headers:{...supabaseHeaders(),...(init.headers as Record<string,string>|undefined)},cache:"no-store"});if(!response.ok){const detail=await response.text().catch(()=>"");throw new Error(`Persistent storage request failed (${response.status}): ${detail||response.statusText}`)}return response}
async function readSupabaseDb():Promise<DemoDb>{const encoded=encodeURIComponent(stateId);const response=await supabaseRequest(`hani_demo_state?select=payload&id=eq.${encoded}&limit=1`);const rows=(await response.json()) as Array<{payload:DemoDb}>;if(rows[0]?.payload)return rows[0].payload;const seed=createSeedDb();await writeSupabaseDb(seed,false);return seed}
async function writeSupabaseDb(db:DemoDb,bumpRevision=true){if(bumpRevision)db.meta.revision+=1;await supabaseRequest("hani_demo_state?on_conflict=id",{method:"POST",headers:{Prefer:"resolution=merge-duplicates,return=minimal"},body:JSON.stringify({id:stateId,payload:db,revision:db.meta.revision,updated_at:new Date().toISOString()})})}
export function getDataBackendStatus(){const backend=selectedBackend();return{backend,configuredBackend,supabaseConfigured:canUseSupabase(),stateId:backend==="supabase"?stateId:undefined,vercel:isVercel,persistentWrites:backend==="supabase"||!isVercel}}
export async function readDb():Promise<DemoDb>{return selectedBackend()==="supabase"?readSupabaseDb():readFileDb()}
async function writeDb(db:DemoDb){return selectedBackend()==="supabase"?writeSupabaseDb(db):writeFileDb(db)}
export async function mutateDb<T>(fn:(db:DemoDb)=>T|Promise<T>):Promise<T>{if(isVercel&&selectedBackend()!=="supabase")throw persistentStorageError();const task=queue.then(async()=>{const db=await readDb();const result=await fn(db);await writeDb(db);return result});queue=task.catch(()=>undefined);return task as Promise<T>}
export async function resetDb(){const db=createSeedDb();if(selectedBackend()==="supabase")await writeSupabaseDb(db,false);else{if(isVercel)throw persistentStorageError();await fs.mkdir(path.dirname(dataPath),{recursive:true});await fs.writeFile(dataPath,JSON.stringify(db,null,2),"utf8")}return db}
