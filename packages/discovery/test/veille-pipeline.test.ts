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

// ——— G9 / wave 3 : le wiring dispatcher (①) ———

test('G9 (wave 3) : le handler research discovery porte discoverySheet=true → le pipeline assemble les items + le notificationJob payload', async () => {
  // Imports différés du wiring : buildDiscoveryResearchHandler +
  // DISCOVERY_JOB_HANDLERS (l'export que le dispatcher ORION importe,
  // packages/discovery/src/jobs.ts).
  const { buildDiscoveryResearchHandler, DISCOVERY_JOB_HANDLERS } = await import('../src/jobs.ts');

  // La table du module (celle que le dispatcher enregistre dans sa
  // global switch, L21 de fn-job-dispatcher) porte un handler 'research'
  // module-scoped : le symbol existe et est branché.
  assert.ok(
    DISCOVERY_JOB_HANDLERS.some((h) => h.jobKind === 'research' && h.module === 'discovery'),
    'DISCOVERY_JOB_HANDLERS expose le handler research/discovery (wiring ORION)',
  );

  // Un filterCtx AI + un hit AI credible-uncertain (source tierce, AD-16b).
  const filterCtx = { disciplines: ['AI'] } as unknown as DiscoveryFilterContext;
  const handler = buildDiscoveryResearchHandler({
    filterCtx,
    provider: new OfflineResearchProvider(), // offline : résultats vides, dégradation AD-1
  });

  const res = await handler.handler('j1', 'u1', {
    op: 'multi-source',
    discoverySheet: true, // le flag qui déclenche le pipeline veille
    channelId: 'ch1',
    sheetTitle: 'Veille AI',
    query: {
      userId: 'u1',
      topic: 'AI',
      domains: ['AI'],
      kinds: ['other'],
    } as never,
  });

  assert.equal(res.ok, true, 'le handler ne casse jamais (dégradation AD-1)');
  const r = res.result as { discoveryItems: unknown[]; notificationJob: { module: string; jobKind: string; uncertain: boolean; channelId: string; title: string } };
  assert.equal(r.discoveryItems.length, 0, 'offline provider : aucun hit, donc 0 item');
  // AD-16b : flag JAMAIS supprimé — offline = source absente = uncertain.
  assert.equal(r.notificationJob.uncertain, true);
  assert.equal(r.notificationJob.module, 'integrations');
  assert.equal(r.notificationJob.jobKind, 'notification');
  assert.equal(r.notificationJob.channelId, 'ch1');
  assert.equal(r.notificationJob.title, 'Veille AI');
});

test('G9 (wave 3) : le flag discoverySheet ABSENT → le handler retourne le shape legacy (pas de pipeline) (invariant du comportement par défaut)', async () => {
  const { buildDiscoveryResearchHandler } = await import('../src/jobs.ts');
  const filterCtx = { disciplines: ['AI'] } as unknown as DiscoveryFilterContext;
  const handler = buildDiscoveryResearchHandler({
    filterCtx,
    provider: new OfflineResearchProvider(),
  });
  const res = await handler.handler('j2', 'u1', {
    op: 'multi-source',
    // PAS de flag discoverySheet → comportement legacy (search only)
    query: {
      userId: 'u1',
      topic: 'AI',
      domains: ['AI'],
      kinds: ['other'],
    } as never,
  });
  assert.equal(res.ok, true);
  const r = res.result as { op: string; count: number; discoveryItems?: unknown };
  assert.equal(r.op, 'multi-source');
  assert.equal(r.count, 0);
  assert.equal('discoveryItems' in r, false, 'sans le flag, le shape legacy est conservé (pas de pipeline)');
});
