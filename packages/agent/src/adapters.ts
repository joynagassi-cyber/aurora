/**
 * Provider adapters — build a LanguageModel for the router's output
 * (task 3, vercel-ai-sdk-integration.md "Integration architecture").
 *
 * AD-1 boundary: this file (with sdk.ts + gateway.ts) is the ONLY
 * `ai`-importing surface in the monorepo.
 *
 * AD-3 invariants: keys are NEVER arguments / NEVER literals. Each
 * adapter reads its key from the server secret store via the injected
 * `KeyProvider` (fn-agent-run env / CF Workers secret). The device
 * bundle contains zero provider keys — these classes only ever run
 * server-side (AD-12/F-09).
 *
 * All providers are OpenAI-compatible (ADR v1.7 S4): one
 * `createOpenAICompatible` factory per provider, different baseURL.
 * No concrete model name leaks into domain code (AD-1, ADR S1): the
 * model id comes from the router's `ProviderModel` output.
 */
import { createOpenAICompatible } from '@ai-sdk/openai-compatible';
import type { LanguageModel } from 'ai';

/**
 * A key provider = server secret store access (env / Workers secret /
 * Vault). The kernel + SDK layers NEVER see the key value in their
 * signatures — only this object does (AD-3).
 */
export type KeyProvider = (provider: string) => string | undefined;

/**
 * Build the LanguageModel for one provider + model (one adapter per
 * call — the router already chose; the 429 cooldown is owned by the
 * health checker, not here, AD-5: never rotate keys on a 429).
 */
export class ProviderModelAdapter {
  private keys: KeyProvider;

  constructor(keys: KeyProvider) {
    this.keys = keys;
  }

  async build(provider: string, model: string, baseURL: string): Promise<LanguageModel> {
    const apiKey = this.keys(provider);
    if (!apiKey) {
      // No key = provider NOT configured on this server (graceful
      // degradation, AD-1 last paragraph): surface a typed error the
      // router's health checker records — NOT a crash, and NEVER the
      // key value (AD-3: the key is never echoed).
      throw new Error(`provider_not_configured:${provider}`);
    }
    const client = createOpenAICompatible({
      name: provider,
      baseURL,
      apiKey,
    });
    return client.languageModel(model);
  }

  /** The provider/model that actually served (envelope, AD-5). */
  serving(provider: string, model: string): { provider: string; model: string } {
    return { provider, model };
  }
}

/**
 * The `keyProvider` for fn-agent-run: reads the Supabase env /
 * secret (server-side ONLY, AD-3). Key names (.env.local, 10-AI):
 * AGNES_API_KEY, GROQ_API_KEY, CEREBRAS_API_KEY, OPENROUTER_API_KEY,
 * EXA_API_KEY / TAVILY_API_KEY / YOU_API_KEY (research providers,
 * consumed by the ResearchProvider port — NOT this layer). No key
 * value ever leaves this function.
 */
export function envKeyProvider(env: Record<string, string | undefined>): KeyProvider {
  const map: Record<string, string> = {
    agnes: env.AGNES_API_KEY ?? '',
    groq: env.GROQ_API_KEY ?? '',
    cerebras: env.CEREBRAS_API_KEY ?? '',
    openrouter: env.OPENROUTER_API_KEY ?? '',
    'workers-ai': env.WORKERS_AI_API_KEY ?? '',
    'cf-worker': env.WORKERS_AI_API_KEY ?? '',
  };
  return (provider: string) => map[provider] || undefined;
}
