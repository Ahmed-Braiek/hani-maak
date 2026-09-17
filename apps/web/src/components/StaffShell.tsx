"use client";

import Link from "next/link";
import {useEffect,useMemo,useState} from "react";
import {usePathname,useRouter} from "next/navigation";
import {Logo} from "./Logo";
import {LocaleSwitcher} from "./LocaleSwitcher";
import {usePersistentLocale} from "@/lib/locale-client";
import {t} from "@/lib/i18n";
import {hasPermission,roleMeta,type Permission,type StaffIdentity,type StaffRole} from "@/lib/access";

const demoIdentity:Record<StaffRole,StaffIdentity>={
  doctor:{id:"staff-doctor-demo",name:"Dr. Leila Mansouri",role:"doctor",department:"Imagerie"},
  administration:{id:"staff-admin-demo",name:"Salma Ben Amor",role:"administration",department:"Admissions"},
  super_admin:{id:"staff-super-demo",name:"Hani Maak Platform",role:"super_admin",department:"Platform"}
};
const roles:StaffRole[]=["doctor","administration","super_admin"];
const links:{href:string;key:string;icon:string;permission?:Permission;roles?:StaffRole[]}[]=[
  {href:"/staff",key:"nav.overview",icon:"⌂"},
  {href:"/staff/doctor",key:"roles.doctor",icon:"⚕",roles:["doctor"]},
  {href:"/staff/administration",key:"roles.administration",icon:"▦",roles:["administration"]},
  {href:"/staff/super-admin",key:"roles.super_admin",icon:"◇",roles:["super_admin"]},
  {href:"/staff/appointments",key:"nav.appointments",icon:"◷",permission:"appointments.view"},
  {href:"/staff/patients",key:"nav.patients",icon:"♙",permission:"patients.view_general"},
  {href:"/staff/services",key:"nav.services",icon:"▦",permission:"services.view"},
  {href:"/staff/map",key:"nav.map",icon:"⌖",permission:"maps.manage",roles:["super_admin"]},
  {href:"/staff/calls",key:"nav.calls",icon:"◉",permission:"ai.manage",roles:["super_admin"]},
  {href:"/staff/analytics",key:"nav.analytics",icon:"⌁",permission:"analytics.view"},
  {href:"/staff/roles",key:"nav.roles",icon:"◫",permission:"roles.manage",roles:["super_admin"]},
  {href:"/staff/super-admin/accounts",key:"nav.accounts",icon:"◎",permission:"staff.manage",roles:["super_admin"]},
  {href:"/staff/super-admin/white-label",key:"nav.white_label",icon:"◈",permission:"white_label.manage",roles:["super_admin"]},
  {href:"/staff/super-admin/audit",key:"nav.audit",icon:"≣",permission:"audit.view",roles:["super_admin"]},
  {href:"/staff/settings",key:"nav.settings",icon:"⚙",permission:"system_settings.manage",roles:["super_admin"]}
];

export function StaffShell({children,role}:{children:React.ReactNode;role?:StaffRole}){
  const pathname=usePathname();
  const router=useRouter();
  const {locale,rtl}=usePersistentLocale();
  const [currentRole,setCurrentRole]=useState<StaffRole|undefined>(role);
  const [switching,setSwitching]=useState(false);

  useEffect(()=>{
    if(role){setCurrentRole(role);return}
    let active=true;
    fetch("/api/v1/staff/session/role",{cache:"no-store"}).then(r=>r.json()).then(payload=>{
      if(active&&(payload.role==="doctor"||payload.role==="administration"||payload.role==="super_admin"))setCurrentRole(payload.role);
    }).catch(()=>undefined);
    return()=>{active=false};
  },[role]);

  const identity=currentRole?demoIdentity[currentRole]:undefined;
  const visible=useMemo(()=>links.filter(link=>{
    if(!identity)return link.href==="/staff";
    if(link.roles&&!link.roles.includes(identity.role))return false;
    return !link.permission||hasPermission(identity,link.permission);
  }),[identity]);

  async function switchRole(next:StaffRole){
    if(switching||next===currentRole)return;
    setSwitching(true);
    try{
      const response=await fetch("/api/v1/staff/session/role",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({role:next})});
      if(!response.ok)throw new Error("role_switch_failed");
      setCurrentRole(next);
      router.push(roleMeta[next].home);
      router.refresh();
    }finally{setSwitching(false)}
  }

  const roleSwitcher=<div className="staff-role-switcher" aria-label="Staff role switcher">{roles.map(item=><button key={item} type="button" className={currentRole===item?"active":""} onClick={()=>void switchRole(item)} disabled={switching}>{item==="doctor"?"⚕":item==="administration"?"▦":"◇"}<span>{t(locale,`roles.${item}`)}</span></button>)}</div>;

  return <div className={`app-shell staff-app-shell ${rtl?"rtl":""}`} dir={rtl?"rtl":"ltr"}>
    <aside className="sidebar staff-sidebar">
      <div className="staff-sidebar-top"><Logo/><Link className="staff-home-link" href="/">⌂ {t(locale,"nav.home")}</Link></div>
      <div className="staff-mode-chip"><span/> {currentRole?t(locale,`roles.${currentRole}`):t(locale,"staff.title")}</div>
      {roleSwitcher}
      <nav className="side-nav">{visible.map(link=><Link key={link.href} className={`side-link ${pathname===link.href?"active":""}`} href={link.href}><span>{link.icon}</span>{t(locale,link.key)}</Link>)}</nav>
      <div className="sidebar-proof"><strong>{identity?.name??t(locale,"staff.role_overview")}</strong><small>{identity?.department??"Doctor · Administration · Super Admin"}</small></div>
      <div className="staff-sidebar-shortcuts"><Link href="/patient">↔ Patient</Link><Link href="/present">▶ Presentation</Link></div>
      <div className="sidebar-foot">Hani Maak · Demo tenant<br/>{t(locale,"common.synthetic")}</div>
    </aside>

    <main className="main staff-main">
      <div className="staff-mobile-head">
        <Link className="staff-mobile-home" href="/" aria-label={t(locale,"nav.home")}>⌂</Link>
        <Logo compact/>
        <div className="staff-mobile-head-actions"><LocaleSwitcher/><details className="staff-mobile-menu"><summary aria-label="Staff menu">☰</summary><div className="staff-mobile-menu-panel"><strong>{t(locale,"staff.title")}</strong>{visible.map(link=><Link key={link.href} href={link.href}>{link.icon} {t(locale,link.key)}</Link>)}<Link href="/patient">↔ Patient</Link><Link href="/present">▶ Presentation</Link></div></details></div>
      </div>
      <div className="staff-mobile-rolebar">{roleSwitcher}</div>
      <div className="staff-toolbar"><Link className="btn btn-secondary compact staff-desktop-home" href="/">⌂ {t(locale,"nav.home")}</Link><LocaleSwitcher/>{identity&&<span className="badge info">{t(locale,`roles.${identity.role}`)}</span>}<Link className="btn btn-secondary compact" href="/patient">↔ Patient</Link></div>
      {children}
    </main>

    <nav className="staff-mobile-dock" aria-label="Staff quick navigation">
      <Link href="/"><span>⌂</span><small>{t(locale,"nav.home")}</small></Link>
      <Link href="/staff"><span>▣</span><small>Staff</small></Link>
      {currentRole&&<Link href={roleMeta[currentRole].home}><span>{currentRole==="doctor"?"⚕":currentRole==="administration"?"▦":"◇"}</span><small>{t(locale,`roles.${currentRole}`)}</small></Link>}
      <Link href="/patient"><span>♡</span><small>Patient</small></Link>
    </nav>
  </div>
}
