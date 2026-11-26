# 🟢 THE SIMPLE GUIDE — Move your Seller database to the new Supabase account

> **Who this is for:** someone who has never migrated a database before.
> **Goal:** copy the Seller tables + data to your NEW Supabase project, then point your app at it — so everything works exactly like today.
> **Time:** about 1–2 hours, plus a little waiting.
> **Note:** a more detailed version exists in `SELLER_SUPABASE_MIGRATION_GUIDE.md`. This file is the easy version.

---

## 📖 The story (60 seconds)

Imagine your database is a **big workbook** stored in a cloud locker (your OLD Supabase project).

We are going to:

1. **Photograph** the workbook (a file copy — nothing is changed).
2. **Paste** the photograph into a brand-new locker (your NEW Supabase project).
3. **Count the pages** in both workbooks to prove nothing is missing.
4. **Tell your app** the new locker address.

The original workbook stays in the old locker forever. We only ever **look** at it.

---

## 🛑 The only 3 rules

1. **OLD project = eyes only.** We only look. We never delete, edit, or "clean up" anything there.
2. **NEW project = the workshop.** All pasting, fixing, and creating happens here.
3. **Don't change the app** until the counting game (Mission 11) says every number matches.

---

## 📝 Words you'll see (only 10!)

| Word | Meaning |
|---|---|
| **Table** | One sheet of data (like `seller_profiles`). Your app uses 7 of them. |
| **Row** | One line in a sheet (one seller, one product). |
| **SQL Editor** | A page in the Supabase website where you paste code and press Run. |
| **Dump file** | The "photograph" file we create (a big text file). |
| **Sequence** | A ticket-number machine that gives each new row its `id` (1, 2, 3…). |
| **Bucket** | A photo album in Supabase Storage. Yours is called `product-images`. |
| **Edge Function** | A tiny program that runs on Supabase's servers. Your app has 4 of them. |
| **Anon key** | A public password your app is allowed to carry. Safe to put in the app. |
| **Service key** | A powerful secret password. **Never** put it in the app. Only for our scripts. |
| **Connection string** | One long line that means "my database address + password". |

---

## ✅ What you need before starting

- [ ] Login access to **both** Supabase projects (OLD and NEW)
- [ ] This app project folder on your computer (you have it — that's where this file is)
- [ ] 1 quiet hour — **ask people to stop using the seller app** during the copy (so numbers don't change while we compare)
- [ ] A notepad file ready: create `MIGRATION-NOTES.txt` and keep it open

---

# MISSION 1 — Install 2 free tools on your computer

**Why:** we need two tiny programs from the PostgreSQL company: `pg_dump` (makes the photo) and `psql` (pastes the photo). They are the safest tools for this job.

**Steps:**

1. Open this website: **https://www.postgresql.org/download/windows/**
2. Download the **"Binaries" ZIP** file (no installer needed).
3. Unzip it so you get a folder like `C:\pgsql` where `C:\pgsql\bin\pg_dump.exe` exists.
4. Add that `bin` folder to your PATH:
   - Press the **Windows key**, type `environment`, click **"Edit environment variables for your account"**
   - In the window that opens, click **Path** → **Edit** → **New**
   - Type `C:\pgsql\bin` (or wherever your `bin` folder is) → press **Enter**
   - Click **OK** on all windows
5. **Close PowerShell completely, then open a brand-new one** (Press `Win+X` → *Windows PowerShell* or *Terminal*).
6. Type these one at a time and press Enter:

```powershell
pg_dump --version
psql --version
```

**✅ You succeed when:** both lines show something like `pg_dump (PostgreSQL) 16.2`.

**❌ If it says "not recognized":** the PATH step didn't save, or you didn't open a *new* window. Do PATH again, close the window, open a new one.

---

# MISSION 2 — Write down 6 values (like collecting keys before a trip)

You need 3 keys from the **OLD** project and 3 from the **NEW** project. Put them all in `MIGRATION-NOTES.txt`.

### For EACH project (do OLD first, then NEW):

**A) Project URL + anon key**

1. Open the Supabase website → click your project.
2. Click **Connect** (top of the page) → copy the **Project URL** (looks like `https://abc123.supabase.co`).
3. Click the **gear icon (Project Settings)** at the bottom-left → **API Keys** → if you see a tab called **"Legacy API keys"**, click it → copy the key labelled **`anon` `public`**.

**B) Connection string (the long database address)**

1. Click **Connect** → **Database** tab.
2. Choose **Session pooler** (port `5432`).
3. Copy the **URI** (starts with `postgresql://postgres....`).
4. It has `YOUR-PASSWORD` written in it — replace that part with your real database password. (Forgot it? → **Project Settings → Database → Reset database password** — resetting a password does NOT delete any data.)

**C) NEW project only — the secret service key**

1. **Project Settings → API Keys → Legacy API keys**
2. Reveal and copy the key labelled **`service_role`**.
3. ⚠️ Keep it secret. Never paste it into the app.

### Your notes file should now look like:

```
OLD:  url = https://xxxx.supabase.co
      anon key = ...
      connection string = postgresql://postgres.xxx:PASSWORD@aws-0-....pooler.supabase.com:5432/postgres

NEW:  url = https://yyyy.supabase.co
      anon key = ...
      service key = ...        <- secret!
      connection string = postgresql://postgres.yyy:PASSWORD@aws-0-....pooler.supabase.com:5432/postgres
      project ref = yyy        <- the short name between "postgres." and ":"
```

**✅ You succeed when:** all boxes are filled in.

---

# MISSION 3 — Look at the OLD database and save what it contains (READ-ONLY)

**Why:** your code folder is missing the original "create table" instructions for 4 of the 7 tables. The old database is the boss that knows the real answers. This step only **reads**.

**Steps:**

1. Open the Supabase website → choose the **OLD** project.
2. Left menu → **SQL Editor** → **New query**.
3. Open the file `seller-migration/00_inspect_old_project_READ_ONLY.sql` from this project folder, copy **all** of its text, paste it into the SQL Editor.
4. Press **Run** (or Ctrl+Enter).
5. You'll see results appear. **Copy each result** into a Notepad file called `OLD-INSPECTION.txt`.
   - Tip: run it in small pieces if the screen is crowded — copy from `-- SECTION A` down to just before `-- SECTION B`, press Run, copy that result, then do the next section, and so on.

**✅ You succeed when:** `OLD-INSPECTION.txt` has all the sections, including:
- a list of **all tables** with how many rows each has
- the **columns** of your 7 Seller tables (the missing answers!)
- a section showing **row counts of the 7 tables** (write these 7 numbers in `MIGRATION-NOTES.txt` — you'll compare them later)

**❌ If an error appears:** check you selected the **OLD** project (top-left of the website says its name). This script cannot change anything — it's just looking.

---

# MISSION 4 — Make sure the NEW database is empty

**Why:** we never paste on top of existing tables. This check prevents a big mess.

**Steps:**

1. Supabase website → choose the **NEW Seller** project.
2. **SQL Editor → New query** → paste everything from `seller-migration/01_precheck_new_project.sql` → **Run**.

**✅ You succeed when:** the section with 7 rows shows **`already_exists = false`** for all 7 tables.

**❌ If any says `true`:** STOP. You're either on the wrong project, or a previous attempt started. Don't run anything else — come back and ask me which table shows `true`.

---

# MISSION 5 — Take the photograph of the OLD database

**Why:** this single command copies the *structure AND every row* of your 7 tables into one file. It only reads from OLD.

**Steps:**

1. Create a working folder and open PowerShell inside it:

```powershell
mkdir C:\seller-work
cd C:\seller-work
```

2. Copy this **whole line**, but first replace `PASTE-OLD-CONNECTION-STRING` with the OLD connection string from `MIGRATION-NOTES.txt` (keep it inside the `"quotes"`):

```powershell
pg_dump "PASTE-OLD-CONNECTION-STRING" --no-owner -t public.sellers_products -t public.seller_profiles -t public.seller_registrations -t public.seller_verify_your_details -t public.seller_bank_details -t public.seller_transactions -t public.seller_lookup_rate_limits -f seller_photo.sql
```

**What this line means, piece by piece:**

| Piece | Meaning |
|---|---|
| `pg_dump "..."` | "Take a photo of **this** database" (the OLD one — it only reads) |
| `--no-owner` | Skip boring ownership settings (avoids harmless errors) |
| `-t public.sellers_products` | "Include this table" — repeated 7 times, once per table |
| `-f seller_photo.sql` | "Save the photo into this file" |

**✅ You succeed when:** the screen shows progress lines like `Dumping the contents of table seller_profiles...`, no error messages, and a new file `seller_photo.sql` appears in the folder (it can be large — that's normal).

**❌ If it fails:** usually the connection string or password is wrong. Re-copy it from the Supabase **Connect → Database → Session pooler** page. Make sure you used the **OLD** project's string.

---

# MISSION 6 — Paste the photograph into the NEW database

**Why:** this puts everything into your new project. The safety switches mean: **if anything goes wrong, everything automatically rolls back** — the new database stays clean, nothing half-done.

**Steps:**

1. In the same PowerShell window, copy this line, but replace `PASTE-NEW-CONNECTION-STRING` with the **NEW** project's connection string:

```powershell
psql "PASTE-NEW-CONNECTION-STRING" --single-transaction -v ON_ERROR_STOP=1 -f seller_photo.sql
```

**What it means:** "Run this photo file against the NEW database, all as one package, and stop instantly if any line fails."

**✅ You succeed when:** you see a wall of lines like `CREATE TABLE`, `ALTER TABLE`, and — very important — **`COPY 123`** lines (the 123 is how many rows went in). The last line must **not** say `ERROR`.

**Check it worked:** run Mission 4's script again — now all 7 tables should say **`already_exists = true`**.

**❌ If you see an ERROR:** read the error line — the good news is the whole thing rolled back, so the NEW database is still clean. Tell me the exact error text and I'll tell you the fix. (Most common: a missing extension — one small `create extension` command fixes it, run in the NEW project.)

---

# MISSION 7 — Fix the ticket-number machines (sequences)

**Why:** rows were copied with their old ids (for example id #5000). The number machine might still think the next number is #1 — which would cause "duplicate key" errors later. This script tells each machine: "start after the biggest number you can see."

**Steps:**

1. NEW project → **SQL Editor → New query**
2. Paste `seller-migration/02_fix_sequences.sql` → **Run**

**✅ You succeed when:** you see `NOTICE` lines like `SEQUENCE seller_bank_details_id_seq: ... (FIXED)` or `already correct`, and the final table shows numbers. For `seller_bank_details` the number will be **huge** (like `1730000000000`) — that's normal, those ids are timestamps.

**This script also ends with a `NOTIFY` line** — that's it telling the API layer "refresh your table list", which is good.

---

# MISSION 8 — Build the photo album (the `product-images` bucket)

**Why:** the bucket (where product photos live) is not part of the table photo — it must be created separately in the NEW project. Your own code folder already contains the verified script for this.

**Steps:**

1. NEW project → **SQL Editor → New query**
2. Open the file **`seller-backend/db/024_product_images_storage.sql`** (it's in this project folder), copy **all** of it, paste, **Run**

**✅ You succeed when:** you see `INSERT` (the bucket was made) and `CREATE POLICY` lines. It's safe to run twice.

---

# MISSION 9 — Copy the photos into the new album

**Good news first:** your product photos will **keep working even if you skip this step**, because the database stores full web addresses that point at the OLD project's photo album, and the old project stays alive. This step is only about being 100% independent from the old account. New photos you add after the switch go to Cloudinary anyway (that's the app's main photo service — nothing to do there).

**If you want to do it (recommended):**

**Step A — count the files first.** Run `seller-migration/06_verify_storage_READ_ONLY.sql` on the **OLD** project and find `file_count` for `product-images`.

**Fewer than ~30 files → do it by hand:**

1. OLD project → left menu **Storage** → `product-images` → you see folders like `firebaseUid123/`
2. Open a file (its address is `https://OLD.supabase.co/storage/v1/object/public/product-images/...`) → download/save it
3. NEW project → **Storage** → `product-images` → **Upload files** → put each file back in the **same folder path**

**Many files → use the helper script** (opens in PowerShell, in the `seller-migration` folder):

```powershell
cd C:\Users\ANJITH\StudioProjects\vpnexuespvtsellerphase\seller-migration

$env:SUPABASE_OLD_URL         = "https://OLD-url-here.supabase.co"
$env:SUPABASE_OLD_SERVICE_KEY = "paste OLD service key"
$env:SUPABASE_NEW_URL         = "https://NEW-url-here.supabase.co"
$env:SUPABASE_NEW_SERVICE_KEY = "paste NEW service key"

.\copy_product_images.ps1 -ListOnly     # 1st: just LOOK at the list (changes nothing)
.\copy_product_images.ps1 -Limit 3      # 2nd: copy only 3 test files, then check they appear in NEW Storage
.\copy_product_images.ps1               # 3rd: copy everything
```

(If Windows blocks it: `powershell -ExecutionPolicy Bypass -File .\copy_product_images.ps1 -ListOnly`)

**✅ You succeed when:** run `06_verify_storage_READ_ONLY.sql` on **both** projects — the `file_count` numbers for `product-images` are **the same**.

---

# MISSION 10 — Install the 4 robots (edge functions) into the NEW project

**Why:** your app calls 4 small programs (`seller-bank`, `seller-link-account`, `seller-registration-status`, `product-image`) at whatever address is in its config. After we switch the address, they must exist in the NEW project — otherwise logging in and saving bank details would break.

**Steps (all in PowerShell, from your project folder):**

1. **Install the Supabase tool (once):**
```powershell
winget install supabase.cli
```
Close and reopen PowerShell, then check: `supabase --version`

2. **Log in (opens a browser):**
```powershell
supabase login
```

3. **Connect this folder to your NEW project** (replace `NEWREF` with your NEW project ref from `MIGRATION-NOTES.txt`):
```powershell
supabase init
supabase link --project-ref NEWREF
```
(`supabase init` only creates a missing settings file — it will not touch your functions.)

4. **Give the robots their keys** (service key from Mission 2C + the 3 Cloudinary values — get them from the OLD project's **Edge Functions → Secrets** page, just *looking* is fine, or from your Cloudinary account):
```powershell
supabase secrets set SUPABASE_SERVICE_ROLE_KEY="new-service-key" CLOUDINARY_CLOUD_NAME="your-cloud" CLOUDINARY_API_KEY="your-key" CLOUDINARY_API_SECRET="your-secret"
```

5. **Deploy the 4 robots** (one line each):
```powershell
supabase functions deploy seller-bank --project-ref NEWREF --no-verify-jwt
supabase functions deploy seller-link-account --project-ref NEWREF --no-verify-jwt
supabase functions deploy seller-registration-status --project-ref NEWREF --no-verify-jwt
supabase functions deploy product-image --project-ref NEWREF --no-verify-jwt
```

**✅ You succeed when:** in the NEW Supabase website → **Edge Functions** → all 4 are listed, and the Secrets page shows 4 keys. The OLD project's functions were not touched.

---

# MISSION 11 — The counting game (prove nothing is missing)

This is the most important mission. **Don't skip it.**

### Game 1 — row counts

1. Run `seller-migration/03_verify_row_counts_READ_ONLY.sql` on the **OLD** project → save as `counts-old.txt`
2. Run the same file on the **NEW** project → save as `counts-new.txt`
3. Open both files side by side (Notepad is fine) and fill this table:

| Table | OLD count | NEW count | Match? |
|---|---|---|---|
| sellers_products | | | ⬜ |
| seller_profiles | | | ⬜ |
| seller_registrations | | | ⬜ |
| seller_verify_your_details | | | ⬜ |
| seller_bank_details | | | ⬜ |
| seller_transactions | | | ⬜ |
| seller_lookup_rate_limits | | | ⬜ |

**✅ Every row must match.** (The very last table holds tiny login counters — if only that one differs by a few, it's harmless; just avoid using the app while migrating.)

### Game 2 — structure, rules and functions

Do the same "run on OLD, run on NEW, compare" with these three files:

- `04_verify_structure_READ_ONLY.sql` → columns/types/indexes must look **identical**
- `05_verify_rls_functions_triggers_READ_ONLY.sql` → security rules + functions identical; for `seller_lookup_registered`, both projects must show `has_service_role = true` and `has_anon = false`
- `06_verify_storage_READ_ONLY.sql` → bucket settings identical + file counts identical

### Game 3 — pretend to be the app (NEW project only)

Run `seller-migration/07_smoke_test_new_project.sql` on the **NEW** project.

**✅ You succeed when:** every message starts with **`PASS`**. The test creates 2 dummy rows and deletes them again automatically (it rolls back), so it leaves nothing behind. Any `FAIL` message tells you which mission to redo.

### 🚦 The rule

> **If any number or line does not match: STOP. Do not switch the app.** The old database is perfectly safe and untouched — you can't lose anything by stopping. Tell me which line mismatched and we fix it **in the NEW project only**.

---

# MISSION 12 — Point the app at the new account

**Only after Mission 11 is all green.**

### Step 1 — save a backup of your current setting (this is your undo button)

Copy the file `assets/config/supabase.json` and paste it as `assets/config/supabase.json.pre-migration` (or just copy its 2 values into `MIGRATION-NOTES.txt`).

### Step 2 — get the NEW project's 2 values

- **URL:** NEW project → **Connect** → Project URL
- **Anon key:** **Project Settings → API Keys → Legacy API keys → `anon public`**

### Step 3 — edit `assets/config/supabase.json` so it looks like this:

```json
{
  "SUPABASE_URL": "https://YOUR-NEW-PROJECT.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR-NEW-ANON-KEY"
}
```

### ⚠️ The one trap to remember

Your app **reads this file first**. If this file has old values, it **ignores** any `--dart-define SUPABASE_URL=...` you pass. So:

- Running locally? Editing this file is enough.
- Building a release with `--dart-define`? Update those too — **and** make sure this file doesn't still hold old values (update it everywhere, or empty its two values so the dart-defines win).

**Never** put the *service* key in this file — only the anon key.

### Step 4 — run the app and walk through it

```powershell
flutter run
```

Test these 7 things and watch the console for red errors:

1. **Sign up** with a new phone number → then check it landed: NEW project → SQL Editor → `select * from public.seller_registrations order by created_at desc limit 5;`
2. **Log in with OTP** (tests robot #2)
3. **Save your profile + location**
4. **Add a product with a photo** (tests robot #4 + Cloudinary)
5. **Save bank details** (tests robot #1)
6. **Open the Wallet** (tests transactions)
7. **Save the KYC step**

**✅ You succeed when:** all 7 work, no red errors like `permission denied`, `PGRST204`, or `Supabase is not configured` — and you can see your activity appearing in the NEW project.

---

# MISSION 13 — If something goes wrong afterwards (how to go back)

Going back is easy and **cannot hurt the old database** (we never wrote to it):

1. Put the backup values back into `assets/config/supabase.json` (from Step 1 above).
2. Run `flutter run`. The app is instantly back on the OLD database, working exactly as before.
3. **Don't delete the NEW project** — it holds any new records made during testing.
4. Optional: save a photo of the NEW database's data for later (run this in PowerShell):
```powershell
pg_dump "PASTE-NEW-CONNECTION-STRING" --no-owner -t public.sellers_products -t public.seller_profiles -t public.seller_registrations -t public.seller_verify_your_details -t public.seller_bank_details -t public.seller_transactions -t public.seller_lookup_rate_limits -f new_project_backup.sql
```
5. Later, fix whatever went wrong (always in the NEW project), redo Mission 11, then repeat Mission 12.

---

# 📋 FINAL CHECKLIST (print this)

**Prepare**
- [ ] Mission 1: `pg_dump --version` and `psql --version` both work
- [ ] Mission 2: 6 values written in `MIGRATION-NOTES.txt`

**Copy**
- [ ] Mission 3: `OLD-INSPECTION.txt` saved + the 7 row counts written down
- [ ] Mission 4: all 7 tables say `already_exists = false`
- [ ] Mission 5: `seller_photo.sql` created from OLD (no errors)
- [ ] Mission 6: paste into NEW finished with **no ERROR** and `COPY` lines visible
- [ ] Mission 7: sequences fixed (big number for `seller_bank_details_id_seq`)
- [ ] Mission 8: `product-images` bucket created
- [ ] Mission 9: photos copied (or consciously skipped — old photos still work)
- [ ] Mission 10: 4 edge functions live in NEW, 4 secrets set

**Prove it**
- [ ] Mission 11 Game 1: all 7 counts match (table above filled)
- [ ] Mission 11 Game 2: structure/rules/functions match on both projects
- [ ] Mission 11 Game 3: smoke test shows all `PASS`

**Switch**
- [ ] Mission 12 Step 1: `supabase.json` backed up
- [ ] Mission 12 Step 3: NEW url + anon key saved in `supabase.json` (remember the trap!)
- [ ] Mission 12 Step 4: all 7 app flows work, rows appear in NEW

**Afterwards**
- [ ] Old project left alone and retained (never deleted)
- [ ] A day or two of normal use with no errors

> **DONE means:** every box checked. Until then, the app stays where it is (or rolls back per Mission 13).

---

## 🆘 Quick help — the 5 problems you're most likely to hit

| Problem | What it means | What to do |
|---|---|---|
| `pg_dump: connection failed` / timeout | Wrong address, wrong password, or internet blocking port | Re-copy the **Session pooler** URI from **Connect → Database**; check password (Project Settings → Database) |
| `password authentication failed` | Password typed wrong in the URI | Reset the database password (that never deletes data), update your notes, try again |
| `relation "public.xxx" does not exist` (during Mission 6) | Something referenced is missing | Copy me the exact error line — usually one `create extension if not exists "pgcrypto";` (run in NEW) or adding one more `-t` table to Mission 5 fixes it |
| App still shows OLD data after editing dart-defines | The `supabase.json` file is overriding them (the trap in Mission 12) | Edit `supabase.json` itself |
| Bank save / login check fails after switch | An edge function or its secret is missing in NEW | Redo Mission 10 (deploy + secrets set) |

---

*This is a plan and set of scripts for YOU to run — nothing has been executed, and no existing file, database, key, or setting was changed in creating it. When in doubt, stop and ask — the old database will always be there, untouched.*
