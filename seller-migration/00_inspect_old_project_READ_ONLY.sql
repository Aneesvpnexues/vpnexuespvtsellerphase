-- ============================================================================
-- 00_inspect_old_project_READ_ONLY.sql
-- ============================================================================
-- TARGET : OLD PROJECT  *** READ ONLY — SAFE TO RUN ON THE OLD PROJECT ***
-- PURPOSE: Capture the REAL, exact definitions of every Seller database
--          object from the old database. Nothing in the repository has the
--          CREATE TABLE statements for 4 of the 7 Seller tables, so this
--          script is how we retrieve the truth instead of guessing.
-- SAFETY : This file contains ONLY SELECT statements. It cannot create,
--          change, or delete anything. It only looks.
--
-- HOW TO RUN:
--   1. Open the Supabase Dashboard of the OLD project.
--   2. Left menu -> SQL Editor -> New query.
--   3. Paste this whole file and press Run (Ctrl+Enter).
--   4. Run it in SECTIONS (each "-- SECTION" block separately) so the output
--      stays readable. Copy each result (or use "Download as CSV") into a
--      text file named OLD-INSPECTION.txt and keep it — we will compare the
--      new project against this evidence later.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- SECTION A — Which database am I talking to? (identity check)
-- Expect: your OLD project's database name and Postgres version.
-- If this shows something you do not recognise, STOP — you are on the
-- wrong project.
-- ---------------------------------------------------------------------------
select current_database()                                   as database_name,
       current_user                                         as database_user,
       (select version())                                   as postgres_version,
       (select current_setting('server_version'))           as server_version;


-- ---------------------------------------------------------------------------
-- SECTION B — Landscape: EVERY table in the public schema + row counts.
-- This reveals the full picture: the 7 Seller tables, plus Buyer tables and
-- any Spring Boot (Render) backend tables that may live in this database.
-- Expect: one row per table with its row count. Save this list — it tells us
-- which extra tables exist that are NOT in our migration scope.
-- ---------------------------------------------------------------------------
select c.relname                                                   as table_name,
       (xpath('/row/c/text()',
              query_to_xml(format('select count(*) as c from public.%I',
                                  c.relname),
                           false, true, '')))[1]::text::bigint     as row_count,
       pg_size_pretty(pg_total_relation_size(c.oid))               as total_size
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind = 'r'
order by row_count desc nulls last, table_name;


-- ---------------------------------------------------------------------------
-- SECTION C — Exact column definitions of the 7 Seller tables.
-- This is the answer to "the CREATE TABLE statements are missing": every
-- column name, data type, length, nullability and default value, exactly as
-- they exist in the old database. Look for: text vs uuid vs bytea vs bigint,
-- DEFAULT nextval(...) (serial columns), and any duplicate-looking columns
-- (for example two name-ish or phone-ish columns). KEEP ALL OF THEM — the
-- migration copies them as-is; we do not clean anything up.
-- Expect: one row per column, ordered per table.
-- ---------------------------------------------------------------------------
select col.table_name,
       col.ordinal_position,
       col.column_name,
       col.data_type,
       col.udt_name,
       col.character_maximum_length,
       col.is_nullable,
       col.column_default,
       col.identity_generation
from information_schema.columns col
where col.table_schema = 'public'
  and col.table_name in (
        'sellers_products',
        'seller_profiles',
        'seller_registrations',
        'seller_verify_your_details',
        'seller_bank_details',
        'seller_transactions',
        'seller_lookup_rate_limits'
      )
order by col.table_name, col.ordinal_position;


-- ---------------------------------------------------------------------------
-- SECTION D — Unusual column types callout (bytea image columns, etc.).
-- Expect: one row for each bytea column. bytea = "binary data" columns
-- (the product image columns are of this type in the old database). This is
-- exactly why we use pg_dump for the copy: pg_dump handles binary columns
-- perfectly, while CSV export/import does NOT.
-- ---------------------------------------------------------------------------
select table_name, column_name, data_type
from information_schema.columns
where table_schema = 'public'
  and table_name in (
        'sellers_products',
        'seller_profiles',
        'seller_registrations',
        'seller_verify_your_details',
        'seller_bank_details',
        'seller_transactions',
        'seller_lookup_rate_limits'
      )
  and data_type in ('bytea', 'json', 'jsonb', 'array', 'user-defined')
order by table_name, column_name;


-- ---------------------------------------------------------------------------
-- SECTION E — Foreign keys (relationships) touching the 7 Seller tables.
--   * "from_table" = the table holding the reference
--   * "referenced_table" = the table being pointed at
-- Expect: possibly ZERO rows. If a Seller table references a table that is
-- NOT one of the 7 (for example "products"), we must decide before the
-- restore: either bring that referenced table along, or remove that one
-- foreign key in the NEW project. This query tells us which case we have.
-- ---------------------------------------------------------------------------
select rel.relname  as from_table,
       con.conname  as constraint_name,
       ref.relname  as referenced_table,
       pg_get_constraintdef(con.oid) as full_definition
from pg_constraint con
join pg_class rel on rel.oid = con.conrelid
join pg_class ref on ref.oid = con.confrelid
join pg_namespace n on n.oid = rel.relnamespace
where n.nspname = 'public'
  and con.contype = 'f'
  and (rel.relname in ('sellers_products','seller_profiles',
                       'seller_registrations','seller_verify_your_details',
                       'seller_bank_details','seller_transactions',
                       'seller_lookup_rate_limits')
    or ref.relname in ('sellers_products','seller_profiles',
                       'seller_registrations','seller_verify_your_details',
                       'seller_bank_details','seller_transactions',
                       'seller_lookup_rate_limits'))
order by from_table, referenced_table;


-- ---------------------------------------------------------------------------
-- SECTION F — Primary keys, UNIQUE and CHECK constraints of the 7 tables.
-- Expect: a PRIMARY KEY for most tables, UNIQUE constraints (for example
-- seller_registrations.phone_e164), and CHECK rules (allowed status values,
-- amount > 0, ...). pg_dump copies these automatically; this output is our
-- "expected list" for verification.
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
  and con.contype in ('p','u','c')
  and tbl.relname in ('sellers_products','seller_profiles',
                      'seller_registrations','seller_verify_your_details',
                      'seller_bank_details','seller_transactions',
                      'seller_lookup_rate_limits')
order by table_name, constraint_type, constraint_name;


-- ---------------------------------------------------------------------------
-- SECTION G — Indexes of the 7 tables.
-- Expect: the PRIMARY KEY index plus the named indexes from the repository
-- SQL (017/018/021...) and any others that exist only in the old database.
-- ---------------------------------------------------------------------------
select tablename, indexname, indexdef
from pg_indexes
where schemaname = 'public'
  and tablename in ('sellers_products','seller_profiles',
                    'seller_registrations','seller_verify_your_details',
                    'seller_bank_details','seller_transactions',
                    'seller_lookup_rate_limits')
order by tablename, indexname;


-- ---------------------------------------------------------------------------
-- SECTION H — Row Level Security (RLS): enabled flag + every policy.
-- RLS = the database's own gatekeeper rules that decide which role (anon,
-- authenticated, service_role) may read or write which rows. These MUST
-- exist identically in the new project or the app will get
-- "permission denied / row-level security" errors.
-- Expect: relrowsecurity = true for all 7 tables, plus the policy list
-- (for example "Allow all reads", "anon_can_register", ...).
-- ---------------------------------------------------------------------------
select tbl.relname        as table_name,
       tbl.relrowsecurity as rls_enabled
from pg_class tbl
join pg_namespace n on n.oid = tbl.relnamespace
where n.nspname = 'public'
  and tbl.relname in ('sellers_products','seller_profiles',
                      'seller_registrations','seller_verify_your_details',
                      'seller_bank_details','seller_transactions',
                      'seller_lookup_rate_limits')
order by table_name;

select schemaname, tablename, policyname, permissive, roles, cmd,
       qual as using_expression, with_check as with_check_expression
from pg_policies
where schemaname = 'public'
  and tablename in ('sellers_products','seller_profiles',
                    'seller_registrations','seller_verify_your_details',
                    'seller_bank_details','seller_transactions',
                    'seller_lookup_rate_limits')
order by tablename, policyname;


-- ---------------------------------------------------------------------------
-- SECTION I — Triggers on the 7 tables + the SQL of their functions.
-- A trigger is a rule that makes the database run some code automatically
-- when you insert or update a row (for example "always refresh updated_at").
-- Expect: for example seller_registrations_touch_updated_at,
-- seller_profiles_touch_updated_at, update_orders_updated_at. The function
-- bodies printed here are what we will re-create in the NEW project.
-- ---------------------------------------------------------------------------
select tbl.relname as table_name,
       trg.tgname  as trigger_name,
       pg_get_triggerdef(trg.oid) as trigger_definition
from pg_trigger trg
join pg_class tbl on tbl.oid = trg.tgrelid
join pg_namespace n on n.oid = tbl.relnamespace
where n.nspname = 'public'
  and not trg.tgisinternal
  and tbl.relname in ('sellers_products','seller_profiles',
                      'seller_registrations','seller_verify_your_details',
                      'seller_bank_details','seller_transactions',
                      'seller_lookup_rate_limits')
order by table_name, trigger_name;


-- ---------------------------------------------------------------------------
-- SECTION J — EVERY function in the public schema, with full source code.
-- Includes seller_lookup_registered (the RPC) and the trigger helper
-- functions (set_updated_at, update_updated_at_column, ...).
-- Expect: one or more rows; copy the "full_definition" column text for each
-- into your OLD-INSPECTION.txt — we will paste these into the NEW project.
-- ---------------------------------------------------------------------------
select p.proname as function_name,
       pg_get_function_identity_arguments(p.oid) as arguments,
       p.prosecdef as is_security_definer,
       coalesce(p.proacl::text, '(default)') as permissions,
       md5(pg_get_functiondef(p.oid)) as definition_hash,
       pg_get_functiondef(p.oid) as full_definition
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
order by function_name, arguments;


-- ---------------------------------------------------------------------------
-- SECTION K — Sequences (the counters behind id columns) and their values.
-- A sequence is the numbering machine that produces the next id
-- (id = 1, 2, 3, ...). seller_bank_details_id_seq is the famous one: its
-- current value MUST be carried to the new project, or new rows will collide
-- with migrated rows ("duplicate key" errors).
-- Expect: one row per sequence with last_value and the column it feeds.
-- ---------------------------------------------------------------------------
select seq.schemaname,
       seq.sequencename,
       seq.last_value,
       seq.start_value,
       seq.increment_by,
       seq.owned_by
from pg_sequences seq
where seq.schemaname = 'public'
order by seq.sequencename;


-- ---------------------------------------------------------------------------
-- SECTION L — Table permissions (grants) for the three app roles.
-- Expect: rows for anon / authenticated / service_role on the Seller tables.
-- pg_dump restores these automatically; this is the "expected list".
-- ---------------------------------------------------------------------------
select table_name, grantee,
       string_agg(privilege_type, ', ' order by privilege_type) as privileges
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name in ('sellers_products','seller_profiles',
                     'seller_registrations','seller_verify_your_details',
                     'seller_bank_details','seller_transactions',
                     'seller_lookup_rate_limits')
  and grantee in ('anon','authenticated','service_role','postgres')
group by table_name, grantee
order by table_name, grantee;


-- ---------------------------------------------------------------------------
-- SECTION M — Installed extensions (add-on modules the tables rely on).
-- Expect: a short list (pgcrypto is common). If the NEW project is missing
-- one of these, the restore would fail with "type does not exist" — we
-- enable the same extensions in the NEW project first (Phase 3).
-- ---------------------------------------------------------------------------
select extname as extension_name,
       extversion as version
from pg_extension
order by extname;


-- ---------------------------------------------------------------------------
-- SECTION N — Storage: the product-images bucket, its files, its rules.
-- Expect: one bucket row "product-images" (public), an object count, and
-- 3 policies on storage.objects. The object count is the number we must
-- reproduce in the NEW project after copying the files.
-- ---------------------------------------------------------------------------
select id as bucket_name,
       public as is_public,
       file_size_limit,
       allowed_mime_types,
       created_at
from storage.buckets
order by id;

select bucket_id,
       count(*) as file_count
from storage.objects
group by bucket_id
order by bucket_id;

select policyname, cmd, roles, qual, with_check
from pg_policies
where schemaname = 'storage' and tablename = 'objects'
order by policyname;


-- ---------------------------------------------------------------------------
-- SECTION O — Final evidence: row counts of exactly the 7 Seller tables.
-- Expect: 7 rows. Write these numbers down — Phase 11 re-runs the same
-- counts on the NEW project and they must match exactly.
-- ---------------------------------------------------------------------------
select 'sellers_products'          as table_name, count(*) as row_count from public.sellers_products
union all
select 'seller_profiles',          count(*) from public.seller_profiles
union all
select 'seller_registrations',     count(*) from public.seller_registrations
union all
select 'seller_verify_your_details',count(*) from public.seller_verify_your_details
union all
select 'seller_bank_details',      count(*) from public.seller_bank_details
union all
select 'seller_transactions',      count(*) from public.seller_transactions
union all
select 'seller_lookup_rate_limits',count(*) from public.seller_lookup_rate_limits
order by 1;

-- ============================================================================
-- END of 00_inspect_old_project_READ_ONLY.sql  (OLD PROJECT — READ ONLY)
-- ============================================================================
