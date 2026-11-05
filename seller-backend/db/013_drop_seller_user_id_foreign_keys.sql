-- Migration 013: drop the auth-era foreign keys on seller `user_id` columns.
-- Run once in the Supabase SQL Editor. Safe to run more than once.
--
-- Background: this app has no login (006_remove_auth.sql). The id the app
-- writes is generated on the phone (a uuid, or the phone number the seller
-- typed), so it never exists in auth.users / users. The FK left behind from
-- the auth era therefore rejects every insert:
--
--   insert or update on table "seller_profiles" violates foreign key
--   constraint "seller_profiles_user_id_fkey"
--
-- The loop below only drops constraints that are actually on a `user_id`
-- column of one of the seller tables, and reports what it dropped.

do $$
declare
  r       record;
  dropped integer := 0;
begin
  for r in
    select t.relname    as table_name,
           c.conname    as constraint_name,
           ft.relname   as referenced_table,
           fn.nspname   as referenced_schema
      from pg_constraint c
      join pg_class     t  on t.oid  = c.conrelid
      join pg_namespace n  on n.oid  = t.relnamespace
      join pg_class     ft on ft.oid = c.confrelid
      join pg_namespace fn on fn.oid = ft.relnamespace
      join pg_attribute a  on a.attrelid = c.conrelid
                          and a.attnum   = any (c.conkey)
     where n.nspname = 'public'
       and t.relname in (
             'seller_profiles',
             'seller_bank_details',
             'sellers_products',
             'seller_verify_your_details'
           )
       and c.contype = 'f'
       and a.attname = 'user_id'
  loop
    execute format(
      'alter table public.%I drop constraint %I',
      r.table_name,
      r.constraint_name
    );
    dropped := dropped + 1;
    raise notice 'Dropped public.% on %.% (references %.%)',
      r.constraint_name,
      r.table_name,
      'user_id',
      r.referenced_schema,
      r.referenced_table;
  end loop;

  if dropped = 0 then
    raise notice 'No user_id foreign keys found - nothing to do.';
  end if;
end $$;

-- Nothing here needs a schema-cache reload (constraints are not part of the
-- PostgREST cache), but the notify is harmless and keeps the pattern used by
-- the other migrations in this folder.
notify pgrst, 'reload schema';
