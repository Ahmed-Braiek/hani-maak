import {cookies} from "next/headers";
import type {Locale} from "./types";

const supported:Locale[]=["fr","ar","en"];

export function isLocale(value:string|undefined|null):value is Locale{
  return supported.includes(value as Locale);
}

export async function getServerLocale(fallback:Locale="fr"):Promise<Locale>{
  const store=await cookies();
  const value=store.get("hani_locale")?.value;
  return isLocale(value)?value:fallback;
}

export function localeTag(locale:Locale){
  return locale==="ar"?"ar-TN":locale==="en"?"en-GB":"fr-TN";
}

export function dirForLocale(locale:Locale){return locale==="ar"?"rtl":"ltr" as const}
