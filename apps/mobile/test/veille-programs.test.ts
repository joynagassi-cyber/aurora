/**
 * veille-programs.test.ts (discovery-vault plan 2026-10-10, Lot 4).
 *
 * Contratuel node:test : le join PUR de la carte (`buildVeilleProgram`
 * + `selectResearchPrograms`) est sans React / DOM / réseau — les deux
 * miroirs PowerSync (AD-7, 03 S3.1) sont simulés par des tableaux de
 * `Automation` + `VeilleVault`. Le test importe le module pur
 * `./src/hooks/use-veille-programs.js` (le `--experimental-strip-types`
 * de `apps/mobile` résout le `.js` de l'import → `use-veille-programs.js`
 * le plain-JS module ; le hook React `use-veille-programs.ts` n'est
 * JAMAIS chargé ici — il traîne `@tanstack/react-query` +
 * `query-client.tsx` par son chemin d'imports `.tsx`).
 *
 * Run: node --experimental-strip-types --no-warnings
 *        --test apps/mobile/test/veille-programs.test.ts
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import type { Automation, VeilleVault, VaultRunManifest } from '@aurora/domain';
import {
  buildVeilleProgram,
  selectResearchPrograms,
} from '../src/hooks/veille-programs-join.js';
import type { VeilleProgram } from '../src/hooks/veille-programs-join.d.ts';

/** Minimal `Automation` research program (the card's title/subtitle). */
function makeAutomation(over: Partial<Automation> & { id: string }): Automation {
  return {
    userId: 'user1',
    name: 'Veille structures',
    trigger: 'schedule',
    jobKind: 'research',
    action: 'Eurocode 7 — dimensionnement des fondations',
    enabled: true,
    createdAt: '2026-10-10T00:00:00.000Z',
    updatedAt: '2026-10-10T00:00:00.000Z',
    ...over,
  };
}

/** A single vault run manifest (the append-only entry the card reads). */
function makeRun(
  id: string,
  newSources: number,
  totalSources: number,
  relevance: number,
): VaultRunManifest {
  return {
    id,
    date: '2026-10-10',
    domaine: id,
    newSources,
    totalSources,
    relevance,
    sectionsTouched: ['Ce que je sais'],
    mutations: [],
    at: '2026-10-10T08:00:00.000Z',
  };
}

/** A `VeilleVault` keyed by a programme (domaine = automation id, V1). */
function makeVault(domaine: string, runs: VaultRunManifest[]): VeilleVault {
  return {
    id: `vault-${domaine}`,
    userId: 'user1',
    domaine,
    vaultMd: `# VAULT — ${domaine}`,
    vaultHash: 'h0',
    runs,
    createdAt: runs[0]?.at ?? '',
    updatedAt: runs.at(-1)?.at ?? '',
  };
}

test('Lot 4 buildVeilleProgram: no vault yet → lastRun null, relevance null, count 0 (premier run en attente)', () => {
  const a = makeAutomation({ id: 'auto-1' });
  const p: VeilleProgram = buildVeilleProgram(a, []);
  assert.equal(p.lastRun, null, 'pas de vault → aucun run');
  assert.equal(p.relevance, null, 'pas de run → pas de verdict');
  assert.equal(p.totalSources, 0, 'pas de run → count 0');
  assert.equal(p.delta, 0, 'pas de run → delta 0');
});

test('Lot 4 buildVeilleProgram: first run → count = newSources, delta = newSources (pas de run précédent)', () => {
  const a = makeAutomation({ id: 'auto-2' });
  const vaults = [makeVault('auto-2', [makeRun('r-0', 5, 5, 0.9)])];
  const p = buildVeilleProgram(a, vaults);
  assert.equal(p.lastRun?.newSources, 5, 'count = newSources du run');
  assert.equal(p.delta, 5, 'delta du 1er run = ses sources (0 avant)');
  assert.equal(p.totalSources, 5, 'total = totalSources du run');
  assert.equal(p.relevance, 0.9, 'pertinence = verdict du run');
});

test('Lot 4 buildVeilleProgram: delta = newSources(courant) − newSources(précédent), borné à 0 min', () => {
  const a = makeAutomation({ id: 'auto-3' });
  const vaults = [makeVault('auto-3', [makeRun('r-0', 5, 5, 0.5), makeRun('r-1', 2, 7, 0.8)])];
  const p = buildVeilleProgram(a, vaults);
  // run r-1: newSources 2, précédent r-0: newSources 5 → delta = 2 − 5 = −3
  // → borné à 0 (la carte ne montre pas un "moins que la veille").
  assert.equal(p.delta, 0, 'delta négatif borné à 0');
  assert.equal(p.lastRun?.id, 'r-1', 'le dernier run du manifest');
  assert.equal(p.totalSources, 7, 'total cumulatif du dernier run');
});

test('Lot 4 buildVeilleProgram: delta positif = croissance du "ce jour"', () => {
  const a = makeAutomation({ id: 'auto-4' });
  const vaults = [makeVault('auto-4', [makeRun('r-0', 2, 2, 0.5), makeRun('r-1', 4, 6, 0.9)])];
  const p = buildVeilleProgram(a, vaults);
  assert.equal(p.delta, 2, 'delta = 4 − 2 = 2 (2 sources de plus ce jour)');
});

test('Lot 4 buildVeilleProgram: le vault se cherche par domaine = id du programme (V1)', () => {
  const a = makeAutomation({ id: 'auto-5' });
  const otherVault = makeVault('auto-X', [makeRun('r-x', 9, 9, 1.0)]);
  const p = buildVeilleProgram(a, [otherVault]);
  // auto-5 n'a pas de vault domaine='auto-5' → pas de run (pas de faux join).
  assert.equal(p.lastRun, null, 'le vault d\'un autre domaine n\'est pas joint');
});

test('Lot 4 selectResearchPrograms: le filtre de la carte = jobKind research + enabled', () => {
  const research = makeAutomation({ id: 'a-research', name: 'Veille' });
  const notResearch = makeAutomation({ id: 'a-other', jobKind: 'digest', name: 'Digest' });
  const disabled = makeAutomation({ id: 'a-off', enabled: false, name: 'Désactivé' });
  const filtered = selectResearchPrograms([research, notResearch, disabled]);
  assert.deepEqual(filtered.map((f) => f.id), ['a-research'], 'un seul programme gardé (research + enabled)');
});
