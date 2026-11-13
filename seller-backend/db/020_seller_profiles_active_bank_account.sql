-- Migration 020: seller_profiles.active_bank_account_id
--
-- WHERE TO RUN IT:
--   https://supabase.com/dashboard/project/ouzxglznpjeewdyxputa/sql
--   The app's anon key points at project ref `ouzxglznpjeewdyxputa`. The
--   script below raises an exception in any other project instead of
--   changing the wrong database.
--
-- WHY THIS EXISTS:
--   The app persists the seller's primary bank account with
--   `PATCH /rest/v1/seller_profiles {active_bank_account_id}` from
--   `SupabaseProductApi.updateActiveBankAccountId()` and reads it back with
--   `getActiveBankAccountId()`. The column was never created, so every call
--   failed with:
--
--     400 {"code":"42703",
--          "message":"column seller_profiles.active_bank_account_id does not exist"}
--
--   The screens swallowed that error ("best-effort persistence"), which is
--   why "Set primary" looked like it worked in the UI but reset every time
--   the page was reopened, and the primary account was never restored on
--   login.
--
-- WHAT IT DOES:
--   1. adds `active_bank_account_id text` (nullable) to seller_profiles
--   2. keeps the same write grants 009/016 set up (re-running is a no-op)
--   3. reloads PostgREST's schema cache so the new column is visible to the
--      app (otherwise PGRST204 "Could not find the 'active_bank_account_id'
--      column")
--
-- SUCCESS LOOKS LIKE: the notices below, then one row in the proof grid:
--   active_bank_account_id   text   (nullable).

do $$
begin
  if to_regclass('public.seller_profiles') is null then
    raise exception 'WRONG PROJECT: public.seller_profiles does not exist here. Open https://supabase.com/dashboard/project/ouzxglznpjeewdyxputa/sql and run this file there.';
  end if;

  if not exists (
    select 1 from information_schema.columns
     where table_schema = 'public'
       and table_name   = 'seller_profiles'
       and column_name  = 'business_name'
  ) then
    raise exception 'WRONG PROJECT: 009_seller_profiles_write.sql has never run here, so the app does not use this database. Switch to project ouzxglznpjeewdyxputa and run this file again.';
  end if;

  raise notice 'Migration 020 running (seller_profiles.active_bank_account_id)';

  if not exists (
    select 1 from information_schema.columns
     where table_schema = 'public'
       and table_name   = 'seller_profiles'
       and column_name  = 'active_bank_account_id'
  ) then
    alter table public.seller_profiles add column active_bank_account_id text;
    raise notice 'Migration 020: active_bank_account_id column added';
  else
    raise notice 'Migration 020: active_bank_account_id column already exists';
  end if;

  -- Same write grants 009/016 set up (re-running is a no-op).
  execute 'grant select, insert, update on public.seller_profiles to anon, authenticated, service_role';

  -- Without this PostgREST keeps serving the old schema and the app fails
  -- with PGRST204 on the new column.
  perform pg_notify('pgrst', 'reload schema');

  raise notice 'Migration 020 done';
end $$;

-- Proof grid: expect exactly one row -
--   active_bank_account_id   text   (nullable)
select
  a.attname                                     as column_name,
  format_type(a.atttypid, a.atttypmod)          as data_type,
  a.attnotnull                                  as not_null
 from pg_attribute a
 where a.attrelid = 'public.seller_profiles'::regclass
   and a.attnum > 0
   and not a.attisdropped
   and a.attname = 'active_bank_account_id';
