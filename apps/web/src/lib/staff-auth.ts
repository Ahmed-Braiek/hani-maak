import {createHmac,timingSafeEqual} from "node:crypto";
import {cookies} from "next/headers";
import {hasPermission,type Permission,type StaffIdentity,type StaffRole} from "./access";
import {DEMO_STAFF_ACCOUNTS,findDemoAccount} from "./staff-demo-accounts";

const COOKIE_NAME="hani_staff_session";
const SESSION_SECONDS=60*60*8;

type StaffSessionPayload={
  v:1;
  role:StaffRole;
  username:string;
  exp:number;
};

function secureEqual(a:string,b:string){
  const left=Buffer.from(a,"utf8"),right=Buffer.from(b,"utf8");
  return left.length===right.length&&timingSafeEqual(left,right);
}

export function validStaffRole(value:string|null|undefined):value is StaffRole{
  return value==="doctor"||value==="administration"||value==="super_admin";
}

export function staffSessionCookie(){return COOKIE_NAME}

export function staffSessionCookieOptions(){
  return {httpOnly:true,sameSite:"lax" as const,secure:process.env.NODE_ENV==="production",path:"/",maxAge:SESSION_SECONDS};
}

export function staffSessionSecret(){
  const configured=process.env.HANI_STAFF_SESSION_SECRET?.trim()||process.env.HENI_AGENT_SHARED_SECRET?.trim();
  if(configured)return configured;
  // Public competition credentials are intentionally demo-only. Real deployments must configure a secret.
  if(process.env.DEMO_MODE==="true"||process.env.NODE_ENV!=="production")return "hani-maak-competition-demo-session-v1";
  return undefined;
}

function encode(payload:StaffSessionPayload){
  return Buffer.from(JSON.stringify(payload),"utf8").toString("base64url");
}

function sign(encoded:string,secret:string){
  return createHmac("sha256",secret).update(encoded).digest("base64url");
}

function issueToken(role:StaffRole,username:string){
  const secret=staffSessionSecret();
  if(!secret)throw new Error("Staff authentication is not configured.");
  const payload:StaffSessionPayload={v:1,role,username,exp:Math.floor(Date.now()/1000)+SESSION_SECONDS};
  const encoded=encode(payload);
  return `${encoded}.${sign(encoded,secret)}`;
}

function verifyToken(token:string|undefined){
  const secret=staffSessionSecret();
  if(!secret||!token)return undefined;
  try{
    const [encoded,supplied]=token.split(".");
    if(!encoded||!supplied||!secureEqual(sign(encoded,secret),supplied))return undefined;
    const payload=JSON.parse(Buffer.from(encoded,"base64url").toString("utf8")) as StaffSessionPayload;
    if(payload.v!==1||!validStaffRole(payload.role)||!payload.username||payload.exp<=Math.floor(Date.now()/1000))return undefined;
    return payload;
  }catch{return undefined}
}

export function roleIdentity(role:StaffRole):StaffIdentity{
  const account=DEMO_STAFF_ACCOUNTS[role];
  return {id:`staff-${role}-demo`,name:account.name,role,department:account.department};
}

export function authenticateDemoStaff(role:unknown,username:string,password:string){
  if(typeof role!=="string"||!validStaffRole(role))return undefined;
  const account=findDemoAccount(role,username);
  if(!account||!secureEqual(account.password,password))return undefined;
  return {identity:roleIdentity(role),token:issueToken(role,account.username)};
}

export function signStaffRole(role:StaffRole){
  const account=DEMO_STAFF_ACCOUNTS[role];
  return issueToken(role,account.username);
}

export async function getStaffIdentity():Promise<StaffIdentity|undefined>{
  const store=await cookies();
  const payload=verifyToken(store.get(COOKIE_NAME)?.value);
  return payload?roleIdentity(payload.role):undefined;
}

export async function requireStaff(){
  const identity=await getStaffIdentity();
  if(!identity)throw Object.assign(new Error("UNAUTHORIZED"),{status:401});
  return identity;
}

export async function requirePermission(permission:Permission){
  const identity=await requireStaff();
  if(!hasPermission(identity,permission))throw Object.assign(new Error("FORBIDDEN"),{status:403});
  return identity;
}

export async function requireRole(role:StaffRole){
  const identity=await requireStaff();
  if(identity.role!==role)throw Object.assign(new Error("FORBIDDEN"),{status:403});
  return identity;
}
