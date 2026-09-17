import type {Metadata,Viewport} from "next";
import type {CSSProperties} from "react";
import "./globals.css";
import "./competition-fixes.css";
import "./staff-phase.css";
import {readDb} from "@/lib/db";
import {HeniCompanion} from "@/components/HeniCompanion";

export const metadata:Metadata={
  title:"Hani Maak — Patient Journey Infrastructure",
  description:"Access. Guidance. Continuity. A competition-ready patient journey platform.",
  applicationName:"Hani Maak",
};
export const viewport:Viewport={width:"device-width",initialScale:1,themeColor:"#0f766e"};
export const dynamic="force-dynamic";

export default async function RootLayout({children}:{children:React.ReactNode}){
  const db=await readDb().catch(()=>null);
  const style=db?({"--brand":db.tenant.brand.primary,"--accent":db.tenant.brand.accent} as CSSProperties):undefined;
  return <html lang="fr" suppressHydrationWarning><body style={style} suppressHydrationWarning>{children}<HeniCompanion/></body></html>;
}
