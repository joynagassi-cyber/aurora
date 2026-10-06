// patch-marketplace-meta.mjs
// Remplit les champs source + description des 589 lignes marketplace dans skill_catalog,
// en lisant les SKILL.md curés dans anthropic-skills/.
//
// Pour chaque ligne du catalogue dont skill_key commence par 'marketplace:', on dérive :
//   source      = "marketplace:" + le 1er segment du skill_key (le repo)
//   description = le champ `description:` du frontmatter du SKILL.md correspondant
//
// On écrit via POSTgREST upsert (Prefer: resolution=merge-duplicates) :
//   PATCH sur source + description uniquement (les autres champs restent intacts).
//
// Idempotent : relançable sans effet de bord.

import { readFileSync, readdirSync, statSync } from "node:fs";
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
const SUPABASE_SECRET_KEY = envGet("SUPABASE_SECRET_KEY");
if (!SUPABASE_URL || !SUPABASE_SECRET_KEY) {
  console.error("ABORT: SUPABASE_URL / SUPABASE_SECRET_KEY absents dans .env.local");
  process.exit(1);
}

const SKILLS_ROOT = path.join(REPO, "anthropic-skills");

// — Construire l'index SKILL.md relatifs → chemin —
// Le skill_key a la forme 'marketplace:<relaPath>/SKILL.md' où relaPath est
// l'index relatif dans anthropic-skills/ (ex: claude-for-financial-advisors/claude-for-...).
//
// Convention du seed : skill_key = 'marketplace:' + (chemin du dossier SKILL.md relatif
// à anthropic-skills/, sans le .md final).
function walk(dir, out = []) {
  for (const entry of readdirSync(dir)) {
    const full = path.join(dir, entry);
    const st = statSync(full);
    if (st.isDirectory()) walk(full, out);
    else if (entry === "SKILL.md") out.push(full);
  }
  return out;
}

const allSkillFiles = walk(SKILLS_ROOT);
const index = new Map(); // skillKey (sans préfixe 'marketplace:') → { source, description, relPath }
for (const f of allSkillFiles) {
  const rel = path.relative(SKILLS_ROOT, f).replace(/\\/g, "/"); // ex: claude-for-legal/.../alts-brief/SKILL.md
  // Le skill_key correspond au chemin du DOSSIER (ex: .../skills/alts-brief), pas au fichier .md
  const key = rel.replace(/\/SKILL\.md$/, "");
  // source = 'marketplace:' + 1er segment (repo)
  const repo = rel.split(/[\\/]/)[0];
  const source = "marketplace:" + repo;

  // Extraire description du frontmatter (tolère CRLF)
  const content = readFileSync(f, "utf8").replace(/\r\n/g, "\n");
  const fmMatch = content.match(/^---\n([\s\S]*?)\n---/);
  let description = "";
  if (fmMatch) {
    // Le frontmatter peut avoir description sur 1 ou plusieurs lignes
    const lines = fmMatch[1].split("\n");
    let inDesc = false;
    const descParts = [];
    for (const line of lines) {
      if (/^description:\s*/.test(line)) {
        inDesc = true;
        const rest = line.replace(/^description:\s*/, "");
        if (rest.length > 0) descParts.push(rest);
        continue;
      }
      if (inDesc) {
        // Continuation line (indented or same-level but not a new key)
        if (/^\s/.test(line) && !/^description:/.test(line)) {
          descParts.push(line.trim());
          continue;
        }
        // New key at column 0 → fin de description
        break;
      }
    }
    description = descParts.join(" ").trim();
  }

  index.set(key, { source, description, relPath: rel });
}

console.log(`Index : ${index.size} SKILL.md`);

// — Charger le catalogue live et repérer les lignes marketplace manquantes —
async function listMarketplaceRows() {
  const q = `${SUPABASE_URL}/rest/v1/skill_catalog?select=skill_key,source,description&skill_key=like.${encodeURIComponent("marketplace:%")}`;
  const res = await fetch(q, {
    headers: {
      apikey: SUPABASE_SECRET_KEY,
      Authorization: "Bearer " + SUPABASE_SECRET_KEY,
    },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error("listMarketplaceRows: HTTP " + res.status + " " + text.slice(0, 200));
  }
  const rows = await res.json();
  return rows.filter((r) => r.skill_key.startsWith("marketplace:"));
}

const rows = await listMarketplaceRows();
console.log(`Lignes marketplace à patcher : ${rows.length}`);

let patched = 0, noIndex = 0, alreadyOk = 0;
const baseUrl = `${SUPABASE_URL}/rest/v1/skill_catalog`;

for (const row of rows) {
  const keyNoPrefix = row.skill_key.replace(/^marketplace:/, "");
  const meta = index.get(keyNoPrefix);
  if (!meta) {
    noIndex++;
    continue;
  }
  const targetSource = meta.source;
  const targetDesc = meta.description;

  // Si déjà correct, on ne requête pas
  if (row.source === targetSource && row.description === targetDesc) {
    alreadyOk++;
    continue;
  }

  // PATCH via PostgREST (méthode PATCH = merge propre, ne viole pas les NOT NULL)
  const payload = {
    source: targetSource,
    description: targetDesc,
  };
  const res = await fetch(`${baseUrl}?skill_key=eq.${encodeURIComponent(row.skill_key)}`, {
    method: "PATCH",
    headers: {
      apikey: SUPABASE_SECRET_KEY,
      Authorization: "Bearer " + SUPABASE_SECRET_KEY,
      "Content-Type": "application/json",
      Prefer: "return=minimal",
    },
    body: JSON.stringify(payload),
  });

  if (res.status === 200 || res.status === 204) {
    patched++;
  } else {
    const text = await res.text();
    console.error(`PATCH FAIL [${res.status}] ${row.skill_key}: ${text.slice(0, 150)}`);
  }

  // Throttle léger pour éviter les 429
  await new Promise((r) => setTimeout(r, 15));
}

console.log("\n--- RÉSULTAT ---");
console.log(`Patcher (upsert) : ${patched}`);
console.log(`Déjà OK          : ${alreadyOk}`);
console.log(`Sans index local : ${noIndex}`);
console.log(`Total            : ${rows.length}`);
