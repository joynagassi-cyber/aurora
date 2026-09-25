/**
 * FocusSessionBilan score computation (G-H1 SSoT shape, 01 S4.1).
 *
 * The score is derived, not free-form: deterministic from the
 * persisted session row so it is re-computable. The bilan row itself
 * is persisted by Productivity/ATLAS (`session_bilan` jsonb, owned
 * column) — this module only computes the number.
 *
 * Composite = 50% adherence + 30% interruption + 20% task completion
 * (spec S15: focus adherence, interruption count, task completion).
 */

export interface BilanScoreInput {
  plannedMinutes: number;
  actualMinutes: number;
  interruptions: number;
  /** completed task ids within the session */
  completedTaskCount?: number;
  /** planned task ids the session targeted */
  plannedTaskCount?: number;
}

export interface BilanScore {
  score: number;
  adherence: number;
  interruptionPenalty: number;
  taskCompletion: number;
}

function clamp01(r: number): number {
  return Math.max(0, Math.min(1, r));
}
function clamp0_100(v: number): number {
  return Math.max(0, Math.min(100, v));
}
function round1(v: number): number {
  return Math.round(v * 10) / 10;
}

export function computeFocusBilanScore(input: BilanScoreInput): BilanScore {
  // Adherence: how close actual is to planned (capped at 100).
  const adherence =
    input.plannedMinutes <= 0
      ? 100
      : round1(
          clamp01(Math.min(input.actualMinutes, input.plannedMinutes) / input.plannedMinutes) * 100,
        );
  // Interruption penalty: each interruption costs up to 15 points.
  const interruptionPenalty = round1(clamp0_100(100 - input.interruptions * 15));
  // Task completion: ratio when tasks were targeted; neutral otherwise.
  const planned = input.plannedTaskCount ?? 0;
  const taskCompletion =
    planned === 0
      ? 100
      : round1(clamp01((input.completedTaskCount ?? 0) / planned) * 100);

  const score = round1(
    adherence * 0.5 + interruptionPenalty * 0.3 + taskCompletion * 0.2,
  );
  return { score, adherence, interruptionPenalty, taskCompletion };
}
