"use client";
import {useRouter} from "next/navigation";import {usePersistentLocale} from "@/lib/locale-client";import type {Locale} from "@/lib/types";
const options:{value:Locale;label:string}[]=[{value:"fr",label:"FR"},{value:"ar",label:"ع"},{value:"en",label:"EN"}];
export function LocaleSwitcher(){const router=useRouter();const {locale,setLocale}=usePersistentLocale();function change(next:Locale){setLocale(next);requestAnimationFrame(()=>router.refresh())}return <div className="locale-switcher" aria-label="Language">{options.map(option=><button key={option.value} type="button" className={locale===option.value?"active":""} onClick={()=>change(option.value)} aria-pressed={locale===option.value}>{option.label}</button>)}</div>}
