# product-image — Cloudinary upload function

The only way the **Add Product** flow stores a photo. The app POSTs the
compressed photo here as base64; this function signs the upload with the
Cloudinary API secret held in Supabase secrets and returns the permanent
`secure_url`, which the app writes into `sellers_products.product_img_1..5`.

**The API secret never reaches the app.** Supabase stays the database and
auth provider — Cloudinary only stores and serves the image bytes.

| | |
|---|---|
| Actions | `upload` → `{ url, publicId }`, `delete` → `{ deleted: true }` |
| Auth | Firebase ID token required (seller must be signed in) |
| Storage path | `seller-products/{firebaseUid}/{timestamp}-{random}` |
| Limits | ≤ 8 MB, JPEG / PNG / WebP / GIF (format checked from magic bytes) |
| Secrets | `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` |

---

## 1. Create the Cloudinary account (one time, ~3 minutes)

1. Go to **<https://cloudinary.com>** → **Sign up** (free tier is fine for
   testing and small production volume).
2. Open the **Dashboard**. Note the **Cloud name** shown at the top
   (something like `dxxxxxxxxxxx`).
3. Go to **Settings → API Keys** → copy the **API key** and the **API
   secret**.

> **Keep the API secret private.** It goes only into Supabase (step 2), never
> into the app, never into a git commit.

> ⚠️ Heads-up: a Cloudinary secret from an older backend is recoverable from
> this repo's git history (`seller-backend/.env1.txt`, since deleted). If it
> belongs to a live company account, rotate it.

## 2. Store the secrets in Supabase (one time)

The project is already linked (`supabase/.temp/project-ref` →
`ouzxglznpjeewdyxputa`), CLI v3.2.0 installed. From the repo root:

```powershell
supabase functions secrets set `
  CLOUDINARY_CLOUD_NAME="your-cloud-name" `
  CLOUDINARY_API_KEY="your-api-key" `
  CLOUDINARY_API_SECRET="your-api-secret"
```

**Dashboard alternative:** Supabase Dashboard → your project → **Edge
Functions → Secrets → Add new secret**, one row per name above.

## 3. Deploy the function (one time, and again after editing it)

```powershell
supabase functions deploy product-image --no-verify-jwt
```

`--no-verify-jwt` matches the other functions in this repo: the gateway does
not check the token, and the function verifies the **Firebase** ID token
itself (Supabase Auth is not used in this app).

## 4. Verify it works

```powershell
# Should return 401 (no token) rather than 404 — 404 means not deployed.
curl -X POST `
  "https://ouzxglznpjeewdyxputa.supabase.co/functions/v1/product-image" `
  -H "Content-Type: application/json" `
  -d '{\"action\":\"upload\"}'
```

Then in the app: **Add Products** → add a photo → save → check the row:

```sql
select id, product_img_1 from public.sellers_products order by id desc limit 3;
```

`product_img_1` should look like
`https://res.cloudinary.com/<cloud>/image/upload/v…/seller-products/<uid>/…`.

## 5. If something goes wrong

| Symptom | Cause | Fix |
|---|---|---|
| `Image upload is not configured on the server yet` | Secrets missing | Re-run step 2 |
| `Image upload is not set up on the server yet. Deploy the product-image…` | Function not deployed | Re-run step 3 |
| HTTP 402 / `exceed_egress_quota` from every function | **Project-level** restriction (egress quota or spend caps) | The function is fine; the project owner must upgrade the plan or remove the spend caps in the Supabase dashboard. Nothing can be fixed client-side — the app will fall back to Supabase Storage automatically. |
| `Your session expired. Please sign in again.` | Missing/expired Firebase token | Sign out and back in |
| Photos still land in Supabase Storage | Fallback engaged | Check the function logs (Dashboard → Edge Functions → product-image → Logs) for the printed reason |

**Rollback:** the app falls back to the original `product-images` bucket
automatically whenever this function is unreachable, so simply undeploying
it restores the previous behaviour with no app release:

```powershell
supabase functions delete product-image
```

Existing rows are unaffected either way — old Supabase Storage URLs keep
rendering, and no database schema changed.
