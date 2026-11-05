-- Migration 014: seller_profiles.fcm_token (Firebase Cloud Messaging token)
--
-- WHERE TO RUN IT:
--   https://supabase.com/dashboard/project/ouzxglznpjeewdyxputa/sql
--   The app's anon key points at project ref `ouzxglznpjeewdyxputa`. Any
--   other project (for example "vpnexuesprivatelimited-alt's Project") is
--   the wrong database - the script below raises an exception there instead
--   of changing it.
--
-- WHAT IT DOES:
--   Adds `seller_profiles.fcm_token`, where the app stores the device's FCM
--   token after login so a push backend can address the device later.
--
-- SUCCESS LOOKS LIKE: notices from the DO block, then a grid with one row
--   (column_name = fcm_token, data_type = text, apps_project = ouzxglznpjeewdyxputa)
--   and rls_enabled = f.
--
-- Until this runs the app still works: the token save fails, is logged to the
-- console as "could not save FCM token" and is retried on the next start.

do $$
begin
  -- Fingerprint: 009 added seller_profiles.business_name in the app's
  -- project. Without it this is the wrong database.
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

  raise notice 'Migration 014 running (seller_profiles.fcm_token)';

  if not exists (
    select 1 from information_schema.columns
     where table_schema = 'public'
       and table_name   = 'seller_profiles'
       and column_name  = 'fcm_token'
  ) then
    alter table public.seller_profiles add column fcm_token text;
    raise notice 'Migration 014: fcm_token column added';
  else
    raise notice 'Migration 014: fcm_token column already exists';
  end if;

  -- Same write grants 009 set up (re-running is a no-op).
  execute 'grant select, insert, update on public.seller_profiles to anon, authenticated, service_role';

  -- Reload PostgREST's schema cache, otherwise the new column is invisible
  -- to the app (PGRST204 "Could not find the 'fcm_token' column").
  perform pg_notify('pgrst', 'reload schema');

  raise notice 'Migration 014 done';
end $$;

-- Proof grid: expect exactly one row with data_type = text and rls_enabled = f.
select
  'ouzxglznpjeewdyxputa'::text as apps_project,
  (select c.relrowsecurity
     from pg_class c
    where c.oid = 'public.seller_profiles'::regclass) as rls_enabled,
  cols.column_name,
  cols.data_type
from information_schema.columns cols
where cols.table_schema = 'public'
  and cols.table_name   = 'seller_profiles'
  and cols.column_name  = 'fcm_token';
