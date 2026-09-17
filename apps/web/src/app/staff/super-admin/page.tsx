"use client";
import Link from "next/link";
import {StaffShell} from "@/components/StaffShell";
import {usePersistentLocale} from "@/lib/locale-client";
import {t} from "@/lib/i18n";

const sections=[
  {key:"super.platform",items:["super.organizations","nav.services","super.languages","super.features"]},
  {key:"super.ai",items:["nav.calls","super.ai","nav.analytics"]},
  {key:"super.navigation",items:["nav.map","nav.services"]},
  {key:"super.access",items:["nav.accounts","nav.roles"]},
  {key:"super.system",items:["super.integrations","super.logs","nav.settings"]}
];

export default function SuperAdminDashboard(){const {locale}=usePersistentLocale();return <StaffShell role="super_admin"><div className="page-head"><div><div className="eyebrow">{t(locale,"roles.super_admin")}</div><h1>{t(locale,"super.dashboard")}</h1><p className="muted">{t(locale,"roles.super_admin_summary")}</p></div><Link className="btn btn-secondary" href="/staff/roles/super_admin">{t(locale,"staff.view_permissions")}</Link></div><div className="super-grid">{sections.map(section=><section className="card super-section" key={section.key}><div className="eyebrow">{t(locale,section.key)}</div><div className="super-link-list">{section.items.map(item=><div className="super-link-row" key={item}><strong>{t(locale,item)}</strong><span>→</span></div>)}</div></section>)}</div><div className="notice safe" style={{marginTop:18}}>Clinical patient information is deliberately excluded from routine Super Admin workflows. Platform authority does not imply unrestricted clinical access.</div></StaffShell>}
