# AI Provider & Routing Specification (Deliverable E)

Status: `DESIGNED_NOT_IMPLEMENTED`. Authority: ADR v1.7 §2–§18 (frozen), spine AD-4/AD-5,
`01-backend` §5.6. **Quota snapshot: 21 Sept 2026 (OQ-12).** Free tiers are **capacities,
not SLAs** (AD-5): nothing below is documented as "permanently free"; the Model Registry
versions states and can auto-retire a provider that becomes unavailable or paid (AD-5,
AD-16b).

## 1. Non-single-model guarantee

Aurora's design never depends on one model: domain/kernel/feature code knows **no concrete
model name** (AD-1, ADR v1.7 §1); model choice is dynamic per typed task profile
(§4 below); at least **two providers are operational in V1** (Agnes + Cloudflare Workers
AI — ADR v1.7 §16); every fallback response is traceable (`AIResponseEnvelope`).

## 2. Pipeline (frozen, AD-4)

`Agent Kernel → Context Builder → Task Classifier → AI Router → AI Policy/Budget →
Cloudflare AI Gateway → Provider Adapter → model`; last-resort path = dedicated Cloudflare
Worker calling Workers AI directly (no business logic; normalizes req/resp + timeouts,
ADR v1.7 §4). Gateway = control/observability layer: analytics, caching, rate limiting,
retries, fallback, dynamic routing, Custom Providers (proxies Agnes without coupling,
ADR v1.7 §3). Placement: **all server-side** (01 §5.6, F-09); secrets in Supabase/Cloudflare
secret stores, never on the device (AD-3).

## 3. Provider matrix (verified 21 Sept 2026; re-verify at integration — ADR v1.7 §8/§18)

| Provider | Role (Aurora) | Free access today (classification) | Useful models / capabilities | Key limits | Decision |
|---|---|---|---|---|---|
| **Agnes** | **Primary** (reasoning + agentic: Agent/Coach/Planner/Tutor/Researcher) | Free API (provider-specific quotas **by account/key type — track, never assume**) | Agnes 3.0 Flash, 2.5 Flash, multimodal Agnes (catalog) | per-account quotas (G-U4) | Core V1 |
| **Cloudflare Workers AI** | **Second pool + fallback** (multimodal) | Free tier: 10 000 Neurons/day (some large models require Workers Paid plan) | GLM-4.7 Flash, Gemma 4 26B A4B, Nemotron 3 Super 120B, others | 10 000 Neurons/day; paid-tier models | Core V1 (second operational provider, R5 ready-to-production criterion) |
| **Cloudflare AI Gateway** | control/observability layer (not a model source) | core features free on all plans (analytics, caching, rate limiting, retries, fallback, dynamic routing) | custom-provider proxying | — | Core V1 |
| **Groq** | high-speed fallback / light batch | Free plan (quota-limited: e.g. 30 RPM; GPT-OSS 120B/20B 1 000 RPD, 8K TPM, 200K TPD on free) | GPT-OSS 120B/20B, tool calling, voice (per model) | free-plan rate caps | V1 optional (wire as soon as key available) |
| **Cerebras** | very-fast reasoning fallback / comparison | Free trial/tier (time-limited; 5 RPM, 30K TPM, 1M tokens/day on covered models) | GPT-OSS 120B, GLM-4.7 + free models per account | temporary limits | V1 optional |
| **OpenRouter** | experimental free pool / benchmarking / diversification | Free pool (50 req/day, 20 RPM per free account; dynamic pool; some free models have different data-use terms) | Nemotron 3 Ultra/Super, Gemma 4, GPT-OSS 20B, others | account caps + data-policy variance (ADR v1.7 §11) | Staging + fallback |
| **Cohere** | specialized RAG/reasoning/vision (not a public V1 engine) | Trial key (1 000 calls/month, ~20 req/min on Chat) | Command A Reasoning 111B, Command A+, Command A Vision, North Mini Code | trial for evaluation/POC | Staging |
| **Mistral** | test alternative | Free mode, no card (low, admin-visible limits; no stable public numbers; check data-use policy settings) | Mistral Small 4, Medium 3.5 | weak public limits | Staging / optional |
| **Google Gemini API** | optional vision/long-context experimentation | Free tier still active Sept 2026 (per project/model, dynamic; verify in AI Studio; free mode may use data for product improvement — ADR v1.7 §12) | Gemini 3.5 Flash / Flash-Lite family | per-project limits | Optional — never a production pillar on free tier |
| **Hugging Face** | one-off benchmarks/tests | micro-credit (0.10 USD/month free account — insufficient for Aurora traffic) | many models via providers | credit too small | Non-core |
| **GitHub Models** | — | **service retired 30 July 2026** | — | — | **Excluded** |
| **SambaNova** | — | Free plan now requires payment + credits (official page) | production models with credits | not a reliable free reserve | **Excluded from free matrix** |

Classification discipline (mission §3): *free tier actuel* vs *trial* vs *promo* vs
*quota limité* vs *provider payant* — Cohere = **trial**; Cerebras = **trial/tier,
time-limited**; Groq/Gemini/HF-free = **quota limité**; Agnes = free API with
account-specific quotas; OpenRouter free pool = quota-limited + data-policy variance.

## 4. Routing (how a model is selected — never `if (task === …)` on raw keywords)

Task Classifier produces a **typed TaskProfile**; the Router decides on: complexity,
reasoning depth, tool calling need, vision need, context length, latency budget, cost/
remaining quota, provider health, task criticality, verification need, data sensitivity
(ADR v1.7 §6). Levels (ADR v1.7 §7):

| Level | Selection (reference strategy, ADR v1.7 §14) |
|---|---|
| ROUTINE (fast/cheap) | Agnes 2.5 / GLM-4.7 Flash / Groq GPT-OSS 20B, per availability |
| AGENT (reasoning/tools) | Agnes 3.0 first, then Nemotron 3 Super / GPT-OSS 120B / Cerebras, per health + quotas |
| MULTIMODAL / VISION-DOCUMENT | Gemma 4 or a compatible vision provider |
| CRITICAL (science etc.) | strong model **+ external/deterministic verification** (KB/source and/or Scientific Engine); optional second "judge" model only when justified |
| FALLBACK | any compatible provider via `AIFallbackStrategy` chain |

Critical-science flow (mission §5 example, ADR v1.7 §14):
`Knowledge/source → method → ScientificEngine (deterministic) → result → verification
(KB/source + engine) → LLM explanation`. A slightly weaker but reliable+verifiable answer is
preferred over total failure (ADR v1.7 §7).

## 5. Fallback rules (AD-5, ADR v1.7 §10)

1. Fallback preserves the task's minimal functional compatibility (vision if vision needed,
   tool calling if tools needed, structured output if JSON required).
2. 429 = interpret the specific limit type; **never** bypass by rotating keys/accounts.
3. Retry (bounded) is for transient faults only; fallback is for unavailability /
   incompatibility / limit reached.
4. Every fallback is traceable: provider, model, attempt, reason, expected quality
   (`AIResponseEnvelope` + `traceId`).
5. Free models can be **auto-retired** from the pool when they become unavailable or paid
   (Model Registry, gated by the single AD-16b owner).

## 6. Privacy / data policy (ADR v1.7 §11)

Documents/courses/notes never auto-flow to a free tier with an incompatible data policy.
Each provider declares a `DataPolicy` in the Model Registry; production routes **can exclude**
incompatible providers (e.g. certain Mistral/OpenRouter free data terms; Groq states no
inference-data retention by default + ZDR control — verify at integration and version it).

## 7. Budgets & usage

`AIBudgetManager`: budgets per provider/model/environment/user; stop **before** overrun;
jobs receive a `budgetSnapshot` and stop cleanly (no mid-generation cut-off, 01 §5.6).
`AIUsageTracker` feeds `ai_usage`; free-tier consumption is tracked explicitly
(degradation = observable, R5).

## 8. Verification & re-verification

All quota/model facts here are the **21 Sept 2026 snapshot** (ADR v1.7 §18 sources).
Re-verify at each provider integration (01 §5.6) and continuously via the Model Registry
(OQ-12, G-U4). The recurring CI "provider retirement" test (01 §7/§8.2 R1) keeps this
drift-safe.
