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
#   SUPABASE_SECRET_KEY    ← .env.local (41 chars)
#                            → utilisé par : fn-agent-run, fn-import-course,
#                                              fn-integrations, fn-job-dispatcher,
#                                              fn-skills, fn-fsrs-tick
#
#   SUPABASE_JWKS_URL      ← .env.local (présente)
#                            → utilisé par : fn-skills, fn-integrations (validation JWT publishable)
#
#   (Les keys AGNES / GROQ / OPENROUTER / EXA / TAVILY / YOU / COMPOSIO /
#    ONESIGNAL / SENTRY / POSTHOG / POWERSYNC / CF_API_* sont pour les
#    providers tiers — les EF qui les consomment n'ont pas encore été
#    déployées sur le live Aurora. On les met en place au moment où
#    les EF correspondantes sont relancées.)
