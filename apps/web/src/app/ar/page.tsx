"use client";
import {useEffect} from "react";
import {useRouter} from "next/navigation";
import {usePersistentLocale} from "@/lib/locale-client";
export default function ArabicLegacy(){const router=useRouter();const {setLocale}=usePersistentLocale("ar");useEffect(()=>{setLocale("ar");router.replace("/patient")},[router,setLocale]);return <main style={{padding:24}}>هاني معاك…</main>}
