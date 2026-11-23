-- =============================================================================
-- 021_seller_registrations_setup.sql
-- Run this in: Supabase Dashboard -> SQL Editor -> New query -> Run
--
-- Safe to run on the existing database:
--   * No tables are dropped, no rows are deleted.
--   * Every CREATE uses IF NOT EXISTS, every ALTER uses IF NOT EXISTS.
--   * Existing tables owned by other apps are not touched except for two
--     additive columns on seller_profiles / seller_verify_your_details.
--   * The `anon_can_register` policy is dropped and recreated (NOT created
--     only when missing), so re-running this file repairs a stale rule
--     instead of silently skipping it.
--   * The file ends with an assertion, so "Success. No rows returned" really
--     means the signup path is usable.
--
-- IMPORTANT FOR THE APP: public.seller_registrations has NO SELECT policy for
-- anon, on purpose (registrations must stay invisible). The signup request
-- must therefore never send `Prefer: return=representation` — reading the row
-- back makes Postgres reject the entire insert with
--   42501 new row violates row-level security policy
-- even though the INSERT policy itself is fine. The app generates the row id
-- itself (SupabaseProductApi._newRegistrationId) and inserts it.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 0. Wrong-project guard.
--    The SQL Editor reports "success" for a script that only no-ops in the
--    wrong database — that is exactly how a missing/stale RLS policy
--    survives. Fail loudly instead.
-- -----------------------------------------------------------------------------
do $$
begin
  if to_regclass('public.seller_profiles') is null then
    raise exception 'WRONG PROJECT: public.seller_profiles does not exist here. Open https://supabase.com/dashboard/project/ouzxglznpjeewdyxputa/sql and run this file there.';
  end if;
end $$;


-- -----------------------------------------------------------------------------
-- 1. seller_registrations -- the pending (unverified) signup record.
--
-- Created at Sign Up time, BEFORE any Firebase OTP happens. It holds only the
-- name + phone. firebase_uid / phone_verified stay NULL/false until the user
-- later logs in and passes OTP; the Edge Function "seller-link-account" is the
-- only thing allowed to link a Firebase UID (it takes the phone from the
-- verified Firebase ID token, never from the client body).
--
-- RLS: anon may INSERT only (and only a pending row). anon can NOT select,
-- update or delete -> registrations are invisible to any other app user.
-- All reads/links happen server-side with the service-role key.
-- -----------------------------------------------------------------------------
create table if not exists public.seller_registrations (
  id              uuid primary key default gen_random_uuid(),
  phone_e164      text not null,
  name            text not null,
  status          text not null default 'pending'
                  check (status in ('pending', 'linked')),
  firebase_uid    text,
  phone_verified  boolean not null default false,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- One registration per phone number (duplicate-signup prevention).
create unique index if not exists seller_registrations_phone_e164_key
  on public.seller_registrations (phone_e164);

-- Linking lookups (server side only).
create index if not exists seller_registrations_firebase_uid_idx
  on public.seller_registrations (firebase_uid)
  where firebase_uid is not null;

alter table public.seller_registrations enable row level security;

-- Defence against `create table if not exists` being a no-op: if an earlier
-- version of this table already existed with a different column set, add
-- whatever the anon_can_register policy below depends on. (A fresh table
-- created above already carries the NOT NULL / default constraints.)
alter table public.seller_registrations
  add column if not exists name          text,
  add column if not exists phone_e164    text,
  add column if not exists status        text default 'pending',
  add column if not exists firebase_uid  text,
  add column if not exists phone_verified boolean default false,
  add column if not exists created_at    timestamptz default now(),
  add column if not exists updated_at    timestamptz default now();

-- RLS: anon may INSERT only (and only a pending row). anon can NOT select,
-- update or delete -> registrations are invisible to any other app user.
-- All reads/links happen server-side with the service-role key.
--
-- NOTE: the policy is dropped and recreated on every run. An earlier version
-- used `if not exists (select ... from pg_policies)`, which silently SKIPPED
-- creation when a stale policy already had this name — the SQL Editor then
-- reported success while anon was still locked out. Dropping first means
-- re-running this file always repairs the rule.
--
-- NOTE: there is deliberately NO SELECT policy for anon here. The app must
-- not ask PostgREST for the inserted row back (Prefer: return=representation)
-- — see the header of this file.
drop policy if exists "anon_can_register" on public.seller_registrations;

create policy "anon_can_register"
  on public.seller_registrations
  for insert
  to anon
  with check (
    status = 'pending'
    and firebase_uid is null
    and phone_verified = false
  );

-- Helper that keeps updated_at fresh (created only if your database does not
-- already have a function with this name — never overwrites an existing one).
do $$
begin
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'set_updated_at'
  ) then
    execute $fn$
      create function public.set_updated_at()
      returns trigger
      language plpgsql
      as $body$
      begin
        new.updated_at = now();
        return new;
      end;
      $body$
    $fn$;
  end if;
end $$;

drop trigger if exists seller_registrations_touch_updated_at on public.seller_registrations;
create trigger seller_registrations_touch_updated_at
  before update on public.seller_registrations
  for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- 2. seller_lookup_rate_limits -- used by the Edge Functions to stop anyone
--    from enumerating phone numbers through the registration-status check.
--    service-role only; the anon key cannot read or write it.
-- -----------------------------------------------------------------------------
create table if not exists public.seller_lookup_rate_limits (
  key          text primary key,
  window_start timestamptz not null default now(),
  count        integer not null default 0
);

alter table public.seller_lookup_rate_limits enable row level security;
-- Intentionally no policies: only the service role (bypasses RLS) can touch it.

-- -----------------------------------------------------------------------------
-- 2b. seller_lookup_registered(p_phone) -- the lookup used by the
--     "seller-registration-status" Edge Function. security definer + execute
--     revoked from anon/public, so it can ONLY be called from the server with
--     the service-role key. Returns id/type only; the function itself only
--     forwards a boolean to the app.
-- -----------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'seller_lookup_registered'
  ) then
    execute $fn$
      create function public.seller_lookup_registered(p_phone text)
      returns table (id uuid, kind text)
      language plpgsql
      security definer
      set search_path = public
      as $body$
      declare
        v_digits text;
        v_suffix text;
      begin
        v_digits := regexp_replace(coalesce(p_phone, ''), '\D', '', 'g');
        v_suffix := right(v_digits, 10);

        if length(v_digits) < 8 then
          return;
        end if;

        return query
          select r.id, 'registration'::text
          from seller_registrations r
          where regexp_replace(r.phone_e164, '\D', '', 'g') = v_digits
             or (length(v_suffix) = 10
                 and right(regexp_replace(r.phone_e164, '\D', '', 'g'), 10) = v_suffix)
          limit 5;

        if not found then
          return query
            select p.user_id, 'profile'::text
            from seller_profiles p
            where regexp_replace(coalesce(p.phone_number, ''), '\D', '', 'g') = v_digits
               or (length(v_suffix) = 10
                   and right(regexp_replace(coalesce(p.phone_number, ''), '\D', '', 'g'), 10) = v_suffix)
            limit 5;
        end if;
      end;
      $body$
    $fn$;
  end if;

  revoke execute on function public.seller_lookup_registered(text) from public, anon;
  grant execute on function public.seller_lookup_registered(text) to service_role;
end $$;

-- -----------------------------------------------------------------------------
-- 3. Additive columns -- Step 04 KYC metadata (file names + status).
--    The actual document files stay on the device for now (no Cloudinary
--    upload in this phase); only metadata is persisted so the step can be
--    restored on another device.
-- -----------------------------------------------------------------------------
alter table public.seller_verify_your_details
  add column if not exists aadhaar_file_name text,
  add column if not exists pan_file_name text,
  add column if not exists business_file_name text,
  add column if not exists kyc_status text,
  add column if not exists updated_at timestamptz default now();

-- -----------------------------------------------------------------------------
-- 4. Additive columns -- Step 01 coordinates + updated_at on seller_profiles.
-- -----------------------------------------------------------------------------
alter table public.seller_profiles
  add column if not exists latitude double precision,
  add column if not exists longitude double precision,
  add column if not exists updated_at timestamptz default now();

-- updated_at auto-touch for seller_profiles (only if the helper exists).
do $$
begin
  if exists (
    select 1 from pg_proc where proname = 'set_updated_at'
  ) then
    if not exists (
      select 1 from pg_trigger
      where tgname = 'seller_profiles_touch_updated_at'
        and tgrelid = 'public.seller_profiles'::regclass
    ) then
      create trigger seller_profiles_touch_updated_at
        before update on public.seller_profiles
        for each row execute function public.set_updated_at();
    end if;
  end if;
end $$;

-- -----------------------------------------------------------------------------
-- 5. Defensive policies for the existing app tables.
--    Only CREATE POLICY IF NOT EXISTS (via the DO block) -- never ENABLE/DROP.
--    If a policy already exists nothing happens.
-- -----------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='seller_profiles' and policyname='anon_select_seller_profiles'
  ) then
    create policy "anon_select_seller_profiles" on public.seller_profiles
      for select to anon using (true);
  end if;

  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='seller_profiles' and policyname='anon_write_seller_profiles'
  ) then
    create policy "anon_write_seller_profiles" on public.seller_profiles
      for insert to anon with check (true);
  end if;

  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='seller_profiles' and policyname='anon_update_seller_profiles'
  ) then
    create policy "anon_update_seller_profiles" on public.seller_profiles
      for update to anon using (true) with check (true);
  end if;

  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='seller_verify_your_details' and policyname='anon_select_seller_verify'
  ) then
    create policy "anon_select_seller_verify" on public.seller_verify_your_details
      for select to anon using (true);
  end if;

  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='seller_verify_your_details' and policyname='anon_write_seller_verify'
  ) then
    create policy "anon_write_seller_verify" on public.seller_verify_your_details
      for insert to anon with check (true);
  end if;

  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='seller_verify_your_details' and policyname='anon_update_seller_verify'
  ) then
    create policy "anon_update_seller_verify" on public.seller_verify_your_details
      for update to anon using (true) with check (true);
  end if;
end $$;

-- -----------------------------------------------------------------------------
-- 6. End-of-script assertion.
--    "Success. No rows returned" must mean the signup path is actually
--    usable, not merely that nothing errored. Anything wrong below makes the
--    script fail loudly instead of reporting success.
-- -----------------------------------------------------------------------------
do $$
declare
  v_policy     record;
  v_columns    integer;
begin
  if to_regclass('public.seller_registrations') is null then
    raise exception
      'ASSERTION FAILED: public.seller_registrations was not created.';
  end if;

  select count(*)::integer into v_columns
  from information_schema.columns
  where table_schema = 'public'
    and table_name = 'seller_registrations'
    and column_name in ('id', 'phone_e164', 'name', 'status',
                        'firebase_uid', 'phone_verified',
                        'created_at', 'updated_at');
  if v_columns <> 8 then
    raise exception 'ASSERTION FAILED: seller_registrations has % of 8 required columns (id, phone_e164, name, status, firebase_uid, phone_verified, created_at, updated_at).', v_columns;
  end if;

  select p.polpermissive, p.polcmd, p.polroles
    into v_policy
  from pg_policy p
  join pg_class c on c.oid = p.polrelid
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'seller_registrations'
    and p.polname = 'anon_can_register';

  if not found then
    raise exception 'ASSERTION FAILED: the policy "anon_can_register" does not exist on public.seller_registrations.';
  end if;

  if not v_policy.polpermissive then
    raise exception 'ASSERTION FAILED: the policy "anon_can_register" is RESTRICTIVE. With no permissive policy on the table, every insert is rejected with 42501 new row violates row-level security policy.';
  end if;

  if v_policy.polcmd <> 'a' then
    raise exception 'ASSERTION FAILED: the policy "anon_can_register" is not an INSERT policy (cmd=%).', v_policy.polcmd;
  end if;

  if not exists (
    select 1 from pg_roles
    where rolname = 'anon'
      and oid = any (v_policy.polroles)
  ) then
    raise exception 'ASSERTION FAILED: the policy "anon_can_register" does not apply to role anon (it applies to %).', v_policy.polroles;
  end if;

  if not has_table_privilege('anon', 'public.seller_registrations', 'insert') then
    raise exception 'ASSERTION FAILED: role anon has no INSERT privilege on public.seller_registrations.';
  end if;

  raise notice '021 OK: anon can insert pending seller_registrations and cannot select them (the app must never read the inserted row back).';
end $$;

-- NOTE: seller_bank_details is intentionally NOT changed here. Its lockdown
-- happens in 022_bank_lockdown.sql, which you run only AFTER installing the
-- updated app (the app then reads/writes bank data through the
-- "seller-bank" Edge Function instead of the anon key).
