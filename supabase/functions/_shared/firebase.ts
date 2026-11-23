// Shared helpers for the seller Edge Functions.
//
// Authentication is Firebase (not Supabase Auth): every request must carry a
// Firebase ID token in `Authorization: Bearer <token>`. The token is verified
// against Google's Secure Token JWKS, so only tokens minted by our own Firebase
// project (vpnexues-otp-and-img-s) are accepted.

export const FIREBASE_PROJECT_ID = "vpnexues-otp-and-img-s";

export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export interface VerifiedToken {
  uid: string;
  /** Present only for phone-authenticated users. */
  phone: string | null;
  provider: string;
}

let cachedJwks: ReturnType<typeof createJwks> | null = null;

async function createJwks() {
  const { createRemoteJWKSet } = await import(
    "https://esm.sh/jose@5.6.3"
  );
  // Google's Secure Token signer JWKS. NOTE: the older-looking
  // `https://securetoken.google.com/<project-id>/certs` now answers 404, which
  // surfaced as jose's "Expected 200 OK from the JSON Web Key Set HTTP
  // response". This is the documented JWKS endpoint for the same signer keys
  // (the `kid` in every Firebase ID token matches a key in this set).
  const url = new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  );
  return createRemoteJWKSet(url);
}

/**
 * Verifies a Firebase ID token (secure-token issuer) and returns the claims we
 * care about. Throws when the token is missing, expired or forged.
 */
export async function verifyFirebaseToken(
  authorization: string | null,
): Promise<VerifiedToken> {
  if (!authorization || !authorization.startsWith("Bearer ")) {
    throw new Error("Missing Firebase ID token.");
  }
  const token = authorization.slice("Bearer ".length).trim();
  if (!token) throw new Error("Missing Firebase ID token.");

  const { jwtVerify } = await import("https://esm.sh/jose@5.6.3");
  if (!cachedJwks) cachedJwks = await createJwks();

  const { payload } = await jwtVerify(token, cachedJwks, {
    issuer: `https://securetoken.google.com/${FIREBASE_PROJECT_ID}`,
    audience: FIREBASE_PROJECT_ID,
  });

  const uid = typeof payload.sub === "string" ? payload.sub : "";
  if (!uid) throw new Error("Invalid Firebase ID token.");

  const phone =
    typeof payload.phone_number === "string" ? payload.phone_number : null;
  const provider =
    typeof payload.firebase?.sign_in_provider === "string"
      ? payload.firebase.sign_in_provider
      : "";

  return { uid, phone, provider };
}

/** "+91 98421-56789" -> "+919842156789" (best effort, keeps leading +). */
export function normalizeE164(raw: string): string {
  const trimmed = (raw ?? "").trim();
  if (!trimmed) return "";
  const digits = trimmed.replace(/\D/g, "");
  if (!digits) return "";
  return `+${digits}`;
}

/** Digits only, last 10 — used to match legacy rows with mixed formats. */
export function last10(raw: string): string {
  const digits = (raw ?? "").replace(/\D/g, "");
  return digits.length > 10 ? digits.slice(-10) : digits;
}
