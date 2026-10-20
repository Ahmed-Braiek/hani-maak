import { NextRequest, NextResponse } from "next/server";
import { allowLocalDemoAccess, isLegacyEndpoint } from "./lib/demo-access-policy";

/**
 * The caregiver-first app uses separate /api/v1/caregiver-* and /api/v1/heni/*
 * APIs. Older competition patient/staff/demo endpoints have no reliable
 * tenant-scoped authentication and must not access the shared production store.
 */
export function proxy(request: NextRequest) {
  if (isLegacyEndpoint(request.nextUrl.pathname) && !allowLocalDemoAccess()) {
    return NextResponse.json(
      { error: "legacy_demo_endpoint_disabled" },
      { status: 404, headers: { "Cache-Control": "no-store" } },
    );
  }
  return NextResponse.next();
}

export const config = {
  matcher: ["/api/v1/:path*", "/api/webhooks/telephony/:path*"],
};
