-- =============================================================================
-- 022_bank_lockdown.sql
-- Run this in: Supabase Dashboard -> SQL Editor -> New query -> Run
--
-- *** RUN THIS ONLY AFTER you have installed the updated app build. ***
-- From that build on, all bank reads/writes go through the "seller-bank"
-- Edge Function (service role), so the public anon key must lose access.
--
-- Safe: no data is deleted, nothing is dropped.
-- =============================================================================

alter table public.seller_bank_details enable row level security;

-- Remove any permissive anon policies that may exist on this table.
do $$
declare
  pol record;
begin
  for pol in
    select policyname from pg_policies
    where schemaname = 'public'
      and tablename = 'seller_bank_details'
      and roles = array['anon']
  loop
    execute format('drop policy %I on public.seller_bank_details', pol.policyname);
  end loop;
end $$;

-- Explicitly deny anon: with RLS enabled and no policies, every anon
-- SELECT/INSERT/UPDATE/DELETE is rejected (42501). The service role
-- (used only inside the Edge Function) bypasses RLS and keeps working.
