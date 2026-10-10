/**
 * LOT 2 (discovery-vault plan 2026-10-10) — the vault synthesis logic:
 * `buildVaultMd`, `appendRun`, `decideVerbe`, `computeVaultHash` (pure
 * builders + the deterministic verb heuristic), `buildRapportMd`.
 *
 * node:test + --experimental-strip-types (no build step).
 * Run: `pnpm --filter @aurora/discovery test`
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  appendRun,
  buildRapportMd,
  buildVaultMd,
  computeVaultHash,
  decideVerbe,
} from '../src/vault.ts';
import type { VeilleVault, VaultRunManifest } from '@aurora/domain';

function makeRun(over: Partial<VaultRunManifest> & { id: string }): VaultRunManifest {
  return {
    date: '2026-10-10',
    domaine: 'structures',
    newSources: 3,
    totalSources: 3,
    relevance: 1.0,
    sectionsTouched: ['Ce que je sais'],
    mutations: [],
    at: '2026-10-10T08:00:00.000Z',
    ...over,
  };
}

/** A minimal `VeilleVault` (for the `prev` argument of the builders). */
function makeVault(runCount: number, userId = 'user1'): VeilleVault {
  const runs: VaultRunManifest[] = [];
  for (let i = 0; i < runCount; i += 1) {
    runs.push(makeRun({ id: `run-${i}`, newSources: i === 0 ? 5 : 0, totalSources: 5 }));
  }
  return {
    id: 'vault-1',
    userId,
    domaine: 'structures',
    vaultMd: '# VAULT — structures\n\n## Ce que je sais\n- (run run-0) ajouter',
    vaultHash: 'abc123',
    runs,
    createdAt: runs[0]?.at ?? '',
    updatedAt: runs.at(-1)?.at ?? '',
  };
}

test('LOT 2 decideVerbe: first run (no prev) → `ajouter` (bootstrap)', () => {
  const run = makeRun({ id: 'run-0', newSources: 2, totalSources: 2 });
  const d = decideVerbe(null, run);
  assert.equal(d.verbe, 'ajouter');
  assert.equal(d.section, 'Ce que je sais');
  assert.ok(d.note !== undefined && d.note.includes('Premier run'));
});

test('LOT 2 decideVerbe: run with newSources > 0 → `ajouter`', () => {
  const prev = makeVault(2);
  const run = makeRun({ id: 'run-2', newSources: 3, totalSources: 8 });
  const d = decideVerbe(prev, run);
  assert.equal(d.verbe, 'ajouter');
});

test('LOT 2 decideVerbe: no new sources, section stable ≥3 runs → `consolider`', () => {
  // Build a prev vault whose last 4 runs all had newSources = 0.
  const prev = makeVault(4);
  // makeVault sets runs[0].newSources=5, runs[1..3].newSources=0
  // → recent = runs[0..3], unchanged = 3 (runs 1,2,3) ≥ 3 → consolider
  const run = makeRun({ id: 'run-4', newSources: 0, totalSources: 5 });
  const d = decideVerbe(prev, run);
  assert.equal(d.verbe, 'consolider');
  assert.equal(d.section, 'Ce que je sais');
});

test('LOT 2 decideVerbe: no new sources, section still evolving → `appuier`', () => {
  const prev = makeVault(1);
  // recent = [run-0], unchanged = 0 (< 3) → appuier (default)
  const run = makeRun({ id: 'run-1', newSources: 0, totalSources: 5 });
  const d = decideVerbe(prev, run);
  assert.equal(d.verbe, 'appuier');
});

test('LOT 2 buildVaultMd: first run (no prev) → the section skeleton is produced', () => {
  const run = makeRun({ id: 'run-0', newSources: 2, totalSources: 2 });
  const d = decideVerbe(null, run);
  const md = buildVaultMd(null, run, d);
  assert.ok(md.includes('# VAULT — structures'));
  assert.ok(md.includes('## Ce que je sais'));
  assert.ok(md.includes('## Ce qui a changé'));
  assert.ok(md.includes('## Historique de runs'));
  assert.ok(md.includes('## Sources (liens + date + crédibilité)'));
  assert.ok(md.includes('(run run-0'));
});

test('LOT 2 buildVaultMd: carry forward the previous "Ce que je sais" body', () => {
  const prev = makeVault(1);
  // prev.vaultMd = "# VAULT — structures\n\n## Ce que je sais\n- (run run-0) ajouter"
  const run = makeRun({ id: 'run-1', newSources: 1, totalSources: 6 });
  const d = decideVerbe(prev, run);
  const md = buildVaultMd(prev, run, d);
  // The previous body line "- (run run-0) ajouter" must be carried forward.
  assert.ok(md.includes('- (run run-0) ajouter'), 'la section précédente est conservée');
  // AND the new run line is appended.
  assert.ok(md.includes('- (run run-1'), 'la ligne du run courant est ajoutée');
});

test('LOT 2 buildRapportMd: the run rapport carries the verb + assets', () => {
  const run = makeRun({
    id: 'run-0',
    newSources: 2,
    totalSources: 2,
    assets: ['prod/u1/discovery/structures/runs/2026-10-10/fig-00.png'],
  });
  run.mutations = [
    { verbe: 'ajouter', runId: 'run-0', section: 'Ce que je sais', note: '+2 nouvelles sources' },
  ];
  const md = buildRapportMd(run);
  assert.ok(md.includes('# Rapport du run 2026-10-10'));
  assert.ok(md.includes('Domaine : structures'));
  assert.ok(md.includes('`ajouter`'));
  assert.ok(md.includes('fig-00.png'));
});

test('LOT 2 computeVaultHash: SHA-256 is deterministic + changes with content', async () => {
  const h1 = await computeVaultHash('hello');
  const h2 = await computeVaultHash('hello');
  const h3 = await computeVaultHash('world');
  assert.equal(h1, h2, 'même contenu → même hash');
  assert.notEqual(h1, h3, 'contenu différent → hash différent');
  assert.equal(h1.length, 64, 'SHA-256 hex = 64 chars');
});

test('LOT 2 appendRun: first run (prev=null) → runs=[run], id=newVaultId', () => {
  const run = makeRun({ id: 'run-0' });
  const next = appendRun(null, run, 'md', 'hash0', 'user1', 'new-vault-id');
  assert.equal(next.id, 'new-vault-id');
  assert.equal(next.userId, 'user1');
  assert.equal(next.runs.length, 1);
  assert.equal(next.vaultMd, 'md');
  assert.equal(next.vaultHash, 'hash0');
});

test('LOT 2 appendRun: second run (prev exists) → runs grows (append-only)', () => {
  const prev = makeVault(1);
  const run = makeRun({ id: 'run-1', newSources: 1, totalSources: 6 });
  const next = appendRun(prev, run, 'md2', 'hash1', 'user1', 'ignored-id');
  assert.equal(next.id, prev.id, 'l\'id du vault est conservé (pas newVaultId)');
  assert.equal(next.runs.length, 2, 'append-only : le manifest grandit');
  assert.equal(next.vaultMd, 'md2');
  assert.equal(next.vaultHash, 'hash1');
});

test('LOT 2 appendRun: hash changes between runs (invariant du test AD-7)', async () => {
  const run0 = makeRun({ id: 'run-0', newSources: 5, totalSources: 5 });
  const md0 = buildVaultMd(null, run0, decideVerbe(null, run0));
  const hash0 = await computeVaultHash(md0);
  const v0 = appendRun(null, run0, md0, hash0, 'user1', 'vault-x');

  const run1 = makeRun({ id: 'run-1', newSources: 1, totalSources: 6 });
  const md1 = buildVaultMd(v0, run1, decideVerbe(v0, run1));
  const hash1 = await computeVaultHash(md1);
  assert.notEqual(hash0, hash1, 'le hash du vault évolue entre deux runs (le SSoT change)');
});
