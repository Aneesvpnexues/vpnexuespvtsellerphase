-- Seller Orders Table Migration
-- Run in Supabase SQL Editor

-- Drop old triggers/functions first
DROP TRIGGER IF EXISTS set_order_item_ownership ON public.order_items;
DROP FUNCTION IF EXISTS public.set_order_item_ownership() CASCADE;
DROP FUNCTION IF EXISTS public.is_order_seller(text) CASCADE;
DROP FUNCTION IF EXISTS public.is_order_buyer(text) CASCADE;

-- Create orders table
CREATE TABLE IF NOT EXISTS public.orders (
  id BIGSERIAL PRIMARY KEY,
  order_id TEXT UNIQUE,
  buyer_id TEXT NOT NULL DEFAULT '',
  seller_id TEXT NOT NULL DEFAULT '',
  total_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  delivery_charges NUMERIC(12,2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending',
  pickup_type TEXT NOT NULL DEFAULT 'buyer_pickup',
  expected_pickup_date DATE,
  buyer_note TEXT,
  seller_note TEXT,
  buyer_pickup_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  delivery_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Generate order_id for existing rows
UPDATE public.orders
SET order_id = '#ON' || LPAD(id::TEXT, 6, '0')
WHERE order_id IS NULL OR order_id = '';

-- Set NOT NULL after populating
ALTER TABLE public.orders ALTER COLUMN order_id SET NOT NULL;

-- Create unique index
CREATE UNIQUE INDEX IF NOT EXISTS orders_order_id_key ON public.orders(order_id);

-- Create order_items table
CREATE TABLE IF NOT EXISTS public.order_items (
  id BIGSERIAL PRIMARY KEY,
  order_id BIGINT REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id BIGINT REFERENCES public.products(id),
  quantity INTEGER NOT NULL DEFAULT 0,
  unit TEXT NOT NULL DEFAULT 'kg',
  rate NUMERIC(12,2) NOT NULL DEFAULT 0,
  total_price NUMERIC(12,2) NOT NULL DEFAULT 0,
  product_name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Clean up old columns
ALTER TABLE public.order_items DROP COLUMN IF EXISTS seller_id;
ALTER TABLE public.order_items DROP COLUMN IF EXISTS buyer_id;

-- Create indexes
CREATE INDEX IF NOT EXISTS orders_buyer_id_idx ON public.orders(buyer_id);
CREATE INDEX IF NOT EXISTS orders_seller_id_idx ON public.orders(seller_id);
CREATE INDEX IF NOT EXISTS orders_status_idx ON public.orders(status);
CREATE INDEX IF NOT EXISTS order_items_order_id_idx ON public.order_items(order_id);

-- Enable RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- Orders policies
DROP POLICY IF EXISTS orders_public_read ON public.orders;
CREATE POLICY orders_public_read ON public.orders FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS orders_seller_insert ON public.orders;
CREATE POLICY orders_seller_insert ON public.orders FOR INSERT TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS orders_seller_update ON public.orders;
CREATE POLICY orders_seller_update ON public.orders FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS orders_seller_delete ON public.orders;
CREATE POLICY orders_seller_delete ON public.orders FOR DELETE TO anon, authenticated USING (true);

-- Order items policies
DROP POLICY IF EXISTS order_items_public_read ON public.order_items;
CREATE POLICY order_items_public_read ON public.order_items FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS order_items_seller_insert ON public.order_items;
CREATE POLICY order_items_seller_insert ON public.order_items FOR INSERT TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS order_items_seller_update ON public.order_items;
CREATE POLICY order_items_seller_update ON public.order_items FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS order_items_seller_delete ON public.order_items;
CREATE POLICY order_items_seller_delete ON public.order_items FOR DELETE TO anon, authenticated USING (true);

-- Grants
GRANT SELECT, INSERT, UPDATE, DELETE ON public.orders TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.order_items TO anon, authenticated;
GRANT ALL ON public.orders, public.order_items TO service_role;

-- Sequence grants - create if not exists
DO $$
BEGIN
  IF to_regclass('public.orders_id_seq') IS NULL THEN
    CREATE SEQUENCE public.orders_id_seq START 1;
  END IF;
  IF to_regclass('public.order_items_id_seq') IS NULL THEN
    CREATE SEQUENCE public.order_items_id_seq START 1;
  END IF;
  GRANT USAGE, SELECT ON SEQUENCE public.orders_id_seq TO anon, authenticated;
  GRANT USAGE, SELECT ON SEQUENCE public.order_items_id_seq TO anon, authenticated;
END$$;

-- First, fix any invalid status values before adding constraint
UPDATE public.orders
SET status = 'pending'
WHERE status IS NULL 
   OR status NOT IN ('pending', 'accepted', 'confirmed', 'delivered', 'rejected');

-- Status constraint
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_status_check;
ALTER TABLE public.orders ADD CONSTRAINT orders_status_check CHECK (status IN ('pending', 'accepted', 'confirmed', 'delivered', 'rejected'));

-- Pickup type constraint
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_pickup_type_check;
ALTER TABLE public.orders ADD CONSTRAINT orders_pickup_type_check CHECK (pickup_type IN ('buyer_pickup', 'delivery'));

-- Updated at trigger
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_orders_updated_at ON public.orders;
CREATE TRIGGER update_orders_updated_at
BEFORE UPDATE ON public.orders
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Refresh schema
NOTIFY pgrst, 'reload schema';