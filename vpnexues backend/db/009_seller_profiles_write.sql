-- Lets the no-login seller app store the STEP 03 business profile.
-- Target: public.seller_profiles
-- Columns today: user_id (text), display_name, location, verified, seller_type,
--                created_at, updated_at, phone_number, business_address
-- Safe to run more than once in the Supabase SQL Editor.

-- The form also collects Business / Farm Name, which the table has no column
-- for yet.
alter table public.seller_profiles
  add column if not exists business_name text;

-- Ensure phone_number is text (in some setups it is double precision, which
-- fails on strings like "+91 12345 67890").
alter table public.seller_profiles
  alter column phone_number type text using phone_number::text;

-- Defaults so a row inserted by the app cannot fail on a NOT NULL column.
alter table public.seller_profiles alter column verified set default false;
alter table public.seller_profiles alter column created_at set default now();
alter table public.seller_profiles alter column updated_at set default now();

alter table public.seller_profiles enable row level security;

-- Read is already granted by 008; repeat it so this file is self-contained.
drop policy if exists seller_profiles_anon_read on public.seller_profiles;
create policy seller_profiles_anon_read on public.seller_profiles
for select to anon
using (true);

drop policy if exists seller_profiles_public_read on public.seller_profiles;
create policy seller_profiles_public_read on public.seller_profiles
for select to anon, authenticated
using (true);

drop policy if exists seller_profiles_public_insert on public.seller_profiles;
create policy seller_profiles_public_insert on public.seller_profiles
for insert to anon, authenticated
with check (true);

drop policy if exists seller_profiles_public_update on public.seller_profiles;
create policy seller_profiles_public_update on public.seller_profiles
for update to anon, authenticated
using (true)
with check (true);

drop policy if exists seller_profiles_public_delete on public.seller_profiles;
create policy seller_profiles_public_delete on public.seller_profiles
for delete to anon, authenticated
using (true);

grant select, insert, update, delete on table public.seller_profiles
  to anon, authenticated;

grant all on table public.seller_profiles to service_role;

-- ---------------------------------------------------------------------------
-- Fix seller_bank_details column types and permissions for Step 05 Bank Details
-- ---------------------------------------------------------------------------
do $$
begin
  if to_regclass('public.seller_bank_details') is not null then
    -- Drop identity constraint if user_id was defined as an identity column
    alter table public.seller_bank_details alter column user_id drop identity if exists;
    -- Convert columns to text if needed
    alter table public.seller_bank_details alter column user_id type text using user_id::text;
    alter table public.seller_bank_details alter column account_number type text using account_number::text;
    alter table public.seller_bank_details alter column "IFSC_code" type text using "IFSC_code"::text;

    alter table public.seller_bank_details enable row level security;

    drop policy if exists seller_bank_details_public_all on public.seller_bank_details;
    create policy seller_bank_details_public_all on public.seller_bank_details
      for all to anon, authenticated
      using (true)
      with check (true);

    grant select, insert, update, delete on table public.seller_bank_details to anon, authenticated;
    grant all on table public.seller_bank_details to service_role;
  end if;
end
$$;

notify pgrst, 'reload schema';
