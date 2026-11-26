-- ============================================================================
-- 01_precheck_new_project.sql
-- ============================================================================
-- TARGET : NEW SELLER PROJECT  (destination — this is the only project
--          where migration changes are allowed)
-- PURPOSE: Confirm the destination is empty, healthy and ready BEFORE we
--          restore anything. Running this first prevents the classic mistake
--          of restoring into the wrong project or on top of existing data.
-- SAFETY : This file contains ONLY SELECT statements. It changes nothing.
--
-- HOW TO RUN:
--   1. Open the Supabase Dashboard of the NEW Seller project.
--   2. Left menu -> SQL Editor -> New query.
--   3. Paste this file and press Run.
--   4. Check every result against the "Expect" notes below.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- SECTION A — Identity check: am I really on the NEW Seller project?
-- Expect: a database name and version. Cross-check the project name shown in
-- the top-left of the Dashboard. NEVER run migration steps if this does not
-- match your NEW Seller project.
-- ---------------------------------------------------------------------------
select current_database()                         as database_name,
       current_user                               as database_user,
       current_setting('server_version')          as postgres_version;


-- ---------------------------------------------------------------------------
-- SECTION B — The 7 Seller tables must NOT exist yet (empty destination).
-- Expect: 7 rows, every "already_exists" = false.
--   * If all are false  -> destination is clean, continue.
--   * If any is true    -> STOP. Either you are on the wrong project, or a
--     previous attempt already created tables. Do NOT restore on top.
--     Ask for guidance before doing anything else (dropping partial
--     objects is only ever done in the NEW project, never the old one).
-- ---------------------------------------------------------------------------
select t.table_name,
       (to_regclass('public.' || t.table_name) is not null) as already_exists
from (values ('sellers_products'),
             ('seller_profiles'),
             ('seller_registrations'),
             ('seller_verify_your_details'),
             ('seller_bank_details'),
             ('seller_transactions'),
             ('seller_lookup_rate_limits')) as t(table_name)
order by t.table_name;


-- ---------------------------------------------------------------------------
-- SECTION C — The three application roles must exist.
-- Supabase creates them automatically. Expect: anon, authenticated,
-- service_role and postgres — 4 rows. (The app talks as "anon"; edge
-- functions talk as "service_role"; "authenticated" is unused because the
-- app uses Firebase Auth, but the role must still exist because the old
-- schema grants permissions to it.)
-- ---------------------------------------------------------------------------
select rolname
from pg_roles
where rolname in ('anon','authenticated','service_role','postgres')
order by rolname;


-- ---------------------------------------------------------------------------
-- SECTION D — Extensions the old database uses must be AVAILABLE here.
-- Expect: pgcrypto (and possibly uuid-ossp / pg_cron / pg_net) listed with
-- installed_version NOT null (already on) or null (available, we may need
-- to enable). Compare with Section M of the OLD inspection: every extension
-- the old project has installed should also be installable here.
-- Later, if the restore fails with "type does not exist" / "function does
-- not exist", enable the missing one in the NEW project with:
--     create extension if not exists "pgcrypto";
-- (That statement runs only in the NEW project.)
-- ---------------------------------------------------------------------------
select name, default_version, installed_version
from pg_available_extensions
where name in ('pgcrypto','uuid-ossp','pg_cron','pg_net','pg_hashagg')
order by name;


-- ---------------------------------------------------------------------------
-- SECTION E — Storage must be present (it always is on Supabase).
-- Expect: true, plus the 3 default roles' ability to use storage.
-- ---------------------------------------------------------------------------
select (to_regnamespace('storage') is not null) as storage_schema_exists,
       (to_regnamespace('auth')    is not null) as auth_schema_exists;


-- ---------------------------------------------------------------------------
-- SECTION F — How much room does the destination have?
-- Expect: a few hundred MB free at minimum. If the old Seller data is
-- larger than the free space, the restore will fail partway (it would roll
-- back atomically, but still). Check Dashboard -> Project Settings ->
-- Usage for the real numbers.
-- ---------------------------------------------------------------------------
select pg_size_pretty(
         pg_database_size(current_database())
       ) as current_database_size;

-- ============================================================================
-- END of 01_precheck_new_project.sql  (NEW SELLER PROJECT — destination)
-- ============================================================================
