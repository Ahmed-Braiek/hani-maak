"use client";

import {useMemo,useState} from "react";
import {useRouter} from "next/navigation";
import {Logo} from "./Logo";
import {LocaleSwitcher} from "./LocaleSwitcher";
import {usePersistentLocale} from "@/lib/locale-client";
import {DEMO_STAFF_ACCOUNTS} from "@/lib/staff-demo-accounts";
import type {StaffRole} from "@/lib/access";

type Mode="signin"|"signup";
const roles:StaffRole[]=["doctor","administration","super_admin"];

async function readJson(response:Response){
  const text=await response.text();
  if(!text)return {};
  try{return JSON.parse(text)}catch{return {error:"invalid_response"}}
}

export function StaffAccessClient({initialMode="signin"}:{initialMode?:Mode}){
  const router=useRouter();
  const {locale,rtl}=usePersistentLocale();
  const [mode,setMode]=useState<Mode>(initialMode);
  const [role,setRole]=useState<StaffRole>("doctor");
  const [username,setUsername]=useState("");
  const [password,setPassword]=useState("");
  const [displayName,setDisplayName]=useState("");
  const [busy,setBusy]=useState(false);
  const [error,setError]=useState("");
  const [success,setSuccess]=useState("");

  const copy=useMemo(()=>({
    eyebrow:locale==="ar"?"دخول الفريق":locale==="en"?"Staff access":"Accès équipe",
    title:locale==="ar"?"مساحة آمنة للفريق":locale==="en"?"Secure staff workspace":"Espace équipe sécurisé",
    lead:locale==="ar"?"اختار دورك وادخل بحساب الفريق. الصلاحيات تتطبق في السيرفر.":locale==="en"?"Choose your role and sign in with a staff account. Permissions are enforced server-side.":"Choisissez votre rôle et connectez-vous avec un compte équipe. Les permissions sont appliquées côté serveur.",
    signin:locale==="ar"?"تسجيل الدخول":locale==="en"?"Sign in":"Se connecter",
    signup:locale==="ar"?"طلب حساب":locale==="en"?"Request account":"Demander un compte",
    role:locale==="ar"?"الدور":locale==="en"?"Role":"Rôle",
    username:locale==="ar"?"اسم المستخدم":locale==="en"?"Username":"Nom d’utilisateur",
    password:locale==="ar"?"كلمة السر":locale==="en"?"Password":"Mot de passe",
    name:locale==="ar"?"الاسم الكامل":locale==="en"?"Full name":"Nom complet",
    demo:locale==="ar"?"حسابات جاهزة للتجربة":locale==="en"?"Ready-to-use access":"Accès prêts à tester",
    demoHint:locale==="ar"?"اضغط على حساب لتعمير البيانات مباشرة.":locale==="en"?"Tap an account to fill the credentials instantly.":"Touchez un compte pour remplir les identifiants.",
    pending:locale==="ar"?"طلبك تسجّل. يلزم موافقة مسؤول قبل تفعيل أي صلاحيات.":locale==="en"?"Request recorded. An administrator must approve it before any permissions are granted.":"Demande enregistrée. Un administrateur doit l’approuver avant l’activation des permissions.",
    secure:locale==="ar"?"جلسة موقعة · صلاحيات حسب الدور · خروج واضح":locale==="en"?"Signed session · role permissions · explicit logout":"Session signée · permissions par rôle · déconnexion explicite",
    back:locale==="ar"?"الرجوع للرئيسية":locale==="en"?"Back home":"Retour à l’accueil",
    submitSignup:locale==="ar"?"إرسال الطلب":locale==="en"?"Submit request":"Envoyer la demande",
    invalid:locale==="ar"?"راجع الدور واسم المستخدم وكلمة السر.":locale==="en"?"Check the role, username and password.":"Vérifiez le rôle, le nom d’utilisateur et le mot de passe.",
    failed:locale==="ar"?"تعذر إتمام العملية. جرّب مرة أخرى.":locale==="en"?"The request could not be completed. Try again.":"Impossible de terminer l’opération. Réessayez."
  }),[locale]);

  const roleName=(value:StaffRole)=>value==="doctor"?(locale==="ar"?"طبيب":locale==="en"?"Doctor":"Médecin"):value==="administration"?(locale==="ar"?"الإدارة":locale==="en"?"Administration":"Administration"):(locale==="ar"?"مدير المنصة":locale==="en"?"Super Admin":"Super Admin");

  function fillDemo(next:StaffRole){
    const account=DEMO_STAFF_ACCOUNTS[next];
    setMode("signin");setRole(next);setUsername(account.username);setPassword(account.password);setError("");setSuccess("");
  }

  async function submit(event:React.FormEvent){
    event.preventDefault();setBusy(true);setError("");setSuccess("");
    try{
      if(mode==="signin"){
        const response=await fetch("/api/v1/staff/session/login",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({role,username,password})});
        const payload=await readJson(response);
        if(!response.ok){setError(response.status===401?copy.invalid:copy.failed);return}
        router.replace(String(payload.home||"/staff"));router.refresh();
      }else{
        const response=await fetch("/api/v1/staff/session/signup",{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify({displayName,role,username,password})});
        if(!response.ok){setError(copy.failed);return}
        setSuccess(copy.pending);setPassword("");
      }
    }catch{setError(copy.failed)}
    finally{setBusy(false)}
  }

  return <main className={"staff-access-page "+(rtl?"rtl":"")} dir={rtl?"rtl":"ltr"}>
    <header className="staff-access-topbar">
      <Logo/>
      <div className="staff-access-top-actions"><LocaleSwitcher/><a href="/" className="btn btn-secondary compact">⌂ {copy.back}</a></div>
    </header>

    <section className="staff-access-shell">
      <div className="staff-access-story">
        <div className="eyebrow">{copy.eyebrow}</div>
        <h1>{copy.title}</h1>
        <p>{copy.lead}</p>
        <div className="staff-auth-proof"><span>✓</span><strong>{copy.secure}</strong></div>

        <div className="staff-demo-accounts">
          <div><strong>{copy.demo}</strong><small>{copy.demoHint}</small></div>
          <div className="staff-demo-grid">{roles.map(item=>{const account=DEMO_STAFF_ACCOUNTS[item];return <button type="button" key={item} onClick={()=>fillDemo(item)} className={role===item&&mode==="signin"?"active":""}>
            <span className="staff-demo-icon">{item==="doctor"?"⚕":item==="administration"?"▦":"◇"}</span>
            <span><b>{roleName(item)}</b><small>{account.username}</small></span>
            <span className="staff-demo-use">→</span>
          </button>})}</div>
        </div>
      </div>

      <section className="staff-access-card">
        <div className="staff-access-tabs">
          <button type="button" className={mode==="signin"?"active":""} onClick={()=>{setMode("signin");setError("");setSuccess("")}}>{copy.signin}</button>
          <button type="button" className={mode==="signup"?"active":""} onClick={()=>{setMode("signup");setError("");setSuccess("")}}>{copy.signup}</button>
        </div>

        <form onSubmit={submit} className="staff-access-form">
          {mode==="signup"&&<label className="field"><span>{copy.name}</span><input className="input" value={displayName} onChange={e=>setDisplayName(e.target.value)} autoComplete="name" required minLength={2}/></label>}
          <label className="field"><span>{copy.role}</span><select className="select" value={role} onChange={e=>setRole(e.target.value as StaffRole)}>{roles.map(item=><option key={item} value={item}>{roleName(item)}</option>)}</select></label>
          <label className="field"><span>{copy.username}</span><input className="input" value={username} onChange={e=>setUsername(e.target.value)} autoCapitalize="none" autoComplete="username" required minLength={4}/></label>
          <label className="field"><span>{copy.password}</span><input className="input" type="password" value={password} onChange={e=>setPassword(e.target.value)} autoComplete={mode==="signin"?"current-password":"new-password"} required minLength={8}/></label>
          {error&&<div className="staff-access-alert error">{error}</div>}
          {success&&<div className="staff-access-alert success">{success}</div>}
          <button className="btn btn-primary btn-wide staff-access-submit" disabled={busy}>{busy?"…":mode==="signin"?copy.signin:copy.submitSignup}</button>
        </form>

        <div className="staff-access-security">
          <span>🔒</span>
          <p>{locale==="ar"?"إنشاء الحساب ما يعطي حتى صلاحية آلياً. الطلب يبقى في انتظار موافقة مسؤول.":locale==="en"?"Creating an account never grants a privileged role automatically. New requests stay pending until an administrator approves them.":"La création d’un compte n’accorde jamais automatiquement un rôle privilégié. Toute demande reste en attente d’approbation."}</p>
        </div>
      </section>
    </section>
  </main>;
}