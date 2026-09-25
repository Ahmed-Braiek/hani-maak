import { NextResponse } from "next/server";
import { caregiverContext, caregiverSupplement } from "@/app/api/v1/caregiver-agent/tools/route";

export const dynamic = "force-dynamic";

const DEMO_CAREGIVER = "10000000-0000-0000-0000-000000000001";
const DEMO_PATIENT = "30000000-0000-0000-0000-000000000001";

export async function GET() {
  try {
    const [data, extra] = await Promise.all([\n      caregiverContext(DEMO_CAREGIVER, DEMO_PATIENT),\n      caregiverSupplement(DEMO_CAREGIVER, DEMO_PATIENT),\n    ]);\n    return NextResponse.json({ success: true, data: { ...data, ...extra } });
  } catch (error) {
    console.error("caregiver demo context failed", error);
    return NextResponse.json(
      { success: false, error: "caregiver_demo_context_failed" },
      { status: 500 },
    );
  }
}
