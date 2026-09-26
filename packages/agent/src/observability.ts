/**
 * Component 14 — Observability (kernel.md S12, AD-16d).
 *
 * Run traces: job_logs (01 S5.3), Sentry / PostHog, `AIUsageTracker`
 * feeds, per-kind SLOs. The `RunTracer` is the kernel-side span
 * collector; it is transport-agnostic — the server adapters flush it
 * to `job_logs` (Agent-owned table) + `ai_usage` (registry-owned,
 * AD-16b single owner).
 */
import type { TaskProfile } from './types.ts';
import type { AIResponseEnvelope } from '@aurora/domain';

/** A trace span — one kernel component's execution. */
export interface TraceSpan {
  /** span name = the component ("intent", "context", "plan", …) */
  name: string;
  startedAt: string;
  endedAt?: string;
  /** structured fields (tool, provider, model, attempt, …) */
  fields?: Record<string, unknown>;
  ok?: boolean;
  error?: string;
}

/** The kernel's trace scope for one run. */
export interface RunScope {
  agentRunId: string;
  userId: string;
  /** the trace id (AD-5 correlation) */
  traceId: string;
  intentKind: string;
  profile?: TaskProfile;
  /** the envelope of the last model call (AD-5) */
  lastEnvelope?: AIResponseEnvelope<unknown>;
  /** total spans */
  spans: TraceSpan[];
  /** usage accounting (AIUsageTracker feed) */
  usage: { tokensIn: number; tokensOut: number; costUsd: number; calls: number };
}

/**
 * `RunTracer` — the per-run span collector. Spans are appended in
 * order; the kernel flushes them on completion / failure.
 */
export class RunTracer {
  private scope: RunScope;
  private now: () => string;

  constructor(init: { agentRunId: string; userId: string; traceId: string; intentKind: string; profile?: TaskProfile; now?: () => string }) {
    const now = init.now ?? (() => new Date().toISOString());
    this.now = now;
    this.scope = {
      agentRunId: init.agentRunId,
      userId: init.userId,
      traceId: init.traceId,
      intentKind: init.intentKind,
      profile: init.profile,
      spans: [],
      usage: { tokensIn: 0, tokensOut: 0, costUsd: 0, calls: 0 },
    };
  }

  /** Open a span; close it via `closeSpan`. */
  span(name: string, fields?: Record<string, unknown>): TraceSpan {
    const s: TraceSpan = { name, startedAt: this.now(), fields };
    this.scope.spans.push(s);
    return s;
  }

  closeSpan(s: TraceSpan, ok: boolean, error?: string): void {
    s.endedAt = this.now();
    s.ok = ok;
    s.error = error;
  }

  /** Record an AI usage line (AIUsageTracker feed). */
  recordUsage(u: { tokensIn: number; tokensOut: number; costUsd: number }): void {
    this.scope.usage.tokensIn += u.tokensIn;
    this.scope.usage.tokensOut += u.tokensOut;
    this.scope.usage.costUsd += u.costUsd;
    this.scope.usage.calls += 1;
  }

  /** Attach the last envelope (AD-5 traceability). */
  setLastEnvelope(e: AIResponseEnvelope<unknown>): void {
    this.scope.lastEnvelope = e;
  }

  /** The run's scope (for flush to job_logs + Sentry). */
  run(): RunScope {
    return this.scope;
  }

  /** The span list (read-only view). */
  spans(): TraceSpan[] {
    return [...this.scope.spans];
  }

  /** Total wall time ms of the run. */
  wallMs(): number {
    const started = this.scope.spans.find((s) => s.endedAt)?.startedAt;
    if (!started) return 0;
    return Date.now() - Date.parse(started);
  }
}
