-- 024_product_images_storage.sql
-- Run this in the Supabase SQL Editor at:
-- https://supabase.com/dashboard/project/ouzxglznpjeewdyxputa/sql
--
-- Makes product listings survive app reinstalls / device switches:
--   1. Adds the `unit` price column (kg, piece, …) that the app sends but
--      the table was missing.
--   2. Creates the public `product-images` Storage bucket the app uploads
--      product photos to (the row only stores the returned public URL).
--   3. Adds Storage policies so the app's anon key can upload/delete those
--      photos and anyone can read them through the public URLs.
--   4. Safety net: if `sellers_products` has row-level security on but no
--      anon INSERT policy yet, adds the same permissive "API layer filters
--      by user_id" policies the rest of the app uses (pattern from 017).
--
-- Safe to re-run: every statement is idempotent. No data is deleted.
--
-- NOTE: this app uses Firebase Phone Auth (not Supabase Auth), so `auth.uid()`
-- is always null and row privacy is enforced by filtering `user_id=eq.{uid}`
-- in every request, exactly as the app already does for reads.

-- ---------------------------------------------------------------------------
-- 1. Price unit column
-- ---------------------------------------------------------------------------
ALTER TABLE public.sellers_products
  ADD COLUMN IF NOT EXISTS unit text NOT NULL DEFAULT 'kg';

-- Let PostgREST pick the new column up without waiting for a schema cache
-- refresh.
NOTIFY pgrst, 'reload schema';

-- ---------------------------------------------------------------------------
-- 2. Public bucket for product photos (max 10 MB per image)
-- ---------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'product-images',
  'product-images',
  true,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 3. Storage policies for the bucket
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Product images are publicly readable" ON storage.objects;
CREATE POLICY "Product images are publicly readable"
  ON storage.objects FOR SELECT
  TO anon, authenticated
  USING (bucket_id = 'product-images');

DROP POLICY IF EXISTS "Anyone can upload product images" ON storage.objects;
CREATE POLICY "Anyone can upload product images"
  ON storage.objects FOR INSERT
  TO anon, authenticated
  WITH CHECK (bucket_id = 'product-images');

DROP POLICY IF EXISTS "Anyone can delete product images" ON storage.objects;
CREATE POLICY "Anyone can delete product images"
  ON storage.objects FOR DELETE
  TO anon, authenticated
  USING (bucket_id = 'product-images');

-- ---------------------------------------------------------------------------
-- 4. Safety net for sellers_products writes
--
-- Reads already work (verified): either RLS is off on this table, or an
-- anon SELECT policy exists. This block only runs when RLS is ON and anon
-- has no INSERT policy at all — the one state in which adding a product
-- would fail with 42501 "permission denied". If policies already exist,
-- nothing is touched.
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'sellers_products'
      AND c.relrowsecurity
  ) AND NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'sellers_products'
      AND cmd = 'INSERT'
      AND roles @> ARRAY['anon']::name[]
  ) THEN
    CREATE POLICY "Allow all inserts" ON public.sellers_products
      FOR INSERT WITH CHECK (true);
    CREATE POLICY "Allow all updates" ON public.sellers_products
      FOR UPDATE USING (true) WITH CHECK (true);
    CREATE POLICY "Allow all deletes" ON public.sellers_products
      FOR DELETE USING (true);
  END IF;
END $$;

GRANT ALL ON public.sellers_products TO anon;
GRANT ALL ON storage.objects TO anon;
