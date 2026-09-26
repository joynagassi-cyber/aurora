/**
 * ModelGateway — the runtime that ties the router (task 3 S2.6) to the
 * Vercel SDK layer (sdk.ts / adapters.ts) with error recovery (task 1
 * component 15). The kernel's `invokeModel` delegates here:
 *
 *   router.chain(profile) → build LanguageModel → streamText /
 *   generateText (via sdk.ts) → on failure: classifyFailure +
 *   ErrorRecovery.decide → advance the chain (429 = cooldown, NEVER
 *   key rotation, AD-5) → wrap in AIResponseEnvelope (Result
 *   Normalizer: fallbackUsed, degraded, traceId — no silent fallback).
 *
 * AD-3: no provider key ever appears in this file — keys come from
 * the injected `KeyProvider` (server secret store, adapters.ts).
 * AD-1: the SDK import is confined to this package.
 */
import { generateText, type LanguageModel, type ModelMessage } from 'ai';
import type { ProviderModel, RouterRegistry, HealthChecker, BudgetChecker, DataPolicy } from './router.ts';
import { AgnesPrimaryRouter, AGNES_REGISTRY } from './router.ts';
import { ErrorRecovery, classifyFailure } from './recovery.ts';
import { ProviderModelAdapter, type KeyProvider } from './adapters.ts';
import { streamKernelRun, ALL_TOOL_IDS, KERNEL_MAX_STEPS, type KernelToolId } from './sdk.ts';
import type { TaskProfile } from './types.ts';
import type { AIResponseEnvelope } from '@aurora/domain';
import type { KernelEvent } from './kernel.ts';

/** The S2.6 registry wired to the router (frozen seed, router.ts). */
export function defaultRegistry(): RouterRegistry {
  const entries = AGNES_REGISTRY.map((e) => ({ ...e }));
  return {
    list: () => entries,
    modelFor: (provider, _level, profile) => {
      // ADR v1.7 S7/S10: tools>0 or deep reasoning = AGENT profile
      // (stronger model); else ROUTINE (flash / fast model).
      const wantsStrong = profile.tools > 0 || profile.reasoning === 'deep';
      const models = entries.find((e) => e.provider === provider)?.models ?? [];
      if (models.length === 0) return undefined;
      // first entry = strongest model; last = fastest / cheapest
      return wantsStrong ? models[0] : models[models.length - 1];
    },
  };
}

export interface ModelGatewayDeps {
  registry: RouterRegistry;
  health: HealthChecker;
  budget: BudgetChecker;
  dataPolicy: DataPolicy;
  keys: KeyProvider;
  /** endpoint URL per provider (server config; no key material) */
  baseURLs: Record<string, string>;
  recovery?: ErrorRecovery;
  traceId?: () => string;
}

type ChainEntry = { provider: string; model: string; reason: ProviderModel['reason'] };

/**
 * Call a model for a task profile (the kernel's invokeModel seam).
 * Runs the full S2.6 chain: Agnes-primary (alwaysFirst) → Workers AI
 * fallback (GLM-4.7 Flash / Gemma 4 26B / Nemotron 3 120B) → Groq →
 * Cerebras → OpenRouter → CF Worker. A 429 records a cooldown (AD-5),
 * never rotates keys. The envelope is fully traceable (AD-5).
 */
export class ModelGateway {
  private rg: AgnesPrimaryRouter;
  private adapter: ProviderModelAdapter;
  private recovery: ErrorRecovery;
  private d: ModelGatewayDeps;

  constructor(d: ModelGatewayDeps) {
    this.d = d;
    this.rg = new AgnesPrimaryRouter(d.registry, d.health, d.budget, d.dataPolicy);
    this.adapter = new ProviderModelAdapter(d.keys);
    this.recovery = d.recovery ?? new ErrorRecovery();
  }

  /** The ordered provider chain for a profile (router S2.6). */
  chainFor(profile: TaskProfile, userId: string): ChainEntry[] {
    return this.rg.chain(profile, userId);
  }

  /**
   * Generate (non-streaming) a response, walking the fallback chain.
   * Returns { envelope, text } — the envelope is AD-5 traceable
   * (provider/model/attempt/reason/fallbackUsed).
   */
  async generate(
    req: {
      profile: TaskProfile;
      userId: string;
      messages: ModelMessage[];
      system?: string;
    },
  ): Promise<{ envelope: AIResponseEnvelope<string>; text: string }> {
    const chain = this.chainFor(req.profile, req.userId);
    if (chain.length === 0) {
      return this.deny('no_eligible_provider');
    }
    let attempt = 1;
    let lastError = '';
    for (const entry of chain) {
      let model: LanguageModel;
      try {
        model = await this.adapter.build(
          entry.provider,
          entry.model,
          this.d.baseURLs[entry.provider] ?? `https://models.invalid/${entry.provider}`,
        );
      } catch (e) {
        // provider not configured on this server → unavailable,
        // advance the chain (graceful degradation, AD-1 last ¶)
        lastError = e instanceof Error ? e.message : String(e);
        attempt += 1;
        continue;
      }
      try {
        const res = await generateText({
          model,
          system: req.system,
          messages: req.messages,
        });
        const isPrimary = attempt === 1 && entry.reason === 'primary';
        return {
          text: res.text,
          envelope: this.envelope(entry, res.text, attempt, isPrimary),
        };
      } catch (e) {
        const status = (e as { statusCode?: number })?.statusCode;
        const failure = classifyFailure({ status, kind: e instanceof Error ? e.name : 'error' });
        lastError = e instanceof Error ? e.message : String(e);
        const decision = this.recovery.decide(
          failure,
          { provider: entry.provider, model: entry.model, attempt, reason: entry.reason, expectedQuality: 'full' },
          chain.map((c) => ({ provider: c.provider, model: c.model, attempt: 0, reason: c.reason, expectedQuality: 'full' as const })),
          1,
        );
        if (decision.action === 'stop' || decision.action === 'degrade') {
          return this.deny(`stop:${decision.action}:${lastError}`);
        }
        attempt += 1;
        // 429 → the health checker records the cooldown (AD-5: no key
        // rotation). The router's inCooldown() gate handles the next run.
      }
    }
    return this.deny(`chain_exhausted:${lastError}`);
  }

  /**
   * Stream (the 02 S4 surface, maxSteps=KERNEL_MAX_STEPS).
   * KernelEvents flow to the device as AgentRunState chunks (AD-12).
   * On a stream failure the gateway walks the same fallback chain
   * (streamText is re-invoked on the next eligible provider).
   */
  async stream(
    req: {
      profile: TaskProfile;
      userId: string;
      agentRunId: string;
      messages: ModelMessage[];
      system?: string;
      onEvent: (e: KernelEvent) => void;
      onToolCall?: (tool: string, input: unknown) => boolean | Promise<boolean>;
      toolIds?: KernelToolId[];
    },
  ): Promise<{ envelope: AIResponseEnvelope<string>; text: string }> {
    const chain = this.chainFor(req.profile, req.userId);
    if (chain.length === 0) {
      return this.deny('no_eligible_provider');
    }
    let attempt = 1;
    for (const entry of chain) {
      let model: LanguageModel;
      try {
        model = await this.adapter.build(
          entry.provider,
          entry.model,
          this.d.baseURLs[entry.provider] ?? `https://models.invalid/${entry.provider}`,
        );
      } catch {
        attempt += 1;
        continue;
      }
      try {
        const text = await streamKernelRun({
          model,
          agentRunId: req.agentRunId,
          provider: entry.provider,
          modelName: entry.model,
          system: req.system,
          messages: req.messages,
          onEvent: req.onEvent,
          onToolCall: req.onToolCall,
          toolIds: req.toolIds,
        });
        const isPrimary = attempt === 1 && entry.reason === 'primary';
        return {
          text,
          envelope: this.envelope(entry, text, attempt, isPrimary),
        };
      } catch {
        attempt += 1;
      }
    }
    return this.deny('stream_chain_exhausted');
  }

  /** Build the AD-5 envelope for a served call. */
  private envelope(entry: ChainEntry, data: string, attempt: number, isPrimary: boolean): AIResponseEnvelope<string> {
    return {
      provider: entry.provider,
      model: entry.model,
      attempt,
      reason: isPrimary ? 'primary' : entry.reason === 'last_resort' ? 'last_resort' : 'fallback',
      expectedQuality: entry.reason === 'last_resort' ? 'degraded' : 'full',
      fallbackUsed: attempt > 1 || !isPrimary,
      traceId: this.d.traceId ? this.d.traceId() : `trace-${Date.now()}`,
      data,
    };
  }

  /**
   * The "no eligible provider / exhausted" path: degraded envelope
   * (expectedQuality='degraded') so the device surfaces the notice —
   * never silent (kernel S8, AD-5).
   */
  private deny(why: string): { envelope: AIResponseEnvelope<string>; text: string } {
    void why;
    const primary = this.d.registry.list().find((p) => p.alwaysFirst);
    return {
      text: '',
      envelope: {
        provider: primary?.provider ?? 'none',
        model: 'unavailable',
        attempt: 0,
        reason: 'primary',
        expectedQuality: 'degraded',
        fallbackUsed: false,
        traceId: this.d.traceId ? this.d.traceId() : `trace-${Date.now()}`,
        data: '',
      },
    };
  }

  /** Expose the router (tests + health probes). */
  router(): AgnesPrimaryRouter {
    return this.rg;
  }

  /** The available tool ids (the `tools` subset gate, kernel S14). */
  toolIds(): KernelToolId[] {
    return ALL_TOOL_IDS;
  }
}

/** maxSteps for the streaming surface (02 S4) — a plain function so it
 *  survives `node --experimental-strip-types` (class statics are stripped). */
export function kernelMaxSteps(): number {
  return KERNEL_MAX_STEPS;
}

export { classifyFailure };
