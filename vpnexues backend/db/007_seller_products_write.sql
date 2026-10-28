-- Enables the no-login seller app to add, update and delete products.
-- Run after 005_seller_products.sql in the Supabase SQL Editor.
-- Safe to run more than once.

alter table public.sellers_products
  add column if not exists product_avaliblit text not null default 'active',
  add column if not exists buyer_pickup_enabled boolean not null default true,
  add column if not exists delivery_enabled boolean not null default true;

-- Normalise any legacy availability values before enforcing the check.
update public.sellers_products
set product_avaliblit = case lower(trim(product_avaliblit))
  when 'active' then 'active'
  when 'available' then 'active'
  when 'in stock' then 'active'
  when 'out_of_stock' then 'out_of_stock'
  when 'out of stock' then 'out_of_stock'
  when 'unavailable' then 'out_of_stock'
  when 'draft' then 'draft'
  when 'inactive' then 'draft'
  else 'active'
end
where product_avaliblit is null
   or lower(trim(product_avaliblit)) not in (
     'active',
     'out_of_stock',
     'draft'
   );

alter table public.sellers_products
  alter column product_avaliblit set default 'active',
  alter column product_avaliblit set not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'sellers_products_availability_check'
      and conrelid = 'public.sellers_products'::regclass
  ) then
    alter table public.sellers_products
      add constraint sellers_products_availability_check
      check (product_avaliblit in ('active', 'out_of_stock', 'draft'));
  end if;
end
$$;

alter table public.sellers_products enable row level security;

drop policy if exists sellers_products_public_read on public.sellers_products;
create policy sellers_products_public_read on public.sellers_products
for select to anon, authenticated
using (true);

drop policy if exists sellers_products_public_insert on public.sellers_products;
create policy sellers_products_public_insert on public.sellers_products
for insert to anon, authenticated
with check (true);

drop policy if exists sellers_products_public_update on public.sellers_products;
create policy sellers_products_public_update on public.sellers_products
for update to anon, authenticated
using (true)
with check (true);

drop policy if exists sellers_products_public_delete on public.sellers_products;
create policy sellers_products_public_delete on public.sellers_products
for delete to anon, authenticated
using (true);

grant select, insert, update, delete on table public.sellers_products
  to anon, authenticated;

grant all on table public.sellers_products to service_role;

do $$
begin
  if to_regclass('public.sellers_products_id_seq') is not null then
    execute 'grant usage, select on sequence public.sellers_products_id_seq to anon, authenticated';
  end if;
end
$$;

notify pgrst, 'reload schema';
