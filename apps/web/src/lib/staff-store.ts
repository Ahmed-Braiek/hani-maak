import type {Permission,StaffRole} from "./access";
export type PlatformStaffAccount={id:string;name:string;email:string;role:StaffRole;department:string;active:boolean;lastLogin?:string;createdAt:string;permissionOverrides?:Partial<Record<Permission,boolean>>};
export const defaultStaffAccounts:PlatformStaffAccount[]=[
{id:"acct-doctor",name:"Dr. Leila Mansouri",email:"leila.mansouri@example.demo",role:"doctor",department:"Imagerie",active:true,lastLogin:new Date().toISOString(),createdAt:"2026-09-12T08:00:00Z"},
{id:"acct-admin",name:"Salma Ben Amor",email:"salma.benamor@example.demo",role:"administration",department:"Admissions",active:true,lastLogin:new Date().toISOString(),createdAt:"2026-09-10T08:00:00Z"},
{id:"acct-super",name:"Hani Maak Platform",email:"platform@example.demo",role:"super_admin",department:"Platform",active:true,lastLogin:new Date().toISOString(),createdAt:"2026-09-01T08:00:00Z"}
];
export function getPlatformAccounts(db:any):PlatformStaffAccount[]{return Array.isArray(db.platformStaffAccounts)?db.platformStaffAccounts:defaultStaffAccounts.map(x=>({...x}))}
export function ensurePlatformAccounts(db:any):PlatformStaffAccount[]{if(!Array.isArray(db.platformStaffAccounts))db.platformStaffAccounts=defaultStaffAccounts.map(x=>({...x}));return db.platformStaffAccounts}
