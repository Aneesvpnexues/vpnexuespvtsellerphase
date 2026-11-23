// seller-registration-status
//
// Called by the Login screen BEFORE any OTP is sent:
//   { phone: "+919842156789" }  ->  { registered: true | false }
//
// Security:
//   * The Firebase ID token is OPTIONAL. Anonymous sign-in was removed from
//     the app (the Firebase project must only contain phone users), and this
//     lookup runs before any phone user exists — so the real safeguards are:
//   * Rate limited per phone number and per IP (seller_lookup_rate_limits).
//   * Returns ONLY a boolean — no names, no ids, no way to enumerate users.
//   * A token that IS presented must still be valid (a stale/garbage token is
//     rejected with 401 rather than silently ignored).
//
// Deploy with:  supabase functions deploy seller-registration-status --no-verify-jwt

import { createClient } from "npm:@supabase/supabase-js@2";
import {
  corsHeaders,
  json,
  last10,
  normalizeE164,
  verifyFirebaseToken,
} from "../_shared/firebase.ts";

const PHONE_LIMIT_PER_HOUR = 5;
const IP_LIMIT_PER_HOUR = 30;

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false } },
);

/** Sliding one-hour window counter. Returns false when the limit is hit. */
async function rateLimit(key: string, limit: number): Promise<boolean> {
  const now = new Date();
  const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);

  const { data, error } = await supabase
    .from("seller_lookup_rate_limits")
    .select("key, window_start, count")
    .eq("key", key)
    .maybeSingle();
  if (error) return true; // fail open: availability over strict limiting

  if (!data || new Date(data.window_start) <= oneHourAgo) {
    await supabase.from("seller_lookup_rate_limits").upsert(
      { key, window_start: now.toISOString(), count: 1 },
      { onConflict: "key" },
    );
    return true;
  }
  if (data.count >= limit) return false;

  await supabase.from("seller_lookup_rate_limits").upsert(
    { key, count: data.count + 1 },
    { onConflict: "key" },
  );
  return true;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed." }, 405);
  }

  try {
    // 1. Identity is OPTIONAL (anonymous sign-in was removed; this lookup
    //    happens before any phone user exists). A token that is presented
    //    must still be valid — only the rate limits below gate the answer.
    const authorization = req.headers.get("Authorization");
    if (authorization && authorization.trim() !== "") {
      const valid = await verifyFirebaseToken(authorization)
        .then(() => true)
        .catch(() => false);
      if (!valid) {
        return json({ error: "Your session expired. Please try again." }, 401);
      }
    }

    // 2. Rate limits (phone + IP) before touching any data.
    const body = await req.json().catch(() => ({}));
    const phone = normalizeE164(String(body?.phone ?? ""));
    if (phone.replace(/\D/g, "").length < 8) {
      return json({ error: "Enter a valid phone number." }, 400);
    }

    const ip =
      req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
      req.headers.get("x-real-ip") ||
      "unknown";

    const phoneOk = await rateLimit(`phone:${phone}`, PHONE_LIMIT_PER_HOUR);
    const ipOk = await rateLimit(`ip:${ip}`, IP_LIMIT_PER_HOUR);
    if (!phoneOk || !ipOk) {
      return json(
        { error: "Too many attempts. Please try again later." },
        429,
      );
    }

    // 3. Look the number up through the service-role-only SQL function.
    const { data, error } = await supabase.rpc("seller_lookup_registered", {
      p_phone: phone,
    });
    if (error) {
      console.error("seller_lookup_registered failed:", error.message);
      return json({ error: "Could not check the number right now." }, 500);
    }

    const registered = Array.isArray(data) && data.length > 0;
    return json({ registered });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unexpected error.";
    const unauthorized = /token/i.test(message);
    return json(
      { error: unauthorized ? "Your session expired. Please try again." : message },
      unauthorized ? 401 : 400,
    );
  }
});
