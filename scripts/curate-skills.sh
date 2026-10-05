#!/bin/bash
# scripts/curate-skills.sh
# Construit anthropic-skills/ (curé, git-tracked) à partir de third-party/anthropic/ (bruts, gitignored).
# Conserve seulement SKILL.md (+ references/*.md/yaml/yml). Récrit en style simple, rapide.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW="$REPO_ROOT/third-party/anthropic"
CUR="$REPO_ROOT/anthropic-skills"

echo "Curation : $RAW -> $CUR"
rm -rf "$CUR"
mkdir -p "$CUR"

TOTAL=0
# Parcourt chaque SKILL.md une seule fois (pas de boucle par repo imbriquée)
while IFS= read -r skill_md; do
  # Repo = 3e composant du chemin relatif à RAW
  rel="${skill_md#"$RAW"/}"
  repo="${rel%%/*}"
  [ "$repo" = "claude-cookbooks" ] && continue   # pas de SKILL.md locaux
  # skill_dir = chemin relatif de SKILL.md, moins son nom
  skill_dir="$(dirname "$rel")"

  dest_dir="$CUR/$repo/$skill_dir"
  mkdir -p "$dest_dir"
  cp "$skill_md" "$dest_dir/SKILL.md"

  ref_src="$(dirname "$skill_md")/references"
  if [ -d "$ref_src" ]; then
    mkdir -p "$dest_dir/references"
    find "$ref_src" \( -name "*.md" -o -name "*.yaml" -o -name "*.yml" \) -exec cp {} "$dest_dir/references/" \; 2>/dev/null
  fi
  TOTAL=$((TOTAL + 1))
done < <(find "$RAW" -name "SKILL.md" -not -path "*/.git/*" 2>/dev/null)

echo "Curés : $TOTAL"
echo "Par dépôt :"
for d in "$CUR"/*/; do
  [ -d "$d" ] || continue
  printf "  %4d  %s\n" "$(find "$d" -name SKILL.md | wc -l)" "$(basename "$d")"
done
echo "Taille : $(du -sh "$CUR" | cut -f1)"
