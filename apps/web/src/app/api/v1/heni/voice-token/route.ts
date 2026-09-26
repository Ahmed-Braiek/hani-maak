import { createHmac, randomUUID } from "node:crypto";
import { NextResponse } from "next/server";
import {
  caregiverAuthStatus,
  DEMO_CAREGIVER_ID,
  DEMO_PATIENT_ID,
  verifyCaregiverAccess,
} from "@/lib/caregiver-access";

export const dynamic = "force-dynamic";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST,OPTIONS",
  "Access-Control-Allow-Headers": "*",
  "Access-Control-Max-Age": "86400",
};

function b64url(value: Buffer | string) {
  return Buffer.from(value).toString("base64url");
}

function websocketBase() {
  const explicit = process.env.HENI_AGENT_WSS_URL?.trim().replace(/\/$/, "");
  if (explicit) return explicit;

  const base = process.env.HENI_AGENT_BASE_URL?.trim().replace(/\/$/, "");
  if (!base) return "";

  if (base.startsWith("https://")) return `wss://${base.slice(8)}`;
  if (base.startsWith("http://")) return `ws://${base.slice(7)}`;
  return base;
}

function withCors(response: NextResponse) {
  for (const [key, value] of Object.entries(CORS_HEADERS)) {
    response.headers.set(key, value);
  }
  return response;
}

export async function OPTIONS() {
  return new Response(null, {
    status: 204,
    headers: CORS_HEADERS,
  });
}

export async function POST(req: Request) {
  const secret = process.env.HENI_AGENT_SHARED_SECRET;
  const wsBase = websocketBase();

  if (!secret || !wsBase) {
    return withCors(
      NextResponse.json(
        { error: "live_voice_not_configured" },
        { status: 503 },
      ),
    );
  }

  const body = await req.json().catch(() => ({}));

  const locale =
    body?.locale === "tn" ||
    body?.locale === "fr" ||
    body?.locale === "en" ||
    body?.locale === "ar"
      ? body.locale
      : "ar";

  const now = Math.floor(Date.now() / 1000);
  const exp = now + 120;

  const caregiverId = String(
    body?.caregiverId || DEMO_CAREGIVER_ID,
  );

  const patientId = String(
    body?.patientId || DEMO_PATIENT_ID,
  );

  try {
    await verifyCaregiverAccess(req, caregiverId, patientId);
  } catch (error) {
    return withCors(
      NextResponse.json(
        {
          error:
            error instanceof Error
              ? error.message
              : "caregiver_auth_failed",
        },
        { status: caregiverAuthStatus(error) },
      ),
    );
  }

  const payload = {
    sid: randomUUID(),
    patientId,
    caregiverId,
    locale,
    iat: now,
    exp,
  };

  const encoded = b64url(JSON.stringify(payload));
  const signature = createHmac("sha256", secret)
    .update(encoded)
    .digest("base64url");

  const token = `${encoded}.${signature}`;

  return withCors(
    NextResponse.json({
      token,
      wsUrl: `${wsBase}/ws/voice`,
      sessionId: payload.sid,
      expiresAt: new Date(exp * 1000).toISOString(),
    }),
  );
}
