import { NextResponse } from "next/server";
import { demoFixtures, demoUuid } from "@/lib/public-demo-seed";
import { approvedDemoUser } from "@/lib/public-demo-access";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

const url = (process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL || "").replace(/\/$/, "");
const key = process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY || "";

async function rest(path: string, init: RequestInit = {}) {
  const headers: Record<string, string> = { apikey: key, "content-type": "application/json", ...init.headers as Record<string,string> };
  if (!key.startsWith("sb_secret_")) headers.Authorization = "Bearer " + key;
  const response = await fetch(url + "/rest/v1/" + path, { ...init, headers, cache: "no-store" });
  const body = await response.json().catch(() => null);
  if (!response.ok) throw new Error("demo_bootstrap_store_failed");
  return body;
}

function fail(code: string, status: number) {
  return NextResponse.json({ error: code }, { status, headers: { "Cache-Control": "no-store" } });
}

export async function POST(req: Request) {
  // This endpoint never accepts client-supplied identity IDs or database keys.
  // The shared demo account is verified by signed-in Auth UID, not by email text.
  if (process.env.PUBLIC_SYNTHETIC_DEMO !== "true") return fail("demo_not_enabled", 503);
  if (!url || !key || !process.env.DEMO_ACCOUNT_USER_ID) return fail("demo_not_configured", 503);
  const bearer = req.headers.get("authorization") || "";
  if (!bearer.startsWith("Bearer ") || bearer.length < 30) return fail("authentication_required", 401);
  const auth = await fetch(url + "/auth/v1/user", {
    headers: { apikey: key, Authorization: bearer }, cache: "no-store",
  });
  if (!auth.ok) return fail("invalid_session", 401);
  const user = await auth.json();
  // Never grant demo provisioning to a random newly registered/anonymous user.
  // Only an admin-created, password-authenticated UID may bootstrap fixtures.
  if (!approvedDemoUser(user, process.env.DEMO_ACCOUNT_USER_ID)) {
    return fail("demo_account_only", 403);
  }

  const caregiverId = demoUuid(user.id, "profile");
  const { patientId, fixtures } = demoFixtures(user.id, caregiverId);
  try {
    // Never repurpose an existing non-demo profile or patient as demo data.
    const existing = await rest("profiles?select=id,is_demo,auth_user_id&id=eq." + caregiverId + "&limit=1");
    if (existing.length && (existing[0].is_demo !== true || existing[0].auth_user_id !== user.id)) {
      return fail("demo_identity_conflict", 409);
    }
    const profile = {
      id: caregiverId, auth_user_id: user.id, full_name: "Demo caregiver (fictional)",
      role: "caregiver", preferred_language: "derja", timezone: "Africa/Tunis",
      is_demo: true, onboarding_completed: true, metadata: { public_demo: true },
    };
    if (!existing.length) {
      await rest("profiles?on_conflict=id", {
        method: "POST", headers: { Prefer: "resolution=merge-duplicates,return=minimal" },
        body: JSON.stringify(profile),
      });
    }
    const patient = await rest("patients?select=id,is_demo,created_by_profile_id&id=eq." + patientId + "&limit=1");
    if (patient.length && (patient[0].is_demo !== true || patient[0].created_by_profile_id !== caregiverId)) {
      return fail("demo_patient_conflict", 409);
    }
    for (const group of fixtures) {
      if (group.table === "patients" && patient.length) continue;
      // Idempotent deterministic inserts: never overwrite guest modifications.
      const ids = group.rows.map(row => row.id).join(",");
      const current = await rest(group.table + "?select=id&id=in.(" + ids + ")");
      const present = new Set((current as Array<{id:string}>).map(row => row.id));
      const missing = group.rows.filter(row => !present.has(String(row.id)));
      if (missing.length) {
        await rest(group.table, {
          method: "POST", headers: { Prefer: "return=minimal" },
          body: JSON.stringify(missing),
        });
      }
    }
    return NextResponse.json({ caregiverId, patientId, synthetic: true }, { headers: { "Cache-Control": "no-store" } });
  } catch {
    return fail("demo_bootstrap_unavailable", 503);
  }
}
