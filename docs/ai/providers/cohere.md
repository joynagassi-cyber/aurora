# Cohere — Specialized RAG / Reasoning / Vision (Staging)

Provider ID: `cohere` · Role: **specialized RAG/reasoning/vision — NOT a public V1
engine** (ADR v1.7 §8: "Staging") · Classification: **TRIAL (1 000 calls/month on a
trial key, POC-grade)**.

- **Models (21 Sept 2026)**: Command A Reasoning 111B, Command A+, Command A
  Vision, North Mini Code (ADR v1.7 §8).
- **Limits (snapshot)**: 1 000 calls/month; ~20 req/min on Chat (ADR v1.7 §8).
- **Usage**: RAG/reasoning/vision experiments + benchmarking; `AIHealthRegistry`
  tracks trial exhaustion; production exclusion possible per data policy (ADR
  v1.7 §11).
- **Snapshot date**: 2026-09-21 · **Sources**: ADR v1.7 §8/§18 (docs.cohere.com
  rate limits + model pages).
