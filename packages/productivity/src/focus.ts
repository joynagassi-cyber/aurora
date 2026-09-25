/**
 * Productivity module — Focus Mode (wave 2, ATLAS; DPC chez HYPATIYAS).
 *
 * master-feature-catalog `productivity.focus`: in-app focus sessions +
 * Pomodoro + blocklist = FULL; app blocking = PLATFORM_DEPENDENT
 * (v1.8 DPC / OQ-17 — that layer is the HYPATIYAS FocusControllerPort
 * DPC; this file owns the SESSION + TIMER + blocklist domain logic).
 *
 * Tables owned (0002_productivity.sql): `focus_sessions` (incl. the
 * notification/call/app-rules jsonb + session_bilan columns, G-H1).
 * HYPATIYAS never writes these tables (chevauchement rule: HYPATIYAS
 * = DPC system layer only — FocusControllerPort + setPackagesSuspended
 * + boot receiver).
 */
import type { FocusSession } from '@aurora/domain';
import type { Ctx, ProductivityCommand } from './tasks.ts';

export type FocusMode = 'pomodoro' | 'timer' | 'open';

/** Pomodoro cycle defaults (configurable per user later). */
export const POMODORO = {
  focusMin: 25,
  shortBreakMin: 5,
  longBreakMin: 15,
  cyclesBeforeLong: 4,
} as const;

export interface PomodoroState {
  phase: 'focus' | 'short_break' | 'long_break';
  /** remaining seconds in the current phase */
  remainingSec: number;
  /** completed focus cycles in this sit */
  cyclesDone: number;
}

export interface NewFocusSession {
  userId: string;
  mode: FocusMode;
  plannedDurationSec?: number;
  /** block profile id (focus app rules engaged, 04 S4.1) */
  blockProfile?: string;
  /** linked tasks (OR-Set input) */
  taskIds?: string[];
}

/** Open a focus session (focus_sessions table — owned, AD-7).
 *  The DPC layer (HYPATIYAS) is invoked SEPARATELY via
 *  FocusControllerPort; this command only persists the session. */
export function startFocusSession(
  input: NewFocusSession,
  ctx: Ctx,
  id: string,
): ProductivityCommand {
  const ts = ctx.now;
  return {
    table: 'focus_sessions',
    id,
    patch: {
      id,
      user_id: input.userId,
      started_at: new Date(ts).toISOString(),
      status: 'active',
      mode: input.mode,
      ...(input.plannedDurationSec !== undefined
        ? { planned_minutes: Math.round(input.plannedDurationSec / 60) }
        : {}),
      ...(input.blockProfile
        ? { focus_app_rules: { profile: input.blockProfile } }
        : {}),
      linked_task_ids: (input.taskIds ?? []).map((v) => ({
        v,
        ts,
        c: ctx.clientId,
      })),
    },
    localMutationId: `fs-${id}-start`,
  };
}

/** End a session + write the G-H1 bilan (planned vs actual, 01 S4.1
 *  session_bilan jsonb — owned column). */
export function endFocusSession(
  session: FocusSession,
  ctx: Ctx,
  opts?: { interruptions?: number; notes?: string },
): ProductivityCommand {
  const startedMs = Date.parse(session.startedAt);
  const endMs = ctx.now;
  const actualSec = Math.max(0, Math.round((endMs - startedMs) / 1000));
  const plannedSec = session.plannedDurationSec;
  return {
    table: 'focus_sessions',
    id: session.id,
    patch: {
      id: session.id,
      ended_at: new Date(endMs).toISOString(),
      status: 'ended',
      actual_minutes: Math.round(actualSec / 60),
      session_bilan: {
        focus_session_id: session.id,
        completed_at: new Date(endMs).toISOString(),
        ...(plannedSec !== undefined ? { planned_duration_sec: plannedSec } : {}),
        actual_duration_sec: actualSec,
        ...(opts?.interruptions !== undefined
          ? { interruptions: opts.interruptions }
          : {}),
        ...(opts?.notes !== undefined ? { notes: opts.notes } : {}),
      },
    },
    localMutationId: `fs-${session.id}-end`,
  };
}

// ---------------------------------------------------------------------------
// Pomodoro timer state machine (pure — the UI ticks it, no vendor)
// ---------------------------------------------------------------------------

/** Tick a pomodoro state machine by `elapsedSec`. Returns the new
 *  state + whether a phase transition happened (UI chime/haptics). */
export function tickPomodoro(
  prev: PomodoroState,
  elapsedSec: number,
  cfg: Partial<typeof POMODORO> = {},
): { state: PomodoroState; transitioned: boolean } {
  const focusSec = (cfg.focusMin ?? POMODORO.focusMin) * 60;
  const shortSec = (cfg.shortBreakMin ?? POMODORO.shortBreakMin) * 60;
  const longSec = (cfg.longBreakMin ?? POMODORO.longBreakMin) * 60;
  const before = (cfg.cyclesBeforeLong ?? POMODORO.cyclesBeforeLong);

  let rem = prev.remainingSec - elapsedSec;
  let { phase, cyclesDone } = prev;
  let transitioned = false;

  while (rem <= 0) {
    transitioned = true;
    if (phase === 'focus') {
      cyclesDone += 1;
      const useLong = cyclesDone % before === 0;
      phase = useLong ? 'long_break' : 'short_break';
      rem += (useLong ? longSec : shortSec);
    } else {
      phase = 'focus';
      rem += focusSec;
    }
  }
  return { state: { phase, remainingSec: rem, cyclesDone }, transitioned };
}

export function newPomodoro(cfg?: Partial<typeof POMODORO>): PomodoroState {
  return {
    phase: 'focus',
    remainingSec: (cfg?.focusMin ?? POMODORO.focusMin) * 60,
    cyclesDone: 0,
  };
}

/** Minutes remaining in the current phase (display helper, UI token). */
export function pomodoroDisplay(s: PomodoroState): { min: number; label: string } {
  const min = Math.max(0, Math.ceil(s.remainingSec / 60));
  const label =
    s.phase === 'focus'
      ? 'Focus'
      : s.phase === 'short_break'
        ? 'Short break'
        : 'Long break';
  return { min, label };
}

// ---------------------------------------------------------------------------
// Blocklist (focus app rules — owned focus_sessions jsonb columns)
// ---------------------------------------------------------------------------

export interface FocusBlockRule {
  appId: string;
  action: 'block' | 'limit';
  dailyLimitMin?: number;
  enabled: boolean;
}

/** Toggle a block rule in the active session's focus_app_rules. */
export function toggleBlockRule(
  session: FocusSession,
  rule: FocusBlockRule,
  enabled: boolean,
  currentRules: FocusBlockRule[],
  ctx: Ctx,
): ProductivityCommand {
  void ctx;
  const next = currentRules.some((r) => r.appId === rule.appId)
    ? currentRules.map((r) => (r.appId === rule.appId ? { ...r, enabled } : r))
    : [...currentRules, { ...rule, enabled }];
  return {
    table: 'focus_sessions',
    id: session.id,
    patch: {
      id: session.id,
      focus_app_rules: { rules: next },
    },
    localMutationId: `fs-${session.id}-rule-${rule.appId}`,
  };
}
