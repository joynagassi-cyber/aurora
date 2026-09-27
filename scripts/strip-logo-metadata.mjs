#!/usr/bin/env node
/**
 * strip-logo-metadata.mjs — ui-libraries §9.2 (owner decision 2026-09-27).
 *
 * Emits a BUILD-TIME stripped copy of the monochrome logo SVG for the
 * bundler. The C2PA provenance manifest (Recraft AI) is ~125 Ko of base64
 * inside `<metadata>` — it must NOT ship to the device (AD-3: no secrets /
 * provenance on device). Stripping metadata is NOT a redraw (S9): the art
 * is byte-identical, only the `<metadata>` element is removed.
 *
 * - INPUT  (SSoT, NEVER modified):  assets/vs_monochrome_en_svg.svg
 * - OUTPUT (generated, gitignored): apps/mobile/.build/aurora-mono.stripped.svg
 *
 * Run manually or as a pre-bundle step:
 *   node scripts/strip-logo-metadata.mjs
 *
 * Exits 0 on success, non-zero if the strip did not reduce size.
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import process from "node:process";

// fileURLToPath (not URL.pathname): correct Windows drive-letter handling.
const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const SRC = resolve(root, "assets/vs_monochrome_en_svg.svg");
const OUT_DIR = resolve(root, "apps/mobile/.build");
const OUT = resolve(OUT_DIR, "aurora-mono.stripped.svg");

function fail(msg) {
  console.error(`[strip-logo-metadata] ERROR: ${msg}`);
  process.exit(1);
}

const raw = readFileSync(SRC, "utf8");
const srcBytes = Buffer.byteLength(raw, "utf8");

// Remove every <metadata>...</metadata> element (non-greedy). The C2PA
// manifest is a single base64 blob, so a plain non-greedy match is safe and
// leaves the vector art (all <path>/<defs>/gradients) untouched.
const stripped = raw.replace(/<metadata[\s\S]*?<\/metadata>/g, "");
const outBytes = Buffer.byteLength(stripped, "utf8");

if (outBytes >= srcBytes) {
  fail(
    `strip did not reduce size (src=${srcBytes} out=${outBytes}); ` +
      "is the C2PA <metadata> block present in the SSoT?",
  );
}

mkdirSync(OUT_DIR, { recursive: true });
writeFileSync(OUT, stripped, "utf8");

console.log(
  `[strip-logo-metadata] OK: ${srcBytes} -> ${outBytes} bytes ` +
    `(−${srcBytes - outBytes} bytes, C2PA manifest removed). Wrote ${OUT}`,
);
