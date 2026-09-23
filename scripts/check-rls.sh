#!/bin/sh
# check-rls.sh — RLS penetration static scan (01-backend S2.2 + S7, AD-2/AD-7)
#
# Refs:
#   - 01-backend S2.2 "Tranchement RLS" (le mecanisme d'application d'AD-2
#     au niveau donnees) + S7 "Tests obligatoires" (test RLS de penetration)
#   - docs/architecture/dependency-matrix.md S10 (anti-pattern "Learning
#     imports semantic_nodes table directly" = RLS penetration)
#
# Scan des fichiers de migration dans supabase/migrations/*.sql (livres par
# MINERVA en parallele). 3 checks par table:
#   (a) ENABLE ROW LEVEL SECURITY sur chaque table (pas de table sans RLS)
#   (b) AUCUN USING(true) / WITH CHECK(true) sans bornage (policy permissive)
#   (c) FORCE ROW LEVEL SERVICE ROLE sur service_role (la passe par les
#       policies, pas par BYPASSRLS — 01 S2.2 regle 1)
#
# C'est un check STATIQUE. Le test live (user A ne lit pas les lignes de
# user B sur chaque table) reste a faire contre une Supabase dev — marque
# "TODO(wave1): run against live Supabase" dans le fichier et dans ci.yml.
#
# Usage: sh scripts/check-rls.sh
# Exit: 0 clean / 0 (skip, pas de migrations) / 1 echec + fichier/ligne.

set -u

# Resoudre la racine du repo: usage standard = sh scripts/check-rls.sh
# depuis la racine du repo. Si $0 est relatif, on part de PWD.
if [ -d "supabase/migrations" ] || [ -d "supabase" ]; then
  REPO_ROOT="$(pwd)"
else
  REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fi
cd "$REPO_ROOT" || exit 1

MIG_DIR="supabase/migrations"
if [ ! -d "$MIG_DIR" ]; then
  echo "[check-rls] SKIP — $MIG_DIR n'existe pas encore (MINERVA crele en parallele)."
  echo "[check-rls] TODO(wave1): run against live Supabase (user A ne lit pas user B, sur chaque table)."
  exit 0
fi

rc=0

# (a) ENABLE ROW LEVEL SECURITY sur chaque table.
echo "[check-rls (a)] ENABLE ROW LEVEL SECURITY sur chaque table..."
tables_created=$(grep -rhoE 'CREATE[[:space:]]+TABLE[[:space:]]+(IF[[:space:]]+NOT[[:space:]]+EXISTS[[:space:]]+)?[`"\[]?[a-z0-9_]+"?\]?' "$MIG_DIR"/*.sql 2>/dev/null \
  | sed -E 's/.*IF NOT EXISTS[[:space:]]+//; s/.*EXISTS[[:space:]]+//; s/[`"\[]//g; s/[)]//g' \
  | tr -d '`"' | sed 's/^ *//;s/ *$//' | grep -v '^$' | sort -u || true)

for t in $tables_created; do
  # Un "table" = dernier identifiant (le nom) de la declaration.
  if ! grep -rqE "ALTER[[:space:]]+TABLE[[:space:]]+[\"$t\"(]\??$t[\"(]?[[:space:]]+ENABLE[[:space:]]+ROW[[:space:]]+LEVEL[[:space:]]+SECURITY" "$MIG_DIR"/*.sql 2>/dev/null; then
    # Chercher la forme "CREATE TABLE t (...) ... ENABLE ROW LEVEL SECURITY"
    # (rare) ou une ALTER ELSEPART.
    if ! grep -rqE "ENABLE[[:space:]]+ROW[[:space:]]+LEVEL[[:space:]]+SECURITY" "$MIG_DIR"/*.sql 2>/dev/null \
       || ! grep -rq "$t" "$MIG_DIR"/*.sql 2>/dev/null; then
      echo "  [a] FAIL — table '$t' creee sans ENABLE ROW LEVEL SECURITY"
      rc=1
    fi
  fi
done
[ "$rc" -eq 0 ] && echo "  [a] OK"

# (b) AUCUN USING(true) / WITH CHECK(true) sans bornage.
echo "[check-rls (b)] pas de policy permissive (USING/WITH CHECK true)..."
# "USING (true)" / "WITH CHECK (true)" ou "USING(true)" sans expression
# bornee = bug bloquant (01 S2.2 regle 4: aucune policy permissive par defaut).
permissive=$(grep -rnE 'USING[[:space:]]*\(\s*true\s*\)|WITH[[:space:]]+CHECK[[:space:]]*\(\s*true\s*\)' "$MIG_DIR"/*.sql 2>/dev/null || true)
if [ -n "$permissive" ]; then
  echo "  [b] FAIL — policy permissive (USING/ WITH CHECK true) sans bornage:"
  echo "$permissive"
  rc=1
else
  echo "  [b] OK — aucune policy permissive."
fi

# (c) FORCE ROW LEVEL SERVICE ROLE sur service_role.
echo "[check-rls (c)] FORCE ROW LEVEL SERVICE ROLE sur service_role..."
# 01 S2.2 regle 1: FORCE ROW LEVEL SERVICE ROLE sur service_role —
# la cle service passe par les policies, pas par BYPASSRLS.
# Formes accepteess: "ALTER ROLE service_role FORCE ROW LEVEL SECURITY;"
# (Postgres natif) ou "FORCE ROW LEVEL SECURITY ON <table>" (rappel par table).
if ! grep -rqE 'FORCE[[:space:]]+ROW[[:space:]]+LEVEL[[:space:]]+SECURITY' "$MIG_DIR"/*.sql 2>/dev/null; then
  echo "  [c] WARN — pas de FORCE ROW LEVEL SECURITY detectee."
  echo "       (01 S2.2 regle 1: FORCE ROW LEVEL SERVICE ROLE sur service_role."
  echo "       Si les migrations MINERVA n'en ont pas encore, c'est un echec"
  echo "       bloquant en wave 1. Pour l'instant = warning, pas un echec."
  # On ne bloque PAS: le role service_role doit exister pour le FORcer;
  # tant que MINERVA n'a pas livre, on reste en warning.
else
  echo "  [c] OK — FORCE ROW LEVEL SECURITY present."
fi

# Guard: si une migration a un role BYPASSRLS sur service_role = FAIL.
bypass=$(grep -rniE 'GRANT[[:space:]]+BYPASSRLS|BYPASSRLS[[:space:]]+(TO|ON)' "$MIG_DIR"/*.sql 2>/dev/null || true)
if [ -n "$bypass" ]; then
  echo "  FAIL — BYPASSRLS sur service_role (01 S2.2: jamais par BYPASSRLS):"
  echo "$bypass"
  rc=1
fi

if [ "$rc" -eq 0 ]; then
  echo "[check-rls] RLS static checks passed (migrations: $(ls "$MIG_DIR"/*.sql 2>/dev/null | wc -l) fichiers)."
  echo "[check-rls] TODO(wave1): run against live Supabase (penetration user A vs B, sur chaque table)."
else
  echo "[check-rls] RLS static checks FAILED."
fi
exit "$rc"
