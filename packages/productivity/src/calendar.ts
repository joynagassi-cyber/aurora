/**
 * Productivity module — Calendar & time blocking (wave 2, ATLAS).
 *
 * master-feature-catalog `productivity.calendar` + 05 S4.4: agenda /
 * time blocking / conflict + overload detection. UI renderer =
 * FullCalendar (docs/ui-libraries.md — NOT ion-calendar); this package
 * stays vendor-free (AD-1): it computes, FullCalendar displays.
 *
 * Tables owned (0002_productivity.sql): `calendar_events` — the
 * server-side name; local mirror entity is `events` (03 S4.2,
 * Event in packages/domain). Recurrences are materialized rows
 * (01 S4.1) — never a rule table.
 */
import type { Event as CalendarEvent } from '@aurora/domain';
import type { Ctx, ProductivityCommand } from './tasks.ts';
import { nextRecurrence } from './tasks.ts';

// ---------------------------------------------------------------------------
// Commands
// ---------------------------------------------------------------------------

export interface NewCalendarEvent {
  userId: string;
  title: string;
  /** ISO 8601 */
  startAt: string;
  endAt?: string;
  location?: string;
  allDay?: boolean;
  recurring?: boolean;
  recurrenceRule?: string;
}

/** Create a calendar event (calendar_events table, AD-7). */
export function createEvent(
  input: NewCalendarEvent,
  _ctx: Ctx,
  id: string,
): ProductivityCommand {
  const patch: Record<string, unknown> = {
    id,
    user_id: input.userId,
    title: input.title,
    start_at: input.startAt,
    all_day: input.allDay ?? false,
  };
  if (input.endAt !== undefined) patch.end_at = input.endAt;
  if (input.location !== undefined) patch.location = input.location;
  if (input.recurring) {
    patch.recurrence = {
      active: true,
      rule: input.recurrenceRule ?? 'FREQ=DAILY',
      materialized: true,
    };
  }
  return {
    table: 'calendar_events',
    id,
    patch,
    localMutationId: `ce-${id}-create`,
  };
}

/** Reschedule (move/resize) a calendar event — time-blocking
 *  re-planning is a CONFIRMATION_REQUIRED agent action (catalog);
 *  locally it is a single partial command. */
export function rescheduleEvent(
  ev: CalendarEvent,
  startAt: string,
  endAt?: string,
  _ctx?: Ctx,
  localMutationId?: string,
): ProductivityCommand {
  const patch: Record<string, unknown> = { id: ev.id, start_at: startAt };
  if (endAt !== undefined) patch.end_at = endAt;
  return {
    table: 'calendar_events',
    id: ev.id,
    patch,
    localMutationId: localMutationId ?? `ce-${ev.id}-move`,
  };
}

// ---------------------------------------------------------------------------
// Conflict & overload detection (pure — 05 S4.4)
// ---------------------------------------------------------------------------

export interface Conflict {
  kind: 'overlap' | 'back-to-back' | 'overload';
  aId: string;
  bId?: string;
  /** overlap duration in ms (overlap kind only) */
  overlapMs?: number;
  /** hour bucket (overload kind) */
  hourIso?: string;
  /** how many events share the bucket (overload) */
  count?: number;
}

function evEndMs(e: Pick<CalendarEvent, 'startAt' | 'endAt' | 'allDay'>): number {
  const start = Date.parse(e.startAt);
  if (e.endAt) return Date.parse(e.endAt);
  if (e.allDay) {
    const d = new Date(start);
    d.setUTCDate(d.getUTCDate() + 1);
    return d.getTime();
  }
  // default 30-min event when no end (agendar convention)
  return start + 30 * 60_000;
}

/** Pairwise overlaps + overloaded hour buckets (≥3 events).
 *  Deterministic; input order irrelevant (sorted internally). */
export function detectConflicts(
  events: Array<Pick<CalendarEvent, 'id' | 'startAt' | 'endAt' | 'allDay'>>,
  _now?: Date,
): Conflict[] {
  const sorted = [...events].sort(
    (a, b) => Date.parse(a.startAt) - Date.parse(b.startAt),
  );
  const out: Conflict[] = [];
  for (let i = 0; i < sorted.length; i++) {
    for (let j = i + 1; j < sorted.length; j++) {
      const a = sorted[i]!;
      const b = sorted[j]!;
      const aStart = Date.parse(a.startAt);
      const bStart = Date.parse(b.startAt);
      const aEnd = evEndMs(a);
      const bEnd = evEndMs(b);
      if (bStart < aEnd && aStart < bEnd) {
        const overlapMs = Math.min(aEnd, bEnd) - Math.max(aStart, bStart);
        out.push(
          overlapMs > 0
            ? { kind: 'overlap', aId: a.id, bId: b.id, overlapMs }
            : { kind: 'back-to-back', aId: a.id, bId: b.id },
        );
      }
    }
  }
  // overload buckets: whole local hours with ≥3 starts
  const buckets = new Map<string, number>();
  for (const e of sorted) {
    const h = new Date(Date.parse(e.startAt));
    h.setUTCMinutes(0, 0, 0);
    const key = h.toISOString();
    buckets.set(key, (buckets.get(key) ?? 0) + 1);
  }
  for (const [hourIso, count] of buckets) {
    if (count >= 3) out.push({ kind: 'overload', aId: hourIso, hourIso, count });
  }
  return out;
}

// ---------------------------------------------------------------------------
// Time blocking: plan the day from AVAILABLE time (05 S4.4: quality
// depends on user-entered available windows — known limitation §21).
// ---------------------------------------------------------------------------

export interface AvailableWindow {
  startMs: number;
  endMs: number;
}

export interface BlockPlanItem {
  taskId: string;
  /** proposed start (ms) */
  startMs: number;
  /** proposed end (ms) */
  endMs: number;
}

export interface BlockPlan {
  blocks: BlockPlanItem[];
  /** tasks that did NOT fit the available windows */
  unscheduled: string[];
}

/** Greedy longest-window-first packing of tasks with estimates into
 *  the free windows, honoring task order (q1 first is the caller's
 *  job — eisenhower feeds this). Deterministic. */
export function planTimeBlocks(
  available: AvailableWindow[],
  tasks: Array<{ id: string; estimateSec?: number }>,
  minBufferSec = 15 * 60,
): BlockPlan {
  // sort by estimate desc so big tasks get the best windows (LPT heuristic)
  const ordered = [...tasks].sort(
    (a, b) => (b.estimateSec ?? 30 * 60) - (a.estimateSec ?? 30 * 60),
  );
  const cursor = available.map((w) => w.startMs);
  const blocks: BlockPlanItem[] = [];
  const unscheduled: string[] = [];
  const DEFAULT_SEC = 30 * 60;
  const bufferMs = minBufferSec * 1000;
  for (const t of ordered) {
    const needMs = (t.estimateSec ?? DEFAULT_SEC) * 1000;
    let placed = false;
    for (let w = 0; w < available.length; w++) {
      const win = available[w]!;
      const start = cursor[w]!;
      if (start + needMs + bufferMs <= win.endMs) {
        blocks.push({ taskId: t.id, startMs: start, endMs: start + needMs });
        cursor[w] = start + needMs + bufferMs;
        placed = true;
        break;
      }
    }
    if (!placed) unscheduled.push(t.id);
  }
  blocks.sort((a, b) => a.startMs - b.startMs);
  return { blocks, unscheduled };
}

// ---------------------------------------------------------------------------
// Recurring calendar event materialization (01 S4.1: materialized rows)
// ---------------------------------------------------------------------------

/** Materialize the next occurrence of a recurring calendar event.
 *  Returns the next command, or null when the rule is unsupported. */
export function materializeRecurringEvent(
  ev: CalendarEvent,
  ctx: Ctx,
  newId: string,
): ProductivityCommand | null {
  if (!ev.recurrenceRule) return null;
  const next = nextRecurrence(ev.recurrenceRule, ctx.now);
  if (next === null) return null;
  const start = new Date(next);
  const end = ev.endAt
    ? new Date(next + (Date.parse(ev.endAt) - Date.parse(ev.startAt))).toISOString()
    : undefined;
  return {
    table: 'calendar_events',
    id: newId,
    patch: {
      id: newId,
      user_id: ev.userId,
      title: ev.title,
      start_at: start.toISOString(),
      ...(end ? { end_at: end } : {}),
      ...(ev.location !== undefined ? { location: ev.location } : {}),
      all_day: ev.allDay ?? false,
      recurrence: { active: true, rule: ev.recurrenceRule, materialized: true },
    },
    localMutationId: `ce-${newId}-recurrence`,
  };
}
