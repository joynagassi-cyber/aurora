import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  classifyPlanError, replanPartial,
  type PlanStep,
} from '../src/index.ts';

/** Task 5b: plan-level recovery — partial execution + rollback decisions
 *  (docs/agent/error-recovery.md S64, AD-8 idempotent re-dispatch). */

const PLAN: readonly PlanStep[] = [
  { id: 's1', durable: true, jobKind: 'agent_run' },
  { id: 's2', durable: true, jobKind: 'artifact_gen', compensates: 's1' },
  { id: 's3', important: true, jobKind: 'agent_run' },
];

test('replanPartial: E1 transient 5xx retries within the AD-8 attempt budget', () => {
  const d = replanPartial(PLAN, {
    stepId: 's2', kind: 'provider_5xx', attempts: 1,
  });
  assert.equal(d.errorClass, 'E1');
  assert.equal(d.retryStep, true);
  assert.equal(d.attemptsLeft, 2);
  assert.equal(d.resumeFromStep, 's2');
  assert.equal(d.needsConfirmation, false);
  assert.equal(d.jobKind, 'artifact_gen');
  assert.deepEqual(d.compensations, []);
});

test('replanPartial: E1 budget exhausted -> no retry, no rollback, no confirmation', () => {
  const d = replanPartial(PLAN, {
    stepId: 's2', kind: 'provider_429', attempts: 3,
  });
  assert.equal(d.errorClass, 'E1');
  assert.equal(d.retryStep, false);
  assert.equal(d.needsConfirmation, false);
  // resume point moves to the next surviving step (s3), s1 compensation
  // NOT triggered (transient class, no rollback of earlier durable work).
  assert.equal(d.resumeFromStep, 's3');
});

test('replanPartial: E2 permission failure pauses + confirms, rolls back the invalidated step', () => {
  const d = replanPartial(PLAN, { stepId: 's2', kind: 'permission_denied' });
  assert.equal(d.errorClass, 'E2');
  assert.equal(d.retryStep, false);
  assert.equal(d.needsConfirmation, true);
  // s2's compensates edge: s1's durable side effect is invalidated.
  assert.deepEqual(d.compensations, ['s1']);
});

test('replanPartial: E3 offline -> auto-reschedule on restore (transient, no confirmation)', () => {
  const d = replanPartial(PLAN, { stepId: 's2', kind: 'offline', attempts: 0 });
  assert.equal(d.errorClass, 'E3');
  assert.equal(d.retryStep, true, 'network restore resumes from the first pending step');
  assert.equal(d.resumeFromStep, 's2');
  assert.equal(d.needsConfirmation, false);
  assert.deepEqual(d.compensations, [], 'offline does not roll back completed local work');
});

test('replanPartial: E7 schema mismatch -> degrade, no confirmation', () => {
  const d = replanPartial(PLAN, { stepId: 's2', kind: 'schema_mismatch' });
  assert.equal(d.errorClass, 'E7');
  assert.equal(d.needsConfirmation, false);
});

test('replanPartial: E10 destructive constraint failure -> full rollback + re-confirmation', () => {
  const plan: readonly PlanStep[] = [
    { id: 'del-tasks', durable: true, important: true, jobKind: 'agent_run' },
    { id: 'del-project', important: true, jobKind: 'agent_run' },
  ];
  const d = replanPartial(plan, { stepId: 'del-project', kind: 'constraint_violation' });
  assert.equal(d.errorClass, 'E10');
  assert.equal(d.needsConfirmation, true);
  assert.equal(d.retryStep, false);
  assert.match(d.summary, /confirmation required/);
});

test('classifyPlanError: maps every failure kind to the right class', () => {
  const cases: Array<[Parameters<typeof classifyPlanError>[0]['kind'], string]> = [
    ['provider_5xx', 'E1'],
    ['timeout', 'E1'],
    ['permission_denied', 'E2'],
    ['offline', 'E3'],
    ['auth_expired', 'E4'],
    ['feature_disabled', 'E5'],
    ['tool_unavailable', 'E6'],
    ['schema_mismatch', 'E7'],
    ['conflict', 'E8'],
    ['constraint_violation', 'E10'],
  ];
  for (const [kind, id] of cases) {
    assert.equal(classifyPlanError({ stepId: 's1', kind }), id, `kind ${kind}`);
  }
});
