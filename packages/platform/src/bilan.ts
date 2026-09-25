/**
 * FocusSessionBilan computation (G-H1) — the SCORE is derived, not
 * persisted freely. The bilan SSoT shape (01 S4.1, ChartSpec `focusBilan`
 * 05 S3.6.9) is produced by Productivity at session end (ATLAS); this
 * module provides the pure scoring function so the number is
 * deterministic and re-computable from a persisted session row.
 *
 * Score = 0..100 composite: focus adherence (planned vs actual),
 * interruption penalty, bonus on task completion (spec S15 + master
 * mission S41).
 */

export interface BilanInput {
  plannedMinutes: number;
  actualMinutes: number;
  interruptions: number;
  /** completed task ids within the session (optional, 0..n) */
  completedTaskCount?: number;
  /** planned task ids the session targeted (optional) */
  plannedTaskCount?: number;
}

export interface FocusBilanScore {
  score: number;
  /** the component contributions, clamped 0..100 */
  adherence: number;
  interruptionPenalty: number;
  taskCompletion: number;
}

/** Adherence: how close actual is to planned (min(actual,planned)/planned). */
function adherenceScore(planned: number, actual: number): number {
  if (planned <= 0) return 100;
  return clamp100(Math.min(actual, planned) / planned) * 100;
}

/** Each interruption costs up to 15 points, floor 0. */
function interruptionPenaltyOf(interruptions: number): number {
  return clamp0(100 - interruptions * 15);
}

/** Task completion ratio when tasks were targeted; neutral (100) otherwise. */
function taskScore(input: BilanInput): number {
  const planned = input.plannedTaskCount ?? 0;
  if (planned === 0) return 100;
  const done = input.completedTaskCount ?? 0;
  return clamp100(done / planned) * 100;
}

function clamp100(r: number): number {
  return Math.max(0, Math.min(1, r));
}
function clamp0(v: number): number {
  return Math.max(0, Math.min(100, v));
}

/** Deterministic composite: 50% adherence + 30% interruption + 20% task. */
export function computeFocusBilanScore(input: BilanInput): FocusBilanScore {
  const adherence = round1(adherenceScore(
    input.plannedMinutes,
    input.actualMinutes,
  ));
  const interruptionPenalty = round1(interruptionPenaltyOf(input.interruptions));
  const taskCompletion = round1(taskScore(input));
  const score = round1(
    adherence * 0.5 + interruptionPenalty * 0.3 + taskCompletion * 0.2,
  );
  return { score, adherence, interruptionPenalty, taskCompletion };
}

function round1(v: number): number {
  return Math.round(v * 10) / 10;
}
