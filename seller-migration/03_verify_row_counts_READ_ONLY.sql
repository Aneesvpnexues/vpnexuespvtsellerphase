-- ============================================================================
-- 03_verify_row_counts_READ_ONLY.sql
-- ============================================================================
-- TARGET : Run on BOTH projects, separately:
--            1) OLD PROJECT          *** READ ONLY ***
--            2) NEW SELLER PROJECT   (also read-only in this script)
--          Compare the two outputs side by side. They MUST match.
-- PURPOSE: Prove that not one single Seller record was lost, added or
--          changed during the copy.
-- SAFETY : ONLY SELECT statements. Safe on the old project.
--
-- HOW TO RUN:
--   OLD  -> Dashboard of the OLD project          -> SQL Editor -> Run
--           -> save output as VERIFY-OLD.txt
--   NEW  -> Dashboard of the NEW Seller project   -> SQL Editor -> Run
--           -> save output as VERIFY-NEW.txt
--   Open both files side by side (Notepad is fine) and compare every number.
--
-- HOW TO READ THE RESULTS:
--   row_count         = number of rows. Must be IDENTICAL in both projects.
--   distinct_*        = number of distinct owners/phones. Must match.
--   min_id / max_id   = smallest/largest id. Must match (proves no rows
--                       were skipped and ids were preserved).
--   sum_amount        = total of all money amounts. Must match.
--   content_checksum  = an md5 "fingerprint" of the entire table content.
--                       If ANY cell in ANY row differs, this hash differs.
--   CAVEAT: the fingerprint is computed from PostgreSQL's text rendering of
--           each row. If the two projects run DIFFERENT PostgreSQL major
--           versions, a hash may differ even when the data is identical —
--           in that case trust row_count / min_id / max_id / sum_amount
--           (these are version-independent) as the primary proof.
--   If ANY row_count differs -> STOP. Do not switch the app. Re-check
--   Phase 5 (restore) for that table. Never "fix" anything in the old
--   project — the fix always happens in the NEW project only.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) sellers_products  (Seller product catalog)
-- ---------------------------------------------------------------------------
select 'sellers_products' as table_name,
       count(*)                        as row_count,
       count(distinct user_id)         as distinct_sellers,
       min(id)                         as min_id,
       max(id)                         as max_id,
       md5(string_agg((t)::text, E'\n' order by (t)::text)) as content_checksum
from public.sellers_products t;

-- ---------------------------------------------------------------------------
-- 2) seller_profiles  (one row per seller: business profile, location, FCM)
-- ---------------------------------------------------------------------------
select 'seller_profiles' as table_name,
       count(*)                                   as row_count,
       count(distinct user_id)                    as distinct_profiles,
       count(*) filter (where firebase_uid is not null) as linked_to_firebase,
       md5(string_agg((t)::text, E'\n' order by (t)::text)) as content_checksum
from public.seller_profiles t;

-- ---------------------------------------------------------------------------
-- 3) seller_registrations  (pre-OTP sign-up records)
-- ---------------------------------------------------------------------------
select 'seller_registrations' as table_name,
       count(*)                                as row_count,
       count(distinct phone_e164)              as distinct_phones,
       count(*) filter (where status = 'linked') as linked_count,
       count(*) filter (where firebase_uid is not null) as with_firebase_uid,
       md5(string_agg((t)::text, E'\n' order by (t)::text)) as content_checksum
from public.seller_registrations t;

-- ---------------------------------------------------------------------------
-- 4) seller_verify_your_details  (KYC document metadata)
-- ---------------------------------------------------------------------------
select 'seller_verify_your_details' as table_name,
       count(*)                    as row_count,
       count(distinct user_id)     as distinct_sellers,
       md5(string_agg((t)::text, E'\n' order by (t)::text)) as content_checksum
from public.seller_verify_your_details t;

-- ---------------------------------------------------------------------------
-- 5) seller_bank_details  (bank accounts — the table with legacy
--    millisecond-timestamp ids, hence min_id/max_id are big numbers)
-- ---------------------------------------------------------------------------
select 'seller_bank_details' as table_name,
       count(*)                    as row_count,
       count(distinct user_id)     as distinct_sellers,
       min(id)                     as min_id,
       max(id)                     as max_id,
       md5(string_agg((t)::text, E'\n' order by (t)::text)) as content_checksum
from public.seller_bank_details t;

-- ---------------------------------------------------------------------------
-- 6) seller_transactions  (wallet ledger)
-- ---------------------------------------------------------------------------
select 'seller_transactions' as table_name,
       count(*)                        as row_count,
       count(distinct user_id)         as distinct_sellers,
       min(id)                         as min_id,
       max(id)                         as max_id,
       sum(amount)                     as sum_amount,
       count(*) filter (where type = 'credit')     as credit_count,
       count(*) filter (where type = 'withdrawal') as withdrawal_count,
       md5(string_agg((t)::text, E'\n' order by (t)::text)) as content_checksum
from public.seller_transactions t;

-- ---------------------------------------------------------------------------
-- 7) seller_lookup_rate_limits  (login rate-limit counters; small table,
--    may legitimately be empty or have fresher rows in OLD if someone
--    logged in during migration — see note below)
-- ---------------------------------------------------------------------------
select 'seller_lookup_rate_limits' as table_name,
       count(*)                    as row_count,
       count(distinct key)         as distinct_keys,
       max(window_start)           as latest_window,
       md5(string_agg((t)::text, E'\n' order by (t)::text)) as content_checksum
from public.seller_lookup_rate_limits t;
-- NOTE on this table: it stores short-lived "phone:/ip:" counters. If the
-- live app still writes to the OLD project while you migrate, its count can
-- grow between your two runs. That is NOT data loss. This table's rows are
-- disposable by design; exact equality is expected only if no one used the
-- app during the migration window (recommended: migrate during downtime).

-- ============================================================================
-- END of 03_verify_row_counts_READ_ONLY.sql  (run on BOTH, compare)
-- ============================================================================
