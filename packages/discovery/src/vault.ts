/**
 * Discovery module — the vault synthesis logic (Lot 2, discovery-vault plan
 * 2026-10-10).
 *
 * Pure builders: `VAULT.md` (the evolving single document) + the
 * append-only `runs` manifest + SHA-256 hash + the 6 deterministic
 * verbs (V1 heuristic — LLM verb-choice = backlog). The `research`
 * job handler (jobs.ts) is the SOLE writer (AD-7); this module only
 * computes the next vault state from the previous + the new run.
 */
import type {
  VeilleVault,
  VaultRunManifest,
  VaultVerbe,
} from '@aurora/domain';

/** The stable VAULT.md sections (Yumi's structure). */
export const VAULT_SECTIONS = [
  'Ce que je sais',
  'Ce qui a changé',
  'Questions ouvertes',
  'Historique de runs',
  'Sources (liens + date + crédibilité)',
] as const;

/**
 * Deterministic verb decision (V1 heuristic, AD-7: the run decides, not
 * the chat agent). Input: the PREVIOUS vault state + the NEW run's
 * findings. Output: the verb + the section it touches.
 *
 * Heuristics:
 *  - new sources (run.newSources > 0, section "Ce que je sais" unchanged
 *    since the last run) → `ajouter`
 *  - section unchanged since N runs (N ≥ 3) → `consolider`
 *  - a previously-"Ce que je sais" entry is now re-confirmed by a new
 *    source → `appuier`
 *  - a previously-"Questions ouvertes" entry is answered → `ameliorer`
 *  - two entries now contradict → `comparer`
 *  - a previously-"Ce que je sais" entry is superseded → `supprimer`
 *
 * In V1 the verb is `ajouter` by default (the common case: a new run
 * adds sources). The heuristic refinement (consolidation / comparison)
 * requires the LLM = backlog.
 */
export function decideVerbe(
  prevVault: VeilleVault | null,
  run: VaultRunManifest,
): { verbe: VaultVerbe; section: string; note?: string } {
  // No previous vault → first run, always `ajouter` (bootstrap).
  if (prevVault === null || prevVault.runs.length === 0) {
    return {
      verbe: 'ajouter',
      section: 'Ce que je sais',
      note: `Premier run — bootstrap du vault (${run.domaine}).`,
    };
  }
  // The previous run also added sources → this run adds too.
  if (run.newSources > 0) {
    return {
      verbe: 'ajouter',
      section: 'Ce que je sais',
      note: `+${run.newSources} nouvelle(s) source(s) (total ${run.totalSources}).`,
    };
  }
  // No new sources: check whether "Ce que je sais" has been unchanged
  // for ≥ 3 consecutive runs → `consolider` (stabilisation).
  const recent = prevVault.runs.slice(-4);
  const unchangedCount = recent.filter((r) => r.newSources === 0).length;
  if (unchangedCount >= 3) {
    return {
      verbe: 'consolider',
      section: 'Ce que je sais',
      note: `Section stable depuis ${unchangedCount} runs — consolidation.`,
    };
  }
  // Default: no new sources, section still evolving → `appuier`
  // (re-confirm the existing knowledge, no new material).
  return {
    verbe: 'appuier',
    section: 'Ce que je sais',
    note: `Aucune nouvelle source — reconfirmation des connaissances existantes.`,
  };
}

/**
 * Build the VAULT.md content for the next vault state. Pure: same input
 * → same output. The sections are stable (Yumi's structure); the content
 * evolves per run (append-only for "Historique de runs"; "Ce que je
 * sais" / "Ce qui a changé" are updated in place).
 *
 * The "Ce que je sais" body is carried forward from the previous vault
 * (the evolving SSoT) — split on the stable `## ` section header, keep
 * the first section's body verbatim, append this run's line.
 */
export function buildVaultMd(
  prev: VeilleVault | null,
  run: VaultRunManifest,
  decision: { verbe: VaultVerbe; section: string; note?: string },
): string {
  const lines: string[] = [];
  lines.push(`# VAULT — ${run.domaine}`);
  lines.push('');
  lines.push('## Ce que je sais');
  if (prev !== null && prev.vaultMd !== '') {
    // Carry forward the "Ce que je sais" body from the previous vault.
    // Split on `## ` headers; the first header is "Ce que je sais".
    const sections = prev.vaultMd.split(/(?=^## )/m);
    const knowsBody = sections.find((s) => s.startsWith('## Ce que je sais'));
    if (knowsBody !== undefined) {
      const body = knowsBody.replace(/^## Ce que je sais\s*\n?/, '').trim();
      if (body !== '') lines.push(body);
    }
  }
  lines.push(`- (run ${run.id}, ${run.date}) ${decision.note ?? decision.verbe}`);
  lines.push('');
  lines.push('## Ce qui a changé');
  lines.push(`- (run ${run.id}) ${decision.verbe} — ${decision.section}`);
  lines.push('');
  lines.push('## Questions ouvertes');
  lines.push('(à compléter par le run suivant)');
  lines.push('');
  lines.push('## Historique de runs');
  const runs = prev !== null ? [...prev.runs, run] : [run];
  for (const r of runs) {
    lines.push(`- ${r.date} — ${r.newSources} nouvelle(s), total ${r.totalSources}`);
  }
  lines.push('');
  lines.push('## Sources (liens + date + crédibilité)');
  lines.push(`(cumul ${run.totalSources} sources au ${run.date})`);
  return lines.join('\n');
}

/**
 * Build the run's rapport.md (append-only, stored in
 * runs/YYYY-MM-DD/). Pure.
 */
export function buildRapportMd(run: VaultRunManifest): string {
  const lines: string[] = [];
  lines.push(`# Rapport du run ${run.date}`);
  lines.push('');
  lines.push(`- Domaine : ${run.domaine}`);
  lines.push(`- Date : ${run.date}`);
  lines.push(`- Relevance : ${run.relevance.toFixed(2)}`);
  lines.push(`- Nouvelles sources : ${run.newSources}`);
  lines.push(`- Total sources : ${run.totalSources}`);
  lines.push(`- Sections touchées : ${run.sectionsTouched.join(', ') || '(aucune)'}`);
  lines.push('');
  lines.push('## Mutations');
  for (const m of run.mutations) {
    lines.push(`- \`${m.verbe}\` — ${m.section}${m.note ? ` — ${m.note}` : ''}`);
  }
  lines.push('');
  lines.push('## Assets');
  for (const a of run.assets ?? []) {
    lines.push(`- !(${a})`);
  }
  return lines.join('\n');
}

/**
 * SHA-256 hash of the vault content (hex). Pure. Used for integrity
 * check (hash ≠ manifest = corrupted, the Lot 4 "error" UX state).
 *
 * Uses Node's built-in `node:crypto` (the module runs in the EF + the
 * node:test harness; browser-side callers would use a different
 * implementation — this module is server-only, AD-3).
 */
export async function computeVaultHash(content: string): Promise<string> {
  const { createHash } = await import('node:crypto');
  return createHash('sha256').update(content, 'utf8').digest('hex');
}

/**
 * Append a run to the vault (append-only: the manifest grows, the VAULT.md
 * evolves in place). Returns the next vault state. Pure.
 *
 * AD-7: this is the ONLY function that mutates the vault state — the
 * `research` job handler calls it, then `VaultStore.write` persists.
 *
 * `userId` is passed explicitly (the handler knows it); `prev` may be
 * null (first run for this user+domain) — in that case the vault's id
 * is seeded by the caller's `newVaultId` (a ULID from the job), and
 * `createdAt` = the run's timestamp.
 */
export function appendRun(
  prev: VeilleVault | null,
  run: VaultRunManifest,
  vaultMd: string,
  hash: string,
  userId: string,
  newVaultId: string,
): VeilleVault {
  const now = run.at;
  return {
    id: prev?.id ?? newVaultId,
    userId,
    domaine: run.domaine,
    vaultMd,
    vaultHash: hash,
    runs: prev !== null ? [...prev.runs, run] : [run],
    storagePrefix: prev?.storagePrefix,
    createdAt: prev?.createdAt ?? now,
    updatedAt: now,
  };
}
