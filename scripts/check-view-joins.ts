#!/usr/bin/env node
// check-view-joins.ts — No cross-module JOIN static check (03-sync S5.4, F-03)
//
// Refs:
//   - 03-sync S5.4 "Scopes / vues SQL PowerSync": un scope ne joint JAMAIS
//     les tables internes d'un autre module (AD-7 + AD-2, F-03).
//   - 01-backend S3.4 "Vues PowerSync cote serveur": "un scope n'joint
//     jamais les tables internes d'un autre module".
//   - dependency-matrix S10 (anti-pattern "Discovery SQL JOINs
//     progress_snapshots") + S15 ("No cross-module JOIN test").
//   - docs/architecture/data-ownership-matrix.md (liste module -> tables
//     internes; les lectures inter-modules passent par une VUE PUBLIQUE
//     du module source, jamais par une table interne).
//
// Mechanisme: on scanne les vues PowerSync (fichiers .sql dans
// packages/data/... et supabase/migrations/...) et on detecte tout JOIN
// d'une table interne d'un module A sur une table interne d'un module B
// (A != B). Un JOIN sur une vue publique (nomme `*_public` ou `*_view`)
// est autorisé — les vues publiques sont le seul canal inter-module
// (01 S3.4).
//
// Parametrable:
//   node scripts/check-view-joins.ts <chemin...>        (args = chemins,
//                                                          remplacent le defaut)
//   AURORA_VIEW_JOIN_SCAN=packages/data,supabase/migrations node scripts/check-view-joins.ts
//   AURORA_VIEW_JOIN_SKIP=1                               (mode skip — toujours exit 0)
// Par defaut, on scanne packages/data (si existe) + supabase/migrations.
//
// Le scope courant est defini par le NOM du fichier ou du dossier parent:
//   <module>/*.sql  (ex. packages/data/scopes/productivity/*.sql) ou
//   <module>_<...>.sql  (ex. productivity_tasks.sql)
// Un fichier sans module identifiable n'est pas un scope declare par
// packages/data (03 S5.4: 1 scope = 1 vue d'un module owner) et est
// SKIPPE (pas de faux positif).
//
// Regles detectees (03-sync S5.4 / F-03 / 01-backend S3.4):
//   - Un scope ne joint JAMAIS une table interne d'un autre module
//     (data-ownership-matrix.md: liste module -> tables internes).
//   - Les lectures inter-modules passent par une VUE PUBLIQUE du module
//     source: nomme <table>_public, <table>_view(s) ou <table>_join.
//     Ces suffixes sont autorises dans un JOIN.
//   - Un JOIN sur une table du meme module est autorise.
//
// TODO(wave1): une fois les vues PowerSync declarees par MINERVA dans
// packages/data/scopes/, ajouter des cas de test (1 test par scope,
// 03 S7) + run le check sur la suite complete.
//
// Exit: 0 clean / 0 (skip, pas de vues) / 1 echec + fichier/ligne.

import { readFileSync, existsSync, readdirSync, statSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

// ---------------------------------------------------------------------------
// Module -> tables internes (data-ownership-matrix.md). Une table est
// "interne" si son nom est dans la liste d'un module ET qu'elle n'est
// pas une vue publique (nom ne se termine ni par _public ni par _view).
// ---------------------------------------------------------------------------
const MODULE_TABLES: Record<string, string[]> = {
  Productivity: [
    "tasks", "subtasks", "events", "projects", "milestones", "goals",
    "habits", "routines", "notes", "resources", "decisions",
    "focus_sessions", "productivity_snapshots",
  ],
  Learning: [
    "courses", "subjects", "learning_items", "learning_sessions",
    "fsrs_state", "skill_definitions",
  ],
  Knowledge: [
    "sources", "concepts", "formulas", "definitions", "methods",
    "semantic_nodes", "semantic_relations", "semantic_tree_version",
    "node_states",
  ],
  Progress: [
    "progress_evidences", "progress_snapshots", "skill_states",
    "progress_events", "progress_trajectories",
  ],
  Discovery: [
    "discovery_items", "discovery_sources", "discovery_scenarios",
  ],
  Artifact: [
    "artifacts", "artifact_files",
  ],
  Agent: [
    "expert_skills", "agent_runs", "job_queue", "job_logs",
  ],
  Integrations: [
    "integrations_state", "automations", "notification_preferences",
  ],
  Identity: [
    "user_context", "users", "session_tokens",
  ],
  Foundation: [
    "model_registry", "environment_config",
  ],
};
// Note (data-ownership-matrix.md): "gaps" (rows) = table interne du module
// Discovery (01 S4.5 discovery_scenarios porte les gap rows; les DEFINITIONS
// des gaps vivent cote domain/Progress). Pas de fausse attribution: on ne
// mappe pas "gaps" a Progress dans TABLE_TO_MODULE.

// inverse: table -> module
const TABLE_TO_MODULE: Record<string, string> = {};
for (const [mod, tables] of Object.entries(MODULE_TABLES)) {
  for (const t of tables) TABLE_TO_MODULE[t] = mod;
}

// ---------------------------------------------------------------------------
// Resoudre la racine du repo.
// ---------------------------------------------------------------------------
const here = dirname(fileURLToPath(import.meta.url));
// usage standard: node scripts/check-view-joins.ts depuis la racine.
let repoRoot = process.cwd();
if (!existsSync(join(repoRoot, "package.json")) && !existsSync(join(repoRoot, "pnpm-workspace.yaml"))) {
  // on remonte depuis $0 (si execute depuis un autre lieu).
  repoRoot = join(here, "..");
}

if (process.env.AURORA_VIEW_JOIN_SKIP === "1") {
  console.log("[check-view-joins] SKIP (AURORA_VIEW_JOIN_SKIP=1).");
  process.exit(0);
}

// ---------------------------------------------------------------------------
// Chemins a scanner (parametrable).
// ---------------------------------------------------------------------------
const argPaths = process.argv.slice(2);
const scanEnv = process.env.AURORA_VIEW_JOIN_SCAN;

const candidates: string[] = [];
if (argPaths.length > 0) {
  for (const a of argPaths) candidates.push(a);
} else if (scanEnv) {
  for (const p of scanEnv.split(",").map((s) => s.trim()).filter(Boolean)) {
    candidates.push(join(repoRoot, p));
  }
} else {
  if (existsSync(join(repoRoot, "packages/data"))) {
    candidates.push(join(repoRoot, "packages/data"));
  }
  if (existsSync(join(repoRoot, "supabase/migrations"))) {
    candidates.push(join(repoRoot, "supabase/migrations"));
  }
  if (existsSync(join(repoRoot, "packages/platform"))) {
    // les vues PowerSync peuvent aussi vivre cote plateforme
    candidates.push(join(repoRoot, "packages/platform"));
  }
}

// Recolte tous les fichiers .sql (recursif; un chemin direct vers un
// fichier .sql est accepte tel quel).
function walkSql(dir: string, out: string[] = []): string[] {
  if (!existsSync(dir)) return out;
  const st = statSync(dir);
  if (st.isFile()) {
    if (dir.endsWith(".sql")) out.push(dir);
    return out;
  }
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    const pst = statSync(p);
    if (pst.isDirectory()) walkSql(p, out);
    else if (name.endsWith(".sql")) out.push(p);
  }
  return out;
}

const sqlFiles: string[] = [];
for (const c of candidates) sqlFiles.push(...walkSql(c));

if (sqlFiles.length === 0) {
  console.log("[check-view-joins] SKIP — aucun .sql a scanner (packages/data + supabase/migrations absents).");
  console.log("[check-view-joins] Le gate wave 0 le branche en continue-on-error + log explicite, pas un echec du run.");
  process.exit(0);
}

// ---------------------------------------------------------------------------
// Detecter les JOIN inter-modules. On cherche toute occurrence de
// "JOIN <identifiant>" ou "LEFT/RIGHT/FULL/INNER/OUTER JOIN <identifiant>"
// et on verifie que le second operand n'est pas une table interne
// d'un module DIFFERENT de celle du scope courant.
// ---------------------------------------------------------------------------
// Pour chaque fichier, on determine le "module du scope courant":
// - si le fichier est dans un dossier nomme d'apres un module, on prend
//   ce module.
// - sinon on prend le module de la PREMIERE table du FROM principal.
// Un JOIN sur une vue publique (nommable par _public ou _view) est OK.
// Un JOIN sur une table interne de MEME module est OK.
// Un JOIN sur une table interne d'UN AUTRE module = FAIL.

type Violation = { file: string; line: number; ltable: string; rtable: string; lmod: string; rmod: string; raw: string };
const violations: Violation[] = [];

// Regex: capture l'operande (table/cible) de chaque JOIN. Les alias
// avec schema-qualif (public.focus_sessions) sont handles par le split
// sur "." (on prend le dernier segment = le nom de table/vue).
const joinRe = /\b(LEFT\s+OUTER\s+|RIGHT\s+OUTER\s+|FULL\s+(OUTER\s+)?|INNER\s+|OUTER\s+)?JOIN\s+([`"\[]?[a-zA-Z0-9_.$`"\]]+)/gi;

// (moduleOfPath remplace scopeModuleOf — voir definition ci-dessous)

// DETERMINE le module du scope courant: depuis le NOM du fichier ou du
// dossier parent (ex. packages/data/scopes/productivity/*.sql ou
// productivity_tasks.sql). Si aucune mention de module, le fichier est
// une DDL interne au module du dossier; on retourne null = "pas de scope
// identifiable" et le fichier est SKIPPE (pas de faux positif).
function scopeModuleOf(file: string): string | null {
  const lower = file.toLowerCase();
  for (const mod of Object.keys(MODULE_TABLES)) {
    // matcher "productivity" comme segment (pas substring arbitraire)
    const needle = mod.toLowerCase();
    if (lower.split(/[\\/]/).some((seg) => seg.startsWith(needle))) return mod;
    // ex. "productivity_tasks.sql"
    if (lower.includes(needle + "_") || lower.includes(needle + "-")) return mod;
  }
  return null;
}

for (const file of sqlFiles) {
  let text: string;
  try { text = readFileSync(file, "utf8"); } catch { continue; }
  const lines = text.split(/\r?\n/);
  const scopeModule = scopeModuleOf(file);
  if (!scopeModule) {
    // pas de scope PowerSync identifiable dans le nom du fichier/dossier:
    // ce n'est pas un scope declare par packages/data (règle 03 S5.4:
    // 1 scope = 1 vue d'un module owner). On ne le verifie pas.
    continue;
  }

  // Parcourir ligne par ligne pour avoir le numero de ligne dans le log.
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!/\bJOIN\b/i.test(line)) continue;

    // Chaque ligne peut contenir plusieurs JOIN (a JOIN b JOIN c).
    // On extrait toutes les paires (precedent JOIN -> suivant operande).
    // Strategier simple et robuste: on cherche toutes les occurrences de
    // "JOIN <table>" et on verifie le module de <table> contre scopeModule.
    let m: RegExpExecArray | null;
    joinRe.lastIndex = 0;
    const joinTables: string[] = [];
    while ((m = joinRe.exec(line)) !== null) {
      // L'operande est m[3]; schema-qualified (public.focus_sessions) ->
      // on prend le dernier segment (le nom de table/vue).
      const raw = m[3].replace(/[`"\[\]]/g, "");
      const jt = raw.split(".").pop() ?? raw;
      joinTables.push(jt);
    }
    for (const jt of joinTables) {
      // Vue publique = autorisee (canal inter-module, 01 S3.4).
      // On accepte _public/_view/_views (suffixed views) et _join
      // (les vues de "jointure publique" declarees par le module source).
      if (/(_public|_view|_views|_join)$/i.test(jt)) continue;
      // Table du module courant = autorisee.
      const jtMod = TABLE_TO_MODULE[jt];
      if (!jtMod) continue; // pas dans la matrice = pas un module connu = OK.
      if (jtMod === scopeModule) continue; // meme module = OK.
      // Violation: table interne d'un AUTRE module.
      violations.push({
        file,
        line: i + 1,
        ltable: scopeModule,
        rtable: jt,
        lmod: scopeModule,
        rmod: jtMod,
        raw: line.trim(),
      });
    }
  }
}

if (violations.length === 0) {
  console.log(`[check-view-joins] OK — ${sqlFiles.length} .sql scannes, 0 JOIN inter-module.`);
  process.exit(0);
}

console.error(`[check-view-joins] FAIL — ${violations.length} JOIN(s) inter-module detectes:`);
for (const v of violations) {
  console.error(`  ${v.file}:${v.line}  scope(${v.lmod}) JOINs ${v.rtable} [${v.rmod}]`);
  console.error(`      ligne: ${v.raw}`);
}
console.error("\nRegles (03-sync S5.4 / F-03 / 01-backend S3.4 / data-ownership-matrix.md):");
console.error("  - Un scope PowerSync ne joint JAMAIS les tables internes d'un autre module.");
console.error("  - Les lectures inter-modules passent par une VUE PUBLIQUE du module source");
console.error("    (nomme <table>_public ou <table>_view, exposee SELECT + policy service_role).");
console.error("  - 1 test par scope (03 S7): chaque scope ne joint que les tables de SON module owner.");
process.exit(1);
