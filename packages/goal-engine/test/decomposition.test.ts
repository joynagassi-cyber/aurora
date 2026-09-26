/**
 * Goal Engine — GoalProject assembly tests (wave 3, HEPHAESTUS task 1).
 * node:test + --experimental-strip-types (no build step).
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  assembleGoalProject,
  recomposeGoalProject,
  validateGoalProject,
  type GoalDecomposition,
} from '../src/decomposition.ts';

const NOW = '2026-10-01T08:00:00Z';

function decomposition(over: Partial<GoalDecomposition> = {}): GoalDecomposition {
  return {
    objective: "Maitriser le machine learning d'ici 6 mois",
    successCriteria: 'QCM >= 80%',
    horizon: 'semester',
    targetDate: '2027-04-01',
    subGoals: [
      { label: "Evaluer ou j'en suis", features: ['progress_analyze'], successCriteria: 'diagnostic fait' },
      { label: 'Pratiquer', features: ['qcm_generate', 'focus_session'], sequence: 2, successCriteria: 'QCM >= 80%' },
      { label: 'Verifier', features: ['mirror_analyze'], sequence: 2, successCriteria: 'skill >= autonomous-application' },
    ],
    ...over,
  };
}

test('assembleGoalProject: deduped feature union + normalized sequences', () => {
  const g = assembleGoalProject({
    decomposition: decomposition(),
    userId: 'u1',
    goalId: 'gp1',
    now: NOW,
  });

  assert.equal(g.id, 'gp1');
  assert.equal(g.status, 'active');
  assert.equal(g.horizon, 'semester');
  assert.equal(g.createdAt, NOW);
  // Feature union across sub-goals, deduplicated, order-preserving.
  assert.deepEqual(
    g.features.map((f) => f.featureId),
    ['progress_analyze', 'qcm_generate', 'focus_session', 'mirror_analyze'],
  );
  // Sub-goal 1 gets sequence 1 (auto), sub-goals 2 and 3 keep sequence 2 (parallel).
  assert.deepEqual(
    g.subGoals.map((s) => s.sequence),
    [1, 2, 2],
  );
  // First sub-goal active, the rest pending.
  assert.deepEqual(
    g.subGoals.map((s) => s.status),
    ['active', 'pending', 'pending'],
  );
  // Initial progress: 0 everywhere, no evidence refs yet (F-07).
  assert.equal(g.progress.overallPct, 0);
  assert.equal(g.progress.evidenceRefs.length, 0);
  assert.deepEqual(
    g.progress.subGoalProgress,
    { sg_1: 0, sg_2: 0, sg_3: 0 },
  );
  // Normalizer gate passes.
  assert.deepEqual(validateGoalProject(g), []);
});

test('assembleGoalProject: empty objective rejected', () => {
  assert.throws(
    () =>
      assembleGoalProject({
        decomposition: decomposition({ objective: '   ' }),
        userId: 'u1',
        goalId: 'gp1',
        now: NOW,
      }),
    /empty_objective/,
  );
});

test('assembleGoalProject: unknown explicit placement rejected', () => {
  assert.throws(
    () =>
      assembleGoalProject({
        decomposition: decomposition({
          placements: [
            { featureId: 'not_a_feature', role: 'x', frequency: 'on-event', position: '', config: {} },
          ],
        }),
        userId: 'u1',
        goalId: 'gp1',
        now: NOW,
      }),
    /unknown_placement_feature/,
  );
});

test('recomposeGoalProject: preserves progress of surviving sub-goals (ADR S13)', () => {
  let g = assembleGoalProject({
    decomposition: decomposition(),
    userId: 'u1',
    goalId: 'gp1',
    now: NOW,
  });
  g = {
    ...g,
    progress: {
      ...g.progress,
      overallPct: 50,
      subGoalProgress: { sg_1: 100, sg_2: 40, sg_3: 45 },
    },
  };

  // Recomposition that keeps "Pratiquer" (by label) + drops the others.
  const recomposed = recomposeGoalProject(
    g,
    decomposition({
      subGoals: [{ label: 'Pratiquer', features: ['qcm_generate', 'flashcard_generate'] }],
    }),
    '2026-10-15T08:00:00Z',
  );

  assert.equal(recomposed.subGoals.length, 1);
  // History preserved: "Pratiquer" carries over its 40% (label match),
  // the new sub-goal id is sg_1 so progress is remapped by label.
  assert.equal(recomposed.progress.subGoalProgress.sg_1, 40);
  assert.equal(recomposed.recomposedAt, '2026-10-15T08:00:00Z');
  assert.equal(recomposed.createdAt, NOW); // original creation kept
});

test('recomposeGoalProject: terminal goals cannot be recomposed', () => {
  const g = assembleGoalProject({
    decomposition: decomposition(),
    userId: 'u1',
    goalId: 'gp1',
    now: NOW,
  });
  assert.throws(
    () => recomposeGoalProject({ ...g, status: 'completed' }, decomposition(), NOW),
    /recompose_on_terminal_goal/,
  );
});
