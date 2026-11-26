-- ============================================================================
-- 07_smoke_test_new_project.sql
-- ============================================================================
-- TARGET : NEW SELLER PROJECT ONLY — run this AFTER restore, sequences,
--          functions, RLS and storage are all in place (end of Phase 12).
-- PURPOSE: Act like the app does, but inside a transaction that is ALWAYS
--          rolled back, so nothing is left behind. It proves the new
--          database behaves the way the Flutter app + edge functions need:
--            * anon (the app's role) can READ the tables the app reads
--            * anon can INSERT where the app inserts
--            * anon is CORRECTLY DENIED on the locked-down tables
--              (seller_bank_details, seller_lookup_rate_limits) — a denial
--              here is SUCCESS, not failure
--            * service_role (the edge functions' role) can read the
--              rate-limit table and call the seller_lookup_registered RPC
-- SAFETY : The whole script runs inside BEGIN ... ROLLBACK. Even the test
--          INSERTs are undone. Nothing persists. Never run it on the OLD
--          project (it would still be read-only in effect, but it is
--          pointless there — this tests the destination).
--
-- HOW TO RUN: NEW project -> SQL Editor -> paste -> Run. Read the NOTICE
--             lines: every "PASS" line must be present. Any "FAIL" line
--             means STOP — do not switch the app yet.
-- ============================================================================

begin;

-- ---------------------------------------------------------------------------
-- T1 — Counts still intact (quick re-check after all the setup steps).
-- ---------------------------------------------------------------------------
do $$
declare
  v_count bigint;
begin
  select count(*) into v_count from public.sellers_products;
  if v_count > 0 then
    raise notice 'PASS T1: sellers_products readable, % rows', v_count;
  else
    raise notice 'FAIL T1: sellers_products is EMPTY (restore did not run?)';
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- T2 — anon can SELECT the tables the Flutter app reads directly.
-- ---------------------------------------------------------------------------
do $$
begin
  set local role anon;
  perform count(*) from public.sellers_products;
  perform count(*) from public.seller_profiles;
  perform count(*) from public.seller_transactions;
  perform count(*) from public.seller_verify_your_details;
  reset role;
  raise notice 'PASS T2: anon can read sellers_products / seller_profiles / seller_transactions / seller_verify_your_details';
exception when others then
  reset role;
  raise notice 'FAIL T2: anon read denied (%) - check grants + RLS policies (05 script)', sqlerrm;
end $$;

-- ---------------------------------------------------------------------------
-- T3 — anon must NOT be able to SELECT seller_registrations (the sign-up
--      table has an INSERT-only policy on purpose: rows are written with
--      return=minimal and never read back). A denial here is CORRECT.
-- ---------------------------------------------------------------------------
do $$
begin
  begin
    set local role anon;
    perform count(*) from public.seller_registrations;
    raise notice 'FAIL T3: anon can read seller_registrations (should be DENIED)';
  exception when insufficient_privilege then
    raise notice 'PASS T3: anon correctly DENIED on seller_registrations';
  end;
  reset role;
end $$;

-- ---------------------------------------------------------------------------
-- T4 — anon must NOT touch seller_bank_details (locked down by 022; only
--      the seller-bank edge function with the service role may). Denial =
--      CORRECT.
-- ---------------------------------------------------------------------------
do $$
begin
  begin
    set local role anon;
    perform count(*) from public.seller_bank_details;
    raise notice 'FAIL T4: anon can read seller_bank_details (should be DENIED)';
  exception when insufficient_privilege then
    raise notice 'PASS T4: anon correctly DENIED on seller_bank_details';
  end;
  reset role;
end $$;

-- ---------------------------------------------------------------------------
-- T5 — anon must NOT touch seller_lookup_rate_limits (no policies at all;
--      service-role only). Denial = CORRECT.
-- ---------------------------------------------------------------------------
do $$
begin
  begin
    set local role anon;
    perform count(*) from public.seller_lookup_rate_limits;
    raise notice 'FAIL T5: anon can read seller_lookup_rate_limits (should be DENIED)';
  exception when insufficient_privilege then
    raise notice 'PASS T5: anon correctly DENIED on seller_lookup_rate_limits';
  end;
  reset role;
end $$;

-- ---------------------------------------------------------------------------
-- T6 — anon can INSERT a seller_registrations row exactly like the Sign Up
--      screen does (Prefer: return=minimal, status='pending', no firebase
--      uid). Rolled back at the end of this script.
-- ---------------------------------------------------------------------------
do $$
begin
  set local role anon;
  insert into public.seller_registrations
    (id, name, phone_e164, status, firebase_uid, phone_verified)
  values
    ('00000000-0000-4000-8000-000000000001', 'SMOKE TEST', '+910000000001',
     'pending', null, false);
  reset role;
  raise notice 'PASS T6: anon can INSERT into seller_registrations (rolled back later)';
exception when others then
  reset role;
  raise notice 'FAIL T6: registration insert denied (%) - check anon_can_register policy', sqlerrm;
end $$;

-- ---------------------------------------------------------------------------
-- T7 — anon can INSERT a wallet transaction (allow-all policy from 017).
--      Rolled back at the end of this script.
-- ---------------------------------------------------------------------------
do $$
begin
  set local role anon;
  insert into public.seller_transactions (user_id, type, amount, title)
  values ('smoke-test-uid', 'credit', 1, 'smoke test - rolled back');
  reset role;
  raise notice 'PASS T7: anon can INSERT into seller_transactions (rolled back later)';
exception when others then
  reset role;
  raise notice 'FAIL T7: transaction insert denied (%) - check 017 policies/grants', sqlerrm;
end $$;

-- ---------------------------------------------------------------------------
-- T8 — service_role (used by all three Supabase edge functions) can read
--      the rate-limit table and CALL the seller_lookup_registered RPC.
-- ---------------------------------------------------------------------------
do $$
declare
  v_rows bigint;
begin
  set local role service_role;
  perform count(*) from public.seller_lookup_rate_limits;
  select count(*) into v_rows
    from public.seller_lookup_registered('+910000000000');
  reset role;
  raise notice 'PASS T8: service_role can read rate limits and call seller_lookup_registered (% result rows)', v_rows;
exception when others then
  reset role;
  raise notice 'FAIL T8: service_role test failed (%) - check function + grants (05 script)', sqlerrm;
end $$;

-- ---------------------------------------------------------------------------
-- Everything above (including the two test INSERTs) is discarded now.
-- The database stays exactly as it was before this script.
-- ---------------------------------------------------------------------------
rollback;

-- ============================================================================
-- END of 07_smoke_test_new_project.sql  (NEW SELLER PROJECT — all rolled back)
-- ============================================================================
