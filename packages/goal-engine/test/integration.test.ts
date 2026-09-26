/**
 * Goal Engine — integration tests (wave 3, HEPHAESTUS task 5:
 * GoalProject -> feature-registry -> Agent Planner -> Progress).
 *
 * The chain is validated end-to-end with the PURE, server-side pieces:
 *   - GoalProject composition (decomposition -> assemble);
 *   - the composition pattern -> Planner hints (patterns);
 *   - the dashboard layout DERIVED from the composition (layout —
 *     the Agent->UI contract, goal-dashboard-ui.md S5);
 *   - progress evaluation + completion (progress — F-07 sole producer);
 *   - cross-goal feature sequencing (mutations).
 * No DB, no LLM, no registry access — the deterministic path only.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import type { GoalProject } from '@aurora/domain';
import {
  assembleGoalProject,
  recomposeGoalProject,
  validateGoalProject,
  type GoalDecomposition,
} from '../src/decomposition.ts';
import {
  matchPatterns,
  patternTemplate,
  type GoalSignature,
} from '../src/patterns.ts';
import {
  addFeatureToGoal,
  removeFeatureFromGoal,
  sequenceSharedFeatures,
} from '../src/mutations.ts';
import {
  computeGoalDashboardLayout,
  layoutTagFor,
} from '../src/layout.ts';
import {
  overallProgress,
  completeGoal,
  pauseGoal,
  detectStall,
  goalSuggestion,
} from '../src/progress.ts';

const NOW = '2026-11-01T08:00:00Z';
const LATER = '2026-11-15T08:00:00Z';

/** An "exam prep" goal signature (deadline + domain). */
const EXAM_SIG: GoalSignature = {
  hasDeadline: true,
  hasDomain: true,
  isRepetitive: false,
  isCollecting: false,
  hasMilestones: false,
  isBehaviorChange: false,
};

test('exam goal -> preparation pattern (the Planner\'s HINT, not a constraint)', () => {
  const ranked = matchPatterns(EXAM_SIG);
  assert.equal(ranked[0], 'preparation', 'deadline+domain -> preparation is the top hint');
});

test('the composition chain: pattern -> placements -> GoalProject -> dashboard layout', () => {
  // 1. The Planner takes the pattern template as a seed.
  const template = patternTemplate('preparation');

  // 2. The decomposition (LLM step) fills the spec; the pattern's
  //    placements are the explicit feature placements.
  const decomposition: GoalDecomposition = {
    objective: 'Master machine learning before the exam',
    successCriteria: 'QCM >= 80%',
    targetDate: LATER,
    horizon: 'semester',
    subGoals: [
      { label: 'Identify the gaps', features: ['gap_detect', 'research_run'], sequence: 1, successCriteria: 'gaps mapped' },
      { label: 'Practice regularly', features: ['qcm_generate', 'focus_session'], sequence: 2, successCriteria: '30 QCM done' },
      { label: 'Verify mastery', features: ['mirror_analyze', 'progress_analyze'], sequence: 3, successCriteria: 'skill >= competent' },
    ],
    placements: template.placements,
    timeline: template.timeline,
    pattern: template.layout,
  };

  // 3. Assemble the GoalProject (the agent's creation, CONFIRMATION_REQUIRED
  //    happens upstream — the assembled project is what the user confirms).
  const goal = assembleGoalProject({ decomposition, userId: 'u1', goalId: 'gp1', now: NOW });
  assert.deepEqual(validateGoalProject(goal), [], 'the Normalizer gate passes');

  // 4. The UI derives the LAYOUT from the composition (goal-dashboard-ui.md
  //    S5 Agent->UI contract: DATA in, LAYOUT out).
  const layout = computeGoalDashboardLayout(goal, layoutTagFor(goal, 'preparation'));
  assert.equal(layout.shape, 'preparation');
  assert.ok(layout.header.overallPct === 0, 'a fresh goal starts at 0%');
  // Every placed feature has a node (the workflow is spatially complete).
  for (const p of goal.features) assert.ok(layout.nodes.has(p.featureId));

  // 5. Cross-goal: two goals both using focus_session are SEQUENCED.
  const goal2 = assembleGoalProject({
    decomposition: {
      ...decomposition,
      objective: 'A second ML goal',
      subGoals: [{ label: 'Focus', features: ['focus_session'], sequence: 1, successCriteria: 'ok' }],
    } as GoalDecomposition,
    userId: 'u1',
    goalId: 'gp2',
    now: LATER,
  });
  const sequenced = sequenceSharedFeatures([goal, goal2]);
  assert.equal(sequenced.length, 2);
  // The shared feature (focus_session) is sequenced, not parallel.
  const slots = sequenced
    .filter((g) => g.features.some((p) => p.featureId === 'focus_session'))
    .map((g) => g.features.find((p) => p.featureId === 'focus_session')?.config.goalSlot as number | undefined)
    .filter((s) => s !== undefined);
  assert.ok(new Set(slots).size === slots.length, 'each goal claims a distinct slot for the shared feature');
});

test('feature add/remove + progress eval + completion (F-07 sole producer)', () => {
  const decomposition: GoalDecomposition = {
    objective: 'Stay current on concrete norms',
    successCriteria: '8/8 norms documented',
    horizon: 'quarterly',
    subGoals: [
      { label: 'Collect new norms', features: ['knowledge_add', 'research_run'], sequence: 1, successCriteria: '8 norms' },
    ],
  };
  let goal = assembleGoalProject({ decomposition, userId: 'u1', goalId: 'gp3', now: NOW });

  // goal.feature.add: "et ajoute des QCM chaque semaine".
  goal = addFeatureToGoal(goal, 'qcm_generate', { subGoalId: 'sg_1', now: LATER });
  assert.ok(goal.features.some((p) => p.featureId === 'qcm_generate'));
  // goal.feature.remove: "plus besoin de focus sur ce but".
  goal = removeFeatureFromGoal(goal, 'qcm_generate', LATER);
  assert.ok(!goal.features.some((p) => p.featureId === 'qcm_generate'));

  // Progress evaluation: 100% on the single sub-goal -> goal complete.
  goal = { ...goal, progress: { ...goal.progress, overallPct: 100, subGoalProgress: { sg_1: 100 } } };
  goal.subGoals[0] = { ...goal.subGoals[0], status: 'done' };
  assert.equal(overallProgress(goal), 100);
  const completed = completeGoal(goal, LATER);
  assert.equal(completed.status, 'completed');

  // A paused goal never triggers a stall (jobs are stopped).
  const paused = pauseGoal(goal, LATER);
  assert.deepEqual(detectStall(paused), []);

  // The NL suggestion is a string for an ACTIVE goal with a next sub-goal
  // (goal-dashboard-ui.md S4: a natural-language sentence, not a system
  // message). The completed goal above has no next sub-goal -> null.
  const freshGoal = assembleGoalProject({ decomposition, userId: 'u1', goalId: 'gp3b', now: LATER });
  assert.equal(typeof goalSuggestion(freshGoal), 'string');
});

test('recomposition preserves history (ADR S13) but replaces the composition', () => {
  const base: GoalDecomposition = {
    objective: 'ML mastery',
    successCriteria: 'QCM >= 80%',
    horizon: 'semester',
    subGoals: [
      { label: 'Learn', features: ['qcm_generate'], sequence: 1, successCriteria: 'ok' },
      { label: 'Verify', features: ['mirror_analyze'], sequence: 2, successCriteria: 'ok' },
    ],
  };
  const goal = assembleGoalProject({ decomposition: base, userId: 'u1', goalId: 'gp4', now: NOW });
  // A sub-goal at 0% has NOT stalled — it has simply not started
  // (detectStall: progress > 0 only). Set 50% -> stall.
  goal.progress.subGoalProgress['sg_1'] = 50;
  goal.progress.subGoalProgress['sg_2'] = 30;

  // Stall on BOTH sub-goals (50% + 30%, both below the 70% threshold)
  // -> the agent re-composes (more targeted QCM).
  assert.equal(detectStall(goal).length, 2);
  const spec: GoalDecomposition = {
    ...base,
    subGoals: [
      { label: 'Learn', features: ['qcm_generate', 'flashcard_generate'], sequence: 1, successCriteria: 'ok' },
      { label: 'Verify', features: ['mirror_analyze'], sequence: 2, successCriteria: 'ok' },
      { label: 'New targeted QCM', features: ['qcm_generate'], sequence: 3, successCriteria: 'ok' },
    ],
  };
  const recomposed = recomposeGoalProject(goal, spec, LATER);
  assert.ok(recomposed.subGoals.length === 3, 're-composition adds the new sub-goal');
  assert.equal(recomposed.recomposedAt, LATER, 're-planning is recorded');
  // History survives: the surviving sub-goal keeps its progress.
  assert.equal(recomposed.progress.subGoalProgress['sg_1'], 50);
  assert.equal(recomposed.createdAt, NOW, 'createdAt is never reset');
});
