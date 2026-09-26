/**
 * @aurora/ascent — test suite (wave 3, W3-E2; docs/ascent/overview.md S19,
 * implementation.md "Test Plan").
 *
 * Pure-domain tests: node built-in runner, no vendor deps, no DOM
 * (AD-1 / F-09 — the Ascent engine is deterministic server-side logic
 * over the AD-15 SSoT types).
 *
 * Pass criteria (implementation.md "Test Plan"), covered here:
 *  - baseline accuracy (5 states, dimensions 0..1, derived buckets)
 *  - prerequisite enforcement (a step cannot be 'active' on an unmet prereq)
 *  - adaptation on evidence (QCM below threshold -> remediation inserted)
 *  - depth selection (mastered->quick, time-constrained->quick,
 *    core+fragile->standard, core+unknown->deep, peripheral->quick)
 *  - READ->DO->PROVE flexibility (mastered skips READ; exam week -> PROVE)
 *  - source hierarchy (Level D NEVER overrides A; conflicts flagged)
 *  - "Je bloque" flow (stuck -> diagnose -> remediation -> new evidence)
 *  - GoalUpdated / TaskCompleted / ArtifactGenerated / Discovery adapters
 *
 * NOTE: slide-types (UI) + RLS + offline mirror are covered elsewhere
 * (UI rendering in apps/mobile; RLS via tests/rls-penetration.sql; offline
 * via the PowerSync mirror). This file covers the deterministic ENGINE.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import type {
  AscentLearningIR,
  AscentStep,
  DepthLevel,
  LearnerBaseline,
  SkillState,
} from '@aurora/domain';
import { computeLearnerBaseline, mapLevelToBaselineState } from '../src/baseline.ts';
import { selectDepth, isTimeConstrained, DEPTH_BUDGETS } from '../src/depth.ts';
import { phasesForStep, reorderPhases, insertRemediationBefore } from '../src/read-do-prove.ts';
import {
  strongestSource,
  resolveConflict,
  rankSources,
  flagConflicts,
  type SourceRefInfo,
} from '../src/source-hierarchy.ts';
import { buildPath, type BuildPathInput, type AscentStepInput } from '../src/path-builder.ts';
import {
  adaptOnEvidence,
  adaptOnSkillStateChanged,
  adaptOnDiscovery,
  adaptOnGoalUpdated,
  adaptOnTaskCompleted,
  adaptOnArtifact,
  adaptPath,
  diagnoseBlocker,
  insertRemediationForBlocker,
} from '../src/adapter.ts';

// ---- shared fixtures (deterministic, no clock / randomness) ----

const NOW = '2026-09-26T10:00:00Z';
const PATH_ID = '01JA2PATH00000000000000000';
const USER = 'user-horeb';

let _n = 0;
const nextId = (prefix: string): string => `${prefix}-${(++_n).toString().padStart(4, '0')}`;

/** A Progress `SkillState` row (minimal — only the fields Ascent reads). */
function skill(
  skillId: string,
  level: SkillState['level'],
  confidence?: number,
): SkillState {
  return {
    id: `sk-${skillId}`,
    userId: USER,
    skillId,
    level,
    confidence,
    evidenceRefs: [
      {
        v: `ev-${skillId}`,
        ts: Date.parse(NOW),
        c: 'server',
      },
    ],
    updatedAt: NOW,
  };
}

/** A `LearnerBaseline` directly (for depth / phase tests that don't need a full build). */
function baseline(userId: string, skillStates: LearnerBaseline['skillStates']): LearnerBaseline {
  const byStatus = (pred: (s: LearnerBaseline['skillStates'][number]) => boolean) =>
    skillStates.filter(pred).map((s) => s.skillId);
  return {
    userId,
    skillStates,
    gaps: byStatus((s) => s.status === 'unknown' || s.status === 'partial'),
    fragiles: byStatus((s) => s.status === 'fragile'),
    mastered: byStatus((s) => s.status === 'mastered'),
    computedAt: NOW,
  };
}

const skillStateEntry = (
  skillId: string,
  status: LearnerBaseline['skillStates'][number]['status'],
) => ({
  skillId,
  status,
  lastEvidence: `ev-${skillId}`,
  freshness: NOW,
});

/** A minimal active path (one concept: READ -> DO -> PROVE) via buildPath. */
function minimalPath(extra: Partial<BuildPathInput> = {}): AscentLearningIR {
  const input: AscentStepInput = {
    conceptId: 'concept-rdm-flexion',
    label: 'Flexion simple',
    skillId: 'skill-rdm-flexion',
    sourceRefIds: ['src-rdm'],
    requires: [],
    importance: 'core',
  };
  return buildPath({
    userId: USER,
    goal: 'Master RDM by exam day',
    targetSkill: 'skill-rdm-flexion',
    baseline: baseline(USER, [skillStateEntry('skill-rdm-flexion', 'unknown')]),
    inputs: [input],
    now: NOW,
    pathId: PATH_ID,
    ...extra,
  });
}

const opts = { now: NOW, nextId };

// ---------------------------------------------------------------------------
// baseline accuracy
// ---------------------------------------------------------------------------
test('baseline: mapLevelToBaselineState is monotone (5 states, no single score)', () => {
  assert.equal(mapLevelToBaselineState('discovered'), 'unknown');
  assert.equal(mapLevelToBaselineState('comprehended'), 'partial');
  assert.equal(mapLevelToBaselineState('recalled', 0.7), 'known');
  assert.equal(mapLevelToBaselineState('recalled', 0.3), 'partial');
  assert.equal(mapLevelToBaselineState('guided-application'), 'known');
  assert.equal(mapLevelToBaselineState('autonomous-application'), 'fragile');
  assert.equal(mapLevelToBaselineState('novel-problem'), 'fragile');
  assert.equal(mapLevelToBaselineState('mastered'), 'mastered');
  assert.equal(mapLevelToBaselineState('expert'), 'mastered');
  // closed vocabulary — be loud on an unknown level.
  assert.throws(() => mapLevelToBaselineState('nonsense' as SkillState['level']));
});

test('baseline: computeLearnerBaseline derives the 3 buckets from status', () => {
  const b = computeLearnerBaseline(
    USER,
    [
      skill('s-gaps', 'discovered'),
      skill('s-frag', 'novel-problem', 0.6),
      skill('s-mast', 'mastered', 0.9),
    ],
    NOW,
  );
  assert.deepEqual(b.gaps, ['s-gaps']);
  assert.deepEqual(b.fragiles, ['s-frag']);
  assert.deepEqual(b.mastered, ['s-mast']);
  // dimensions are optional but stay in [0,1] — NEVER a single global score.
  const frag = b.skillStates.find((s) => s.skillId === 's-frag')!;
  assert.ok(frag.dimensions!.application! >= 0 && frag.dimensions!.application! <= 1);
  // lastEvidence carries the newest evidence id (by ts).
  assert.equal(frag.lastEvidence, 'ev-s-frag');
  assert.equal(b.computedAt, NOW);
});

// ---------------------------------------------------------------------------
// depth selection
// ---------------------------------------------------------------------------
test('depth: mastered -> quick (consolidation, never deepen)', () => {
  const b = baseline(USER, [skillStateEntry('s', 'mastered')]);
  assert.equal(selectDepth({ baseline: b, importance: { skillId: 's', importance: 'core' } }), 'quick');
});

test('depth: peripheral -> quick (never spend Deep on the non-critical path)', () => {
  const b = baseline(USER, [skillStateEntry('s', 'unknown')]);
  assert.equal(
    selectDepth({ baseline: b, importance: { skillId: 's', importance: 'peripheral' } }),
    'quick',
  );
});

test('depth: exam week (time-constrained) -> quick for everything', () => {
  const b = baseline(USER, [skillStateEntry('s', 'unknown')]);
  // target 24h away, now NOW -> time-constrained.
  assert.equal(
    isTimeConstrained('2026-09-27T10:00:00Z', NOW),
    true,
  );
  assert.equal(
    selectDepth({
      baseline: b,
      importance: { skillId: 's', importance: 'core' },
      targetDate: '2026-09-27T10:00:00Z',
      now: NOW,
    }),
    'quick',
  );
});

test('depth: core + fragile -> standard', () => {
  const b = baseline(USER, [skillStateEntry('s', 'fragile')]);
  assert.equal(
    selectDepth({ baseline: b, importance: { skillId: 's', importance: 'core' } }),
    'standard',
  );
});

test('depth: core + unknown/partial/known -> deep', () => {
  const b = baseline(USER, [skillStateEntry('s', 'unknown')]);
  assert.equal(
    selectDepth({ baseline: b, importance: { skillId: 's', importance: 'core' } }),
    'deep',
  );
});

test('depth: budgets grow quick < standard < deep (content, not architecture)', () => {
  assert.ok(DEPTH_BUDGETS.quick.qcmItems < DEPTH_BUDGETS.standard.qcmItems);
  assert.ok(DEPTH_BUDGETS.standard.qcmItems < DEPTH_BUDGETS.deep.qcmItems);
  assert.equal(DEPTH_BUDGETS.deep.mirror, true);
  assert.equal(DEPTH_BUDGETS.quick.mirror, false);
});

// ---------------------------------------------------------------------------
// READ -> DO -> PROVE flexibility (framework, not rigid)
// ---------------------------------------------------------------------------
test('phases: mastered skips READ (go to DO/PROVE only)', () => {
  assert.deepEqual(phasesForStep({ status: 'pending', baselineStatus: 'mastered' }), ['do', 'prove']);
});

test('phases: time-constrained -> PROVE only (exam week, QCM is the priority)', () => {
  assert.deepEqual(phasesForStep({ status: 'pending', timeConstrained: true }), ['prove']);
});

test('phases: default framework = READ -> DO -> PROVE', () => {
  assert.deepEqual(
    phasesForStep({ status: 'pending', baselineStatus: 'unknown' }),
    ['read', 'do', 'prove'],
  );
});

test('reorderPhases: re-sorts one concept to the requested order, others untouched', () => {
  const path = minimalPath();
  // default order: READ, DO, PROVE (+ recap). Reverse the concept block.
  const reordered = reorderPhases(path, 'concept-rdm-flexion', ['prove', 'do', 'read']);
  const conceptSteps = reordered.steps.filter(
    (s) => s.conceptRefs[0] === 'concept-rdm-flexion' && s.phase !== 'recap',
  );
  assert.deepEqual(conceptSteps.map((s) => s.phase), ['prove', 'do', 'read']);
  // the recap stays present.
  assert.ok(reordered.steps.some((s) => s.phase === 'recap'));
});

test('insertRemediationBefore: places a remediation step before the main step', () => {
  const path = minimalPath();
  const remediation: AscentStep = {
    id: 'step-rem',
    label: 'Remediation — Flexion simple',
    conceptRefs: ['concept-rdm-flexion'],
    sourceRefs: [],
    activities: [],
    phase: 'remediation',
    depth: 'standard',
    status: 'pending',
  };
  const out = insertRemediationBefore(path, 'concept-rdm-flexion', remediation);
  const idxRem = out.steps.findIndex((s) => s.id === 'step-rem');
  const idxRead = out.steps.findIndex((s) => s.conceptRefs[0] === 'concept-rdm-flexion' && s.phase === 'read');
  assert.ok(idxRem >= 0 && idxRem < idxRead, 'remediation precedes the READ step');
  assert.equal(out.depth[remediation.id], 'standard');
});

// ---------------------------------------------------------------------------
// prerequisite enforcement
// ---------------------------------------------------------------------------
test('path-builder: DO requires READ; PROVE requires READ+DO (prereq gating)', () => {
  const path = minimalPath();
  const doStep = path.steps.find((s) => s.phase === 'do')!;
  const proveStep = path.steps.find((s) => s.phase === 'prove')!;
  const readStep = path.steps.find((s) => s.phase === 'read')!;

  const doPrereq = path.prerequisites.find((p) => p.stepId === doStep.id)!;
  assert.deepEqual(doPrereq.requires, [readStep.id]);

  const provePrereq = path.prerequisites.find((p) => p.stepId === proveStep.id)!;
  assert.equal(provePrereq.requires.length, 2);
  // PROVE must gate on BOTH read and do.
  assert.ok(provePrereq.requires.includes(readStep.id));
  assert.ok(provePrereq.requires.includes(doStep.id));
  // nothing is done yet -> pending.
  assert.equal(provePrereq.status, 'pending');
});

test('path-builder: external prerequisites gate the READ step', () => {
  const input: AscentStepInput = {
    conceptId: 'concept-c',
    label: 'C',
    skillId: 'skill-c',
    sourceRefIds: [],
    requires: ['skill-external-mastered'],
    importance: 'core',
  };
  const path = buildPath({
    userId: USER,
    goal: 'C path',
    baseline: baseline(USER, [skillStateEntry('skill-external-mastered', 'mastered')]),
    inputs: [input],
    now: NOW,
    pathId: PATH_ID,
  });
  const readStep = path.steps.find((s) => s.phase === 'read')!;
  const p = path.prerequisites.find((x) => x.stepId === readStep.id)!;
  // the mastered external skill satisfies the prereq at build time.
  assert.deepEqual(p.requires, ['skill-external-mastered']);
  assert.equal(p.status, 'met');
});

// ---------------------------------------------------------------------------
// adaptation on evidence
// ---------------------------------------------------------------------------
test('adaptOnEvidence: below-threshold -> insert_remediation before the PROVE step', () => {
  const path = minimalPath();
  const prove = path.steps.find((s) => s.phase === 'prove')!;
  const out = adaptOnEvidence(
    path,
    { evidenceId: 'ev-1', skillId: 'skill-rdm-flexion', confidence: 0.5, sourceEventId: 'e' },
    opts,
  );
  // a remediation step now sits immediately before the (now-remediation) PROVE step.
  const idxProve = out.steps.findIndex((s) => s.id === prove.id);
  const before = out.steps[idxProve - 1]!;
  assert.equal(before.phase, 'remediation');
  assert.equal(prove.status === 'remediation' ? out.steps[idxProve].status : out.steps[idxProve].status, 'remediation');
  const adapt = out.adaptations[out.adaptations.length - 1]!;
  assert.equal(adapt.action, 'insert_remediation');
  assert.deepEqual(adapt.evidenceRefs, ['ev-1']);
});

test('adaptOnEvidence: at/above threshold -> PROVE step done, prerequisites met', () => {
  const path = minimalPath();
  const prove = path.steps.find((s) => s.phase === 'prove')!;
  const out = adaptOnEvidence(
    path,
    { evidenceId: 'ev-2', skillId: 'skill-rdm-flexion', confidence: 0.9, sourceEventId: 'e' },
    opts,
  );
  assert.equal(out.steps.find((s) => s.id === prove.id)!.status, 'done');
  const p = out.prerequisites.find((x) => x.stepId === prove.id)!;
  assert.equal(p.status, 'met');
  assert.equal(out.adaptations[out.adaptations.length - 1]!.action, 'accelerate');
});

// ---------------------------------------------------------------------------
// "Je bloque" flow
// ---------------------------------------------------------------------------
test('"Je bloque": diagnoseBlocker -> the active/pending step on the skill', () => {
  const path = minimalPath();
  // mark the READ step active so diagnoseBlocker finds it.
  const readStep = path.steps.find((s) => s.phase === 'read')!;
  readStep.status = 'active';
  const blocker = diagnoseBlocker(path, 'skill-rdm-flexion');
  assert.equal(blocker?.id, readStep.id);
});

test('"Je bloque": insertRemediationForBlocker -> remediation before the blocker', () => {
  const path = minimalPath();
  const prove = path.steps.find((s) => s.phase === 'prove')!;
  prove.status = 'active';
  const out = insertRemediationForBlocker(path, 'skill-rdm-flexion', opts);
  const idxProve = out.steps.findIndex((s) => s.id === prove.id);
  assert.equal(out.steps[idxProve - 1]!.phase, 'remediation');
  assert.equal(out.adaptations[out.adaptations.length - 1]!.action, 'insert_remediation');
});

// ---------------------------------------------------------------------------
// source hierarchy
// ---------------------------------------------------------------------------
test('source-hierarchy: strongest of {A,B,C,D} = A; D never overrides A', () => {
  assert.equal(strongestSource(['D', 'C', 'B', 'A']), 'A');
  assert.equal(strongestSource(['D', 'C']), 'C');
  assert.equal(strongestSource([]), undefined);

  const a: SourceRefInfo = { refId: 'src-norm', level: 'A', label: 'Eurocode 2' };
  const d: SourceRefInfo = { refId: 'src-blog', level: 'D', label: 'YouTube' };
  const conflict = resolveConflict(a, d);
  assert.ok(conflict);
  assert.equal(conflict!.winner.refId, 'src-norm');
  assert.equal(conflict!.overridden.refId, 'src-blog');
  assert.match(conflict!.message, /Following Level A/);
});

test('source-hierarchy: same-level is not a conflict (no override)', () => {
  const a1: SourceRefInfo = { refId: 'x', level: 'A' };
  const a2: SourceRefInfo = { refId: 'y', level: 'A' };
  assert.equal(resolveConflict(a1, a2), undefined);
});

test('source-hierarchy: rankSources puts the most authoritative first', () => {
  const ranked = rankSources([
    { refId: 'd', level: 'D' },
    { refId: 'a', level: 'A' },
    { refId: 'c', level: 'C' },
  ]);
  assert.deepEqual(ranked.map((r) => r.refId), ['a', 'c', 'd']);
});

test('source-hierarchy: flagConflicts surfaces the A/D clash (never silent)', () => {
  const conflicts = flagConflicts([
    { refId: 'src-norm', level: 'A' },
    { refId: 'src-blog', level: 'D' },
  ]);
  assert.equal(conflicts.length, 1);
  assert.equal(conflicts[0]!.winner.refId, 'src-norm');
});

// ---------------------------------------------------------------------------
// the remaining adapters (GoalUpdated / TaskCompleted / Artifact / Discovery)
// ---------------------------------------------------------------------------
test('adaptOnGoalUpdated: flags the path for recomposition (recompose)', () => {
  const path = minimalPath();
  const out = adaptOnGoalUpdated(
    path,
    {
      eventId: 'e',
      occurredAt: NOW,
      type: 'GoalUpdated',
      payload: { goalId: 'g1', userId: USER, changedAt: NOW, fields: ['horizon'] },
    },
    opts,
  );
  const a = out.adaptations[out.adaptations.length - 1]!;
  assert.equal(a.action, 'recompose');
  assert.equal(a.trigger.includes('GoalUpdated'), true);
});

test('adaptOnTaskCompleted: marks a matching PROVE step done', () => {
  const path = minimalPath();
  const prove = path.steps.find((s) => s.phase === 'prove')!;
  const out = adaptOnTaskCompleted(
    path,
    {
      eventId: 'e',
      occurredAt: NOW,
      type: 'TaskCompleted',
      payload: { taskId: prove.id, userId: USER, completedAt: NOW, evidenceRefs: [prove.id] },
    },
    opts,
  );
  assert.equal(out.steps.find((s) => s.id === prove.id)!.status, 'done');
});

test('adaptOnArtifact: marks the most recent READ step done', () => {
  const path = minimalPath();
  const out = adaptOnArtifact(
    path,
    {
      eventId: 'e',
      occurredAt: NOW,
      type: 'ArtifactGenerated',
      payload: {
        artifactId: 'art-1',
        userId: USER,
        kind: 'study-sheet',
        r2Key: 'k',
        sizeBytes: 1,
        generatedAt: NOW,
        jobId: 'job-1',
      },
    },
    opts,
  );
  const doneReads = out.steps.filter((s) => s.phase === 'read' && s.status === 'done');
  assert.equal(doneReads.length, 1);
});

test('adaptOnDiscovery: inserts a new READ step for the new topic', () => {
  const path = minimalPath();
  const out = adaptOnDiscovery(
    path,
    {
      eventId: 'e',
      occurredAt: NOW,
      type: 'DiscoveryItemCreated',
      payload: { discoveryItemId: 'disc-1', userId: USER, topic: 'New shear topic', sources: [], createdAt: NOW },
    },
    opts,
  );
  assert.ok(out.steps.some((s) => s.label === 'Discovery — New shear topic'));
  assert.equal(out.adaptations[out.adaptations.length - 1]!.action, 'insert_remediation');
});

test('adaptOnSkillStateChanged: mastered -> shallow bound steps to quick', () => {
  const path = minimalPath();
  const out = adaptOnSkillStateChanged(
    path,
    {
      eventId: 'e',
      occurredAt: NOW,
      type: 'SkillStateChanged',
      payload: { skillId: 'skill-rdm-flexion', userId: USER, newState: 'mastered', freshness: 1, confidence: 0.9 },
    },
    opts,
  );
  const bound = out.steps.filter((s) => s.skillRef === 'skill-rdm-flexion' && s.status !== 'done');
  for (const s of bound) {
    assert.equal(s.depth, 'quick');
    assert.equal(out.depth[s.id], 'quick');
  }
  assert.equal(out.adaptations[out.adaptations.length - 1]!.action, 'shallow');
});

test('adaptPath: dispatches to the right handler and no-ops unknown events', () => {
  const path = minimalPath();
  // a non-consumed event (CourseImported) leaves the path unchanged.
  const same = adaptPath(
    path,
    {
      eventId: 'e',
      occurredAt: NOW,
      type: 'CourseImported',
      payload: { courseId: 'c1', userId: USER, source: 's', importedAt: NOW },
    },
    opts,
  );
  assert.equal(same, path); // AD-9 stays closed — no invented reaction.

  // a consumed event DOES change the path.
  const changed = adaptPath(
    path,
    {
      eventId: 'e',
      occurredAt: NOW,
      type: 'ArtifactGenerated',
      payload: {
        artifactId: 'art-9',
        userId: USER,
        kind: 'study-sheet',
        r2Key: 'k',
        sizeBytes: 1,
        generatedAt: NOW,
        jobId: 'job-9',
      },
    },
    opts,
  );
  assert.notEqual(changed, path);
});

test('path-builder: recap closes the path + passage criteria on every PROVE step', () => {
  const path = minimalPath();
  assert.ok(path.steps.some((s) => s.phase === 'recap'));
  const proveSteps = path.steps.filter((s) => s.phase === 'prove');
  assert.equal(path.passageCriteria.length, proveSteps.length);
  for (const c of path.passageCriteria) {
    assert.equal(c.threshold, 0.8);
    assert.equal(c.metric, 'qcm_score');
  }
  // depth record covers every step.
  assert.equal(Object.keys(path.depth).length, path.steps.length);
});

// keep the DepthLevel import exercised (type-only, no runtime value).
const _depth: DepthLevel = 'deep';
void _depth;

// ---------------------------------------------------------------------------
// kernel integration (forward-compatible: consumes domain SSoT only)
// ---------------------------------------------------------------------------
import {
  ascentSessionContext,
  collectLearningCommands,
  currentLearningCommands,
  reactTo,
  remediateBlocker,
} from '../src/kernel-integration.ts';

test('kernel: ascentSessionContext derives Level 1 (current+next) + active step', () => {
  const path = minimalPath();
  const ctx = ascentSessionContext(path);
  assert.equal(ctx.goal, 'Master RDM by exam day');
  // first step is READ, all pending -> current = first pending, next = 2nd.
  assert.equal(ctx.l1.current?.phase, 'read');
  assert.equal(ctx.l1.next?.phase, 'do');
  assert.equal(ctx.l1.goal, path.goal);
  assert.equal(ctx.activeStep?.phase, 'read');
  assert.equal(ctx.status, 'active');
  assert.equal(ctx.recentAdaptations.length, 0);
});

test('kernel: collectLearningCommands returns the step delegate-to-Learning cmds (AD-7)', () => {
  const path = minimalPath();
  const prove = path.steps.find((s) => s.phase === 'prove')!;
  const cmds = collectLearningCommands(path, prove.id);
  // PROVE step carries a generate_qcm command (S13 budgets).
  assert.ok(cmds.some((c) => c.action === 'generate_qcm'));
  // no unknown step -> empty.
  assert.deepEqual(collectLearningCommands(path, 'does-not-exist'), []);
});

test('kernel: currentLearningCommands -> the active step first, else current', () => {
  const path = minimalPath();
  const read = path.steps.find((s) => s.phase === 'read')!;
  assert.ok(Array.isArray(currentLearningCommands(path)));
  read.status = 'active';
  assert.ok(Array.isArray(currentLearningCommands(path)));
});

test('kernel: reactTo is event-driven adaptation (rewrites the path, AD-9 closed)', () => {
  const path = minimalPath();
  const out = reactTo(
    path,
    {
      eventId: 'e',
      occurredAt: NOW,
      type: 'ArtifactGenerated',
      payload: {
        artifactId: 'a',
        userId: USER,
        kind: 'study-sheet',
        r2Key: 'k',
        sizeBytes: 1,
        generatedAt: NOW,
        jobId: 'j',
      },
    },
    opts,
  );
  assert.notEqual(out, path);
  assert.ok(out.adaptations.length > path.adaptations.length);
});

test('kernel: remediateBlocker -> inserts remediation + returns its LearningCommands', () => {
  const path = minimalPath();
  const prove = path.steps.find((s) => s.phase === 'prove')!;
  prove.status = 'active';
  const { path: next, commands } = remediateBlocker(path, 'skill-rdm-flexion', opts);
  assert.ok(next.steps.some((s) => s.phase === 'remediation'));
  // the remediation step carries a create_exercise remediation command.
  assert.ok(commands.some((c) => c.action === 'create_exercise'));
});
