"use client";
import {useState} from "react";
import {useRouter} from "next/navigation";
import type {StaffRole} from "@/lib/access";
import {usePersistentLocale} from "@/lib/locale-client";
import {t} from "@/lib/i18n";

export function RoleLauncher({role,href}:{role:StaffRole;href:string}){const router=useRouter();const {locale}=usePersistentLocale();const [busy,setBusy]=useState(false);async function open(){setBusy(true);try{const r=await fetch("/api/v1/staff/session/role",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({role})});if(!r.ok)throw new Error();router.push(href);router.refresh()}finally{setBusy(false)}}return <button className="btn btn-primary" onClick={()=>void open()} disabled={busy}>{busy?"…":t(locale,"staff.open_workspace")}</button>}
