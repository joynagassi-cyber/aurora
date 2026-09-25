/**
 * Productivity module — Inbox / quick capture (wave 2, ATLAS).
 *
 * master-feature-catalog `productivity.inbox`: capture → triage →
 * organized objects. The inbox is a LENS over the owned tables
 * (tasks / calendar_events / decisions), not a new entity — capture
 * is always "create in Inbox state" (task without project, status
 * todo, due_at null); triage produces commands that resolve the item
 * into a structured object (AD-7: one command per mutation).
 */
import type { Task } from '@aurora/domain';
import type { Ctx, ProductivityCommand } from './tasks.ts';
import { createTask } from './tasks.ts';

/** Inbox filter: open, unstructured, unlinked items (05 S4.1 Home "what
 *  matters now" companion). Pure predicate over the local mirror. */
export function inboxItems(tasks: Task[]): Task[] {
  return tasks.filter(
    (t) =>
      t.status !== 'done' &&
      t.status !== 'cancelled' &&
      t.projectId === undefined &&
      t.goalId === undefined &&
      t.dueAt === undefined,
  );
}

/** Quick capture: "remember this" → a bare inbox task. */
export function captureTask(
  text: string,
  ctx: Ctx,
  id: string,
): ProductivityCommand {
  const clean = text.trim();
  if (clean.length === 0) {
    throw new Error('productivity/capture_empty: nothing to capture');
  }
  return createTask({ userId: ctx.userId, title: clean }, ctx, id);
}

/** Triage: pull an inbox task out of the lens by structuring it.
 *  Each triage = ONE partial command against tasks (AD-7/F-03). */
export function triageTask(
  task: Task,
  res:
    | { kind: 'project'; projectId: string; dueAt?: string }
    | { kind: 'tomorrow'; dueAt: string }
    | { kind: 'discard' },
  ctx: Ctx,
): ProductivityCommand {
  const base: ProductivityCommand = {
    table: 'tasks',
    id: task.id,
    patch: { id: task.id, status: 'cancelled' },
    localMutationId: `tm-${task.id}-${res.kind}`,
  };
  if (res.kind === 'discard') {
    void ctx;
    return base;
  }
  const patch: Record<string, unknown> = { id: task.id };
  if (res.kind === 'project') {
    patch.project_id = res.projectId;
    patch.status = 'todo';
    if (res.dueAt) patch.due_at = res.dueAt;
  } else {
    patch.status = 'todo';
    patch.due_at = res.dueAt;
  }
  return {
    table: 'tasks',
    id: task.id,
    patch,
    localMutationId: `tm-${task.id}-triage`,
  };
}
