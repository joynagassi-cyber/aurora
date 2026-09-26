/**
 * recovery-plan.ts — plan-level error recovery (docs/agent/error-recovery.md,
 * master mission S64).
 *
 * The 10 error classes (error-recovery.ts) pin WHAT each class means. This
 * module pins HOW a multi-step plan recovers from them:
 *   - classifyPlanError: map a failure signal (status code / kind /
 *     constraint) to an error class
 *   - replanPartial: given a plan + failure point, produce the resumption
 *     decision (which steps to retry, which to roll back, what to confirm,
 *     which JobKind persists the recovery work, AD-8)
 *
 * Deterministic logic — the Execution Engine (kernel S12) and the E2E
 * failure paths replay these decisions. No LLM judgment, no prose.
 */
import type { JobKind } from '@aurora/domain';
import type { ErrorClassId } from './types.ts';
import { ERROR_CLASSES } from './error-recovery.ts';

/** A plan step with enough state to reason about partial execution. */
export interface PlanStep {
  id: string;
  /** durable side effects already persisted (AD-8: Postgres / R2 / system state) */
  durable?: boolean;
  /** important/irreversible (ADR S5) — re-execution requires confirmation */
  important?: boolean;
  /**
   * this step invalidates the side effect of `compensates` when it fails
   * (the compensating action of that step runs first — rollback).
   */
  compensates?: string;
  /** job kind that executes the step (AD-8, AD-15) */
  jobKind?: JobKind;
}

/** The failure signal recorded by the Execution Engine at a step. */
export interface PlanFailure {
  stepId: string;
  /** status / error kind observed (429, 5xx, 401, offline, …) */
  kind:
    | 'provider_5xx'
    | 'provider_429'
    | 'timeout'
    | 'permission_denied'
    | 'offline'
    | 'auth_expired'
    | 'feature_disabled'
    | 'tool_unavailable'
    | 'schema_mismatch'
    | 'conflict'
    | 'constraint_violation';
  /** transient = bounded retry on the same provider / idempotency key */
  transient?: boolean;
  /** attempts already spent on this step (before this signal) */
  attempts?: number;
  /** AD-8 bounded retry ceiling for transient provider errors */
  maxAttempts?: number;
}

export interface RecoveryDecision {
  errorClass: ErrorClassId;
  /** retry the failed step now (transient, within the attempt budget) */
  retryStep: boolean;
  /** the attempt budget left for this step */
  attemptsLeft: number;
  /**
   * the step the resumption starts from (the failed step when retryable,
   * the next step when the failure was handled in-place).
   */
  resumeFromStep: string;
  /** compensation order (rollback of earlier durable steps invalidated by the failure) */
  compensations: string[];
  /** the user must confirm before resumption (ADR S5 / E-class contract) */
  needsConfirmation: boolean;
  /** the AD-8 job kind that persists / re-dispatches the recovery work */
  jobKind?: JobKind;
  /** one-line plan summary shown in AgentRunState */
  summary: string;
}

const CLASS_BY_KIND: Record<PlanFailure['kind'], ErrorClassId> = {
  provider_5xx: 'E1',
  provider_429: 'E1',
  timeout: 'E1',
  permission_denied: 'E2',
  offline: 'E3',
  auth_expired: 'E4',
  feature_disabled: 'E5',
  tool_unavailable: 'E6',
  schema_mismatch: 'E7',
  conflict: 'E8',
  constraint_violation: 'E10',
};

/** Transient classes: bounded retry on the same idempotency key (AD-8). */
const TRANSIENT: ReadonlySet<ErrorClassId> = new Set(['E1', 'E3', 'E4']);

/** Default AD-8 retry budget for transient provider errors (E1 spec: 3x). */
const DEFAULT_MAX_ATTEMPTS = 3;

export function classifyPlanError(failure: PlanFailure): ErrorClassId {
  return CLASS_BY_KIND[failure.kind];
}

export function errorClassErrorById(id: ErrorClassId) {
  return ERROR_CLASSES.find((e) => e.id === id);
}

/**
 * Produce the resumption decision for a plan after a step failure.
 *
 * Rules (per error class, docs/agent/error-recovery.md):
 *  - transient (E1/E3/E4): retry the failed step while the attempt budget
 *    allows; nothing rolls back.
 *  - E9-shaped inputs (constraint_violation handled as E10 on a confirmed
 *    destructive step): the whole operation is rolled back (Postgres ACID),
 *    re-execution always re-confirms.
 *  - non-transient failures (E2/E5/E6/E7/E8): the step pauses or degrades;
 *    resumption starts at the failed step, compensations run for any
 *    earlier durable step the failure invalidates (`compensates` edges).
 */
export function replanPartial(
  plan: readonly PlanStep[],
  failure: PlanFailure,
): RecoveryDecision {
  const errorClass = classifyPlanError(failure);
  const step = plan.find((s) => s.id === failure.stepId);
  const maxAttempts = failure.maxAttempts ?? DEFAULT_MAX_ATTEMPTS;
  const attemptsUsed = failure.attempts ?? 0;
  const transient = TRANSIENT.has(errorClass) && failure.transient !== false;
  const attemptsLeft = transient ? Math.max(0, maxAttempts - attemptsUsed) : 0;

  // Compensation: earlier steps the failed step would invalidate.
  const compensations: string[] = [];
  if (!transient) {
    for (const s of plan) {
      if (s.id === failure.stepId || !s.durable) continue;
      if (step?.compensates === s.id) compensations.push(s.id);
    }
  }

  const retryStep = transient && attemptsLeft > 0;
  const resumeFromStep = retryStep ? failure.stepId : nextStepAfter(plan, failure.stepId, retryStep);

  const needsConfirmation =
    !retryStep &&
    (ERROR_CLASSES.find((e) => e.id === errorClass)?.needsConfirmation ||
      step?.important === true);

  const summary = retryStep
    ? `${failure.stepId} transient (${errorClass}) — retry attempt ${attemptsUsed + 1}/${maxAttempts}`
    : `${failure.stepId} failed (${errorClass}) — resume from ${resumeFromStep}${
        compensations.length ? `, roll back: ${compensations.join(', ')}` : ''
      }${needsConfirmation ? ' (confirmation required)' : ''}`;

  return {
    errorClass,
    retryStep,
    attemptsLeft,
    resumeFromStep,
    compensations,
    needsConfirmation,
    jobKind: step?.jobKind,
    summary,
  };
}

function nextStepAfter(plan: readonly PlanStep[], fromStepId: string, stay: boolean): string {
  if (stay) return fromStepId;
  const idx = plan.findIndex((s) => s.id === fromStepId);
  const next = idx >= 0 ? plan[idx + 1] : undefined;
  // E9 contract: even when the step failed, the resume point is the failed
  // step itself if it is retryable in place (degradation), else the next
  // surviving step.
  return next?.id ?? fromStepId;
}
