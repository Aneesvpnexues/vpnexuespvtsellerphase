# SELLER SUPABASE MIGRATION GUIDE

### Complete, risk-free plan to copy the Seller app's database from the OLD Supabase project to the NEW Seller Supabase project

---

> ## ⚠️ THE ONE RULE THAT PROTECTS EVERYTHING
>
> | Label | Project | What we ever do to it |
> |---|---|---|
> | 📕 **OLD PROJECT (READ ONLY)** | Your existing project that holds Seller **and** Buyer data | **READ and EXPORT only.** Every script we run there is `SELECT`-only. We never delete, update, drop, re-configure, or "clean up" anything in it. `pg_dump` only reads. |
> | 📗 **NEW SELLER PROJECT (DESTINATION)** | The new "Seller" project in your other Supabase account | **All changes happen only here.** Restore, fixes, bucket creation, edge functions — everything destination-side. |
>
> If any instruction is ever unclear about which project it targets, **stop** and re-read this box.
> This guide itself performs nothing. You execute each step, one at a time, and only when you understand it.

---

## How to use this guide

- Read **Part 1 (Glossary)** first if any database word is unfamiliar — everything else assumes those words.
- Follow the **Phases in order**. Each phase has: *What → Why → Where to click → Commands → What success looks like → What to do if it fails*.
- Every command is labeled with the project it targets: 📕 OLD (read only) or 📗 NEW.
- Keep a text file open (e.g. `MIGRATION-NOTES.txt`) and paste in every result the guide tells you to save. You will need them for verification and for recovering edge-function secrets.
- **Do not mark the migration "done" until every item in Part 9 (Final Checklist) is checked.**

---

# PART 1 — Glossary (plain-English definitions)

| Term | What it means |
|---|---|
| **Supabase project** | A separate cloud database + API + storage + serverless functions bundle. Your OLD project and NEW project are two completely independent islands — nothing flows between them automatically. |
| **Table** | A structured sheet in the database: rows = records, columns = fields (e.g. `seller_profiles`). |
| **Schema** | The *structure* of the data: table names, column names, data types, rules. Not the records themselves. |
| **Row / record** | One entry in a table (one seller, one product, ...). |
| **Data type** | What kind of value a column holds: `text` (words), `bigint` (large whole numbers), `uuid` (a 36-character id), `bytea` (raw binary — used by the old product image columns), `timestamptz` (date+time with timezone), `numeric` (precise decimal — money). |
| **Primary key** | The unique id column that makes each row one-of-a-kind (e.g. `id`). |
| **Unique constraint** | A rule: this column may never contain duplicates (e.g. `seller_registrations.phone_e164`). |
| **Check constraint** | A rule: values must satisfy a condition (e.g. `amount > 0`, `status IN ('pending','linked')`). |
| **Foreign key (FK)** | A link from one table's column to another table's primary key ("this order belongs to that seller"). |
| **Index** | A lookup structure that makes queries fast. |
| **Default value** | What a column gets if you don't supply one (e.g. `DEFAULT now()`). |
| **Sequence** | The counter behind `id` columns (`nextval` = "give me the next number"). `seller_bank_details_id_seq` is the tricky one because its old ids are millisecond timestamps. |
| **Function** | A stored SQL program in the database. `seller_lookup_registered` is an **RPC** = a function the app/edge functions call over the network. |
| **Trigger** | A rule that makes the database run a function automatically on insert/update (e.g. refresh `updated_at`). |
| **RLS (Row Level Security)** | Per-row gatekeeping rules attached to a table that decide which *role* may read/write. |
| **Roles** | Database user identities: `anon` (what the Flutter app uses, via the anon key), `authenticated` (unused — app uses Firebase), `service_role` (what edge functions use; bypasses RLS), `postgres` (admin — you, in the SQL Editor). |
| **Anon key** | A public API key the app embeds. Safe to ship in an app; protected by RLS. |
| **Service-role key** | A powerful secret key that bypasses RLS. **Never** put it in app code. Only in edge functions / your local scripts. |
| **Storage bucket** | A folder-like file store inside Supabase (e.g. `product-images`). |
| **Edge Function** | Serverless TypeScript code running on Supabase's servers (your 4 seller functions). |
| **PostgREST / SQL Editor** | PostgREST is the engine turning REST URLs into SQL. SQL Editor = the browser page where you run SQL by hand. |
| **pg_dump / psql** | Free command-line PostgreSQL tools. `pg_dump` = "photograph a database (structure+rows) into a file". `psql` = "run an SQL file against a database". |
| **Connection string (URI)** | One line containing host + user + password + database, e.g. `postgresql://postgres.abc:pw@aws-0-x.pooler.supabase.com:5432/postgres`. |
| **Pooler** | Supabase's connection middleman. Use the **Session pooler (port 5432)** for pg_dump/psql — it is the most compatible option. |
| **NOTIFY pgrst** | A message telling the REST layer "reload your knowledge of the tables" so the app sees new tables immediately. |

---

# PART 2 — What we are migrating

## 2.1 The 7 Seller tables (scope confirmed)

`sellers_products`, `seller_profiles`, `seller_registrations`, `seller_verify_your_details`, `seller_bank_details`, `seller_transactions`, `seller_lookup_rate_limits`

Full detail (columns, operations, screens) is in **`SELLER_SUPABASE_TABLE_AUDIT.md`** in this repository. The complete object checklist is **Appendix A**; external services are **Appendix B**.

## 2.2 What is intentionally NOT in scope (and why)

| Object | Why excluded |
|---|---|
| `orders`, `order_items` | The Seller app's order code exists but is **dormant** (never imported); the Orders screen uses local demo data. The Buyer app owns these. *Exception:* if your old DB shows a foreign key **from one of the 7 tables into** `orders`/`products`, see Phase 2 Section E — we handle it then. |
| `seller_reviews` | Never used by the Seller app (reviews are stored locally on the device). |
| `products` | Never used by the Seller app (its catalog is `sellers_products`). Only relevant if a foreign key forces it — checked in Phase 2. |
| Buyer tables, Spring Boot (Render) backend tables | Different applications. Identified but not copied (Phase 13 decides their fate separately). |
| Supabase Auth (`auth` schema) | Not used — the app authenticates with **Firebase Phone Auth**. |
| Cloudinary images | Not Supabase — they stay where they are. |

## 2.3 The special-attention items you asked about

| Item | Finding | What the plan does |
|---|---|---|
| **Missing SQL migrations 001–016** | The repo has only 017–024. `CREATE TABLE` for 4 of the 7 tables exists **only in the old database**. | We do **not** guess. Phase 2 extracts the real definitions from the old DB; Phase 4–5 copy them with `pg_dump` (which reads the real thing). |
| **Unusual column names** (`product_descrption`, `product_avaliblit`, `IFSC_code`, `account_houlder_name`) | Real column names with typos — the app code writes them exactly like that. | Copied verbatim. **Never rename anything** during migration. |
| **Duplicate-looking columns** (`seller_profiles`: `user_id` + `firebase_uid` + `phone_number`; possibly two name/phone columns; `seller_bank_details`: possible holder-name twins) | Legacy evolution: rows can be keyed three different ways. | Copied verbatim. Phase 2 Section C shows you every column so you see the real list. |
| **bytea image columns** in `sellers_products` (`product_img_1..5`) | Binary columns (the app even hex-decodes `\x…` values). | **This is why we use `pg_dump`, not CSV export/import** — CSV corrupts binary data; `pg_dump` handles it perfectly. |
| **`seller_bank_details_id_seq`** | Legacy ids are millisecond timestamps (huge), sequence must jump past them. | `pg_dump` carries the sequence value; `02_fix_sequences.sql` double-checks and repairs it. |
| **`seller_transactions_id_seq`** | Normal bigserial counter. | Same protection (fix script). |
| **KYC document storage** | Two paths: (1) the **app** stores only *file names/status* in `seller_verify_your_details` — files stay on the phone; (2) the **Render Spring Boot backend** stores actual KYC files in a *private bucket* (its own backend, separate credentials). | Table data migrates with Phase 5. The private bucket is investigated in Phase 13. |
| **Cloudinary** | External image service; primary image store for new photos. | No data moves. Its 3 secrets must be set on the NEW project's edge functions (Phase 10). |
| **Firebase** | Identity provider; independent of Supabase. | **Nothing to change.** |
| **Render Spring Boot backend** | Separate service (`vpnexues-seller-backend.onrender.com`) with its own Supabase credentials in Render's environment. May point at the OLD project. | Investigated read-only in Phase 13; migrating it is a **separate, later decision** — it does not block the app switch. |
| **`orders`/`order_items` FK → `products`** | Exists in repo SQL 019 (not our scope). | Only relevant if Phase 2 Section E finds FKs among *our 7 tables*. |

---

# PART 3 — Migration strategy (the big picture)

**Method chosen: `pg_dump` (photograph) → `psql` (restore).** Why this is the safest for a beginner:

1. It copies **structure and rows in one file, in dependency order** — columns, types, defaults, primary keys, checks, uniques, indexes, RLS policies, grants, triggers, and sequence values all come across exactly as they are. No hand-written `CREATE TABLE`, therefore **no guessed schema**.
2. It is **read-only on the old project** — `pg_dump` never writes.
3. The restore runs inside **one transaction with stop-on-error**: if anything fails, *everything rolls back* and the NEW project is left clean — no half-migrated mess.

**What pg_dump does NOT include** (so we handle them separately): functions whose tables aren't dumped (Phase 6), the storage bucket + files (Phases 8–9), edge functions (Phase 10).

### Phase overview — what runs where

| Phase | Name | Runs against | Tool | Changes anything? |
|---|---|---|---|---|
| 0 | Record credentials & labels | — | Dashboard (view) | No |
| 1 | Install tools (pg_dump/psql) | your PC | installer | PC only |
| 2 | **Inspect old schema** | 📕 OLD | SQL script `00` | **No (read only)** |
| 3 | **Precheck destination** | 📗 NEW | SQL script `01` | No (SELECTs) |
| 4 | **Dump structure+data** | 📕 OLD (reads) | `pg_dump` → file | **No (read only)** |
| 5 | **Restore into destination** | 📗 NEW | `psql` | **Yes (NEW only)** |
| 6 | Functions & their permissions | 📗 NEW | SQL (text from Phase 2) | Yes (NEW only) |
| 7 | Fix sequences | 📗 NEW | SQL script `02` | Yes (NEW only) |
| 8 | Create `product-images` bucket | 📗 NEW | repo SQL `024` | Yes (NEW only) |
| 9 | Copy bucket files | 📕 reads → 📗 writes | PowerShell script | Old: no / New: yes |
| 10 | Deploy 4 edge functions + secrets | 📗 NEW | Supabase CLI | Yes (NEW only) |
| 11 | **Verification suite** | 📕 OLD + 📗 NEW | SQL scripts `03–06` | **No (read only)** |
| 12 | Smoke test (rolled back) | 📗 NEW | SQL script `07` | No (rolls back) |
| 13 | External services review | Firebase/Cloudinary/Render | Dashboards (view) | No |
| 14 | Switch the Flutter app | your repo | editor + `flutter run` | App config only |
| 15 | Post-switch watch & retire plan | — | — | — |

**Golden rule repeated:** the only phases that *write* are 5, 6, 7, 8, 9 (new side), 10 (new side) and 14 (your app config). Everything touching 📕 OLD is read-only by construction.

---

# PART 4 — Phase-by-phase instructions

## Phase 0 — Record credentials for BOTH projects (view only)

**What/Why:** You will need 6 values. Writing them down now prevents mid-migration panic.

**Where to click (do this for OLD first, then NEW):**

1. Open the Supabase Dashboard and select the project.
2. **Project URL + anon key:** click **Connect** (top bar) → *Project URL*; then **Project Settings (gear, bottom-left) → API Keys → "Legacy API keys" tab** → copy the **`anon` `public`** key.
   *(If you only see "Publishable/Secret" keys, open the **Legacy API keys** tab — this app uses the classic JWT-style `anon` key.)*
3. **Connection string (for pg_dump/psql):** **Connect → Database → Session pooler (port 5432)** → copy the **URI**. Replace `[YOUR-PASSWORD]` with your database password (Project Settings → Database → *Connection string* → reset password if forgotten — reset it on **each** project separately; resetting does not alter data).
4. **service-role key (NEW project only):** **Project Settings → API Keys → Legacy API keys → `service_role`** (reveal + copy). This is the secret for edge functions and the copy script — **never** put it in the app.

Record in `MIGRATION-NOTES.txt`:

```
OLD (READ ONLY):  url = https://xxxx.supabase.co
                  anon key = ...
                  session-pooler URI = postgresql://postgres.xxx:***@aws-0-....pooler.supabase.com:5432/postgres
NEW (DESTINATION): url = https://yyyy.supabase.co
                  anon key = ...
                  service_role key = ...      <- keep secret
                  session-pooler URI = postgresql://postgres.yyy:***@aws-0-....pooler.supabase.com:5432/postgres
                  project ref = yyy           <- the part between "postgres." and ":"
```

**Success:** all 6 values present. **If a page looks different** than described (dashboard updates over time), the equivalents are always under *Project Settings* and *Connect*.

---

## Phase 1 — Install the tools (your PC)

**What/Why:** `pg_dump` and `psql` are the industry-standard, safest tools for this job. You need them on your Windows machine.

**Steps:**

1. Go to <https://www.postgresql.org/download/windows/> → download the **"Binaries" ZIP** (no installer needed) *or* install PostgreSQL with the graphical installer (it ships the same tools).
2. Extract to e.g. `C:\pgsql` so that `C:\pgsql\bin\pg_dump.exe` exists.
3. Add `C:\pgsql\bin` to your PATH: Start → "env" → *Edit environment variables for your account* → *Path* → *New* → paste `C:\pgsql\bin` → OK.
4. Open a **new** PowerShell window and verify:

```powershell
pg_dump --version
psql --version
```

**Success:** both print a version (e.g. `pg_dump (PostgreSQL) 17.x`). A *newer* pg_dump than the server is fine (Supabase runs PG 15/17). **If "not recognized":** the PATH change needs a brand-new terminal window; check the folder really contains `pg_dump.exe`.

---

## Phase 2 — 📕 OLD PROJECT: inspect and capture the real schema (READ ONLY)

**What/Why:** The repo is missing migrations 001–016, so the *old database itself* is the only source of truth for the 4 tables without `CREATE TABLE`. This script captures everything: columns and types (including **bytea** and duplicate-looking columns), keys, indexes, RLS policies, triggers, functions (including the RPC), sequences, grants, extensions, storage, and per-table row counts.

**Where:** Dashboard of the **OLD project** → left menu **SQL Editor** → **New query** → paste `seller-migration/00_inspect_old_project_READ_ONLY.sql` → **Run** (Ctrl+Enter).

**How to run it:** execute it **section by section** (from `-- SECTION A` to the next `-- SECTION`) so each result stays readable. For each section: select the output → copy (or *Download as CSV*) → paste into `OLD-INSPECTION.txt`.

**What to expect:**

- **A:** database name + Postgres version → confirms you're on the OLD project. If it looks wrong, **stop**.
- **B:** *every* table in `public` with row counts — you'll see the 7 Seller tables plus Buyer/backend tables (evidence for Part 2.2).
- **C:** the real columns of the 7 tables — this is your missing 001–016 schema.
- **D:** bytea/json columns called out explicitly.
- **E:** foreign keys touching the 7 tables. **Critical decision input:**
  - **0 rows** → perfect, no cross-table dependencies; continue.
  - **A row like `seller_x → products`** → before Phase 5 choose: *(a)* add that table to the dump (extra `-t` flag, explained in Phase 4), or *(b)* keep it out and remove that one FK line from the dump file (Phase 4 shows exactly how). Default recommendation: if the referenced table is small and Seller-related, copy it too (option a).
- **F/G/H/I/J/K/L/M/N/O:** constraints, indexes, RLS, triggers, functions (copy every `full_definition` into your notes — needed in Phase 6), sequences (note `last_value`), grants, extensions, storage buckets/counts, and the 7 row counts.

**Success:** `OLD-INSPECTION.txt` contains sections A–O. **Errors:** if a section errors with *permission denied*, you are not using the `postgres` user — the SQL Editor always runs as `postgres`, so re-check you picked the OLD project. Nothing here can modify data.

---

## Phase 3 — 📗 NEW SELLER PROJECT: precheck (SELECTs only)

**What/Why:** Prove the destination is clean and ready *before* anything is written. Restoring on top of existing tables is the #1 beginner accident — this prevents it.

**Where:** Dashboard of the **NEW Seller project** → **SQL Editor** → paste `seller-migration/01_precheck_new_project.sql` → **Run**.

**What to expect / pass criteria:**

| Section | Expect | If not |
|---|---|---|
| A | recognizable NEW project name | You're on the wrong project — switch. |
| B | 7 rows, all `already_exists = false` | **STOP.** Wrong project or a prior partial attempt. Do not restore; ask before doing anything. |
| C | roles `anon, authenticated, postgres, service_role` | Supabase always has them — if missing, wrong project. |
| D | `pgcrypto` available | Note which extensions OLD has (Phase 2 M) that NEW lacks; enable with `create extension if not exists "pgcrypto";` **(NEW only)** if the restore later demands it. |
| E | storage + auth schemas exist | Wrong project. |
| D/E | free space larger than old data size | Upgrade plan or empty something in NEW first. |

**Also in this phase:** in the Dashboard of NEW, open **Connect → Database → Session pooler** and copy the URI into your notes (you got it in Phase 0 — just confirming it's there).

**Success:** Section B all-false. Only then continue.

---

## Phase 4 — 📕 OLD PROJECT: photograph structure + data into a file (READ ONLY)

**What/Why:** `pg_dump` reads the 7 tables (structure *and* rows, in dependency order) and writes everything into one plain-text file. It only ever sends read queries to the old project.

**Where:** your PC — PowerShell. Create a working folder:

```powershell
mkdir C:\seller-migration-work
cd C:\seller-migration-work
```

**The command — target: 📕 OLD PROJECT (read only):**

```powershell
pg_dump "PASTE-YOUR-OLD-SESSION-Pooler-URI-HERE" --no-owner -t public.sellers_products -t public.seller_profiles -t public.seller_registrations -t public.seller_verify_your_details -t public.seller_bank_details -t public.seller_transactions -t public.seller_lookup_rate_limits -f seller_migration_OLD_dump.sql
```

**Plain-language breakdown of every part:**

| Part | Meaning |
|---|---|
| `pg_dump "postgresql://..."` | "Photograph *this* database" — the URI is the **OLD** project's session-pooler URI from Phase 0 (read-only operation). |
| `--no-owner` | Don't try to recreate the old server's ownership settings (avoids harmless errors on the new server). |
| `-t public.<name>` (×7) | "Include exactly these tables." Repeat once per table. *(Add `-t public.<other_table>` here if Phase 2 Section E told you a referenced table must come along.)* |
| `-f seller_migration_OLD_dump.sql` | Write the photograph into this file. |

**What to expect:** the command prints progress (`Dumping the contents of table ...`) and exits with **no error**. You now have `seller_migration_OLD_dump.sql`.

**Sanity-check the file (still just reading a text file):**

```powershell
Select-String -Path seller_migration_OLD_dump.sql -Pattern "CREATE TABLE" | Measure-Object
Select-String -Path seller_migration_OLD_dump.sql -Pattern "REFERENCES" -Context 0,0
```

- Expect **7** `CREATE TABLE` lines (plus one per extra table you chose to include).
- The `REFERENCES` search shows any foreign keys inside the dump. Cross-check against Phase 2 Section E — every reference must point to a table **included in this dump**, or Phase 5 will fail (that failure is atomic — nothing partial is kept). Fix by either adding the table to Phase 4's command or editing out that single `ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY ...` line (comment it with `--`).

**Success:** file exists, 7 `CREATE TABLE`s, all `REFERENCES` resolvable. **Never** point this command at the NEW project by mistake (it would create a confusing file of the wrong database — harmless, but useless; just re-run with the right URI).

---

## Phase 5 — 📗 NEW SELLER PROJECT: restore the file (the only heavy write)

**What/Why:** `psql` executes the dump file against the NEW project. `--single-transaction` + `ON_ERROR_STOP=1` make it **all-or-nothing**: any error rolls the entire restore back, leaving the NEW project exactly as it was.

**The command — target: 📗 NEW SELLER PROJECT (destination):**

```powershell
psql "PASTE-YOUR-NEW-SESSION-POOLER-URI-HERE" --single-transaction -v ON_ERROR_STOP=1 -f seller_migration_OLD_dump.sql
```

| Part | Meaning |
|---|---|
| `psql "postgresql://..."` | "Execute this file *against* this database" — the **NEW** project's URI. |
| `--single-transaction` | Wrap the whole run in one transaction (BEGIN … COMMIT). Any error → automatic ROLLBACK. |
| `-v ON_ERROR_STOP=1` | Stop at the first error instead of limping on (without this, a partial run could commit!). |
| `-f seller_migration_OLD_dump.sql` | The file from Phase 4. |

**What to expect:** many lines like `CREATE TABLE`, `ALTER TABLE`, `COPY 123` (the row counts!), `CREATE POLICY`, `CREATE INDEX`, `setval(...)`. Ends **without** `ERROR`. The `COPY n` numbers should match Phase 2 Section O's counts.

**Verification (Phase 3 script again):** run `01_precheck_new_project.sql` Section B — now all 7 should be `already_exists = true`. Then run `03_verify_row_counts_READ_ONLY.sql` **on the NEW project only** and compare with your OLD numbers from Phase 2 Section O.

**If it fails:** the output shows the exact `ERROR` line and the NEW project is **unchanged** (rolled back). Common causes → Appendix D (`relation ... does not exist` = missing extension or you forgot Phase 3; `duplicate key` = tables already existed — Section B should have caught it; `permission denied` = not the postgres URI). Fix the cause, re-run — `psql` is safe to re-run only after a full rollback (the error message will confirm `ROLLBACK`).

**Success:** no `ERROR`, `COPY` counts match, script `01` Section B now all-true.

---

## Phase 6 — 📗 NEW: functions (including the RPC) and their permissions

**What/Why:** pg_dump was told to dump *tables*; functions that only those tables' triggers reference usually come along, but functions called over the network (the RPC `seller_lookup_registered`) and their permission rules must be guaranteed. We use the **exact source captured from your old database in Phase 2 Section J** — no guessing.

**Steps (target: 📗 NEW project):**

1. Open `OLD-INSPECTION.txt`, find Section J. For **each** function (`seller_lookup_registered`, `set_updated_at`, `update_updated_at_column`, and any others) copy its `full_definition` (the `CREATE OR REPLACE FUNCTION ... END;` block).
2. NEW Dashboard → **SQL Editor** → paste → **Run**. Do this for every function.
3. Also paste the permission lines you captured (they appear in the definition output's neighborhood in old DB terms — the standard pair, which Phase 2 confirmed):
   ```sql
   revoke execute on function public.seller_lookup_registered(text) from public, anon;
   grant  execute on function public.seller_lookup_registered(text) to service_role;
   ```
   *(These are copied from your inspection output — if your old DB shows different grants, use yours.)*
4. Finally run **`05_verify_rls_functions_triggers_READ_ONLY.sql`** on **both** projects and compare: `definition_hash` values must match for every function.

**Success:** Section E hashes identical OLD vs NEW; Section F shows `has_service_role = true`, `has_anon = false` on both.

**If a function errors:** the message names the missing dependency (e.g. a type from an extension → run `create extension if not exists ...` **(NEW only)** and retry; or a table → you'll see which table Phase 4 missed).

---

## Phase 7 — 📗 NEW: fix sequences

**What/Why:** The counters that generate the next `id` must sit *past* the largest copied id, or the app's first insert after migration fails with `duplicate key`. This script computes the correct value from the data itself.

**Where:** NEW → **SQL Editor** → paste `seller-migration/02_fix_sequences.sql` → **Run**.

**What to expect:** NOTICE lines such as `SEQUENCE seller_bank_details_id_seq: ... (FIXED)` or `already correct`, then a table of final sequence values, then `NOTIFY`. Pay attention to `seller_bank_details_id_seq` — it must show a large (timestamp-like) number ≥ `max(id)` from your Phase 2/3 counts.

**Success:** every sequence's `last_value` ≥ its table's `max(id)` (spot-check with `select max(id) from public.seller_bank_details;`).

---

## Phase 8 — 📗 NEW: create the `product-images` bucket

**What/Why:** The bucket (public file storage) + its 3 security policies live outside the tables, so pg_dump didn't bring them. The repository's own verified file `seller-backend/db/024_product_images_storage.sql` creates them.

**Where:** NEW → **SQL Editor** → open the repo file `seller-backend/db/024_product_images_storage.sql` → paste its **entire contents** → **Run**.

**What to expect:** `INSERT 0 1` (bucket row — `ON CONFLICT DO NOTHING`, harmless if repeated), `ALTER TABLE` (adds `unit` column — already there from the restore, so "no-op/notice"), `CREATE POLICY` ×3, `NOTIFY`. It is idempotent (safe if re-run).

**Alternative (if you prefer clicks):** **Storage (left menu) → Buckets → New bucket** → name `product-images` → **Public bucket: ON** → *Public object limits*: allowed MIME types `image/jpeg, image/png, image/webp, image/gif`, file size limit `10 MB` → Save. Then still run the 3 storage policies from `024` (they are the security half — easier to just run the SQL file, which does both).

**Verify:** run `06_verify_storage_READ_ONLY.sql` Section A on NEW — bucket `product-images`, `public = true`, limit `10485760`.

---

## Phase 9 — Copy the bucket files (📕 reads → 📗 writes)

**What/Why:** The image files themselves live in OLD storage. We download them (read) and upload them to NEW at identical paths.

**Step 1 — count first:** run `06_verify_storage_READ_ONLY.sql` on 📕 OLD, Section B → note `file_count` for `product-images`. Also check for **other buckets** (e.g. a KYC bucket) — note them; only `product-images` is in scope now (Phase 13 decides the rest).

**Step 2 — choose a path:**

- **Few files (≲ 30):** download from the OLD public URL pattern `https://OLD.supabase.co/storage/v1/object/public/product-images/<path>` in your browser (folder by folder), then upload to NEW via **Storage → product-images → Upload files** (keep the same folder structure `firebaseUid/...`).
- **Many files:** use the provided script (PowerShell 5+ or 7):

```powershell
cd C:\Users\ANJITH\StudioProjects\vpnexuespvtsellerphase\seller-migration

# keys from environment variables (recommended — never hardcode them):
$env:SUPABASE_OLD_URL            = "https://xxxx.supabase.co"
$env:SUPABASE_OLD_SERVICE_KEY    = "PASTE-OLD-service_role-KEY"
$env:SUPABASE_NEW_URL            = "https://yyyy.supabase.co"
$env:SUPABASE_NEW_SERVICE_KEY    = "PASTE-NEW-service_role-KEY"

# 1) list only — writes nothing anywhere:
.\copy_product_images.ps1 -ListOnly

# 2) TEST: copy just the first 3 files:
.\copy_product_images.ps1 -Limit 3
#    -> verify those 3 appear in NEW: Storage → product-images
#    -> also confirm they still exist in OLD (they must!)

# 3) full copy:
.\copy_product_images.ps1
```

**Safety properties:** reads OLD public URLs only (never writes OLD); uploads to NEW with `x-upsert`; verifies each file exists in NEW afterwards; prints `copied/failed` summary. **If execution policy blocks it:** `powershell -ExecutionPolicy Bypass -File .\copy_product_images.ps1 -ListOnly`.

**Success:** script reports 0 failed **and** `06_verify_storage_READ_ONLY.sql` shows **identical `file_count` in OLD and NEW**.

---

## Phase 10 — 📗 NEW: deploy the 4 edge functions + set their secrets

**What/Why:** The app's login check, account linking, bank-details writes and photo upload call Supabase Edge Functions. They live in this repo (`supabase/functions/`) but must be deployed to the **NEW** project. Secrets (service-role key, Cloudinary) are per-project and must be re-entered on NEW. The OLD project's functions are untouched.

**Steps (all targeting the 📗 NEW project):**

1. **Install the Supabase CLI:** Windows → `winget install supabase.cli` (or download `supabase.exe` from the GitHub releases page and add it to PATH). Verify: `supabase --version`.
2. **Log in:** `supabase login` (opens browser).
3. **Project setup in this repo:** the repo has `supabase/functions/` but no `config.toml`, so from the repo root run `supabase init` (creates only `config.toml`; it will not touch your functions), then:
   `supabase link --project-ref YOUR-NEW-PROJECT-REF` (the `yyy` part from Phase 0).
4. **Collect secrets:** the 3 Cloudinary values + service-role key.
   - Service-role key: NEW → Project Settings → API Keys → Legacy → `service_role`.
   - Cloudinary values: either from the **OLD** project's **Edge Functions → Secrets** page (viewing is read-only) or your Cloudinary dashboard (Settings → API keys). Save them into `MIGRATION-NOTES.txt`.
5. **Set secrets on NEW** (the CLI targets the linked project):
   ```powershell
   supabase secrets set SUPABASE_SERVICE_ROLE_KEY="paste-new-service-role-key" CLOUDINARY_CLOUD_NAME="your-cloud" CLOUDINARY_API_KEY="your-key" CLOUDINARY_API_SECRET="your-secret"
   ```
6. **Deploy each function** (from the repo root; `--no-verify-jwt` matches how they were built — they verify Firebase tokens themselves):
   ```powershell
   supabase functions deploy seller-bank --project-ref YOUR-NEW-REF --no-verify-jwt
   supabase functions deploy seller-link-account --project-ref YOUR-NEW-REF --no-verify-jwt
   supabase functions deploy seller-registration-status --project-ref YOUR-NEW-REF --no-verify-jwt
   supabase functions deploy product-image --project-ref YOUR-NEW-REF --no-verify-jwt
   ```
7. **Verify:** NEW Dashboard → **Edge Functions** → all 4 listed; **Secrets** page shows the 4 keys set.

**Success:** 4 functions visible on NEW, secrets present. **If deploy errors:** "Could not find a project" → re-run `supabase link`; "config.toml not found" → `supabase init` first; secrets rejected → check you didn't paste the *anon* key where the *service_role* key belongs.

---

## Phase 11 — Verification suite (the "is it really identical?" phase)

**Run each script twice — once on 📕 OLD (read only), once on 📗 NEW — and compare the saved outputs:**

| Script | Compares | Pass condition |
|---|---|---|
| `03_verify_row_counts_READ_ONLY.sql` | counts, distinct owners, min/max ids, money sums, content fingerprints | **Every number identical** (fingerprint caveat: if PG versions differ, numbers take precedence — see script header) |
| `04_verify_structure_READ_ONLY.sql` | columns/types/defaults, constraints, indexes | Line-by-line identical |
| `05_verify_rls_functions_triggers_READ_ONLY.sql` | RLS flags, policies, grants, triggers, function hashes, RPC privileges | Identical; RPC: service_role=true, anon=false |
| `06_verify_storage_READ_ONLY.sql` | bucket config, policies, **file counts** | `product-images` counts identical |

**Method that works for beginners:** run a script on OLD → *Download as CSV* → rename `03-OLD.csv`; same on NEW → `03-NEW.csv`; open both in Notepad/Excel side by side. Rows are sorted, so they line up.

**If ANY check fails — stop safely:**

1. **Do nothing to the old project.** It is still the untouched source of truth; you cannot lose it by stopping.
2. Identify the mismatch (which table/section).
3. Fix **only in the NEW project** (re-run Phase 5 for a whole table if needed — after dropping the partial objects **in NEW only**, or re-run the specific phase: functions → 6, sequences → 7, storage → 8/9).
4. Re-run the failed comparison. Only when **all four scripts pass** do you proceed.

**This guide does not consider the migration complete until all of Part 9's checks pass.**

---

## Phase 12 — 📗 NEW: behavioral smoke test (everything rolls back)

**Where:** NEW → SQL Editor → paste `seller-migration/07_smoke_test_new_project.sql` → Run.

**What it does:** inside `BEGIN … ROLLBACK` it acts like the app: `anon` reads the tables the app reads, inserts a test registration + wallet row (undone at the end), is *correctly denied* on `seller_bank_details` and `seller_lookup_rate_limits`, and `service_role` calls the RPC.

**Success:** every NOTICE line reads `PASS …`. Any `FAIL …` → fix per the message (usually grants/policies → re-run Phase 6 & the `05` comparison). Because of `ROLLBACK`, the test leaves zero rows behind — run it as often as you like.

---

## Phase 13 — External services review (view only + decisions)

| Service | Investigation | Action needed? |
|---|---|---|
| **Firebase Auth** | Independent of Supabase. Edge functions verify Firebase ID tokens using the hardcoded project `vpnexues-otp-and-img-s`. | **No change.** App + functions keep working after the switch. |
| **Cloudinary** | Stores the actual product images (folder `seller-products/...`). Account-level, not Supabase. | **No data move.** Verify its 3 secrets were set on NEW in Phase 10. |
| **Render Spring Boot backend** | Render Dashboard → your service → **Environment** tab: look for `SUPABASE_URL`, `SUPABASE_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `DATABASE_URL`, etc. | **Read-only check now.** If they point at the OLD project: the backend *keeps working* (OLD is untouched) — the app switch does not depend on it. Migrating the backend (its own tables + KYC bucket, visible in Phase 2 Section B's table list) is a **separate later project**. Only update Render env vars when you deliberately migrate it. |
| **KYC document files** | App path stores file *names* only (in `seller_verify_your_details` — already migrated). Render path stores *files* in a private bucket of OLD (visible in Phase 2 Section N / Phase 9 Step 1). | Decide: keep backend on OLD for now (default), or later copy that bucket with the same script (`-Bucket <name>`) when migrating the backend. |
| **Supabase CLI link state** | `supabase/.temp` in the repo references the OLD ref (local cache only). | Relinked to NEW in Phase 10. Harmless. |
| **Hardcoded old project ref in docs/tests** | `product-image/README.md`, `017_...sql` header comment, `test/product_image_url_test.dart` (a literal sample URL passed through a passthrough function). | Documentation/test samples only — **no runtime impact**. Optionally update later. |

---

## Phase 14 — Switch the Flutter Seller app to the NEW project

**Precondition:** Phases 11 + 12 fully green.

### 14.1 Back up the current configuration (rollback insurance)

Copy `assets/config/supabase.json` → `assets/config/supabase.json.pre-migration` (or just record its two values in `MIGRATION-NOTES.txt`). **This single file is your instant rollback switch.**

### 14.2 Get the NEW values

📗 NEW Dashboard → **Connect → Project URL** (`https://yyyy.supabase.co`) and **Project Settings → API Keys → Legacy → `anon public`**.

### 14.3 Edit the config

`assets/config/supabase.json` becomes:

```json
{
  "SUPABASE_URL": "https://YOUR-NEW-PROJECT.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR-NEW-ANON-KEY"
}
```

> ### ⚠️ Precedence warning (verified in `lib/data/api_config.dart`)
> The app uses `supabase.json` **whenever it contains non-empty values** — it **overrides** any `--dart-define SUPABASE_URL / SUPABASE_ANON_KEY` you pass! So:
> - Local dev: editing `supabase.json` is enough.
> - Release/CI builds that use `--dart-define`: you must update **those build arguments too**, *and* make sure `supabase.json` doesn't still hold old values (either update it everywhere it's bundled, or empty its two fields so the dart-defines win).
>
> **Never** put the service-role key in this file or anywhere in app code.

### 14.4 Rebuild and smoke-test the real app

```powershell
flutter run
```

Walk the critical paths and watch the console (`[supabase_product_api]`, `[edge_api]` logs):

1. **Sign up** (new phone) → check the row appeared: NEW SQL → `select * from public.seller_registrations order by created_at desc limit 5;`
2. **OTP login** → exercises `seller-link-account` on NEW.
3. **Save profile + location** → `seller_profiles` row updates on NEW.
4. **Add a product with a photo** → `product-image` function (Cloudinary) + `sellers_products` insert on NEW; image URL renders.
5. **Bank details save/read** → `seller-bank` function on NEW.
6. **Wallet** → `seller_transactions` selects on NEW.
7. **KYC step save** → `seller_verify_your_details` upsert on NEW.

**Success:** no `42501/permission denied`, no `PGRST204 missing table`, no "Supabase is not configured" — and rows appear in the NEW project as you use the app.

---

## Phase 15 — Post-switch: observation and old-project retirement

- **Data divergence begins now:** from the switch moment, every new write goes to NEW; OLD keeps everything that existed before, frozen (plus any writes made by services still pointed at it, e.g. Render — check in Phase 13).
- **Watch for 48–72 hours:** console errors, failed sign-ups, failed bank saves, image upload failures.
- **Never delete or "clean up" the OLD project.** Retirement rule: only after the app has run on NEW for a comfortable period **and** you have taken one final `pg_dump` of OLD to your own storage. Old Supabase free projects can be paused by the platform — that is not deletion, and data survives pause.
- Keep the NEW project's backups in mind too: from now on it is the production database.

---

# PART 5 — Verification reference (what each check proves)

| # | Check | Script / method | Proves | Failure action |
|---|---|---|---|---|
| 1 | Row counts per table | `03` OLD vs NEW | Not one record lost/added | Re-run Phase 5 for that table (NEW only) |
| 2 | Min/max ids + money sums | `03` | No rows skipped, values intact | Same as #1 |
| 3 | Content fingerprints (md5) | `03` (see version caveat) | No cell changed anywhere | Diff the table data (NEW only); OLD untouched |
| 4 | Columns: names/types/defaults/nulls | `04A` | Bytea columns, typo names, duplicates all preserved | Re-run Phase 5 (schema came from wrong place) |
| 5 | PK / UNIQUE / CHECK constraints | `04B` | Keys and rules identical | Re-run Phase 5 |
| 6 | Indexes | `04C` | Performance structures identical | Re-run Phase 5 |
| 7 | RLS enabled + policies | `05A/05B` | Security rules identical (incl. INSERT-only registration policy, zero-policy lockdown tables) | Re-run Phase 6 / restore policies from OLD output |
| 8 | Grants per role | `05C` | App (`anon`) can still do its operations | Re-run Phase 6 |
| 9 | Triggers | `05D` | `updated_at` auto-refresh works | Paste trigger+function from OLD inspection (NEW only) |
| 10 | Functions + RPC permissions | `05E/05F` | `seller_lookup_registered` exists, security-definer, service_role-only | Phase 6 again |
| 11 | Sequence values ≥ max(id) | `02` + `03` | Next inserts won't collide | Re-run `02` (NEW only) |
| 12 | Storage bucket config + policies | `06A/06D` | Public read/upload/delete rules match 024 | Re-run Phase 8 (NEW only) |
| 13 | Storage file count | `06B` | Every image copied | Re-run Phase 9 |
| 14 | Behavioral smoke test | `07` | The app's actual read/write patterns work under `anon`/`service_role` | Read the FAIL notice → corresponding phase |
| 15 | Live app walkthrough | Phase 14.4 | End-to-end reality | Roll back (Part 8), diagnose, redo the failed phase |

---

# PART 6 — Rollback guide

**Nothing in this migration can damage the OLD project** — every OLD-side operation was `SELECT`/read-only. Rollback is therefore only about pointing the *app* back.

### If the new project misbehaves after switching:

1. **Switch the app back (minutes):** restore `assets/config/supabase.json.pre-migration` (or paste the OLD URL + anon key from `MIGRATION-NOTES.txt`), or revert your `--dart-define` values → `flutter run`. The app is immediately back on the OLD project, whose data was never touched.
2. **Do NOT delete the NEW project.** It holds any *new* records created during testing (new sign-ups, new products, profile edits).
3. **Preserve new-side data before any long rollback:** from your PC:
   ```powershell
   pg_dump "PASTE-NEW-SESSION-POOLER-URI" --no-owner -t public.sellers_products -t public.seller_profiles -t public.seller_registrations -t public.seller_verify_your_details -t public.seller_bank_details -t public.seller_transactions -t public.seller_lookup_rate_limits -f new_project_data_after_test.sql
   ```
   Keep this file. When you re-migrate later, its data can be merged deliberately (or simply re-point the app at NEW again after fixing the issue — the data is still there).
4. **If you changed Render environment variables:** revert them in Render's Environment tab (that's outside Supabase; old values were never overwritten by us — note them before changing anything).
5. **Re-switching later:** fix the problem on NEW (only ever NEW), re-run the failed verification (Part 5), then repeat Phase 14.

### What rollback can never require:

- Any write, drop, restore or config change in the OLD project. If anyone suggests one, stop — that violates this plan's core rule.

---

# PART 7 — Script & file index

| File | Target project | Contains writes? | Used in |
|---|---|---|---|
| `seller-migration/00_inspect_old_project_READ_ONLY.sql` | 📕 OLD | **No (SELECT only)** | Phase 2 |
| `seller-migration/01_precheck_new_project.sql` | 📗 NEW | No (SELECT only) | Phases 3, 5 |
| `seller-migration/02_fix_sequences.sql` | 📗 NEW | Yes (sequence values + NOTIFY) | Phase 7 |
| `seller-migration/03_verify_row_counts_READ_ONLY.sql` | 📕 OLD + 📗 NEW | **No (SELECT only)** | Phase 11 |
| `seller-migration/04_verify_structure_READ_ONLY.sql` | 📕 OLD + 📗 NEW | **No (SELECT only)** | Phase 11 |
| `seller-migration/05_verify_rls_functions_triggers_READ_ONLY.sql` | 📕 OLD + 📗 NEW | **No (SELECT only)** | Phases 6, 11 |
| `seller-migration/06_verify_storage_READ_ONLY.sql` | 📕 OLD + 📗 NEW | **No (SELECT only)** | Phases 8, 9, 11 |
| `seller-migration/07_smoke_test_new_project.sql` | 📗 NEW | Yes, but **fully rolled back** | Phase 12 |
| `seller-migration/copy_product_images.ps1` | 📕 reads → 📗 writes | Old: no / New: yes | Phase 9 |
| `seller-backend/db/024_product_images_storage.sql` (existing repo file) | 📗 NEW | Yes (NEW only) | Phase 8 |
| Phase 4/5/11 commands | 📕 read / 📗 write | as labeled | Phases 4, 5, 15 |

---

# PART 8 — Final checklist (follow top to bottom)

**Preparation**
- [ ] Read Part 1 glossary; understand the 📕 OLD READ ONLY / 📗 NEW DESTINATION rule
- [ ] Phase 0: recorded all 6 credential values for both projects (incl. NEW service_role key — kept secret)
- [ ] Phase 1: `pg_dump --version` and `psql --version` work
- [ ] Created `MIGRATION-NOTES.txt` and working folder `C:\seller-migration-work`

**Investigation**
- [ ] Phase 2: ran `00` on OLD section by section; `OLD-INSPECTION.txt` saved (sections A–O)
- [ ] Phase 2 Section E: FK decision made (none / include referenced table / remove that FK line)
- [ ] Phase 2 Section J: all function definitions pasted into notes
- [ ] Phase 2 Section M: OLD extension list noted; missing ones enabled in NEW if needed
- [ ] Phase 3: ran `01` on NEW — Section B all `false`

**Migration writes (NEW only)**
- [ ] Phase 4: dump file created from OLD; 7 `CREATE TABLE`s; `REFERENCES` all resolvable
- [ ] Phase 5: `psql` restore completed with **no ERROR**; `COPY` counts match OLD
- [ ] Phase 6: all functions + RPC permissions applied on NEW; `05E` hashes match
- [ ] Phase 7: ran `02` — every sequence ≥ max(id) (incl. big `seller_bank_details_id_seq`)
- [ ] Phase 8: `product-images` bucket + 3 policies created (`06A`/`06D` pass on NEW)
- [ ] Phase 9: files copied (test with `-Limit 3` first if using the script); `06B` counts identical
- [ ] Phase 10: 4 edge functions deployed on NEW; 4 secrets set on NEW; OLD functions untouched

**Verification (no phase is "done" until it passes)**
- [ ] `03` row counts OLD = NEW (all 7 tables)
- [ ] `04` structure OLD = NEW (columns/constraints/indexes)
- [ ] `05` RLS/grants/triggers/functions OLD = NEW; RPC service_role=true, anon=false
- [ ] `06` storage config + file counts OLD = NEW
- [ ] `07` smoke test: every NOTICE is PASS
- [ ] Phase 13: Firebase (no change confirmed), Cloudinary secrets confirmed, Render env inspected & noted, KYC bucket decision recorded

**Switch & watch**
- [ ] Phase 14.1: `supabase.json` backed up
- [ ] Phase 14.3: NEW URL + anon key written (remember: json overrides dart-define!)
- [ ] Phase 14.4: all 7 app flows pass; rows land in NEW
- [ ] Phase 15: 48–72h observation window with no errors; OLD project untouched & retained

**Definition of DONE:** every box above checked **and** all four verification scripts pass on both projects. Until then, the migration is *not* complete — and the app stays on the OLD project (or rolls back per Part 6).

---

# Appendix A — Required database objects (checklist)

**Tables (7):** `sellers_products` · `seller_profiles` · `seller_registrations` · `seller_verify_your_details` · `seller_bank_details` · `seller_transactions` · `seller_lookup_rate_limits`

**Table details:**

| Table | Key columns (from code/repo SQL; full list = Phase 2 output) | Notes |
|---|---|---|
| `sellers_products` | `id`, `user_id`(text), `product_name`, `category`, `price`, `quantity`, `unit`(added by 024), `product_descrption`*, `product_avaliblit`*, `product_img_1..5`(**bytea in OLD**), `buyer_pickup_enabled`, `delivery_enabled` | *typos are real column names |
| `seller_profiles` | `user_id`(uuid PK), `firebase_uid`, `display_name`, `phone_number`, `location`, `business_address`, `business_name`, `seller_type`, `latitude`, `longitude`, `active_bank_account_id`, `avatar_url`, `fcm_token`, `verified`, `created_at`, `updated_at` (+ any duplicate-looking legacy columns — see Phase 2 C) | 3-way legacy keying (`user_id` / `firebase_uid` / `phone_number`) |
| `seller_registrations` | `id`(uuid PK), `name`, `phone_e164`(UNIQUE), `status`, `firebase_uid`, `phone_verified`, `created_at`, `updated_at` | anon may INSERT only (`anon_can_register`), never SELECT |
| `seller_verify_your_details` | `user_id`(key), `aadhaar_card`, `pan_card`, `business_registration`, `aadhaar_file_name`, `pan_file_name`, `business_file_name`, `kyc_status`, `updated_at` | UPSERT on `user_id`; file *names* only, no files |
| `seller_bank_details` | `id`(bigint, legacy ms-timestamp ids), `user_id`, `account_houlder_name`*, `bank_name`, `account_number`, `IFSC_code` | *typo is real; anon fully locked out (022); service-role via `seller-bank` only |
| `seller_transactions` | `id`(bigserial PK), `user_id`, `type`, `amount`, `title`, `order_id`, `created_at` | CHECKs: type in credit/withdrawal, amount>0 |
| `seller_lookup_rate_limits` | `key`(PK), `window_start`, `count` | RLS on, **zero** policies (service-role only) |

**Sequences:** `seller_transactions_id_seq` · `seller_bank_details_id_seq` (critical — ms-timestamp range) · `sellers_products_id_seq` (if serial) · any others found in Phase 2 K — all re-pointed by `02_fix_sequences.sql`.

**Functions / RPC:** `seller_lookup_registered(p_phone text)` (SECURITY DEFINER; EXECUTE revoked from public/anon, granted to service_role) · `set_updated_at()` · `update_updated_at_column()` · *(any others listed in Phase 2 Section J)*.

**Triggers:** `seller_registrations_touch_updated_at` → `set_updated_at()` · `seller_profiles_touch_updated_at` → `set_updated_at()` · *(orders' trigger only if orders migrated)*.

**Constraints:** PKs per table · `seller_registrations_phone_e164_key` UNIQUE · `seller_transactions` CHECKs · any CHECK/FK found in Phase 2 Sections E/F (unknown until inspected — *never assumed*).

**Indexes:** `seller_transactions_user_created_idx` · `seller_registrations_phone_e164_key` · `seller_registrations_firebase_uid_idx` (partial) · `seller_profiles` phone/fcuid indexes if present · anything else from Phase 2 G.

**RLS:** enabled on all 7; policies: allow-all ×4 on `seller_transactions`; `anon_can_register` (INSERT, TO anon, with check) on registrations; zero policies on `seller_lookup_rate_limits` **and** on `seller_bank_details` (post-022); anon select/write/update on `seller_profiles` & `seller_verify_your_details`; sellers_products policies as captured in Phase 2 H.

**Grants:** `anon`/`authenticated`/`service_role` privileges per Phase 2 L (pg_dump restores them).

**Extensions:** whatever Phase 2 M shows (commonly `pgcrypto`) — must be available in NEW.

**Storage:** bucket `product-images` (public, 10 MB, jpeg/png/webp/gif) · 3 policies on `storage.objects` · all existing files.

**Edge functions (4):** `seller-bank`, `seller-link-account`, `seller-registration-status`, `product-image` — deployed to NEW with secrets `SUPABASE_SERVICE_ROLE_KEY`, `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`.

**PostgREST:** final `notify pgrst, 'reload schema';` (step 4 of `02_fix_sequences.sql`).

---

# Appendix B — External dependencies

| Dependency | Role | Migration impact |
|---|---|---|
| **Firebase Phone Auth** (project `vpnexues-otp-and-img-s`) | Identity for app + edge-function token checks | None — unchanged |
| **Cloudinary** (folder `seller-products/…`) | Stores product images | No data move; 3 secrets must exist on NEW (Phase 10) |
| **Render Spring Boot backend** (`vpnexues-seller-backend.onrender.com`) | Secondary onboarding/KYC API with its own Supabase credentials + private KYC bucket | Investigated Phase 13; stays on OLD until separately migrated; does not block app switch |
| **Supabase Edge Functions runtime** | Runs the 4 seller functions | Redeployed to NEW (Phase 10) |
| **PostgREST / Storage / Auth APIs** | REST layer behind the app | `NOTIFY pgrst` after restore; Auth unused (Firebase instead) |
| **Your Windows PC** | Runs pg_dump/psql/PowerShell/CLI | Tools Phase 1; keys only in env vars — never committed |
| **Supabase CLI** | Deploys functions, sets secrets | Linked to NEW in Phase 10 |
| **Service-role key** | Secret for edge functions + copy script | NEW project's key only; **never in app code** |
| **Anon key + Project URL** | Public app configuration | Swapped in Phase 14 (`supabase.json` / dart-defines) |

---

# Appendix C — Troubleshooting common errors

| Error | Meaning | Fix (always NEW-side unless noted) |
|---|---|---|
| `pg_dump: error: connection ... failed` / timeout | Wrong URI, password, or IPv6 blocked | Use the **Session pooler (5432)** URI from Connect → Database; verify password (Phase 0); try the IPv4 option on the Connect page |
| `password authentication failed` | Wrong/old DB password | Project Settings → Database → reset password (per project), update URI |
| `pg_dump: server version: 15.x; pg_dump version: 14.x` | Client older than server | Install a newer pg_dump (Phase 1) — newer client than server is always OK |
| `relation "public.xxx" does not exist` during restore | A referenced table/extension is missing | Check dump's `REFERENCES` (Phase 4) and OLD extensions (Phase 2 M); add the table to the dump or `create extension if not exists ...` on NEW; re-run Phase 5 |
| `duplicate key value violates unique constraint` during restore | Tables already had rows | Phase 3 Section B should have caught this — confirm you're on NEW; drop the partial objects **in NEW only**, re-run |
| `permission denied for schema storage` in Phase 8 | Bucket creation via SQL blocked | Use the manual dashboard path in Phase 8 instead |
| `42501 / row-level security` **after migration** | A policy didn't make it | Compare `05B` OLD vs NEW; re-create missing policy from OLD's output (NEW only) |
| `PGRST204 / could not find the ...` from the app | PostgREST schema cache stale or table missing | Run step 4 of `02` (`notify pgrst, 'reload schema'`) on NEW; confirm table exists |
| `Supabase is not configured` in app | Config file not loaded / empty | Check `assets/config/supabase.json` contents & that it's bundled |
| App still hits OLD after editing dart-defines | **`supabase.json` overrides dart-defines** | Update/empty the json file (Phase 14 warning box) |
| Bank save returns 401/403 after switch | Edge function missing/secret wrong on NEW | Phase 10: redeploy `seller-bank`, re-set `SUPABASE_SERVICE_ROLE_KEY` |
| Image upload fails after switch | Cloudinary secrets missing on NEW | Phase 10 `secrets set` with the 3 Cloudinary values |
| PowerShell blocks `copy_product_images.ps1` | Execution policy | `powershell -ExecutionPolicy Bypass -File .\copy_product_images.ps1 -ListOnly` |
| Verification counts differ on `seller_lookup_rate_limits` | Live logins during migration | Expected for this disposable table (see `03` note) — migrate during an app-quiet window for exact equality |

---

*This document is a plan only. Nothing in it has been executed; no database, setting, key, or existing file was modified in producing it. Companion deliverables: `SELLER_SUPABASE_TABLE_AUDIT.md` (object audit) and the `seller-migration/` scripts (indexed in Part 7).*
