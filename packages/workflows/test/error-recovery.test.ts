import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  ERROR_CLASSES, ERROR_CLASS_IDS, errorClassById,
} from '../src/index.ts';

/** Task 5: the 10 error-recovery classes (E1..E10, docs/agent/error-recovery.md
 *  S64) — each pins the four recovery questions + needs-confirmation flag,
 *  covering partial execution (E9) and rollback semantics (E10/E7). */

test('ERROR_CLASSES: 10 classes E1..E10, each complete', () => {
  assert.equal(ERROR_CLASSES.length, 10);
  for (let i = 1; i <= 10; i++) {
    assert.ok(ERROR_CLASS_IDS.includes(`E${i}` as never), `missing E${i}`);
  }
  for (const e of ERROR_CLASSES) {
    assert.ok(e.title.length > 0, `${e.id} title empty`);
    assert.ok(e.whatHappened.length > 0, `${e.id} whatHappened empty`);
    assert.ok(e.executed.length > 0, `${e.id} executed empty`);
    assert.ok(e.notExecuted.length > 0, `${e.id} notExecuted empty`);
    assert.ok(e.retryable.length > 0, `${e.id} retryable empty`);
    assert.ok(e.recovery.length > 0, `${e.id} recovery empty`);
    assert.equal(typeof e.needsConfirmation, 'boolean', `${e.id} confirmation type`);
  }
});

test('ERROR_CLASSES: confirmation gating matches ADR S5', () => {
  // needs confirmation: E2 (grant permission), E4 (re-login), E5 (re-enable),
  // E8 (conflict resolution), E9 (irreversible step), E10 (destructive retry)
  for (const id of ['E2', 'E4', 'E5', 'E8', 'E9', 'E10'] as const) {
    assert.equal(errorClassById(id)?.needsConfirmation, true, `${id} must confirm`);
  }
  // no confirmation: E1 (auto fallback), E3 (auto upsync), E6 (auto degrade), E7
  for (const id of ['E1', 'E3', 'E6', 'E7'] as const) {
    assert.equal(errorClassById(id)?.needsConfirmation, false, `${id} auto-recover`);
  }
});

test('E9 partial execution: exact completion boundary is recorded', () => {
  const e9 = errorClassById('E9');
  assert.ok(e9, 'E9 exists');
  assert.match(e9!.recovery, /step 4/);
  assert.match(e9!.executed, /steps 1-3/);
  assert.match(e9!.notExecuted, /steps 4-5/);
});

test('E10 destructive rollback: transaction rolled back, re-confirm required', () => {
  const e10 = errorClassById('E10');
  assert.match(e10!.executed, /rolled back/);
  assert.match(e10!.recovery, /re-confirmation/);
});
