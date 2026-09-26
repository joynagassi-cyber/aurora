/**
 * @aurora/ascent — depth selection (wave 3, docs/ascent/overview.md S13).
 *
 * Chooses the per-step DepthLevel (quick | standard | deep). The 3 levels
 * modify CONTENT, not architecture — they pick how many activities the
 * path-builder attaches to a step, all through the SAME IR shape.
 *
 * Deterministic (overview S22: no second pedagogical LLM). Inputs:
 *  - the learner's baseline state for the step's skill (S6.2, 5 states);
 *  - the step's importance in the trajectory (prerequisite = core);
 *  - the time window to the goal's target date (exam week vs semester).
 */
import type { DepthLevel, LearnerBaseline } from '@aurora/domain';

/** What the goal asks of a step (overview S13: exam = Deep for core…). */
export interface DepthImportance {
  /** the step's skill (Progress skill_id) */
  skillId?: string;
  /** prerequisite = core of the trajectory; peripheral = auxiliary */
  importance: 'core' | 'standard' | 'peripheral';
}

export interface DepthSelectionInput {
  baseline: LearnerBaseline;
  importance: DepthImportance;
  /** ISO deadline of the goal (AscentLearningIR.targetDate); undefined = no deadline pressure */
  targetDate?: string;
  /** "now" for the time-window computation (injectable, deterministic) */
  now?: string;
}

/** Hours until the target date (negative = already past). */
export function hoursUntil(target: string, now: string): number {
  const ms = Date.parse(target) - Date.parse(now);
  if (Number.isNaN(ms)) throw new Error(`ascent/bad_target_date: ${target}`);
  return ms / 3_600_000;
}

/** Exam-week pressure: < 72h to the deadline = time-constrained. */
export function isTimeConstrained(target: string | undefined, now: string): boolean {
  return target !== undefined && hoursUntil(target, now) <= 72;
}

/**
 * Select the depth for one step. Rules (overview S13 + S10):
 *
 *  1. mastered skill → 'quick' (consolidation only; README S10:
 *     mastered = skip, never deepen what is already proven).
 *  2. core + time-constrained → 'quick' (the QCM is the priority, not
 *     the reading — S10 "exam week, time-constrained").
 *  3. core + fragile → 'standard' (remediation-grade practice).
 *  4. core + unknown/partial/known → 'deep' (mastery of the
 *     prerequisite before it chains forward).
 *  5. peripheral → 'quick' (never spend Deep on the non-critical path).
 */
export function selectDepth(input: DepthSelectionInput): DepthLevel {
  const state = input.baseline.skillStates.find(
    (s) => s.skillId === input.importance.skillId,
  )?.status;

  if (state === 'mastered') return 'quick';
  if (input.importance.importance === 'peripheral') return 'quick';
  if (isTimeConstrained(input.targetDate, input.now ?? input.baseline.computedAt)) {
    return 'quick';
  }
  if (input.importance.importance === 'core') {
    return state === 'fragile' ? 'standard' : 'deep';
  }
  // standard-importance default
  return 'standard';
}

/** The activity budget per depth level (S13 table). */
export const DEPTH_BUDGETS: Record<
  DepthLevel,
  { qcmItems: number; examples: number; flashcards: number; openProblems: number; mirror: boolean; derivation: boolean }
> = {
  quick: { qcmItems: 5, examples: 1, flashcards: 0, openProblems: 0, mirror: false, derivation: false },
  standard: { qcmItems: 10, examples: 2, flashcards: 3, openProblems: 0, mirror: false, derivation: false },
  deep: { qcmItems: 20, examples: 3, flashcards: 10, openProblems: 1, mirror: true, derivation: true },
};
