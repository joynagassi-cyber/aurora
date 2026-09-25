/**
 * Discovery module — test suite (wave 2, ORION).
 * node:test + --experimental-strip-types (no build step).
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  applyDiscoveryFilters,
  discoveryCadence,
  type DiscoveryFilterContext,
} from '../src/filtering.ts';
import {
  detectGap,
  weighGapsAgainstStates,
  type GapDetectionInput,
} from '../src/gaps.ts';
import {
  buildDiscoveryItemCreated,
} from '../src/events.ts';
import {
  DiscoveryService,
} from '../src/discovery.ts';
import { OfflineResearchProvider } from '../src/research-provider.ts';
import type {
  DiscoveryItem,
  SkillState,
} from '@aurora/domain';

const USER = '00000000-0000-0000-0000-000000000001';

/** Benin filtering (S5 test case): $5000/yr tool + student budget
 *  → not actionable now (stored, not discarded). */
test('benin filtering: expensive paid tool + student budget = not_actionable', () => {
  const ctx: DiscoveryFilterContext = {
    disciplines: ['structures', 'concrete'],
    region: 'benin',
    budget: 'student',
    professionalTarget: 'bureau_etudes',
  };
  const d = applyDiscoveryFilters(
    ctx,
    { discipline: 'structures', tool: 'xyz-fem', costPerYearUsd: 5000 },
    [],
  );
  assert.equal(d.verdict, 'not_actionable_currently');
  assert.equal(d.rule, 'infrastructure-reality');
});

/** Free open-source tool in-budget = actionable. */
test('benin filtering: free open-source tool = relevant', () => {
  const ctx: DiscoveryFilterContext = {
    disciplines: ['structures'],
    region: 'benin',
    budget: 'student',
  };
  const d = applyDiscoveryFilters(
    ctx,
    {
      discipline: 'structures',
      tool: 'opensees',
      costPerYearUsd: 0,
      openSource: true,
    },
    [],
  );
  assert.equal(d.verdict, 'relevant');
});

/** Domain match: out-of-discipline hit is discarded. */
test('filtering: out-of-discipline = discarded', () => {
  const ctx: DiscoveryFilterContext = { disciplines: ['structures'] };
  const d = applyDiscoveryFilters(ctx, { discipline: 'hydraulics' }, []);
  assert.equal(d.verdict, 'discarded');
});

/** Cadence: exam period = reduced (S5). */
test('cadence: exam period = reduced 14d', () => {
  const ctx: DiscoveryFilterContext = {
    disciplines: ['structures'],
    examinationPeriod: true,
  };
  assert.deepEqual(discoveryCadence(ctx, '2026-09-25'), {
    intervalDays: 14,
    reduced: true,
  });
});

/** Gap detection (S1.2/S1.3): concept not in tree + required by
 *  regulatory → DetectedGap; same concept already gapped → deduped. */
test('gap detection: missing concept = detected, dup = null', () => {
  const result = {
    provider: 'offline',
    kind: 'regulatory' as const,
    title: 'FEM validation',
    summary: 'Eurocode 2 6.2 requires FEM validation',
    confidence: 0.8,
    credibility: 'documented' as const,
  };
  const input: GapDetectionInput = {
    userId: USER,
    result,
    nodes: [{ id: 'n1', label: 'Flexion simple', kind: 'formula' }],
    existingGaps: [],
    discipline: 'structures',
  };
  const g = detectGap(input);
  assert.notEqual(g, null);
  assert.equal(g?.concept, 'FEM validation');
  assert.equal(g?.treePosition.status, 'missing');

  // Same concept already has a gap → no dup (S1.3 test).
  const input2: GapDetectionInput = {
    ...input,
    existingGaps: [{ id: 'g1', kind: 'skill', description: 'FEM validation' }],
  };
  assert.equal(detectGap(input2), null);
});

/** Competence weighing: a gap whose skill is mastered → low urgency. */
test('gap weighing: mastered skill downgrades urgency', () => {
  const gap = {
    userId: USER,
    concept: 'M_max PL/4',
    discipline: 'rdm',
    kind: 'skill' as const,
    urgency: 'high' as const,
    sourceRefs: [],
    treePosition: { branch: 'rdm', status: 'missing' as const },
    discoveryRef: 'x',
  };
  const states: SkillState[] = [
    {
      id: 's1',
      userId: USER,
      skillId: 'M_max PL/4',
      level: 'mastered',
      evidenceRefs: [],
      updatedAt: '2026-09-25',
    },
  ];
  const out = weighGapsAgainstStates([gap], states);
  assert.equal(out[0]?.urgency, 'low');
});

/** DiscoveryItemCreated event builder (AD-9 SSoT shape). */
test('event builder: DiscoveryItemCreated payload shape', () => {
  const item: DiscoveryItem = {
    id: 'D-1',
    userId: USER,
    title: 'Eurocode 2 FEM validation',
    whyNow: 'Normative convergence',
    summary: 'FEM now standard in bureaux',
    sources: [{ v: 'EC2-6.2' }, { v: 'bureau-report-A' }],
    relatedCourseIds: [],
    relatedSkillIds: [],
    semanticNodeIds: [],
    relatedGoalIds: [],
    createdAt: '2026-09-25T00:00:00Z',
    updatedAt: '2026-09-25T00:00:00Z',
  };
  const ev = buildDiscoveryItemCreated(item, '2026-09-25T00:00:01Z');
  assert.equal(ev.type, 'DiscoveryItemCreated');
  assert.equal(ev.payload.discoveryItemId, 'D-1');
  assert.equal(ev.payload.userId, USER);
  assert.equal(ev.payload.topic, 'Eurocode 2 FEM validation');
  assert.deepEqual(ev.payload.sources, ['EC2-6.2', 'bureau-report-A']);
});

/** Offline degradation (AD-1): no provider → results degraded, product
 *  does not break. */
test('offline: no provider → empty degraded results, no throw', async () => {
  const svc = new DiscoveryService(
    { disciplines: ['structures'], region: 'benin' },
    new OfflineResearchProvider(),
  );
  const out = await svc.research({
    userId: USER,
    topic: 'FEM validation',
    domains: ['structures'],
    kinds: ['technical'],
  });
  assert.deepEqual(out, []);
});
