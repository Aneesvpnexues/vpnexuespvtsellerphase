-- 017_seller_transactions.sql
-- Run this in the Supabase SQL Editor at:
-- https://supabase.com/dashboard/project/ouzxglznpjeewdyxputa/sql
--
-- Wallet ledger for the seller Profile / Wallet screens. One row per
-- credit (order earning) or withdrawal. All stats — withdrawal balance,
-- total earned, period earned/orders — are derived client-side from this
-- single table.
--
-- NOTE: This app uses Firebase Phone Auth (not Supabase Auth), so
-- `auth.uid()` is always null. Row-level filtering is enforced at the API
-- layer — every SELECT/INSERT includes `user_id = eq.{uid}`.

CREATE TABLE IF NOT EXISTS public.seller_transactions (
  id bigserial PRIMARY KEY,
  user_id text NOT NULL,
  type text NOT NULL CHECK (type IN ('credit', 'withdrawal')),
  amount numeric NOT NULL CHECK (amount > 0),
  title text NOT NULL,
  order_id text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS seller_transactions_user_created_idx
  ON public.seller_transactions (user_id, created_at DESC);

-- Permissive RLS: the API layer does the real user_id filtering
-- (auth.uid() is null with Firebase Auth). Same pattern as 015.
ALTER TABLE public.seller_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all reads" ON public.seller_transactions;
DROP POLICY IF EXISTS "Allow all inserts" ON public.seller_transactions;
DROP POLICY IF EXISTS "Allow all updates" ON public.seller_transactions;
DROP POLICY IF EXISTS "Allow all deletes" ON public.seller_transactions;

CREATE POLICY "Allow all reads" ON public.seller_transactions FOR SELECT USING (true);
CREATE POLICY "Allow all inserts" ON public.seller_transactions FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow all updates" ON public.seller_transactions FOR UPDATE USING (true);
CREATE POLICY "Allow all deletes" ON public.seller_transactions FOR DELETE USING (true);

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.seller_transactions TO authenticated;
GRANT ALL ON public.seller_transactions TO anon;

NOTIFY pgrst, 'reload schema';
