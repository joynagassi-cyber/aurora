/**
 * Productivity module — Eisenhower quadrant (G-L5, wave 2, ATLAS).
 *
 * docs/productivity/eisenhower.md: the quadrant is COMPUTED, never
 * stored (§3: "the only stored priority data are Task.priority
 * (manual) + Task.importance + Task.due_at + Task.dependencies[]").
 * Urgency is DERIVED from due_at vs now (§6: no `urgency` column).
 *
 * Agent-assisted, explainable prioritization (ADR S2.3): deterministic,
 * local rule-based `prioritizationSuggestion` — each suggestion lists
 * the signals it used so the UI can render the agent's explanation.
 * The agent NEVER re-prioritizes silently: suggestions degrade to
 * local rules offline; the user confirms before any TaskUpdateCommand
 * is applied (AD-7 single-writer, eisenhower.md §5).
 */
import type { Goal, Task } from '@aurora/domain';
import { orSetValues, type Ctx, type ProductivityCommand } from './tasks.ts';

/** Frozen quadrant ids (eisenhower.md §5, SSoT shape). */
export type Quadrant = 'q1_do' | 'q2_plan' | 'q3_minimize' | 'q4_defer';

/**
 * Importance input: explicit `importance` when present, else inferred
 * from a goal link (inference is flagged — eisenhower.md §6).
 */
export interface ImportanceInput {
  /** 1..4 explicit user-declared importance */
  explicit?: number;
  /** linked goal horizons: long > medium > short (goal criticality proxy) */
  goalHorizons?: Array<Goal['horizon']>;
  /** whether the importance value was inferred (agent suggestion, not stored) */
  inferred?: boolean;
}

export interface UrgencyBands {
  /** overdue → urgent */
  isOverdue: boolean;
  /** due within the window (default 48h) */
  isDueSoon: boolean;
  /** due today */
  isDueToday: boolean;
  /** blocked = urgency flag (eisenhower.md §6) */
  isBlocked: boolean;
}

/** Compute the urgency bands from due_at / status (§6, derived — no
 *  stored column). */
export function urgencyOf(
  task: Pick<Task, 'dueAt' | 'status'>,
  now: Date,
  opts?: { soonWindowMs?: number },
): UrgencyBands {
  const windowMs = opts?.soonWindowMs ?? 48 * 3600_000;
  const dueMs = task.dueAt ? Date.parse(task.dueAt) : Number.NaN;
  const isDue = Number.isFinite(dueMs);
  const dayMs = 24 * 3600_000;
  const startOfDay = new Date(now);
  startOfDay.setUTCHours(0, 0, 0, 0);
  const endOfDay = new Date(startOfDay.getTime() + dayMs);
  return {
    isOverdue: isDue && dueMs < now.getTime(),
    isDueSoon: isDue && dueMs >= now.getTime() && dueMs <= now.getTime() + windowMs,
    isDueToday:
      isDue && dueMs >= startOfDay.getTime() && dueMs < endOfDay.getTime(),
    isBlocked: task.status === 'blocked',
  };
}

/** The quadrant of a task (eisenhower.md §3: computed, not stored). */
export function quadrantOf(
  task: Pick<Task, 'dueAt' | 'status'>,
  now: Date,
  importance?: ImportanceInput,
): Quadrant {
  const imp =
    importance?.explicit ??
    (importance?.goalHorizons?.some((h) => h === 'long')
      ? 4
      : importance?.goalHorizons?.some((h) => h === 'medium')
        ? 3
        : 2);
  const important = (imp ?? 1) >= 3;
  const u = urgencyOf(task, now);
  const urgent = u.isOverdue || u.isDueSoon || u.isBlocked;
  if (urgent && important) return 'q1_do';
  if (!urgent && important) return 'q2_plan';
  if (urgent) return 'q3_minimize';
  return 'q4_defer';
}

/** The four quadrants grouped, in display order. */
export function quadrantBoard(
  tasks: Task[],
  now: Date,
  importanceOf?: (t: Task) => ImportanceInput | undefined,
): Record<Quadrant, Task[]> {
  const board: Record<Quadrant, Task[]> = {
    q1_do: [],
    q2_plan: [],
    q3_minimize: [],
    q4_defer: [],
  };
  for (const t of tasks) {
    if (t.status === 'done' || t.status === 'cancelled') continue;
    board[quadrantOf(t, now, importanceOf?.(t))].push(t);
  }
  return board;
}

// ---------------------------------------------------------------------------
// Agent-assisted, explainable prioritization (ADR S2.3 "Explication par
// l'agent de ses recommandations"). Pure + deterministic (Vitest, no DOM).
// ---------------------------------------------------------------------------

export interface Signal {
  key: 'overdue' | 'due-today' | 'due-48h' | 'blocked' | 'goal-link' | 'dependency-blocked' | 'overrun' | 'low-importance';
  description: string;
  /** sign: + pushes up, − pushes down */
  weight: number;
}

export interface PrioritizationSuggestion {
  taskId: string;
  /** the quadrant / priority the agent proposes */
  proposedPriority: number;
  proposedQuadrant: Quadrant;
  /** which signals the agent used — the explainability contract */
  signals: Signal[];
  /** one-line human explanation (UI renders verbatim) */
  rationale: string;
  /** user must confirm; never silent re-prioritization */
  requiresConfirmation: true;
}

export interface SuggestionContext {
  now: Date;
  /** task id -> blocked state of its dependencies */
  dependencyBlocked?: Map<string, boolean>;
  /** task id -> estimated minutes vs actual (overrun detection) */
  effort?: Map<string, { estimatedMin: number; actualMin?: number }>;
  /** task id -> linked goal horizons (importance inference, eisenhower.md �6) */
  goalHorizonsByTask?: Map<string, Array<import('@aurora/domain').Goal['horizon']>>;
}

/** Rank all open tasks; return top-N explainable suggestions.
 *  Deterministic given the same inputs (offline-degradable). */
export function prioritizationSuggestion(
  tasks: Task[],
  ctx: SuggestionContext,
  limit = 5,
): PrioritizationSuggestion[] {
  const open = tasks.filter((t) => t.status !== 'done' && t.status !== 'cancelled');
  const scored = open.map((t) => {
    const u = urgencyOf(t, ctx.now);
    const signals: Signal[] = [];
    let score = 0;
    if (u.isOverdue) {
      signals.push({ key: 'overdue', description: 'Past due', weight: 3 });
      score += 3;
    }
    if (u.isDueToday) {
      signals.push({ key: 'due-today', description: 'Due today', weight: 2 });
      score += 2;
    } else if (u.isDueSoon) {
      signals.push({ key: 'due-48h', description: 'Due within 48h', weight: 1.5 });
      score += 1.5;
    }
    if (u.isBlocked) {
      signals.push({ key: 'blocked', description: 'Task is blocked', weight: 2 });
      score += 2;
    }
    const effort = ctx.effort?.get(t.id);
    if (effort && effort.actualMin !== undefined && effort.actualMin > effort.estimatedMin) {
      signals.push({ key: 'overrun', description: 'Effort overrun', weight: 1 });
      score += 1;
    }
    const depBlocked = t.dependencies.length > 0 &&
      [...new Set(t.dependencies.map((d) => d.v))]
        .some((depId) => ctx.dependencyBlocked?.get(depId) === true);
    if (depBlocked) {
      signals.push({ key: 'dependency-blocked', description: 'Dependency blocked', weight: 2 });
      score += 2;
    }
    if (t.goalId !== undefined) {
      signals.push({ key: 'goal-link', description: 'Linked to a goal', weight: 1 });
      score += 1;
      const horizons = ctx.goalHorizonsByTask?.get(t.id);
      if (horizons?.every((h) => h === 'short')) {
        signals.push({ key: 'low-importance', description: 'Short-horizon goal only', weight: -0.5 });
        score -= 0.5;
      }
    }
    const quadrant = quadrantOf(t, ctx.now, { goalHorizons: ctx.goalHorizonsByTask?.get(t.id) });
    return { task: t, score, signals, quadrant, u };
  });

  scored.sort((a, b) => b.score - a.score || a.task.title.localeCompare(b.task.title));

  return scored.slice(0, limit).map(({ task, signals, quadrant }) => {
    const proposedPriority =
      quadrant === 'q1_do' ? 4 : quadrant === 'q2_plan' ? 3 : quadrant === 'q3_minimize' ? 2 : 1;
    return {
      taskId: task.id,
      proposedPriority,
      proposedQuadrant: quadrant,
      signals,
      rationale: signals.length > 0
        ? `Re-prioritized because: ${signals.map((s) => s.description.toLowerCase()).join(', ')}.`
        : 'No strong signals; keep current order.',
      requiresConfirmation: true,
    } satisfies PrioritizationSuggestion;
  });
}

/** Apply a confirmed suggestion as a partial task command (AD-7/F-03:
 *  one partial command per task, single-writer). */
export function applySuggestion(
  task: Task,
  suggestion: PrioritizationSuggestion,
  ctx: Ctx,
): ProductivityCommand {
  void ctx;
  return {
    table: 'tasks',
    id: task.id,
    patch: {
      id: task.id,
      priority: suggestion.proposedPriority,
    },
    localMutationId: `tm-${task.id}-reprior`,
  };
}

// orSetValues re-exported for callers building dependency partials.
export { orSetValues };
