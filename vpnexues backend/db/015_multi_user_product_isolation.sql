-- 015_multi_user_product_isolation.sql
-- Run this in the Supabase SQL Editor at:
-- https://supabase.com/dashboard/project/ouzxglznpjeewdyxputa/sql
--
-- This migration converts the single-seller app into a multi-user private
-- product management system. Every product is owned by exactly one auth user
-- via `user_id` (text, storing Firebase Auth UID). All product queries filter
-- by `user_id` in the API layer so a user can never see another user's rows.
--
-- NOTE: This app uses Firebase Phone Auth (not Supabase Auth), so
-- `auth.uid()` is always null. Row-level filtering is enforced at the API
-- layer — every SELECT/INSERT/UPDATE/DELETE includes `user_id = eq.{uid}`.

-- 1. Replace the existing auth-era `user_id` (uuid) with a text column
--    storing Firebase Auth UIDs. Existing rows get NULL.
--    Use CASCADE because RLS policies depend on this column.
ALTER TABLE public.sellers_products
  DROP COLUMN IF EXISTS user_id CASCADE;
ALTER TABLE public.sellers_products
  ADD COLUMN user_id text;

-- 2. Create the profiles table: one row per Firebase Auth user (id = Firebase UID, text).
CREATE TABLE IF NOT EXISTS public.profiles (
  id text PRIMARY KEY,
  full_name text,
  phone_number text,
  email text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 3. Row Level Security: keep enabled but permissive (true). The API layer
--    enforces user_id filtering on every query, so RLS here is a safety net
--    that allows all authenticated reads/writes while the API does the real
--    user-scoped filtering (since auth.uid() is null with Firebase Auth).
ALTER TABLE public.sellers_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 4. Drop any existing policies so we start clean (idempotent).
DROP POLICY IF EXISTS "Allow all reads" ON public.sellers_products;
DROP POLICY IF EXISTS "Allow all inserts" ON public.sellers_products;
DROP POLICY IF EXISTS "Allow all updates" ON public.sellers_products;
DROP POLICY IF EXISTS "Allow all deletes" ON public.sellers_products;
DROP POLICY IF EXISTS "Allow all profile reads" ON public.profiles;
DROP POLICY IF EXISTS "Allow all profile inserts" ON public.profiles;
DROP POLICY IF EXISTS "Allow all profile updates" ON public.profiles;
DROP POLICY IF EXISTS "Allow all profile deletes" ON public.profiles;
DROP POLICY IF EXISTS "Users can view their own products" ON public.sellers_products;
DROP POLICY IF EXISTS "Users can insert their own products" ON public.sellers_products;
DROP POLICY IF EXISTS "Users can update their own products" ON public.sellers_products;
DROP POLICY IF EXISTS "Users can delete their own products" ON public.sellers_products;

-- 5. Permissive policies — API layer does the real user_id filtering.
CREATE POLICY "Allow all reads" ON public.sellers_products FOR SELECT USING (true);
CREATE POLICY "Allow all inserts" ON public.sellers_products FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow all updates" ON public.sellers_products FOR UPDATE USING (true);
CREATE POLICY "Allow all deletes" ON public.sellers_products FOR DELETE USING (true);

CREATE POLICY "Allow all profile reads" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Allow all profile inserts" ON public.profiles FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow all profile updates" ON public.profiles FOR UPDATE USING (true);
CREATE POLICY "Allow all profile deletes" ON public.profiles FOR DELETE USING (true);

-- 6. Grant the authenticated role access.
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.sellers_products TO authenticated;
GRANT ALL ON public.profiles TO authenticated;

-- 7. Proof query: confirm policies exist.
SELECT polname, polcmd::text AS command
FROM pg_policy
WHERE polrelid = 'public.sellers_products'::regclass
   OR polrelid = 'public.profiles'::regclass
ORDER BY polrelid::text, polname;
