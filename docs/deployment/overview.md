# Deployment & Environments — Technical Page

Status: `DESIGNED_NOT_IMPLEMENTED` (wave 0 structure; wave 7 release pipeline).
Authority: spine AD-16 (frozen operational envelope), `01-backend` §5/§8.1, ADR
§21.5 (PR pipeline), AI_RULES (GitHub Actions).

## 1. Environments (AD-16a — structure frozen, values open)

Exactly **three** deploy targets: `dev`, `staging`, `prod`. The *structure* is
fixed; the concrete values (regions, R2 bucket names, provider account IDs,
per-environment Model Registry entries) are **wave-0 data** (OQ-03, owner
Foundation). No team provisions its own buckets/keys/environments (AD-16; CI
test: a new bucket/registry in a feature PR = failure, 01 §8.2 R7).

## 2. Platform targets

- **Supabase** (Postgres + Auth + Edge Functions + Cron + pgvector; project
  wired in the workspace via `.mcp.json` `supabase-aurora`). RLS + policies
  migrate with every schema change (blocking test, 01 §7).
- **Cloudflare** (R2 private buckets; AI Gateway; Workers AI pool; last-resort
  fallback Worker; worker templates for jobs, 01 §5.2) — accounts owned by
  Foundation (AD-16c).
- **Device**: Android APK (Phase 1 target, ADR §23.1).

## 3. CI/CD (GitHub Actions, ADR §21.5 — the mandatory PR pipeline)

code in branch → unit + domain tests → type-check → lint/format (**incl. the
wave-0 boundary gate**, SPEC) → build affected package → contract verification →
Codex review → findings fixed → CI green → merge. `main` always buildable
(ADR §21.8); small PRs; dependent PRs declare their dependency; recommended
merge order Foundation → Contracts → Data/Core → Features → Agent → UI
refinement → QA. Wave 7 adds the E2E device suite (OQ-08).

## 4. Observability & duty (AD-16d)

Sentry (errors + perf SLOs: ≤300 Ko JS gz, ≤1.5 s TTI, 30 fps — 02 §9.1/§9.4)
+ PostHog (product analytics, per-module events). Failed jobs = `job_logs` +
Sentry + per-kind SLO alerts; **Foundation is the duty owner** until a module
owns measurable traffic (AD-16d, 01 §7 observability test: alerts point to
Foundation).

## 5. Release

Phase 1 release = **mobile production-ready** (ADR §24: One-Day Build target is
the mobile version; no Electron in build/QA/release of the day). Phase 1.1 =
stabilization (real-device tests, security, observability, sync, UX fixes);
Phase 1.2 = production measurement (ADR §26.9). Desktop = Phase 2, after
stabilization.
