/**
 * Productivity module — Habits & Routines (wave 2, ATLAS).
 *
 * master-feature-catalog `productivity.habits`: daily/weekly habits +
 * routines (temporal anchors) + adherence analytics; `HabitStreak`
 * heatmap (05 S3.6.12 — UI renders via AntV G2 in @aurora/ui).
 *
 * Streak math is pure and deterministic: adherence = completions on
 * the days the cadence requires (daily = last N days minus gaps;
 * weekly = required weekdays met this week). The habit `completions`
 * live in the habits table (0002 SSoT: `habits.streak` + local
 * completion rows owned by Productivity — single writer AD-7).
 */
import type { Ctx, ProductivityCommand } from './tasks.ts';
import type { OrSetValue } from '@aurora/domain';

export type HabitCadence = 'daily' | 'weekly' | 'custom';

export interface NewHabit {
  userId: string;
  title: string;
  cadence: HabitCadence;
  /** 1..7 for weekly (Mon=1 … Sun=7) */
  weekdays?: number[];
  /** custom cadence (e.g. every 2nd day of week) */
  recurrenceRule?: string;
}

/** Create a habit (habits table). */
export function createHabit(
  input: NewHabit,
  ctx: Ctx,
  id: string,
): ProductivityCommand {
  void ctx;
  const patch: Record<string, unknown> = {
    id,
    user_id: input.userId,
    name: input.title,
    status: 'active',
    streak: 0,
    frequency: {
      cadence: input.cadence,
      ...(input.weekdays ? { weekdays: input.weekdays } : {}),
      ...(input.recurrenceRule ? { rule: input.recurrenceRule } : {}),
    },
  };
  return {
    table: 'habits',
    id,
    patch,
    localMutationId: `hb-${id}-create`,
  };
}

/** Mark a habit done for a calendar day (ISO date `YYYY-MM-DD`).
 *  One command per completion (AD-7/F-03); the habits table owns
 *  both the row and its completions JSON. */
export function recordHabitCompletion(
  habitId: string,
  dateIso: string,
  ctx: Ctx,
  localMutationId?: string,
): ProductivityCommand {
  void ctx;
  return {
    table: 'habits',
    id: habitId,
    patch: {
      id: habitId,
      completions_add: [dateIso], // OR-Set add (03 S5.3)
    },
    localMutationId: localMutationId ?? `hb-${habitId}-${dateIso}`,
  };
}

/** Compute a streak from the completion set + cadence.
 *  `datesIso` = ascending UTC day keys `YYYY-MM-DD`. Deterministic. */
export function habitStreak(
  datesIso: string[],
  cadence: HabitCadence,
  weekdays?: number[],
  nowMs = Date.now(),
): { current: number; best: number; days: string[] } {
  const set = new Set(datesIso);
  const todayIso = isoDay(nowMs);
  // iterate back from today; streak breaks on a MISSED required day
  // (a future/unknown day never breaks the current streak)
  let current = 0;
  const cursor = new Date(nowMs);
  const startIso = datesIso.length > 0 ? [...datesIso].sort()[0]! : todayIso;
  for (let i = 0; i < 4000; i++) {
    const iso = isoDay(cursor.getTime());
    if (iso < startIso) break; // reached the start of the recorded history
    const required = isRequiredDay(cadence, weekdays, cursor);
    if (set.has(iso)) {
      current += 1;
    } else if (required) {
      break; // missed a required day
    }
    cursor.setUTCDate(cursor.getUTCDate() - 1);
  }
  // best streak over the whole history: ascending runs broken only by a
  // missed REQUIRED day (skipped non-required days don't break weekly/custom).
  const sorted = [...new Set(datesIso)].sort();
  let best = 0;
  let run = 0;
  let prev: string | null = null;
  for (const iso of sorted) {
    if (prev !== null && isConsecutive(prev, iso, cadence, weekdays)) run += 1;
    else run = 1;
    best = Math.max(best, run);
    prev = iso;
  }
  return { current, best: Math.max(best, current), days: sorted };
}

function isConsecutive(a: string, b: string, cadence: HabitCadence, weekdays?: number[]): boolean {
  const da = Date.parse(a + 'T00:00:00Z');
  const db = Date.parse(b + 'T00:00:00Z');
  if (cadence === 'daily') return db - da === 86_400_000;
  if (cadence === 'weekly') {
    const wb = new Date(db).getUTCDay();
    const need = new Set((weekdays ?? [1, 2, 3, 4, 5, 6, 7]).map((d) => (d % 7)));
    return need.has(wb) && db > da;
  }
  return db > da;
}

function isRequiredDay(
  cadence: HabitCadence,
  weekdays: number[] | undefined,
  d: Date,
): boolean {
  if (cadence === 'daily') return true;
  if (cadence === 'weekly') {
    // JS getUTCDay: 0=Sun..6=Sat; spec 1=Mon..7=Sun
    const spec = d.getUTCDay() % 7;
    return (weekdays ?? [spec + 1]).includes(spec + 1);
  }
  return true; // custom: every day counts
}

function isoDay(ms: number): string {
  return new Date(ms).toISOString().slice(0, 10);
}

/** Heatmap cells for the HabitStreak view (05 S3.6.12: last N weeks,
 *  weekly column per AntV G2 heatmap). */
export interface HeatmapCell {
  dateIso: string;
  /** 0..1 adherence on required days (daily: completed or not) */
  value: number;
  required: boolean;
}

export function habitHeatmap(
  datesIso: string[],
  weeks = 16,
  cadence: HabitCadence = 'daily',
  weekdays?: number[],
  nowMs = Date.now(),
): HeatmapCell[] {
  const set = new Set(datesIso);
  const start = new Date(nowMs - weeks * 7 * 86_400_000);
  const out: HeatmapCell[] = [];
  // exactly weeks*7 UTC day cells, end day = today (the week columns render
  // right-to-left, most recent week last)
  for (let t = start.getTime(); t <= start.getTime() + (weeks * 7 - 1) * 86_400_000; t += 86_400_000) {
    const d = new Date(t);
    const iso = isoDay(t);
    const required = isRequiredDay(cadence, weekdays, d);
    out.push({
      dateIso: iso,
      value: set.has(iso) ? 1 : 0,
      required,
    });
  }
  return out;
}

// ---------------------------------------------------------------------------
// Routines (temporal anchors + step lists — owned routines table)
// ---------------------------------------------------------------------------

export interface NewRoutine {
  userId: string;
  title: string;
  /** morning / evening / study / custom */
  kind: 'morning' | 'evening' | 'study' | 'custom';
  /** step refs (OR-Set input) */
  steps: string[];
  /** habit ids attached to this routine */
  habitIds: string[];
}

export function createRoutine(
  input: NewRoutine,
  ctx: Ctx,
  id: string,
): ProductivityCommand {
  const ts = ctx.now;
  const mk = (vals: string[]): OrSetValue[] => vals.map((v) => ({ v, ts, c: ctx.clientId }));
  return {
    table: 'routines',
    id,
    patch: {
      id,
      user_id: input.userId,
      name: input.title,
      status: 'active',
      anchor: { kind: input.kind },
      steps: mk(input.steps),
      attached_habit_ids: mk(input.habitIds),
    },
    localMutationId: `rt-${id}-create`,
  };
}
