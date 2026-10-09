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
import type { ConfirmationDecision } from './types.ts';
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
  invokeTool(tool: string, input: Record<string, unknown>, runCtx?: { userId?: string }): Promise<unknown>;
  /** persist a heavy step as a job (AD-8). */
  jobs: JobDispatcherPort;
  /** the expert-skill memory store (server-only). */
  memory: MemoryEngine;
  /** verification deps (deterministic / source / judge). */
  verification: import('./verification.ts').VerificationDeps;
  /** id + clock (injectable) */
  ulid(): string;
  now(): string;
  /**
   * LOT 1-bis / Story 1.1-bis — load a run's pending plan server-side
   * (from `agent_runs.pending_plan`, by agentRunId + user_id). Absent /
   * unconfigured = resume degrades to a fresh plan build (the run still
   * stops at the confirmation point — no auto-confirm).
   */
  resumePlan?: (userId: string, agentRunId: string) => Promise<Plan | null>;
}

export interface KernelRequest {
  userId: string;
  intent: string;
  contextRefs?: string[];
  taskProfile?: TaskProfile;
  signals?: import('./intent.ts').IntentRequest['signals'];
  /**
   * Resume an interrupted run (AD-8 recovery).
   *
   * LOT 1-bis / Story 1.1-bis — the resume plan NEVER comes from the
   * client. The previous pass's plan is re-loaded server-side from
   * `agent_runs` BY `agentRunId` AND `user_id` (the user_id is the
   * auth-validated id, never the HTTP body). A client-supplied
   * `resumeFrom.pendingPlan` is rejected by fn-agent-run with 400
   * `agent/plan_not_accepted` and is not part of this type.
   */
  resumeFrom?: { agentRunId: string };
  /**
   * User confirmation decisions (ADR S5) — the answers to the
   * `confirmation` events of a previous pass, keyed by stepId. The run
   * proceeds a confirmation point only when a matching `confirmed`
   * decision exists AND its `stepHash` still matches the step's content
   * hash (`computeStepHash` — a mismatch is treated as "no decision",
   * the step must be re-confirmed, never auto-approved); `rejected`
   * marks the step skipped (never executed); absent → the run stops at
   * that step (event `confirmation` emitted, nothing after it runs — no
   * auto-confirmation, AD-12/S5).
   */
  decisions?: ConfirmationDecision[];
}

/**
 * LOT 1-bis / Story 1.1-bis — the content hash that binds a
 * ConfirmationDecision to the step it was emitted for
 * (`FNV-1a 64-bit on tool + canonical JSON of input`). Canonical JSON = object
 * keys sorted recursively, so the digest is stable across
 * serializations of the same logical input.
 */
export function computeStepHash(tool: string, input: Record<string, unknown> | undefined): string {
  const canon = JSON.stringify(canonicalize(input ?? {}));
  // FNV-1a 64-bit on `${tool}\u0000${canon}` — a content-BINDING digest
  // (a mismatch means "the step changed, the decision no longer
  // applies"), not a signing key. Kept dependency-free: pure TS, runs
  // in the Deno EF, the Node test runner, and any future bundle.
  let h = 0xcbf29ce484222325n;
  const data = `${tool}\u0000${canon}`;
  for (let i = 0; i < data.length; i++) {
    h ^= BigInt(data.charCodeAt(i));
    h = (h * 0x100000001b3n) & 0xffffffffffffffffn;
  }
  return h.toString(16).padStart(16, '0');
}

/** Recursive key-sort JSON canonicalization (stable byte order). */
function canonicalize(value: unknown): unknown {
  if (Array.isArray(value)) return value.map((v) => canonicalize(v));
  if (value !== null && typeof value === 'object') {
    const out: Record<string, unknown> = {};
    for (const k of Object.keys(value as Record<string, unknown>).sort()) {
      out[k] = canonicalize((value as Record<string, unknown>)[k]);
    }
    return out;
  }
  return value;
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
    // LOT 1-bis / Story 1.1-bis — on resume, the pending plan is ALWAYS
    // re-loaded server-side (agent_runs, by agentRunId + user_id) — it
    // NEVER comes from the client. The kernel receives it through a new
    // `resumePlan` dep injected by the deployment bootstrap; a fresh
    // run (no resumeFrom) builds the plan from scratch.
    if (req.resumeFrom?.agentRunId) {
      const reloaded = await this.deps.resumePlan?.(req.userId, req.resumeFrom.agentRunId);
      plan = reloaded ? replanRemaining(reloaded, ctx, perm, planner) : buildPlan(ctx, perm, planner);
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
      invoke: (tool, input, runCtx) => this.deps.invokeTool(tool, input, runCtx),
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
    // LOT 1-bis / Story 1.1-bis: every confirmation-carrying step has its
    // `stepHash` (FNV-1a 64-bit of tool + canonical input) computed here, at
    // prompt time, and stamped on the step itself — a decision whose
    // stepHash does not match (a stale / forged answer) is treated as if
    // the decision were absent (the step is re-prompted, never run).
    const decisions = new Map((req.decisions ?? []).map((d) => [d.stepId, d]));
    for (const step of plan.steps) {
      if (step.confirmationRequired && step.status === 'pending') {
        const decision = decisions.get(step.stepId);
        const stepHash = computeStepHash(step.tool, step.input);
        step.stepHash = stepHash;
        // LOT 1-bis / 1.1-bis — the decision is trusted only when it
        // binds to this exact step content (stepHash). A stale / forged
        // decision (wrong or missing stepHash) behaves like "no
        // decision" → the step is re-prompted, never auto-confirmed.
        const trustedDecision =
          decision &&
          (decision.stepHash === stepHash ||
            (decision.stepHash === undefined && !step.stepHash))
            ? decision
            : undefined;
        const answer = trustedDecision?.answer;
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
          stepHash,
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
        // LOT 1-bis / Story 1.1-bis: the terminal snapshot is the `done`
        // state (status awaiting-confirmation) — the dispatcher's
        // persistRun writes `plan` onto `agent_runs.pending_plan` so a
        // later resume re-loads it server-side (never from the client).
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
