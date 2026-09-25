/**
 * Productivity module — Reviews & Analytics (wave 2, ATLAS).
 *
 * master-feature-catalog `productivity.reviews` / `productivity.analytics`:
 * daily / weekly / monthly bilan + decisions journal; personal
 * analytics (planned vs actual load, procrastination trends, overload
 * detection).
 *
 * AD-8: heavy aggregation = PERSISTED JOB, not a UI computation.
 * `prepareReview` / `aggregateAnalytics` build the idempotent job
 * descriptors; the server worker (fn per JobDispatcherPort) runs
 * them and writes review summaries (owned `decisions` + local
 * analytics mirror). The module itself only defines the payload
 * shapes + the deterministic aggregation core (pure, testable).
 */
import type { Decision, Goal, Task } from '@aurora/domain';
import type { JobKind } from '@aurora/domain';
import type { Ctx, ProductivityCommand } from './tasks.ts';
import { orSetValues } from './tasks.ts';

export type ReviewPeriod = 'daily' | 'weekly' | 'monthly';

// ---------------------------------------------------------------------------
// Reviews (bilan + decisions journal)
// ---------------------------------------------------------------------------

export interface ReviewSummary {
  period: ReviewPeriod;
  /** ISO day key the review covers */
  startIso: string;
  endIso: string;
  completedTaskIds: string[];
  cancelledTaskIds: string[];
  overdueOpenTaskIds: string[];
  /** planned load vs actual (01 S6: planned-vs-real) */
  plannedSec: number;
  actualSec: number;
  /** habit adherence ratio 0..1 */
  habitAdherence: number;
  /** next actions proposed (user-confirmed, AD-5) */
  nextActions: string[];
}

/** Deterministic daily/weekly/monthly summary over owned data.
 *  Pure — the UI or the job worker calls it. */
export function buildReview(
  period: ReviewPeriod,
  data: {
    tasks: Task[];
    decisions: Decision[];
    habits: Array<{ id: string; cadence: string; completions: string[] }>;
    nowMs: number;
  },
): ReviewSummary {
  const startMs = periodStart(period, data.nowMs);
  const endMs = data.nowMs;
  const inWindow = (iso?: string) =>
    iso !== undefined && Date.parse(iso) >= startMs && Date.parse(iso) < endMs;

  const completed = data.tasks.filter((t) => t.status === 'done' && inWindow(t.updatedAt));
  const cancelled = data.tasks.filter((t) => t.status === 'cancelled' && inWindow(t.updatedAt));
  const overdueOpen = data.tasks.filter(
    (t) =>
      (t.status === 'todo' || t.status === 'in_progress' || t.status === 'blocked') &&
      t.dueAt !== undefined &&
      Date.parse(t.dueAt) < data.nowMs,
  );

  let plannedSec = 0;
  for (const t of data.tasks) {
    if (inWindow(t.createdAt)) plannedSec += t.timeSpentSec ?? 0;
  }
  let actualSec = 0;
  for (const t of data.tasks) {
    if (inWindow(t.updatedAt)) actualSec += t.timeSpentSec ?? 0;
  }

  // habit adherence: completions within window / required days
  let requiredDays = 0;
  let doneDays = 0;
  const dayMs = 86_400_000;
  for (const h of data.habits) {
    const stepMs = h.cadence === 'weekly' ? 7 * dayMs : dayMs;
    const required = Math.max(1, Math.ceil((endMs - startMs) / stepMs));
    requiredDays += required;
    const inWin = h.completions.filter((d) => {
      const ts = Date.parse(d + 'T00:00:00Z');
      return ts >= startMs && ts < endMs;
    }).length;
    doneDays += Math.min(inWin, required);
  }
  const habitAdherence = requiredDays > 0 ? doneDays / requiredDays : 1;

  const nextActions = overdueOpen
    .slice(0, 5)
    .map((t) => `Re-plan overdue: ${t.title}`);

  return {
    period,
    startIso: new Date(startMs).toISOString().slice(0, 10),
    endIso: new Date(endMs).toISOString().slice(0, 10),
    completedTaskIds: completed.map((t) => t.id),
    cancelledTaskIds: cancelled.map((t) => t.id),
    overdueOpenTaskIds: overdueOpen.map((t) => t.id),
    plannedSec,
    actualSec,
    habitAdherence,
    nextActions,
  };
}

function periodStart(period: ReviewPeriod, nowMs: number): number {
  const d = new Date(nowMs);
  if (period === 'daily') {
    d.setUTCHours(0, 0, 0, 0);
    return d.getTime();
  }
  if (period === 'weekly') {
    const dow = (d.getUTCDay() + 6) % 7; // Monday=0
    d.setUTCHours(0, 0, 0, 0);
    return d.getTime() - dow * 86_400_000;
  }
  d.setUTCDate(1);
  d.setUTCHours(0, 0, 0, 0);
  return d.getTime();
}

/** Log a decision (decisions journal — owned table). One command
 *  per decision (AD-7). */
export function logDecision(
  input: {
    userId: string;
    title: string;
    rationale?: string;
    context?: string;
    linkedTaskIds?: string[];
  },
  ctx: Ctx,
  id: string,
): ProductivityCommand {
  const ts = ctx.now;
  return {
    table: 'decisions',
    id,
    patch: {
      id,
      user_id: input.userId,
      title: input.title,
      ...(input.rationale !== undefined ? { rationale: input.rationale } : {}),
      ...(input.context !== undefined ? { context: input.context } : {}),
      decided_at: new Date(ts).toISOString(),
      linked_task_ids: orSetValues(input.linkedTaskIds ?? [], ts, ctx.clientId),
    },
    localMutationId: `dc-${id}-log`,
  };
}

// ---------------------------------------------------------------------------
// Analytics core (planned vs actual, procrastination, overload)
// ---------------------------------------------------------------------------

export interface AnalyticsSlice {
  /** planned load (estimates of open tasks) vs actual (timeSpentSec) */
  plannedSec: number;
  actualSec: number;
  /** procrastination ratio: overdue open / all open (0..1, higher = worse) */
  procrastination: number;
  /** true when the day has an overloaded hour bucket (05 S4.4) */
  overloaded: boolean;
  /** goal progress: achieved goals / active goals (0..1) */
  goalProgress: number;
}

export function aggregateAnalytics(
  tasks: Task[],
  goals: Goal[],
  nowMs: number,
): AnalyticsSlice {
  const open = tasks.filter((t) => t.status !== 'done' && t.status !== 'cancelled');
  let plannedSec = 0;
  let actualSec = 0;
  let overdue = 0;
  for (const t of tasks) {
    plannedSec += t.timeSpentSec ?? 0;
    if (t.status === 'done') actualSec += t.timeSpentSec ?? 0;
    if (
      open.includes(t) &&
      t.dueAt !== undefined &&
      Date.parse(t.dueAt) < nowMs
    ) overdue += 1;
  }
  const openCount = open.length;
  const procrastination = openCount > 0 ? overdue / openCount : 0;
  const achieved = goals.filter((g) => g.status === 'achieved');
  const goalProgress = goals.length > 0 ? achieved.length / goals.length : 0;
  void nowMs;
  return {
    plannedSec,
    actualSec,
    procrastination,
    overloaded: overdue >= 3 || openCount > 0 && overdue / openCount > 0.5,
    goalProgress,
  };
}

// ---------------------------------------------------------------------------
// AD-8: heavy work = persisted jobs. The module DEFINES the job
// descriptors; enqueuing goes through JobDispatcherPort (packages/data
// implements it). Idempotency key = kind + hash(payload) + user (0010 SSoT).
// ---------------------------------------------------------------------------

export interface ReviewJobDescriptor {
  /** the JobKind from the shared vocabulary (packages/domain jobs.ts) */
  jobKind: JobKind;
  /** idempotency key fragment (01 S5.3: kind + hash(payload) + user) */
  idempotencyKey: string;
  userId: string;
  payload: Record<string, unknown>;
}

/** Review preparation = a persisted job (AD-8), NOT a UI compute.
 *  JobKind `research` is the generic heavy-analysis worker (01 S5.3
 *  vocabulary); the payload is module-scoped so only Productivity
 *  writes its own review data. */
export function prepareReviewJob(
  period: ReviewPeriod,
  userId: string,
  range: { startIso: string; endIso: string },
): ReviewJobDescriptor {
  const payload = {
    module: 'productivity',
    op: 'review',
    period,
    range,
  };
  return {
    jobKind: 'research',
    idempotencyKey: `research:productivity:review:${userId}:${period}:${range.startIso}`,
    userId,
    payload,
  };
}

/** Analytics aggregation = persisted job (AD-8). Same `research`
 *  workerKind with a module-scoped payload. */
export function analyticsJob(
  userId: string,
  windowDays: number,
): ReviewJobDescriptor {
  const payload = { module: 'productivity', op: 'analytics', windowDays };
  return {
    jobKind: 'research',
    idempotencyKey: `research:productivity:analytics:${userId}:${windowDays}`,
    userId,
    payload,
  };
}
