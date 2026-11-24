// product-image — the only way the add-product flow stores a photo.
//
// The Flutter app never talks to Cloudinary directly and never sees an API
// secret: it POSTs the compressed photo here as base64, this function signs
// the upload with the secret held in Supabase secrets, and the returned
// `secure_url` is what the app writes into `sellers_products.product_img_1..5`.
//
// Body: { action: "upload" | "delete", ... }
//   upload: { file: "<base64>" }                    -> { url, publicId }
//   delete: { url: "https://res.cloudinary.com/…" } -> { deleted: true }
//
// Auth: a Firebase ID token is REQUIRED for both actions. Assets live under
// `seller-products/{uid}/…` and a caller may only ever touch its own folder,
// so one seller's token cannot delete another seller's photo.
//
// Secrets (Dashboard -> Settings -> Edge Functions -> Secrets, or CLI):
//   CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET
// Deploy with:
//   supabase functions deploy product-image --no-verify-jwt
//
// Photos are stored at full (already picker-compressed) resolution; every
// renderer asks Cloudinary for a resized copy through URL transformations
// (`f_auto,q_auto,w_<n>`), added in `lib/data/product_image_url.dart`.

import { corsHeaders, json, verifyFirebaseToken } from "../_shared/firebase.ts";

/** Namespaces every asset so a token can only reach its own folder. */
const FOLDER = "seller-products";

/** Matches the bucket limit this app shipped with (024_product_images_storage.sql). */
const MAX_BYTES = 8 * 1024 * 1024;

const ALLOWED_MIME = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
]);

/** Carries an HTTP status so Cloudinary's own wording can reach the app. */
class HttpError extends Error {
  readonly status: number;
  constructor(message: string, status: number) {
    super(message);
    this.name = "HttpError";
    this.status = status;
  }
}

interface Config {
  cloudName: string;
  apiKey: string;
  apiSecret: string;
}

/** Reads the three secrets; returns null when any is missing. */
function config(): Config | null {
  const cloudName = (Deno.env.get("CLOUDINARY_CLOUD_NAME") ?? "").trim();
  const apiKey = (Deno.env.get("CLOUDINARY_API_KEY") ?? "").trim();
  const apiSecret = (Deno.env.get("CLOUDINARY_API_SECRET") ?? "").trim();
  if (!cloudName || !apiKey || !apiSecret) return null;
  return { cloudName, apiKey, apiSecret };
}

/** Cloudinary's signature: sha1 of the sorted signable params + secret. */
async function signature(
  params: Record<string, string>,
  apiSecret: string,
): Promise<string> {
  const canonical = Object.keys(params)
    .sort()
    .map((key) => `${key}=${params[key]}`)
    .join("&");
  const digest = await crypto.subtle.digest(
    "SHA-1",
    new TextEncoder().encode(canonical + apiSecret),
  );
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

/** Accepts raw base64 or a `data:…;base64,` URI. */
function decodeBase64(value: string): Uint8Array {
  const payload = value.startsWith("data:")
    ? value.slice(value.indexOf(",") + 1)
    : value;
  const binary = atob(payload);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

/** Identifies the format from magic bytes — the client's word is not trusted. */
function sniffMime(bytes: Uint8Array): string | null {
  if (bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
    return "image/jpeg";
  }
  if (
    bytes.length >= 8 && bytes[0] === 0x89 && bytes[1] === 0x50 &&
    bytes[2] === 0x4e && bytes[3] === 0x47
  ) {
    return "image/png";
  }
  if (bytes.length >= 6 && bytes[0] === 0x47 && bytes[1] === 0x49 && bytes[2] === 0x46 && bytes[3] === 0x38) {
    return "image/gif";
  }
  if (
    bytes.length >= 12 && bytes[0] === 0x52 && bytes[1] === 0x49 &&
    bytes[2] === 0x46 && bytes[3] === 0x46 && bytes[8] === 0x57 &&
    bytes[9] === 0x45 && bytes[10] === 0x42 && bytes[11] === 0x50
  ) {
    return "image/webp";
  }
  return null;
}

function extensionFor(mime: string): string {
  switch (mime) {
    case "image/png":
      return "png";
    case "image/webp":
      return "webp";
    case "image/gif":
      return "gif";
    default:
      return "jpg";
  }
}

/** 16 hex chars — collision-safe alongside the millisecond timestamp. */
function randomToken(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(8));
  return Array.from(bytes, (byte) => byte.toString(16).padStart(2, "0")).join("");
}

/**
 * `…/image/upload/v1234567/seller-products/uid/abc.jpg`
 *   -> `seller-products/uid/abc`
 *
 * Delivery URLs carry a version prefix and a format extension that the
 * public_id never includes. Throws when the URL is not a Cloudinary image.
 */
function publicIdFromUrl(raw: string): string {
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    throw new HttpError("Not a Cloudinary image url.", 400);
  }
  if (!url.hostname.endsWith(".cloudinary.com")) {
    throw new HttpError("Not a Cloudinary image url.", 400);
  }
  const marker = "/upload/";
  const at = url.pathname.indexOf(marker);
  if (at < 0) throw new HttpError("Not a Cloudinary image url.", 400);

  let rest = url.pathname.slice(at + marker.length);
  rest = rest.replace(/^v\d+\//, "");
  rest = rest.replace(/\.(jpe?g|png|webp|gif|avif|bmp)$/i, "");
  if (!rest) throw new HttpError("Not a Cloudinary image url.", 400);
  return decodeURIComponent(rest);
}

async function handleUpload(
  body: Record<string, unknown>,
  uid: string,
  cfg: Config,
): Promise<Response> {
  const encoded = typeof body?.file === "string" ? body.file.trim() : "";
  if (!encoded) return json({ error: "Missing photo." }, 400);

  let bytes: Uint8Array;
  try {
    bytes = decodeBase64(encoded);
  } catch {
    return json({ error: "The photo could not be read." }, 400);
  }
  if (bytes.length === 0) return json({ error: "The photo is empty." }, 400);
  if (bytes.length > MAX_BYTES) {
    return json({ error: "Photos must be smaller than 8 MB." }, 400);
  }

  const mime = sniffMime(bytes);
  if (!mime || !ALLOWED_MIME.has(mime)) {
    return json({ error: "Use a JPEG, PNG, WebP or GIF photo." }, 400);
  }

  const timestamp = Math.floor(Date.now() / 1000);
  const publicId = `${FOLDER}/${uid}/${timestamp}-${randomToken()}`;
  const sig = await signature(
    { public_id: publicId, timestamp: String(timestamp) },
    cfg.apiSecret,
  );

  const form = new FormData();
  form.append("file", new Blob([bytes], { type: mime }), `photo.${extensionFor(mime)}`);
  form.append("api_key", cfg.apiKey);
  form.append("timestamp", String(timestamp));
  form.append("signature", sig);
  form.append("public_id", publicId);

  const response = await fetch(
    `https://api.cloudinary.com/v1_1/${cfg.cloudName}/image/upload`,
    { method: "POST", body: form },
  );
  const result = await response.json().catch(() => null);

  if (!response.ok || !result?.secure_url) {
    const message = result?.error?.message ??
      `Cloudinary rejected the upload (HTTP ${response.status}).`;
    throw new HttpError(String(message), 502);
  }
  return json({
    url: String(result.secure_url),
    publicId: String(result.public_id ?? publicId),
  });
}

async function handleDelete(
  body: Record<string, unknown>,
  uid: string,
  cfg: Config,
): Promise<Response> {
  const raw = typeof body?.url === "string" ? body.url.trim() : "";
  if (!raw) return json({ error: "Missing image url." }, 400);

  const publicId = publicIdFromUrl(raw);

  // The real security check: only assets under this caller's own folder.
  if (!publicId.startsWith(`${FOLDER}/${uid}/`)) {
    return json({ error: "Not authorized." }, 403);
  }

  const timestamp = Math.floor(Date.now() / 1000);
  const sig = await signature(
    { public_id: publicId, timestamp: String(timestamp) },
    cfg.apiSecret,
  );

  const form = new FormData();
  form.append("public_id", publicId);
  form.append("api_key", cfg.apiKey);
  form.append("timestamp", String(timestamp));
  form.append("signature", sig);

  const response = await fetch(
    `https://api.cloudinary.com/v1_1/${cfg.cloudName}/image/destroy`,
    { method: "POST", body: form },
  );
  const result = await response.json().catch(() => ({}));

  // "Not found" is the outcome we wanted — deletion stays idempotent.
  if (!response.ok && result?.error?.message !== "Not found") {
    const message = result?.error?.message ??
      `Cloudinary could not delete the photo (HTTP ${response.status}).`;
    throw new HttpError(String(message), 502);
  }
  return json({ deleted: true });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed." }, 405);
  }

  // Declared outside the try so the catch can log which action failed.
  let action = "";

  try {
    const cfg = config();
    if (!cfg) {
      return json(
        { error: "Image upload is not configured on the server yet." },
        500,
      );
    }

    const token = await verifyFirebaseToken(req.headers.get("Authorization"))
      .catch(() => null);
    if (!token) {
      return json({ error: "Your session expired. Please sign in again." }, 401);
    }

    const body = await req.json().catch(() => ({})) as Record<string, unknown>;
    action = String(body?.action ?? "");

    if (action === "upload") return await handleUpload(body, token.uid, cfg);
    if (action === "delete") return await handleDelete(body, token.uid, cfg);
    return json({ error: "Unknown action." }, 400);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unexpected error.";
    console.error(`product-image ${action || "?"} failed: ${message}`);
    if (err instanceof HttpError) return json({ error: message }, err.status);
    const unauthorized = /token/i.test(message);
    return json(
      {
        error: unauthorized
          ? "Your session expired. Please sign in again."
          : "Could not reach the server. Please try again.",
      },
      unauthorized ? 401 : 500,
    );
  }
});
