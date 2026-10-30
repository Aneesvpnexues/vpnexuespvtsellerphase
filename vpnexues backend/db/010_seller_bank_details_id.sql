-- Fixes seller_bank_details.id so inserting rows without an explicit id works.
-- Target: public.seller_bank_details
-- Safe to run more than once in the Supabase SQL Editor.

create sequence if not exists public.seller_bank_details_id_seq;

alter table public.seller_bank_details
  alter column id set default nextval('public.seller_bank_details_id_seq');

alter sequence public.seller_bank_details_id_seq owned by public.seller_bank_details.id;

grant usage, select on sequence public.seller_bank_details_id_seq
  to anon, authenticated, service_role;

notify pgrst, 'reload schema';

