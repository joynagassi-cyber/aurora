# Aurora — Complete Secrets & Environment Checklist (2026-09-22)

**What YOU (Joy) must configure BEFORE launching the agents.**
Each item = what to create, where to put it, who reads it.

---

## 1. Supabase (3 projects: dev / staging / prod)

Create at: https://supabase.com/dashboard

| Item | Where | Who reads it | Notes |
|---|---|---|---|
| Supabase project URL (dev) | `.env.dev` + GitHub Secret `SUPABASE_URL_DEV` | Mobile app, server | `https://{ref}.supabase.co` |
| Supabase project URL (staging) | `.env.staging` + GitHub Secret `SUPABASE_URL_STAGING` | Mobile app, server | |
| Supabase project URL (prod) | `.env.prod` + GitHub Secret `SUPABASE_URL_PROD` | Mobile app, server | |
| Supabase anon key (dev) | `.env.dev` + GitHub Secret `SUPABASE_ANON_KEY_DEV` | Mobile app (public, RLS-protected) | Safe in bundle |
| Supabase anon key (staging) | `.env.staging` + GitHub Secret `SUPABASE_ANON_KEY_STAGING` | Mobile app | Safe in bundle |
| Supabase anon key (prod) | `.env.prod` + GitHub Secret `SUPABASE_ANON_KEY_PROD` | Mobile app | Safe in bundle |
| Supabase service_role key (dev) | GitHub Secret `SUPABASE_SERVICE_ROLE_DEV` | Server Edge Functions ONLY | **NEVER in mobile bundle (AD-3)** |
| Supabase service_role key (staging) | GitHub Secret `SUPABASE_SERVICE_ROLE_STAGING` | Server | NEVER in bundle |
| Supabase service_role key (prod) | GitHub Secret `SUPABASE_SERVICE_ROLE_PROD` | Server | NEVER in bundle |
| Supabase DB URL (dev) | GitHub Secret `SUPABASE_DB_URL_DEV` | Migrations, PowerSync relay | `postgresql://{user}:{pass}@db.{ref}.supabase.co:5432/postgres` |
| Supabase DB URL (staging) | GitHub Secret `SUPABASE_DB_URL_STAGING` | Migrations | |
| Supabase DB URL (prod) | GitHub Secret `SUPABASE_DB_URL_PROD` | Migrations | |
| Supabase secret: `agnes_api_key` | Supabase Secrets (dev/staging/prod) | `fn-agent-run`, AI pipeline | Agnes API key, server-side only |
| Supabase secret: `groq_api_key` | Supabase Secrets | AI pipeline (fallback) | Optional |
| Supabase secret: `cerebras_api_key` | Supabase Secrets | AI pipeline (fallback) | Optional |
| Supabase secret: `exa_api_key` | Supabase Secrets | ResearchProvider (Exa) | Discovery |
| Supabase secret: `tavily_api_key` | Supabase Secrets | ResearchProvider (Tavily) | Discovery |
| Supabase secret: `youcom_api_key` | Supabase Secrets | ResearchProvider (You.com) | Discovery |
| Supabase secret: `composio_api_key` | Supabase Secrets | IntegrationProvider | Composio |
| Supabase secret: `onesignal_app_id` | Supabase Secrets | `fn-notifications` | OneSignal app ID |
| Supabase secret: `onesignal_rest_api_key` | Supabase Secrets | `fn-notifications` | OneSignal REST key (server) |
| Supabase secret: `r2_account_id` | Supabase Secrets | R2 presigned URL gen | Cloudflare R2 |
| Supabase secret: `r2_api_token` | Supabase Secrets | R2 presigned URL gen | Cloudflare API token (R2 scope) |
| Supabase secret: `sentry_dsn_dev` | Supabase Secrets | Error reporting | Sentry |
| Supabase secret: `sentry_dsn_staging` | Supabase Secrets | Error reporting | Sentry |
| Supabase secret: `sentry_dsn_prod` | Supabase Secrets | Error reporting | Sentry |
| Supabase secret: `posthog_api_key_dev` | Supabase Secrets | Analytics | PostHog |
| Supabase secret: `posthog_api_key_staging` | Supabase Secrets | Analytics | PostHog |
| Supabase secret: `posthog_api_key_prod` | Supabase Secrets | Analytics | PostHog |
| Supabase secret: `fal_ai_api_key` | Supabase Secrets | Image fallback (Flux Schnell) | Optional |
| Supabase secret: `powersync_secret` | Supabase Secrets | PowerSync relay auth | PowerSync |

---

## 2. PowerSync (local-first sync)

Create at: https://powersync.com

| Item | Where | Who reads it | Notes |
|---|---|---|---|
| PowerSync secret (relay) | Supabase Secret `powersync_secret` + GitHub Secret `POWERSYNC_SECRET` | PowerSync relay + mobile app | The shared secret between relay and client |
| PowerSync relay URL (dev) | `.env.dev` + GitHub Secret `POWERSYNC_URL_DEV` | Mobile app | `wss://{ref}.powersync.dev` |
| PowerSync relay URL (staging) | `.env.staging` | Mobile app | |
| PowerSync relay URL (prod) | `.env.prod` | Mobile app | |
| PowerSync DB URL | Supabase (DB access) | PowerSync relay | Connects to Supabase Postgres |

**PowerSync relay setup (in Supabase Edge Function or separate worker):**
- Watches `events` table (AD-9)
- Watches all module tables for the PowerSync sync scope (03 S4.2)
- Pushes changes to connected devices via WebSocket

---

## 3. Cloudflare (R2 + AI Gateway + Workers)

Create at: https://dash.cloudflare.com

| Item | Where | Who reads it | Notes |
|---|---|---|---|
| Cloudflare Account ID | GitHub Secret `CF_ACCOUNT_ID` + Supabase Secret `r2_account_id` | R2, Gateway, Workers | |
| Cloudflare API Token (R2 scope) | GitHub Secret `CF_API_TOKEN` + Supabase Secret `r2_api_token` | R2 presigned URL generation | R2 scope only (not account admin) |
| R2 bucket: `aurora-artifacts-dev` | Cloudflare R2 (create) | `artifact_gen` jobs, R2 presigned | Private bucket |
| R2 bucket: `aurora-artifacts-staging` | Cloudflare R2 (create) | Staging artifacts | Private |
| R2 bucket: `aurora-artifacts-prod` | Cloudflare R2 (create) | Prod artifacts | Private |
| R2 bucket: `aurora-media-dev` | Cloudflare R2 (create) | Image cache (WebP, infographics) | Private |
| R2 bucket: `aurora-media-staging` | Cloudflare R2 (create) | | Private |
| R2 bucket: `aurora-media-prod` | Cloudflare R2 (create) | | Private |
| Cloudflare AI Gateway (create) | Cloudflare Dashboard -> AI Gateway | AI pipeline routing | Free on all plans |
| CF Gateway: provider routing | CF Gateway config | Agnes, Workers AI, Groq, Cerebras, OpenRouter, Cohere, Mistral, Gemini | Dynamic Routing (S3) |
| CF Gateway: rate limiting | CF Gateway config | Per-provider rate limits | 429 handling |
| CF Gateway: budget | CF Gateway config | Daily/monthly token budget | AIBudgetManager |
| CF Gateway: caching | CF Gateway config | Response cache (optional) | |
| Cloudflare Worker: fallback | CF Workers (create) | Last-resort AI (direct Workers AI) | AD-4, v1.7 S4 |
| CF Worker: secrets | CF Workers Dashboard | `AGNES_API_KEY`, `WORKERS_AI_TOKEN` | Server-side |

---

## 4. Agnes AI (PRIMARY provider)

Create at: https://agnes-ai.com

| Item | Where | Who reads it | Notes |
|---|---|---|---|
| Agnes API key | Supabase Secret `agnes_api_key` (dev/staging/prod) | `fn-agent-run`, AI pipeline | **Server-side ONLY (AD-3)** |
| Agnes API key (GitHub) | GitHub Secret `AGNES_API_KEY` (optional, for local dev) | Local development | NOT in CI (use Supabase secrets in CI) |
| Agnes model IDs | No key needed (public catalog) | Model Registry | `agnes-3.0-flash`, `agnes-2.5-flash`, `agnes-image-2.5-flash` |

**Agnes is ALWAYS primary (S2.6). No rotation, no round-robin.**

---

## 5. Groq (optional fallback)

Create at: https://console.groq.com

| Item | Where | Who reads it | Notes |
|---|---|---|---|
| Groq API key | Supabase Secret `groq_api_key` | AI pipeline fallback | Optional (only if you want Groq fallback) |
| Groq Free Plan limits | No key needed (account-based) | Model Registry | 30 RPM, 1000 RPD (GPT-OSS) |

---

## 6. Cerebras (optional fallback)

Create at: https://inference.cerebras.ai

| Item | Where | Who reads it | Notes |
|---|---|---|---|
| Cerebras API key | Supabase Secret `cerebras_api_key` | AI pipeline fallback | Optional |
| Cerebras Free Trial limits | Account-based | Model Registry | 5 RPM, 30K TPM |

---

## 7. Research Providers (Discovery Engine)

| Provider | Where to create | Secret location | Notes |
|---|---|---|---|
| **Exa** | https://exa.ai | Supabase Secret `exa_api_key` | ResearchProvider (primary) |
| **Tavily** | https://tavily.com | Supabase Secret `tavily_api_key` | ResearchProvider (secondary) |
| **You.com** | https://you.com | Supabase Secret `youcom_api_key` | ResearchProvider (tertiary) |

**All 3 are optional (AD-1: if absent, Discovery degrades to `uncertain`).**

---

## 8. Composio (Integrations)

Create at: https://composio.dev

| Item | Where | Who reads it | Notes |
|---|---|---|---|
| Composio API key | Supabase Secret `composio_api_key` | `IntegrationProvider` adapter | Server-side only |
| Composio connected accounts | Composio dashboard (per-user) | Per-user OAuth/API keys | User connects via in-app flow |

---

## 9. OneSignal (Notifications)

Create at: https://onesignal.com

| Item | Where | Who reads it | Notes |
|---|---|---|---|
| OneSignal App ID | `capacitor.config.ts` (appKey, allowed in bundle, 04 S3.2.5) + Supabase Secret `onesignal_app_id` | Mobile app (appKey) + server (app ID) | App key is OK in bundle (not a secret) |
| OneSignal REST API Key | Supabase Secret `onesignal_rest_api_key` | `fn-notifications` (server) | **NEVER in mobile bundle (AD-3)** |

---

## 10. Sentry (Error Tracking)

Create at: https://sentry.io

| Item | Where | Who reads it | Notes |
|---|---|---|---|
| Sentry DSN (dev) | GitHub Secret `SENTRY_DSN_DEV` + Supabase Secret `sentry_dsn_dev` | Mobile + server | |
| Sentry DSN (staging) | GitHub Secret `SENTRY_DSN_STAGING` | | |
| Sentry DSN (prod) | GitHub Secret `SENTRY_DSN_PROD` | | |
| Sentry auth token | GitHub Secret `SENTRY_AUTH_TOKEN` | CI (source map upload) | |

---

## 11. PostHog (Analytics)

Create at: https://posthog.com

| Item | Where | Who reads it | Notes |
|---|---|---|---|
| PostHog API key (dev) | GitHub Secret `POSTHOG_KEY_DEV` + Supabase Secret `posthog_api_key_dev` | Server events | No personal data in events |
| PostHog API key (staging) | GitHub Secret `POSTHOG_KEY_STAGING` | | |
| PostHog API key (prod) | GitHub Secret `POSTHOG_KEY_PROD` | | |
| PostHog project ID | `.env` (public, per-env) | Mobile app | Not a secret |

---

## 12. fal.ai (Image Generation Fallback, optional)

Create at: https://fal.ai

| Item | Where | Who reads it | Notes |
|---|---|---|---|
| fal.ai API key | Supabase Secret `fal_ai_api_key` | Image generation fallback (Flux Schnell) | 0.003 USD/MP |
| fal.ai API key (GitHub, local dev) | GitHub Secret `FAL_KEY` | Local development | Optional |

---

## 13. GitHub (CI/CD)

Create at: https://github.com/settings -> your repo -> Secrets

### GitHub Secrets (repo-level, for Actions)

| Secret | Value | Used by |
|---|---|---|
| `SUPABASE_URL_DEV` | Supabase dev project URL | CI: build, test |
| `SUPABASE_URL_STAGING` | Supabase staging URL | CI: deploy staging |
| `SUPABASE_URL_PROD` | Supabase prod URL | CI: deploy prod |
| `SUPABASE_ANON_KEY_DEV` | Supabase dev anon key | CI: integration tests |
| `SUPABASE_ANON_KEY_STAGING` | | |
| `SUPABASE_ANON_KEY_PROD` | | |
| `SUPABASE_SERVICE_ROLE_DEV` | Supabase dev service role | CI: RLS tests, migrations |
| `SUPABASE_SERVICE_ROLE_STAGING` | | |
| `SUPABASE_SERVICE_ROLE_PROD` | | |
| `SUPABASE_DB_URL_DEV` | Supabase dev DB URL | CI: migrations, PowerSync |
| `SUPABASE_DB_URL_STAGING` | | |
| `SUPABASE_DB_URL_PROD` | | |
| `POWERSYNC_SECRET` | PowerSync shared secret | CI: relay config |
| `POWERSYNC_URL_DEV` | PowerSync relay URL | CI: mobile build |
| `POWERSYNC_URL_STAGING` | | |
| `POWERSYNC_URL_PROD` | | |
| `CF_ACCOUNT_ID` | Cloudflare account ID | CI: R2, Gateway |
| `CF_API_TOKEN` | Cloudflare API token (R2 scope) | CI: R2 presigned, deploy |
| `AGNES_API_KEY` | Agnes API key | CI: integration tests (optional) |
| `GROQ_API_KEY` | Groq key | CI: fallback tests (optional) |
| `CEREBRAS_API_KEY` | Cerebras key | CI: fallback tests (optional) |
| `EXA_API_KEY` | Exa key | CI: Discovery tests |
| `TAVILY_API_KEY` | Tavily key | CI: Discovery tests |
| `YOUcom_API_KEY` | You.com key | CI: Discovery tests |
| `COMPOSIO_API_KEY` | Composio key | CI: Integration tests |
| `ONESIGNAL_APP_ID` | OneSignal app ID | CI: notification tests |
| `ONESIGNAL_REST_KEY` | OneSignal REST key | CI: notification tests |
| `SENTRY_DSN_DEV` | Sentry DSN dev | CI: error reporting |
| `SENTRY_DSN_STAGING` | | |
| `SENTRY_DSN_PROD` | | |
| `SENTRY_AUTH_TOKEN` | Sentry auth token | CI: source map upload |
| `POSTHOG_KEY_DEV` | PostHog key dev | CI: analytics |
| `POSTHOG_KEY_STAGING` | | |
| `POSTHOG_KEY_PROD` | | |
| `FAL_KEY` | fal.ai key | CI: image gen tests (optional) |

### GitHub Variables (repo-level, NOT secrets, for public config)

| Variable | Value | Notes |
|---|---|---|
| `POSTHOG_PROJECT_ID_DEV` | PostHog project ID dev | Not a secret |
| `POSTHOG_PROJECT_ID_STAGING` | | |
| `POSTHOG_PROJECT_ID_PROD` | | |
| `GITHUB_ACTIONS_NODE_VERSION` | `22` | CI node version |

### GitHub Branch Protection

| Rule | Setting |
|---|---|
| `main` | Require PR + Codex review + CI pass |
| `develop` | Require PR + CI pass |
| `wave-N-*` | No protection (agent branches) |
| Required reviews | 1 (Codex) |
| Status checks required | `build`, `lint`, `type-check`, `grep-secrets`, `grep-vendors` |

---

## 14. Local .env files (per developer, git-ignored)

### `.env.local` (git-ignored, each developer creates)

```env
# Supabase
SUPABASE_URL=https://{dev_ref}.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...  (for local server testing ONLY)
SUPABASE_DB_URL=postgresql://postgres:{pass}@db.{dev_ref}.supabase.co:5432/postgres

# PowerSync
POWERSYNC_SECRET=...
POWERSYNC_URL=wss://{dev_ref}.powersync.dev

# Cloudflare
CF_ACCOUNT_ID=...
CF_API_TOKEN=...
R2_BUCKET=aurora-artifacts-dev

# Agnes (local dev only, server-side)
AGNES_API_KEY=...

# Optional providers
GROQ_API_KEY=...
CEREBRAS_API_KEY=...
EXA_API_KEY=...
TAVILY_API_KEY=...
YOUcom_API_KEY=...
COMPOSIO_API_KEY=...
FAL_KEY=...

# OneSignal
ONESIGNAL_APP_ID=...
ONESIGNAL_REST_KEY=...

# Sentry
SENTRY_DSN=...

# PostHog
POSTHOG_KEY=...
POSTHOG_PROJECT_ID=...

# Capacitor
CAPACITOR_APP_ID=com.aurora
```

### `.env.local.example` (committed, template for developers)

```env
# Supabase
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
SUPABASE_DB_URL=

# PowerSync
POWERSYNC_SECRET=
POWERSYNC_URL=

# Cloudflare
CF_ACCOUNT_ID=
CF_API_TOKEN=
R2_BUCKET=

# Agnes (server-side)
AGNES_API_KEY=

# OneSignal
ONESIGNAL_APP_ID=
ONESIGNAL_REST_KEY=

# Sentry
SENTRY_DSN=
```

---

## 15. capacitor.config.ts (mobile app config, committed)

```ts
// apps/mobile/capacitor.config.ts
const config: CapacitorConfig = {
  appId: "com.aurora",
  appName: "Aurora",
  webDir: "www",
  server: { androidScheme: "https" },
  plugins: {
    OneSignal: {
      appId: process.env.CAPACITOR_ONESIGNAL_APP_ID ?? "",
      // appKey is NOT a secret (04 S3.2.5, allowed in bundle)
      // server key is NEVER here (AD-3)
    },
  },
};
```

**Rule: OneSignal appKey = OK in bundle (04 S3.2.5).
Server key = NEVER in bundle (04 S7.2e test).**

---

## 16. Summary: What You Create (Joy)

### Step 1: Accounts (create, get keys)

| # | Service | What to create | Keys to get |
|---|---|---|---|
| 1 | Supabase | 3 projects (dev/staging/prod) | URLs, anon keys, service role keys, DB URLs |
| 2 | PowerSync | 1 relay config | Secret, relay URL |
| 3 | Cloudflare | R2 (6 buckets) + AI Gateway + Worker | Account ID, API token |
| 4 | Agnes | 1 API key | API key |
| 5 | Groq (optional) | 1 API key | API key |
| 6 | Cerebras (optional) | 1 API key | API key |
| 7 | Exa | 1 API key | API key |
| 8 | Tavily | 1 API key | API key |
| 9 | You.com | 1 API key | API key |
| 10 | Composio | 1 API key | API key |
| 11 | OneSignal | 1 app (dev) | App ID + REST key |
| 12 | Sentry | 3 projects (dev/staging/prod) | 3 DSNs + auth token |
| 13 | PostHog | 3 projects (dev/staging/prod) | 3 API keys |
| 14 | fal.ai (optional) | 1 API key | API key |
| 15 | GitHub | 1 repo + Actions | All secrets (table S13) |

### Step 2: Put the keys in the right place

```
GitHub Secrets (repo)     -> CI/CD (Actions)
Supabase Secrets (per env)-> Server Edge Functions
Local .env.local          -> Your dev machine (git-ignored)
capacitor.config.ts       -> Committed (appKey only, no server secrets)
```

### Step 3: Verify

```
1. Supabase: RLS enabled on all tables, anon key works for auth
2. PowerSync: relay connects to Supabase, syncs 1 test row
3. R2: presigned URL generates + uploads + downloads
4. Agnes: 1 test call (Agnes 3.0 Flash) returns a response
5. OneSignal: 1 test push notification on a device
6. Sentry: 1 test error report appears
7. PostHog: 1 test event appears
8. GitHub Actions: 1 test pipeline runs (build + lint + grep)
```

### Step 4: Launch the agents

```
ACHILLES + HERMES + MINERVA  (wave 0)
  -> 2 weeks
APOLLO + ATHENA + PROMETHEUS (wave 1)
  -> 3 weeks
ATLAS + SAPPHO + ORION + VECTOR + ECHIDNA + HYPATIYAS (wave 2)
  -> 4 weeks
ORACLE + HEPHAESTUS (wave 3)
  -> 2-3 weeks
HARPYS + ERYNIS (wave 4-7)
  -> 4 weeks
DAPHNE (parallel, all waves)
CODEX / me (review, all waves)
```

**Total: ~16 weeks to release candidate.**
