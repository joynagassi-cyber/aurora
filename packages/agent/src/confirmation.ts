/**
 * Component 8 — Confirmation Engine (kernel.md S12, ADR S5).
 *
 * Surfaces confirmations to the user (UI `AgentRunState`), blocks
 * until answered; timeout = safe-cancel. Confirmations are part of
 * the plan, not an afterthought.
 *
 * The device sees ONLY `AgentRunState` (AD-12); the confirmation
 * prompt is part of that state. The decision comes back through the
 * command bus (kernel S15: the agent drives the UI through commands,
 * never React).
 */
import type { AgentRunState } from './types.ts';

export interface ConfirmationPrompt {
  stepId: string;
  tool: string;
  /** the human-readable action summary */
  message: string;
  /** the declared side effects (AgentCapability.effects) */
  effects?: string;
  /** risk class */
  risk: 'write' | 'destructive';
  /** when the prompt was raised */
  at: string;
  /** timeout → safe-cancel (ADR S5) */
  timeoutMs?: number;
  /**
   * LOT 1-bis / Story 1.1-bis — the step content hash
   * (FNV-1a 64-bit on tool + canonical JSON of input, `computeStepHash`)
   * exposed at prompt time so the device's ConfirmationDecision can bind to
   * the exact step. A decision whose stepHash no longer matches is
   * treated as "no decision" (the step must be re-confirmed).
   */
  stepHash?: string;
}

export type ConfirmationDecision =
  | { stepId: string; answer: 'confirmed'; at: string }
  | { stepId: string; answer: 'rejected'; at: string }
  | { stepId: string; answer: 'timeout'; at: string };

/**
 * In-memory confirmation store. The kernel calls `prompt()` when it
 * reaches a confirmation point; the UI surface (AgentRunState)
 * renders the message; the user's decision is fed back via
 * `decide()`. Timeout is treated as `rejected` (safe-cancel).
 */
export class ConfirmationEngine {
  private pending = new Map<string, ConfirmationPrompt>();
  private decisions: ConfirmationDecision[] = [];
  private now: () => string;

  constructor(now?: () => string) {
    this.now = now ?? (() => new Date().toISOString());
  }

  prompt(step: { stepId: string; tool: string; risk: PlanStepLikeRisk; effects?: string; message: string; stepHash?: string }, timeoutMs?: number): ConfirmationPrompt {
    const p: ConfirmationPrompt = {
      stepId: step.stepId,
      tool: step.tool,
      message: step.message,
      effects: step.effects,
      risk: step.risk === 'destructive' ? 'destructive' : 'write',
      at: this.now(),
      timeoutMs,
      ...(step.stepHash ? { stepHash: step.stepHash } : {}),
    };
    this.pending.set(step.stepId, p);
    return p;
  }

  /** The pending prompts (the UI renders these from AgentRunState). */
  pendingPrompts(): ConfirmationPrompt[] {
    return [...this.pending.values()];
  }

  /** The AgentRunState confirmation surface (02 S4). */
  runState(agentRunId: string, confirmationMessage?: string, confirmationStepId?: string): AgentRunState {
    const t = this.now();
    const prompt = confirmationStepId ? this.pending.get(confirmationStepId) : undefined;
    return {
      agentRunId,
      stage: 'action',
      status: prompt ? 'awaiting-confirmation' : 'running',
      confirmationMessage,
      confirmationStepId,
      toolLog: prompt ? [] : undefined,
      startedAt: t,
      updatedAt: t,
    };
  }

  /** Feed back a user decision. */
  decide(d: ConfirmationDecision): void {
    this.decisions.push(d);
    if (d.answer !== 'timeout') {
      this.pending.delete(d.stepId);
    } else {
      // timeout = safe-cancel: the step is rejected, not auto-approved
      this.pending.delete(d.stepId);
    }
  }

  /** Did a step get confirmed? (timeout counts as rejected.) */
  isConfirmed(stepId: string): boolean {
    return this.decisions.some((d) => d.stepId === stepId && d.answer === 'confirmed');
  }

  wasRejected(stepId: string): boolean {
    return this.decisions.some((d) => d.stepId === stepId && d.answer !== 'confirmed');
  }

  history(): ConfirmationDecision[] {
    return this.decisions;
  }
}

type PlanStepLikeRisk = 'read' | 'write' | 'destructive';
