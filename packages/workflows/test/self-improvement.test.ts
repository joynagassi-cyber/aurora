import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  confidenceAt, decayVerdict, DECAY_LAMBDA,
  contrastiveConfidence, generateHypothesis, resolveHypothesis,
  firewallVerdict, userOverride,
  loopStage, SELF_IMPROVEMENT_STAGES,
} from '../src/index.ts';

/** Task 4: the Expert Skill self-improvement loop (Progress -> Self-Improve
 *  -> Discovery -> Expert Skill revisee) — deterministic formulas per
 *  docs/agent/expert-skills-extensions.md §2. */

test('confidence decay (§2.2): closed-form, per-skill-type lambda', () => {
  assert.equal(DECAY_LAMBDA.planning, 0.3);
  assert.equal(DECAY_LAMBDA.learning, 0.1);
  assert.equal(DECAY_LAMBDA.discipline, 0.5);
  // doc example: conf=0.8, lambda=0.3/30d, 60 days -> 0.8 * exp(-0.6) = 0.44
  const c = confidenceAt({
    confidence0: 0.8, daysSinceValidation: 60, type: 'planning',
  });
  assert.ok(Math.abs(c - 0.8 * Math.exp(-0.6)) < 1e-9, `got ${c}`);
  // 0.8 * exp(-0.6) ≈ 0.44 — still above the 0.3 re-evaluation threshold
  const v = decayVerdict({
    confidence0: 0.8, daysSinceValidation: 60, type: 'planning',
  });
  assert.equal(v.flagForReevaluation, false, '0.44 >= 0.3 -> not flagged yet');
  // 120 days -> 0.8 * exp(-1.2) ≈ 0.246 < 0.3 -> flag
  assert.ok(
    decayVerdict({
      confidence0: 0.8, daysSinceValidation: 120, type: 'planning',
    }).flagForReevaluation,
  );
});

test('contrastive pairs (§2.1): no one-shot promotion, min 2 pairs', () => {
  const one = contrastiveConfidence(0.7, [{
    successSnapshotId: 'a', failureSnapshotId: 'b',
    divergentVariables: ['start_time'], conclusion: 'timing',
    confidenceDelta: 0.1,
  }]);
  assert.equal(one.promotable, false, '1 pair must not promote above 0.6');
  const two = contrastiveConfidence(0.5, [
    {
      successSnapshotId: 'a', failureSnapshotId: 'b',
      divergentVariables: ['start_time'], conclusion: 'timing',
      confidenceDelta: 0.1,
    },
    {
      successSnapshotId: 'c', failureSnapshotId: 'd',
      divergentVariables: ['energy_level'], conclusion: 'energy',
      confidenceDelta: 0.1,
    },
  ]);
  assert.equal(two.promotable, true, '2 pairs + delta -> promotable');
});

test('hypotheses (§2.3): low confidence at creation, lifecycle', () => {
  const h = generateHypothesis({ trigger: 'stagnation', proposedAction: 'mirror after lecture' });
  assert.equal(h.confidence, 0.2);
  assert.equal(h.status, 'hypothesis');
  assert.equal(h.evidenceWindowDays, 14);
  assert.equal(resolveHypothesis(h, 'supports', 5).status, 'validated');
  assert.equal(resolveHypothesis(h, 'absent', 14).status, 'expired');
});

test('firewall (§2.4): established skill survives < 3 cycles', () => {
  const c1 = { at: '2026-09-01', motif: 'skipped after lecture' };
  const c2 = { at: '2026-09-08', motif: 'skipped after lecture' };
  const v1 = firewallVerdict({ confidence: 0.7, status: 'active', anomalousCycles: [c1] });
  assert.equal(v1.skillAdjustable, false, '1 cycle -> firewall holds');
  assert.equal(v1.logAsIncident, true);
  const v3 = firewallVerdict({
    confidence: 0.7, status: 'active',
    anomalousCycles: [c1, c2, { at: '2026-09-15', motif: 'skipped after lecture' }],
  });
  assert.equal(v3.skillAdjustable, true, '3 cycles -> skill adjustable');
  // user authority overrides the firewall
  assert.equal(userOverride({ userExplicitlyStopped: true }).archiveImmediately, true);
});

test('loop stages: 6 stages in fixed order', () => {
  assert.equal(SELF_IMPROVEMENT_STAGES.length, 6);
  assert.deepEqual(
    SELF_IMPROVEMENT_STAGES,
    ['progress-gap', 'self-improve-triage', 'discovery',
     'skill-revised', 'next-session-applied', 'progress-recorded'],
  );
  assert.equal(
    loopStage({ gapSkillId: 'rdm.flexion' }),
    'progress-gap',
  );
  assert.equal(
    loopStage({ gapSkillId: 'x', causalConclusion: 'timing' }),
    'self-improve-triage',
  );
  assert.equal(
    loopStage({ gapSkillId: 'x', revisedSkillKey: 'planning.heavy-day' }),
    'skill-revised',
  );
  assert.equal(
    loopStage({
      gapSkillId: 'x', applied: true, outcomeLevel: '78%',
    }),
    'progress-recorded',
  );
});
