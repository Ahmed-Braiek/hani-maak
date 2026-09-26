const supabaseUrl = (
  process.env.SUPABASE_URL ||
  process.env.NEXT_PUBLIC_SUPABASE_URL
)?.replace(/\/$/, "");

const supabaseKey =
  process.env.SUPABASE_SECRET_KEY ||
  process.env.SUPABASE_SERVICE_ROLE_KEY;

export const DEMO_CAREGIVER_ID =
  "10000000-0000-0000-0000-000000000001";
export const DEMO_PATIENT_ID =
  "30000000-0000-0000-0000-000000000001";

function serviceHeaders(extra: Record<string, string> = {}) {
  if (!supabaseKey) throw new Error("supabase_secret_missing");
  const headers: Record<string, string> = {
    apikey: supabaseKey,
    "content-type": "application/json",
    ...extra,
  };
  if (
    !supabaseKey.startsWith("sb_secret_") &&
    !supabaseKey.startsWith("sb_publishable_")
  ) {
    headers.Authorization = `Bearer ${supabaseKey}`;
  }
  return headers;
}

async function rest(path: string) {
  if (!supabaseUrl || !supabaseKey) {
    throw new Error("supabase_not_configured");
  }
  const response = await fetch(`${supabaseUrl}/rest/v1/${path}`, {
    headers: serviceHeaders(),
    cache: "no-store",
  });
  const raw = await response.text();
  const body = raw ? JSON.parse(raw) : null;
  if (!response.ok) {
    throw new Error(
      body?.message || body?.error || `supabase_http_${response.status}`,
    );
  }
  return body;
}

export async function verifyCaregiverAccess(
  req: Request,
  caregiverId: string,
  patientId: string,
) {
  if (
    caregiverId === DEMO_CAREGIVER_ID &&
    patientId === DEMO_PATIENT_ID
  ) {
    return { demo: true as const, userId: null };
  }

  if (!supabaseUrl || !supabaseKey) {
    throw new Error("supabase_not_configured");
  }

  const authorization = req.headers.get("authorization") || "";
  if (!authorization.startsWith("Bearer ")) {
    throw new Error("authentication_required");
  }

  const userResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: {
      apikey: supabaseKey,
      Authorization: authorization,
    },
    cache: "no-store",
  });
  if (!userResponse.ok) throw new Error("invalid_session");
  const user = await userResponse.json();

  const profileRows = await rest(
    `profiles?select=id&auth_user_id=eq.${encodeURIComponent(user.id)}&id=eq.${encodeURIComponent(caregiverId)}&limit=1`,
  );
  if (!Array.isArray(profileRows) || !profileRows.length) {
    throw new Error("caregiver_identity_mismatch");
  }

  const relationshipRows = await rest(
    `caregiver_patient_relationships?select=id&caregiver_profile_id=eq.${encodeURIComponent(caregiverId)}&patient_id=eq.${encodeURIComponent(patientId)}&access_status=eq.active&limit=1`,
  );
  if (!Array.isArray(relationshipRows) || !relationshipRows.length) {
    throw new Error("caregiver_patient_access_denied");
  }

  return { demo: false as const, userId: String(user.id) };
}

export function caregiverAuthStatus(error: unknown) {
  const message =
    error instanceof Error ? error.message : "caregiver_auth_failed";
  if (
    /authentication_required|invalid_session|identity_mismatch|access_denied/.test(
      message,
    )
  ) {
    return 401;
  }
  if (/not_configured|secret_missing/.test(message)) return 503;
  return 500;
}
