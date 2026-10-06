# Supabase Edge Functions — secrets manuels
#
# EXCÉCUTION MANUELLE — le compte `cli_joyda@NAGASSI` a un 403 sur
# l'endpoint secrets de la Management API (docs "Access Control").
# Deux options pour contourner :
#
# OPTION A — Dashboard (recommandé, le seul fiable)
#   1. https://supabase.com/dashboard/project/opagfyspdbhxthlxvlrk
#   2. Edge Functions → Secrets → "Edit secrets"
#   3. Coller la KEY + la VALUE ci-dessous (voir valeur dans .env.local,
#      ne la commiter JAMAIS ici)
#   4. Save
#
# OPTION B — CLI (si le compte a le scope)
#   1. supabase secrets list                       # doit renvoyer 200
#   2. supabase secrets set \
#        SUPABASE_SECRET_KEY="<le secret>"
#
# Ce que ce script contient :
#   - La LISTE des keys à set dans les project secrets de l'instance
#     Aurora (opagfyspdbhxthlxvlrk)
#   - La source exacte de chaque valeur (toujours .env.local / GitHub Actions,
#     jamais en clair dans ce fichier)
#
# Après set, relauncher la fonction target pour vérifier :
#   supabase functions logs fn-agent-run

# === Keys à set (sources en commentaire, valeurs à copier depuis .env.local) ===
#
# ⚠ RENOMMÉ (2026-10-06, wave canvas/agent) : l'EF lit `SERVICE_ROLE_KEY`,
# plus `SUPABASE_SECRET_KEY` — Supabase REFUSE tout nom de secret projet
# commençant par le prefix `SUPABASE_` (réservé au runtime). À set côté
# Dashboard > Edge Functions > Secrets (ou `supabase secrets set` si le
# compte y a le scope) :
#
#   SERVICE_ROLE_KEY       ← valeur = le service_role secret (celui qu'on
#                            trouvait sous `SUPABASE_SECRET_KEY` dans
#                            .env.local / GitHub secrets, 41 chars
#                            `sb_secret_...`). Un seul secret, plus de
#                            doublon : tous les EF (fn-agent-run,
#                            fn-import-course, fn-integrations,
#                            fn-job-dispatcher, fn-skills, fn-fsrs-tick)
#                            + le shared `fn-agent-bootstrap.ts` lisent
#                            `SERVICE_ROLE_KEY` dans `Deno.env`.
#
#   SUPABASE_JWKS_URL      ← .env.local (présente)
#                            → utilisé par : fn-skills, fn-integrations (validation JWT publishable)
#
# .env.local (lecture locale, pas déployé) : on y garde la valeur du
# service_role sous `SERVICE_ROLE_KEY` (la valeur sous
# `SUPABASE_SECRET_KEY` n'y est plus consommée par les EF ni les
# scripts — scripts/skills-seed.ts / skills-qa.ts /
# supabase/migrations/0021_lots/*.mjs ont basculé sur l'alias
# `SERVICE_ROLE_KEY`). Ne pas commiter .env.local.
#
#   (Les keys AGNES / GROQ / OPENROUTER / EXA / TAVILY / YOU / COMPOSIO /
#    ONESIGNAL / SENTRY / POSTHOG / POWERSYNC / CF_API_* sont pour les
#    providers tiers — les EF qui les consomment n'ont pas encore été
#    déployées sur le live Aurora. On les met en place au moment où
#    les EF correspondantes sont relancées.)

# === Vérification post-set (2026-10-06) ===
# 1. `supabase functions list` ou Dashboard Edge Functions → l'EF cible
#    (ex. fn-agent-run) doit afficher `SERVICE_ROLE_KEY` dans ses secrets.
# 2. Redeploy / relaunch de l'EF (Dashboard ou `supabase functions deploy
#    fn-agent-run --no-verify-jwt` ou équivalent selon le compte), sinon
#    le runtime conserve l'ancienne liste de secrets.
# 3. Smoke test (valeurs locales depuis .env.local, ne pas commiter) :
#    - un POST verb list_catalog vers fn-skills (EF live) ne doit plus
#      renvoyer `{degraded:true}` ni 503 "SUPABASE env not configured".
#    - `node scripts/skills-qa.ts` (ou le script équivalent du module
#      concerné) doit passer sans le fallback [5b] "service key".
# 4. `supabase functions logs fn-agent-run` : aucun warn
#    "SERVICE_ROLE_KEY not configured" après un vrai run d'agent.
#
# La liste des secrets GitHub Actions (set-secrets.ps1 / .env.example,
# catégorie A/F/C/D/E) n'est PAS modifiée par ce renommage : le
# service_role reste `SUPABASE_SECRET_KEY` côté CI (grep secret,
# check-boundaries.sh le cite tel quel) et côté .env.local historique ;
# seul le secret PROJECT Supabase consommé par les EF est
# `SERVICE_ROLE_KEY`.
