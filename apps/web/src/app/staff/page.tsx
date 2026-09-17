"use client";
import Link from "next/link";
import {StaffShell} from "@/components/StaffShell";
import {usePersistentLocale} from "@/lib/locale-client";
import {t} from "@/lib/i18n";
import {roleMeta,type StaffRole} from "@/lib/access";

const roles:StaffRole[]=["doctor","administration","super_admin"];
const accessKey:Record<StaffRole,string>={doctor:"roles.doctor_access",administration:"roles.administration_access",super_admin:"roles.super_admin_access"};
const manageKey:Record<StaffRole,string>={doctor:"roles.doctor_manage",administration:"roles.administration_manage",super_admin:"roles.super_admin_manage"};

export default function StaffHome(){const {locale}=usePersistentLocale();return <StaffShell><div className="page-head"><div><div className="eyebrow">{t(locale,"staff.role_overview")}</div><h1>{t(locale,"staff.title")}</h1><div className="muted">{t(locale,"staff.subtitle")}</div></div><Link className="btn btn-secondary" href="/">Hani Maak</Link></div><div className="role-card-grid">{roles.map(role=>{const meta=roleMeta[role];return <section className={`card role-card role-${role}`} key={role}><div className="role-card-icon">{meta.icon}</div><div className="eyebrow">{t(locale,meta.labelKey)}</div><h2>{t(locale,meta.labelKey)}</h2><p className="muted">{t(locale,meta.summaryKey)}</p><div className="role-scope"><strong>{t(locale,"staff.what_can_access")}</strong><p>{t(locale,accessKey[role])}</p></div><div className="role-scope"><strong>{t(locale,"staff.what_can_manage")}</strong><p>{t(locale,manageKey[role])}</p></div><div className="role-card-actions"><Link className="btn btn-primary" href={meta.home}>{t(locale,"staff.open_workspace")}</Link><Link className="btn btn-secondary" href={`/staff/roles/${role}`}>{t(locale,"staff.view_permissions")}</Link></div></section>})}</div></StaffShell>}
