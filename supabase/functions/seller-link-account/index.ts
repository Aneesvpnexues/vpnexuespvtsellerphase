// seller-link-account
//
// Called ONCE, right after the user verifies their OTP on the Login screen.
// Body: {} (everything comes from the verified Firebase ID token).
//
// What it does:
//   1. Verifies the Firebase ID token and reads the phone number that Firebase
//      itself verified (never a client-supplied phone) — so nobody can claim
//      someone else's pending registration just by knowing their number.
//   2. Finds the matching seller_registrations row (exact E.164, then the
//      legacy last-10-digits fallback for old mixed-format rows).
//   3. Links it: firebase_uid, status='linked', phone_verified=true.
//   4. Marks the matching seller_profiles row verified + linked to the UID.
//   5. Returns { registered, userId } so the app can restore the profile.
//
// Deploy with:  supabase functions deploy seller-link-account --no-verify-jwt

import { createClient } from "npm:@supabase/supabase-js@2";
import {
  corsHeaders,
  json,
  last10,
  normalizeE164,
  verifyFirebaseToken,
} from "../_shared/firebase.ts";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false } },
);

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed." }, 405);
  }

  try {
    const token = await verifyFirebaseToken(req.headers.get("Authorization"));

    // Phone-authenticated users only: an anonymous token has no phone claim
    // and must never be able to link anything.
    if (!token.phone) {
      return json({ error: "Phone verification required." }, 401);
    }

    const e164 = normalizeE164(token.phone);
    const suffix = last10(token.phone);

    // 1. Pending registration by exact E.164, then by last-10 fallback.
    let registration = null;
    {
      const exact = await supabase
        .from("seller_registrations")
        .select("id, phone_e164, status, firebase_uid")
        .eq("phone_e164", e164)
        .maybeSingle();
      registration = exact.data;
      if (!registration && exact.error) throw exact.error;
    }
    if (!registration && suffix.length === 10) {
      const { data, error } = await supabase
        .from("seller_registrations")
        .select("id, phone_e164, status, firebase_uid")
        .filter("phone_e164", "like", `%${suffix}`)
        .limit(1);
      if (error) throw error;
      registration = data?.[0] ?? null;
    }

    // 2. Legacy user: no registration row, but a seller_profiles row exists
    //    (accounts created before this flow). Link that instead.
    let profile = null;
    {
      const { data, error } = await supabase
        .from("seller_profiles")
        .select("user_id, phone_number, firebase_uid, display_name")
        .eq("firebase_uid", token.uid)
        .maybeSingle();
      if (error) throw error;
      profile = data;
    }
    if (!profile) {
      const { data, error } = await supabase
        .from("seller_profiles")
        .select("user_id, phone_number, firebase_uid, display_name")
        .eq("phone_number", e164)
        .limit(1);
      if (error) throw error;
      profile = data?.[0] ?? null;
      if (!profile && suffix.length === 10) {
        const { data: rows, error: err2 } = await supabase
          .from("seller_profiles")
          .select("user_id, phone_number, firebase_uid, display_name")
          .filter("phone_number", "like", `%${suffix}`)
          .limit(1);
        if (err2) throw err2;
        profile = rows?.[0] ?? null;
      }
    }

    if (!registration && !profile) {
      // Number was never registered — the Login screen should have caught
      // this, but never link anything blindly.
      return json({ registered: false });
    }

    // 3. Link the registration row to the verified Firebase UID.
    //
    // Written unconditionally (the row was matched by the token's own phone
    // claim, so this UID is the current owner of that number). A
    // `firebase_uid <> uid` filter would look equivalent but is NOT: for a
    // pending row `firebase_uid IS NULL`, `NULL <> uid` evaluates to NULL
    // and the row would be skipped — the link would silently never happen.
    if (registration) {
      const { error } = await supabase
        .from("seller_registrations")
        .update({
          firebase_uid: token.uid,
          status: "linked",
          phone_verified: true,
          updated_at: new Date().toISOString(),
        })
        .eq("id", registration.id);
      if (error) throw error;
    }

    // 4. Mark the profile verified + associated with the UID.
    if (profile) {
      const patch: Record<string, unknown> = {
        firebase_uid: token.uid,
        verified: true,
        updated_at: new Date().toISOString(),
      };
      // A row found without a phone number gets the verified one now, so the
      // next login can find it by phone as well as by UID.
      if (!profile.phone_number) patch.phone_number = e164;
      const { error } = await supabase
        .from("seller_profiles")
        .update(patch)
        .eq("user_id", profile.user_id);
      if (error) throw error;
    }

    const userId = profile?.user_id ?? registration?.id ?? null;
    const kind = profile
      ? "profile"
      : registration
      ? "registration"
      : "";
    return json({ registered: true, userId, kind });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unexpected error.";
    const unauthorized = /token|Phone verification/i.test(message);
    return json(
      {
        error: unauthorized
          ? "Your session expired. Please sign in again."
          : "Could not finish signing you in.",
      },
      unauthorized ? 401 : 500,
    );
  }
});
