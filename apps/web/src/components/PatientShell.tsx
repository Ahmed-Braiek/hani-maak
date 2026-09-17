"use client";
import Link from "next/link";
import {Logo} from "./Logo";
import {LocaleSwitcher} from "./LocaleSwitcher";
import type {Locale} from "@/lib/types";
import {usePersistentLocale} from "@/lib/locale-client";
import {t} from "@/lib/i18n";

export function PatientShell({children,locale:initialLocale="fr"}:{children:React.ReactNode;locale?:Locale}){
  const {locale,rtl}=usePersistentLocale(initialLocale);
  return <div className={`patient-shell ${rtl?"rtl":""}`} dir={rtl?"rtl":"ltr"}>
    <header className="patient-head">
      <div className="patient-head-brand"><Link className="patient-home-icon" href="/" aria-label={t(locale,"nav.home")}>⌂</Link><Logo compact/></div>
      <div className="patient-head-actions"><Link className="patient-staff-chip" href="/staff">▣ Staff</Link><LocaleSwitcher/></div>
    </header>
    <main className="patient-main">{children}</main>
    <nav className="mobile-nav patient-mobile-nav" aria-label={t(locale,"patient.navigation")}>
      <Link className="mobile-link" href="/patient"><span>⌂</span><span>{t(locale,"nav.home")}</span></Link>
      <Link className="mobile-link" href="/patient/journey"><span>✓</span><span>{t(locale,"nav.journey")}</span></Link>
      <Link className="mobile-link" href="/patient/map"><span>⌖</span><span>{t(locale,"nav.map")}</span></Link>
      <Link className="mobile-link" href="/patient/profile"><span>○</span><span>{t(locale,"nav.profile")}</span></Link>
      <Link className="mobile-link patient-staff-nav" href="/staff"><span>▣</span><span>Staff</span></Link>
    </nav>
  </div>
}
