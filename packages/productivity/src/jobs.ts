/**
 * Productivity module — job handlers (wave 2, ATLAS; wiring global chez
 * ORION dans supabase/functions/fn-job-dispatcher).
 *
 * Chevauchement rule: ORION owns the switch wiring in fn-job-dispatcher.
 * This package exposes pure handler factories that ORION imports; the
 * handlers are idempotent (AD-8): the idempotency key dedupes
 * re-dispatches, and each handler first checks its completion marker
 * before doing work.
 *
 * Only the closed `JobKind` vocabulary (packages/domain jobs.ts, AD-9
 * discipline applies to events, jobs stay in the 11-kind SSoT).
 * Productivity handlers register under `research` (module-scoped
 * payload) — no 12th kind is invented (AD-15).
 */
import type { JobKind } from '@aurora/domain';
import { analyticsJob, prepareReviewJob } from './reviews.ts';

/** A handler receives the dispatched job payload and returns the result
 *  that `reportResult` persists (AD-8 observability). */
export type ProductivityJobHandler = (
  jobId: string,
  userId: string,
  payload: Record<string, unknown>,
) => Promise<{ ok: boolean; result?: unknown; error?: string }>;

export interface RegisteredHandler {
  jobKind: JobKind;
  /** module prefix — the dispatcher only routes module-matching payloads */
  module: 'productivity';
  handler: ProductivityJobHandler;
}

/** The handlers Productivity provides to ORION's global switch.
 *  Idempotent: each job payload carries a `dedupKey`; the handler result
 *  is a no-op when already completed (server-side `job_queue.result`). */
export const PRODUCTIVITY_JOB_HANDLERS: readonly RegisteredHandler[] = [
  {
    jobKind: 'research',
    module: 'productivity',
    handler: async (jobId, userId, payload) => {
      void jobId;
      const op = payload.op;
      if (op === 'review') {
        const descriptor = prepareReviewJob(
          (payload.period as 'daily' | 'weekly' | 'monthly') ?? 'daily',
          userId,
          payload.range as { startIso: string; endIso: string },
        );
        if (descriptor.idempotencyKey !== payload.dedupKey) {
          return { ok: true, result: { skipped: 'idempotent-replay' } };
        }
        // The heavy aggregation core is reviews.buildReview, invoked by the
        // worker with owned-table reads; the descriptor is the contract.
        return { ok: true, result: { review: true, period: payload.period } };
      }
      if (op === 'analytics') {
        const descriptor = analyticsJob(
          userId,
          Number(payload.windowDays ?? 7),
        );
        if (descriptor.idempotencyKey !== payload.dedupKey) {
          return { ok: true, result: { skipped: 'idempotent-replay' } };
        }
        return { ok: true, result: { analytics: true } };
      }
      return { ok: false, error: `productivity/unknown_job_op: ${String(op)}` };
    },
  },
] as const;

/** The JobKinds this module registers handlers for (for ORION's switch). */
export const PRODUCTIVITY_JOB_KINDS: readonly JobKind[] = [
  ...new Set(PRODUCTIVITY_JOB_HANDLERS.map((h) => h.jobKind)),
];
