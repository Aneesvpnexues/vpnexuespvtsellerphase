select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename in (
    'seller_profiles', 'products', 'orders', 'order_items',
    'users', 'addresses', 'notifications'
  )
order by tablename, policyname;

select c.relname as table_name, c.relrowsecurity as rls_enabled, c.relforcerowsecurity as rls_forced
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in (
    'seller_profiles', 'products', 'orders', 'order_items',
    'users', 'addresses', 'notifications'
  )
order by c.relname;

select table_name, column_name, data_type, udt_name, is_nullable, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name in (
    'seller_profiles', 'products', 'orders', 'order_items',
    'users', 'addresses', 'notifications'
  )
order by table_name, ordinal_position;

select table_name, grantee, privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name in (
    'seller_profiles', 'products', 'orders', 'order_items',
    'users', 'addresses', 'notifications'
  )
  and grantee in ('anon', 'authenticated', 'service_role')
order by table_name, grantee, privilege_type;

select
  (select count(*) from public.users) as public_users,
  (select count(*) from public.users u join auth.users au on au.id = u.id) as matched_auth_users,
  (select count(*) from public.orders o left join auth.users au on au.id = o.user_id where au.id is null) as orders_without_auth_buyer,
  (select count(*) from public.order_items oi left join public.products p on p.id = oi.product_id where p.id is null) as order_items_without_product,
  (select count(*) from public.order_items oi left join public.orders o on o.id = oi.order_id where o.id is null) as order_items_without_order;

select table_name, count(*) as row_count
from (
  select 'products' as table_name from public.products
  union all
  select 'orders' from public.orders
  union all
  select 'order_items' from public.order_items
  union all
  select 'users' from public.users
  union all
  select 'addresses' from public.addresses
  union all
  select 'notifications' from public.notifications
) counts
group by table_name
order by table_name;
