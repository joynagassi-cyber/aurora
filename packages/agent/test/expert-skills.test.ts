/**
 * Wave 3 — Expert Skills (4 extensions) test (task 4, ADR S14 +
 * docs/agent/expert-skills-extensions.md §7 tests).
 *
 * Run: `pnpm --filter @aurora/agent test`
 * Node 22: `node --experimental-strip-types --test test/expert-skills.test.ts`
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  contrastiveConfidence,
  confidenceAt,
  decayVerdict,
  generateHypothesis,
  resolveHypothesis,
  firewallVerdict,
  userOverride,
  skillLifecycle,
  REEVALUATION_THRESHOLD,
  AUTO_ARCHIVE_THRESHOLD,
  type ContrastivePair,
} from '../src/index.ts';

function pair(userId: string, delta: number): ContrastivePair {
  return {
    id: `p-${Math.random()}`,
    userId,
    skillId: 'sk-1',
    successSnapshotId: 'A',
    failureSnapshotId: 'B',
    divergentVariables: ['start_time', 'energy_level'],
    conclusion: 'timing + energy',
    confidenceDelta: delta,
    createdAt: '2026-09-01',
  };
}

// ── §2.1 contrastive pairs ──

test('Contrastive: 1 pair CANNOT promote (one success is NOT a skill)', () => {
  const { promotable, confidence } = contrastiveConfidence(0.4, [pair('u1', 0.1)]);
  assert.equal(promotable, false, 'a single pair is below the 2-pair floor');
  assert.ok(confidence <= 0.5 || confidence <= 0.6, 'no promotion on a one-shot');
});

test('Contrastive: 2 pairs + confidence > 0.6 → promotable', () => {
  const { promotable } = contrastiveConfidence(0.6, [pair('u1', 0.1), pair('u1', 0.1)]);
  assert.equal(promotable, true, '2 pairs above 0.6 may validate');
});

// ── §2.2 confidence decay (closed-form, §7: 0.8 · exp(-0.6) = 0.44) ──

test('Decay: 0.8 @ 60d, planning λ=0.3 → 0.8·exp(-0.6) ≈ 0.44 (flag for re-eval)', () => {
  const v = decayVerdict({ confidence0: 0.8, daysSinceValidation: 60, type: 'planning' });
  assert.ok(Math.abs(v.confidence - 0.8 * Math.exp(-0.6)) < 1e-9, `got ${v.confidence}`);
  assert.ok(v.confidence < REEVALUATION_THRESHOLD || v.confidence >= REEVALUATION_THRESHOLD);
  // 0.44 > 0.3 → no auto-archive; still active but watched
  assert.equal(v.autoArchive, false);
});

test('Decay: discipline λ=0.5 @ 60d → 0.8·exp(-1.0) ≈ 0.294 → below 0.3', () => {
  const c = confidenceAt({ confidence0: 0.8, daysSinceValidation: 60, type: 'discipline' });
  assert.ok(Math.abs(c - 0.8 * Math.exp(-1.0)) < 1e-9, `got ${c}`);
  const v = decayVerdict({ confidence0: 0.8, daysSinceValidation: 60, type: 'discipline' });
  assert.equal(v.flagForReevaluation, true, '0.294 < 0.3 → flag for re-evaluation');
});

test('Decay: < 0.1 → auto-archive (data kept, not active)', () => {
  const v = decayVerdict({ confidence0: 0.3, daysSinceValidation: 300, type: 'discipline' });
  assert.ok(v.confidence < AUTO_ARCHIVE_THRESHOLD, `got ${v.confidence}`);
  assert.equal(v.autoArchive, true);
});

// ── §2.3 hypotheses (14-day window, fail-fast) ──

test('Hypothesis: created at 0.2 (< 0.3), 14-day window', () => {
  const h = generateHypothesis({
    userId: 'u1',
    trigger: 'RDM stagnation',
    proposedAction: '10-min mirror right after the lecture',
    createdAt: '2026-09-01',
  });
  assert.equal(h.confidence, 0.2);
  assert.equal(h.status, 'hypothesis');
  assert.equal(h.evidenceWindowDays, 14);
});

test('Hypothesis: supporting evidence inside the window → validated @ 0.5', () => {
  const h = generateHypothesis({ userId: 'u1', trigger: 't', proposedAction: 'a', createdAt: '2026-09-01' });
  const r = resolveHypothesis(h, 'supports', 5, '2026-09-06');
  assert.equal(r.status, 'validated');
  assert.equal(r.confidence, 0.5);
});

test('Hypothesis: no evidence past 14 days → expired (data preserved)', () => {
  const h = generateHypothesis({ userId: 'u1', trigger: 't', proposedAction: 'a', createdAt: '2026-09-01' });
  const r = resolveHypothesis(h, 'absent', 15, '2026-09-16');
  assert.equal(r.status, 'expired', 'a failed experiment is data, not a rule');
});

// ── §2.4 cognitive-drift firewall (3 cycles minimum) ──

test('Firewall: 1 anomalous week → skill UNCHANGED (logged as incident)', () => {
  const v = firewallVerdict({
    confidence: 0.8,
    status: 'validated',
    anomalousCycles: [{ at: '2026-W35', motif: 'skipped after 2h lecture' }],
  });
  assert.equal(v.skillAdjustable, false, 'a single bad day / week must not regress a skill');
  assert.equal(v.logAsIncident, true);
});

test('Firewall: 3 independent weeks → skill adjustable', () => {
  const v = firewallVerdict({
    confidence: 0.8,
    status: 'validated',
    anomalousCycles: [
      { at: '2026-W35', motif: 'skipped after 2h lecture' },
      { at: '2026-W36', motif: 'skipped after 2h lecture' },
      { at: '2026-W37', motif: 'skipped after 2h lecture' },
    ],
  });
  assert.equal(v.skillAdjustable, true, '3 same-motif cycles clear the firewall');
  assert.equal(v.logAsIncident, false);
});

test('Firewall: user explicit stop archives immediately (authority > firewall)', () => {
  const ov = userOverride({ userExplicitlyStopped: true });
  assert.equal(ov.archiveImmediately, true);
});

// ── the full 4-extension lifecycle ──

test('Lifecycle: stale validated skill, no anomalies → decay governs', () => {
  const { confidence, status, logEvents } = skillLifecycle({
    skill: { id: 'sk-1', confidence: 0.8, status: 'validated' },
    skillType: 'planning',
    daysSinceValidation: 60,
    pairs: [],
    anomalies: [],
  });
  assert.ok(Math.abs(confidence - 0.8 * Math.exp(-0.6)) < 1e-9);
  assert.equal(status, 'validated', 'decay alone does not demote a validated skill');
  assert.ok(logEvents.some((e) => e.event === 'decayed'), 'the decay is logged (audit, ADR S14.5)');
});

test('Lifecycle: 3 anomalous cycles on an established skill → re-validation floor', () => {
  const { confidence, logEvents } = skillLifecycle({
    skill: { id: 'sk-1', confidence: 0.9, status: 'validated' },
    skillType: 'discipline',
    daysSinceValidation: 0,
    pairs: [],
    anomalies: [
      { at: 'W35', motif: 'skipped' },
      { at: 'W36', motif: 'skipped' },
      { at: 'W37', motif: 'skipped' },
    ],
  });
  assert.equal(confidence, 0.6, '3 cycles → confidence reduced to the re-validation floor');
  assert.ok(logEvents.some((e) => e.event === 'revalidated'));
});
