"use client";
import Link from "next/link";
import {usePathname} from "next/navigation";
import {Logo} from "./Logo";
import {LocaleSwitcher} from "./LocaleSwitcher";
import type {Locale} from "@/lib/types";
import {usePersistentLocale} from "@/lib/locale-client";
import {t} from "@/lib/i18n";

export function PatientShell({children,locale:initialLocale="fr"}:{children:React.ReactNode;locale?:Locale}){
  const pathname=usePathname();
  const {locale,rtl}=usePersistentLocale(initialLocale);
  const items=[
    {href:"/patient",icon:"⌂",label:t(locale,"nav.home"),match:(p:string)=>p==="/patient"},
    {href:"/patient/journey",icon:"✓",label:t(locale,"nav.journey"),match:(p:string)=>p.startsWith("/patient/journey")},
    {href:"/patient/map",icon:"⌖",label:t(locale,"nav.map"),match:(p:string)=>p.startsWith("/patient/map")},
    {href:"/patient/profile",icon:"○",label:t(locale,"nav.profile"),match:(p:string)=>p.startsWith("/patient/profile")}
  ];
  return <div className={`patient-shell ${rtl?"rtl":""}`} dir={rtl?"rtl":"ltr"}>
    <header className="patient-head">
      <div className="patient-head-brand">
        <Link className="patient-home-icon" href="/" aria-label={t(locale,"nav.home")}>⌂</Link>
        <Link href="/patient" aria-label="Heni Maak"><Logo compact/></Link>
      </div>
      <div className="patient-head-actions"><LocaleSwitcher/></div>
    </header>
    <main className="patient-main">{children}</main>
    <nav className="mobile-nav patient-mobile-nav" aria-label={t(locale,"patient.navigation")}>
      {items.map(item=><Link key={item.href} className={`mobile-link ${item.match(pathname)?"active":""}`} href={item.href} aria-current={item.match(pathname)?"page":undefined}>
        <span>{item.icon}</span><span>{item.label}</span>
      </Link>)}
    </nav>
  </div>;
}
