import type {StaffRole} from "./access";

export type DemoStaffAccount={
  role:StaffRole;
  username:string;
  password:string;
  name:string;
  department:string;
};

/**
 * Competition-only credentials.
 * They are intentionally public and MUST NOT be reused for a real hospital deployment.
 * Production deployments should replace this module with the hospital identity provider.
 */
export const DEMO_STAFF_ACCOUNTS:Record<StaffRole,DemoStaffAccount>={
  doctor:{
    role:"doctor",
    username:"doctor.demo",
    password:"HaniDoctor2026!",
    name:"Dr. Leila Mansouri",
    department:"Imagerie"
  },
  administration:{
    role:"administration",
    username:"admin.demo",
    password:"HaniAdmin2026!",
    name:"Salma Ben Amor",
    department:"Admissions"
  },
  super_admin:{
    role:"super_admin",
    username:"super.demo",
    password:"HaniSuper2026!",
    name:"Hani Maak Platform",
    department:"Platform"
  }
};

export function findDemoAccount(role:StaffRole,username:string){
  const account=DEMO_STAFF_ACCOUNTS[role];
  return account.username.toLowerCase()===username.trim().toLowerCase()?account:undefined;
}
