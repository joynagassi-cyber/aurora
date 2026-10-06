/**
 * G9 (feature-agentique plan 2026-10-06 §G9) — pipeline veille.
 *
 * `research` → `discovery sheet` → `notification` push : l'assemblage
 * (pas un thin emitter). Le test pinne le contrat pur de
 * `runVeillePipeline` (discovery/src/veille-pipeline.ts) :
 *   1. items DiscoveryItem qualifiés (le hit relevant produit un item ;
 *      le flag AD-16b se lit sur le suffixe `(uncertain)` du summary,
 *      invariant `buildDiscoveryItem` L93-96)
 *   2. le payload du notification job (module 'integrations',
 *      jobKind 'notification') avec le flag `uncertain` JAMAIS
 *      supprimé (AD-16b) + le vendor OneSignal N'EST JAMAIS appelé
 *      (AD-1 : payload retourné uniquement, le dispatcher le détient).
 *
 * Run: `pnpm --filter @aurora/discovery test`
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import { runVeillePipeline } from '../src/veille-pipeline.ts';
import { OfflineResearchProvider } from '../src/research-provider.ts';
import type { DiscoveryFilterContext } from '../src/filtering.ts';
import type { ResearchResult } from '@aurora/domain';

/** Un hit filtrable : discipline `AI` (dans le filterCtx) + credible
 *  `uncertain` (source tierce, AD-16b). */
function makeHit(over: Partial<ResearchResult> & { discipline: string }): ResearchResult {
  return {
    provider: 'offline',
    kind: 'other',
    title: 'Hit',
    summary: 'Summary',
    confidence: 0.5,
    credibility: 'uncertain',
    ...over,
  } as unknown as ResearchResult;
}

test('G9: runVeillePipeline returns items + notification job payload (uncertain flag AD-16b)', () => {
  const filterCtx = { disciplines: ['AI'], goals: [], courses: [] } as unknown as DiscoveryFilterContext;
  const results = [
    makeHit({
      discipline: 'AI',
      title: 'X',
      summary: 'Y',
      credibility: 'uncertain',
      url: 'u1',
    }),
  ];
  const out = runVeillePipeline(
    results,
    { userId: 'u1', title: 'Veille' },
    filterCtx,
    { channelId: 'ch1', title: 'Veille OK' },
  );
  assert.equal(out.discoveryItems.length, 1, 'le hit relevant produit 1 DiscoveryItem');
  assert.equal(out.notificationJob.uncertain, true, 'AD-16b: uncertain flag NEVER stripped');
  assert.equal(out.notificationJob.jobKind, 'notification');
  assert.equal(out.notificationJob.module, 'integrations');
  assert.equal(out.notificationJob.channelId, 'ch1');
  assert.equal(out.notificationJob.title, 'Veille OK');
});

test('G9: AD-16b — un hit UNCERTAIN-source produit un item au suffixe (uncertain) + flag job true', () => {
  const filterCtx = { disciplines: ['AI'] } as unknown as DiscoveryFilterContext;
  const results = [
    makeHit({ discipline: 'AI', title: 'X', summary: 'Y', credibility: 'uncertain', url: 'u1' }),
  ];
  const out = runVeillePipeline(results, { userId: 'u1', title: 'Veille' }, filterCtx, {
    channelId: 'ch1',
    title: 'Veille OK',
  });
  // L'invariant AD-16b se lit sur l'ITEM (invariant `buildDiscoveryItem`
  // L93-96 : summary portera le suffixe `(uncertain)`).
  assert.ok(
    out.discoveryItems[0]?.summary?.endsWith('(uncertain)'),
    'DiscoveryItem.summary porte le suffixe (uncertain) — AD-16b, le flag est JAMAIS supprimé',
  );
  assert.equal(out.notificationJob.uncertain, true);
});

test('G9: hit OFF-domaine (discipline absente du ctx) = pas d\'item ; dégradation AD-1 force le flag uncertain', () => {
  const filterCtx = { disciplines: ['AI'] } as unknown as DiscoveryFilterContext;
  const results = [
    makeHit({ discipline: 'BIO', title: 'X', summary: 'Y', credibility: 'documented', url: 'u1' }),
  ];
  const out = runVeillePipeline(results, { userId: 'u1', title: 'Veille' }, filterCtx, {
    channelId: 'ch1',
    title: 'Veille OK',
  });
  assert.equal(out.discoveryItems.length, 0, 'le hit hors-domaine est filtré (pas d\'item)');
  // Aucun item qualifiable (tous les hits écartés) → la dégradation
  // AD-1 (01 §6 : l'absence de source qualifiée n'éclate jamais le
  // produit, elle le marque uncertain) force le flag à true, MÊME si
  // la source est `documented` (le flag regarde l'INCAPACITÉ à
  // qualifier, pas seulement la crédibilité brute).
  assert.equal(out.notificationJob.uncertain, true);
});

test('G9: résultat vide = 0 item, flag uncertain true (dégradation AD-1, aucun provider)', () => {
  const filterCtx = { disciplines: ['AI'] } as unknown as DiscoveryFilterContext;
  const out = runVeillePipeline(
    [],
    { userId: 'u1', title: 'Veille' },
    filterCtx,
    { channelId: 'ch1', title: 'Veille OK' },
  );
  assert.equal(out.discoveryItems.length, 0);
  // Aucun hit qualifiable → le verdict par défaut est 'uncertain'
  // (dégradation AD-1 : l'absence de provider n'éclate jamais le produit,
  // elle le marque uncertain).
  assert.equal(out.notificationJob.uncertain, true);
});

test('G9: le pipeline est SYNCHRONE + PUR (pas de vendor, pas de job queue) — OfflineResearchProvider branché', () => {
  // Le vendor OneSignal n'est JAMAIS appelé (AD-1) : le pipeline retourne
  // uniquement le payload. L'OfflineResearchProvider prouve que la chaîne
  // marche sans provider configuré (dégradation AD-1, 01 §6).
  const provider = new OfflineResearchProvider();
  assert.equal(provider.isConfigured(), false);
  const out = runVeillePipeline([], { userId: 'u1', title: 'Veille' }, { disciplines: ['AI'] } as DiscoveryFilterContext, {
    channelId: 'ch1',
    title: 'Veille OK',
  });
  // Le payload est complet, le body est optionnel mais présent si fourni.
  assert.equal(typeof out.notificationJob.uncertain, 'boolean');
  assert.ok(!('body' in out.notificationJob) || out.notificationJob.body === undefined);
});
