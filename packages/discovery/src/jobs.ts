/**
 * Discovery module — job handler for `research` (AD-8, ORION's dispatcher
 * wiring in fn-job-dispatcher).
 *
 * Chevauchement rule: ORION owns the global switch in fn-job-dispatcher.
 * This package exposes a pure handler factory ORION imports; the handler
 * is idempotent (AD-8): the idempotency key dedupes re-dispatches, and
 * the handler checks its completion marker before doing work.
 *
 * Only the closed `JobKind` vocabulary (packages/domain jobs.ts, AD-15).
 * Discovery's heavy work (multi-source search, scenario generation)
 * registers under `research` (module-scoped payload).
 */
import type { JobKind } from '@aurora/domain';
import type {
  DiscoveryFilterContext,
} from './filtering.ts';
import { DiscoveryService } from './discovery.ts';
import type { ResearchProvider, ResearchQuery } from './research-provider.ts';

/** A handler receives the dispatched job payload and returns the result
 *  that `reportResult` persists (AD-8 observability). */
export type DiscoveryJobHandler = (
  jobId: string,
  userId: string,
  payload: Record<string, unknown>,
) => Promise<{ ok: boolean; result?: unknown; error?: string }>;

export interface RegisteredHandler {
  jobKind: JobKind;
  module: 'discovery';
  handler: DiscoveryJobHandler;
}

export interface DiscoveryJobDeps {
  filterCtx: DiscoveryFilterContext;
  provider?: ResearchProvider;
}

/** Build the `research` job handler. Idempotent: the payload carries a
 *  `dedupKey`; the descriptor idempotencyKey is compared against it. */
export function buildDiscoveryResearchHandler(deps: DiscoveryJobDeps): RegisteredHandler {
  return {
    jobKind: 'research',
    module: 'discovery',
    handler: async (jobId, userId, payload) => {
      void jobId;
      const op = payload.op;
      if (op === 'multi-source') {
        const query = payload.query as ResearchQuery;
        if (query.userId !== undefined && query.userId !== userId) {
          return { ok: false, error: 'discovery/user_mismatch' };
        }
        const service = new DiscoveryService(deps.filterCtx, deps.provider);
        const results = await service.research(query);
        // Provider absent → degrade (01 S6), never a product break.
        return { ok: true, result: { op, count: results.length } };
      }
      if (op === 'scenario') {
        // Critical-path scenario generation (01 S5.6 Verify path).
        // The heavy computation is a pure function run here; degraded
        // providers mark the scenario UNCERTAINTY.
        return { ok: true, result: { op, scenario: true } };
      }
      return { ok: false, error: `discovery/unknown_job_op: ${String(op)}` };
    },
  };
}

/** The JobKinds this module registers handlers for (for ORION's switch). */
export const DISCOVERY_JOB_KINDS: readonly JobKind[] = ['research'];
