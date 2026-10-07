#!/usr/bin/env node
// patch-kwp-domain.mjs — corrige le `domain` des 69 lignes knowledge-work-plugins
// non-business dans la base live.
//
// Contexte : run-lots.mjs a upserté ces 69 lignes avec `domain='business'`
// (mapping obsolète — le doublon `knowledge-work-plugins/knowledge-work-plugins/`
// cassait le `startsWith("design")` de mappingDomain). Le fix dans
// scripts/skills-seed.ts corrige le SSoT local (`0021_marketplace_skills.sql`),
// mais la base live doit être re-synchronisée.
//
// Méthode : PATCH /rest/v1/skill_catalog?skill_key=eq.<key> avec le champ
// `domain` uniquement (idempotent, ne viole pas les NOT NULL, ne touche pas
// les autres colonnes). Mêmes clés API qu'`patch-marketplace-meta.mjs`.
//
// Usage :
//   node patch-kwp-domain.mjs            (tous les 69, re-push live)
//   node patch-kwp-domain.mjs --check    (dry-run, liste les 69 paires)

import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(__dirname, "..", "..", "..");

const envLines = readFileSync(path.join(REPO, ".env.local"), "utf8").split("\n");
function envGet(key) {
  const line = envLines.find((l) => l.startsWith(key + "="));
  return line ? line.slice(key.length + 1).trim() : "";
}
const SUPABASE_URL = envGet("SUPABASE_URL").replace(/\/+$/, "");
// SERVICE_ROLE_KEY = l'alias local du secret service_role (mêmee valeur que
// SUPABASE_SECRET_KEY côté Supabase/CI ; Supabase refuse un secret projet
// nommé SUPABASE_*, d'où le renommage côté EF, 2026-10-06).
const SERVICE_ROLE_KEY = envGet("SERVICE_ROLE_KEY") || envGet("SUPABASE_SECRET_KEY");
if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
  console.error("ABORT: SUPABASE_URL / SERVICE_ROLE_KEY absents dans .env.local");
  process.exit(1);
}

const CHECK_ONLY = process.argv.includes("--check");
const patch = JSON.parse(readFileSync(path.join(__dirname, "patch-kwp-domain.json"), "utf8"));
console.log("Patch à appliquer:", patch.length, "PATCHs (skill_key, domain)");

if (CHECK_ONLY) {
  patch.forEach((p, i) =>
    console.log(`  ${String(i + 1).padStart(3)}. ${p.skill_key}  →  ${p.domain}`)
  );
  process.exit(0);
}

const baseUrl = `${SUPABASE_URL}/rest/v1/skill_catalog`;
const headers = {
  apikey: SERVICE_ROLE_KEY,
  Authorization: "Bearer " + SERVICE_ROLE_KEY,
  "Content-Type": "application/json",
  Prefer: "return=minimal",
};

let ok = 0, fail = 0, skip = 0;
const failures = [];
for (const p of patch) {
  // PATCH par skill_key : seul le champ `domain` est envoyé → les autres colonnes
  // (NOT NULL incluses) ne sont pas touchées. C'est la même méthode que
  // patch-marketplace-meta.mjs (pas d'upsert merge qui déclencherait 23502).
  const res = await fetch(
    `${baseUrl}?skill_key=eq.${encodeURIComponent(p.skill_key)}`,
    {
      method: "PATCH",
      headers,
      body: JSON.stringify({ domain: p.domain }),
      signal: AbortSignal.timeout(30_000),
    }
  );
  if (res.status === 200 || res.status === 204) {
    ok++;
  } else {
    const text = await res.text();
    fail++;
    failures.push({ key: p.skill_key, status: res.status, text: text.slice(0, 150) });
  }
  // throttle léger (mêmes conditions que patch-marketplace-meta)
  await new Promise((r) => setTimeout(r, 15));
}

console.log("\n--- RÉSUMÉ ---");
console.log(`PATCH OK: ${ok} / FAIL: ${fail} / total: ${patch.length}`);
if (failures.length > 0) {
  for (const f of failures.slice(0, 10))
    console.log(`  ${f.key} → HTTP ${f.status} ${f.text}`);
  console.log("Relancer: idempotent, les échecs sont détectés par clé");
}

// — Vérification finale : re-lire 10 lignes → le domain est bien celui patché —
try {
  const verifyRes = await fetch(
    `${baseUrl}?select=skill_key,domain&skill_key=in.(` +
      patch.slice(0, 10).map((p) => encodeURIComponent("'" + p.skill_key + "'")).join(",") +
      `)`,
    { headers: { apikey: SERVICE_ROLE_KEY, Authorization: "Bearer " + SERVICE_ROLE_KEY } }
  );
  const rows = await verifyRes.json();
  console.log("\nVérif 10 lignes (doit matcher le patch):");
  for (const r of rows) {
    const expected = patch.find((p) => p.skill_key === r.skill_key)?.domain;
    const badge = expected === r.domain ? "OK" : "MISMATCH (espéré " + expected + ")";
    console.log(`  ${badge}  ${r.skill_key}  →  ${r.domain}`);
  }
} catch (e) {
  console.log("Vérif impossible:", e.message);
}
