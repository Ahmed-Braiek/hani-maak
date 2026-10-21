/**
 * A shared demo account is an ordinary, password-authenticated Supabase user.
 * Its immutable auth UID is explicitly configured on the server. Never embed
 * its email/password in client bundles, source, or environment variables.
 */
export function approvedDemoUser(
  user: { id?: unknown; is_anonymous?: unknown } | null | undefined,
  configuredUserId: string | undefined,
): boolean {
  const id = typeof user?.id === "string" ? user.id.toLowerCase() : "";
  const allowedId = (configuredUserId ?? "").trim().toLowerCase();
  return (
    user?.is_anonymous !== true &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/.test(allowedId) &&
    id === allowedId
  );
}
