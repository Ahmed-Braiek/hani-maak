import type { NextConfig } from "next";

const securityHeaders = [
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "X-Frame-Options", value: "DENY" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  { key: "Permissions-Policy", value: "camera=(self), microphone=(self), geolocation=(self)" },
  { key: "Cross-Origin-Opener-Policy", value: "same-origin" }
];

const unrestrictedDevCors = [
  { key: "Access-Control-Allow-Origin", value: "*" },
  { key: "Access-Control-Allow-Methods", value: "GET,POST,PUT,PATCH,DELETE,OPTIONS" },
  { key: "Access-Control-Allow-Headers", value: "*" },
  { key: "Access-Control-Max-Age", value: "86400" }
];

const nextConfig: NextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  async headers() {
    const rules = [{ source: "/:path*", headers: securityHeaders }];

    if (process.env.NODE_ENV !== "production") {
      rules.push({
        source: "/api/:path*",
        headers: unrestrictedDevCors
      });
    }

    return rules;
  }
};

export default nextConfig;
