#!/usr/bin/env node
// scripts/skills-seed.ts
//
// Génère la migration 0021_marketplace_skills.sql à partir de
// anthropic-skills/ (le dossier curé, git-tracked).
//
// Pour chaque SKILL.md :
//   - Parse le frontmatter YAML (name, description, argument-hint)
//   - Le corps (après la 2e `---`) devient le champ `body`
//   - skill_key = 'marketplace:<repo>/<plugin>/<skill-dir>'
//   - source    = 'marketplace:<repo>'
//   - domain    = mappingDomain(repo, pluginPath) (table de mapping ci-dessous)
//   - procedure/constraints/tools = [] (prompt-only, pas de KERNEL_TOOLS)
//
// Sortie : supabase/migrations/0021_marketplace_skills.sql
// Usage  : pnpm tsx scripts/skills-seed.ts
//          ou : node --experimental-strip-types scripts/skills-seed.ts
//
// Application en prod (règle supabase-mcp.md) : exécuter le SQL généré
// via mcp__supabase-aurora__execute_sql, bloc par bloc.

import { readFileSync, writeFileSync, readdirSync, existsSync } from "node:fs";
import { join, dirname, relative } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = join(__dirname, "..");
const CURATED = join(REPO_ROOT, "anthropic-skills");
const OUT = join(REPO_ROOT, "supabase", "migrations", "0021_marketplace_skills.sql");

// ---------------------------------------------------------------------------
// Mapping repo/plugin → domaine Aurora
// ---------------------------------------------------------------------------

// Ordre manuel d'affichage (à figer dans le script + dans l'UI)
export const DOMAIN_ORDER = [
  "science",
  "legal",
  "finance",
  "healthcare",
  "students",
  "productivity",
  "business",
  "marketing",
  "documents",
  "research",
  "creative",
  "design",
  "social",
  "coding",
] as const;

export const DOMAIN_LABELS: Record<string, string> = {
  science: "Scientifique",
  legal: "Juridique",
  finance: "Finance",
  healthcare: "Santé",
  students: "Étudiants & Apprentissage",
  productivity: "Productivité",
  business: "Business & Ops",
  marketing: "Marketing & Productivité",
  documents: "Documents & Présentations",
  research: "Recherche",
  creative: "Création",
  design: "Design & UX",
  social: "Réseau & Social",
  coding: "Développement",
};

// Mapping par (repo, chemin relatif dans le repo)
function mappingDomain(repo: string, skillDir: string): string {
  const lower = skillDir.toLowerCase();

  // claude-for-legal : tout est legal, sauf law-student qui est students
  if (repo === "claude-for-legal") {
    if (skillDir.startsWith("law-student")) return "students";
    return "legal";
  }

  // k12-teacher-skills : pédagogie = students
  if (repo === "k12-teacher-skills") return "students";

  // financial-services + claude-for-financial-advisors = finance
  if (repo === "financial-services") return "finance";
  if (repo === "claude-for-financial-advisors") return "finance";

  // life-sciences = science
  if (repo === "life-sciences") return "science";

  // healthcare = healthcare
  if (repo === "healthcare") return "healthcare";

  // commerce-agents = business (e-commerce)
  if (repo === "commerce-agents") return "business";

  // launch-your-agent = productivity (outillage d'agent)
  if (repo === "launch-your-agent") return "productivity";

  // oncall-kit = productivity (support/ops)
  if (repo === "oncall-kit") return "productivity";

  // claude-quickstarts : skills de setup (first-run, verify) → coding
  if (repo === "claude-quickstarts") return "coding";

  // knowledge-work-plugins : skillDir est relatif au repo (ex. "finance/skills/audit-support")
  if (repo === "knowledge-work-plugins") {
    if (skillDir.startsWith("engineering")) return "coding";
    if (skillDir.startsWith("partner-built/zoom")) return "coding";
    if (skillDir.startsWith("partner-built/slack")) return "coding";
    if (skillDir.startsWith("partner-built")) return "business";
    if (skillDir.startsWith("design")) return "design";
    if (skillDir.startsWith("marketing")) return "marketing";
    if (skillDir.startsWith("data")) return "research";
    if (skillDir.startsWith("enterprise-search")) return "research";
    if (skillDir.startsWith("bio-research")) return "science";
    if (skillDir.startsWith("productivity")) return "productivity";
    if (skillDir.startsWith("legal")) return "legal";
    if (skillDir.startsWith("sales")) return "business";
    if (skillDir.startsWith("human-resources")) return "business";
    if (skillDir.startsWith("operations")) return "business";
    if (skillDir.startsWith("small-business")) return "business";
    if (skillDir.startsWith("customer-support")) return "business";
    if (skillDir.startsWith("product-management")) return "business";
    if (skillDir.startsWith("cowork-plugin-management")) return "productivity";
    if (skillDir.startsWith("finance")) return "finance";
    return "business"; // fallback
  }

  // anthropics/skills (le repo « Agent Skills »)
  if (repo === "skills") {
    if (skillDir === "docx" || skillDir === "pdf" || skillDir === "pptx" || skillDir === "xlsx") return "documents";
    if (skillDir === "doc-coauthoring") return "documents";
    if (skillDir === "canvas-design" || skillDir === "theme-factory" || skillDir === "slack-gif-creator" || skillDir === "algorithmic-art" || skillDir === "brand-guidelines") return "creative";
    if (skillDir === "frontend-design" || skillDir === "mcp-builder" || skillDir === "webapp-testing" || skillDir === "claude-api" || skillDir === "web-artifacts-builder") return "coding";
    if (skillDir === "skill-creator" || skillDir === "discernment-nudge") return "productivity";
    if (skillDir === "academy-guide") return "students";
    return "documents";
  }

  // claude-quickstarts : exclu (setup .claude/skills, pas de knowledge work)
  if (repo === "claude-quickstarts") return ""; // exclu

  // inconnu → business (fallback conservateur)
  return "business";
}

// ---------------------------------------------------------------------------
// Parseur de frontmatter YAML (simple, sans dépendance)
// ---------------------------------------------------------------------------

function parseSkillMd(content: string): { name: string; description: string; body: string } {
  // Le frontmatter est délimité par `---` en début et en fin
  const lines = content.split("\n");
  if (lines[0]?.trim() !== "---") {
    return { name: "", description: "", body: content };
  }
  // Trouver la fin du frontmatter (2e ---)
  let end = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i].trim() === "---") {
      end = i;
      break;
    }
  }
  if (end === -1) {
    return { name: "", description: "", body: content };
  }
  const fmLines = lines.slice(1, end);
  const body = lines.slice(end + 1).join("\n").trim();

  // Parse simple du frontmatter : key: value (pas de nested)
  let name = "";
  let description = "";
  let inDescription = false;
  for (const line of fmLines) {
    if (inDescription) {
      if (line.startsWith(" ") || line.startsWith("\t")) {
        description += " " + line.trim();
        continue;
      } else {
        inDescription = false;
      }
    }
    const m = line.match(/^(\S+):\s*(.*)$/);
    if (m) {
      const key = m[1].trim();
      let val = m[2].trim();
      // Gérer les multi-lines (`>`)
      if (val === ">" || val === ">-") {
        inDescription = true;
        if (key === "name") name = val === ">" || val === ">-" ? "" : val;
        if (key === "description") description = "";
        continue;
      }
      // Enlever les guillemets
      if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
        val = val.slice(1, -1);
      }
      if (key === "name") name = val;
      if (key === "description") description = val;
    }
  }
  return { name, description, body };
}

// ---------------------------------------------------------------------------
// Récursion : lister tous les SKILL.md du dossier curé
// ---------------------------------------------------------------------------

function listSkillMds(dir: string): string[] {
  const out: string[] = [];
  if (!existsSync(dir)) return out;
  const entries = readdirSync(dir, { withFileTypes: true });
  for (const e of entries) {
    if (e.name === ".git" || e.name === "node_modules") continue;
    const full = join(dir, e.name);
    if (e.isDirectory()) {
      out.push(...listSkillMds(full));
    } else if (e.name === "SKILL.md") {
      out.push(full);
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// SQL escaping
// ---------------------------------------------------------------------------

// Pour le `body`, on utilise le dollar-quoting $body$...$body$ (pas $$ imbriqué,
// conformément à la règle supabase-mcp.md). Vérifier que le corps ne contient
// pas déjà `$body$` (quasi impossible).
function quoteBody(body: string): string {
  // Si le body contient déjà le délimiteur, on bascule sur un délimiteur plus
  // robuste (ne devrait jamais arriver en pratique)
  if (body.includes("$body$")) {
    return "$skill_body$" + body + "$skill_body$";
  }
  return "$body$" + body + "$body$";
}

// Pour les autres champs (name, description, ...), on escape les simples quotes
function sqlQuote(s: string): string {
  return "'" + s.replace(/'/g, "''") + "'";
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

function main() {
  if (!existsSync(CURATED)) {
    console.error(`Dossier curé introuvable : ${CURATED}`);
    console.error(`Exécuter d'abord : bash scripts/curate-skills.sh`);
    process.exit(1);
  }

  const skillFiles = listSkillMds(CURATED);
  console.log(`SKILL.md trouvés dans ${CURATED} : ${skillFiles.length}`);

  const rows: string[] = [];
  let kept = 0;
  let excluded = 0;
  const domainCounts: Record<string, number> = {};

  for (const file of skillFiles) {
    const rel = relative(CURATED, file);
    const parts = rel.split(/[/\\]/);
    if (parts.length < 3) continue; // besoin : repo + au moins 1 dir + SKILL.md
    const repo = parts[0];
    // skillDir = tout le chemin entre repo et SKILL.md (peut contenir plusieurs segments)
    const skillDir = parts.slice(1, -1).join("/");

    const domain = mappingDomain(repo, skillDir);
    if (domain === "") {
      excluded++;
      continue; // exclu (ex. weather, quickstarts)
    }

    const content = readFileSync(file, "utf-8");
    const { name, description, body } = parseSkillMd(content);

    // skill_key convention : marketplace:<repo>/<skill-dir>
    const skillKey = `marketplace:${repo}/${skillDir}`;
    const source = `marketplace:${repo}`;
    const skillName = name || skillDir.split("/").pop() || "skill";

    // objective = première phrase de la description (ou fallback)
    const objective =
      description.length > 0
        ? description.split(/[.!?\n]/)[0]
        : skillName;

    domainCounts[domain] = (domainCounts[domain] ?? 0) + 1;
    kept++;

    const row = `  (${sqlQuote(skillKey)}, ${sqlQuote(domain)}, ${sqlQuote(skillName)}, ${sqlQuote(description || "")}, ${sqlQuote(objective)}, '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, ${sqlQuote(source)}, ${sqlQuote(description || "")}, ${quoteBody(body)})`;
    rows.push(row);
  }

  console.log(`Conservés : ${kept}, exclus : ${excluded}`);
  console.log(`Par domaine :`, Object.entries(domainCounts).sort((a, b) => b[1] - a[1]));

  // Construire le SQL final
  const insertValues = rows.join(",\n");
  const sql = `-- 0021_marketplace_skills.sql
-- Généré par scripts/skills-seed.ts le ${new Date().toISOString().slice(0, 10)}
-- Source : anthropic-skills/ (curé de ${skillFiles.length} SKILL.md de third-party/anthropic/*)
-- Règle : le fichier de migration est le SSoT du schéma (règle supabase-mcp.md) ;
-- le live doit rester aligné. Application via mcp__supabase-aurora__execute_sql,
-- bloc par bloc (ALTER, CREATE INDEX, INSERT).
-- Le dollar-quoting $body$...$body$ est utilisé pour le corps markdown (pas de
-- $$ imbriqué). Pas de DROP.
--
-- Statistiques : ${kept} skills conservées, ${excluded} exclues.

ALTER TABLE skill_catalog ADD COLUMN body text;
ALTER TABLE user_skills   ADD COLUMN body text;
CREATE INDEX IF NOT EXISTS idx_skill_catalog_domain ON skill_catalog (domain);
CREATE INDEX IF NOT EXISTS idx_skill_catalog_source ON skill_catalog (source);
CREATE INDEX IF NOT EXISTS idx_skill_catalog_source ON skill_catalog (source);

INSERT INTO skill_catalog
  (skill_key, domain, name, trigger_, objective, procedure, constraints, tools, source, description, body)
VALUES
${insertValues}
ON CONFLICT (skill_key) DO NOTHING;
`;

  writeFileSync(OUT, sql, "utf-8");
  console.log(`\nMigration générée : ${OUT}`);
  console.log(`Taille : ${(sql.length / 1024).toFixed(1)} KB`);
}

main();
