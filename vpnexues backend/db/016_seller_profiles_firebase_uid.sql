-- Migration 016: seller_profiles.firebase_uid
--
-- WHERE TO RUN IT:
--   https://supabase.com/dashboard/project/ouzxglznpjeewdyxputa/sql
--   The app's anon key points at project ref `ouzxglznpjeewdyxputa`. The
--   script below raises an exception in any other project instead of
--   changing the wrong database.
--
-- WHY THIS EXISTS:
--   `seller_profiles.user_id` is a Postgres `uuid` left over from the auth
--   era. This app signs in with Firebase Phone Auth, whose UID is a
--   28-character alphanumeric string, e.g.
--
--     CebmFO5Z4UfEZTh3JaRJZdLCruZ2
--
--   Writing or filtering that value on a `uuid` column fails with:
--
--     invalid input syntax for type uuid: "CebmFO5Z4UfEZTh3JaRJZdLCruZ2"
--
--   which the app surfaced as "Could not save business profile" and
--   "could not save FCM token", and which made every profile lookup miss so
--   returning sellers were sent through onboarding again.
--
--   Migration 015 already solved this for `sellers_products` by making
--   `user_id` text. This file does it for the profile row the same way:
--   `user_id` keeps its uuid value as the row's legacy key (bank and KYC
--   rows still join to it), and the Firebase Auth UID moves to a new
--   `firebase_uid` text column that the app reads and writes.
--
-- WHAT IT DOES:
--   1. adds `firebase_uid text` (nullable, unique - multiple NULLs allowed)
--   2. gives `user_id` a `gen_random_uuid()` default so a new row can be
--      inserted without the client supplying a uuid
--   3. reloads PostgREST's schema cache so the new column is visible to the
--      app (otherwise PGRST204 "Could not find the 'firebase_uid' column")
--
-- SUCCESS LOOKS LIKE: notices from the DO block, then a two-row grid with
--   column_name user_id / firebase_uid, data_type uuid / text.

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

  raise notice 'Migration 016 running (seller_profiles.firebase_uid)';

  -- 1. The Firebase Auth UID column.
  if not exists (
    select 1 from information_schema.columns
     where table_schema = 'public'
       and table_name   = 'seller_profiles'
       and column_name  = 'firebase_uid'
  ) then
    alter table public.seller_profiles add column firebase_uid text;
    raise notice 'Migration 016: firebase_uid column added';
  else
    raise notice 'Migration 016: firebase_uid column already exists';
  end if;

  -- 2. `user_id` must be insertable without a client-supplied uuid.
  --    An identity column cannot take a default, so drop it first.
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public'
       and table_name   = 'seller_profiles'
       and column_name  = 'user_id'
       and is_identity  = 'YES'
  ) then
    alter table public.seller_profiles alter column user_id drop identity;
    raise notice 'Migration 016: identity dropped from user_id';
  end if;

  alter table public.seller_profiles
    alter column user_id set default gen_random_uuid();
  raise notice 'Migration 016: user_id default set to gen_random_uuid()';

  -- 3. One profile row per Firebase account. NULLs stay allowed, so rows
  --    that have not been linked yet (legacy rows keyed by phone number)
  --    do not collide.
  create unique index if not exists seller_profiles_firebase_uid_key
    on public.seller_profiles (firebase_uid);
  raise notice 'Migration 016: unique index on firebase_uid';

  -- Same write grants 009/014 set up (re-running is a no-op).
  execute 'grant select, insert, update on public.seller_profiles to anon, authenticated, service_role';

  -- Without this PostgREST keeps serving the old schema and the app fails
  -- with PGRST204 on the new column.
  perform pg_notify('pgrst', 'reload schema');

  raise notice 'Migration 016 done';
end $$;

-- Proof grid: expect exactly two rows -
--   user_id      uuid   (has_unique t, it is the primary key)
--   firebase_uid text   (has_unique t, nullable)
select
  a.attname                                     as column_name,
  format_type(a.atttypid, a.atttypmod)          as data_type,
  a.attnotnull                                  as not_null,
  exists (
    select 1 from pg_index i
     where i.indrelid = 'public.seller_profiles'::regclass
       and i.indisunique
       and i.indnkeyatts = 1
       and i.indkey[0] = a.attnum
  )                                             as has_unique
 from pg_attribute a
 where a.attrelid = 'public.seller_profiles'::regclass
   and a.attnum > 0
   and not a.attisdropped
   and a.attname in ('user_id', 'firebase_uid')
 order by a.attname;
