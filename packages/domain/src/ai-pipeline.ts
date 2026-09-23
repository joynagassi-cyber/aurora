/**
 * AI pipeline contracts (AD-15 SSoT; implementation in
 * `data/platform/ai-pipeline` — AD-1 vendor isolation).
 *
 * Multi-provider failover: Agnes (primary) -> Cloudflare AI Gateway ->
 * Workers AI -> Groq / Cerebras (optional) -> CF Worker last-resort.
 *
 * The envelope is `AIResponseEnvelope` (envelopes.ts); these 8 contracts
 * describe the registry / router / policy / health / usage / budget / guard
 * surfaces the pipeline exposes.
 */

/** 1. `AIModelRegistry` — declared models + capabilities. */
export interface AIModelRegistry {
  /** provider id -> model id */
  list(): Array<{ provider: string; model: string; capabilities: string[]; contextWindow?: number }>;
  /** resolve the canonical model id for a capability */
  resolve(capability: string): { provider: string; model: string } | undefined;
}

/** 2. `AIModelRouter` — picks the provider/model for a request
 * (priority + capability + budget aware). */
export interface AIModelRouter {
  route(req: {
    capability: string;
    /** optional hint from the caller */
    preferredProvider?: string;
    /** the request class (fast / full) */
    requestClass: 'fast' | 'full';
  }): { provider: string; model: string; attempt: number; reason: 'primary' | 'fallback' | 'last_resort' };
}

/** 3. `AIModelPolicy` — per-class model policy (which provider at which
 * attempt, when to fall back). */
export interface AIModelPolicy {
  /** the ordered provider chain for a class */
  chain(requestClass: 'fast' | 'full'): Array<{ provider: string; model: string }>;
  /** max attempts before last-resort */
  maxAttempts(requestClass: 'fast' | 'full'): number;
  /** the expected quality when a fallback is used */
  expectedQuality(reason: 'primary' | 'fallback' | 'last_resort'): 'full' | 'degraded';
}

/** 4. `AIFallbackStrategy` — the concrete failover behavior across the
 * provider chain. */
export interface AIFallbackStrategy {
  /**
   * Run a request across the chain; returns the envelope describing which
   * provider/model/attempt served it.
   */
  execute(
    chain: Array<{ provider: string; model: string }>,
    invoke: (p: { provider: string; model: string; attempt: number }) => Promise<unknown>,
  ): Promise<{ result: unknown; envelope: import('./envelopes').AIResponseEnvelope<unknown> }>;
}

/** 5. `AIHealthRegistry` — provider health (last error / availability). */
export interface AIHealthRegistry {
  /** record an outcome for a provider */
  record(provider: string, ok: boolean, latencyMs?: number, error?: string): void;
  /** is a provider usable right now? */
  healthy(provider: string): boolean;
  /** snapshot of all providers */
  snapshot(): Array<{ provider: string; ok: boolean; lastError?: string; lastLatencyMs?: number; lastAt?: string }>;
}

/** 6. `AIUsageTracker` — per-user / per-model token + cost accounting. */
export interface AIUsageTracker {
  /** record a completed call */
  record(entry: { userId: string; provider: string; model: string; tokensIn: number; tokensOut: number; costUsd: number; at: string }): void;
  /** cumulative usage for a user */
  total(userId: string): { calls: number; tokensIn: number; tokensOut: number; costUsd: number };
}

/** 7. `AIBudgetManager` — the user's AI budget (AD-3: no keys on device;
 * budget enforced server-side). */
export interface AIBudgetManager {
  /** the remaining budget for a user */
  remaining(userId: string): number;
  /** would a cost fit the remaining budget? */
  canAfford(userId: string, costUsd: number): boolean;
  /** charge a cost */
  charge(userId: string, costUsd: number): void;
}

/** 8. `AIRequestGuard` — rate / guardrail checks before a call. */
export interface AIRequestGuard {
  /**
   * Gate a request. Returns a `pass` (with any downgrade) or a `deny`
   * reason. Guards: budget, rate, sensitive-content, size.
   */
  check(req: { userId: string; requestClass: 'fast' | 'full'; sizeBytes: number }):
    | { pass: true; downgraded?: boolean; reason?: string }
    | { pass: false; code: string; message: string };
}
