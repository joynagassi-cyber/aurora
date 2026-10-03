
> **NOTE (2026-10-03, OQ-03):** Agnes dual-key failover (01 S5.6 / AD-5):
> the router tries `AGNES_API_KEY_1` first; on a 429 / hard error it moves
> to `AGNES_API_KEY_2` (a separate capacity pool) BEFORE falling through to
> Workers AI, then Groq, then OpenRouter. `AGNES_API_KEY_2` is NOT a 429
> bypass - a 429 still records a cooldown on the provider (AD-5 invariant).
> Cerebras is removed (no key, OQ-03). Cloudflare Workers AI uses
> `CF_API_WORKERS_AI_TOKEN` (scope workers-ai), NOT a dedicated provider
> key. Research (Exa/Tavily/You.com) + Integration (Composio) keys are in
> the **same Supabase secret store** but are consumed by the
> `ResearchProvider` / `IntegrationProvider` ports - NOT the LLM router.
