"use client";
import Link from "next/link";
import {usePathname} from "next/navigation";
import {Logo} from "./Logo";
import {LocaleSwitcher} from "./LocaleSwitcher";
import {usePersistentLocale} from "@/lib/locale-client";
import {t} from "@/lib/i18n";
import {hasPermission,type Permission,type StaffIdentity,type StaffRole} from "@/lib/access";

const demoIdentity:Record<StaffRole,StaffIdentity>={
  doctor:{id:"staff-doctor-demo",name:"Dr. Leila Mansouri",role:"doctor",department:"Imagerie"},
  administration:{id:"staff-admin-demo",name:"Salma Ben Amor",role:"administration",department:"Admissions"},
  super_admin:{id:"staff-super-demo",name:"Hani Maak Platform",role:"super_admin",department:"Platform"}
};

const links:{href:string;key:string;icon:string;permission?:Permission;roles?:StaffRole[]}[]=[
  {href:"/staff",key:"nav.overview",icon:"⌂"},
  {href:"/staff/doctor",key:"roles.doctor",icon:"⚕",roles:["doctor"]},
  {href:"/staff/administration",key:"roles.administration",icon:"▦",roles:["administration"]},
  {href:"/staff/super-admin",key:"roles.super_admin",icon:"◇",roles:["super_admin"]},
  {href:"/staff/appointments",key:"nav.appointments",icon:"◷",permission:"appointments.view"},
  {href:"/staff/patients",key:"nav.patients",icon:"♙",permission:"patients.view_general"},
  {href:"/staff/services",key:"nav.services",icon:"▦",permission:"services.view"},
  {href:"/staff/calls",key:"nav.calls",icon:"◉",permission:"ai.manage",roles:["super_admin"]},
  {href:"/staff/analytics",key:"nav.analytics",icon:"⌁",permission:"analytics.view"},
  {href:"/staff/roles",key:"nav.roles",icon:"◫",permission:"roles.manage",roles:["super_admin"]},
  {href:"/staff/super-admin/accounts",key:"nav.accounts",icon:"◎",permission:"staff.manage",roles:["super_admin"]},
  {href:"/staff/settings",key:"nav.settings",icon:"⚙",permission:"system_settings.manage",roles:["super_admin"]}
];

export function StaffShell({children,role}:{children:React.ReactNode;role?:StaffRole}){const pathname=usePathname();const {locale,rtl}=usePersistentLocale();const identity=role?demoIdentity[role]:undefined;const visible=links.filter(link=>{if(!identity)return !link.roles&&(!link.permission||["appointments.view","patients.view_general","services.view","analytics.view"].includes(link.permission));if(link.roles&&!link.roles.includes(identity.role))return false;return !link.permission||hasPermission(identity,link.permission)});return <div className={`app-shell ${rtl?"rtl":""}`} dir={rtl?"rtl":"ltr"}>
    <aside className="sidebar">
      <Logo/>
      <div className="staff-mode-chip"><span/> {role?t(locale,`roles.${role==="super_admin"?"super_admin":role}`):t(locale,"staff.title")}</div>
      <nav className="side-nav">{visible.map(link=><Link key={link.href} className={`side-link ${pathname===link.href?"active":""}`} href={link.href}><span>{link.icon}</span>{t(locale,link.key)}</Link>)}</nav>
      <div className="sidebar-proof"><strong>{identity?.name??t(locale,"staff.role_overview")}</strong><small>{identity?.department??"Doctor · Administration · Super Admin"}</small></div>
      <div className="sidebar-foot">Hani Maak · Demo tenant<br/>Synthetic data only</div>
    </aside>
    <main className="main">
      <div className="staff-mobile-head"><Logo compact/><div className="row"><LocaleSwitcher/><span className="map-live-dot"/></div></div>
      <div className="staff-toolbar"><LocaleSwitcher/>{identity&&<span className="badge info">{t(locale,`roles.${identity.role==="super_admin"?"super_admin":identity.role}`)}</span>}</div>
      {children}
    </main>
  </div>}
