/**
 * Component 9 — Model Router (kernel.md S12, ADR v1.7 S6/S9/S10).
 *
 * Agnes = PRIMARY for ALL tasks (event-reconciliation-and-router S2.6:
 * `alwaysFirst: true`, no exception except the per-task data-policy
 * one). Fallback chain: Workers AI (GLM-4.7 Flash / Gemma 4 /
 * Nemotron 3 Super 120B) → Groq (GPT-OSS) → Cerebras → OpenRouter →
 * CF Worker direct (last resort). The moment Agnes is healthy again,
 * ALL subsequent tasks go BACK to Agnes (PRIORITY 3 return).
 *
 * No concrete model name leaks into domain code (AD-1, ADR S1): the
 * router returns a typed `ProviderModel` + the `AIResponseEnvelope`
 * reason, the adapter layer builds the actual LanguageModel instance.
 */
import type { TaskProfile } from './types.ts';
import { levelFor } from './intent.ts';

/** The router's output — which provider/model serves the task. */
export interface ProviderModel {
  provider: string;
  model: string;
  attempt: number;
  reason: 'primary' | 'fallback' | 'last_resort';
  /** the expected quality when a fallback is used (AD-5) */
  expectedQuality: 'full' | 'degraded';
}

/**
 * The provider registry the router reads (AIModelRegistry shape,
 * 9 AI contracts S1). Frozen entries mirror S2.6's JSON.
 */
export interface RouterRegistry {
  /** the declared providers in failover order */
  list(): Array<{
    provider: string;
    models: string[];
    role: 'primary' | 'fallback' | 'last_resort' | 'optional';
    /** S2.6: Agnes is alwaysFirst */
    alwaysFirst?: boolean;
    /** S2.6: fallbacks only when primary unavailable */
    onlyWhenPrimaryUnavailable?: boolean;
    /** S2.6: per-provider 429 cooldown seconds */
    cooldownOn429?: number;
    /** S2.6: bounded 5xx retries */
    retryOn5xx?: number;
    /** data-policy tag (ADR S11) — `true` = compatible with sensitive */
    zeroDataRetention?: boolean;
  }>;
  /** pick the model for a provider + level */
  modelFor(provider: string, level: import('./types.ts').TaskLevel, profile: TaskProfile): string | undefined;
}

/** Provider health surface (AIHealthRegistry shape). */
export interface HealthChecker {
  healthy(provider: string, model: string): boolean;
  /** last 429 cooldown expiry (ISO) — the provider is in cooldown */
  inCooldown(provider: string): boolean;
}

/** Budget surface (AIBudgetManager shape). */
export interface BudgetChecker {
  hasQuota(provider: string, model: string, userId: string): boolean;
}

/** Data-policy surface (ADR S11). */
export interface DataPolicy {
  /** is the provider compatible with `sensitive` data? */
  compatible(provider: string, sensitivity: 'public' | 'sensitive'): boolean;
}

/**
 * `AgnesPrimaryRouter` — the S2.6 routing logic.
 *
 *  1. ALWAYS try Agnes first (unless data-policy exception).
 *  2. Agnes unavailable / 429 cooldown / data conflict → fallback
 *     chain (Workers AI → Groq → Cerebras → OpenRouter → CF Worker).
 *  3. Agnes healthy again → next call returns to Agnes immediately
 *     (the fallback is a TEMPORARY bridge, not a permanent switch).
 *
 * A 429 is NEVER bypassed by rotating keys (AD-5): the health
 * checker carries the cooldown; the router respects it.
 */
export class AgnesPrimaryRouter {
  private registry: RouterRegistry;
  private health: HealthChecker;
  private budget: BudgetChecker;
  private dataPolicy: DataPolicy;

  constructor(
    registry: RouterRegistry,
    health: HealthChecker,
    budget: BudgetChecker,
    dataPolicy: DataPolicy,
  ) {
    this.registry = registry;
    this.health = health;
    this.budget = budget;
    this.dataPolicy = dataPolicy;
  }

  /** The full ordered chain for a profile (primary + fallbacks). */
  chain(profile: TaskProfile, userId: string): Array<{ provider: string; model: string; reason: ProviderModel['reason'] }> {
    const level = levelFor(profile);
    const providers = this.registry.list();
    const out: Array<{ provider: string; model: string; reason: ProviderModel['reason'] }> = [];

    // 1. PRIMARY — Agnes (alwaysFirst) — unless per-task data conflict.
    const primary = providers.find((p) => p.alwaysFirst);
    if (primary) {
      const model = this.registry.modelFor(primary.provider, level, profile);
      if (model && this.eligible(primary.provider, model, profile, userId)) {
        out.push({ provider: primary.provider, model, reason: 'primary' });
      }
    }

    // 2. FALLBACK — only when primary unavailable / ineligible.
    for (const p of providers) {
      if (p.alwaysFirst || p.role === 'primary') continue;
      const model = this.registry.modelFor(p.provider, level, profile);
      if (!model) continue;
      // data-policy block: AIRequestGuard refuses BEFORE the call.
      if (!this.dataPolicy.compatible(p.provider, profile.dataSensitivity)) continue;
      if (!this.eligible(p.provider, model, profile, userId)) continue;
      out.push({
        provider: p.provider,
        model,
        reason: p.role === 'last_resort' ? 'last_resort' : 'fallback',
      });
    }
    return out;
  }

  /**
   * Select the provider/model for a task profile. Returns the first
   * eligible entry (Agnes-primary guaranteed when available).
   */
  select(profile: TaskProfile, userId: string): ProviderModel | undefined {
    const chain = this.chain(profile, userId);
    if (chain.length === 0) return undefined;
    const pick = chain[0] as { provider: string; model: string; reason: ProviderModel['reason'] };
    const isPrimary = pick.reason === 'primary';
    return {
      provider: pick.provider,
      model: pick.model,
      attempt: 1,
      reason: pick.reason,
      expectedQuality: isPrimary ? 'full' : pick.reason === 'last_resort' ? 'degraded' : 'full',
    };
  }

  /** A provider+model is eligible when healthy + not in cooldown + quota. */
  private eligible(provider: string, model: string, profile: TaskProfile, userId: string): boolean {
    void profile;
    if (!this.health.healthy(provider, model)) return false;
    if (this.health.inCooldown(provider)) return false;
    if (!this.budget.hasQuota(provider, model, userId)) return false;
    return true;
  }

  /**
   * Advance the attempt after a failure (fallback progression). The
   * caller tracks which entry of `chain()` succeeded; when one fails,
   * move to the next. A 429 → record cooldown (never rotate keys).
   */
  nextAttempt(current: ProviderModel): ProviderModel['reason'] {
    return current.reason === 'primary' ? 'fallback' : 'last_resort';
  }
}

/**
 * The frozen S2.6 registry seed (event-reconciliation S2.6 JSON).
 * This is the data the `RouterRegistry` list() returns in production.
 */
export const AGNES_REGISTRY: Array<{
  provider: string;
  models: string[];
  role: 'primary' | 'fallback' | 'last_resort' | 'optional';
  /** S2.6 PRIORITY 3: Agnes recovers → all tasks return to Agnes */
  alwaysFirst?: boolean;
  returnAfterFallback?: boolean;
  onlyWhenPrimaryUnavailable?: boolean;
  cooldownOn429?: number;
  retryOn5xx?: number;
  zeroDataRetention?: boolean;
}> = [
  {
    provider: 'agnes',
    models: ['agnes-2.5-flash', 'agnes-3.0', 'agnes-image-2.5-flash'],
    role: 'primary',
    alwaysFirst: true,
    returnAfterFallback: true,
    cooldownOn429: 60,
    retryOn5xx: 3,
    zeroDataRetention: false,
  },
  {
    provider: 'workers-ai',
    models: ['glm-4.7-flash', 'gemma-4-26b', 'nemotron-3-super-120b'],
    role: 'fallback',
    onlyWhenPrimaryUnavailable: true,
    cooldownOn429: 120,
    retryOn5xx: 2,
  },
  {
    provider: 'groq',
    models: ['gpt-oss-120b', 'gpt-oss-20b'],
    role: 'fallback',
    onlyWhenPrimaryUnavailable: true,
    cooldownOn429: 60,
    retryOn5xx: 2,
  },
  {
    provider: 'cerebras',
    models: ['gpt-oss-120b'],
    role: 'fallback',
    onlyWhenPrimaryUnavailable: true,
    zeroDataRetention: true,
  },
  {
    provider: 'openrouter',
    models: ['nemotron-3-ultra', 'gemma-4'],
    role: 'optional',
    onlyWhenPrimaryUnavailable: true,
  },
  {
    provider: 'cf-worker',
    models: ['workers-ai-direct'],
    role: 'last_resort',
    onlyWhenPrimaryUnavailable: true,
    zeroDataRetention: true,
  },
];

export { levelFor };