# Plan Reversa — Aurora (aurora-2)

> Projet : suite de productivité + apprentissage + orchestration agentique (Phase 1 mobile-only Android).
> Le présent projet n'est **pas** un codebase legacy : il s'agit d'un plan de spécifications
> (ADR v1.7 gelé, spine AD-1…AD-16, SPEC + 5 packs de dimension). L'analyse Reversa opère
> donc sur la **documentation existante** (docs/ + _bmad-output/) comme source d'information,
> en plus de la structure du monorepo à venir (pnpm-workspace.yaml).

## Scoping — Niveau de documentation

- **Niveau retenu : 2. Complet** (diagrammes C4, registre de dépendances, ADRs existantes à retracer,
  matrices de traçabilité) — recommandé par l'exécution ; projet à architecture composite,
  déjà riche en ADR/SPEC. Aucun blocant.
- Le niveau ne change pas la séquence des agents Reversa, uniquement la profondeur des artefacts.

## Phase 1 — Scout (reconnaissance)

- [ ] Cartographie de la structure racine (monorepo pnpm, docs/, _bmad-output/, prompts/, skills/)
- [ ] Identification des modules et composants principaux (packages à créer selon SPEC wave 0)
- [ ] Inventaire des intégrations externes (Supabase, R2, OneSignal, AI providers)
- [ ] Vérification de la présence de schéma de base de données (Supabase / PowerSync)
- [ ] Production de `_reversa_sdd/inventory.md`, `_reversa_sdd/dependencies.md`, `.reversa/context/surface.json`

## Phase 2 — Archéologue (fouille)

- [ ] Archéologue — Analyse du module `docs/architecture` (spine, ADR, registres)
- [ ] Archéologue — Analyse du module `docs/agent` (kernel, permissions, orquestration)
- [ ] Archéologue — Analyse du module `docs/ai` (gateway, providers, budget, fallback)
- [ ] Archéologue — Analyse du module `docs/focus-mode` + `docs/mobile`
- [ ] Archéologue — Analyse du module `docs/frontend` + design system
- [ ] Archéologue — Analyse du module `docs/data` + `docs/events` + `docs/jobs`
- [ ] Archéologue — Analyse du module `_bmad-output/architecture` (packs 01–05)

## Phase 3 — Détective (interprétation)

- [ ] Interprétation des patterns (Modular Monolith + Hexagonal + Local-First)
- [ ] Reconstruction du flux de données (UI → repositories → PowerSync/SQLite → Supabase → jobs)
- [ ] Identification des hypothèses de confiance (🟢 confirmé / 🟡 inféré / 🔴 lacune)

## Phase 4 — Architecte + Data Master + Design System (génération)

- [ ] Architecture — Génération de `DESIGN-BLUEPRINT.md` à la racine
- [ ] Data Master — Schéma de données (entités AD-15, tables, vues PowerSync, RLS)
- [ ] Design System — Tokens, composants, contrats AD-10, thèmes (pack 05)

## Phase 5 — Reviewer (révision)

- [ ] Vérification de cohérence cross-fichiers
- [ ] Validation des matrices de traçabilité
- [ ] Sign-off final

## Phase 6 — Sécurité

- [ ] Analyse de sécurité (RLS, zéro clé sur appareil AD-3, secrets management, audit des vecteurs d'attaque)
- [ ] Production de `.reversa/security-report.md`

## Contraintes

- Écriture uniquement dans `.reversa/` et `_reversa_sdd/` (règle absolue Reversa).
- Chaque phase conclue → checkpoint dans `.reversa/state.json` + entrée dans `_reversa_sdd/execution-log.md`.
