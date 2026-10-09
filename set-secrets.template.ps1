# =============================================================================
# Aurora — GitHub secrets template (TRACKED, value-free).
#
# The LOCAL script `set-secrets.ps1` (gitignored, NOT in this repo) holds the
# real values and runs `gh secret set` against joynagassi-cyber/aurora.
# After a fresh clone or a new collaborator, recreate set-secrets.ps1 from
# this template + the owner's key vault, then run it.
#
# SECURITY RULE (AD-3 + G2 boundary gate): no real key, token, or DSN may
# ever be committed to this repo — the CI G2 grep blocks it.
#
# Supabase SECRETS (server-side, AD-3) — these are NOT pushed to GitHub
# Secrets by this template; they live in Supabase's secret store per env:
#
#   Category  | Supabase Secret name        | GitHub Secret name (CI tests)
#   ----------|-----------------------------|--------------------------------
#   A (LLM)   | AGNES_API_KEY_1 (primary)   | AGNES_API_KEY_1
#             | AGNES_API_KEY_2 (failover)  | AGNES_API_KEY_2 (load test ONLY)
#             | GROQ_API_KEY                | GROQ_API_KEY
#             | OPENROUTER_API_KEY          | OPENROUTER_API_KEY
#   F (CF)    | CF_API_WORKERS_AI_TOKEN     | CF_API_WORKERS_AI_TOKEN
#   C (res)   | EXA_API_KEY / TAVILY_API_KEY / YOU_API_KEY | same
#   D (intg)  | COMPOSIO_API_KEY            | COMPOSIO_API_KEY
#   E (vision)| GEMINI_API_KEY / MISTRAL_API_KEY (optional, OQ-03)
#
# Agnes dual-key failover (01 §5.6 / AD-5): the router tries AGNES_API_KEY_1
# first; on a 429 / hard error it moves to AGNES_API_KEY_2 (a separate
# capacity pool) BEFORE falling through to Workers AI → Groq → OpenRouter.
# AGNES_API_KEY_2 is NOT a 429 bypass — a 429 still records a cooldown on
# the provider (AD-5 invariant).
# =============================================================================
$repo = "joynagassi-cyber/aurora"
$secrets = @(
  @("SUPABASE_URL",               "FILL_IN_FROM_KEY_VAULT"),
  @("SUPABASE_PUBLISHABLE_KEY",   "FILL_IN_FROM_KEY_VAULT"),
  @("SUPABASE_SECRET_KEY",        "FILL_IN_FROM_KEY_VAULT"),
  # LOT 1-bis / Story 1.2-bis — the internal server-to-server secret for the
  # kernel → fn-canvas channel (header `x-aurora-internal`). Server-only
  # (AD-3: NEVER on the device, never in the app bundle). Set alongside
  # SERVICE_ROLE_KEY in Supabase's Edge Function secret store; absent or
  # wrong → fn-canvas fails closed with 401 on the internal path (the
  # device-JWT path is unaffected, unchanged).
  @("INTERNAL_FN_SECRET",         "FILL_IN_FROM_KEY_VAULT"),
  @("POWERSYNC_URL",              "FILL_IN_FROM_KEY_VAULT"),
  @("PS_ADMIN_TOKEN",            "FILL_IN_FROM_KEY_VAULT"),
  @("CF_ACCOUNT_ID",             "FILL_IN_FROM_KEY_VAULT"),
  @("CF_API_TOKEN",             "FILL_IN_FROM_KEY_VAULT"),
  @("CF_API_WORKERS_AI_TOKEN",  "FILL_IN_FROM_KEY_VAULT"),
  @("AGNES_API_KEY_1",          "FILL_IN_FROM_KEY_VAULT"),
  @("AGNES_API_KEY_2",          "FILL_IN_FROM_KEY_VAULT"),
  @("AGNES_GATEWAY_TOKEN",      "FILL_IN_FROM_KEY_VAULT"),
  @("GROQ_API_KEY",             "FILL_IN_FROM_KEY_VAULT"),
  @("OPENROUTER_API_KEY",       "FILL_IN_FROM_KEY_VAULT"),
  @("EXA_API_KEY",              "FILL_IN_FROM_KEY_VAULT"),
  @("TAVILY_API_KEY",           "FILL_IN_FROM_KEY_VAULT"),
  @("YOU_API_KEY",              "FILL_IN_FROM_KEY_VAULT"),
  @("COMPOSIO_API_KEY",         "FILL_IN_FROM_KEY_VAULT"),
  @("ONESIGNAL_APP_ID",         "FILL_IN_FROM_KEY_VAULT"),
  @("ONESIGNAL_REST_API_KEY",   "FILL_IN_FROM_KEY_VAULT"),
  @("SENTRY_DSN",               "FILL_IN_FROM_KEY_VAULT"),
  @("SENTRY_AUTH_TOKEN",        "FILL_IN_FROM_KEY_VAULT"),
  @("POSTHOG_API_KEY",          "FILL_IN_FROM_KEY_VAULT"),
  @("POSTHOG_HOST",            "https://eu.i.posthog.com"),
  @("POSTHOG_PROJECT_ID",       "FILL_IN_FROM_KEY_VAULT")
)
foreach ($s in $secrets) {
  $name = $s[0]; $val = $s[1]
  if ($val -eq "FILL_IN_FROM_KEY_VAULT") {
    Write-Warning "MISSING value for $name — fill from the local key vault first"
    continue
  }
  gh secret set $name --body $val --repo $repo 2>&1 | Out-Null
  Write-Host "SET: $name"
}
