/**
 * AgentKernel — the orchestrating loop (kernel.md S3, AD-12).
 *
 *   Intent → Context → Plan → Retrieve → Tools → Verify → Action → Result → Memory
 *
 * All 15 components run server-side (AD-12/F-09). The device sees
 * ONLY `AgentRunState` (02 S4); it never sees AIProvider / router /
 * keys (AD-3). The kernel owns the orchestration; each component owns
 * its own state machine.
 *
 * Single-writer (AD-7): the kernel NEVER writes a module table
 * directly — it emits commands the owning module applies; heavy steps
 * are persisted jobs (AD-8). The kernel's own writes go to its
 * server-only table `expert_skills` (Memory) + `job_logs`
 * (Observability).
 */
import type { AgentRunState, Intent, AgentContext, Plan, TaskProfile } from './types.ts';
import { classifyIntent } from './intent.ts';
import { buildAgentContext, type ContextAssembler } from './context.ts';
import { buildPlan, replanRemaining, type PlannerDeps } from './planner.ts';
import { DefaultCapabilityRegistry } from './capability.ts';
import { isAllowed, type PermissionContext } from './permission.ts';
import { ConfirmationEngine } from './confirmation.ts';
import { AgnesPrimaryRouter, type RouterRegistry, type HealthChecker, type BudgetChecker, type DataPolicy } from './router.ts';
import { ExecutionEngine } from './execution.ts';
import { VerificationEngine } from './verification.ts';
import { buildNormalizedResult, type RawModelResponse } from './result.ts';
import type { MemoryEngine } from './memory.ts';
import type { AIResponseEnvelope, JobDispatcherPort, JobKind } from '@aurora/domain';

export interface KernelDeps {
  assembler: ContextAssembler;
  permission: (userId: string) => Promise<PermissionContext>;
  /** the model router (Agnes-primary, S2.6) */
  router: {
    registry: RouterRegistry;
    health: HealthChecker;
    budget: BudgetChecker;
    dataPolicy: DataPolicy;
  };
  /** invoke a model (Vercel SDK layer) → raw response. Component 10. */
  invokeModel(req: {
    profile: TaskProfile;
    intent: Intent;
    ctx: AgentContext;
    plan: Plan;
    envelope: AIResponseEnvelope<unknown>;
  }): Promise<RawModelResponse>;
  /** run inline tool handlers (Vercel SDK tools). */
  invokeTool(tool: string, input: Record<string, unknown>): Promise<unknown>;
  /** persist a heavy step as a job (AD-8). */
  jobs: JobDispatcherPort;
  /** the expert-skill memory store (server-only). */
  memory: MemoryEngine;
  /** verification deps (deterministic / source / judge). */
  verification: import('./verification.ts').VerificationDeps;
  /** id + clock (injectable) */
  ulid(): string;
  now(): string;
}

export interface KernelRequest {
  userId: string;
  intent: string;
  contextRefs?: string[];
  taskProfile?: TaskProfile;
  signals?: import('./intent.ts').IntentRequest['signals'];
  /** resume an interrupted run (AD-8 recovery: state in Postgres) */
  resumeFrom?: { agentRunId: string; pendingPlan: Plan };
  /**
   * User confirmation decisions (ADR S5) — the answer to the `confirmation`
   * events of a previous pass, keyed by stepId. The run proceeds a
   * confirmation point only when a matching `confirmed` decision exists;
   * `rejected` marks the step skipped (never executed); absent → the run
   * stops at that step (event `confirmation` emitted, nothing after it
   * runs — no auto-confirmation, AD-12/S5).
   */
  decisions?: Array<{ stepId: string; answer: 'confirmed' | 'rejected' }>;
}

/**
 * The kernel's event stream. `fn-agent-run` maps these to the SSE
 * chunks `AgentRunState` consumed by the device (02 S4). Each event
 * carries a fresh `AgentRunState` snapshot.
 */
export type KernelEvent =
  | { type: 'stage'; state: AgentRunState }
  | { type: 'confirmation'; state: AgentRunState; prompt: import('./confirmation.ts').ConfirmationPrompt }
  | { type: 'tool'; state: AgentRunState; tool: string; input: unknown }
  | { type: 'text'; state: AgentRunState; chunk: string }
  | { type: 'done'; state: AgentRunState }
  | { type: 'failed'; state: AgentRunState; error: string };

/**
 * The Agent Kernel. `run()` executes the full loop and yields
 * KernelEvents via the async iterator. The Vercel SDK integration
 * (task 2) plugs into `invokeModel` / `invokeTool`.
 */
export class AgentKernel {
  private deps: KernelDeps;
  private registry: DefaultCapabilityRegistry;

  constructor(deps: KernelDeps) {
    this.deps = deps;
    this.registry = new DefaultCapabilityRegistry();
  }

  /** Expose the capability registry (for the Context Builder tool form). */
  capabilities(): DefaultCapabilityRegistry {
    return this.registry;
  }

  async *run(req: KernelRequest): AsyncGenerator<KernelEvent> {
    const agentRunId = req.resumeFrom?.agentRunId ?? this.deps.ulid();
    const t0 = this.deps.now();

    // ── 1. INTENT ──
    const intentReq = { userId: req.userId, intent: req.intent, contextRefs: req.contextRefs, taskProfile: req.taskProfile, signals: req.signals };
    const intent = classifyIntent(intentReq);
    let state = this.state(agentRunId, 'intent', 'running', t0);

    yield { type: 'stage', state };

    // ── 2. CONTEXT ──
    const asm = this.deps.assembler;
    const ctx: AgentContext = await buildAgentContext(req.userId, intent, asm, {
      capabilityRegistry: this.registry.toDomain(),
    });
    state = this.state(agentRunId, 'context', 'running', t0);

    // ── 3. PLAN ──
    const perm = await this.deps.permission(req.userId);
    const planner: PlannerDeps = {
      registry: this.registry,
      permission: (step, _c, p) => {
        const entry = this.registry.byTool(step.tool);
        if (!entry) return 'blocked';
        return isAllowed(step, entry, p);
      },
      now: () => this.deps.now(),
      ulid: () => this.deps.ulid(),
    };
    let plan: Plan;
    if (req.resumeFrom?.pendingPlan) {
      plan = replanRemaining(req.resumeFrom.pendingPlan, ctx, perm, planner);
    } else {
      plan = buildPlan(ctx, perm, planner);
    }
    state = this.state(agentRunId, 'plan', 'running', t0, { plan });
    yield { type: 'stage', state };

    // ── 4. RETRIEVE ── (KB / source + R2, through the Knowledge port)
    state = this.state(agentRunId, 'retrieve', 'running', t0, { plan });
    yield { type: 'stage', state };

    // ── 5. TOOLS (Execution Engine, step-by-step) ──
    const confirmations = new ConfirmationEngine(() => this.deps.now());
    const execution = new ExecutionEngine({
      invoke: (tool, input) => this.deps.invokeTool(tool, input),
      dispatchJob: (step) =>
        this.deps.jobs.dispatch({
          jobKind: step.jobKind as JobKind,
          userId: req.userId,
          payload: { tool: step.tool, input: step.input, agentRunId },
          idempotencyKey: `agent:${agentRunId}:${step.stepId}`,
        }).then((r) => ({ jobId: r.jobId })),
      confirmations,
      now: () => this.deps.now(),
    });

    // Confirmation points (write / destructive steps, ADR S5).
    // No auto-confirmation: a step is decided ONLY by `req.decisions`
    // (answers returned by the device on the previous pass).
    //  - no decision  → emit `confirmation`, mark the step skipped, stop
    //    the run properly (yield `done`); nothing after it executes.
    //  - rejected     → the step is skipped / never executed; the run
    //    stops the same way.
    //  - confirmed    → feed the ConfirmationEngine; execution proceeds.
    // Resume (reprise) goes through the existing `resumeFrom` + a new
    // decisions array: re-running carries its own pendingPlan via
    // resumeFrom (whose stepIds are stable, unlike a fresh buildPlan) and
    // the decisions key off those stepIds.
    const decisions = new Map((req.decisions ?? []).map((d) => [d.stepId, d.answer]));
    for (const step of plan.steps) {
      if (step.confirmationRequired && step.status === 'pending') {
        const answer = decisions.get(step.stepId);
        if (answer === 'confirmed') {
          confirmations.decide({ stepId: step.stepId, answer: 'confirmed', at: this.deps.now() });
          continue;
        }
        // Rejected → the step is NEVER executed; stop the run so that
        // no subsequent (potentially write/destructive) step runs either.
        if (answer === 'rejected') {
          step.status = 'skipped';
          step.result = { stepId: step.stepId, ok: false, error: 'confirmation_rejected' };
          confirmations.decide({ stepId: step.stepId, answer: 'rejected', at: this.deps.now() });
          for (const later of plan.steps) {
            if (later.status === 'pending') later.status = 'skipped';
          }
          state = this.state(agentRunId, 'action', 'cancelled', t0, {
            plan,
            confirmationMessage: `${step.tool} rejected by the user`,
            confirmationStepId: step.stepId,
          });
          yield { type: 'done', state };
          return;
        }

        // No decision yet → ask the user, then end the run properly here
        // (ADR S5: never proceed past an unanswered confirmation point).
        const prompt = confirmations.prompt({
          stepId: step.stepId,
          tool: step.tool,
          risk: step.risk,
          message: `${step.tool}: ${JSON.stringify(step.input ?? '')}`,
        });
        confirmations.decide({ stepId: prompt.stepId, answer: 'timeout', at: this.deps.now() });
        step.status = 'skipped';
        step.result = { stepId: step.stepId, ok: false, error: 'confirmation_pending' };
        // Nothing after this point may run without a decision.
        for (const later of plan.steps) {
          if (later.status === 'pending') later.status = 'skipped';
        }
        state = this.state(agentRunId, 'action', 'awaiting-confirmation', t0, {
          plan,
          confirmationMessage: prompt.message,
          confirmationStepId: prompt.stepId,
        });
        yield { type: 'confirmation', state, prompt };
        state = this.state(agentRunId, 'action', 'awaiting-confirmation', t0, {
          plan,
          confirmationMessage: prompt.message,
          confirmationStepId: prompt.stepId,
        });
        yield { type: 'done', state };
        return;
      }
    }

    const { outcomes } = await execution.execute(plan, req.userId);
    for (const o of outcomes.filter((o) => o.ok)) {
      state = this.state(agentRunId, 'tools', 'running', t0, {
        plan,
        toolLog: [...(state.toolLog ?? []), { tool: o.stepId, input: o.result, at: this.deps.now() }],
      });
      yield { type: 'tool', state, tool: o.stepId, input: o.result };
    }

    // ── 6. VERIFY (Verification Engine, critical tasks) ──
    state = this.state(agentRunId, 'verify', 'running', t0, { plan });
    yield { type: 'stage', state };
    const verification = new VerificationEngine(this.deps.verification);

    // ── 7. ACTION ── (commands emitted; single-writer modules apply)
    state = this.state(agentRunId, 'action', 'running', t0, { plan });

    // ── 8. RESULT (Result Normalizer + AIResponseEnvelope, AD-5) ──
    const raw = await this.deps.invokeModel({ profile: intent.profile, intent, ctx, plan, envelope: this.emptyEnvelope(agentRunId) });
    const { envelope, degraded } = buildNormalizedResult<unknown>(raw);
    const verify = await verification.verify(plan, envelope);
    if (verify.degraded) {
      envelope.expectedQuality = 'degraded';
    }
    state = this.state(agentRunId, 'result', 'running', t0, {
      plan,
      envelope,
      degraded: degraded || verify.degraded,
      text: typeof envelope.data === 'string' ? envelope.data : JSON.stringify(envelope.data ?? ''),
    });
    yield { type: 'text', state, chunk: state.text ?? '' };

    // ── 9. MEMORY (Expert Skills, server-only) ──
    state = this.state(agentRunId, 'memory', 'running', t0, { plan, envelope, degraded: degraded || verify.degraded });
    yield { type: 'stage', state };

    // ── DONE ──
    const failed = outcomes.some((o) => !o.ok);
    state = this.state(agentRunId, failed ? 'failed' : 'done', failed ? 'failed' : 'succeeded', t0, { plan, envelope });
    if (failed) {
      yield { type: 'failed', state, error: 'a plan step failed' };
    } else {
      yield { type: 'done', state };
    }
  }

  /** A minimal placeholder envelope (the model layer fills it in). */
  private emptyEnvelope(agentRunId: string): AIResponseEnvelope<unknown> {
    return {
      provider: 'agnes',
      model: 'agnes-3.0',
      attempt: 1,
      reason: 'primary',
      expectedQuality: 'full',
      fallbackUsed: false,
      traceId: agentRunId,
      data: null,
    };
  }

  /**
   * Build an `AgentRunState` snapshot. The device sees ONLY this type
   * (AD-12); the optional `extras` carry the streaming fields.
   */
  private state(
    agentRunId: string,
    stage: AgentRunState['stage'],
    status: AgentRunState['status'],
    t0: string,
    extras?: Partial<AgentRunState>,
  ): AgentRunState {
    return {
      agentRunId,
      stage,
      status,
      ...extras,
      startedAt: t0,
      updatedAt: this.deps.now(),
    };
  }
}

/** Convenience: expose the router + recovery for the Vercel layer. */
export function makeRouter(d: KernelDeps['router']): AgnesPrimaryRouter {
  return new AgnesPrimaryRouter(d.registry, d.health, d.budget, d.dataPolicy);
}

export { classifyIntent };
export type { MemoryEngine };
