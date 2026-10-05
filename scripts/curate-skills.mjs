#!/usr/bin/env node
// scripts/curate-skills.mjs
//
// Construit anthropic-skills/ (curé, git-tracked) à partir de
// third-party/anthropic/ (bruts, gitignored).
//
// Conserve seulement : SKILL.md + references/*.md|yaml|yml
// Exclut : .git/, .claude-plugin/, .mcp.json, hooks/, agents/, logs/, binaires,
//          et les skill-setup (quickstarts .claude/skills/*).
//
// Usage : node scripts/curate-skills.mjs
// (Le .mjs évite le flag --experimental-strip-types ; aucun TS à compiler.)

import { cpSync, mkdirSync, readdirSync, statSync, rmSync, existsSync } from "node:fs";
import { join, dirname, relative, basename } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = join(__dirname, "..");
const RAW = join(REPO_ROOT, "third-party", "anthropic");
const CUR = join(REPO_ROOT, "anthropic-skills");

// On ne descend que dans les vrais contenus ; on saute l'infra non-contenu.
// (On conserve volontairement .claude/skills/ : c'est du contenu de skill, cf.
//  décision utilisateur "on prend tout".)
const EXCLUDED_DIRS = new Set([".git", "node_modules", ".claude-plugin"]);
const EXCLUDED_EXTENSIONS = new Set([
  ".ttf", ".woff", ".woff2", ".png", ".jpg", ".jpeg", ".gif", ".ico",
  ".pdf", ".mp4", ".wav", ".ogg", ".mp3", ".bin", ".wasm", ".zip",
]);

function listSkillMds(dir, out = []) {
  if (!existsSync(dir)) return out;
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    if (EXCLUDED_DIRS.has(e.name)) continue;
    const full = join(dir, e.name);
    if (e.isDirectory()) {
      listSkillMds(full, out);
    } else if (e.name === "SKILL.md") {
      out.push(full);
    }
  }
  return out;
}

rmSync(CUR, { recursive: true, force: true });
mkdirSync(CUR, { recursive: true });

const skillFiles = listSkillMds(RAW);
console.log(`SKILL.md trouvés dans ${RAW} : ${skillFiles.length}`);

let kept = 0;
let excluded = 0;
const perRepo = {};

for (const file of skillFiles) {
  const rel = relative(RAW, file);
  const parts = rel.split(/[/\\]/);
  const repo = parts[0];

  // Décision utilisateur (2026-10-04) : on prend TOUT, même le coding pur.
  // Plus aucune exclusion de repo ni de skill — seulement l'infra non-contenu
  // (exclue par EXCLUDED_DIRS ci-dessus).
  // Structure de destination : anthropic-skills/<repo>/<chemin-relatif-sans-SKILL.md>
  const destSkillDir = dirname(rel);
  const destDir = join(CUR, repo, destSkillDir);
  mkdirSync(destDir, { recursive: true });
  cpSync(file, join(destDir, "SKILL.md"));

  // Copier references si présent
  const refSrc = join(dirname(file), "references");
  if (existsSync(refSrc) && statSync(refSrc).isDirectory()) {
    const refDest = join(destDir, "references");
    mkdirSync(refDest, { recursive: true });
    for (const f of readdirSync(refSrc, { withFileTypes: true })) {
      const ext = (basename(f.name).split(".").pop() || "").toLowerCase();
      if (!["md", "yaml", "yml"].includes(ext)) continue;
      cpSync(join(refSrc, f.name), join(refDest, f.name));
    }
  }

  kept++;
  perRepo[repo] = (perRepo[repo] ?? 0) + 1;
}

console.log(`\nCurés : ${kept} skills (aucune exclusion — décision "prendre tout")`);
console.log(`Récap par dépôt :`);
for (const [repo, count] of Object.entries(perRepo).sort((a, b) => b[1] - a[1])) {
  console.log(`  ${String(count).padStart(4)}  ${repo}`);
}
const total = (await import("node:fs/promises")).stat(CUR).then(s => s.isDirectory() ? null : null);
