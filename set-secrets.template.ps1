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
# =============================================================================
$repo = "joynagassi-cyber/aurora"
$secrets = @(
  @("SUPABASE_URL",               "FILL_IN_FROM_KEY_VAULT"),
  @("SUPABASE_PUBLISHABLE_KEY",   "FILL_IN_FROM_KEY_VAULT"),
  @("SUPABASE_SECRET_KEY",        "FILL_IN_FROM_KEY_VAULT"),
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
