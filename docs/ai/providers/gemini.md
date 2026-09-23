# Google Gemini API — Optional Experimentation

Provider ID: `google-gemini` · Role: **optional vision/long-context
experimentation — never a production pillar on the free tier** (ADR v1.7 §8/§12) ·
Classification: **FREE TIER (dated photograph — still active Sept 2026, ADR v1.7
§12 "statut corrigé")**.

- **Models (21 Sept 2026)**: Gemini 3.5 Flash, Flash-Lite + catalog (dynamic, ADR
  v1.7 §8).
- **Limits**: per project/model, **dynamic — verify in AI Studio at integration**
  (Google does not publish a stable universal quota table, ADR v1.7 §12); free mode
  may use data for product improvement (ADR v1.7 §12) → **DataPolicy check
  mandatory** before routing sensitive user data.
- **Role**: VISION/long-context experiments + fallback pool membership; Model
  Registry can disable it per environment (AD-1: domain unaffected).
- **Snapshot date**: 2026-09-21 · **Sources**: ADR v1.7 §8/§12/§18 (ai.google.dev
  pricing + rate limits).
