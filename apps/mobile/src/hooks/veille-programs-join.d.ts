/**
 * veille-programs-join.d.ts (discovery-vault plan 2026-10-10, Lot 4).
 *
 * La surface TypeScript du module de join PUR `veille-programs-join.js` :
 * les 2 fonctions exportées + le type `VeilleProgram`. Le `.js` est
 * le module runtime (chargé par le test `node:test` et par le hook
 * `use-veille-programs.ts`) ; ce `.d.ts` porte les types qu'il n'a
 * pas (plain-JS, pas de types inline) — le consommateur TypeScript
 * y va par l'import `from './veille-programs-join'` (le TS
 * `moduleResolution` bundler résout le `.d.ts` avant le `.js`).
 */
import type { Automation, VeilleVault, VaultRunManifest } from '@aurora/domain';

/** What one Discovery card renders (the veille program + its latest vault). */
export interface VeilleProgram {
  /** the automation that drives the program (id + name + subtitle). */
  automation: Automation;
  /** the last run's vault manifest (null when the program has no run yet). */
  lastRun: VaultRunManifest | null;
  /** the "ce jour" delta vs the previous run (0 when no previous run). */
  delta: number;
  /** the last run's verdict relevance (0..1, null when no run yet). */
  relevance: number | null;
  /** the total accumulated sources across all runs (the vault SSoT count). */
  totalSources: number;
  /** the whole vault (the SSoT document the card can open). */
  vault: VeilleVault | null;
}

/**
 * Filter the veille programs: the card shows only the active research
 * automations (`jobKind === 'research'` AND `enabled`). The single
 * writer of the `automations` table is the Integrations module
 * (AD-7); this is the read-side projection the card renders.
 */
export function selectResearchPrograms(automations: Automation[]): Automation[];

/**
 * Join one automation with its latest vault run + delta. The vault is
 * looked up by `domaine = automation.id` (V1 key: the research handler
 * writes the program's vault under the automation id when no explicit
 * `vaultDomaine` is in the job payload).
 *
 * Bounds:
 *  - no vault / no runs → `lastRun = null`, `relevance = null`,
 *    `totalSources = 0`, `delta = 0` (the card shows "En attente du
 *    1er run" — an honest empty state, never a fake verdict).
 *  - negative delta (the run has fewer new sources than the previous —
 *    consolidation, no novelty) → clamped to 0 (the "ce jour" of the
 *    card never says "less than yesterday").
 */
export function buildVeilleProgram(
  automation: Automation,
  vaults: VeilleVault[],
): VeilleProgram;
