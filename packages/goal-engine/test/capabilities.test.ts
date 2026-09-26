/**
 * Goal capability state machine tests (wave 3, HEPHAESTUS task 4:
 * the 7 agent goal capabilities). The agent emits the commands; these
 * mutations are the deterministic state transitions the Progress module
 * applies to GoalProject rows (AD-7 single-writer).
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  assembleGoalProject,
  type GoalDecomposition,
} from '../src/decomposition.ts';
import {
  pauseGoal,
  resumeGoal,
  completeGoal,
  abandonGoal,
  isGoalComplete,
  detectStall,
  type GoalProject,
} from '../src/progress.ts';

const NOW = '2026-10-01T08:00:00Z';
const LATER = '2026-10-02T08:00:00Z';

function activeGoal(spec: Partial<GoalDecomposition> = {}): GoalProject {
  return assembleGoalProject({
    decomposition: {
      objective: 'ML Mastery — 6 mois',
      successCriteria: 'QCM >= 80%',
      horizon: 'monthly',
      subGoals: [
        { label: 'A', features: ['qcm_generate'], sequence: 1, successCriteria: 'ok' },
        { label: 'B', features: ['mirror_analyze'], sequence: 2, successCriteria: 'ok' },
      ],
      ...spec,
    } as GoalDecomposition,
    userId: 'u1',
    goalId: 'gp1',
    now: NOW,
  });
}

test('goal.pause: active -> paused, progress untouched (ADR S13)', () => {
  const g = activeGoal();
  g.progress.subGoalProgress['sg_1'] = 42;
  const paused = pauseGoal(g, LATER);
  assert.equal(paused.status, 'paused');
  assert.equal(paused.progress.overallPct, g.progress.overallPct);
  assert.equal(paused.updatedAt, LATER);
});

test('goal.pause on a non-active goal throws', () => {
  const g = activeGoal();
  const completed = completeGoal(g, NOW);
  assert.throws(() => pauseGoal(completed, LATER), /pause_invalid_status/);
});

test('goal.pause + resume round-trip; resume only legal from paused', () => {
  const g = activeGoal();
  const paused = pauseGoal(g, LATER);
  const resumed = resumeGoal(paused, LATER);
  assert.equal(resumed.status, 'active');
  assert.throws(() => resumeGoal(g, LATER), /resume_invalid_status/);
});

test('goal.complete: success path — overall 100%, terminal, no re-mutation', () => {
  const g = activeGoal();
  g.progress.subGoalProgress = { sg_1: 100, sg_2: 100 };
  g.progress.overallPct = 100;
  g.subGoals[0].status = 'done';
  g.subGoals[1].status = 'done';
  assert.equal(isGoalComplete(g), true);
  const completed = completeGoal(g, LATER);
  assert.equal(completed.status, 'completed');
  assert.equal(completed.progress.overallPct, 100);
  assert.throws(() => completeGoal(completed, LATER), /complete_on_terminal_goal/);
  assert.throws(() => abandonGoal(completed, LATER), /abandon_on_terminal_goal/);
});

test('goal.abandon: data preserved, goal deactivated (terminal)', () => {
  const g = activeGoal();
  g.progress.subGoalProgress['sg_1'] = 30;
  const abandoned = abandonGoal(g, LATER);
  assert.equal(abandoned.status, 'abandoned');
  // history survives: progress values are intact, row remains readable.
  assert.equal(abandoned.progress.subGoalProgress['sg_1'], 30);
  assert.throws(() => abandonGoal(abandoned, LATER), /abandon_on_terminal_goal/);
});

test('a paused goal is NOT counted as a progress stall trigger', () => {
  const g = activeGoal();
  g.progress.subGoalProgress['sg_1'] = 20; // would stall when active
  const paused = pauseGoal(g, LATER);
  assert.deepEqual(detectStall(paused), []);
  assert.equal(detectStall(g).length, 1);
});
