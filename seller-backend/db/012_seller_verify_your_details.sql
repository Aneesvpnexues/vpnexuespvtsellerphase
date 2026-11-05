-- Migration 012: seller_verify_your_details (KYC document URLs)
--
-- WHERE TO RUN IT (this is what went wrong last time):
--   The dashboard breadcrumb must be project ref `ouzxglznpjeewdyxputa`,
--   i.e. https://supabase.com/dashboard/project/ouzxglznpjeewdyxputa/sql
--   The app's anon key points at that project, and that is the project where
--   your seller profile row lives. Any other project (for example
--   "vpnexuesprivatelimited-alt's Project") is ignored - the script below
--   raises an exception instead of changing the wrong database.
--
-- WHAT IT FIXES:
--   1. row-level security is ON with no policy for the anon role
--      -> "new row violates row-level security policy for table ..."
--   2. user_id is int8, but this app has no login so its id is text (uuid)
--      -> "invalid input syntax for type bigint"
--   3. user_id may be an IDENTITY column, which cannot change type
--      -> SQLSTATE 22023 "identity column type must be smallint, integer,
--         or bigint"   (drop the identity first)
--   4. the document columns may be bytea, which cannot hold a URL
--   5. no unique index on user_id would break ?on_conflict=user_id
--   6. PostgREST caches column types, so the schema cache is reloaded
--
-- SUCCESS LOOKS LIKE: notices from the DO block, then a grid where
--   apps_project = t, rls_enabled = f, data_type = text (x4), has_unique = t

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

  raise notice 'Migration 012 running (seller_verify_your_details)';

  -- 1. RLS off so the anon role (the app) can insert.
  alter table public.seller_verify_your_details
    disable row level security;

  -- 2. bytea -> text, only while still bytea, so a re-run is a no-op.
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public'
       and table_name   = 'seller_verify_your_details'
       and column_name  = 'aadhaar_card'
       and data_type    = 'bytea'
  ) then
    alter table public.seller_verify_your_details
      alter column aadhaar_card          type text using convert_from(aadhaar_card, 'UTF8'),
      alter column pan_card              type text using convert_from(pan_card, 'UTF8'),
      alter column business_registration type text using convert_from(business_registration, 'UTF8');
    raise notice 'Migration 012: document columns converted bytea -> text';
  end if;

  -- 3. user_id: int8 -> text, in the only order PostgreSQL accepts.
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public'
       and table_name   = 'seller_verify_your_details'
       and column_name  = 'user_id'
       and data_type   <> 'text'
  ) then
    if exists (
      select 1 from information_schema.columns
       where table_schema = 'public'
         and table_name  = 'seller_verify_your_details'
         and column_name = 'user_id'
         and is_identity = 'YES'
    ) then
      alter table public.seller_verify_your_details
        alter column user_id drop identity;
      raise notice 'Migration 012: identity dropped from user_id';
    end if;

    alter table public.seller_verify_your_details
      alter column user_id type text using user_id::text;
    raise notice 'Migration 012: user_id int8 -> text';
  end if;

  -- 4. ?on_conflict=user_id needs a unique index; it is the PK on most
  --    installs, so this only fires when there is none.
  if not exists (
    select 1
      from pg_index i
     where i.indrelid = 'public.seller_verify_your_details'::regclass
       and i.indisunique
       and i.indnkeyatts = 1
       and i.indkey[0] = (
             select a.attnum
               from pg_attribute a
              where a.attrelid = 'public.seller_verify_your_details'::regclass
                and a.attname = 'user_id'
           )
  ) then
    alter table public.seller_verify_your_details add unique (user_id);
    raise notice 'Migration 012: unique index added on user_id';
  end if;

  grant select, insert, update, delete
    on table public.seller_verify_your_details
    to anon, authenticated;
  grant all on table public.seller_verify_your_details to service_role;

  -- 5. PostgREST caches column types; without this it keeps casting the app's
  --    uuid to bigint and its URLs to bytea.
  perform pg_notify('pgrst', 'reload schema');

  raise notice 'Migration 012 done: rls off, user_id text, schema cache reloaded';
end $$;

-- Proof. apps_project must be t (009 ran here), rls_enabled f, every
-- data_type text, has_unique t.
select exists (
         select 1 from information_schema.columns
          where table_schema = 'public'
            and table_name   = 'seller_profiles'
            and column_name  = 'business_name'
       )                                       as apps_project,
       c.relrowsecurity                        as rls_enabled,
       a.attname                               as column_name,
       format_type(a.atttypid, a.atttypmod)    as data_type,
       a.attidentity                           as identity_marker,
       exists (
         select 1 from pg_index i
          where i.indrelid = c.oid
            and i.indisunique
            and i.indnkeyatts = 1
            and i.indkey[0] = a.attnum
       )                                       as has_unique
  from pg_class c
  join pg_attribute a
    on a.attrelid = c.oid
   and a.attnum > 0
   and not a.attisdropped
 where c.relnamespace = 'public'::regnamespace
   and c.relname = 'seller_verify_your_details'
 order by a.attnum;
