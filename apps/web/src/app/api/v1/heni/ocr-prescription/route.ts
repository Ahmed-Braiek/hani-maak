import { NextResponse } from "next/server";
import {
  caregiverAuthStatus,
  DEMO_CAREGIVER_ID,
  DEMO_PATIENT_ID,
  verifyCaregiverAccess,
} from "@/lib/caregiver-access";

export const runtime = "nodejs";

function cors(res: NextResponse) {
  res.headers.set("Access-Control-Allow-Origin", "*");
  res.headers.set("Access-Control-Allow-Methods", "POST,OPTIONS");
  res.headers.set("Access-Control-Allow-Headers", "content-type,authorization");
  return res;
}

export async function OPTIONS() {
  return cors(new NextResponse(null, { status: 204 }));
}

export async function POST(req: Request) {
  const base = process.env.HENI_AGENT_BASE_URL?.replace(/\/$/, "");
  const secret = process.env.HENI_AGENT_SHARED_SECRET;
  if (!base || !secret) {
    return cors(
      NextResponse.json(
        { error: "heni_agent_not_configured" },
        { status: 503 },
      ),
    );
  }

  try {
    const body = await req.json();
    const caregiverId = String(
      body?.caregiverId || DEMO_CAREGIVER_ID,
    );
    const patientId = String(
      body?.patientId || DEMO_PATIENT_ID,
    );
    await verifyCaregiverAccess(req, caregiverId, patientId);

    const response = await fetch(`${base}/v1/ocr-prescription`, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-heni-agent-key": secret,
      },
      body: JSON.stringify({
        imageBase64: body?.imageBase64,
        mimeType: body?.mimeType || "image/jpeg",
        documentType: body?.documentType || "prescription",
        locale: body?.locale || "tn",
      }),
      cache: "no-store",
      signal: AbortSignal.timeout(45000),
    });

    const text = await response.text();
    let payload: unknown = null;
    try {
      payload = text ? JSON.parse(text) : null;
    } catch {
      payload = { error: text || "ocr_invalid_response" };
    }

    return cors(
      NextResponse.json(payload, { status: response.status }),
    );
  } catch (error) {
    const status = caregiverAuthStatus(error);
    return cors(
      NextResponse.json(
        {
          error:
            error instanceof Error ? error.message : "ocr_failed",
        },
        { status },
      ),
    );
  }
}
