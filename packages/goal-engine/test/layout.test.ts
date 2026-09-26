/**
 * Goal Engine — dashboard layout engine tests (wave 3, HEPHAESTUS task 3:
 * 5 adaptive layouts). The layout is DERIVED from the goal's shape +
 * timeline structure (goal-dashboard-ui.md S5) — position = meaning.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  assembleGoalProject,
  type GoalDecomposition,
} from '../src/decomposition.ts';
import {
  computeGoalDashboardLayout,
  GOAL_SHAPES,
  featureLabel,
  layoutTagFor,
} from '../src/layout.ts';

const NOW = '2026-10-01T08:00:00Z';

function goal(spec: Partial<GoalDecomposition> = {}): import('@aurora/domain').GoalProject {
  return assembleGoalProject({
    decomposition: {
      objective: 'Goal',
      successCriteria: '100%',
      horizon: 'monthly',
      subGoals: [
        { label: 'A', features: ['focus_session', 'qcm_generate'], sequence: 1, successCriteria: 'ok' },
        { label: 'B', features: ['mirror_analyze'], sequence: 2, successCriteria: 'ok' },
      ],
      ...spec,
    } as GoalDecomposition,
    userId: 'u1',
    goalId: 'gp1',
    now: NOW,
  });
}

test('the layout vocabulary is closed at 5 shapes + custom', () => {
  assert.deepEqual([...GOAL_SHAPES], [
    'preparation',
    'practice',
    'curation',
    'delivery',
    'adaptation',
  ]);
});

test('rows group parallel features (same sequence = same row, side by side)', () => {
  const g = goal();
  const layout = computeGoalDashboardLayout(g, 'practice');
  // Row 1: focus_session + qcm_generate (sequence 1, parallel).
  const row1 = layout.rows.find((r) => r.row === 0);
  assert.deepEqual(row1?.featureIds, ['focus_session', 'qcm_generate']);
  const row2 = layout.rows.find((r) => r.row === 1);
  assert.deepEqual(row2?.featureIds, ['mirror_analyze']);
  // The active node = first feature of the first active sub-goal.
  assert.equal(layout.activeFeatureId, 'focus_session');
});

test('vertical flow connects every node of a row to the next row', () => {
  const g = goal();
  const layout = computeGoalDashboardLayout(g, 'practice');
  const focus = layout.nodes.get('focus_session');
  const qcm = layout.nodes.get('qcm_generate');
  const mirror = layout.nodes.get('mirror_analyze');
  assert.ok(focus && qcm && mirror);
  assert.ok(focus.connections.includes('mirror_analyze'));
  assert.ok(qcm.connections.includes('mirror_analyze'));
  assert.deepEqual(mirror.connections, []);
});

test('"parallel:" position draws a horizontal line on the same row', () => {
  const g = goal({
    subGoals: [
      { label: 'A', features: ['focus_session', 'qcm_generate'], sequence: 1, successCriteria: 'ok' },
    ],
    placements: [
      { featureId: 'focus_session', role: 'execution', frequency: 'daily', position: '', config: {} },
      { featureId: 'qcm_generate', role: 'practice', frequency: 'per-block', position: 'parallel: focus_session', config: {} },
    ],
  });
  const layout = computeGoalDashboardLayout(g, 'practice');
  const qcm = layout.nodes.get('qcm_generate');
  assert.ok(qcm);
  assert.ok(
    qcm.connections.includes('focus_session'),
    'parallel line focus_session <-> qcm_generate',
  );
});

test('adaptation shape adds the loop-back (last row -> first row)', () => {
  const g = goal({
    subGoals: [
      { label: 'Analyze', features: ['progress_analyze'], sequence: 1, successCriteria: 'ok' },
      { label: 'Intervene', features: ['focus_session'], sequence: 2, successCriteria: 'ok' },
      { label: 'Verify', features: ['mirror_analyze'], sequence: 3, successCriteria: 'ok' },
    ],
  });
  const layout = computeGoalDashboardLayout(g, 'adaptation');
  const verify = layout.nodes.get('mirror_analyze');
  assert.ok(verify);
  assert.ok(
    verify.connections.includes('progress_analyze'),
    'loop-back: verification reconnects to the assessment row',
  );
  // Non-adaptation shapes do NOT add the loop-back.
  const plain = computeGoalDashboardLayout(g, 'practice');
  const plainVerify = plain.nodes.get('mirror_analyze');
  assert.ok(plainVerify);
  assert.ok(!plainVerify.connections.includes('progress_analyze'));
});

test('node states come from the owning sub-goal (S3 node states)', () => {
  const g = goal();
  const layout = computeGoalDashboardLayout(g, 'practice');
  assert.equal(layout.nodes.get('focus_session')?.state, 'active');
  assert.equal(layout.nodes.get('mirror_analyze')?.state, 'pending');
});

test('layoutTagFor: explicit tag wins; structure derives otherwise', () => {
  const g = goal({
    targetDate: '2026-12-31',
    subGoals: [
      { label: 'A', features: ['gap_detect'], sequence: 1, successCriteria: 'ok' },
    ],
  });
  // Explicit tag wins.
  assert.equal(layoutTagFor(g, 'delivery'), 'delivery');
  // gap_detect + deadline -> preparation.
  assert.equal(layoutTagFor(g), 'preparation');
  // knowledge features -> curation.
  const g2 = goal({
    subGoals: [{ label: 'K', features: ['knowledge_add'], sequence: 1, successCriteria: 'ok' }],
  });
  assert.equal(layoutTagFor(g2), 'curation');
});

test('context strip: stats + NL suggestion (NOT a system message)', () => {
  const g = goal();
  const layout = computeGoalDashboardLayout(g, 'practice');
  assert.equal(layout.contextStrip.stats.length, 2);
  // The next active sub-goal ("A") is not stalled (< 70% is the stall
  // threshold; 0% counts as pending progress, not a stall of an in-flight
  // sub-goal — the suggestion points at the next action).
  assert.match(layout.contextStrip.suggestion ?? '', /Prochain/);
});

test('featureLabel: canonical ids get user-facing labels, unknowns humanize', () => {
  assert.equal(featureLabel('qcm_generate'), 'QCM');
  assert.equal(featureLabel('focus_session'), 'Focus');
  assert.equal(featureLabel('gap_detect'), 'Lacunes');
  assert.equal(featureLabel('my_custom_feature'), 'My Custom Feature');
});
