# anthropic-skills

Dossier curé (git-tracked, SSoT du seed 0021) des **Agent Skills officiels
d'Anthropic** — clonés depuis l'org public [`anthropics`](https://github.com/anthropics)
et copiés par `scripts/curate-skills.mjs` depuis `third-party/anthropic/*`.

## Contenu

| Repo source | Skill | Domaine Aurora |
|---|---|---|
| `claude-for-legal` | 151 skills juridiques | legal (sauf `law-student` → students) |
| `knowledge-work-plugins` | ~200 plugins coworkers | business / marketing / finance / design / research / productivity / coding / legal / students |
| `skills` (Agent Skills public) | 20 skills | documents / creative / coding / productivity / students |
| `claude-for-financial-advisors` + `financial-services` | 120 skills | finance |
| `life-sciences` | 6 skills | science |
| `healthcare` | 11 skills | healthcare |
| `commerce-agents` | 1 skill | business |
| `k12-teacher-skills` | 4 skills | students |
| `launch-your-agent` + `oncall-kit` | 6 skills | productivity |
| `claude-quickstarts` | 3 skills | coding |

**Total : 589 skills** — règle « prendre tout » (décision 2026-10-05) : même le
coding pur est inclus, aucune exclusion.

## Licence

Anthropic Agent Skills sont publiés sous **Apache 2.0** (vérifier le
`LICENSE` de chaque repo cloné avant toute redistribution à l'extérieur
d'Aurora). Les contenus restent propriété d'Anthropic ; Aurora ne fait
qu'indexer et afficher.

## Génération du seed

```bash
# 1. Cloner les 10 repos dans third-party/anthropic/ (gitignored)
# 2. Copier dans anthropic-skills/ (git-tracked)
bash scripts/curate-skills.sh

# 3. Régénérer la migration 0021_marketplace_skills.sql
pnpm tsx scripts/skills-seed.ts
# → supabase/migrations/0021_marketplace_skills.sql (SSoT)
# → supabase/migrations/0021_lots/lot_000.sql … lot_058.sql (exécutables bloc par bloc)
```

Application en production : exécuter les 59 lots via
`mcp__supabase-aurora__execute_sql` (bloc par bloc, ordre strict,
`ON CONFLICT (skill_key) DO NOTHING` = idempotent).

## Structure par skill

```
anthropic-skills/<repo>/<plugin>/skills/<skill-name>/
  SKILL.md                  ← frontmatter YAML (name, description) + corps markdown
  references/*.md|yaml     ← sous-fichiers optionnels (références de profondeur)
```

Le générateur `scripts/skills-seed.ts` parse le frontmatter, extrait le corps
markdown dans `body`, et produit un tuple SQL par skill avec :

- `skill_key = 'marketplace:<repo>/<plugin>/<skill-dir>'`
- `source    = 'marketplace:<repo>'`
- `domain    = mappingDomain(repo, skillDir)` (table `DOMAIN_ORDER`, 14 valeurs)
- `procedure/constraints/tools = '[]'::jsonb` (skills prompt-only, pas de
  KERNEL_TOOLS)
- `body` = le markdown complet via dollar-quoting `$body$…$body$`
