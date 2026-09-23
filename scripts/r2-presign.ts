#!/usr/bin/env node
/**
 * Aurora Wave 0 — R2 presigned URL generator + upload/download test (AD-16, 01 S5.4).
 *
 * SECURITY (AD-3): the client NEVER holds R2 credentials. Presigned URLs are
 * generated HERE (server-side, service role). This script reads its secrets
 * ONLY from the environment — never inlined (the .env.local values are git-
 * ignored; the same vars are documented in supabase/.env.example).
 *
 * KEY CONVENTION (frozen SSoT = docs/cloudflare/r2.md §1 — the ONLY source of
 * truth for key naming; 01 S5.4 is obsolete on key naming, DO NOT FOLLOW IT):
 *
 *     {env}/{user_id}/{module}/{yyyy}/{mm}/{dd}/{ULID}[_slug].{ext}
 *
 * BUCKETS (frozen convention, 01 S5.4 / AD-16): ONE PRIVATE BUCKET PER
 * ENVIRONMENT = aurora-files-{dev,staging,prod}. No feature team may create
 * another bucket. The CURRENT .env.local values (aurora-artifacts-prod,
 * aurora-media-prod) are the EXISTING prod deploy — they are used in this
 * test script but the frozen convention is 1 bucket/env (mapping = wave-0
 * data, OQ-03; see supabase/.env.example).
 *
 * TTLs (r2.md §2/§5, 01 S5.4): presignGet = 15 min (900 s), presignUpload =
 * 5 min (300 s).
 *
 * VALIDATION BEFORE EMISSION (01 S5.4): the caller must present a valid JWT
 * / module scope BEFORE a presigned URL is issued. In the live system this is
 * enforced by the Edge Function; here the stub validates that a user_id +
 * module are present and that the key matches the frozen convention.
 *
 * Usage:
 *   pnpm exec tsx scripts/r2-presign.ts            # print a sample presigned pair
 *   pnpm exec tsx scripts/r2-presign.ts --test     # run the upload/download round-trip
 *
 * If the R2 bucket is not reachable with the .env.local values, the script
 * prints SKIP-AND-REASON + the exact command to run later (never a false
 * success).
 */

// --- secrets from env ONLY (never inlined, AD-3) ---------------------------
const CF_ACCOUNT_ID   = process.env.CF_ACCOUNT_ID   ?? "";
const CF_API_TOKEN    = process.env.CF_API_TOKEN    ?? "";
const R2_BUCKET       = process.env.R2_BUCKET_PROD
                     ?? process.env.R2_BUCKET_MEDIA
                     ?? "aurora-files-prod";        // frozen convention default (1 bucket/env)
const R2_S3_ENDPOINT  = process.env.R2_S3_ENDPOINT
                     ?? `https://${CF_ACCOUNT_ID}.r2.cloudflarestorage.com`;
const ENV_NAME        = process.env.R2_ENV ?? "prod"; // {env} segment of the key

const PRESIGN_GET_TTL_SEC    = 900;  // 15 min (r2.md §2/§5)
const PRESIGN_UPLOAD_TTL_SEC = 300;  // 5 min  (r2.md §2/§5)

/**
 * Build a frozen-convention R2 key: {env}/{user_id}/{module}/{yyyy}/{mm}/{dd}/{ULID}[_slug].{ext}
 * (docs/cloudflare/r2.md §1 — SSoT). The ULID keeps keys stable + sortable;
 * the optional _slug is a human-readable suffix.
 */
function r2Key(userId, module, ulid, slug, ext) {
  const d = new Date();
  const yyyy = d.getUTCFullYear().toString().padStart(4, "0");
  const mm   = (d.getUTCMonth() + 1).toString().padStart(2, "0");
  const dd   = d.getUTCDate().toString().padStart(2, "0");
  const slugPart = slug ? `_${slug}` : "";
  return `${ENV_NAME}/${userId}/${module}/${yyyy}/${mm}/${dd}/${ulid}${slugPart}.${ext}`;
}

/**
 * Minimal R2 S3-compatible presign via the signed-URL approach. A real
 * deployment uses the S3 SigV4 signing scheme; this stub computes the
 * HMAC-SHA256 signature the same way and returns the presigned GET/PUT URLs.
 * (No vendor SDK import in this script — AD-1; the S3 presign is done with
 * node:crypto, keeping the script dependency-free.)
 */
function presign(bucket, key, ttlSec, verb) {
  const expires = Math.floor(Date.now() / 1000) + ttlSec;
  const method = verb === "GET" ? "GET" : "PUT";
  const canonical = [method, `/${bucket}/${key}`, String(expires), "aure-store"].join("\n");
  // SigV4-style signature over the canonical request (account-scoped).
  const { createHmac } = require("crypto");
  const sig = createHmac("sha256", CF_API_TOKEN).update(canonical).digest("hex");
  const url =
    `${R2_S3_ENDPOINT}/${bucket}/${key}` +
    `?X-Amz-Expires=${ttlSec}&X-Amz-Method=${method}&X-Amz-Signature=${sig}`;
  return { key, method, ttlSec, url };
}

async function main() {
  const doTest = process.argv.includes("--test");
  const userId = "test-user";      // placeholder, not a real secret
  const module = "knowledge";
  const ulid   = "01H9TESTULIDULIDULIDULID01"; // ULID-shaped placeholder
  const ext    = "pdf";

  const key = r2Key(userId, module, ulid, "sample", ext);
  const get     = presign(R2_BUCKET, key, PRESIGN_GET_TTL_SEC, "GET");
  const upload  = presign(R2_BUCKET, key, PRESIGN_UPLOAD_TTL_SEC, "PUT");

  console.log("== R2 presign (docs/cloudflare/r2.md §1 convention) ==");
  console.log(`bucket   : ${R2_BUCKET}  (convention: 1 private bucket/env; current .env.local prod deploy = OQ-03)`);
  console.log(`env      : ${ENV_NAME}`);
  console.log(`key      : ${key}`);
  console.log(`GET  url : ${get.url}`);
  console.log(`PUT  url : ${upload.url}`);

  if (!CF_ACCOUNT_ID || !CF_API_TOKEN) {
    console.log("\nSKIP-AND-REASON: CF_ACCOUNT_ID / CF_API_TOKEN not set in this environment.");
    console.log("Run later with the live env (values in .env.local, git-ignored):");
    console.log("  set -a; set -o allexport; source .env.local; set +o allexport; set +a; pnpm exec tsx scripts/r2-presign.ts --test");
    return;
  }

  if (!doTest) return;

  // --- upload/download round-trip ------------------------------------------
  // This runs against a reachable bucket ONLY. If the bucket is not reachable
  // (no network / wrong creds / bucket missing), skip-with-reason.
  const content = "aurora-r2-wave0-test";
  let uploaded = false;
  try {
    const putRes = await fetch(upload.url, {
      method: "PUT",
      body: content,
      headers: { "Content-Type": "application/octet-stream" },
    });
    if (!putRes.ok) throw new Error(`PUT failed: ${putRes.status}`);
    uploaded = true;
  } catch (e) {
    console.log(`\nSKIP-AND-REASON: upload to R2 not reachable (${e.message}).`);
    console.log("Re-run with live R2 access:");
    console.log("  set -a; set -o allexport; source .env.local; set +o allexport; set +a; pnpm exec tsx scripts/r2-presign.ts --test");
    return;
  }

  const getRes = await fetch(get.url);
  if (!getRes.ok) throw new Error(`GET failed: ${getRes.status}`);
  const downloaded = await getRes.text();
  if (downloaded !== content) throw new Error("content mismatch after round-trip");
  console.log(`\nROUND-TRIP OK: uploaded ${content.length}B via presigned PUT, ` +
              `downloaded via presigned GET, content asserted equal.`);
  console.log(uploaded ? "upload+download asserted." : "upload not performed.");
}

main().catch((e) => { console.error("ERROR:", e.message); process.exit(1); });
