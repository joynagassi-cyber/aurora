# Cloudflare Workers AI — Second Pool (mission §24)

Provider ID: `cloudflare-workers-ai` · Role: **second pool + fallback pool +
multimodal** (AD-4) · Classification: **FREE TIER (dated photograph)** — 10 000
Neurons/day on Free; beyond that = Workers Paid billing (documented as a
photograph, never a promise — G-U4).

- **Models (21 Sept 2026, ADR v1.7 §8)**: GLM-4.7 Flash (ROUTINE tier, §14), Gemma
  4 26B A4B, Nemotron 3 Super 120B (AGENT tier fallback); "modèles éligibles" — the
  live list moves, so **model availability/removal is a health item, not a
  constant** (Model Registry tracks, AD-5).
- **Capabilities**: reasoning (Nemotron 3 Super), vision (Gemma 4 — VISION/
  DOCUMENT tier §14), tool calling per model catalog; streaming via `AIProvider`.
- **Limits (dated)**: 10 000 Neurons/day free; some large models require Workers
  Paid (ADR v1.7 §8) → `AIUsageTracker` monitors Neuron consumption explicitly
  (free-tier drift = observable, 01 §8.2 R5).
- **Quota reset / paid transition**: daily Neuron reset (verify at integration);
  exhaustion → provider marked degraded → fallback chain continues (AD-5; a 429 is
  never bypassed by rotating accounts — AD-5).
- **Failure modes / 429 behavior**: standard rate-limit semantics; retry bounded
  (transient), fallback on limit hit; traceability via `AIResponseEnvelope`
  (`reason:'fallback'|'last_resort'` — the last-resort Worker calls this pool
  directly when the Gateway path is down, ADR v1.7 §4).
- **Health**: `AIHealthRegistry` (latency, 429/5xx, cooldown); auto-retirement from
  the pool when unavailable/paid (AD-5, single owner AD-16b).
- **Snapshot date**: 2026-09-21 · **Verification date**: 2026-09-21 · **Sources**:
  ADR v1.7 §8/§18 (https://developers.cloudflare.com/workers-ai/platform/pricing/,
  changelog); re-verify the model list at each integration (01 §5.6).
