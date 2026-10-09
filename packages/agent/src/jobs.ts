/**
 * Agent module — job handler for the global JobKind switch (wave 3
 * integration, AD-8 / chevauchement rule).
 *
 * Chevauchement rule: ORION owns fn-job-dispatcher's wiring. This
 * package exposes a pure, idempotent `agent_run` handler factory that
 * the dispatcher imports and registers — the dispatcher file is edited
 * ONLY to add the import + registration line (AD-7 single-writer is
 * preserved: agent code lives in packages/agent).
 *
 * AD-12/F-09: the kernel runs server-side; the device sees ONLY
 * AgentRunState (the persisted terminal snapshot + the result of this
 * job) — never keys / providers / router internals (AD-3: the job
 * payload carries intent / contextRefs / taskProfile / agentRunId
 * ONLY, zero provider or key material).
 */
import type { JobDispatcherPort } from '@aurora/domain';
import type {
  AgentKernel,
  KernelDeps,
  KernelRequest,
  PermissionContext,
  ContextAssembler,
  MemoryEngine,
  VerificationDeps,
} from './index.ts';
import type { AgentRunState, Plan } from './types.ts';

export interface AgentJobHandler {
  jobKind: 'agent_run';
  module: 'agent';
  handler: (
    jobId: string,
    userId: string,
    payload: Record<string, unknown>,
  ) => Promise<{ ok: boolean; result?: unknown; error?: string }>;
}

/**
 * Server-side seams the handler needs. Everything is injected: the
 * factory stays pure (no env access, no fetch) so it is unit-testable
 * and safe to import from the Deno dispatcher.
 */
export interface AgentHandlerDeps {
  /** boot the kernel with the FULL KernelDeps (including the
   *  invokeModel / invokeTool model+tool seams wired to the
   *  ModelGateway). Pure: no env access inside this factory.
   *  The deployment bootstrap may not be wired yet — in that case
   *  throw and the handler reports the degraded no-op. */
  kernelFactory: (
    d: Pick<
      KernelDeps,
      | 'assembler'
      | 'permission'
      | 'memory'
      | 'verification'
      | 'jobs'
      | 'ulid'
      | 'now'
      | 'invokeModel'
      | 'invokeTool'
    >,
  ) => AgentKernel;
  assembler: ContextAssembler | null;
  permission: ((userId: string) => Promise<PermissionContext>) | null;
  memory: MemoryEngine | null;
  verification: VerificationDeps | null;
  jobs: JobDispatcherPort | null;
  ulid(): string;
  now(): string;
  /** persist the terminal AgentRunState snapshot (module-owned
   *  server-only table, AD-12: the device's SSoT run state) */
  persistRun(userId: string, state: AgentRunState): Promise<void>;
}

/**
 * The `agent_run` handler for ORION's global switch.
 *
 * Idempotency (AD-8): the idempotency key is `agent:<agentRunId>`
 * (set by fn-agent-run on enqueue); the dispatcher dedupes
 * re-dispatches of the same run — the handler itself just persists
 * the terminal snapshot, so a replay is a no-op overwrite of the same
 * row.
 *
 * Pure: the kernel is provided as an injected factory (`deps.kernel`)
 * carrying every `KernelDeps` seam (assembler, permission, memory,
 * verification, jobs, ulid, now, invokeModel, invokeTool) — no env
 * access and no fetch in this file.
 */
export function buildAgentRunHandler(
  deps: AgentHandlerDeps,
): AgentJobHandler {
  const {
    kernelFactory,
    assembler,
    permission,
    memory,
    verification,
    jobs,
    ulid,
    now,
    persistRun,
  } = deps;
  return {
    jobKind: 'agent_run',
    module: 'agent',
    handler: async (_jobId, userId, payload) => {
      const agentRunId =
        typeof payload.agentRunId === 'string' && payload.agentRunId
          ? payload.agentRunId
          : ulid();
      const intent = typeof payload.intent === 'string' ? payload.intent : '';
      const contextRefs = Array.isArray(payload.contextRefs)
        ? payload.contextRefs
        : undefined;
      const taskProfile = payload.taskProfile as
        | KernelRequest['taskProfile']
        | undefined;
      const resumeFrom = payload.resumeFrom as
        | { agentRunId: string; pendingPlan: Plan }
        | undefined;
      // LOT 1 / Story 1.1 — user confirmation decisions (ADR S5): the
      // device answers the `confirmation` events of a previous pass; the
      // run only proceeds past a write/destructive step with a matching
      // `confirmed` decision. Absent/invalid entries degrade to [] (the
      // run stops at the confirmation point, never auto-confirms).
      const rawDecisions = Array.isArray(payload.decisions) ? payload.decisions : [];
      const decisions = rawDecisions
        .filter(
          (d): d is { stepId: string; answer: 'confirmed' | 'rejected' } =>
            typeof d === 'object' &&
            d !== null &&
            typeof (d as { stepId?: unknown }).stepId === 'string' &&
            ((d as { answer?: unknown }).answer === 'confirmed' ||
              (d as { answer?: unknown }).answer === 'rejected'),
        )
        .map((d) => ({ stepId: d.stepId, answer: d.answer }));

      // Degraded no-op when the server bootstrap is not yet wired:
      // the job completes idempotently (AD-8: no data loss, the run
      // will execute on a future dispatch once the bootstrap lands).
      if (!assembler || !permission || !memory || !verification || !jobs) {
        return {
          ok: true,
          result: {
            agentRunId,
            status: 'pending-bootstrap' as const,
            note: 'server kernel bootstrap not configured in this deployment',
          },
        };
      }

      let last: AgentRunState | undefined;
      let failed = false;
      const kernel = kernelFactory({
        assembler,
        permission,
        memory,
        verification,
        jobs,
        ulid,
        now,
        invokeModel: () => {
          throw new Error(
            'agent_run handler: invokeModel must be injected via the kernel factory',
          );
        },
        invokeTool: () => {
          throw new Error(
            'agent_run handler: invokeTool must be injected via the kernel factory',
          );
        },
      });
      const req: KernelRequest = {
        userId,
        intent,
        contextRefs,
        taskProfile,
        resumeFrom,
        ...(decisions.length > 0 ? { decisions } : {}),
      };
      try {
        for await (const ev of kernel.run(req)) {
          last = ev.state;
          if (ev.type === 'failed') failed = true;
        }
      } catch (e) {
        // Bootstrap / runtime failure — report the job failure so the
        // dispatcher marks it failed (AD-8: no silent loss).
        return {
          ok: false,
          error: e instanceof Error ? e.message : String(e),
        };
      }
      const finalState: AgentRunState = last ?? {
        agentRunId,
        stage: 'done',
        status: failed ? 'failed' : 'succeeded',
        startedAt: now(),
        updatedAt: now(),
      };
      await persistRun(userId, finalState);
      return {
        ok: true,
        result: {
          agentRunId,
          status: finalState.status,
          stage: finalState.stage,
        },
      };
    },
  };
}
