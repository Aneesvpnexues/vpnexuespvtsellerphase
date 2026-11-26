-- ============================================================================
-- 02_fix_sequences.sql
-- ============================================================================
-- TARGET : NEW SELLER PROJECT  (destination — run ONLY here, AFTER the
--          data restore in Phase 5)
-- PURPOSE: A "sequence" is the counter that generates the next id for a
--          table (1, 2, 3, ...). When rows are copied between databases the
--          counter often stays at its old starting value, so the NEXT insert
--          in the new project would try to reuse an id that is already taken
--          -> "duplicate key value violates unique constraint" errors.
--          This script re-reads each table's real maximum id and points the
--          sequence just past it. The most important one is
--          seller_bank_details_id_seq (legacy ids are millisecond
--          timestamps, far ahead of any counter).
-- SAFETY : Runs only where you execute it. Execute it ONLY in the NEW
--          Seller project. It never touches the old project.
--
-- HOW TO RUN:
--   Supabase Dashboard of the NEW Seller project -> SQL Editor -> paste ->
--   Run. Read the "NOTICE" messages in the result panel: each line tells
--   you which sequence was corrected and from what value to what value.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- STEP 1 — Re-point every sequence in the public schema to max(id) of the
--          column it feeds. Handles both "table has rows" (set to max, so
--          the next id = max + 1) and "table is empty" (restart at 1).
-- ---------------------------------------------------------------------------
do $$
declare
  seq record;
  v_max bigint;
  v_current bigint;
begin
  for seq in
    select distinct on (c.oid)
           c.relname  as seq_name,
           t.relname  as tbl_name,
           a.attname  as col_name
    from pg_class c
    join pg_namespace n    on n.oid = c.relnamespace
    join pg_depend d      on d.objid    = c.oid
                         and d.classid  = 'pg_class'::regclass
                         and d.refclassid = 'pg_class'::regclass
                         and d.deptype in ('a','i')
    join pg_class t       on t.oid = d.refobjid
    join pg_attribute a   on a.attrelid = t.oid
                         and a.attnum   = d.refobjsubid
    where n.nspname = 'public'
      and c.relkind = 'S'
    order by c.oid
  loop
    execute format('select max(%I) from public.%I', seq.col_name, seq.tbl_name)
      into v_max;
    execute format('select last_value from public.%I', seq.seq_name)
      into v_current;

    if v_max is null then
      -- Empty table: next generated id must be 1.
      perform setval(seq.seq_name, 1, false);
      raise notice 'SEQUENCE %: table %.% is empty -> reset to 1 (was %)',
                   seq.seq_name, seq.tbl_name, seq.col_name, v_current;
    elsif v_current is distinct from v_max then
      -- Rows copied in: jump the counter just past the biggest existing id.
      perform setval(seq.seq_name, v_max, true);
      raise notice 'SEQUENCE %: %.% max(id)=% -> last_value % => % (FIXED)',
                   seq.seq_name, seq.tbl_name, seq.col_name,
                   v_max, v_current, v_max;
    else
      raise notice 'SEQUENCE %: already correct at %', seq.seq_name, v_current;
    end if;
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- STEP 2 — Show the final state of every public sequence (evidence).
-- Expect: one row per sequence; "last_value" must be >= the max id of the
--          table it belongs to. seller_bank_details_id_seq will show a very
--          large number (a millisecond timestamp) — that is normal.
-- ---------------------------------------------------------------------------
select schemaname,
       sequencename,
       last_value,
       owned_by
from pg_sequences
where schemaname = 'public'
order by sequencename;

-- ---------------------------------------------------------------------------
-- STEP 3 — Public sequences that belong to NO table (orphans), if any.
-- Expect: usually zero rows. Any row here is listed only for awareness;
--          nothing in the Seller app depends on orphan sequences.
-- ---------------------------------------------------------------------------
select c.relname as orphan_sequence
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind = 'S'
  and not exists (
        select 1
        from pg_depend d
        where d.objid = c.oid
          and d.classid = 'pg_class'::regclass
          and d.deptype in ('a','i')
      )
order by c.relname;

-- ---------------------------------------------------------------------------
-- STEP 4 — Ask PostgREST (the REST API layer the Flutter app uses) to
--          reload its schema cache so the app immediately sees the newly
--          restored tables. Expect: "NOTIFY".
-- ---------------------------------------------------------------------------
notify pgrst, 'reload schema';

-- ============================================================================
-- END of 02_fix_sequences.sql  (NEW SELLER PROJECT — destination only)
-- ============================================================================
