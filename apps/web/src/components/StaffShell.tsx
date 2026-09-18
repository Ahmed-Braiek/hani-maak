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
  const [loggingOut,setLoggingOut]=useState(false);

  useEffect(()=>{
    if(role){setCurrentRole(role);return}
    let active=true;
    fetch("/api/v1/staff/session/role",{cache:"no-store"})
      .then(r=>r.json())
      .then(payload=>{
        if(active&&(payload.role==="doctor"||payload.role==="administration"||payload.role==="super_admin"))setCurrentRole(payload.role);
      })
      .catch(()=>undefined);
    return()=>{active=false};
  },[role]);

  const identity=currentRole?demoIdentity[currentRole]:undefined;
  const visible=useMemo(()=>links.filter(link=>{
    if(!identity)return link.href==="/staff";
    if(link.roles&&!link.roles.includes(identity.role))return false;
    return !link.permission||hasPermission(identity,link.permission);
  }),[identity]);

  const navTitle=locale==="ar"?"شنوّة تحب تعمل؟":locale==="en"?"What do you want to do?":"Que voulez-vous faire ?";
  const logoutLabel=locale==="ar"?"تسجيل الخروج":locale==="en"?"Log out":"Se déconnecter";
  const workspaceLabel=locale==="ar"?"مساحة عمل الفريق":locale==="en"?"Staff workspace":"Espace équipe";
  const currentLabel=locale==="ar"?"الدور الحالي":locale==="en"?"Signed in as":"Connecté en tant que";

  async function logout(){
    if(loggingOut)return;
    setLoggingOut(true);
    try{await fetch("/api/v1/staff/session/role",{method:"DELETE"})}finally{
      setCurrentRole(undefined);
      router.replace("/");
      router.refresh();
    }
  }

  return <div className={`app-shell staff-app-shell ${rtl?"rtl":""}`} dir={rtl?"rtl":"ltr"}>
    <aside className="sidebar staff-sidebar">
      <div className="staff-sidebar-top">
        <Logo/>
        <Link className="staff-home-link" href="/">⌂ {t(locale,"nav.home")}</Link>
      </div>

      {identity&&<div className="staff-current-role-card">
        <span className="staff-current-role-icon">{currentRole==="doctor"?"⚕":currentRole==="administration"?"▦":"◇"}</span>
        <div><small>{currentLabel}</small><strong>{t(locale,`roles.${currentRole}`)}</strong><span>{identity.name}</span></div>
      </div>}

      <nav className="side-nav" aria-label={navTitle}>
        {visible.map(link=><Link key={link.href} className={`side-link ${pathname===link.href?"active":""}`} href={link.href}>
          <span>{link.icon}</span>{t(locale,link.key)}
        </Link>)}
      </nav>

      <button className="staff-logout-btn" type="button" onClick={()=>void logout()} disabled={loggingOut}>
        <span>↪</span><b>{loggingOut?"…":logoutLabel}</b>
      </button>
      <div className="sidebar-foot">Hani Maak<br/>{workspaceLabel}</div>
    </aside>

    <main className="main staff-main">
      <div className="staff-mobile-head">
        <Link className="staff-mobile-home" href="/" aria-label={t(locale,"nav.home")}>⌂</Link>
        <Link className="staff-mobile-brand" href="/staff" aria-label={t(locale,"staff.title")}>
          <Logo compact/>
          <span className="staff-mobile-context">
            <small>{workspaceLabel}</small>
            <strong>{currentRole?t(locale,`roles.${currentRole}`):t(locale,"staff.title")}</strong>
          </span>
        </Link>
        <div className="staff-mobile-head-actions">
          <LocaleSwitcher/>
          <details className="staff-mobile-menu">
            <summary aria-label="Staff menu">☰</summary>
            <div className="staff-mobile-menu-panel">
              <div className="staff-menu-heading">
                <strong>{navTitle}</strong>
                <small>{identity?.name??"Hani Maak"}</small>
              </div>
              {visible.map(link=><Link key={link.href} className={pathname===link.href?"active":""} href={link.href}>
                <span>{link.icon}</span><b>{t(locale,link.key)}</b>
              </Link>)}
              <div className="staff-menu-divider"/>
              <button className="staff-menu-logout" type="button" onClick={()=>void logout()} disabled={loggingOut}>
                <span>↪</span><b>{logoutLabel}</b>
              </button>
            </div>
          </details>
        </div>
      </div>

      <div className="staff-toolbar">
        <Link className="btn btn-secondary compact staff-desktop-home" href="/">⌂ {t(locale,"nav.home")}</Link>
        <div className="staff-toolbar-context">
          <small>{currentLabel}</small>
          <strong>{currentRole?t(locale,`roles.${currentRole}`):t(locale,"staff.title")}</strong>
        </div>
        <LocaleSwitcher/>
        <button className="btn btn-secondary compact staff-toolbar-logout" type="button" onClick={()=>void logout()} disabled={loggingOut}>↪ {logoutLabel}</button>
      </div>

      {children}
    </main>

    <nav className="staff-mobile-dock" aria-label="Staff quick navigation">
      <Link href="/"><span>⌂</span><small>{t(locale,"nav.home")}</small></Link>
      <Link href="/staff"><span>▣</span><small>{locale==="ar"?"نظرة عامة":locale==="en"?"Overview":"Aperçu"}</small></Link>
      {currentRole&&<Link href={roleMeta[currentRole].home}><span>{currentRole==="doctor"?"⚕":currentRole==="administration"?"▦":"◇"}</span><small>{t(locale,`roles.${currentRole}`)}</small></Link>}
      <button type="button" className="staff-mobile-logout" onClick={()=>void logout()} disabled={loggingOut}><span>↪</span><small>{logoutLabel}</small></button>
    </nav>
  </div>;
}
