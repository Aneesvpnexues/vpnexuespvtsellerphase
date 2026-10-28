-- Product columns used by the public seller catalog.
-- This migration no longer touches auth.users or creates auth triggers.

alter table public.products
  add column if not exists description text not null default '';

alter table public.products
  add column if not exists image_urls text[] not null default '{}';

alter table public.products
  add column if not exists quantity integer not null default 0;

alter table public.products
  add column if not exists status text not null default 'active';

update public.products
set image_urls = array[image_url]
where (image_urls is null or cardinality(image_urls) = 0)
  and image_url is not null
  and image_url <> '';

do $$
begin
  if exists (
    select 1 from pg_constraint
    where conname = 'products_status_check'
      and conrelid = 'public.products'::regclass
  ) then
    alter table public.products drop constraint products_status_check;
  end if;

  alter table public.products
    add constraint products_status_check
    check (status in ('active', 'inactive', 'out_of_stock', 'draft'));

  if not exists (
    select 1 from pg_constraint
    where conname = 'products_quantity_check'
      and conrelid = 'public.products'::regclass
  ) then
    alter table public.products
      add constraint products_quantity_check
      check (quantity >= 0);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'products_image_urls_check'
      and conrelid = 'public.products'::regclass
  ) then
    alter table public.products
      add constraint products_image_urls_check
      check (cardinality(image_urls) <= 5);
  end if;
end
$$;

notify pgrst, 'reload schema';
