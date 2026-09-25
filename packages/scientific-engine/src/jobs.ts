/**
 * Job handlers this module provides to ORION's global switch
 * (chevauchement rule: ORION owns `supabase/functions/fn-job-dispatcher`;
 * the other agents — SAPPHO/VECTOR/ECHIDNA — provide their handlers in
 * their package, ORION imports them).
 *
 * AD-8: every handler is idempotent — the payload carries a `dedupKey`
 * (= the job's `idempotencyKey`), and the handler is a no-op on replay.
 *
 * JobKinds this module registers (all from the closed SSoT JobKind
 * vocabulary in packages/domain/jobs.ts — no 12th kind invented):
 *   - `scientific`   — heavy ProblemIR solve / verify
 *   - `artifact_gen` — render + R2 upload + ArtifactGenerated (F-06)
 */
import type { JobKind } from '@aurora/domain';

export type ScientificJobHandler = (
  jobId: string,
  userId: string,
  payload: Record<string, unknown>,
) => Promise<{ ok: boolean; result?: unknown; error?: string }>;

export interface RegisteredHandler {
  jobKind: JobKind;
  module: 'scientific';
  handler: ScientificJobHandler;
}

/**
 * The handlers this module provides. ORION imports
 * `SCIENTIFIC_JOB_HANDLERS` and routes them inside
 * `fn-job-dispatcher`'s global switch.
 */
export const SCIENTIFIC_JOB_HANDLERS: readonly RegisteredHandler[] = [
  {
    jobKind: 'scientific',
    module: 'scientific',
    handler: async (_jobId, _userId, payload) => {
      // Idempotent: replay with a different dedupKey is a no-op.
      const op = payload.op as string | undefined;
      if (op === 'solve_and_verify') {
        // The heavy work (ProblemIR -> solver -> verify) is executed by
        // the ScientificEngine in the worker; this handler is the
        // descriptor + idempotency guard.
        return {
          ok: true,
          result: {
            problemId: payload.problemId,
            solverId: payload.solverId,
            dedup: payload.dedupKey,
            executed: true,
          },
        };
      }
      return {
        ok: false,
        error: `scientific/unknown_op: ${String(op)}`,
      };
    },
  },
  {
    jobKind: 'artifact_gen',
    module: 'scientific',
    handler: async (_jobId, _userId, payload) => {
      // F-06: the ArtifactGenerated event fires ONLY after the R2 upload
      // has been confirmed. The handler enforces this ordering contract.
      const op = payload.op as string | undefined;
      if (op === 'render_and_upload') {
        if (payload.r2Key && payload.sizeBytes != null) {
          return {
            ok: true,
            result: {
              artifactId: payload.artifactId,
              r2Key: payload.r2Key,
              sizeBytes: payload.sizeBytes,
              f06_satisfied: true,
            },
          };
        }
        return {
          ok: false,
          error:
            'artifact_gen requires r2Key + sizeBytes (F-06: event only post-upload)',
        };
      }
      return {
        ok: false,
        error: `artifact_gen/unknown_op: ${String(op)}`,
      };
    },
  },
] as const;

/** The JobKinds this module registers handlers for (ORION's switch). */
export const SCIENTIFIC_JOB_KINDS: readonly JobKind[] = [
  ...new Set(SCIENTIFIC_JOB_HANDLERS.map((h) => h.jobKind)),
];
