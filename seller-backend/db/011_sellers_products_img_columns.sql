-- Migration 011: Convert product_img_* columns from bytea to text
-- Root cause: columns were created as bytea, so Cloudinary URLs were stored as hex.
-- PostgREST returned \xHEX strings instead of plain URLs.
-- Run this once in the Supabase SQL Editor.

DO $$
BEGIN
  -- Convert each image column from bytea to text using UTF-8 decoding.
  -- convert_from() reads the bytea as UTF-8 bytes and returns a text value.
  -- Existing NULL values are preserved.
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'sellers_products'
      AND column_name  = 'product_img_1'
      AND data_type    = 'bytea'
  ) THEN
    ALTER TABLE public.sellers_products
      ALTER COLUMN product_img_1 TYPE text USING convert_from(product_img_1, 'UTF8'),
      ALTER COLUMN product_img_2 TYPE text USING convert_from(product_img_2, 'UTF8'),
      ALTER COLUMN product_img_3 TYPE text USING convert_from(product_img_3, 'UTF8'),
      ALTER COLUMN product_img_4 TYPE text USING convert_from(product_img_4, 'UTF8'),
      ALTER COLUMN product_img_5 TYPE text USING convert_from(product_img_5, 'UTF8');

    RAISE NOTICE 'Migration 011: product_img_* columns converted bytea → text.';
  ELSE
    RAISE NOTICE 'Migration 011: columns already text, skipping.';
  END IF;
END $$;

-- Notify PostgREST to reload the schema cache
NOTIFY pgrst, 'reload schema';

