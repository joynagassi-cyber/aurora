/**
 * Productivity module — tasks use-case (wave 2, ATLAS).
 *
 * docs/productivity/overview.md §4/§7 + master-feature-catalog
 * `productivity.tasks`: tasks/subtasks (statuses, estimates vs actual,
 * recurrence materialized, dependencies, postponements history).
 *
 * Single-writer discipline (AD-7/F-03): every use-case returns
 * PARTIAL command updates (`ProductivityCommand`) against the tables
 * THIS module owns (0002_productivity.sql: tasks, subtasks). One
 * command per mutation; multi-table writes are a blocking finding
 * (02 S11). The UI applies commands via `LocalCommandRepository.apply(
 * 'productivity', …)`; heavy work stays out of the render path
 * (AD-8).
 *
 * Recurrence (01 S4.1): occurrences are MATERIALIZED rows grouped by
 * `parent_recurrence_key`; there is no rule table — a completed
 * recurring occurrence spawns the next occurrence as part of the
 * same use-case result (still single-table: tasks only).
 *
 * Events (AD-9): `completeTask` emits `TaskCompleted` (sole producer =
 * this module). No other event is emitted here — the closed
 * 9-event vocabulary is the limit.
 */
import type {
  OrSetValue,
  Task,
  TaskStatus,
} from '@aurora/domain';
import { buildTaskCompleted } from './events.ts';

/** Local client identity for OR-Set elements (03 S5.3). */
export interface Ctx {
  userId: string;
  clientId: string;
  /** server-canonical timestamp (ms) — 03 S4.2 rule 3 */
  now: number;
}

/** Partial command updates for tables owned by Productivity (AD-7). */
export interface ProductivityCommand {
  /** owned table (0002_productivity.sql) */
  table: 'tasks' | 'subtasks' | 'projects' | 'goals' | 'milestones' | 'habits' | 'routines' | 'calendar_events' | 'focus_sessions' | 'decisions';
  /** upsert key */
  id: string;
  /** partial fields (server-wins merge, 03 S4.2) */
  patch: Record<string, unknown>;
  /** ULID of the local mutation (G-M4 traceability) */
  localMutationId: string;
  /** optional event emitted atomically with this command (AD-9) */
  event?: import('@aurora/domain').DomainEvent;
}

export interface NewTask {
  userId: string;
  title: string;
  description?: string;
  projectId?: string;
  goalId?: string;
  dueAt?: string;
  priority?: number;
  /** RFC5545-ish rule (P1D, FREQ=WEEKLY…) */
  recurring?: boolean;
  recurrenceRule?: string;
  /** dependency task ids (OR-Set input) */
  dependencies?: string[];
  tags?: string[];
}

/** Create a task. If `recurring`, the first occurrence is materialized
 *  now and `parent_recurrence_key` groups the series (01 S4.1). */
export function createTask(
  input: NewTask,
  ctx: Ctx,
  id: string,
): ProductivityCommand {
  const ts = ctx.now;
  const patch: Record<string, unknown> = {
    id,
    user_id: input.userId,
    subject: input.title,
    status: 'todo',
    tags: (input.tags ?? []).map((v) => ({ v, ts, c: ctx.clientId })),
    dependencies: (input.dependencies ?? []).map((v) => ({
      v,
      ts,
      c: ctx.clientId,
    })),
  };
  if (input.description !== undefined) patch.description = input.description;
  if (input.projectId !== undefined) patch.project_id = input.projectId;
  if (input.goalId !== undefined) patch.goal_id = input.goalId;
  if (input.dueAt !== undefined) patch.due_at = input.dueAt;
  if (input.priority !== undefined) patch.priority = input.priority;
  if (input.recurring) {
    patch.parent_recurrence_key = `rec-${id}`;
    patch.recurrence_rule = input.recurrenceRule ?? 'FREQ=DAILY';
  }
  return {
    table: 'tasks',
    id,
    patch,
    localMutationId: `tm-${id}-create`,
  };
}

/** Status transition. `done` emits `TaskCompleted` (AD-9 producer). */
export function setTaskStatus(
  task: Task,
  status: TaskStatus,
  ctx: Ctx,
  localMutationId?: string,
): ProductivityCommand {
  const patch: Record<string, unknown> = {
    id: task.id,
    status,
  };
  let event: import('@aurora/domain').DomainEvent | undefined;
  if (status === 'done') {
    const completedAt = new Date(ctx.now).toISOString();
    patch.done_at = completedAt;
    event = buildTaskCompleted(task.id, task.userId, completedAt);
  }
  return {
    table: 'tasks',
    id: task.id,
    patch,
    localMutationId: localMutationId ?? `tm-${task.id}-${status}`,
    ...(event ? { event } : {}),
  };
}

/** Complete a task + materialize the NEXT occurrence of a recurring
 *  series (01 S4.1). Two commands, ONE table — still AD-7 compliant
 *  (the repository applies them atomically; recurrence is "tasks
 *  table only" by design). */
export function completeTask(
  task: Task,
  ctx: Ctx,
  id: (n: number) => string,
  opts?: { estimateSec?: number },
): ProductivityCommand[] {
  const first = setTaskStatus(task, 'done', ctx, `tm-${task.id}-done`);
  const commands: ProductivityCommand[] = [first];
  if (opts?.estimateSec !== undefined) {
    first.patch.actual_minutes = Math.round(opts.estimateSec / 60);
  }
  if (task.recurring && task.recurrenceRule) {
    const next = nextRecurrence(task.recurrenceRule, ctx.now);
    if (next !== null) {
      const occId = id(1);
      commands.push({
        table: 'tasks',
        id: occId,
        patch: {
          id: occId,
          user_id: task.userId,
          subject: task.title,
          status: 'todo',
          due_at: new Date(next).toISOString(),
          // same series, new materialized row (01 S4.1)
          parent_recurrence_key:
            task.dependencies.length > 0
              ? `rec-${task.id}`
              : `rec-${task.id}`,
          recurrence_rule: task.recurrenceRule,
        },
        localMutationId: `tm-${occId}-recurrence`,
      });
    }
  }
  return commands;
}

/** Postpone a due task (postponements history: each reschedule appends
 *  a new due_at; the history lives in the local mirror, server-wins). */
export function rescheduleTask(
  task: Task,
  newDueAt: string,
  _ctx: Ctx,
  localMutationId?: string,
): ProductivityCommand {
  return {
    table: 'tasks',
    id: task.id,
    patch: { id: task.id, due_at: newDueAt },
    localMutationId: localMutationId ?? `tm-${task.id}-resched`,
  };
}

/** Sub-task toggling (one command per sub-task; subtasks table is
 *  owned by Productivity too — 0002/03 S4.2 local mirror). */
export function toggleSubTask(
  subId: string,
  _taskId: string,
  nextDone: boolean,
  ctx: Ctx,
  localMutationId?: string,
): ProductivityCommand {
  const patch: Record<string, unknown> = {
    id: subId,
    status: nextDone ? 'done' : 'todo',
  };
  if (nextDone) patch.done_at = new Date(ctx.now).toISOString();
  return {
    table: 'subtasks',
    id: subId,
    patch,
    localMutationId: localMutationId ?? `tm-${subId}-toggle`,
  };
}

// ---------------------------------------------------------------------------
// Recurrence materialization (01 S4.1: materialized rows, no rule table).
// Supported deterministic rules: FREQ=DAILY / WEEKLY / MONTHLY with
// INTERVAL=n. Anything else = no auto-materialization (user re-plans).
// ---------------------------------------------------------------------------

/** Compute the next occurrence timestamp (ms) after `fromMs`, or null
 *  when the rule is unsupported. Deterministic, unit-testable. */
export function nextRecurrence(rule: string, fromMs: number): number | null {
  const m = /^FREQ=(DAILY|WEEKLY|MONTHLY)(;INTERVAL=(\d+))?$/i.exec(
    rule.trim(),
  );
  if (!m) return null;
  const interval = m[3] ? Number.parseInt(m[3], 10) : 1;
  const step = new Date(fromMs);
  switch (m[1]!.toUpperCase()) {
    case 'DAILY':
      step.setUTCHours(9, 0, 0, 0);
      step.setUTCDate(step.getUTCDate() + interval);
      return step.getTime();
    case 'WEEKLY':
      step.setUTCHours(9, 0, 0, 0);
      step.setUTCDate(step.getUTCDate() + 7 * interval);
      return step.getTime();
    case 'MONTHLY': {
      step.setUTCHours(9, 0, 0, 0);
      step.setUTCMonth(step.getUTCMonth() + interval, step.getUTCDate());
      return step.getTime();
    }
    default:
      return null;
  }
}

/** OR-Set list helper: turn plain ids into the frozen OR-Set encoding
 *  (03 S5.3: {v, ts, c}). */
export function orSetValues(
  values: string[],
  ts: number,
  clientId: string,
): OrSetValue[] {
  return values.map((v) => ({ v, ts, c: clientId }));
}
