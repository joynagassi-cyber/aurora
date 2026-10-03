/**
 * Component 15 — Error Recovery (kernel.md S12).
 *
 * Bounded retry (transient) vs fallback (unavailability /
 * incompatibility / limit reached). 429 → cooldown, NEVER key
 * rotation (AD-5). Budget exhaustion → stop before overrun
 * (`budgetSnapshot` to the job, clean stop — 01 S5.6). Recovery =
 * resume from persisted step state (AD-8: executors are stateless,
 * state lives in Postgres).
 */
import type { ProviderModel } from './router.ts';

export type FailureClass =
  | 'transient' // 5xx / timeout → bounded retry, same provider
  | 'rate_limited' // 429 → cooldown on that provider, then fallback (never rotate keys)
  | 'unavailable' // provider down → fallback
  | 'incompatible' // feature missing (no vision / tools / JSON) → fallback to capable provider
  | 'budget' // budget exhausted → clean stop, no fallback
  | 'policy' // data-policy block → AIRequestGuard refused; route to compliant provider or degrade
  | 'fatal'; // unrecoverable

export interface RecoveryDecision {
  action: 'retry' | 'fallback' | 'stop' | 'degrade';
  /** next provider/model (fallback / degrade) */
  next?: ProviderModel;
  /** bounded retry count left for this provider (transient only) */
  retriesLeft?: number;
  /** the 429 cooldown to record on the current provider (AD-5) */
  cooldownSec?: number;
  reason: string;
}

/**
 * Classify a provider failure into the recovery classes. The
 * classifier is pure (no side effects); the kernel / health registry
 * act on the decision.
 *
 * AD-5 invariant: a 429 NEVER bypasses the limit by rotating keys.
 * The decision carries `cooldownSec` so the `AIHealthRegistry` marks
 * the provider unavailable until the retry-after elapses.
 */
export function classifyFailure(err: {
  /** the HTTP / provider-level status */
  status?: number;
  /** error class string from the provider adapter */
  kind?: string;
  message?: string;
  /** whether a retry-after header / value was present */
  retryAfterSec?: number;
}): FailureClass {
  const s = err.status;
  const k = err.kind ?? '';
  if (s === 429 || /rate.?limit|throttl|429/i.test(k)) return 'rate_limited';
  if (s === 402 || /budget|quota|insufficient.?funds/i.test(k)) return 'budget';
  if (/polic|guard|denied/i.test(k)) return 'policy';
  if (s && s >= 500 && s < 600) return 'transient';
  if (s === 408 || s === 504 || /timeout/i.test(k)) return 'transient';
  if (s === 404 || /unavailable|unreachable|econn/i.test(k)) return 'unavailable';
  if (/incompat|feature.?not.?support|no.?such.?model/i.test(k)) return 'incompatible';
  if (/fatal|unrecoverable/i.test(k)) return 'fatal';
  // default: treat unknown as transient with a bounded retry
  return 'transient';
}

/**
 * The Error Recovery engine. Holds the current `ProviderModel`
 * selection + the fallback chain; produces a `RecoveryDecision` per
 * failure. The kernel advances through the chain on `fallback` and
 * stops on `budget` / `fatal` / `stop`.
 */
export class ErrorRecovery {
  private maxRetries: number;

  /** 429 cooldown per provider (S2.6: agnes=60s, workers-ai=120s). */
  private cooldowns: Record<string, number> = {
    agnes: 60,
    'workers-ai': 120,
    groq: 60,
  };

  constructor(opts?: { maxRetries?: number }) {
    this.maxRetries = opts?.maxRetries ?? 3;
  }

  /**
   * Decide the recovery action for a failure. `current` = the
   * provider/model that just failed; `chain` = the ordered fallback
   * chain (primary first); `attempt` = how many times `current` has
   * been tried.
   */
  decide(
    failure: FailureClass,
    current: ProviderModel,
    chain: ProviderModel[],
    attempt: number,
  ): RecoveryDecision {
    switch (failure) {
      case 'transient':
        if (attempt < this.maxRetries) {
          return { action: 'retry', retriesLeft: this.maxRetries - attempt, reason: `transient, retry ${attempt + 1}/${this.maxRetries}` };
        }
        return this.fallback(current, chain, 'transient exhausted');
      case 'rate_limited': {
        // AD-5: record the cooldown, then go to the next provider.
        // NEVER rotate keys.
        const cd = this.cooldowns[current.provider] ?? 60;
        const next = this.nextAfter(current, chain);
        return {
          action: next ? 'fallback' : 'degrade',
          next,
          cooldownSec: cd,
          reason: '429 — cooldown, then fallback (no key rotation, AD-5)',
        };
      }
      case 'unavailable':
      case 'incompatible':
        return this.fallback(current, chain, failure);
      case 'budget':
        // Stop BEFORE overrun — no fallback, no mid-generation cut-off.
        return { action: 'stop', reason: 'budget exhausted — clean stop (01 S5.6)' };
      case 'policy':
        return { action: 'degrade', reason: 'data-policy block — AIRequestGuard refused (01 S6)' };
      case 'fatal':
      default:
        return { action: 'stop', reason: 'fatal — unrecoverable' };
    }
  }

  private fallback(current: ProviderModel, chain: ProviderModel[], why: string): RecoveryDecision {
    const next = this.nextAfter(current, chain);
    if (!next) return { action: 'stop', reason: `no fallback left (${why})` };
    return {
      action: 'fallback',
      next,
      reason: why,
    };
  }

  private nextAfter(current: ProviderModel, chain: ProviderModel[]): ProviderModel | undefined {
    const idx = chain.findIndex((c) => c.provider === current.provider && c.model === current.model);
    for (let i = idx + 1; i < chain.length; i++) {
      const c = chain[i];
      if (c) return c;
    }
    return undefined;
  }

  /** Cooldown table (tests + the health registry). */
  cooldown(provider: string): number {
    return this.cooldowns[provider] ?? 60;
  }
}
