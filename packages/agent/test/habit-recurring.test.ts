/**
 * L2 (G6-G8) — habit/routine create + recurring task/event + Automation NL doc
 *
 * AD-7 thin-emitter pattern for G6 (habit_create, routine_create).
 * G7 extends existing taskUpdate + schedule with optional recurring fields.
 * G8 = doc block near createAutomation (create_automation → focus.start / review.run).
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import { KERNEL_TOOLS, DefaultCapabilityRegistry } from '../src/index.ts';
import {
  createAutomation,
  habitCreate,
  routineCreate,
  schedule,
  taskUpdate,
} from '../src/tools.ts';

const reg = new DefaultCapabilityRegistry();

// ---------------------------------------------------------------------------
// G6 — habit_create + routine_create
// ---------------------------------------------------------------------------

test('G6: habit_create + routine_create in KERNEL_TOOLS', () => {
  assert.ok('habit_create' in KERNEL_TOOLS, 'habit_create in KERNEL_TOOLS');
  assert.ok('routine_create' in KERNEL_TOOLS, 'routine_create in KERNEL_TOOLS');
});

test('G6: habit_create resolved via byTool + registry (habit.create)', () => {
  assert.ok(reg.byTool('habitCreate'), 'habit_create tool resolved by ToolResolver');
  const e = reg.get('habit.create');
  assert.ok(e, 'habit.create capability entry exists');
  assert.deepEqual(e.writeScopes, ['productivity:write'], 'write productivity:write');
  assert.equal(e.destructive, false, 'non-destructive');
  assert.equal(e.requiresConfirmation, false, 'no confirmation');
});

test('G6: routine_create resolved via byTool + registry (routine.create)', () => {
  assert.ok(reg.byTool('routineCreate'), 'routine_create tool resolved by ToolResolver');
  const e = reg.get('routine.create');
  assert.ok(e, 'routine.create capability entry exists');
  assert.deepEqual(e.writeScopes, ['productivity:write'], 'write productivity:write');
  assert.equal(e.destructive, false, 'non-destructive');
  assert.equal(e.requiresConfirmation, false, 'no confirmation');
});

test('G6: habit_create emits productivity.habit_create with cadence (programmer)', async () => {
  const r = (await habitCreate.execute(
    { title: 'Lecture', cadence: 'daily', userId: 'u1' },
    {} as never,
    undefined as never,
  )) as { ok: boolean; command: string; payload: Record<string, unknown> };
  assert.equal(r.ok, true);
  assert.equal(r.command, 'productivity.habit_create');
  assert.equal(r.payload.cadence, 'daily');
  assert.equal(r.payload.title, 'Lecture');
  assert.equal(r.payload.userId, 'u1');
});

test('G6: habit_create supports weekly cadence + weekdays', async () => {
  const r = (await habitCreate.execute(
    { title: 'Sport', cadence: 'weekly', weekdays: [1, 3, 5], userId: 'u1' },
    {} as never,
    undefined as never,
  )) as { payload: { cadence: string; weekdays?: number[] } };
  assert.equal(r.payload.cadence, 'weekly');
  assert.deepEqual(r.payload.weekdays, [1, 3, 5]);
});

test('G6: routine_create emits productivity.routine_create', async () => {
  const r = (await routineCreate.execute(
    { title: 'Matin', kind: 'morning', steps: ['café', 'étirements'], userId: 'u1' },
    {} as never,
    undefined as never,
  )) as { ok: boolean; command: string; payload: Record<string, unknown> };
  assert.equal(r.ok, true);
  assert.equal(r.command, 'productivity.routine_create');
  assert.equal(r.payload.kind, 'morning');
  assert.deepEqual(r.payload.steps, ['café', 'étirements']);
});

test('G6: routine_create accepts habitIds (attached habits)', async () => {
  const r = (await routineCreate.execute(
    { title: 'Study', kind: 'study', steps: ['flashcards'], habitIds: ['hb-1', 'hb-2'], userId: 'u1' },
    {} as never,
    undefined as never,
  )) as { payload: { habitIds?: string[] } };
  assert.deepEqual(r.payload.habitIds, ['hb-1', 'hb-2']);
});

// ---------------------------------------------------------------------------
// G7 — recurring (extend taskUpdate + schedule input schemas, pass-through)
// ---------------------------------------------------------------------------

test('G7: task_update carry recurring + recurrenceRule in payload (materialized rows, 01 S4.1)', async () => {
  const r = (await taskUpdate.execute(
    {
      taskIds: [],
      action: 'create',
      title: 'Réviser',
      recurring: true,
      recurrenceRule: 'FREQ=WEEKLY',
      userId: 'u1',
    },
    {} as never,
    undefined as never,
  )) as { payload: { recurring?: boolean; recurrenceRule?: string } };
  assert.equal(r.payload.recurring, true, 'recurring flag flows through');
  assert.equal(r.payload.recurrenceRule, 'FREQ=WEEKLY', 'recurrenceRule flows through');
});

test('G7: task_update creates non-recurring task without the optional fields', async () => {
  const r = (await taskUpdate.execute(
    { taskIds: [], action: 'create', title: 'One-off', userId: 'u1' },
    {} as never,
    undefined as never,
  )) as { payload: Record<string, unknown> };
  assert.equal(r.payload.title, 'One-off');
  assert.equal(r.payload.recurring, undefined, 'recurring absent when not set');
});

test('G7: schedule carries recurring + recurrenceRule (calendar.materialize)', async () => {
  const r = (await schedule.execute(
    {
      subject: 'Deep work',
      startAt: '2026-10-07T09:00:00Z',
      durationMin: 50,
      recurring: true,
      recurrenceRule: 'FREQ=DAILY',
      userId: 'u1',
    },
    {} as never,
    undefined as never,
  )) as { payload: { recurring?: boolean; recurrenceRule?: string } };
  assert.equal(r.payload.recurring, true);
  assert.equal(r.payload.recurrenceRule, 'FREQ=DAILY');
});

// ---------------------------------------------------------------------------
// G8 — Automation NL examples doc (verify create_automation still works
// with action: 'focus.start' and action: 'review.run' — the two canonical
// phrases G8 maps to).
// ---------------------------------------------------------------------------

test('G8: create_automation with action=focus.start is emitted cleanly (focus récurrent)', async () => {
  const r = (await createAutomation.execute(
    {
      name: 'Focus matin',
      trigger: 'schedule',
      schedule: '0 9 * * *',
      jobKind: 'agent_run',
      action: 'focus.start',
      userId: 'u1',
    },
    {} as never,
    undefined as never,
  )) as { ok: boolean; command: string; payload: Record<string, unknown> };
  assert.equal(r.ok, true);
  assert.equal(r.command, 'integrations.automation_create');
  assert.equal(r.payload.action, 'focus.start');
  assert.equal(r.payload.trigger, 'schedule');
  assert.equal(r.payload.schedule, '0 9 * * *');
});

test('G8: create_automation with action=review.run is emitted cleanly (bilan récurrent)', async () => {
  const r = (await createAutomation.execute(
    {
      name: 'Bilan vendredi',
      trigger: 'schedule',
      schedule: '0 17 * * 5',
      jobKind: 'agent_run',
      action: 'review.run',
      userId: 'u1',
    },
    {} as never,
    undefined as never,
  )) as { payload: { action: string; schedule: string } };
  assert.equal(r.payload.action, 'review.run');
  assert.equal(r.payload.schedule, '0 17 * * 5');
});
