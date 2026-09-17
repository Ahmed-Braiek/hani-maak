"use client";

import {useCallback,useEffect,useState} from "react";
import type {Locale} from "./types";

const STORAGE_KEY="hani_locale";
const COOKIE_KEY="hani_locale";
const EVENT_NAME="hani-locale-change";
const supported:Locale[]=["fr","ar","en"];

function valid(value:string|null|undefined):value is Locale{return supported.includes(value as Locale)}
function cookieLocale(){if(typeof document==="undefined")return null;const match=document.cookie.split("; ").find(v=>v.startsWith(`${COOKIE_KEY}=`));return match?decodeURIComponent(match.split("=").slice(1).join("=")):null}
function storedLocale(){if(typeof window==="undefined")return null;const local=window.localStorage.getItem(STORAGE_KEY);if(valid(local))return local;const cookie=cookieLocale();return valid(cookie)?cookie:null}
function applyLocale(locale:Locale){if(typeof document==="undefined")return;document.documentElement.lang=locale;document.documentElement.dir=locale==="ar"?"rtl":"ltr";document.body?.setAttribute("dir",locale==="ar"?"rtl":"ltr")}
function persist(locale:Locale){if(typeof window==="undefined")return;window.localStorage.setItem(STORAGE_KEY,locale);document.cookie=`${COOKIE_KEY}=${encodeURIComponent(locale)}; Path=/; Max-Age=31536000; SameSite=Lax`;applyLocale(locale);window.dispatchEvent(new CustomEvent(EVENT_NAME,{detail:locale}));}

export function usePersistentLocale(initialLocale:Locale="fr"){
  const [locale,setLocaleState]=useState<Locale>(initialLocale);
  useEffect(()=>{const saved=storedLocale();const resolved=initialLocale!=="fr"?initialLocale:(saved??initialLocale);setLocaleState(resolved);if(!saved||resolved!==saved)persist(resolved);else applyLocale(resolved);const onChange=(event:Event)=>{const next=(event as CustomEvent<Locale>).detail;if(valid(next))setLocaleState(next)};const onStorage=(event:StorageEvent)=>{if(event.key===STORAGE_KEY&&valid(event.newValue)){setLocaleState(event.newValue);applyLocale(event.newValue)}};window.addEventListener(EVENT_NAME,onChange);window.addEventListener("storage",onStorage);return()=>{window.removeEventListener(EVENT_NAME,onChange);window.removeEventListener("storage",onStorage)}},[initialLocale]);
  const setLocale=useCallback((next:Locale)=>{setLocaleState(next);persist(next)},[]);
  return {locale,setLocale,rtl:locale==="ar"};
}
