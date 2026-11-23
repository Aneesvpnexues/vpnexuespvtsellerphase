-- Migration 023: seller_bank_details.id default (sequence)
--
-- WHERE TO RUN IT:
--   Supabase Dashboard -> SQL Editor, project ref `ouzxglznpjeewdyxputa`, i.e.
--   https://supabase.com/dashboard/project/ouzxglznpjeewdyxputa/sql
--   The script raises an exception in any other project instead of changing
--   the wrong database.
--
-- WHY THIS EXISTS:
--   `seller_bank_details.id` is numeric NOT NULL with no default and no
--   identity marker. The app's bank writes go through the `seller-bank` Edge
--   Function, which inserts a row WITHOUT an id (the pre-lockdown app code
--   used to send one explicitly, which is why it used to work). Every upsert
--   therefore failed with:
--
--     23502  null value in column "id" violates not-null constraint
--
--   and the function's catch-all turned that into
--   "Could not reach the server. Please try again." on the Add your bank
--   details page, so onboarding could never reach Home.
--
-- WHAT IT DOES:
--   1. creates public.seller_bank_details_id_seq (no-op when it exists)
--   2. seeds it past the highest id already in the table - legacy rows use
--      millisecond timestamps, so new ids keep sorting after them
--   3. sets it as the column default for id
--   4. grants usage/select on the sequence to the roles the app uses
--   5. reloads PostgREST's schema cache
--
-- SAFE: adds a DEFAULT only. No row is created, updated or deleted, and an
-- already-applied run reports "nothing to do" instead of touching anything.
--
-- SUCCESS LOOKS LIKE: the notices below, then one row in the proof grid:
--   id | NO | nextval('public.seller_bank_details_id_seq'::regclass)

do $$
begin
  if to_regclass('public.seller_bank_details') is null then
    raise exception 'WRONG PROJECT: public.seller_bank_details does not exist here. Open https://supabase.com/dashboard/project/ouzxglznpjeewdyxputa/sql and run this file there.';
  end if;

  if not exists (
    select 1
      from information_schema.columns
     where table_schema = 'public'
       and table_name   = 'seller_profiles'
       and column_name   = 'business_name'
  ) then
    raise exception 'WRONG PROJECT: 009_seller_profiles_write.sql has never run here, so the app does not use this database. Switch to project ouzxglznpjeewdyxputa and run this file again.';
  end if;

  raise notice 'Migration 023 running (seller_bank_details.id default)';

  if exists (
    select 1
      from information_schema.columns
     where table_schema = 'public'
       and table_name   = 'seller_bank_details'
       and column_name   = 'id'
       and column_default is not null
  ) then
    raise notice 'Migration 023: seller_bank_details.id already has a default - nothing to do';
  else
    create sequence if not exists public.seller_bank_details_id_seq;

    -- Start past the biggest id already in the table (legacy rows hold
    -- millisecond timestamps) so new ids never collide and keep sorting
    -- after the old ones. `id` is numeric, so it is cast to the bigint
    -- setval(regclass, bigint, boolean) expects.
    perform setval(
      'public.seller_bank_details_id_seq',
      coalesce((select max(id) from public.seller_bank_details), 0)::bigint + 1,
      false
    );

    alter table public.seller_bank_details
      alter column id set default nextval('public.seller_bank_details_id_seq');

    alter sequence public.seller_bank_details_id_seq
      owned by public.seller_bank_details.id;

    grant usage, select on sequence public.seller_bank_details_id_seq
      to anon, authenticated, service_role;

    raise notice 'Migration 023: default set on seller_bank_details.id';
  end if;

  -- PostgREST caches schema details; without this the new default may only
  -- become visible after its next automatic reload.
  perform pg_notify('pgrst', 'reload schema');

  raise notice 'Migration 023 done';
end $$;

-- Proof grid: expect column_default to be the nextval(...) expression.
select column_name,
       is_nullable,
       column_default
  from information_schema.columns
 where table_schema = 'public'
   and table_name   = 'seller_bank_details'
   and column_name   = 'id';
