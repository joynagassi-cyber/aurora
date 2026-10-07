#!/usr/bin/env node
// patch-kwp-domain.mjs — corrige le `domain` des 69 lignes knowledge-work-plugins
// non-business dans la base live (re-push via PostgREST, `skill_key` UNIQUE constraint
// → on utilise `Prefer: resolution=merge-duplicates` pour PATCHER, pas ignorer).
//
// Contexte : run-lots.mjs a upserté ces 69 lignes avec `domain='business'`
// (mapping obsolète). Le fix mappingDomain (extrait le segment de domaine après
// le préfixe repo) corrige `0021_marketplace_skills.sql`, mais le SSoT live
// (`skill_catalog`) doit être re-syncé. Le `ON CONFLICT (skill_key) DO NOTHING`
// de run-lots.mjs ignore les lignes déjà présentes → il faut un POST
// différent, avec `resolution=merge-duplicates` (upsert) pour PATCHER le champ
// `domain` des 69 clés concernées.
//
// Usage :
//   node patch-kwp-domain.mjs            (tous les lots, 69 upserts PATCH)
//   node patch-kwp-domain.mjs --check    (dry-run, liste les 69, pas de re-push)

import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(__dirname, "..", "..", "..");

// — Identifiants (jamais en clair : lus depuis .env.local) —
const envLines = readFileSync(path.join(REPO, ".env.local"), "utf8").split("\n");
function envGet(key) {
  const line = envLines.find((l) => l.startsWith(key + "="));
  return line ? line.slice(key.length + 1).trim() : "";
}
const SUPABASE_URL = envGet("SUPABASE_URL").replace(/\/+$/, "");
const SERVICE_ROLE_KEY = envGet("SERVICE_ROLE_KEY") || envGet("SUPABASE_SECRET_KEY");
if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
  console.error("ABORT: SUPABASE_URL / SERVICE_ROLE_KEY absents dans .env.local");
  process.exit(1);
}

const CHECK_ONLY = process.argv.includes("--check");
const patch = JSON.parse(readFileSync(path.join(__dirname, "patch-kwp-domain.json"), "utf8"));
console.log("Patch à appliquer:", patch.length, "upserts PATCH (skill_key, domain)");

if (CHECK_ONLY) {
  console.log("\n— Dry-run: les 69 paires (clé, domaine) à patcher —");
  patch.forEach((p, i) => console.log(`  ${String(i + 1).padStart(3)}. ${p.skill_key}  →  ${p.domain}`));
  process.exit(0);
}

const base = SUPABASE_URL + "/rest/v1/skill_catalog";
const headers = {
  apikey: SERVICE_ROLE_KEY,
  Authorization: "Bearer " + SERVICE_ROLE_KEY,
  "Content-Type": "application/json",
  // PATCH par skill_key : upsert en mode merge (pas ignore-duplicates),
  // sinon les 69 clés déjà présentes ne sont pas touchées.
  Prefer: "resolution=merge-duplicates,return=minimal",
};

let ok = 0, fail = 0;
const failures = [];
for (const p of patch) {
  try {
    // POST /rest/v1/skill_catalog en mode upsert (Prefer: resolution=merge-duplicates)
    // avec `on_conflict=skill_key` : si la ligne existe, merge = patch le champ
    // `domain` sans toucher aux autres colonnes. Les 3 colonnes NOT NULL sans
    // défaut (name, source, domain) sont incluses explicitement pour éviter
    // une 23502 ; le merge ne fait PAS de re-not-null check sur les champs
    // non transmis.
    const res = await fetch(base + "?on_conflict=skill_key", {
      method: "POST",
      headers,
      body: JSON.stringify({
        skill_key: p.skill_key,
        domain: p.domain,
        name: p.name ?? p.skill_key.split("/").pop(),
        source: p.source ?? "marketplace:knowledge-work-plugins",
        trigger_: p.trigger_ ?? "",
        objective: p.objective ?? p.skill_key.split("/").pop(),
        description: p.description ?? "",
        procedure: p.procedure ?? [],
        constraints: p.constraints ?? [],
        tools: p.tools ?? [],
      }),
      signal: AbortSignal.timeout(30_000),
    });
    if (res.ok || res.status === 409) ok++;
    else {
      const text = await res.text();
      fail++;
      failures.push({ key: p.skill_key, status: res.status, text: text.slice(0, 150) });
    }
  } catch (e) {
    fail++;
    failures.push({ key: p.skill_key, error: e.message });
  }
}

console.log("\n--- RÉSUMÉ ---");
console.log("Upserts PATCH OK:", ok, "/ Fail:", fail, "/", patch.length);
if (failures.length > 0) {
  for (const f of failures.slice(0, 10))
    console.log("  " + (f.key ?? "?") + " → " + (f.error ? f.error : "HTTP " + f.status + " " + (f.text ?? "")));
  console.log("Relancer: idempotent, les échecs sont détectés par clé");
}

// — Vérification finale : re-lire 10 lignes aléatoires du patch → doit afficher le
//    domaine patché, non business.
try {
  const verify = await fetch(
    base +
      "?skill_key=in.(" +
      patch.slice(0, 10).map((p) => "'" + p.skill_key + "'").join(",") +
      ")&select=skill_key,domain",
    { headers: { apikey: SERVICE_ROLE_KEY, Authorization: "Bearer " + SERVICE_ROLE_KEY } },
  );
  const rows = await verify.json();
  console.log("\nVérif 10 lignes (doit matcher patch):");
  rows.forEach((r) => {
    const expected = patch.find((p) => p.skill_key === r.skill_key)?.domain;
    const badge = expected === r.domain ? "OK" : "MISMATCH (espéré " + expected + ")";
    console.log("  " + badge + "  " + r.skill_key + "  →  " + r.domain);
  });
} catch (e) {
  console.log("Vérif impossible:", e.message);
}
