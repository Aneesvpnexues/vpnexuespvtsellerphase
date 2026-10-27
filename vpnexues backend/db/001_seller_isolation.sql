create table if not exists public.seller_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  location text not null default '',
  verified boolean not null default false,
  seller_type text not null default 'seller',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.products
  add column if not exists seller_id uuid;

alter table public.products
  add column if not exists quantity integer not null default 0;

alter table public.products
  add column if not exists status text not null default 'active';

alter table public.order_items
  add column if not exists seller_id uuid;

alter table public.order_items
  add column if not exists buyer_id uuid;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'seller_profiles_user_id_fkey') then
    alter table public.seller_profiles
      add constraint seller_profiles_user_id_fkey
      foreign key (user_id) references auth.users(id) on delete cascade;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'products_seller_id_fkey') then
    alter table public.products
      add constraint products_seller_id_fkey
      foreign key (seller_id) references public.seller_profiles(user_id) on delete set null;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'order_items_seller_id_fkey') then
    alter table public.order_items
      add constraint order_items_seller_id_fkey
      foreign key (seller_id) references public.seller_profiles(user_id) on delete set null;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'order_items_buyer_id_fkey') then
    alter table public.order_items
      add constraint order_items_buyer_id_fkey
      foreign key (buyer_id) references auth.users(id) on delete set null;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'products_quantity_check') then
    alter table public.products
      add constraint products_quantity_check check (quantity >= 0);
  end if;

  if not exists (select 1 from pg_constraint where conname = 'products_status_check') then
    alter table public.products
      add constraint products_status_check check (status in ('active', 'inactive', 'out_of_stock'));
  end if;
end
$$;

create index if not exists products_seller_id_idx on public.products (seller_id);
create index if not exists orders_user_id_idx on public.orders (user_id);
create index if not exists order_items_order_id_idx on public.order_items (order_id);
create index if not exists order_items_seller_id_idx on public.order_items (seller_id);
create index if not exists order_items_buyer_id_idx on public.order_items (buyer_id);

update public.order_items oi
set buyer_id = o.user_id::uuid
from public.orders o
where oi.order_id = o.id
  and oi.buyer_id is null;

update public.order_items oi
set seller_id = p.seller_id
from public.products p
where oi.product_id = p.id
  and oi.seller_id is null
  and p.seller_id is not null;

create or replace function public.set_order_item_ownership()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.seller_id := (
    select p.seller_id
    from public.products p
    where p.id = new.product_id
  );
  new.buyer_id := (
    select o.user_id::uuid
    from public.orders o
    where o.id = new.order_id
  );
  return new;
end;
$$;

drop trigger if exists set_order_item_ownership on public.order_items;

create trigger set_order_item_ownership
before insert or update of order_id, product_id on public.order_items
for each row execute function public.set_order_item_ownership();

create or replace function public.is_order_seller(p_order_id text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.order_items oi
    where oi.order_id::text = p_order_id
      and oi.seller_id = auth.uid()
  );
$$;

create or replace function public.is_order_buyer(p_order_id text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.orders o
    where o.id::text = p_order_id
      and o.user_id::text = auth.uid()::text
  );
$$;

do $$
declare policy_row record;
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
    execute format('drop policy if exists %I on %I.%I',
      policy_row.policyname, policy_row.schemaname, policy_row.tablename);
  end loop;
end
$$;

alter table public.seller_profiles enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.users enable row level security;
alter table public.addresses enable row level security;
alter table public.notifications enable row level security;

create policy seller_profiles_select_own on public.seller_profiles
for select to authenticated
using (user_id = auth.uid());

create policy seller_profiles_insert_own on public.seller_profiles
for insert to authenticated
with check (user_id = auth.uid());

create policy seller_profiles_update_own on public.seller_profiles
for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy products_public_read on public.products
for select to anon, authenticated
using (true);

create policy products_seller_write on public.products
for all to authenticated
using (seller_id = auth.uid())
with check (seller_id = auth.uid());

create policy orders_buyer_read on public.orders
for select to authenticated
using (user_id::text = auth.uid()::text);

create policy orders_seller_read on public.orders
for select to authenticated
using (public.is_order_seller(id::text));

create policy order_items_read on public.order_items
for select to authenticated
using (
  seller_id = auth.uid()
  or buyer_id = auth.uid()
  or public.is_order_buyer(order_id::text)
);

create policy users_select_own on public.users
for select to authenticated
using (id = auth.uid());

create policy users_insert_own on public.users
for insert to authenticated
with check (id = auth.uid());

create policy users_update_own on public.users
for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

create policy addresses_all_own on public.addresses
for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy notifications_select_own on public.notifications
for select to authenticated
using (user_id = auth.uid());

create policy notifications_insert_own on public.notifications
for insert to authenticated
with check (user_id = auth.uid());

create policy notifications_update_own on public.notifications
for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy notifications_delete_own on public.notifications
for delete to authenticated
using (user_id = auth.uid());

revoke all on table public.seller_profiles from anon;
revoke all on table public.products from anon;
revoke all on table public.orders from anon;
revoke all on table public.order_items from anon;
revoke all on table public.users from anon;
revoke all on table public.addresses from anon;
revoke all on table public.notifications from anon;

grant select on table public.products to anon, authenticated;
grant select, insert, update, delete on table public.seller_profiles to authenticated;
grant select, insert, update, delete on table public.products to authenticated;
grant select, insert, update, delete on table public.orders to authenticated;
grant select, insert, update, delete on table public.order_items to authenticated;
grant select, insert, update, delete on table public.users to authenticated;
grant select, insert, update, delete on table public.addresses to authenticated;
grant select, insert, update, delete on table public.notifications to authenticated;

grant all on table public.seller_profiles to service_role;
grant all on table public.products to service_role;
grant all on table public.orders to service_role;
grant all on table public.order_items to service_role;
grant all on table public.users to service_role;
grant all on table public.addresses to service_role;
grant all on table public.notifications to service_role;

revoke all on function public.set_order_item_ownership() from public, anon;
revoke all on function public.is_order_seller(text) from public, anon;
revoke all on function public.is_order_buyer(text) from public, anon;

grant execute on function public.set_order_item_ownership() to authenticated, service_role;
grant execute on function public.is_order_seller(text) to authenticated, service_role;
grant execute on function public.is_order_buyer(text) to authenticated, service_role;
