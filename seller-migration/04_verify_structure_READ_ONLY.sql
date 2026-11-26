-- ============================================================================
-- 04_verify_structure_READ_ONLY.sql
-- ============================================================================
-- TARGET : Run on BOTH projects (OLD = read only, NEW = read only) and
--          compare the outputs line by line. They must be identical.
-- PURPOSE: Prove that every column (name, type, length, default, nullability),
--          every primary key / unique / check constraint and every index in
--          the NEW project matches the OLD project exactly.
-- SAFETY : ONLY SELECT statements. Safe everywhere.
--
-- HOW TO RUN: SQL Editor -> paste -> Run -> save as STRUCTURE-OLD.txt and
--             STRUCTURE-NEW.txt -> compare (a plain text diff tool or
--             careful eyeballing; the rows are sorted so they line up).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- A) Columns: name, type, size, nullability, default — per table.
--    Expect: byte-for-byte identical lists in both projects (including the
--    unusual names such as product_descrption / product_avaliblit and the
--    duplicate-looking columns — they must be preserved as they are).
-- ---------------------------------------------------------------------------
select col.table_name,
       col.ordinal_position,
       col.column_name,
       col.data_type,
       col.udt_name,
       col.character_maximum_length,
       col.is_nullable,
       col.column_default
from information_schema.columns col
where col.table_schema = 'public'
  and col.table_name in ('sellers_products','seller_profiles',
                         'seller_registrations','seller_verify_your_details',
                         'seller_bank_details','seller_transactions',
                         'seller_lookup_rate_limits')
order by col.table_name, col.ordinal_position;

-- ---------------------------------------------------------------------------
-- B) Constraints: PRIMARY KEY, UNIQUE, CHECK (and foreign keys if any).
--    Expect: identical list. The definition text must match exactly.
-- ---------------------------------------------------------------------------
select tbl.relname as table_name,
       con.conname as constraint_name,
       case con.contype
         when 'p' then 'PRIMARY KEY'
         when 'u' then 'UNIQUE'
         when 'c' then 'CHECK'
         when 'f' then 'FOREIGN KEY'
       end as constraint_type,
       pg_get_constraintdef(con.oid) as full_definition
from pg_constraint con
join pg_class tbl on tbl.oid = con.conrelid
join pg_namespace n on n.oid = tbl.relnamespace
where n.nspname = 'public'
  and tbl.relname in ('sellers_products','seller_profiles',
                      'seller_registrations','seller_verify_your_details',
                      'seller_bank_details','seller_transactions',
                      'seller_lookup_rate_limits')
order by table_name, constraint_type, constraint_name;

-- ---------------------------------------------------------------------------
-- C) Indexes (speed structures, including UNIQUE indexes).
--    Expect: identical list in both projects.
-- ---------------------------------------------------------------------------
select tablename, indexname, indexdef
from pg_indexes
where schemaname = 'public'
  and tablename in ('sellers_products','seller_profiles',
                    'seller_registrations','seller_verify_your_details',
                    'seller_bank_details','seller_transactions',
                    'seller_lookup_rate_limits')
order by tablename, indexname;

-- ============================================================================
-- END of 04_verify_structure_READ_ONLY.sql  (run on BOTH, compare)
-- ============================================================================
