// seller-bank — the ONLY way the updated app touches seller_bank_details.
//
// After 022_bank_lockdown.sql the anon key has no access to bank rows, so all
// reads/writes go through this function (service role, server side only).
//
// Body: { action: "read" | "upsert" | "delete", ... }
//   read:   { userIds: string[] }                       -> { rows: [...] }
//   upsert: { userId, holderName, bankName, accountNumber, ifsc, updateId? }
//                                                   -> { row: {...} }
//   delete: { id }                                     -> { deleted: true }
//
// Authorization — two paths:
//   * WITH a Firebase ID token (after OTP): the caller may only touch rows
//     whose user_id belongs to them (their own registration id, their Firebase
//     UID, or rows for their verified phone) — anything else returns 403.
//   * WITHOUT a token (Sign Up tab's bank step, before any OTP exists —
//     anonymous sign-in was removed from the app): the caller may touch ONLY
//     the `seller_registrations` uuid it presents, and ONLY while that
//     registration is still unclaimed (`firebase_uid IS NULL`). That uuid is
//     a 122-bit random secret created on the device, and it stops working the
//     moment the account is claimed through the Login tab's OTP.
//
// Deploy with:  supabase functions deploy seller-bank --no-verify-jwt

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

/** Ids this token is allowed to read/write. Always its own Firebase UID plus,
 *  for a pending onboarding caller, the registration id it presents (validated
 *  to exist and still unclaimed), plus the `seller_profiles` row ids that
 *  belong to the caller's verified phone number. */
function ownsPhone(
  row: { firebase_uid?: string | null; phone_number?: string | null },
  token: { uid: string; phone: string | null },
): boolean {
  if (row.firebase_uid && row.firebase_uid === token.uid) return true;
  if (!token.phone || !row.phone_number) return false;
  return last10(row.phone_number) === last10(token.phone);
}

async function allowedIds(
  token: { uid: string; phone: string | null },
  presentedUserId: string | null,
): Promise<Set<string>> {
  const ids = new Set<string>([token.uid]);

  if (presentedUserId && presentedUserId !== token.uid) {
    // A pending (or this caller's) registration row.
    const { data: reg } = await supabase
      .from("seller_registrations")
      .select("id, firebase_uid")
      .eq("id", presentedUserId)
      .maybeSingle();
    if (reg && (reg.firebase_uid === null || reg.firebase_uid === token.uid)) {
      ids.add(reg.id);
    }

    // A profile row (created by onboarding before the account was linked).
    const { data: prof } = await supabase
      .from("seller_profiles")
      .select("user_id, firebase_uid, phone_number")
      .eq("user_id", presentedUserId)
      .maybeSingle();
    if (prof && ownsPhone(prof, token)) ids.add(prof.user_id);
  }

  if (token.phone) {
    const suffix = last10(token.phone);
    const e164 = normalizeE164(token.phone);

    // Registrations linked to this Firebase account.
    const { data: regs } = await supabase
      .from("seller_registrations")
      .select("id")
      .eq("firebase_uid", token.uid)
      .limit(10);
    for (const row of regs ?? []) ids.add(row.id);

    // Profile rows for this phone number (exact E.164, then the legacy
    // last-10-digits format old rows were saved in).
    const { data: exact } = await supabase
      .from("seller_profiles")
      .select("user_id, firebase_uid, phone_number")
      .eq("phone_number", e164)
      .limit(10);
    for (const row of exact ?? []) {
      if (ownsPhone(row, token)) ids.add(row.user_id);
    }
    if (suffix.length === 10) {
      const { data: tail } = await supabase
        .from("seller_profiles")
        .select("user_id, firebase_uid, phone_number")
        .like("phone_number", `%${suffix}`)
        .limit(10);
      for (const row of tail ?? []) {
        if (ownsPhone(row, token)) ids.add(row.user_id);
      }
    }
  }

  return ids;
}

/** Ids a **token-less** pre-OTP caller may touch: at most the registration
 *  uuid it presents, and only while that registration is still unclaimed.
 *  Everything else requires a verified phone token. */
async function pendingRegistrationIds(
  presentedUserId: string | null,
): Promise<Set<string>> {
  const ids = new Set<string>();
  if (!presentedUserId) return ids;
  const { data: reg } = await supabase
    .from("seller_registrations")
    .select("id, firebase_uid")
    .eq("id", presentedUserId)
    .maybeSingle();
  if (reg && reg.firebase_uid === null) ids.add(reg.id);
  return ids;
}

function bankRow(userId: string, body: Record<string, unknown>) {
  return {
    user_id: userId,
    account_houlder_name: String(body.holderName ?? "").trim(),
    bank_name: String(body.bankName ?? "").trim(),
    account_number: String(body.accountNumber ?? "").trim(),
    IFSC_code: String(body.ifsc ?? "").trim().toUpperCase(),
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed." }, 405);
  }

  try {
    const authorization = req.headers.get("Authorization");
    const body = await req.json().catch(() => ({}));
    const action = String(body?.action ?? "");
    const presentedUserId =
      typeof body?.userId === "string" && body.userId ? body.userId : null;

    let ids: Set<string>;
    if (authorization && authorization.trim() !== "") {
      // Phone user (after OTP): normal ownership rules, unchanged.
      const token = await verifyFirebaseToken(authorization).catch(() => null);
      if (!token) {
        return json({ error: "Your session expired. Please sign in again." }, 401);
      }
      ids = await allowedIds(token, presentedUserId);
    } else {
      // Pre-OTP path (Sign Up onboarding): no Firebase identity exists yet —
      // anonymous sign-in was removed on purpose. The only door is the
      // unguessable registration uuid, and only while it is unclaimed.
      ids = await pendingRegistrationIds(presentedUserId);
      if (ids.size === 0) return json({ error: "Not authorized." }, 403);
    }

    if (action === "read") {
      const requested: string[] = Array.isArray(body?.userIds)
        ? body.userIds.map(String)
        : [];
      const allowed = requested.filter((id) => ids.has(id));
      if (allowed.length === 0) return json({ rows: [] });
      const { data, error } = await supabase
        .from("seller_bank_details")
        .select("*")
        .in("user_id", allowed)
        .order("id", { ascending: false });
      if (error) throw error;
      return json({ rows: data ?? [] });
    }

    if (action === "upsert") {
      const userId = presentedUserId;
      if (!userId || !ids.has(userId)) {
        return json({ error: "Not authorized." }, 403);
      }
      const row = bankRow(userId, body);
      if (
        !row.account_houlder_name ||
        !row.bank_name ||
        !row.account_number ||
        !row.IFSC_code
      ) {
        return json({ error: "All bank fields are required." }, 400);
      }

      if (body?.updateId != null) {
        const { data, error } = await supabase
          .from("seller_bank_details")
          .update(row)
          .eq("id", body.updateId)
          .eq("user_id", userId)
          .select("*")
          .maybeSingle();
        if (error) throw error;
        if (!data) return json({ error: "Bank account not found." }, 404);
        return json({ row: data });
      }

      const { data, error } = await supabase
        .from("seller_bank_details")
        .insert(row)
        .select("*")
        .single();
      if (error) throw error;
      return json({ row: data });
    }

    if (action === "delete") {
      const id = body?.id;
      if (id == null) return json({ error: "Missing bank account id." }, 400);
      // Scope the delete to rows the caller owns.
      const { data, error } = await supabase
        .from("seller_bank_details")
        .delete()
        .eq("id", id)
        .in("user_id", [...ids])
        .select("id");
      if (error) throw error;
      if (!data || data.length === 0) {
        return json({ error: "Bank account not found." }, 404);
      }
      return json({ deleted: true });
    }

    return json({ error: "Unknown action." }, 400);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unexpected error.";
    const unauthorized = /token/i.test(message);
    return json(
      {
        error: unauthorized
          ? "Your session expired. Please sign in again."
          : "Could not reach the server. Please try again.",
      },
      unauthorized ? 401 : 500,
    );
  }
});
