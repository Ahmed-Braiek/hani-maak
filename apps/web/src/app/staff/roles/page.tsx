"use client";
import Link from "next/link";
import {StaffShell} from "@/components/StaffShell";
import {usePersistentLocale} from "@/lib/locale-client";
import {t} from "@/lib/i18n";
import {roleMeta,type StaffRole} from "@/lib/access";
const roles:StaffRole[]=["doctor","administration","super_admin"];
export default function Roles(){const {locale}=usePersistentLocale();return <StaffShell role="super_admin"><div className="page-head"><div><div className="eyebrow">{t(locale,"nav.roles")}</div><h1>{t(locale,"permissions.title")}</h1><p className="muted">Role defaults are explicit, least-privilege, and can later be extended with account-specific overrides.</p></div></div><div className="role-card-grid compact">{roles.map(role=>{const meta=roleMeta[role];return <Link className="card role-card" key={role} href={`/staff/roles/${role}`}><div className="role-card-icon">{meta.icon}</div><h2>{t(locale,meta.labelKey)}</h2><p className="muted">{t(locale,meta.summaryKey)}</p><span className="btn btn-secondary">{t(locale,"staff.view_permissions")} →</span></Link>})}</div></StaffShell>}
