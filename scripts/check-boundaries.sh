#!/bin/sh
# check-boundaries.sh — 4 boundary greps (SPEC "gate de boundaries", AD-16c)
#
# Usage:
#   sh scripts/check-boundaries.sh [G1|G2|G3|G4|all]
#     G1 = vendor names hors des 5 adapters        (AD-1)
#     G2 = secrets en clair dans le code            (AD-3)
#     G3 = user hardcode (ex "Horeb")               (règle produit)
#     G4 = DOM access dans packages/agent            (AD-12/F-09)
#     all = G1+G2+G3+G4 (defaut)
#
# Exit: 0 clean, 1 echec (avec la ligne violante). Idempotent (lecture seule).
# Scope: git-tracked files uniquement (pas .env.local, ni node_modules,
# ni docs/, ni prompts/, ni set-secrets.ps1, ni .github/workflows — qui
# contient le mot "concurrency" et les noms de secrets, jamais de valeur).

set -u

# Resoudre la racine du repo: usage standard = sh scripts/check-boundaries.sh
# depuis la racine du repo. Si PWD contient deja les scripts/, on reste;
# sinon on remonte depuis $0 (cas ou le script est copie ailleurs).
if [ -d "scripts" ] || [ -d "packages" ] || [ -d "supabase" ]; then
  REPO_ROOT="$(pwd)"
else
  REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fi
cd "$REPO_ROOT" || { echo "[check-boundaries] echec: cd \$REPO_ROOT." >&2; exit 1; }

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[check-boundaries] echec: pas dans un repo git — git init d'abord." >&2
  exit 1
fi

# Fichiers source (code) a scanner — git tracked, extensions code.
code_files() {
  git ls-files \
    | grep -E '\.(ts|tsx|js|jsx|mjs|cjs|json|sql)$' \
    | grep -v '^\.env\.local' \
    || true
}

# ---------------------------------------------------------------------------
# G1 — Vendor names hors des 5 adapters
# Refs: SPEC wave 0 (gate de boundaries, AD-1/AD-3), dependency-matrix S10
#      ("Learning imports supabase table directly" = anti-pattern).
# Les SDK de fournisseur vivent que dans:
#   packages/data, packages/platform, packages/integrations,
#   packages/scientific-engine, apps/server
# Les patterns sont specifiques au vendor (pas de mot nu "Agnes" qui
# matcherait des mentions de docs) pour eviter les faux positifs.
# ---------------------------------------------------------------------------
g1() {
  echo "[G1] vendor names hors des 5 adapters (AD-1)..."
  # Pattern d'IMPORT (from 'x' / require('x')), pas de mention textuelle :
  # les configs (eslint.config.js) et schemas (powersync/schema.json) qui
  # nomment des vendors ne sont PAS des imports de code (la regle ESLint
  # no-restricted-imports porte le verrou, ce grep est la 2e couche).
  local vendor_re="from '@(cloudflare|supabase|onesignal|powersync|groq|cerebras|openrouter|composio)/|require(['\''\x60]@(cloudflare|supabase|onesignal|powersync|groq|cerebras|openrouter|composio)/|from ['\''\x60]@(cloudflare|supabase|onesignal|powersync|groq|cerebras|openrouter|composio)/"
  local hits=""
  for f in $(code_files); do
    case "$f" in
      packages/data/*|packages/platform/*|packages/integrations/*|packages/scientific-engine/*|apps/server/*)
        continue ;;
    esac
    # Fichier pas encore dans git (workspace pas cree) = rien a scanner.
    [ -f "$f" ] || continue
    if grep -nE "$vendor_re" "$f" >/dev/null 2>&1; then
      hits="$hits
$f: $(grep -nE "$vendor_re" "$f" | head -5)"
    fi
  done
  if [ -n "$hits" ]; then
    echo "[G1] FAIL — vendor references hors adapters:"
    echo "$hits"
    return 1
  fi
  echo "[G1] OK — aucun vendor hors des 5 adapters."
  return 0
}

# ---------------------------------------------------------------------------
# G2 — Secrets en clair
# Refs: secrets-checklist.md (valeurs = jamais en clair), AD-3.
# Exclure: .env.local (git-ignored), docs/, prompts/, set-secrets.ps1
# (noms de vars OK, valeurs NON), .github/workflows (ne porte que les
# noms de secrets, pas les valeurs).
# Exception sanctionnee (SPEC wave 0, 04-mobile S7.2e): OneSignal appKey
# dans capacitor.config.ts uniquement.
# ---------------------------------------------------------------------------
g2() {
  echo "[G2] secrets en clair dans le code (AD-3)..."
  # Prefixes de valeurs (jamais de nom de var, que des prefixes de valeur):
  #   sk-   (OpenAI/Agnes/OpenRouter keys),
  #   gsk_  (Groq keys),
  #   cfut_ (Cloudflare user tokens),
  #   Bearer <value>,
  #   <KEY_NAME>=<value> dans du code (pas dans .env ou .ps1).
  local secret_re='(^|[^A-Za-z0-9_])(sk-[A-Za-z0-9]{8,}|gsk_[A-Za-z0-9_-]{8,}|cfut_[A-Za-z0-9_-]{8,})|Bearer[[:space:]]+[A-Za-z0-9._-]{8,}|(^|[^A-Za-z0-9_])(API_KEY|SERVICE_ROLE_KEY|SUPABASE_DB_URL|POWERSYNC_SECRET|ONESIGNAL_REST_API_KEY|Sentry_DSN|SENTRY_DSN|POSTHOG_API_KEY)=.{8,}'
  local hits=""
  for f in $(code_files); do
    case "$f" in
      *.env.local*|docs/*|prompts/*|set-secrets.ps1|.github/*)
        continue ;;
      # Exception sanctionnee: le contenu de SKILL.md troisiemes parties (seed 0021,
      # docs Anthropic avec exemples curl/Bearer ACCESS_TOKEN, Zoom SDK, etc.)
      # n'est PAS du code Aurora, ne contient aucune valeur de secret reelle.
      supabase/migrations/*)
        continue ;;
      # Exception sanctionnee: appKey OneSignal dans capacitor.config.ts.
      */capacitor.config.ts)
        # Scanner le fichier mais ignorer les lignes "appKey" OneSignal.
        local hits_one
        hits_one=$(grep -nE "$secret_re" "$f" 2>/dev/null \
          | grep -v "appKey" || true)
        if [ -n "$hits_one" ]; then
          hits="$hits
$f: $(echo "$hits_one" | head -5)"
        fi
        ;;
      *)
        if grep -nE "$secret_re" "$f" >/dev/null 2>&1; then
          hits="$hits
$f: $(grep -nE "$secret_re" "$f" | head -5)"
        fi
        ;;
    esac
  done
  if [ -n "$hits" ]; then
    echo "[G2] FAIL — valeur de secret en clair:"
    echo "$hits"
    echo "      (exception sanctionnee: appKey OneSignal dans capacitor.config.ts uniquement)"
    return 1
  fi
  echo "[G2] OK — aucune valeur de secret en clair."
  return 0
}

# ---------------------------------------------------------------------------
# G3 — User hardcode (ex "if user === Horeb")
# Refs: dependency-matrix S11 (exemple "Horeb"), règle produit.
# Pas de hardcode d'utilisateur: l'identite passe par auth.uid() / user_id.
# ---------------------------------------------------------------------------
g3() {
  echo "[G3] user hardcode (ex 'Horeb')..."
  local user_re='[Ii]f[[:space:]]+\(?[[:space:]]*user[[:space:]]*(===?|==)?[[:space:]]*[Hh]oreb|user[[:space:]]*(===?)?[[:space:]]*["'\'']Horeb'
  local hits=""
  for f in $(code_files); do
    case "$f" in
      docs/*|prompts/*|.github/*)
        continue ;;
    esac
    [ -f "$f" ] || continue
    if grep -nE "$user_re" "$f" >/dev/null 2>&1; then
      hits="$hits
$f: $(grep -nE "$user_re" "$f" | head -5)"
    fi
  done
  if [ -n "$hits" ]; then
    echo "[G3] FAIL — user hardcode detecte:"
    echo "$hits"
    return 1
  fi
  echo "[G3] OK — aucun user hardcode."
  return 0
}

# ---------------------------------------------------------------------------
# G4 — DOM access dans packages/agent (AD-12/F-09)
# Refs: AD-12/F-09 (kernel serveur, le device ne fait que lire l'UI state),
#      dependency-matrix S10 ("Agent kernel calls ... in a loop" = N+1).
# document.querySelector est un access DOM direct — interdit dans
# packages/agent (le kernel est serveur, le device consomme AgentRunState).
# ---------------------------------------------------------------------------
g4() {
  echo "[G4] DOM access dans packages/agent (AD-12/F-09)..."
  if [ ! -d packages/agent ]; then
    echo "[G4] SKIP — packages/agent n'existe pas encore (workspace wave 0)."
    return 0
  fi
  local hits
  hits=$(grep -rn "document\.querySelector" packages/agent --include='*.ts' --include='*.tsx' 2>/dev/null || true)
  if [ -n "$hits" ]; then
    echo "[G4] FAIL — document.querySelector dans packages/agent:"
    echo "$hits"
    return 1
  fi
  echo "[G4] OK — pas de DOM access dans packages/agent."
  return 0
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
target="${1:-all}"
rc=0
case "$target" in
  G1) g1 || rc=1 ;;
  G2) g2 || rc=1 ;;
  G3) g3 || rc=1 ;;
  G4) g4 || rc=1 ;;
  all|'')
    g1 || rc=1
    g2 || rc=1
    g3 || rc=1
    g4 || rc=1
    ;;
  *)
    echo "usage: $0 [G1|G2|G3|G4|all]" >&2
    exit 2
    ;;
esac

if [ "$rc" -eq 0 ]; then
  echo "[check-boundaries] All boundary checks passed (target: $target)."
else
  echo "[check-boundaries] FAILED (target: $target)."
fi
exit "$rc"
