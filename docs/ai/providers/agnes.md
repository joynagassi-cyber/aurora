# Agnes — Primary Provider

Provider ID: `agnes` · Role: **primary** (reasoning + agentic: Agent/Coach/Planner/
Tutor/Researcher, ADR v1.7 §8) · Classification: **FREE TIER (current, dated
photograph)** — "API gratuite", quotas Agnes propres **à suivre par compte/type de
clé** (never documented as permanent; G-U4 drift, OQ-12).

- **Base URL / SDK**: server-side adapter only (Cloudflare AI Gateway Custom
  Provider proxy, ADR v1.7 §3 — the core is not coupled to Agnes); **domain/kernel/
  feature code depends on `AIProvider`, never on Agnes** (AD-1, ADR v1.7 §16: code
  must not treat `agnes-3.0-flash` as the only model).
- **Authentication**: API key in **Supabase Secrets / Cloudflare Secrets Store**
  (01 §5.6) — never in code, never on device (AD-3).
- **Models (21 Sept 2026 snapshot, ADR v1.7 §8)**: Agnes 3.0 Flash (AGENT tier
  first choice, §14), Agnes 2.5 Flash (ROUTINE tier), multimodal Agnes models per
  current catalog (VISION tier); re-verify the catalog at integration.
- **Capabilities**: reasoning, tool calling, streaming, structured outputs (via the
  adapter contract `AIProvider.complete/stream`); vision per model catalog entry.
- **Rate limits / 429**: account/key-type-specific (no stable public numbers in the
  ADR snapshot) → `AIHealthRegistry` tracks them; a 429 = cooldown, **never** key
  rotation (AD-5, 01 §7(b)); retry bounded (transient only).
- **Timeouts / fallback compatibility**: full (ROUTINE/AGENT/VISION/CRITIQUE tiers
  all compatible; fallback = `AIFallbackStrategy` chain → Workers AI pool → last-
  resort Worker, docs/ai/gateway.md).
- **Health check**: Model Registry status + `AIHealthRegistry` (auto-retirement
  gated by the single AD-16b owner).
- **Data policy**: declared in the Model Registry (`DataPolicy`, ADR v1.7 §11) —
  verify current terms at integration; production routes can exclude incompatible
  providers.
- **Snapshot date**: 2026-09-21 · **Verification date**: 2026-09-21 (ADR v1.7 §8/
  §18) · **Source**: ADR v1.7 §8/§14/§18 (Agnes entries); re-check official Agnes
  docs at wave 1 (wave 1 readiness = Agnes + Workers AI operational, ADR v1.7 §16).
