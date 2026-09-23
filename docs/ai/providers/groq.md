# Groq — High-Speed Fallback (mission §27)

Provider ID: `groq` · Role: **fallback haute vitesse / light batch** (ADR v1.7 §8
decision: "Provider V1 optionnel" — wire as soon as a key exists; ready-to-
production criterion R5, 01 §8.2) · Classification: **LIMITED QUOTA (free plan,
dated)** — not a trial: a standing free plan with hard caps.

- **Models (21 Sept 2026, ADR v1.7 §8)**: GPT-OSS 120B (reasoning + tool use),
  GPT-OSS 20B (fast/tool); current model list to be taken **from the account/docs
  at implementation time** (explicit ADR instruction — do not freeze this page's
  list beyond the snapshot).
- **Free plan limits (snapshot)**: e.g. 30 RPM; GPT-OSS 120B/20B: 1 000 RPD, 8K
  TPM, 200K TPD on the Free Plan (ADR v1.7 §8 "limitations clés").
- **Rate limits / 429**: organization-level rate-limit headers (document per the
  current Groq docs at integration; ADR §18 source: console.groq.com/docs/rate-
  limits) → `AIHealthRegistry` cooldowns; **never** rotate keys to bypass a 429
  (AD-5); bounded retry for transient faults.
- **Data policy**: Groq states it does not retain inference data by default and
  offers Zero Data Retention control (ADR v1.7 §11) — **verify and version at
  integration** (DataPolicy in the Model Registry).
- **Fallback compatibility**: full (high-speed pool for AGENT/ROUTINE tiers; vision
  not claimed).
- **Snapshot date**: 2026-09-21 · **Verification date**: 2026-09-21 · **Sources**:
  ADR v1.7 §8/§18 (rate limits, models, your-data pages).
