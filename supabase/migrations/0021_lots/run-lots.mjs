#!/usr/bin/env node
// run-lots.mjs — exécute les 59 lots 0021 (589 tuples skill_catalog) en blocs
// via PostgREST upsert, avec la service key de .env.local.
//
// Stratégie :
//   - Chaque lot contient 10 tuples (le dernier en contient moins).
//   - Les segments sont extraits par signature "('marketplace:" (jamais par
//     balancement de parenthèses — les corps markdown en contiennent).
//   - Chaque tuple est inséré individuellement via :
//       POST /rest/v1/skill_catalog?on_conflict=skill_key
//       Prefer: resolution=ignore-duplicates,return=minimal
//   - Idempotent : ON CONFLICT DO NOTHING — les re-exécutions sont sûres.
//
// Usage :
//   node run-lots.mjs               (tout, lot_000 → lot_058)
//   node run-lots.mjs 58            (dernier lot seul)
//   node run-lots.mjs 55 58         (lot_055 → lot_058)

import { readFileSync, readdirSync } from "node:fs";
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
// SERVICE_ROLE_KEY = l'alias local du secret service_role (mêmes valeur que
// SUPABASE_SECRET_KEY côté Supabase/CI ; Supabase refuse un secret projet
// nommé SUPABASE_*, d'où le renommage côté EF, 2026-10-06).
const SUPABASE_SECRET_KEY = envGet("SERVICE_ROLE_KEY") || envGet("SUPABASE_SECRET_KEY");
if (!SUPABASE_URL || !SUPABASE_SECRET_KEY) {
  console.error("ABORT: SUPABASE_URL / SERVICE_ROLE_KEY absents dans .env.local");
  process.exit(1);
}

// — Extraction des segments SQL bruts depuis un lot —
// Le lot est structuré :
//   INSERT INTO skill_catalog (...) VALUES
//   ('marketplace:repo/...', 'domain', 'name', '', 'obj',
//    '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:repo', '', $body$...$body$),
//   ('marketplace:...', ...)
//   ON CONFLICT (skill_key) DO NOTHING;
//
// On split sur "('marketplace:" — parts[1..N] = tuples sans le préfixe.
// Les tuples non-derniers se terminent par "," ; le dernier par le footer ON CONFLICT.
function extractSegments(sql) {
  const sig = "('marketplace:";
  const parts = sql.split(sig);
  return parts.slice(1).map((seg) => {
    let s = "('marketplace:" + seg;
    // Dernier tuple : retirer le footer ON CONFLICT
    s = s.replace(/\s*\nON CONFLICT \(skill_key\) DO NOTHING;\s*$/, "");
    // Tuples non-derniers : retirer la virgule de fin
    s = s.replace(/,\s*$/, "");
    return s;
  });
}

// — Parse les 10 champs textuels/jsonb d'un tuple SQL (approche char-by-char) —
// Le lot SQL est géré par patch-marketplace-meta.mjs : ici, les 3 jsonb
// (procedure/constraints/tools) sont '[]'::jsonb — on les parse comme "[]" (array vide).
// Les doubles quotes SQL ('') dans les champs textuels sont un-escaped.
// source/description sont ici '' (le patch les remplit depuis le frontmatter SKILL.md).
function parseFields(fieldsPart) {
  const vals = [];
  let i = 0;
  while (i < fieldsPart.length) {
    while (i < fieldsPart.length && (fieldsPart[i] === " " || fieldsPart[i] === ",")) i++;
    if (i >= fieldsPart.length) break;
    if (fieldsPart[i] !== "'") break;
    let j = i + 1;
    let val = "";
    while (j < fieldsPart.length) {
      if (fieldsPart[j] === "'") {
        if (j + 1 < fieldsPart.length && fieldsPart[j + 1] === "'") {
          val += "'";
          j += 2;
        } else {
          j++;
          break;
        }
      } else {
        val += fieldsPart[j];
        j++;
      }
    }
    let after = j;
    while (after < fieldsPart.length && fieldsPart[after] === " ") after++;
    if (fieldsPart.slice(after, after + 8) === "::jsonb") {
      vals.push(val === "[]" ? [] : JSON.parse(val));
      i = after + 8;
    } else {
      vals.push(val);
      i = j;
    }
  }
  return vals;
}

// — Parse un segment SQL brut en objet JSON —
// Format du segment (après nettoyage) :
//   ('marketplace:repo/plugin/skills/skill-name', 'domain', 'name', '', 'objective',
//    '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, 'marketplace:repo', '', $body$CONTENT$body$)
//
// 10 champs textuels : key, domain, name, trigger_, objective, proc, cons, tools, source, desc
// + 1 body (dollar-quoted, entre $body$ et $body$)
//
// Les 3 jsonb sont littéralement '[]'::jsonb — on les parse comme "[]" (array vide).
// Les doubles quotes SQL ('') dans les champs textuels sont un-escaped.
function parseSegment(segment) {
  // Le corps est $body$...$body$ : l'OUVERTURE = le premier $body$ absolu
  // (il ne se trouve jamais dans le corps lui-même), la CLÔTURE = le dernier.
  // Les 10 champs SQL (key..desc) sont entre "(" et l'ouverture.
  const openBody = segment.indexOf("$body$");
  const closeBody = segment.lastIndexOf("$body$");
  const fieldsPart = segment.slice(0, openBody).replace(/^\(/, "").replace(/,\s*$/, "");

  const vals = parseFields(fieldsPart);
  // parseFields un-escape les '' SQL : les 3 jsonb (5,6,7) sont '[]'::jsonb →
  // parseés comme "[]" (array vide). source/description ici '' — le patch
  // patch-marketplace-meta.mjs les remplit depuis le frontmatter SKILL.md.
  return {
    skill_key: vals[0] ?? "",
    domain: vals[1] ?? "",
    name: vals[2] ?? "",
    trigger_: vals[3] ?? "",
    objective: vals[4] ?? "",
    procedure: JSON.parse(vals[5] ?? "[]"),
    constraints: JSON.parse(vals[6] ?? "[]"),
    tools: JSON.parse(vals[7] ?? "[]"),
    source: vals[8] ?? "",
    description: vals[9] ?? "",
    body: segment.slice(openBody + 6, closeBody),
  };
}

// — Filtre optionnel : node run-lots.mjs [debut] [fin] —
const [fromArg, toArg] = process.argv.slice(2);
const lots = readdirSync(__dirname)
  .filter((f) => /^lot_\d{3}\.sql$/.test(f))
  .sort();
const from = fromArg ? parseInt(fromArg, 10) : 0;
const to = toArg ? parseInt(toArg, 10) : lots.length - 1;
const selected = lots.filter((f) => {
  const n = parseInt(f.match(/\d+/)[0], 10);
  return n >= from && n <= to;
});
console.log(
  "Lots à exécuter:", selected.length,
  "(lot_" + String(from).padStart(3, "0") + ".sql → lot_" + String(to).padStart(3, "0") + ".sql)"
);

const base = SUPABASE_URL + "/rest/v1/skill_catalog";
const headers = {
  apikey: SUPABASE_SECRET_KEY,
  Authorization: "Bearer " + SUPABASE_SECRET_KEY,
  "Content-Type": "application/json",
  Prefer: "resolution=ignore-duplicates,return=minimal",
};

let totalOk = 0;
let totalFail = 0;
const chunkFailures = [];

for (const file of selected) {
  const sql = readFileSync(path.join(__dirname, file), "utf8");
  const segments = extractSegments(sql);
  let lotOk = 0;
  let lotFail = 0;
  for (const seg of segments) {
    try {
      const row = parseSegment(seg);
      const res = await fetch(base + "?on_conflict=skill_key", {
        method: "POST",
        headers,
        body: JSON.stringify(row),
        signal: AbortSignal.timeout(30_000),
      });
      if (res.ok || res.status === 409) {
        lotOk++;
      } else {
        const text = await res.text();
        lotFail++;
        chunkFailures.push({
          file,
          key: row.skill_key,
          status: res.status,
          text: text.slice(0, 150),
        });
      }
    } catch (e) {
      lotFail++;
      chunkFailures.push({ file, error: e.message, segmentHead: seg.slice(0, 80) });
    }
  }
  totalOk += lotOk;
  totalFail += lotFail;
  console.log(
    "[" + (lotFail === 0 ? "OK" : "!!") + "] " + file.padEnd(12) +
    " " + lotOk + "/" + segments.length +
    (lotFail > 0 ? "  (fail: " + lotFail + ")" : "")
  );
}

console.log("\n--- RÉSUMÉ ---");
console.log("Tuples OK:", totalOk, "/ Fail:", totalFail, "/ Total attendu:", 589);
if (chunkFailures.length > 0) {
  for (const f of chunkFailures.slice(0, 10)) {
    console.log(
      "  " + f.file + " [" + (f.key ?? f.segmentHead ?? "?") + "] → " +
      (f.error ?? "HTTP " + f.status + " " + (f.text ?? ""))
    );
  }
  console.log("Relancer la plage manquante (idempotent: ON CONFLICT DO NOTHING)");
}

// — Vérification finale (counts globaux via PostgREST HEAD) —
try {
  const checkRes = await fetch(
    SUPABASE_URL + "/rest/v1/skill_catalog?select=skill_key",
    {
      method: "HEAD",
      headers: {
        apikey: SUPABASE_SECRET_KEY,
        Authorization: "Bearer " + SUPABASE_SECRET_KEY,
        Prefer: "count=exact",
      },
    }
  );
  const contentRange = checkRes.headers.get("content-range") ?? "?";
  console.log("skill_catalog live (content-range):", contentRange);
} catch (e) {
  console.log("Vérification des counts impossible:", e.message);
}
