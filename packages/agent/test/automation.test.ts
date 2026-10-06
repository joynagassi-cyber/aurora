/**
 * Automation (veille) tools G1–G3 (feature-agentique plan 2026-10-06).
 *
 * AD-7: the kernel NEVER writes a module table — each tool EMITS a typed
 * `integrations.automation_*` command; the Integrations module owns
 * `automations` (0008) + applies the mutation.
 *
 *  - G1 create_automation  (3 triggers: schedule / event / condition;
 *    jobKind constrained to the AD-15 closed vocabulary, unknown kind
 *    degrades to `notification` — AD-1 optional capability).
 *  - G2 update_automation  (rename / reprogram / lock; verrouiller =
 *    enabled:false, reversible → non-destructive).
 *  - G3 delete_automation  (DESTRUCTIVE, ADR §5: requiresConfirmation).
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import { KERNEL_TOOLS, DefaultCapabilityRegistry } from '../src/index.ts';
import {
  createAutomation,
  deleteAutomation,
  updateAutomation,
} from '../src/tools.ts';

const reg = new DefaultCapabilityRegistry();

// ---------------------------------------------------------------------------
// G1 — create_automation
// ---------------------------------------------------------------------------

test('G1: create_automation est dans KERNEL_TOOLS et résolu via byTool', () => {
  assert.ok('create_automation' in KERNEL_TOOLS);
  assert.ok(reg.byTool('create_automation'), 'capability byTool');
  assert.equal(
    reg.get('integrations.automation.create')?.writeScopes[0],
    'integrations:write',
  );
});

test('G1: flags registry (non-destructif, pas de confirmation)', () => {
  const e = reg.get('integrations.automation.create');
  assert.equal(e?.destructive, false);
  assert.equal(e?.requiresConfirmation, false);
});

test('G1: create_automation émet integrations.automation_create pour les 3 triggers (AD-7)', async () => {
  for (const trigger of ['schedule', 'event', 'condition'] as const) {
    const r = (await createAutomation.execute(
      {
        name: 'veille IA',
        trigger,
        schedule: '0 9 * * 4',
        triggerEvent: 'CourseCompleted',
        condition: 'energy < low',
        jobKind: 'research',
        action: 'LLM agents',
        userId: 'u1',
      },
      {} as never,
      undefined as never,
    )) as { ok: boolean; command: string; payload: Record<string, unknown> };
    assert.equal(r.ok, true);
    assert.equal(r.command, 'integrations.automation_create');
    assert.equal(r.payload.trigger, trigger);
    assert.equal(r.payload.name, 'veille IA');
    assert.equal(r.payload.jobKind, 'research');
  }
});

test('G1: le payload filtre les champs incohérents avec le trigger choisi', async () => {
  // trigger 'condition' → schedule / triggerEvent ne figurent pas.
  const c = (await createAutomation.execute(
    {
      name: 'x',
      trigger: 'condition',
      schedule: '0 9 * * 4',
      triggerEvent: 'CourseCompleted',
      condition: 'energy < low',
      userId: 'u1',
    },
    {} as never,
    undefined as never,
  )) as { payload: Record<string, unknown> };
  assert.equal(c.payload.condition, 'energy < low');
  assert.equal(c.payload.schedule, undefined);
  assert.equal(c.payload.triggerEvent, undefined);

  const s = (await createAutomation.execute(
    { name: 'x', trigger: 'schedule', schedule: '0 9 * * 4', userId: 'u1' },
    {} as never,
    undefined as never,
  )) as { payload: Record<string, unknown> };
  assert.equal(s.payload.schedule, '0 9 * * 4');
  assert.equal(s.payload.triggerEvent, undefined);
  assert.equal(s.payload.condition, undefined);
});

test('G1: jobKind restreint au vocabulaire fermé AD-15 (isJobKind; inconnu → notification)', async () => {
  const r = (await createAutomation.execute(
    { name: 'x', trigger: 'schedule', jobKind: 'not-a-kind', userId: 'u1' },
    {} as never,
    undefined as never,
  )) as { payload: { jobKind: string } };
  assert.equal(r.payload.jobKind, 'notification');

  // un kind valide passe intact.
  const r2 = (await createAutomation.execute(
    { name: 'x', trigger: 'schedule', jobKind: 'research', userId: 'u1' },
    {} as never,
    undefined as never,
  )) as { payload: { jobKind: string } };
  assert.equal(r2.payload.jobKind, 'research');
});

// ---------------------------------------------------------------------------
// G2 — update_automation
// ---------------------------------------------------------------------------

test('G2: update_automation est dans KERNEL_TOOLS + registry (non-destructif, pas de confirmation)', () => {
  assert.ok('update_automation' in KERNEL_TOOLS);
  const e = reg.get('integrations.automation.update');
  assert.ok(e, 'capability byTool');
  assert.equal(e?.destructive, false);
  assert.equal(e?.requiresConfirmation, false);
});

test('G2: update_automation patche name/cron/action/enabled (verrouiller = enabled:false)', async () => {
  const r = (await updateAutomation.execute(
    { automationId: 'a1', patch: { name: 'Veille IA', enabled: false }, userId: 'u1' },
    {} as never,
    undefined as never,
  )) as { ok: boolean; command: string; payload: { patch: Record<string, unknown> } };
  assert.equal(r.ok, true);
  assert.equal(r.command, 'integrations.automation_update');
  assert.deepEqual(r.payload.patch, { name: 'Veille IA', enabled: false });
});

// ---------------------------------------------------------------------------
// G3 — delete_automation (DESTRUCTIVE, ADR §5)
// ---------------------------------------------------------------------------

test('G3: delete_automation est destructive + requiresConfirmation (ADR §5)', () => {
  assert.ok('delete_automation' in KERNEL_TOOLS);
  assert.equal(reg.get('integrations.automation.delete')?.destructive, true);
  assert.equal(reg.get('integrations.automation.delete')?.requiresConfirmation, true);
});

test('G3: delete_automation émet integrations.automation_delete', async () => {
  const r = (await deleteAutomation.execute(
    { automationId: 'a1', userId: 'u1' },
    {} as never,
    undefined as never,
  )) as { ok: boolean; command: string; payload: { automationId: string } };
  assert.equal(r.ok, true);
  assert.equal(r.command, 'integrations.automation_delete');
  assert.equal(r.payload.automationId, 'a1');
});
