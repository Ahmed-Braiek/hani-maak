import { NextResponse } from "next/server";
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

  // Preserve the existing Mariem / Fatma synthetic scenario, including its
  // care circle, tasks, medications, conversations and linked helpers.
  const caregiverId = "10000000-0000-0000-0000-000000000001";
  const patientId = "30000000-0000-0000-0000-000000000001";
  try {
    const profiles = await rest(
      "profiles?select=id,is_demo,auth_user_id&id=eq." + caregiverId + "&limit=1",
    );
    const patients = await rest(
      "patients?select=id,is_demo,created_by_profile_id&id=eq." + patientId + "&limit=1",
    );
    const relationships = await rest(
      "caregiver_patient_relationships?select=id,access_status&caregiver_profile_id=eq." +
        caregiverId + "&patient_id=eq." + patientId + "&limit=1",
    );
    const profile = profiles[0];
    const patient = patients[0];
    const relationship = relationships[0];

    if (
      !profile || profile.is_demo !== true ||
      !patient || patient.is_demo !== true ||
      patient.created_by_profile_id !== caregiverId ||
      !relationship || relationship.access_status !== "active"
    ) return fail("demo_scenario_not_verified", 409);

    if (profile.auth_user_id && profile.auth_user_id !== user.id) {
      return fail("demo_identity_already_linked", 409);
    }

    // One-time assignment of the verified synthetic caregiver to the
    // explicitly allowlisted Supabase Auth account.
    if (!profile.auth_user_id) {
      await rest("profiles?id=eq." + caregiverId + "&auth_user_id=is.null", {
        method: "PATCH",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({ auth_user_id: user.id }),
      }).then((updated) => {
        if (!Array.isArray(updated) || updated.length !== 1) {
          throw new Error("demo_identity_link_conflict");
        }
      });
    }

    return NextResponse.json(
      { caregiverId, patientId, synthetic: true, scenario: "mariem-fatma" },
      { headers: { "Cache-Control": "no-store" } },
    );
  } catch {
    return fail("demo_bootstrap_unavailable", 503);
  }
}
