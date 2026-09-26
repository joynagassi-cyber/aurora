/**
 * Agent goal capabilities tests (wave 3, HEPHAESTUS task 4: the 7 goal.*
 * commands). The kernel NEVER writes a module table (AD-7): every tool
 * emits a typed `goal.*` command; the Progress module owns `user_goals`
 * and applies the mutation. The registry must DISCOVER the 7 capabilities
 * (kernel S14: typed discovery, not a hardcoded branch).
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import { DefaultCapabilityRegistry } from '../src/capability.ts';
import {
  goalAbandon,
  goalComplete,
  goalCreate,
  goalFeatureAdd,
  goalFeatureRemove,
  goalPause,
  goalRecompose,
  goalStatus,
} from '../src/tools.ts';

const registry = new DefaultCapabilityRegistry();

test('the 7 goal capabilities are registered in the kernel registry', () => {
  const ids = [
    'goal.create',
    'goal.status',
    'goal.recompose',
    'goal.pause',
    'goal.complete',
    'goal.abandon',
    'goal.feature.add',
    'goal.feature.remove',
  ];
  for (const id of ids) {
    const entry = registry.get(id);
    assert.ok(entry, `capability missing: ${id}`);
    assert.equal(entry.destructive, false, `${id} must be non-destructive (AD-15: data never destroyed)`);
  }
});

test('goal.create + goal.recompose require confirmation (CONFIRMATION_REQUIRED, dynamic-goal-engine.md)', () => {
  assert.equal(registry.get('goal.create')?.requiresConfirmation, true);
  assert.equal(registry.get('goal.recompose')?.requiresConfirmation, true);
  assert.equal(registry.get('goal.pause')?.requiresConfirmation, true);
  assert.equal(registry.get('goal.abandon')?.requiresConfirmation, true);
  // read-only + low-stakes mutations do not.
  assert.equal(registry.get('goal.status')?.requiresConfirmation, false);
  assert.equal(registry.get('goal.feature.add')?.requiresConfirmation, false);
});

test('every goal tool emits a typed command (AD-7: kernel never writes a module table)', async () => {
  const cases: Array<() => Promise<unknown>> = [
    () => goalCreate.execute({ objective: 'ml', goalDecomposition: {} }, {} as never, undefined as never),
    () => goalStatus.execute({ goalId: 'g1' }, {} as never, undefined as never),
    () => goalRecompose.execute({ goalId: 'g1', goalDecomposition: {} }, {} as never, undefined as never),
    () => goalPause.execute({ goalId: 'g1' }, {} as never, undefined as never),
    () => goalComplete.execute({ goalId: 'g1' }, {} as never, undefined as never),
    () => goalAbandon.execute({ goalId: 'g1' }, {} as never, undefined as never),
    () => goalFeatureAdd.execute({ goalId: 'g1', featureId: 'qcm_generate' }, {} as never, undefined as never),
    () => goalFeatureRemove.execute({ goalId: 'g1', featureId: 'focus_session' }, {} as never, undefined as never),
  ];
  const expected = [
    'goal.create',
    'goal.status',
    'goal.recompose',
    'goal.pause',
    'goal.complete',
    'goal.abandon',
    'goal.feature.add',
    'goal.feature.remove',
  ];
  for (let i = 0; i < cases.length; i++) {
    const result = (await cases[i]()) as { ok: boolean; command: string };
    assert.equal(result.ok, true);
    assert.equal(result.command, expected[i]);
  }
});
