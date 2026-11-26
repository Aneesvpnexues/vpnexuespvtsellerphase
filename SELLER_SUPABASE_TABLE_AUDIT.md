# Seller App — Supabase Table & Dependency Audit

**Purpose:** Identify every Supabase object (tables, RPCs, storage buckets, edge functions) the Seller application depends on, so only the Seller's required schema and data can be migrated from the old Supabase project to the new Seller Supabase project.

**Scope of investigation:** entire repo — `lib/` (all screens, widgets, services, data layer), `supabase/functions/` (edge functions), `seller-backend/db/` (SQL migrations), `test/`, `_legacy_scripts/`, `assets/config/`, `README`s.

**Status:** read-only investigation. **No files, database objects, environment variables, or Supabase settings were modified. No migration was performed.**

---

## 1. Executive Summary

- The Seller app is a **Flutter app that talks to Supabase over raw PostgREST / Storage / Functions HTTP endpoints using the `anon` key** — it does **not** use the Supabase client SDK, **Supabase Auth** (identity is **Firebase Phone Auth**, project `vpnexues-otp-and-img-s`), **Realtime**, or any client-side `.rpc()` call.
- **12 distinct table names** are referenced anywhere in the repo (Dart + edge functions + SQL). Of these, **5 are used actively by the Seller app at runtime**, **3 more are used only by the Seller edge functions**, **2 are dormant (defined in code but never called)**, and **2 are referenced only indirectly (FK / SQL definition)**.
- **1 RPC:** `seller_lookup_registered(p_phone)` (called by an edge function, not the app).
- **1 Supabase Storage bucket:** `product-images` (public). Product images are primarily stored on **Cloudinary** (external service) via the `product-image` edge function.
- **4 Supabase Edge Functions:** `seller-bank`, `seller-link-account`, `seller-registration-status`, `product-image`.
- **Critical gap:** SQL migrations `001`–`016` are **missing from the repo**. Five core tables (`sellers_products`, `seller_profiles`, `seller_verify_your_details`, `seller_bank_details`, and `products`) have **no `CREATE TABLE` anywhere in this repository** — their schema must be exported from the old Supabase project, not recreated from repo SQL.

---

## 2. How the Seller App Reaches Supabase

| Path | Transport | Auth | Files |
|---|---|---|---|
| Direct REST (PostgREST) | `GET/POST/PATCH/DELETE {SUPABASE_URL}/rest/v1/<table>` | `apikey` + `Authorization: Bearer <anon key>` | `lib/data/supabase_product_api.dart`, `lib/data/supabase_order_api.dart` |
| Storage REST | `PUT/DELETE {SUPABASE_URL}/storage/v1/object/<bucket>/<path>` | anon key | `lib/data/supabase_storage_api.dart` |
| Edge Functions | `POST {SUPABASE_URL}/functions/v1/<name>` | anon key + optional **Firebase ID token** | `lib/services/edge_api.dart`, `lib/data/product_image_api.dart` |
| Custom backend (non-Supabase) | `https://vpnexues-seller-backend.onrender.com/api` (Spring Boot on Render) | Firebase ID token | `lib/services/backend_service.dart`, `lib/services/seller_backend_sync.dart` |

Config sources (for later update — **not modified**): `assets/config/supabase.json` and/or `--dart-define SUPABASE_URL / SUPABASE_ANON_KEY` (see `lib/data/api_config.dart`).

**Verified absences:**
- No `.rpc(` / `rpc(` calls in any Dart file.
- No `postgres_changes` / `.channel(` / Realtime subscriptions in any Dart file.
- No `auth/v1` (Supabase Auth) usage anywhere — Firebase Auth only.
- No `.from("table")` Supabase-SDK calls in Dart (raw HTTP instead).

---

## 3. Complete Table Inventory (12 tables)

| # | Table | Category | Used by Seller app at runtime? |
|---|---|---|---|
| 1 | `sellers_products` | Shared (Seller writes / Buyer likely reads) | ✅ Yes |
| 2 | `seller_profiles` | Shared (Seller writes / Buyer likely reads) | ✅ Yes |
| 3 | `seller_registrations` | **Seller-only** | ✅ Yes |
| 4 | `seller_verify_your_details` | **Seller-only** | ✅ Yes |
| 5 | `seller_bank_details` | **Seller-only** | ✅ Yes (via edge function only) |
| 6 | `seller_transactions` | **Seller-only** | ✅ Yes (SELECT); INSERT dormant |
| 7 | `seller_lookup_rate_limits` | **Seller-only** | ✅ Yes (via edge function only) |
| 8 | `orders` | Shared (Buyer creates / Seller updates) | ⚠️ Dormant code only |
| 9 | `order_items` | Shared (part of `orders`) | ⚠️ Dormant code only |
| 10 | `seller_reviews` | Shared (Buyer writes; Seller UI is local-only) | ❌ No |
| 11 | `products` | **Uncertain** — indirect FK dependency only | ❌ No (FK target of `order_items`) |
| 12 | `storage.objects` / `storage.buckets` (system) | Indirect (holds the `product-images` bucket) | ✅ Yes (bucket row) |

> **Category note:** "Shared" is inferred from table semantics and naming — the Buyer app source is **not** in this repository, so Buyer-side usage could not be directly verified. Tables marked *probable shared* are safe to migrate to the Seller project only if the Buyer app will **not** be co-located in the same new project; otherwise plan for data ownership (see §8).

---

## 4. Detailed Table Findings

### 4.1 `sellers_products` — Shared (probable) — **REQUIRED**

Seller product catalog (CRUD).

- **Operations:** `SELECT` (`user_id=eq.<uid>`), `INSERT`, `UPDATE` (`id` + `user_id` scoped), `DELETE` (`id` + `user_id` scoped).
- **Source files:**
  - `lib/data/supabase_product_api.dart` — L43 (SELECT), L88 (INSERT), L508 + L403 (UPDATE), L416 (DELETE)
  - `lib/data/seller_product_repository.dart` (repository wrapper)
  - `lib/screens/add_products_screen.dart` (L440), `lib/screens/edit_product_screen.dart`, `lib/screens/my_products_screen.dart`
  - `lib/data/product_image_uploader.dart`, `lib/data/product_image_url.dart`, `lib/data/product_image_api.dart` (URLs written into `product_img_1..5`)
  - `lib/services/cold_start_router.dart` (background product refresh)
- **Columns written/read:** `id`, `user_id`, `product_name`, `category`, `price`, `quantity`, `unit`, `product_descrption`, `product_avaliblit`, `product_img_1`…`product_img_5`, `buyer_pickup_enabled`, `delivery_enabled`.
- **Dependencies:**
  - `unit` column added by `seller-backend/db/024_product_images_storage.sql` (repo ✅).
  - **Missing migration referenced in error paths:** `008_seller_products_id_access.sql` (not in repo ❌) — implies additional id-based RLS/access policies exist only in the old project.
  - Image URLs point to the `product-images` bucket (legacy rows) or Cloudinary (new rows).

### 4.2 `seller_profiles` — Shared (probable) — **REQUIRED**

One row per seller: onboarding, business profile, location, FCM token, active bank pointer.

- **Operations:** `SELECT` (by `firebase_uid`, `phone_number`, or uuid `user_id`), `INSERT`, `UPDATE`.
- **Source files:**
  - `lib/data/supabase_product_api.dart` — L334/L367 (`saveSellerType`), L749/L796 (lookups), L883 (active bank read), L911 (active bank write), L1123/L1147 (`saveSellerProfile`), L1215/L1239 (`saveLocationDetails`), L1297 (`saveFcmToken`)
  - `lib/screens/seller_type_screen.dart` (L99), `lib/screens/personal_details_screen.dart` (L200), `lib/screens/business_details_screen.dart` (L212), `lib/screens/location_confirm_screen.dart` (L81, L575)
  - `lib/services/notification_service.dart` (L133 — FCM token), `lib/services/cold_start_router.dart` (L215+), `lib/screens/splash_screen.dart` (L254), `lib/screens/otp_screen.dart` (L244)
  - Edge functions: `seller-link-account` (SELECT L79/L88/L96, UPDATE L142), `seller-bank` (SELECT L72/L94/L103)
  - RPC `seller_lookup_registered` reads this table (fallback match on `phone_number`).
- **Columns:** `user_id` (uuid PK), `display_name`, `phone_number`, `location`, `business_address`, `business_name`, `seller_type`, `latitude`, `longitude`, `created_at`, `updated_at`, `active_bank_account_id`, `avatar_url`, `fcm_token`, `firebase_uid`, `verified`.
- **Dependencies (migrations):** `009_seller_profiles_write.sql` ❌ missing, `014_seller_profiles_fcm_token.sql` ❌ missing, `016_seller_profiles_firebase_uid.sql` ❌ missing, `020_seller_profiles_active_bank_account.sql` ✅, `021_seller_registrations_setup.sql` ✅ (adds `latitude`/`longitude`/`updated_at`, anon RLS policies, trigger).
- **Trigger:** `seller_profiles_touch_updated_at` → `public.set_updated_at()` (from 021).

### 4.3 `seller_registrations` — Seller-only — **REQUIRED**

Pre-OTP sign-up + login phone lookup.

- **Operations:**
  - App `INSERT` only (`Prefer: return=minimal`, **client-generated uuid**, no read-back — anon has no SELECT policy). `lib/data/supabase_product_api.dart` L267 (`createRegistration`), called from `lib/screens/welcome_seller_screen.dart` L303.
  - Edge functions (service role): `seller-link-account` SELECT L57/L66 + UPDATE L120 (sets `firebase_uid`, `status='linked'`, `phone_verified=true`); `seller-bank` SELECT L62/L85/L125 (authorization); `seller-registration-status` via RPC.
- **Columns:** `id` (uuid PK), `name`, `phone_e164` (UNIQUE), `status` (`pending`|`linked`), `firebase_uid`, `phone_verified`, `created_at`, `updated_at`.
- **Dependencies:** `021_seller_registrations_setup.sql` ✅ — table, RLS policy `anon_can_register` (INSERT-only, `TO anon`), indexes, trigger `seller_registrations_touch_updated_at` → `set_updated_at()`.
- **Migration note:** unique index on `phone_e164` and RLS policy are load-bearing — the app relies on `409` for duplicates and on no-SELECT for inserts.

### 4.4 `seller_verify_your_details` — Seller-only — **REQUIRED**

KYC document metadata (Step 04).

- **Operations:** `UPSERT` (`POST …?on_conflict=user_id` with `Prefer: return=representation,resolution=merge-duplicates`), `SELECT` (`user_id=eq.<id>`).
- **Source files:** `lib/data/supabase_product_api.dart` — L170 (`saveVerifyDetails`), L959 (`getVerificationByUserId` via dynamic `_rowsWhere` — the **only** table ever passed to that generic helper); `lib/screens/verify_detaile.dart` (L135 read, L427 write).
- **Columns:** `user_id`, `aadhaar_card`, `pan_card`, `business_registration`, `aadhaar_file_name`, `pan_file_name`, `business_file_name`, `kyc_status`, `updated_at`.
- **Dependencies:** `012_seller_verify_your_details.sql` ❌ **missing (CREATE TABLE not in repo)**; `021_…setup.sql` ✅ adds the file-name/status/`updated_at` columns + anon SELECT/INSERT/UPDATE policies.

### 4.5 `seller_bank_details` — Seller-only — **REQUIRED** (edge-function-only access)

Bank account details; direct anon access deliberately revoked.

- **Operations:** `SELECT`, `INSERT`, `UPDATE`, `DELETE` — **all exclusively through the `seller-bank` Edge Function using the service-role key** (RLS lockdown: anon has zero policies after `022`).
  - Edge function: `supabase/functions/seller-bank/index.ts` — SELECT L184, UPDATE L209, INSERT L221, DELETE L234.
  - App call sites: `lib/data/supabase_product_api.dart` (`saveBankDetails` L108, `deleteBankDetails` L142, `getBankDetailsForUsers` L849), `lib/services/edge_api.dart` (`bankRead`/`bankUpsert`/`bankDelete` L210–267).
  - Screens: `lib/screens/bank_detaile.dart`, `lib/screens/bank_details_screen.dart`, `lib/screens/bank_details_view.dart`, plus cold-start/OTP/splash restores.
- **Columns:** `id`, `user_id`, `account_houlder_name` *(typo is in the schema — keep it exactly)*, `bank_name`, `account_number`, `IFSC_code`.
- **Dependencies:**
  - `022_bank_lockdown.sql` ✅ (RLS enable + drop all anon policies).
  - `023_seller_bank_details_id_default.sql` ✅ — creates/​seeds sequence **`seller_bank_details_id_seq`** (`setval` past legacy millisecond-timestamp ids) and sets it as the `id` default.
  - **CREATE TABLE not in repo ❌** — export schema from old project.
  - **Data-migration trap:** the sequence's current value must be migrated too (`setval`), or new inserts will collide with legacy ids.

### 4.6 `seller_transactions` — Seller-only — **REQUIRED** (SELECT live; INSERT dormant)

Seller wallet ledger.

- **Operations:**
  - **Active:** `SELECT` (`user_id=eq.<uid>`, ordered `created_at.desc`) — `lib/data/supabase_product_api.dart` L431, driven by `lib/data/wallet_store.dart` L57 (Wallet page / `profile_shell.dart`).
  - **Dormant:** `INSERT` — `insertTransaction()` (L467, comment: *"Prepared for future writers … not called yet"*) and `supabase_order_api.dart` L227 (`confirmOrderPickup`).
- **Columns:** `id`, `user_id`, `type` (`credit`|`withdrawal`), `amount`, `title`, `order_id`, `created_at`.
- **Dependencies:** `017_seller_transactions.sql` ✅ — table, index `seller_transactions_user_created_idx`, RLS (allow-all), grants.

### 4.7 `seller_lookup_rate_limits` — Seller-only — **REQUIRED** (edge-function-only)

Anti-enumeration rate limiting for the pre-OTP login phone check.

- **Operations:** `SELECT` + `UPSERT` (on conflict `key`) — `supabase/functions/seller-registration-status/index.ts` L41/L48/L56, service role only.
- **Columns:** `key` (PK), `window_start`, `count`.
- **Dependencies:** `021_seller_registrations_setup.sql` ✅ — RLS enabled with **no policies** (service-role only, by design).

### 4.8 `orders` — Shared — **REQUIRED for schema + data if Buyer shares the project; dormant in Seller app**

- **Code status:** `lib/data/supabase_order_api.dart` implements `SELECT` (L29, L60 — with `order_items(*)` embed), `INSERT` (L118), `UPDATE` (L193), `DELETE` (L251) — **but the class is never imported anywhere in `lib/` or `test/`**. The Orders screen (`lib/screens/my_orders_screen.dart`) uses the local demo `OrderStore`. The Buyer app is the presumed live writer.
- **Columns:** `id`, `order_id` (UNIQUE), `buyer_id`, `seller_id`, `total_amount`, `delivery_charges`, `status`, `pickup_type`, `expected_pickup_date`, `buyer_note`, `seller_note`, `buyer_pickup_enabled`, `delivery_enabled`, `created_at`, `updated_at`.
- **Dependencies:** `019_seller_orders.sql` ✅ — table, CHECK constraints (`status`, `pickup_type`), indexes, RLS (4 policies), sequence `orders_id_seq`, trigger `update_orders_updated_at` → `public.update_updated_at_column()`.

### 4.9 `order_items` — Shared — **REQUIRED with `orders`** (dormant in Seller app)

- **Code status:** `INSERT` (L148) and embedded `SELECT` in the same unused `SupabaseOrderApi`.
- **Columns:** `id`, `order_id`, `product_id`, `quantity`, `unit`, `rate`, `total_price`, `product_name`, `created_at`.
- **Dependencies:** `019_seller_orders.sql` ✅ — table, RLS, sequence `order_items_id_seq`, index.
- **⚠️ Foreign keys (only 2 in the whole repo):**
  - `order_items.order_id → orders(id) ON DELETE CASCADE`
  - `order_items.product_id → products(id)` → **forces table `products` to exist** (see §4.11).

### 4.10 `seller_reviews` — Shared — **not used by the Seller app**

- Defined by `018_seller_reviews.sql` ✅ (table, unique index on `(buyer_user_id, seller_user_id)`, RLS, grants).
- **Zero references in Dart** — `lib/screens/write_review_screen.dart` and `review_ratings_page.dart` persist through the **local** `lib/data/review_store.dart` only.
- **Category:** shared/likely Buyer-written. Migrate only if the Buyer app writes it.

### 4.11 `products` — Uncertain / indirect dependency — **INVESTIGATE**

- **Never created, never queried** by the Seller app or edge functions.
- Referenced **only** as the FK target `order_items.product_id → products(id)` inside `019_seller_orders.sql`.
- **Implications for migration:**
  - Running `019` in the new project **fails** unless `public.products` exists.
  - If `order_items.product_id` values actually reference `sellers_products` rows (not a `products` catalog), this FK is a legacy artifact — verify against the old project's live schema before migrating.
- **Action:** inspect the old project (`\d public.products`) to decide: migrate schema+data, migrate schema only, or drop the FK in the new project.

### 4.12 System tables — `storage.buckets` / `storage.objects` — indirect

- The `product-images` bucket row and its 3 RLS policies live in `storage.buckets` / `storage.objects` (created by `024_product_images_storage.sql` ✅). These come along automatically when the bucket + policies SQL is run.

---

## 5. RPC Functions

| RPC | Defined in | Called from | Notes |
|---|---|---|---|
| `public.seller_lookup_registered(p_phone text)` | `seller-backend/db/021_seller_registrations_setup.sql` ✅ | `supabase/functions/seller-registration-status/index.ts` L107 (**service role**) | `SECURITY DEFINER`; reads `seller_registrations` (`phone_e164`) then falls back to `seller_profiles` (`phone_number`); returns `(id uuid, kind text)`; `EXECUTE` revoked from `public`/`anon`, granted to `service_role` only. **No RPC is called from the Flutter app.** |

Non-RPC database functions required (trigger helpers):
- `public.update_updated_at_column()` — from `019` ✅ (fires on `orders`).
- `public.set_updated_at()` — from `021` ✅ (fires on `seller_registrations`, `seller_profiles`).

Dropped-in-019 legacy functions (do **not** migrate): `set_order_item_ownership()`, `is_order_seller(text)`, `is_order_buyer(text)`.

---

## 6. Storage Buckets

| Bucket | Access | Used by | Defined in |
|---|---|---|---|
| **`product-images`** | **public**, 10 MB limit, mime types `image/jpeg,image/png,image/webp,image/gif` | `lib/data/supabase_storage_api.dart` — `PUT` upload (fallback when Cloudinary edge function unreachable), `DELETE` cleanup of legacy URLs only. Policies: public read, anyone upload, anyone delete (`TO anon, authenticated`). | `024_product_images_storage.sql` ✅ |

**Not Supabase, but part of the image pipeline:**
- **Cloudinary** (external) — primary image store, folder namespace `seller-products/{uid}/…`, handled by the `product-image` edge function. No migration needed in Supabase; only secrets must be present in the new project.
- **Private KYC bucket of the Render Spring Boot backend** (`https://vpnexues-seller-backend.onrender.com/api`) — `backend_service.dart` L118 states KYC files are stored in *"the backend's private Supabase bucket"*. Bucket name/schema not present in this repo → **see §7, item 4.**

---

## 7. Edge Functions & Secrets (must be redeployed to the new project)

| Function | Tables touched (service role) | Secrets required |
|---|---|---|
| `seller-bank` | `seller_bank_details` (SELECT/INSERT/UPDATE/DELETE), `seller_registrations` (SELECT), `seller_profiles` (SELECT) | `SUPABASE_SERVICE_ROLE_KEY` |
| `seller-link-account` | `seller_registrations` (SELECT/UPDATE), `seller_profiles` (SELECT/UPDATE) | `SUPABASE_SERVICE_ROLE_KEY` |
| `seller-registration-status` | `seller_lookup_rate_limits` (SELECT/UPSERT) + RPC `seller_lookup_registered` | `SUPABASE_SERVICE_ROLE_KEY` |
| `product-image` | none (writes URLs that the app stores in `sellers_products.product_img_1..5`) | `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` |

All are deployed with `--no-verify-jwt`; Firebase token verification is done in code (`_shared/firebase.ts`, hardcoded project `vpnexues-otp-and-img-s`).

**Items needing further investigation (outside this repo):**
1. **Missing SQL files 001–016** (referenced by name in code: `008`, `009`, `012`, `013`, `014`, `015`, `016`) — the CREATE TABLE definitions for `sellers_products`, `seller_profiles`, `seller_verify_your_details`, `seller_bank_details` exist only in the old project.
2. **`public.products`** table (§4.11) — schema/data unknown.
3. **Render Spring Boot backend** (`vpnexues-seller-backend.onrender.com`) — its own database tables and its private KYC storage bucket live in its own project/repo; decide whether that backend will also point at the new Seller Supabase project.
4. **Buyer app usage** of `sellers_products`, `seller_profiles`, `orders`, `order_items`, `seller_reviews` could not be verified (Buyer source not in this repo).

---

## 8. Suggested Migration Checklist (recommended order — nothing executed)

1. **Export schema from the old project** for the five tables with no repo DDL: `sellers_products`, `seller_profiles`, `seller_verify_your_details`, `seller_bank_details`, (+ `products` if kept). Include defaults, CHECK/UNIQUE constraints, indexes, and FKs.
2. **Run repo SQL in order** in the new project (they are written to be idempotent/guarded): `017` → `018` → `019` (needs `products` to pre-exist!) → `020` → `021` → `022` → `023` → `024`.
3. **Copy data** for the required tables (§3): Seller-only set + shared set agreed with the Buyer side.
4. **Fix sequences after data copy:** `setval` for `orders_id_seq`, `order_items_id_seq`, `seller_transactions_id_seq`, `seller_reviews_id_seq`, and especially **`seller_bank_details_id_seq`** (023's seeding logic).
5. **Storage:** run `024` (bucket + policies) or recreate the `product-images` bucket; optionally copy existing objects.
6. **Deploy the 4 edge functions** to the new project with the secrets listed in §7.
7. **Verify RPC** `seller_lookup_registered` exists with `service_role`-only EXECUTE.
8. **Update app config (when ready):** `assets/config/supabase.json` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) or `--dart-define SUPABASE_URL / SUPABASE_ANON_KEY`; relink the Supabase CLI project (old ref `ouzxglznpjeewdyxputa` appears in `supabase/.temp` and `product-image/README.md`).
9. **Run `NOTIFY pgrst, 'reload schema';`** (already appended to each repo SQL file) so PostgREST picks up the new schema.

---

## 9. Appendix — Source File Index

**Dart REST call sites (only two files hit `/rest/v1/` directly):**
- `lib/data/supabase_product_api.dart` → `sellers_products`, `seller_profiles`, `seller_registrations`, `seller_verify_your_details`, `seller_transactions`
- `lib/data/supabase_order_api.dart` → `orders`, `order_items`, `seller_transactions` *(class never imported — dormant)*

**Other Supabase touchpoints:**
- `lib/data/supabase_storage_api.dart` → bucket `product-images`
- `lib/services/edge_api.dart` → edge functions `seller-registration-status`, `seller-link-account`, `seller-bank`
- `lib/data/product_image_api.dart` → edge function `product-image`
- `supabase/functions/*/index.ts` → tables via service role (§7)

**SQL migrations present:** `seller-backend/db/017`…`024` (8 files). **Missing:** `001`–`016`.

**Confirmed NOT Supabase-backed (local-only):** `lib/data/order_store.dart`, `lib/data/review_store.dart`, `lib/data/sales_store.dart`, `lib/data/session_store.dart`, `lib/data/secure_session_store.dart`, `lib/data/app_storage.dart`, `lib/services/backend_service.dart` (Render backend, separate system).
