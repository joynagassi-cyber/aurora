# Cerebras — Very-Fast Reasoning Fallback (REMOVED, no key — OQ-03)

Provider ID: `cerebras` · Role: **fallback reasoning très rapide / comparison**
(ADR v1.7 §8: "Provider V1 optionnel") · Classification: **TRIAL (time-limited free
limits)** — limits are explicitly temporary in the ADR snapshot.

- **Models (21 Sept 2026)**: GPT-OSS 120B, GLM-4.7 + other free models per account
  (ADR v1.7 §8).
- **Limits (snapshot)**: 5 RPM, 30K TPM, 1M tokens/day on covered models; "limites
  temporaires possibles" (ADR v1.7 §8) → treat as a **capacity photograph**, the
  Model Registry can retire it without touching the domain (AD-1/AD-5).
- **429 / retry-after / quota**: rate-limit semantics per current docs; bounded
  retry, no key rotation (AD-5); exhaustion → `AIHealthRegistry` degradation +
  fallback chain.
- **Data policy**: check current Cerebras terms at integration (DataPolicy field,
  Model Registry).
- **Snapshot date**: 2026-09-21 · **Sources**: ADR v1.7 §8/§18 (inference-docs.
  cerebras.ai rate limits + models overview).
