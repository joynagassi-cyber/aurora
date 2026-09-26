/**
 * Component 10 — Execution Engine (kernel.md S12).
 *
 * Runs the plan step-by-step: tool calls inline, heavy steps
 * persisted as jobs (AD-8: multi-step workflows survive crashes —
 * state lives in Postgres, executors are stateless). The engine
 * NEVER writes a module table directly (AD-7 single-writer): it
 * emits commands the owning module applies; for heavy steps it
 * dispatches through the `JobDispatcherPort`.
 */
import type { Plan, PlanStep } from './types.ts';
import type { ConfirmationEngine } from './confirmation.ts';
export interface StepOutcome {
  stepId: string;
  ok: boolean;
  result?: unknown;
  error?: string;
  /** the job that will run this step (heavy steps, AD-8) */
  jobId?: string;
}

export interface ExecutionDeps {
  /** invoke an inline tool (the Vercel SDK's tool handler). */
  invoke(tool: string, input: Record<string, unknown>): Promise<unknown>;
  /** persist a heavy step as a job (AD-8). Returns the job id. */
  dispatchJob(step: PlanStep): Promise<{ jobId: string }>;
  /** the confirmation engine (component 8) */
  confirmations: ConfirmationEngine;
  /** clock for the step log */
  now(): string;
  /** observability hook (component 14) */
  trace?(entry: { step: PlanStep; outcome: StepOutcome; at: string }): void;
}

/**
 * Execute a plan. Returns the per-step outcomes. A rejected / timed-out
 * confirmation marks the step `failed` with `error='confirmation_denied'`
 * (timeout = safe-cancel, ADR S5) and stops the run (no destructive /
 * write step proceeds after a denied confirmation point).
 */
export class ExecutionEngine {
  private deps: ExecutionDeps;

  constructor(deps: ExecutionDeps) {
    this.deps = deps;
  }

  async execute(plan: Plan, userId: string): Promise<{ outcomes: StepOutcome[]; aborted: boolean }> {
    void userId;
    const outcomes: StepOutcome[] = [];
    let aborted = false;
    for (const step of plan.steps) {
      if (step.status === 'skipped') {
        outcomes.push({ stepId: step.stepId, ok: false, error: 'skipped_unavailable' });
        continue;
      }
      // Confirmation gate (write / destructive steps, ADR S5).
      if (step.confirmationRequired) {
        if (!this.deps.confirmations.isConfirmed(step.stepId)) {
          const denied = this.deps.confirmations.wasRejected(step.stepId);
          const out: StepOutcome = {
            stepId: step.stepId,
            ok: false,
            error: denied ? 'confirmation_denied' : 'confirmation_timeout',
          };
          outcomes.push(out);
          aborted = true;
          this.deps.trace?.({ step, outcome: out, at: this.deps.now() });
          break; // stop the run after a denied confirmation point
        }
      }
      step.status = 'running';
      try {
        if (step.jobKind) {
          // Heavy step: persist the job (AD-8); the dispatcher runs it.
          const { jobId } = await this.deps.dispatchJob(step);
          const out: StepOutcome = { stepId: step.stepId, ok: true, jobId, result: { queued: true } };
          step.status = 'done';
          step.result = out;
          outcomes.push(out);
          this.deps.trace?.({ step, outcome: out, at: this.deps.now() });
        } else {
          const result = await this.deps.invoke(step.tool, step.input);
          const out: StepOutcome = { stepId: step.stepId, ok: true, result };
          step.status = 'done';
          step.result = out;
          outcomes.push(out);
          this.deps.trace?.({ step, outcome: out, at: this.deps.now() });
        }
      } catch (e) {
        const out: StepOutcome = {
          stepId: step.stepId,
          ok: false,
          error: e instanceof Error ? e.message : String(e),
        };
        step.status = 'failed';
        step.result = out;
        outcomes.push(out);
        this.deps.trace?.({ step, outcome: out, at: this.deps.now() });
        aborted = true;
        break;
      }
    }
    return { outcomes, aborted };
  }
}
