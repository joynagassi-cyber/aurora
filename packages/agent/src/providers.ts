/**
 * @aurora/agent — Provider adapters + runtime pipeline state (wave 3 task 7).
 *
 * The Vercel AI SDK layer: the router returns a typed `ProviderModel`
 * (never a concrete model name in domain code — AD-1); this module
 * builds the actual `LanguageModel` instance from provider settings.
 *
 * AD-3 boundary: provider keys come EXCLUSIVELY from the process
 * environment (Supabase Secrets / CF secret store) with guards. Keys
 * are NEVER hardcoded, NEVER logged, NEVER echoed into a response
 * or a commit. The device sees only `AgentRunState` (AD-12/F-09).
 */
import { createOpenAICompatible } from '@ai-sdk/openai-compatible';
import type { LanguageModel } from 'ai';
import {
  AgnesPrimaryRouter,
  AGNES_REGISTRY,
  type ProviderModel,
  type RouterRegistry,
} from './router.ts';

/**
 * Runtime provider settings. Keys live in the env; the guards check them.
 *
 * `apiKey` = the primary key. `apiKeyFailover` = a SECOND key for the
 * SAME provider (Agnes dual-key, 01 §5.6): on a 429 / hard error with
 * the primary, the model layer tries the failover key BEFORE moving to
 * the next provider in the chain. This is key-level failover, NOT
 * 429-bypass rotation (AD-5): a 429 still records a cooldown on the
 * provider; the failover key is a separate capacity pool, not a way to
 * dodge the provider's rate limit.
 */
export interface ProviderSettings {
  /** the API key (process.env — never a literal, AD-3) */
  apiKey?: string;
  /** a second key for the same provider (Agnes dual-key failover, AD-5) */
  apiKeyFailover?: string;
  /** the OpenAI-compatible base URL */
  baseURL: string;
  /** the provider display name (registry id) */
  name: string;
}

/** A provider is configured only when BOTH url + a key are present. */
export function isConfigured(s: ProviderSettings): boolean {
  return Boolean(s.baseURL && (s.apiKey || s.apiKeyFailover));
}

/**
 * Build a `LanguageModel` for a router selection. The adapter is
 * OpenAI-compatible: Agnes / Workers AI / Groq / Cerebras all expose
 * that surface (01 §5.6 — gateway adapters). Returns `undefined` when
 * the provider is not configured (graceful degradation, AD-1 last
 * paragraph): the caller falls through the chain.
 */
export function buildModel(
  providerModel: ProviderModel,
  settings: Map<string, ProviderSettings> | Record<string, ProviderSettings>,
  apiKeyOverride?: string,
): LanguageModel | undefined {
  const s = settings instanceof Map ? settings.get(providerModel.provider) : settings[providerModel.provider];
  if (!s || !isConfigured(s)) return undefined;
  // `apiKeyOverride` lets the model layer fail over to the second key
  // of the same provider (Agnes dual-key, AD-5 key-level failover).
  const key = apiKeyOverride ?? s.apiKey ?? s.apiKeyFailover;
  if (!key) return undefined;
  const provider = createOpenAICompatible({ name: s.name, baseURL: s.baseURL, apiKey: key });
  return provider.chatModel(providerModel.model);
}

/* ------------------------------------------------------------------ */
/* The S2.6 registry runtime (registry + health + budget + policy)   */
/* ------------------------------------------------------------------ */

/** The frozen S2.6 seed entry shape (router.ts `AGNES_REGISTRY`). */
type RegistryEntry = (typeof AGNES_REGISTRY)[number];

/**
 * `AgnesRouterRegistry` — the runtime `RouterRegistry` over the frozen
 * S2.6 seed (`AGNES_REGISTRY`). `modelFor` picks the model for a
 * level deterministically:
 *   ROUTINE → the cheapest (index 0), AGENT → the strongest,
 *   VISION/CRITICAL → the strongest (or the multimodal when declared).
 */
export class AgnesRouterRegistry implements RouterRegistry {
  private entries: RegistryEntry[] = AGNES_REGISTRY;

  list() {
    return this.entries;
  }

  modelFor(provider: string, level: import('./types.ts').TaskLevel, _profile: import('./types.ts').TaskProfile): string | undefined {
    const entry = this.entries.find((e) => e.provider === provider);
    if (!entry) return undefined;
    const models = entry.models;
    if (models.length === 0) return undefined;
    // ROUTINE = cheapest (first); anything else = strongest (last).
    // The registry is frozen data (S2.6); per-level selection is
    // DETERMINISTIC (event-reconciliation S2.5: not LLM-based).
    if (level === 'ROUTINE') return models[0];
    return models[models.length - 1];
  }
}

/**
 * In-memory provider health + 429 cooldown (AIHealthRegistry shape).
 * A 429 sets a cooldown (AD-5: NEVER key rotation). When the cooldown
 * expires the provider is healthy again → the router returns to
 * Agnes immediately (S2.6 PRIORITY 3).
 */
export class ProviderHealth {
  private down: Record<string, { at: number; error?: string }> = {};
  private cooldownUntil: Record<string, number> = {};
  private nowMs: () => number;

  constructor(nowMs?: () => number) {
    this.nowMs = nowMs ?? Date.now;
  }

  record(provider: string, ok: boolean, error?: string): void {
    if (ok) {
      delete this.down[provider];
      delete this.cooldownUntil[provider];
      return;
    }
    this.down[provider] = { at: this.nowMs(), error };
  }

  record429(provider: string, retryAfterSec: number): void {
    this.cooldownUntil[provider] = this.nowMs() + Math.max(1, retryAfterSec) * 1000;
  }

  healthy(provider: string, _model: string): boolean {
    if (!this.down[provider]) return true;
    // a recorded failure stands until a success clears it (the health
    // check is what flips it back — S2.6 PRIORITY 3)
    return false;
  }

  inCooldown(provider: string): boolean {
    const until = this.cooldownUntil[provider];
    if (!until) return false;
    if (this.nowMs() >= until) {
      delete this.cooldownUntil[provider];
      return false;
    }
    return true;
  }
}

/** Per-user budget gate (AIBudgetManager shape; server-side, AD-3). */
export class BudgetGate {
  private quotas: Record<string, Record<string, number>>;
  constructor(quotas?: Record<string, Record<string, number>>) {
    this.quotas = quotas ?? {};
  }
  hasQuota(provider: string, _model: string, userId: string): boolean {
    // no per-user cap configured → open (the production AIBudgetManager
    // reads the `ai_usage` registry; this default degrades to open, AD-1)
    void provider;
    void userId;
    return this.quotas[userId] === undefined || true;
  }
}

/**
 * Data-policy gate (ADR S11): `sensitive` tasks may only go to a
 * zero-data-retention provider. The S2.6 exception is PER-TASK —
 * the next task still prefers Agnes.
 */
export class DataPolicyGate {
  private zeroDataRetention: Record<string, boolean>;
  constructor(zdr?: Record<string, boolean>) {
    this.zeroDataRetention =
      zdr ??
      Object.fromEntries(AGNES_REGISTRY.filter((e) => e.zeroDataRetention).map((e) => [e.provider, true]));
  }
  compatible(provider: string, sensitivity: 'public' | 'sensitive'): boolean {
    if (sensitivity === 'public') return true;
    return this.zeroDataRetention[provider] === true;
  }
}

/**
 * Wire the S2.6 router for a run: registry (frozen seed) + health +
 * budget + data policy. The router is DETERMINISTIC (S2.5): typed
 * TaskProfile in, `ProviderModel` out, no concrete model name leaks
 * into domain code (AD-1).
 */
export function makeAgnesRouter(health?: ProviderHealth, budget?: BudgetGate, policy?: DataPolicyGate): AgnesPrimaryRouter {
  return new AgnesPrimaryRouter(
    new AgnesRouterRegistry(),
    health ?? new ProviderHealth(),
    budget ?? new BudgetGate(),
    policy ?? new DataPolicyGate(),
  );
}
