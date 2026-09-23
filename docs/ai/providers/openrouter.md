# OpenRouter — Experimental Free Pool / Benchmarking

Provider ID: `openrouter` · Role: **experimental fallback / benchmarking /
diversification** (ADR v1.7 §8: "Staging + fallback") · Classification: **LIMITED
QUOTA (free account caps, dynamic pool)** + **data-policy variance** (ADR v1.7
§11: some free models have different data-use terms → production routes may
exclude).

- **Pool (21 Sept 2026)**: Nemotron 3 Ultra/Super, Gemma 4, GPT-OSS 20B, "autres
  free modèles variables" — the pool is dynamic by nature (ADR v1.7 §8).
- **Limits (snapshot)**: 50 requests/day and 20 RPM for free accounts (ADR v1.7 §8).
- **Data policy**: check per-model data-use terms; the production route **can
  exclude** incompatible free models (ADR v1.7 §11, 01 §5.6).
- **Role boundaries**: NOT a V1 production pillar (ADR v1.7 §8 decision:
  "Staging + fallback"); `AIUsageTracker` counts its requests explicitly.
- **Snapshot date**: 2026-09-21 · **Sources**: ADR v1.7 §8/§18 (openrouter.ai
  pricing + free-models collection).
