# Cloudflare AI Gateway — where it sits (mission §23)

Status: design phase. Authority: ADR v1.7 §3/§5/§15, 01 §5.6, spine AD-4.

## 1. Placement (exactly one rule, no undocumented paths)

```
Aurora (kernel + all AI calls)
  → Context Builder → Task Classifier → AI Router → AI Policy/Budget (AIBudgetManager)
  → **Cloudflare AI Gateway** (control plane)
      → provider adapters (Agnes via Custom Provider, Workers AI, Groq, Cerebras,
         OpenRouter, Cohere, Mistral, Gemini — the registered pool, ADR v1.7 §2/§8)
Exception (documented, AD-4 last-resort): if the Gateway/main path is unavailable,
  the dedicated Cloudflare fallback Worker calls **Workers AI directly**
  (docs/cloudflare/workers.md (b)) — that is the ONLY direct-provider path, and it
  stays a normalized edge pass-through (zero business logic).
```

"Aucun appel qui ne passe pas par le Gateway" is true **by design**: everything
else is a configuration error (review red-line: a vendor SDK call outside the
adapter set, AD-1).

## 2. Functions used (per ADR v1.7 §3 + 01 §5.6 — re-verify at integration:
Dynamic Routing & Unified Billing evolve, official docs)

- **analytics** (per-request/tenant logging → feeds `AIUsageTracker`/`ai_usage`),
- **caching** (prompt/response, quota saver — data-policy-aware: cached content
  stays within the provider's declared policy),
- **rate limiting** (per-key/provider; complements `AIBudgetManager` stop-before-
  overrun),
- **retries** (transient only — AD-5 split retry vs fallback),
- **fallback + Dynamic Routing** (router-level failover between registered
  providers; model selection stays Aurora's typed TaskProfile, ADR v1.7 §6 — the
  Gateway routes, it does not choose the model),
- **Custom Providers** (proxies Agnes without coupling the core, ADR v1.7 §3),
- **error normalization** → `AIResponseEnvelope` (provider/model/attempt/reason/
  expected quality + traceId, 01 §3.1).

## 3. Budgets, health, data policy, observability

- **Budgets**: `AIBudgetManager` (per provider/model/env/user; job receives
  `budgetSnapshot` and stops cleanly — 01 §5.6) sits **before** the Gateway call.
- **Health**: `AIHealthRegistry` (latency, error rates, 429/5xx, cooldown,
  availability per provider/model) consumes Gateway analytics + job outcomes;
  the Model Registry auto-retires providers that become unavailable or paid
  (AD-5, gated by the single AD-16b owner).
- **Data policy**: each provider's `DataPolicy` lives in the Model Registry (ADR
  v1.7 §11); incompatible free tiers can be excluded from production routes;
  `AIRequestGuard` refuses before the call when the payload would leak to an
  incompatible provider (01 §6).
- **Observability**: Sentry + PostHog (AD-16d) + `job_logs` for agent runs;
  every fallback response traceable (AD-5) — test suite 01 §7 (a-e).
