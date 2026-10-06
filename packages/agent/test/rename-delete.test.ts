/**
 * G4 / G5 / G12 (feature-agentique plan 2026-10-06).
 *
 * G4 — verbes renommer (thin emitters AD-7, non-destructifs) :
 *  goal_rename / task_rename / event_rename / habit_rename /
 *  canvas_rename / skill_rename.
 *
 * G5 — verbes supprimer DESTRUCTIFS (ADR §5 : confirmation obligatoire) :
 *  task_delete / canvas_delete.
 *  Invariant AD-15 : PAS de goal_delete (les goals sont additifs —
 *  on utilise goal_abandon) ; pas de event_delete / habit_delete
 *  dans ce batch.
 *
 * G12 — mutations skills : skill_delete (DESTRUCTIVE, ADR §5).
 *  skill_rename est couvert par G4 (pas de doublon).
 *
 * AD-7 : execute ne write JAMAIS une table — il émet seulement
 * { ok, command, payload } ; le module du domaine applique.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import { KERNEL_TOOLS, DefaultCapabilityRegistry } from '../src/index.ts';
import {
  canvasDelete,
  canvasRename,
  eventRename,
  goalRename,
  habitRename,
  skillDelete,
  skillRename,
  taskDelete,
  taskRename,
} from '../src/tools.ts';

const reg = new DefaultCapabilityRegistry();

// ---------------------------------------------------------------------------
// G4 — verbes renommer (non-destructifs)
// ---------------------------------------------------------------------------

test('G4: les 6 outils rename sont dans KERNEL_TOOLS', () => {
  for (const id of [
    'goal_rename',
    'task_rename',
    'event_rename',
    'habit_rename',
    'canvas_rename',
    'skill_rename',
  ] as const) {
    assert.ok(id in KERNEL_TOOLS, `${id} en KERNEL_TOOLS`);
  }
});

test('G4: les 6 registry <famille>.rename existent, writeScopes par famille, flags false', () => {
  const specs: Array<[string, string]> = [
    ['goal.rename', 'progress:write'],
    ['task.rename', 'productivity:write'],
    ['event.rename', 'productivity:write'],
    ['habit.rename', 'productivity:write'],
    ['canvas.rename', 'canvas:write'],
    ['skill.rename', 'agent:write'],
  ];
  for (const [id, scope] of specs) {
    const e = reg.get(id);
    assert.ok(e, `registry ${id}`);
    assert.equal(e?.writeScopes[0], scope, `writeScope de ${id}`);
    assert.equal(e?.destructive, false, `${id} non-destructif`);
    assert.equal(e?.requiresConfirmation, false, `${id} sans confirmation`);
  }
});

test('G4: goal_rename émet progress.goal_rename', async () => {
  const r = (await goalRename.execute(
    { goalId: 'g1', title: 'But v2', userId: 'u1' },
    {} as never,
    undefined as never,
  )) as { ok: boolean; command: string; payload: { goalId: string; title: string } };
  assert.equal(r.ok, true);
  assert.equal(r.command, 'progress.goal_rename');
  assert.equal(r.payload.goalId, 'g1');
  assert.equal(r.payload.title, 'But v2');
});

test('G4: task_rename émet productivity.task_update (patch subject)', async () => {
  const r = (await taskRename.execute(
    { taskId: 't1', title: 'Nouvelle tâche', userId: 'u1' },
    {} as never,
    undefined as never,
  )) as {
    ok: boolean;
    command: string;
    payload: { taskIds: string[]; action: string; patch: { subject: string } };
  };
  assert.equal(r.ok, true);
  assert.equal(r.command, 'productivity.task_update');
  assert.deepEqual(r.payload.taskIds, ['t1']);
  assert.equal(r.payload.action, 'update');
  assert.deepEqual(r.payload.patch, { subject: 'Nouvelle tâche' });
});

test('G4: event_rename émet productivity.event_update (patch title)', async () => {
  const r = (await eventRename.execute(
    { eventId: 'e1', title: 'RDV café', userId: 'u1' },
    {} as never,
    undefined as never,
  )) as {
    ok: boolean;
    command: string;
    payload: { eventIds: string[]; patch: { title: string } };
  };
  assert.equal(r.ok, true);
  assert.equal(r.command, 'productivity.event_update');
  assert.deepEqual(r.payload.eventIds, ['e1']);
  assert.deepEqual(r.payload.patch, { title: 'RDV café' });
});

test('G4: habit_rename émet productivity.habit_update (patch name)', async () => {
  const r = (await habitRename.execute(
    { habitId: 'h1', name: 'Lecture 20 min', userId: 'u1' },
    {} as never,
    undefined as never,
  )) as {
    ok: boolean;
    command: string;
    payload: { habitId: string; patch: { name: string } };
  };
  assert.equal(r.ok, true);
  assert.equal(r.command, 'productivity.habit_update');
  assert.equal(r.payload.habitId, 'h1');
  assert.deepEqual(r.payload.patch, { name: 'Lecture 20 min' });
});

test('G4: canvas_rename émet canvas.rename', async () => {
  const r = (await canvasRename.execute(
    { canvasId: 'c1', title: 'Plan de sprint', userId: 'u1' },
    {} as never,
    undefined as never,
  )) as { ok: boolean; command: string; payload: { canvasId: string; title: string } };
  assert.equal(r.ok, true);
  assert.equal(r.command, 'canvas.rename');
  assert.equal(r.payload.canvasId, 'c1');
  assert.equal(r.payload.title, 'Plan de sprint');
});

test('G4: skill_rename émet agent.skill_rename', async () => {
  const r = (await skillRename.execute(
    { skillId: 's1', name: 'Veille IA', userId: 'u1' },
    {} as never,
    undefined as never,
  )) as { ok: boolean; command: string; payload: { skillId: string; name: string } };
  assert.equal(r.ok, true);
  assert.equal(r.command, 'agent.skill_rename');
  assert.equal(r.payload.skillId, 's1');
  assert.equal(r.payload.name, 'Veille IA');
});

// ---------------------------------------------------------------------------
// G5 — verbes supprimer (DESTRUCTIVE, ADR §5)
// ---------------------------------------------------------------------------

test('G5: task_delete + canvas_delete sont dans KERNEL_TOOLS, destructive + requiresConfirmation', () => {
  assert.ok('task_delete' in KERNEL_TOOLS);
  assert.ok('canvas_delete' in KERNEL_TOOLS);
  for (const id of ['task.delete', 'canvas.delete']) {
    const e = reg.get(id);
    assert.ok(e, `registry ${id}`);
    assert.equal(e?.destructive, true, `${id} destructive`);
    assert.equal(e?.requiresConfirmation, true, `${id} requiresConfirmation`);
  }
  assert.equal(reg.get('task.delete')?.writeScopes[0], 'productivity:write');
  assert.equal(reg.get('canvas.delete')?.writeScopes[0], 'canvas:write');
});

test('G5: task_delete émet productivity.task_delete', async () => {
  const r = (await taskDelete.execute(
    { taskId: 't1', userId: 'u1' },
    {} as never,
    undefined as never,
  )) as { ok: boolean; command: string; payload: { taskId: string } };
  assert.equal(r.ok, true);
  assert.equal(r.command, 'productivity.task_delete');
  assert.equal(r.payload.taskId, 't1');
});

test('G5: canvas_delete émet canvas.delete', async () => {
  const r = (await canvasDelete.execute(
    { canvasId: 'c1', userId: 'u1' },
    {} as never,
    undefined as never,
  )) as { ok: boolean; command: string; payload: { canvasId: string } };
  assert.equal(r.ok, true);
  assert.equal(r.command, 'canvas.delete');
  assert.equal(r.payload.canvasId, 'c1');
});

// Invariant AD-15 : les goals sont additifs — il n'y a JAMAIS de
// goal.delete dans le registry (on guide vers goal_abandon, gel avec
// données préservées). Ce test pinne l'invariant pour qu'aucun
// sous-agent ne réajoute un goal_delete à l'avenir.
test('G5: goal.delete est ABSENT du registry (AD-15 additif → goal_abandon)', () => {
  assert.equal(reg.get('goal.delete'), undefined);
  assert.ok('goal_abandon' in KERNEL_TOOLS, 'goal_abandon existe (la voie AD-15)');
});

// ---------------------------------------------------------------------------
// G12 — mutations skills (skill_rename via G4 + skill_delete)
// ---------------------------------------------------------------------------

test('G12: skill_delete est dans KERNEL_TOOLS, destructive + requiresConfirmation (ADR §5)', () => {
  assert.ok('skill_delete' in KERNEL_TOOLS);
  const e = reg.get('skill.delete');
  assert.ok(e, 'registry skill.delete');
  assert.equal(e?.writeScopes[0], 'agent:write');
  assert.equal(e?.destructive, true);
  assert.equal(e?.requiresConfirmation, true);
});

test('G12: skill_delete émet agent.skill_delete', async () => {
  const r = (await skillDelete.execute(
    { skillId: 's1', userId: 'u1' },
    {} as never,
    undefined as never,
  )) as { ok: boolean; command: string; payload: { skillId: string } };
  assert.equal(r.ok, true);
  assert.equal(r.command, 'agent.skill_delete');
  assert.equal(r.payload.skillId, 's1');
});
