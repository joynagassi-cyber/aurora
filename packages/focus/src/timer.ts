/**
 * Focus session timer + state machine (in-app, spec S4/S6).
 *
 * The timer runs on the SYSTEM clock (04 S3.6.9: app kill loses
 * nothing — the persisted session row is the source of truth, AD-7).
 * This module is the pure in-app state machine: it advances a session
 * from `scheduled → starting → active → (paused) → ending →
 * completed` and reports the end reason, so the persistence side
 * (ATLAS) writes exactly the right row transition.
 *
 * Accounting model: `activeSec` = seconds spent ACTIVE only (pauses
 * excluded). `activeAnchor` is the wall-clock instant of the current
 * contiguous active streak; `activeSec + (now - anchor)` = total
 * active time. While paused there is no active accrual.
 */

export type FocusSessionState =
  | 'scheduled'
  | 'starting'
  | 'prechecking'
  | 'active'
  | 'paused'
  | 'ending'
  | 'completed'
  | 'interrupted'
  | 'restoring'
  | 'restored'
  | 'failed';

export type FocusEndReason =
  | 'manual'
  | 'expiry'
  | 'crash'
  | 'reboot'
  | 'restoring';

export interface FocusTimerState {
  state: FocusSessionState;
  /** ms epoch of the current active-streak start (null when not active) */
  activeAnchor: number | null;
  /** seconds spent in `active` state before the current streak */
  activeSec: number;
  /** total seconds spent in `paused` state */
  pausedSec: number;
  /** ms epoch of the current pause start (null when not paused) */
  pauseAnchor: number | null;
  /** planned duration in seconds (0 = open-ended) */
  plannedSec: number;
  endReason: FocusEndReason | null;
}

export interface FocusTimerConfig {
  /** clock source so the state machine stays pure/testable */
  now(): number;
}

export function newFocusTimer(plannedSec = 0): FocusTimerState {
  return {
    state: 'scheduled',
    activeAnchor: null,
    activeSec: 0,
    pausedSec: 0,
    pauseAnchor: null,
    plannedSec,
    endReason: null,
  };
}

/** total active seconds up to `t` (only while state = active). */
function activeTotal(s: FocusTimerState, t: number): number {
  if (s.state === 'active' && s.activeAnchor !== null) {
    return s.activeSec + Math.max(0, Math.floor((t - s.activeAnchor) / 1000));
  }
  return s.activeSec;
}

function totalPaused(s: FocusTimerState, t: number): number {
  if (s.state === 'paused' && s.pauseAnchor !== null) {
    return s.pausedSec + Math.max(0, Math.floor((t - s.pauseAnchor) / 1000));
  }
  return s.pausedSec;
}

/** scheduled → starting (the controller is about to run the pre-check). */
export function beginStart(s: FocusTimerState): FocusTimerState {
  return { ...s, state: 'starting' };
}

/** starting → prechecking → active: start the first active streak. */
export function markActive(
  s: FocusTimerState,
  cfg: FocusTimerConfig,
): FocusTimerState {
  const t = cfg.now();
  return { ...s, state: 'active', activeAnchor: t, activeSec: 0 };
}

/** Pause: freeze active-accrual. (Background app-kill is NOT a pause —
 *  the system clock keeps the session honest.) */
export function pause(s: FocusTimerState, cfg: FocusTimerConfig): FocusTimerState {
  const t = cfg.now();
  if (s.state !== 'active') return s;
  return {
    ...s,
    state: 'paused',
    activeSec: activeTotal(s, t),
    activeAnchor: null,
    pauseAnchor: t,
  };
}

/** Resume: start a fresh active streak from now. */
export function resume(s: FocusTimerState, cfg: FocusTimerConfig): FocusTimerState {
  const t = cfg.now();
  if (s.state !== 'paused') return s;
  return {
    ...s,
    state: 'active',
    pausedSec: totalPaused(s, t),
    pauseAnchor: null,
    activeAnchor: t,
  };
}

/**
 * Tick the timer. SETTLES: `activeSec`/`pausedSec` are advanced to `t`
 * and the corresponding anchor moves to `t`, so a later tick or
 * endSession only accrues the time SINCE the last settlement — no
 * double-counting. `expired` reports whether the planned duration has
 * been reached (the caller then ends the session with endReason='expiry').
 */
export function tick(
  s: FocusTimerState,
  cfg: FocusTimerConfig,
): { state: FocusTimerState; expired: boolean } {
  const t = cfg.now();
  let activeSec = s.activeSec;
  let activeAnchor = s.activeAnchor;
  let pausedSec = s.pausedSec;
  let pauseAnchor = s.pauseAnchor;
  if (s.state === 'active' && activeAnchor !== null) {
    activeSec = activeTotal(s, t);
    activeAnchor = t;
  }
  if (s.state === 'paused' && pauseAnchor !== null) {
    pausedSec = totalPaused(s, t);
    pauseAnchor = t;
  }
  const expired = s.plannedSec > 0 && s.state === 'active' && activeSec >= s.plannedSec;
  return {
    state: { ...s, activeSec, activeAnchor, pausedSec, pauseAnchor },
    expired,
  };
}

/** active → ending → completed (manual end, endReason='manual'). */
export function endSession(
  s: FocusTimerState,
  cfg: FocusTimerConfig,
  reason: Exclude<FocusEndReason, 'restoring'> = 'manual',
): FocusTimerState {
  const t = cfg.now();
  return {
    ...s,
    state: 'completed',
    activeSec: activeTotal(s, t),
    pausedSec: totalPaused(s, t),
    activeAnchor: null,
    pauseAnchor: null,
    endReason: reason,
  };
}

/** Crash / reboot: mark interrupted; the boot receiver (platform) runs
 *  the restore path (spec S7). endReason is set on restore. */
export function markInterrupted(
  s: FocusTimerState,
  reason: 'crash' | 'reboot',
): FocusTimerState {
  return {
    ...s,
    state: 'interrupted',
    activeAnchor: null,
    endReason: reason,
  };
}

/** interrupted → restoring → restored (boot-receiver default path). */
export function restore(s: FocusTimerState): FocusTimerState {
  return {
    ...s,
    state: 'restored',
    activeAnchor: null,
    pauseAnchor: null,
    endReason: 'restoring',
  };
}
