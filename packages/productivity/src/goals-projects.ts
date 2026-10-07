/**
 * Productivity module — Goals & Projects (wave 2, ATLAS).
 *
 * master-feature-catalog `productivity.goals` / `productivity.projects`:
 * goal→project→task hierarchy, horizons (short/medium/long), project
 * views (Gantt/Kanban/Timeline/List, UI = AG Grid / FullCalendar via
 * @aurora/ui — this package computes projections), milestones.
 *
 * Events (AD-9): goal mutations emit `GoalUpdated` (sole producer =
 * this module; consumers Progress, Agent observe via the events table).
 */
import type {
  Goal,
  Milestone,
  Project,
  ProjectView,
} from '@aurora/domain';
import { buildGoalUpdated } from './events.ts';
import type { Ctx, ProductivityCommand } from './tasks.ts';

// ---------------------------------------------------------------------------
// Goals
// ---------------------------------------------------------------------------

export interface NewGoal {
  userId: string;
  title: string;
  /** ADR S2.6 horizon */
  horizon: Goal['horizon'];
  targetDate?: string;
  description?: string;
}

/** Create a goal (goals table). Emits `GoalUpdated` (fields: all —
 *  creation is a total update of the goal row). */
export function createGoal(
  input: NewGoal,
  ctx: Ctx,
  id: string,
): ProductivityCommand {
  const nowIso = new Date(ctx.now).toISOString();
  const patch: Record<string, unknown> = {
    id,
    user_id: input.userId,
    title: input.title,
    horizon: input.horizon,
    status: 'active',
  };
  if (input.targetDate !== undefined) patch.target_date = input.targetDate;
  if (input.description !== undefined) patch.description = input.description;
  return {
    table: 'goals',
    id,
    patch,
    localMutationId: `go-${id}-create`,
    event: buildGoalUpdated(
      id,
      input.userId,
      nowIso,
      ['title', 'horizon', 'targetDate'],
    ),
  };
}

/** Update a goal field. Emits `GoalUpdated` listing the exact changed
 *  fields (AD-9 payload contract). */
export function updateGoal(
  goal: Goal,
  changes: Partial<Pick<Goal, 'title' | 'horizon' | 'targetDate' | 'status' | 'description'>>,
  ctx: Ctx,
  localMutationId?: string,
): ProductivityCommand {
  const camelToSnake: Record<string, string> = { targetDate: 'target_date' };
  const patch: Record<string, unknown> = { id: goal.id };
  const fields: string[] = [];
  for (const [k, v] of Object.entries(changes)) {
    if (v === undefined) continue;
    if (goal[k as keyof Goal] === v) continue; // no-op field: don't report
    patch[camelToSnake[k] ?? k] = v;
    fields.push(k);
  }
  if (fields.length === 0) {
    return {
      table: 'goals',
      id: goal.id,
      patch: { id: goal.id },
      localMutationId: localMutationId ?? `go-${goal.id}-noop`,
    };
  }
  return {
    table: 'goals',
    id: goal.id,
    patch,
    localMutationId: localMutationId ?? `go-${goal.id}-update`,
    event: buildGoalUpdated(
      goal.id,
      goal.userId,
      new Date(ctx.now).toISOString(),
      fields,
    ),
  };
}

/** Mark achieved (the `GoalUpdated` the Progress consumer tracks). */
export function achieveGoal(goal: Goal, ctx: Ctx): ProductivityCommand {
  return updateGoal(goal, { status: 'achieved' }, ctx, `go-${goal.id}-achieved`);
}

/**
 * G12 — renameGoal : renomme un objectif (patch `title` uniquement).
 * Fine use-case (AD-7 : le kernel ÉMET `progress.goal_rename` ; c'est ce
 * module qui applique la mutation) — délégué à `updateGoal` pour rester
 * borné : le no-op guard (title inchangé → pas d'événement) et l'émission
 * de `GoalUpdated` (fields: ['title']) viennent d'en-bas.
 *
 * Non-destructif : un goal ne se supprime jamais (AD-15 additif,
 * `goal_abandon` est le seul verbe de retrait).
 *
 * NB : le `localMutationId` passe par l'argument de `updateGoal` —
 * JS n'évalue le default argument que si l'argument est undefined,
 * donc le no-op branch (L83-87 de ce fichier) retourne l'id
 * `go-${id}-rename` (l'id du caller) PAS `go-${id}-noop`. C'est un
 * replay-safe identifier (l'idempotence AD-8 regarde le no-op via
 * l'absence d'`event`, pas via le mutation id).
 */
export function renameGoal(
  goal: Goal,
  title: string,
  ctx: Ctx,
): ProductivityCommand {
  return updateGoal(goal, { title }, ctx, `go-${goal.id}-rename`);
}

// ---------------------------------------------------------------------------
// Projects
// ---------------------------------------------------------------------------

export interface NewProject {
  userId: string;
  title: string;
  goalId?: string;
  deadline?: string;
  description?: string;
  viewMode?: ProjectView;
}

/** Create a project (projects table; agent project.create =
 *  CONFIRMATION_REQUIRED per catalog — confirmation is a UI gate, not
 *  a module concept). */
export function createProject(
  input: NewProject,
  _ctx: Ctx,
  id: string,
): ProductivityCommand {
  const patch: Record<string, unknown> = {
    id,
    user_id: input.userId,
    name: input.title,
    status: 'active',
  };
  if (input.goalId !== undefined) patch.goal_id = input.goalId;
  if (input.deadline !== undefined) patch.end_date = input.deadline;
  if (input.description !== undefined) patch.description = input.description;
  if (input.viewMode !== undefined) patch.view_mode = input.viewMode;
  return {
    table: 'projects',
    id,
    patch,
    localMutationId: `pr-${id}-create`,
  };
}

export function updateProject(
  project: Project,
  changes: Partial<Pick<Project, 'title' | 'status' | 'deadline' | 'viewMode' | 'description' | 'goalId'>>,
  ctx: Ctx,
  localMutationId?: string,
): ProductivityCommand {
  void ctx;
  const camelToSnake: Record<string, string> = {
    deadline: 'end_date',
    goalId: 'goal_id',
    viewMode: 'view_mode',
    title: 'name',
  };
  const patch: Record<string, unknown> = { id: project.id };
  for (const [k, v] of Object.entries(changes)) {
    if (v === undefined) continue;
    patch[camelToSnake[k] ?? k] = v;
  }
  return {
    table: 'projects',
    id: project.id,
    patch,
    localMutationId: localMutationId ?? `pr-${project.id}-update`,
  };
}

/** Create a milestone (milestones table — owned). */
export function createMilestone(
  input: {
    userId: string;
    projectId: string;
    goalId?: string;
    title: string;
    dueAt?: string;
  },
  _ctx: Ctx,
  id: string,
): ProductivityCommand {
  const patch: Record<string, unknown> = {
    id,
    user_id: input.userId,
    project_id: input.projectId,
    title: input.title,
    status: 'open',
  };
  if (input.goalId !== undefined) patch.goal_id = input.goalId;
  if (input.dueAt !== undefined) patch.due_date = input.dueAt;
  return {
    table: 'milestones',
    id,
    patch,
    localMutationId: `ms-${id}-create`,
  };
}

export function reachMilestone(
  ms: Milestone,
  ctx: Ctx,
): ProductivityCommand {
  return {
    table: 'milestones',
    id: ms.id,
    patch: { id: ms.id, status: 'reached', reached_at: new Date(ctx.now).toISOString() },
    localMutationId: `ms-${ms.id}-reached`,
  };
}

// ---------------------------------------------------------------------------
// View projections (pure data for the UI renderers: AG Grid list /
// Kanban, FullCalendar calendar, Gantt / timeline). No DOM, AD-1.
// ---------------------------------------------------------------------------

export interface GanttBar {
  taskId: string;
  title: string;
  startMs: number;
  endMs: number;
  /** 0..1 done ratio */
  progress: number;
}

/** Gantt / timeline projection of a project's tasks. */
export function ganttProjection(
  project: Project,
  tasks: Array<{ id: string; title: string; dueAt?: string; timeSpentSec?: number; status: string; projectId?: string }>,
  defaultSpanDays = 7,
): GanttBar[] {
  return tasks
    .filter((t) => t.projectId === project.id)
    .map((t) => {
      const endMs = t.dueAt
        ? Date.parse(t.dueAt)
        : Date.now() + defaultSpanDays * 86_400_000;
      const startMs = Math.max(endMs - defaultSpanDays * 86_400_000, 0);
      const estMs =
        t.status === 'done' ? (t.timeSpentSec ?? defaultSpanDays * 86_400) * 1000 : 0;
      const progress =
        t.status === 'done'
          ? 1
          : estMs > 0
            ? Math.min(1, ((t.timeSpentSec ?? 0) * 1000) / estMs)
            : 0;
      return { taskId: t.id, title: t.title, startMs, endMs, progress };
    });
}

/** Kanban columns = task statuses (05 S4.3). */
export function kanbanColumns(
  tasks: Array<{ id: string; title: string; status: string; projectId?: string }>,
  projectId?: string,
): Record<string, string[]> {
  const cols: Record<string, string[]> = {
    todo: [],
    doing: [],
    blocked: [],
    done: [],
  };
  for (const t of tasks) {
    if (projectId && t.projectId !== projectId) continue;
    const col =
      t.status === 'in_progress' ? 'doing' : (t.status as keyof typeof cols);
    const target = cols[col] ?? cols.todo!;
    target.push(t.id);
  }
  return cols;
}

/** Calendar projection (FullCalendar event input shape, vendor-free:
 *  the UI layer adapts to FullCalendar's EventInput). */
export interface UiCalendarEvent {
  id: string;
  title: string;
  start: string;
  end?: string;
  allDay: boolean;
}

export function toUiCalendarEvents(
  events: Array<Pick<Project, 'id' | 'title' | 'status' | 'deadline' | 'viewMode'> | { id: string; title: string; startAt: string; endAt?: string; allDay?: boolean }>,
): UiCalendarEvent[] {
  return events.map((e) => {
    if ('startAt' in e) {
      const ev = e as { id: string; title: string; startAt: string; endAt?: string; allDay?: boolean };
      return {
        id: ev.id,
        title: ev.title,
        start: ev.startAt,
        end: ev.endAt,
        allDay: ev.allDay ?? false,
      };
    }
    const p = e as Project;
    return {
      id: p.id,
      title: p.title,
      start: p.deadline ?? '',
      allDay: true,
    };
  });
}
