-- Removes Supabase Auth coupling from the seller database.
-- Supabase is used only as a product data store after this migration.
-- Destructive: drops seller_profiles and the seller/buyer/user ownership
-- columns. Run in the Supabase SQL Editor as the postgres role.

-- 1. Remove auth triggers and functions.
drop trigger if exists on_auth_user_created_seller on auth.users;
drop function if exists public.handle_new_seller();

drop trigger if exists set_order_item_ownership on public.order_items;
drop function if exists public.set_order_item_ownership();

drop function if exists public.is_order_seller(text) cascade;
drop function if exists public.is_order_buyer(text) cascade;

-- 2. Drop every policy that was tied to auth.uid().
do $$
declare
  policy_row record;
begin
  for policy_row in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename in (
        'seller_profiles', 'products', 'orders', 'order_items',
        'users', 'addresses', 'notifications'
      )
  loop
    execute format(
      'drop policy if exists %I on %I.%I',
      policy_row.policyname, policy_row.schemaname, policy_row.tablename
    );
  end loop;
end
$$;

-- 3. Drop every foreign key that points at auth.users or seller_profiles.
do $$
declare
  fk_row record;
begin
  for fk_row in
    select conrelid::regclass as table_name, conname
    from pg_constraint
    where contype = 'f'
      and (
        confrelid = to_regclass('auth.users')
        or confrelid = to_regclass('public.seller_profiles')
      )
  loop
    execute format(
      'alter table %s drop constraint %I',
      fk_row.table_name, fk_row.conname
    );
  end loop;
end
$$;

-- 4. Drop ownership indexes and columns.
drop index if exists public.products_seller_id_idx;
drop index if exists public.orders_user_id_idx;
drop index if exists public.order_items_order_seller_idx;
drop index if exists public.order_items_seller_id_idx;
drop index if exists public.order_items_buyer_id_idx;

alter table public.products drop column if exists seller_id;

do $$
begin
  if to_regclass('public.order_items') is not null then
    alter table public.order_items drop column if exists seller_id;
    alter table public.order_items drop column if exists buyer_id;
  end if;

  if to_regclass('public.orders') is not null then
    alter table public.orders drop column if exists user_id;
  end if;
end
$$;

-- 5. Drop the auth profile table.
drop table if exists public.seller_profiles cascade;

-- 6. Keep the product catalog publicly readable for the no-login app.
alter table public.products enable row level security;
drop policy if exists products_public_read on public.products;
create policy products_public_read on public.products
for select to anon, authenticated
using (true);

grant select on table public.products to anon, authenticated;
grant all on table public.products to service_role;

notify pgrst, 'reload schema';
