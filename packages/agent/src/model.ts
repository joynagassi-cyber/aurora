/**
 * @aurora/agent — Model invocation layer (wave 3 task 7, AD-1 boundary).
 *
 * This is the ONLY file in the monorepo that imports `ai` besides
 * tools.ts (AD-1: the Vercel AI SDK lives only in packages/agent).
 * `invokeModel()` wires the S2.6 router chain + the OpenAI-compatible
 * adapter: Agnes PRIMARY → Workers AI → Groq (buildModel), bounded
 * per-provider retry, 429 cooldown (never key rotation, AD-5),
 * traceable AIResponseEnvelope (AD-5).
 */
import { generateText, isStepCount, type LanguageModel } from 'ai';
import { AGNES_REGISTRY, AgnesPrimaryRouter, type ProviderModel, type RouterRegistry } from './router.ts';
import { ErrorRecovery, classifyFailure, type FailureClass } from './recovery.ts';
import type { DataPolicy, BudgetChecker, HealthChecker } from './router.ts';
import type { TaskProfile } from './types.ts';
import type { ProviderSettings } from './providers.ts';

export type { ProviderSettings };
export type {
  HealthChecker,
  BudgetChecker,
  DataPolicy,
  RouterRegistry,
} from './router.ts';
export type { ErrorRecovery } from './recovery.ts';

/**
 * The health-mutating surface the model layer writes to after a call
 * (the read-only `HealthChecker` gate is on the router side; the EF
 * passes its `ProviderHealth` which implements both).
 */
export interface HealthMutator extends HealthChecker {
  record(provider: string, ok: boolean, error?: string): void;
  record429?(provider: string, retryAfterSec?: number): void;
}

/**
 * Runtime guard: does this health checker expose the mutating surface
 * (the EF's ProviderHealth does; a read-only gate does not)?
 */
function isHealthMutator(h: HealthChecker): h is HealthMutator {
  return typeof (h as { record?: unknown }).record === 'function';
}

export interface InvokeModelDeps {
  /** registry + health + budget + data-policy (S2.6 surfaces).
   *  `health` is the mutable store when failure recording is desired
   *  (the EF passes its ProviderHealth); a read-only checker is fine. */
  registry: RouterRegistry;
  health: HealthChecker;
  budget: BudgetChecker;
  dataPolicy: DataPolicy;
  /** the SDK adapter settings, keyed by provider (env-injected, AD-3) */
  settings: Record<string, ProviderSettings | undefined>;
  /** bounded retry (recovery component) */
  recovery?: ErrorRecovery;
}

export interface ModelCall {
  profile: TaskProfile;
  system: string;
  prompt: string;
  /** envelope trace id (AD-5 traceability) */
  traceId: string;
  userId: string;
}
export interface ModelResult {
  data: string;
  /** the provider that actually served the call (after any fallback) */
  provider: string;
  model: string;
  /** which attempt (1-based; > 1 means a fallback happened) */
  attempt: number;
  reason: 'primary' | 'fallback' | 'last_resort';
  expectedQuality: 'full' | 'degraded';
  traceId: string;
  /** true when a fallback provider served the call (AD-5) */
  fallbackUsed: boolean;
}

/**
 * The thinking-level → OpenAI-compatible `reasoning_effort` mapping
 * (the SDK's `reasoningEffort` chat option — forwarded to the provider
 * request body as `reasoning_effort` by the OpenAI-compatible adapter;
 * non-reasoning models ignore the field gracefully).
 */
const THINKING_EFFORT: Record<NonNullable<TaskProfile['thinkingLevel']>, string> = {
  low: 'minimal',
  medium: 'medium',
  high: 'high',
  max: 'xhigh',
};

/**
 * `invokeModel` — run the typed S2.6 chain and return the call that
 * actually served. Bounded retry on transient (5xx/timeout), 429 →
 * record cooldown on that provider (AD-5: NEVER key rotation),
 * then fall back through the chain. The moment Agnes is healthy
 * again, the NEXT call returns to Agnes automatically (PRIORITY 3).
 *
 * The `thinkingLevel` (TaskProfile, device picker) is forwarded to the
 * provider as `reasoning_effort` (the OpenAI-compatible chat option
 * `reasoningEffort` — models that don't support it ignore the field).
 */
export async function invokeModel(deps: InvokeModelDeps, call: ModelCall): Promise<ModelResult> {
  const router = new AgnesPrimaryRouter(deps.registry, deps.health, deps.budget, deps.dataPolicy);
  const recovery = deps.recovery ?? new ErrorRecovery();
  const chain: ProviderModel[] = router.chain(call.profile, call.userId).map((c) => ({
    provider: c.provider,
    model: c.model,
    attempt: 1,
    reason: c.reason,
    expectedQuality: c.reason === 'primary' ? 'full' : 'degraded',
  }));

  if (chain.length === 0) {
    // No eligible provider: CRITICAL tasks would throw a budget
    // error (S2.6 step 3); ROUTINE degrades (AD-1 last paragraph).
    const critical = call.profile.criticality === 'critical';
    return {
      data: critical
        ? 'All providers unavailable — task marked degraded (S2.6).'
        : 'Model unavailable — check provider configuration.',
      provider: 'none',
      model: 'none',
      attempt: 0,
      reason: 'last_resort',
      expectedQuality: 'degraded',
      traceId: call.traceId,
      fallbackUsed: false,
    };
  }

  for (let i = 0; i < chain.length; i++) {
    const sel = chain[i]!;
    const settings = deps.settings[sel.provider];
    if (!settings) continue; // not configured → next in the chain

    // The key sequence for this provider: primary, then the failover
    // key (Agnes dual-key, 01 §5.6). A 429 / error on the primary key
    // triggers the failover key BEFORE falling through to the next
    // provider (AD-5: this is key-level failover, not 429-bypass
    // rotation — a 429 still records a cooldown on the provider).
    const keySeq = [settings.apiKey, settings.apiKeyFailover].filter(
      (k): k is string => Boolean(k),
    );
    if (keySeq.length === 0) continue;

    for (const apiKey of keySeq) {
      // build the LanguageModel via the OpenAI-compatible adapter (AD-1)
      let model: LanguageModel | undefined;
      try {
        const { createOpenAICompatible } = await import('@ai-sdk/openai-compatible');
        const provider = createOpenAICompatible({
          name: settings.name,
          baseURL: settings.baseURL,
          apiKey,
        });
        model = provider.chatModel(sel.model);
      } catch {
        break; // adapter failure → next key / provider
      }

      let attempt = 0;
      let lastErr: { status?: number; kind?: string; message?: string; retryAfterSec?: number } = {
        message: 'unconfigured',
      };
      let succeeded = false;
      while (true) {
        attempt++;
        try {
          const res = await generateText({
            model,
            system: call.system,
            prompt: call.prompt,
            // The thinking level (TaskProfile.thinkingLevel, device
            // picker) → the OpenAI-compatible `reasoningEffort` provider
            // option (the exact field the SDK schema accepts). Non-
            // reasoning models ignore it gracefully; Agnes / GLM /
            // Nemotron surface it as their own thinking-effort knob.
            providerOptions: {
              openaiCompatible: {
                reasoningEffort: THINKING_EFFORT[call.profile.thinkingLevel ?? 'medium'],
              },
            },
            // v7: the agentic loop cap (the doc's "maxSteps=5") is now
            // stopWhen: isStepCount(n)
            stopWhen: isStepCount(5),
          });
          succeeded = true;
          return {
            data: res.text,
            provider: sel.provider,
            model: sel.model,
            attempt,
            reason: sel.reason,
            expectedQuality: sel.expectedQuality,
            traceId: call.traceId,
            fallbackUsed: sel.reason !== 'primary' || attempt > 1 || apiKey !== keySeq[0],
          };
        } catch (e) {
          lastErr = {
            status: (e as { status?: number }).status,
            kind: (e as { code?: string }).code,
            message: e instanceof Error ? e.message : String(e),
            retryAfterSec:
              Number((e as { headers?: Record<string, string> }).headers?.['retry-after'] ?? 0) ||
              undefined,
          };
          const cls = classifyFailure(lastErr) as FailureClass;
          const decision = recovery.decide(cls, sel, chain, attempt);
          // bounded retry on the same key (transient, 5xx)
          if (decision.action === 'retry' && attempt < 3) continue;
          // 429 / error → break to the failover key (or next provider)
          break;
        }
      }
      if (succeeded) break;

      // record the failure on the provider so the health gate blocks it
      // next time (S2.6 PRIORITY 3 auto-return when it recovers).
      if (isHealthMutator(deps.health)) {
        deps.health.record(sel.provider, false, lastErr.message);
        if (lastErr.message?.includes('429')) {
          deps.health.record429?.(sel.provider, lastErr.retryAfterSec);
        }
      }
      // a hard error on the last key of this provider → next provider
    }
  }

  // all providers failed
  return {
    data: 'All providers unavailable — task marked degraded.',
    provider: 'none',
    model: 'none',
    attempt: 0,
    reason: 'last_resort',
    expectedQuality: 'degraded',
    traceId: call.traceId,
    fallbackUsed: true,
  };
}

/**
 * Static provider settings for the S2.6 chain (AD-3: keys from env;
 * `loadProviders` in fn-agent-run fills these at boot; `undefined`
 * entries are skipped by invokeModel — graceful degradation).
 */
export function agnesProviderChain(): Array<{ provider: string; role: string; alwaysFirst?: boolean }> {
  return AGNES_REGISTRY.map((r) => ({ provider: r.provider, role: r.role, alwaysFirst: r.alwaysFirst }));
}

/** The system prompt the agent uses (data, not secret) — re-exported from prompt.ts (single source of truth). */
export { AGENT_SYSTEM_PROMPT } from './prompt.ts';
