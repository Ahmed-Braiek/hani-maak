"use client";
import {StaffShell} from "@/components/StaffShell";
import {usePersistentLocale} from "@/lib/locale-client";
import {t} from "@/lib/i18n";

const accounts=[
  {name:"Dr. Leila Mansouri",email:"leila.mansouri@example.demo",role:"doctor",department:"Imagerie",status:"active",last:"Aujourd'hui 08:12",created:"12/09/2026"},
  {name:"Salma Ben Amor",email:"salma.benamor@example.demo",role:"administration",department:"Admissions",status:"active",last:"Aujourd'hui 07:54",created:"10/09/2026"},
  {name:"Hani Maak Platform",email:"platform@example.demo",role:"super_admin",department:"Platform",status:"active",last:"Aujourd'hui 09:02",created:"01/09/2026"}
];

export default function Accounts(){const {locale}=usePersistentLocale();return <StaffShell role="super_admin"><div className="page-head"><div><div className="eyebrow">{t(locale,"nav.accounts")}</div><h1>{t(locale,"accounts.title")}</h1><p className="muted">Default roles plus future account-specific permission overrides.</p></div><button className="btn btn-primary">+ {t(locale,"common.manage")}</button></div><section className="card"><div className="staff-table-wrap"><table className="staff-table"><thead><tr><th>{t(locale,"accounts.name")}</th><th>{t(locale,"accounts.email")}</th><th>{t(locale,"accounts.role")}</th><th>{t(locale,"accounts.department")}</th><th>{t(locale,"accounts.status")}</th><th>{t(locale,"accounts.last_login")}</th><th>{t(locale,"accounts.created")}</th></tr></thead><tbody>{accounts.map(a=><tr key={a.email}><td><strong>{a.name}</strong></td><td>{a.email}</td><td>{t(locale,`roles.${a.role}`)}</td><td>{a.department}</td><td><span className="badge good">{t(locale,"accounts.active")}</span></td><td>{a.last}</td><td>{a.created}</td></tr>)}</tbody></table></div></section></StaffShell>}
