-- 018_seller_reviews.sql
-- Run this in the Supabase SQL Editor at:
-- https://supabase.com/dashboard/project/ouzxglznpjeewdyxputa/sql
--
-- Reviews the buyer flow writes when a buyer rates a seller. One row per
-- (buyer, seller) pair — a buyer can update their review but not add a
-- second one for the same seller. The Review & Ratings page (average,
-- star distribution bars, review rows) reads this single table; all stats
-- are derived client-side like seller_transactions (017).
--
-- NOTE: This app uses Firebase Phone Auth (not Supabase Auth), so
-- `auth.uid()` is always null. Row-level filtering is enforced at the API
-- layer — every SELECT/INSERT includes `user_id = eq.{uid}`.

CREATE TABLE IF NOT EXISTS public.seller_reviews (
  id bigserial PRIMARY KEY,
  buyer_user_id text NOT NULL,
  seller_user_id text NOT NULL,
  rating integer NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment text NOT NULL CHECK (btrim(comment) <> ''),
  reviewer_name text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- One review per buyer per seller (buyer may edit it later).
CREATE UNIQUE INDEX IF NOT EXISTS seller_reviews_buyer_seller_key
  ON public.seller_reviews (buyer_user_id, seller_user_id);

-- Load a seller's reviews newest-first (the Review & Ratings list).
CREATE INDEX IF NOT EXISTS seller_reviews_seller_created_idx
  ON public.seller_reviews (seller_user_id, created_at DESC);

-- Permissive RLS: the API layer does the real user_id filtering
-- (auth.uid() is null with Firebase Auth). Same pattern as 015/017.
ALTER TABLE public.seller_reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all reads" ON public.seller_reviews;
DROP POLICY IF EXISTS "Allow all inserts" ON public.seller_reviews;
DROP POLICY IF EXISTS "Allow all updates" ON public.seller_reviews;
DROP POLICY IF EXISTS "Allow all deletes" ON public.seller_reviews;

CREATE POLICY "Allow all reads" ON public.seller_reviews FOR SELECT USING (true);
CREATE POLICY "Allow all inserts" ON public.seller_reviews FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow all updates" ON public.seller_reviews FOR UPDATE USING (true);
CREATE POLICY "Allow all deletes" ON public.seller_reviews FOR DELETE USING (true);

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.seller_reviews TO authenticated;
GRANT ALL ON public.seller_reviews TO anon;

-- Proof query: expect seller_reviews_buyer_seller_key and
-- seller_reviews_seller_created_idx.
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'seller_reviews'
ORDER BY indexname;

NOTIFY pgrst, 'reload schema';
