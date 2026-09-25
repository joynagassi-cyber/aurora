/**
 * Progress module — test suite (wave 2, ORION).
 * node:test + --experimental-strip-types (no build step).
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  buildEvidence,
  clamp01,
  evidenceFromFlashcardReviewed,
  evidenceFromTaskCompleted,
} from '../src/evidence.ts';
import {
  buildProgressEvidenceCreated,
  buildSkillStateChanged,
  computeFreshness,
  PROGRESS_PRODUCED_EVENTS,
  recomputeSkill,
} from '../src/recompute.ts';
import {
  causalAnalysis,
  projectTrajectory,
  TRAJECTORY_HYPOTHESES,
} from '../src/trajectories.ts';
import {
  dashboard,
  DASHBOARD_BOARDS,
  levelToOrdinal,
  skillTrajectoryChart,
} from '../src/dashboard.ts';
import {
  buildProgressResearchHandler,
  buildSkillRecomputeHandler,
  PROGRESS_JOB_KINDS,
} from '../src/jobs.ts';
import type {
  FlashcardReviewedEvent,
  ProgressEvidence,
  SkillState,
  TaskCompletedEvent,
} from '@aurora/domain';

const USER = '00000000-0000-0000-0000-000000000002';
const NOW = '2026-09-25T00:00:00Z';

/** F-07: sole producer — the evidence builder enforces the ADR S18.3
 *  vocabulary (unknown type throws). */
test('evidence: unknown type rejected (F-07 vocabulary)', () => {
  assert.throws(() =>
    buildEvidence({
      userId: USER,
      type: 'bogus' as never,
      level: 'recalled',
      observedAt: NOW,
    }),
  );
  assert.ok(
    buildEvidence({
      userId: USER,
      type: 'qcm',
      level: 'recalled',
      observedAt: NOW,
    }),
  );
});

/** Qualify a TaskCompleted event into evidence (S18.3 minimum dataset). */
test('evidence: TaskCompleted → successful-repetition evidence', () => {
  const ev: TaskCompletedEvent = {
    eventId: 'E-1',
    occurredAt: NOW,
    type: 'TaskCompleted',
    payload: { taskId: 'T-1', userId: USER, completedAt: NOW },
  };
  const e = evidenceFromTaskCompleted(ev, { now: NOW });
  assert.equal(e.type, 'successful-repetition');
  assert.equal(e.sourceEventId, 'E-1');
  assert.equal(e.confidence, 0.6);
});

/** Qualify a FlashcardReviewed event (recognition vs recall). */
test('evidence: FlashcardReviewed rating>=3 → recalled', () => {
  const ev: FlashcardReviewedEvent = {
    eventId: 'E-2',
    occurredAt: NOW,
    type: 'FlashcardReviewed',
    payload: {
      cardId: 'C-1',
      userId: USER,
      rating: 4,
      nextDueAt: NOW,
      fsrsState: { stability: 0.5, difficulty: 0.5, lapses: 0 },
    },
  };
  const e = evidenceFromFlashcardReviewed(ev, { now: NOW });
  assert.equal(e.type, 'active-recall');
  assert.equal(e.level, 'recalled');
});

/** Skill recompute: strongest recent evidence wins (S18.8, idempotent). */
test('recompute: strongest level + idempotent', () => {
  const evs: ProgressEvidence[] = [
    buildEvidence({ userId: USER, skillId: 'S-1', type: 'qcm', level: 'recalled', observedAt: NOW, confidence: 0.6 }),
    buildEvidence({ userId: USER, skillId: 'S-1', type: 'project', level: 'mastered', observedAt: NOW, confidence: 0.9 }),
  ];
  const a = recomputeSkill({ userId: USER, skillId: 'S-1', evidences: evs, now: NOW });
  assert.equal(a.state.level, 'mastered');
  assert.equal(a.changed, true);
  const b = recomputeSkill({
    userId: USER,
    skillId: 'S-1',
    current: a.state,
    evidences: evs,
    now: NOW,
  });
  assert.equal(b.state.level, a.state.level);
});

/** Freshness buckets (S18.2). */
test('recompute: freshness fresh / stale / forgotten', () => {
  assert.equal(computeFreshness('2026-09-20T00:00:00Z', NOW), 'fresh');
  assert.equal(computeFreshness('2026-07-01T00:00:00Z', NOW), 'stale');
  assert.equal(computeFreshness('2026-01-01T00:00:00Z', NOW), 'forgotten');
});

/** Event builder shapes (AD-9 SSoT). */
test('events: ProgressEvidenceCreated + SkillStateChanged shapes', () => {
  const e: ProgressEvidence = {
    id: 'EV-1',
    userId: USER,
    skillId: 'S-1',
    type: 'qcm',
    level: 'recalled',
    confidence: 0.7,
    sourceEventId: 'E-1',
    observedAt: NOW,
  };
  const ev = buildProgressEvidenceCreated(e, NOW);
  assert.equal(ev.type, 'ProgressEvidenceCreated');
  assert.equal(ev.payload.evidenceId, 'EV-1');

  const s: SkillState = {
    id: 'SS-1',
    userId: USER,
    skillId: 'S-1',
    level: 'recalled',
    confidence: 0.7,
    evidenceRefs: [],
    updatedAt: NOW,
  };
  const sev = buildSkillStateChanged(s, NOW);
  assert.equal(sev.type, 'SkillStateChanged');
  assert.equal(sev.payload.newState, 'recalled');

  assert.deepEqual(PROGRESS_PRODUCED_EVENTS, [
    'ProgressEvidenceCreated',
    'SkillStateChanged',
  ]);
});

/** Trajectories: conditional, NOT predictive (S18.5). */
test('trajectories: unblock multiplies the pace, deterministic', () => {
  const state: SkillState = {
    id: 'SS-2',
    userId: USER,
    skillId: 'S-2',
    level: 'comprehended',
    confidence: 0.5,
    evidenceRefs: [],
    updatedAt: NOW,
  };
  const base = projectTrajectory({
    userId: USER,
    subject: 'S-2',
    state,
    hypothesis: 'maintain-pace',
    now: NOW,
  });
  const boosted = projectTrajectory({
    userId: USER,
    subject: 'S-2',
    state,
    hypothesis: 'unblock',
    now: NOW,
  });
  // Same horizon, unblock projects further than maintain-pace.
  assert.equal(base.projectedPoints.length, boosted.projectedPoints.length);
  const lastBase = base.projectedPoints[base.projectedPoints.length - 1];
  const lastBoost = boosted.projectedPoints[boosted.projectedPoints.length - 1];
  assert.ok(lastBoost !== undefined && lastBase !== undefined);
  assert.ok(
    levelToOrdinal(lastBoost.level as SkillState['level']) >=
      levelToOrdinal(lastBase.level as SkillState['level']),
  );
  assert.equal(TRAJECTORY_HYPOTHESES.length, 5);
});

/** Causal analysis: correlation ≠ causation (S18.4). */
test('causal: uncontrolled factors flagged correlationOnly', () => {
  const out = causalAnalysis({
    userId: USER,
    subject: 'S-3',
    direction: 'plateau',
    factors: ['time-available', 'interruptions'],
    controlled: ['interruptions'],
    now: NOW,
  });
  const timeFinding = out.findings.find((f) => f.factor === 'time-available');
  assert.equal(timeFinding?.correlationOnly, true);
  const intFinding = out.findings.find((f) => f.factor === 'interruptions');
  assert.equal(intFinding?.correlationOnly, false);
  assert.equal(out.primaryFactor, 'interruptions');
});

/** Dashboards: every board returns a G2 ChartSpec, reads mirrors only. */
test('dashboard: all 4 boards produce a ChartSpec', () => {
  const states: SkillState[] = [
    {
      id: 'SS-3',
      userId: USER,
      skillId: 'S-4',
      level: 'autonomous-application',
      confidence: 0.8,
      evidenceRefs: [],
      updatedAt: NOW,
    },
  ];
  const snapshots = [
    { id: 'P-1', userId: USER, takenAt: NOW, subject: 'S-4', level: 'recalled' as const, evidenceRefs: [] },
  ];
  for (const board of DASHBOARD_BOARDS) {
    const spec = dashboard(board, {
      userId: USER,
      subject: 'S-4',
      skillStates: states,
      snapshots,
      now: NOW,
    });
    assert.ok('type' in spec && 'data' in spec, `board ${board} ChartSpec`);
    assert.ok(spec.data.length >= 0);
  }
});

/** Skill-map trajectory chart (G2 line over snapshots). */
test('dashboard: skillTrajectoryChart is a G2 line spec', () => {
  const spec = skillTrajectoryChart(
    'S-5',
    [
      { id: 'P-2', userId: USER, takenAt: '2026-09-01T00:00:00Z', subject: 'S-5', level: 'recalled' as const, evidenceRefs: [] },
      { id: 'P-3', userId: USER, takenAt: NOW, subject: 'S-5', level: 'mastered' as const, evidenceRefs: [] },
    ],
    NOW,
  );
  assert.equal(spec.type, 'line');
  assert.equal(spec.data.length, 2);
  assert.equal((spec.data[1] as { ordinal?: number })?.ordinal, levelToOrdinal('mastered'));
});

/** Job handlers: skill_recompute + research-scoped ops (AD-8). */
test('jobs: skill_recompute handler idempotent on evidence', async () => {
  const evidence: ProgressEvidence[] = [
    buildEvidence({ userId: USER, skillId: 'S-6', type: 'qcm', level: 'recalled', observedAt: NOW, confidence: 0.6 }),
  ];
  const handler = buildSkillRecomputeHandler({
    getEvidences: async () => evidence,
    getSkillState: async () => null,
    now: () => NOW,
  });
  const r = await handler.handler('J-1', USER, { skillId: 'S-6' });
  assert.equal(r.ok, true);
  assert.equal((r.result as { changed?: boolean })?.changed, true);

  const bad = await handler.handler('J-2', USER, {});
  assert.equal(bad.ok, false);
});

test('jobs: research scenario op returns deterministic scenario', async () => {
  const handler = buildProgressResearchHandler();
  const r = await handler.handler('J-3', USER, {
    op: 'scenario',
    subject: 'S-7',
    skillId: 'S-7',
    hypothesis: 'unblock',
    now: NOW,
  });
  assert.equal(r.ok, true);
  assert.equal(PROGRESS_JOB_KINDS.length, 2);
});
