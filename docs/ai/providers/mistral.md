# Mistral — Test Alternative (Optional)

Provider ID: `mistral` · Role: **test alternative; data-policy-sensitive** (ADR
v1.7 §8: "Staging / optionnel") · Classification: **LIMITED QUOTA (free mode, no
card; weak and admin-visible limits, no stable public numbers — ADR v1.7 §8)**.

- **Models (21 Sept 2026)**: Mistral Small 4, Medium 3.5 + account-dependent list
  (ADR v1.7 §8).
- **Data control**: "désactiver l'usage des données pour entraînement selon
  politique" (ADR v1.7 §8/§11) — the training-data setting MUST be checked per
  account; the production route can exclude (01 §5.6).
- **Limits**: visible in the admin console (not stable public numbers) →
  `AIUsageTracker` + `AIHealthRegistry` own the truth at runtime.
- **Snapshot date**: 2026-09-21 · **Sources**: ADR v1.7 §8/§18 (docs.mistral.ai
  usage limits + data policy pages).
