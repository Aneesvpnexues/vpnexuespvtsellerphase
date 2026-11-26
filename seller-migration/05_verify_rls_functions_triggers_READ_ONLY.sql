-- ============================================================================
-- 05_verify_rls_functions_triggers_READ_ONLY.sql
-- ============================================================================
-- TARGET : Run on BOTH projects (OLD = read only, NEW = read only) and
--          compare outputs. They must match.
-- PURPOSE: Prove that the "invisible" layer the app depends on arrived
--          intact:
--            * Row Level Security (RLS) enabled + every policy
--            * Table permissions (grants) for anon / service_role
--            * Triggers (automatic updated_at refreshers, etc.)
--            * Functions — including seller_lookup_registered (the RPC)
--              and their permission lists
-- SAFETY : ONLY SELECT statements. Safe everywhere.
--
-- HOW TO RUN: SQL Editor -> paste -> Run -> save as SECURITY-OLD.txt and
--             SECURITY-NEW.txt -> compare.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- A) Is RLS switched ON for each of the 7 tables?
--    Expect: rls_enabled = true for all 7 rows in BOTH projects.
-- ---------------------------------------------------------------------------
select tbl.relname as table_name,
       tbl.relrowsecurity as rls_enabled
from pg_class tbl
join pg_namespace n on n.oid = tbl.relnamespace
where n.nspname = 'public'
  and tbl.relname in ('sellers_products','seller_profiles',
                      'seller_registrations','seller_verify_your_details',
                      'seller_bank_details','seller_transactions',
                      'seller_lookup_rate_limits')
order by table_name;

-- ---------------------------------------------------------------------------
-- B) Every RLS policy (the per-role read/write rules).
--    Expect: identical policy names, roles, commands and expressions.
--    Important ones:
--      * seller_registrations."anon_can_register"  (INSERT only, role anon,
--        must keep its status='pending AND firebase_uid IS NULL AND
--        phone_verified=false check — the sign-up flow depends on it)
--      * seller_lookup_rate_limits -> ZERO policies (service-role only)
--      * seller_bank_details        -> ZERO anon policies (locked down;
--        only the seller-bank edge function may touch it)
-- ---------------------------------------------------------------------------
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
-- C) Table permissions (grants) per role.
--    Expect: identical lists in both projects.
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
-- D) Triggers on the 7 tables.
--    Expect: identical trigger names + definitions (for example
--    seller_registrations_touch_updated_at, seller_profiles_touch_updated_at,
--    update_orders_updated_at if orders were migrated).
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
-- E) Functions in the public schema with full source and permissions.
--    Expect: identical "definition_hash" values in both projects. If the
--    NEW project is missing a function (for example
--    seller_lookup_registered), copy its full_definition text from the OLD
--    output and paste it into the NEW project's SQL Editor — the text comes
--    from your own old database, so it is the real definition, not a guess.
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
-- F) Quick proof that the RPC is callable by the right role only.
--    Expect in BOTH projects: has_service_role = true, has_anon = false.
-- ---------------------------------------------------------------------------
select p.proname as function_name,
       has_function_privilege('service_role', p.oid, 'execute') as has_service_role,
       has_function_privilege('anon',         p.oid, 'execute') as has_anon,
       has_function_privilege('public',       p.oid, 'execute') as has_public_role
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'seller_lookup_registered';

-- ============================================================================
-- END of 05_verify_rls_functions_triggers_READ_ONLY.sql  (run on BOTH)
-- ============================================================================
