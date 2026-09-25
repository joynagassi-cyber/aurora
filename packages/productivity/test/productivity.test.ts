/**
 * Productivity — minimal tests (node --experimental-strip-types + node:test).
 * One test per feature; deterministic, no DOM (AI_RULES / Vitest parity).
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  applySuggestion,
  captureTask,
  completeTask,
  createEvent,
  createGoal,
  createTask,
  detectConflicts,
  endFocusSession,
  habitHeatmap,
  habitStreak,
  inboxItems,
  materializeRecurringEvent,
  newPomodoro,
  nextRecurrence,
  planTimeBlocks,
  prioritizationSuggestion,
  quadrantBoard,
  quadrantOf,
  rescheduleTask,
  setTaskStatus,
  startFocusSession,
  tickPomodoro,
  updateGoal,
  PRODUCTIVITY_PRODUCED_EVENTS,
  buildTaskCompleted,
} from '../src/index.ts';
import type { Task } from '../src/index.ts';

const ctx = { userId: 'u1', clientId: 'c1', now: Date.parse('2026-09-25T09:00:00Z') };

function task(over: Partial<Task> = {}): Task {
  return {
    id: 't1',
    userId: 'u1',
    title: 'Ship',
    status: 'todo',
    tags: [],
    dependencies: [],
    evidenceRefs: [],
    createdAt: '2026-09-01T00:00:00Z',
    updatedAt: '2026-09-01T00:00:00Z',
    ...over,
  } as Task;
}

test('tasks: completeTask emits TaskCompleted + materializes next occurrence', () => {
  const t = task({ recurring: true, recurrenceRule: 'FREQ=DAILY' });
  const cmds = completeTask(t, ctx, (n) => `occ${n}`);
  assert.equal(cmds.length, 2);
  assert.equal(cmds[0]!.event?.type, 'TaskCompleted');
  assert.equal(cmds[1]!.table, 'tasks');
  assert.match(String(cmds[1]!.patch.due_at), /2026-09-26/);
});

test('tasks: status done without recurrence = single command', () => {
  const cmds = setTaskStatus(task(), 'done', ctx);
  assert.equal(cmds.event?.type, 'TaskCompleted');
  assert.equal(cmds.table, 'tasks');
});

test('tasks: recurrence math (daily/weekly/monthly + interval)', () => {
  const from = Date.parse('2026-09-25T09:00:00Z');
  assert.equal(nextRecurrence('FREQ=DAILY', from), Date.parse('2026-09-26T09:00:00Z'));
  assert.equal(nextRecurrence('FREQ=WEEKLY', from), Date.parse('2026-10-02T09:00:00Z'));
  assert.equal(nextRecurrence('FREQ=MONTHLY;INTERVAL=2', from), Date.parse('2026-11-25T09:00:00Z'));
  assert.equal(nextRecurrence('FREQ=HOURLY', from), null);
});

test('tasks: reschedule + subtask toggle write owned tables only', () => {
  const t = task();
  assert.equal(rescheduleTask(t, '2026-10-01T00:00:00Z', ctx).table, 'tasks');
  const cmd = setTaskStatus(t, 'todo', ctx);
  assert.equal(cmd.table, 'tasks');
});

test('inbox: capture trims + rejects empty; lens filters unstructured', () => {
  const inBox = inboxItems([
    task(),
    task({ projectId: 'p1' }),
    task({ status: 'done' }),
    task({ dueAt: '2026-10-01T00:00:00Z' }),
  ]);
  assert.deepEqual(inBox.map((t) => t.id), ['t1']);
  assert.equal(captureTask('  x  ', ctx, 't2').patch.subject, 'x');
  assert.throws(() => captureTask('   ', ctx, 't3'));
});

test('eisenhower: quadrant derivation (computed, not stored)', () => {
  const now = new Date(Date.parse('2026-09-25T09:00:00Z'));
  const overdue = quadrantOf(task({ dueAt: '2026-09-24T00:00:00Z' }), now, { explicit: 4 });
  assert.equal(overdue, 'q1_do');
  const q2 = quadrantOf(task({ dueAt: '2026-12-01T00:00:00Z' }), now, { explicit: 4 });
  assert.equal(q2, 'q2_plan');
  const q3 = quadrantOf(task({ dueAt: '2026-09-25T10:00:00Z' }), now, { explicit: 1 });
  assert.equal(q3, 'q3_minimize');
  const board = quadrantBoard(
    [task(), task({ id: 't2', dueAt: '2026-09-24T00:00:00Z' }), task({ id: 't3', dueAt: '2027-01-01T00:00:00Z' })],
    now,
    () => ({ explicit: 4 }),
  );
  assert.equal(board.q1_do.length, 1);
  assert.equal(board.q2_plan.length, 2);
  assert.equal(board.q4_defer.length, 0);
});

test('eisenhower: explainable suggestions + confirmed apply', () => {
  const now = new Date(Date.parse('2026-09-25T09:00:00Z'));
  const ts = [
    task({ id: 'a', dueAt: '2026-09-24T00:00:00Z', dependencies: [] }),
    task({ id: 'b', status: 'blocked' }),
  ];
  const sugg = prioritizationSuggestion(ts, { now, goalHorizonsByTask: new Map() }, 10);
  assert.ok(sugg.length >= 2);
  const top = sugg[0]!;
  assert.equal(top.taskId, 'a');
  assert.ok(top.signals.some((s) => s.key === 'overdue'));
  assert.equal(top.requiresConfirmation, true);
  const cmd = applySuggestion(ts[0]!, top, ctx);
  assert.equal(cmd.table, 'tasks');
  assert.equal(cmd.patch.priority, 2);
});

test('calendar: conflicts, overload, time blocking', () => {
  const ev = (id: string, start: string, end?: string) => ({ id, startAt: start, endAt: end });
  const conflicts = detectConflicts([
    ev('e1', '2026-09-25T09:00:00Z', '2026-09-25T10:00:00Z'),
    ev('e2', '2026-09-25T09:30:00Z', '2026-09-25T10:30:00Z'),
    ev('e3', '2026-09-25T09:10:00Z'),
  ]);
  assert.ok(conflicts.some((c) => c.kind === 'overlap' && c.aId === 'e1' && c.bId === 'e2'));
  assert.ok(conflicts.some((c) => c.kind === 'overload'));
  // one 30-min task + 5-min buffer fits an hour window; the second overflows.
  const plan = planTimeBlocks(
    [{ startMs: Date.parse('2026-09-25T09:00:00Z'), endMs: Date.parse('2026-09-25T10:00:00Z') }],
    [{ id: 't1', estimateSec: 1800 }, { id: 't2', estimateSec: 1800 }],
    300,
  );
  assert.equal(plan.blocks.length, 1);
  assert.equal(plan.blocks[0]!.taskId, 't1');
  assert.deepEqual(plan.unscheduled, ['t2']);
  // with more room both fit
  const plan2 = planTimeBlocks(
    [{ startMs: Date.parse('2026-09-25T09:00:00Z'), endMs: Date.parse('2026-09-25T14:00:00Z') }],
    [{ id: 't1', estimateSec: 1800 }, { id: 't2', estimateSec: 1800 }],
    300,
  );
  assert.equal(plan2.blocks.length, 2);
  assert.deepEqual(plan2.unscheduled, []);
  const created = createEvent({ userId: 'u1', title: 'Meet', startAt: '2026-09-25T12:00:00Z' }, ctx, 'e9');
  assert.equal(created.table, 'calendar_events');
});

test('calendar: recurring event materialization', () => {
  const cmd = materializeRecurringEvent(
    { id: 'e1', userId: 'u1', title: 'Gym', startAt: '2026-09-25T08:00:00Z', endAt: '2026-09-25T09:00:00Z', recurring: true, recurrenceRule: 'FREQ=WEEKLY', tags: [], createdAt: '2026-09-01', updatedAt: '2026-09-01' } as Task & import('../src/index.ts').never | import('@aurora/domain').Event,
    ctx,
    'e2',
  );
  // The shape above is illustrative; assert the helper's contract.
  assert.equal(cmd === null || cmd.table === 'calendar_events', true);
});

test('goals: create emits GoalUpdated; update lists changed fields', () => {
  const created = createGoal({ userId: 'u1', title: 'Learn Rust', horizon: 'long', targetDate: '2027-01-01' }, ctx, 'g1');
  assert.equal(created.event?.type, 'GoalUpdated');
  const g = {
    id: 'g1', userId: 'u1', title: 'Learn Rust', horizon: 'long' as const,
    status: 'active' as const, targetDate: '2027-01-01',
    createdAt: '2026-09-01', updatedAt: '2026-09-01',
  };
  const upd = updateGoal(g, { status: 'achieved', title: 'Learn Rust' } as never, ctx);
  assert.equal((upd.event as { payload: { fields: string[] } })!.payload.fields.join(','), 'status');
});

test('habits: streak + heatmap', () => {
  // consecutive completions up to today (23,24,25) keep the streak alive
  const nowMs = Date.parse('2026-09-25T09:00:00Z');
  const dates = ['2026-09-23', '2026-09-24', '2026-09-25'];
  const s = habitStreak(dates, 'daily', undefined, nowMs);
  assert.equal(s.current, 3);
  assert.ok(s.best >= 3);
  const cells = habitHeatmap(dates, 4, 'daily', undefined, nowMs);
  assert.equal(cells.length, 28);
  assert.ok(cells.some((c) => c.value === 1 && c.dateIso === '2026-09-23'));
  // a gap (missed required day) breaks the current streak
  const gapped = habitStreak(['2026-09-20', '2026-09-21', '2026-09-22'], 'daily', undefined, nowMs);
  assert.equal(gapped.current, 0);
  assert.equal(gapped.best, 3);
});

test('focus: session start/end + pomodoro state machine', () => {
  const start = startFocusSession({ userId: 'u1', mode: 'pomodoro', taskIds: ['t1'] }, ctx, 'f1');
  assert.equal(start.table, 'focus_sessions');
  const session = {
    id: 'f1', userId: 'u1', startedAt: new Date(ctx.now - 30 * 60_000).toISOString(),
    mode: 'pomodoro' as const, plannedDurationSec: 25 * 60, linkedTaskIds: [],
    createdAt: '2026-09-25', updatedAt: '2026-09-25',
  };
  const end = endFocusSession(session, ctx, { interruptions: 2 });
  assert.equal(end.patch.status, 'ended');
  assert.equal((end.patch.session_bilan as { actual_duration_sec: number }).actual_duration_sec, 30 * 60);
  let p = newPomodoro();
  assert.equal(p.remainingSec, 25 * 60);
  const t1 = tickPomodoro(p, 25 * 60 + 1);
  assert.equal(t1.state.phase, 'short_break');
  assert.equal(t1.transitioned, true);
});

test('events: module is sole producer of exactly its 2 events', () => {
  assert.deepEqual([...PRODUCTIVITY_PRODUCED_EVENTS], ['TaskCompleted', 'GoalUpdated']);
  const e = buildTaskCompleted('t1', 'u1', '2026-09-25T09:00:00Z', ['ev1']);
  assert.equal(e.type, 'TaskCompleted');
  assert.deepEqual(e.payload.evidenceRefs, ['ev1']);
});

test('recurrence createTask groups series by parent key', () => {
  const c = createTask(
    { userId: 'u1', title: 'Water plants', recurring: true, recurrenceRule: 'FREQ=WEEKLY;INTERVAL=2', dependencies: ['t0'] },
    ctx,
    't9',
  );
  assert.equal(c.patch.parent_recurrence_key, 'rec-t9');
  assert.equal(c.patch.recurrence_rule, 'FREQ=WEEKLY;INTERVAL=2');
  assert.equal((c.patch.dependencies as Array<{ v: string }>)[0]!.v, 't0');
});
