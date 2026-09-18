import type {Metadata,Viewport} from "next";
import type {CSSProperties} from "react";
import "./globals.css";
import "./competition-fixes.css";
import "./staff-phase.css";
import "./mobile-ar-polish.css";
import "./ux-final-polish.css";
import "./ar-cta-redesign.css";
import "./staff-ar-ux-v2.css";
import "./feature-cleanup-v3.css";
import "./staff-auth.css";
import "./heni-expressive.css";
import "./brand-refresh.css";
import {readDb} from "@/lib/db";
import {HeniCompanion} from "@/components/HeniCompanion";
import {getServerLocale,dirForLocale} from "@/lib/i18n-server";

export const metadata:Metadata={
  title:"Heni Maak — Patient Journey Infrastructure",
  description:"Access. Guidance. Continuity. A patient journey platform for healthcare providers.",
  applicationName:"Heni Maak"
};
export const viewport:Viewport={width:"device-width",initialScale:1,themeColor:"#0849b4"};
export const dynamic="force-dynamic";

const LEGACY_PRIMARY="#0f766e";
const LEGACY_ACCENT="#ef6c4d";

export default async function RootLayout({children}:{children:React.ReactNode}){
  const [db,locale]=await Promise.all([readDb().catch(()=>null),getServerLocale()]);
  const primary=db?.tenant.brand.primary===LEGACY_PRIMARY?"#0849b4":db?.tenant.brand.primary;
  const accent=db?.tenant.brand.accent===LEGACY_ACCENT?"#189bed":db?.tenant.brand.accent;
  const style=db?({"--brand":primary||"#0849b4","--accent":accent||"#189bed"} as CSSProperties):undefined;
  return <html lang={locale} dir={dirForLocale(locale)} suppressHydrationWarning>
    <body style={style} dir={dirForLocale(locale)} suppressHydrationWarning>{children}<HeniCompanion/></body>
  </html>;
}
