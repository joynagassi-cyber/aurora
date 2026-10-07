---
name: 'Aurora — Project Context'
type: project-context
status: draft-for-review (v1.4, généré 2026-09-23, maj 2026-09-26 — v1.6 : G-M1/M2/M3/M4/M5 fixés en spec + code SSoT déjà aligné, G-L2 REJECTED 09/27 (pas de mockups — décision owner))
scope: 'Implementation rules for AI agents, wave 0–7 (mobile-only V1)'
supersedes: 'ne rien — AI_RULES.md reste l'autorité scannable (autre agent)'
companion-of: '_bmad-output/architecture/architecture-aurora-2026-09-21/SPEC.md'
---

# Aurora — Project Context (règles pour agents IA)

> **Rôle de ce fichier** : les règles *non évidentes* qu'un agent IA doit retenir
> avant d'écrire du code pour Aurora. Ce n'est **pas** une recopie de `AI_RULES.md`
> (autorité scannable, maintenu par un autre agent) ni des packs 01–05 (contrats
> prescriptifs). Ce fichier = **pont + gaps** : ce qu'il faut pour que les agents
> d'implémentation ne se trompent pas, sans relire tout le corpus.
>
> Conflit détecté → la règle gagne dans l'ordre :
> **spine AD-x (read-only) > ADR v1.7 (gelé) > SPEC/packs > ce fichier > AI_RULES.md > convention d'agent.**
> Un écart de contrat = ADR additif (breaking = dedicated PR + review).

## 1. État du projet (à mettre à jour à chaque vague)

- `IMPLEMENTING` : documentation 100 % (88 fichiers `docs/` + ADR + spine +
  SPEC + 5 packs) ; **code = ~15k lignes** réparties sur les packages ci-dessous
  (wave 0/1 en cours + modules wave 2 déjà partiellement livrés par leurs
  owners) :
  - `packages/domain` 2,5k lignes — SSoT types AD-15 (20 fichiers, zéro import)
  - `packages/data` 2,9k — PowerSync/SQLite repositories, RQ bridge
  - `packages/ui` 7,5k — Design System, 10+3 thèmes, 9 composants data, AD-10
  - `packages/platform` — adapters Capacitor (DPC, lifecycles, focus timer)
  - `packages/{learning,productivity,progress,discovery,focus,
    integrations,scientific-engine,engineering-*}` — modules wave 2+ (5–2k
    lignes chacun, code wave 2 des équipes module-owner, **hors périmètre
    wave 0/1 Foundation**)
  - `apps/mobile` — shell Ionic + feature-slices (SAPPHO wave 2)
  - `apps/server` — Edge Functions skeleton (wave 3)
- Vague courante : **wave 1 (PowerSync live)** + wave 2 modules en parallèle
  par les équipes module-owner ; wave 3 (kernel + Ascent) à lancer.
- `main` doit rester **buildable après chaque vague** (AD-13) ; test du spine
  (deux équipes → même contrat) vérifié à chaque merge (`docs/testing/matrix.md` §3).

## 2. Le monorepo à produire (wave 0, story W0-E1-1)

> **État réel au 09/26 : le layout a déjà plus de packages que le
> ratifié initial d'OQ-01 (7+2).** Le pnpm workspace contient 16
> packages + 2 apps. Les 8 modules ci-dessous (5 G-D12 + 3 équipes
> module-owner wave 2) sont des **additifs non ratifiés** à
> re-ratifier par OQ-01 amendé (Foundation + chaque équipe).

```
pnpm monorepo — ratifié OQ-01 (7 packages + 2 apps)
├── packages/domain         # SSoT types AD-15 — n'importe RIEN (2,5k lignes, livré)
├── packages/data           # PowerSync/SQLite, migrations, Model Registry, bridge RQ
├── packages/ui             # Design System @aurora/ui, contrats AD-10, tokens, 10+3 thèmes
├── packages/platform       # adapters Capacitor (whitelist 04 §3.1) — owner EXCLUSIF Foundation
├── packages/agent          # surface UI du kernel (AgentRunState, F-09) — exécution côté serveur
├── packages/scientific-engine   # [G-D12] moteur scientifique+ingénierie (2,4k lignes, livré wave 2)
├── packages/integrations        # [G-D12] ResearchProvider, Composio, OneSignal client
├── apps/mobile             # shell Ionic + feature-slices (pas d'import sibling)
└── apps/server             # Supabase Edge Functions, dispatcher, AI gateway — SEUL endroit des SDK

Additifs non ratifiés (à re-ratifier OQ-01 amendé, 09/26) :
├── packages/engineering-{core,solvers,adapters,registry}   # [G-D12] décomposition interne de scientific-engine
├── packages/learning         # module wave 2 SAPPHO (8 fichiers, 1,3k)
├── packages/productivity     # module wave 2 ATLAS (11 fichiers, 2k)
├── packages/progress        # module wave 2 ORION (6 fichiers, 865)
├── packages/discovery       # module wave 2 ORION (7 fichiers, 730)
└── packages/focus          # module wave 2 HYPATIYAS (6 fichiers, 594)
```

**Convention module-owner (OQ-02, ratifié 09/26)** : chaque équipe de
module (Productivity/ATLAS, Learning/SAPPHO, Progress+Discovery/ORION,
Focus/HYPATIYAS, Agent, Ascent…) **possède** son package
`packages/{module}` — c'est l'implémentation wave 2+ du module
(use-cases, jobs, services), **pas** le SSoT des types (qui reste
`packages/domain`, AD-15). La frontière entre un package module-owner
et `packages/domain` : le module **consomme** les types du SSoT,
**n'en crée jamais** de nouveaux (nouvelle entité = ADR additif →
`packages/domain` d'abord).

**Frontières (AD-13, ESLint `import/no-restricted-paths` = CI red)** — à
encoder dès `W0-E1-3` (story existante) :

- `packages/domain` = centre hexagonal : **zéro import**.
- SDK de fournisseur (Supabase, PowerSync, Cloudflare, OneSignal, vendor AI) =
  **uniquement** `packages/data`, `packages/platform`, `packages/integrations`,
  `packages/scientific-engine` + `apps/server` (workers). Jamais dans `domain`, `ui`,
  `apps/mobile/src`.
- Les **5 moteurs AD-10** (`@xyflow/react`+`@dagrejs/dagre`, `@antv/infographic`,
  `@antv/g2`, `KaTeX`, `motion`) = **uniquement** `packages/ui` (`no-restricted-imports`).
- `packages/ui` ↛ `packages/data` / `packages/platform`.
- Feature-slices `apps/mobile` ↛ feature-sibling (« la dépendance pointe vers la gauche »).
- Greps CI (story W0-E1-3) : noms de vendor/modèle hors adapters → build failure ;
  patterns de secrets dans le bundle client → build failure.

## 3. Les 15 règles qui font perdre les agents

Ces règles sont dans `AI_RULES.md`/spine mais sont les **pièges les plus fréquents**
pour un agent IA — à re-read avant chaque commit :

1. **Single-writer (AD-7/F-03)** : l'UI ne mute **jamais** directement SQLite ;
   le kernel **n'écrit jamais** une entité ; chaque entité = un seul writer
   (module owner, `03-sync` §4.2). Writes UI = use-case command du module owner.
2. **Zéro clé sur appareil (AD-3)** : les secrets vivent dans Supabase Secrets /
   Cloudflare Secrets (serveur). Seul excepté sanctionné = OneSignal `appKey`
   dans `capacitor.config.ts` (test 04 §7.2e).
3. **Zéro vendor dans le bundle (AD-1)** : pas de nom de modèle concret ni de SDK
   dans `domain`/`ui`/`apps`. Appeler l'AI **via le port `AIProvider`** uniquement.
4. **SSoT des types (AD-15/F-01)** : chaque entité = **une seule** source
   (`packages/domain`). Une « view » = projection déclarée (`extends Pick<Task,…>`),
   jamais une re-déclaration.
5. **RLS = AD-2 (01 §2.2)** : chaque table porte `user_id` ; test de pénétration
   **sur chaque table** avant merge (blocking). `service_role` lit les vues PowerSync
   **via RLS**, jamais `BYPASSRLS`.
6. **Événements fermés (AD-9)** : le vocabulaire = **9 événements** (matrice
   normative spine, `docs/architecture/data-event-job-catalog.md`). Ajouter un
   événement = ADR additif ; une op transactionnelle simple = command direct.
7. **Jobs persistés (AD-8)** : tout travail lourd = job **idempotent**,
   retryable, observable (`job_queue`+`job_logs`, dispatcher Supabase Cron →
   Edge Functions). Jamais bloquant dans l'UI.
8. **CRDT OR-Set figé (03 §5.3)** : les listes qui mergent = OR-Set (SSoT
   `packages/domain`), **pas** LWW-Map ; conflits simples = server-wins +
   `updated_at` serveur par entité.
9. **5 états UX par écran (AD-13)** : `loading / empty / success / error / offline`
   — manquant = **DoD non fermé**, blocking review.
10. **Tokens 100 % (pack 05)** : couleurs/espacement/typo/radius = CSS custom
    properties sémantiques light+dark. Valeur hardcodée hors token = blocking.
    Thèmes : 10 vivants + 3 presets (Slate/Nocturne/High Contrast), `Nocturne`
    = preset autonome (OQ-16) ; un thème ne touche **jamais** les tokens
    sémantiques d'état (`success`/`warning`/`danger`/`info` restants dans le
    style neutre, AD-17).
11. **Invariant Home (AD-14)** : composition fixe « Quoi de *important maintenant* »
    (agenda du jour, prochaine action importante, priorité, progress critique,
    reviews dues, accès Focus, suggestions Coach) — **jamais** un dashboard de widgets.
12. **Zustand = UI state uniquement (pack 02 §3.1)** : sélections, view modes,
    scroll anchors, thème, focus-mode, palette. **Jamais** une entité de domaine
    en cache de SSoT. Données = `@tanstack/react-query` → repository PowerSync.
    **Redux est exclu par décision pack 02 S3.1 (AD-10 : React Flow = Zustand,
    doc §25.2)** — pas une règle AD-1.
13. **Agent = serveur uniquement (AD-12/F-09)** : le kernel (Planner/Coach/Tutor/
    Researcher/Executor) = **un seul** kernel côté serveur ; l'app ne consomme que
    la surface `AgentRunState` + command bus `AgentActionEnvelope`. L'agent
    **n'importe jamais** de composant React, n'exécute jamais du kernel.
14. **Focus = restriction/DND/Screen Pinning uniquement (pack 04 §4.1)** : le
    blocage natif d'applications tierces sur Android = **non promessable**
    (`isBlockingAvailable()` = false → pas de CTA de blocage dans l'UI).
    OQ-17 (DPC v1.8) = mode dégradé si échec du provisioning.
15. **Performance (OQ-11, pack 02 §9)** : budgets = Pixel 4a, ≤ 300 Ko JS gz
    initial, ≤ 1,5 s TTI, 30 fps (arbre sémantique). Listes = `IonList` natif ;
    `react-virtuoso` **uniquement** > 100 items. Moteurs AD-10 = lazy (`React.lazy`)
    à l'ouverture de l'écran, **jamais** dans le bundle Home.

## 4. Gates wave 0 (à trancher AVANT de coder — story W0-E1-1)

C'est le **blocant** de la vague 0 (`SPEC.md` wave plan, `01/03` §8.1) :

| Gate | Contenu | Owner | Story |
|---|---|---|---|
| **OQ-01** | Ratifier le layout pnpm + mapping AD-15 entité→package→équipe (**doit inclure les packages engineering de G-D12 : `engineering-core`, `engineering-solvers`, `engineering-adapters` + `engineering-registry` + les 4 packages module-owner wave 2 : `learning`, `productivity`, `progress`, `discovery`, `focus`**) — **ré-ratification nécessaire au 09/26 (le layout réel = 16 packages + 2 apps)** | Foundation + chaque team | W0-E1-1 précondition |
| **OQ-02** | Colonnes équipe par entité AD-15 (mapping entité→module owner→table locale déjà frozen dans 03 §4.2 ; reste = colonne équipe) + les 4 nouvelles entités G-D13 (`GoalProject`, `SubGoal`, `FeaturePlacement`, `GoalProgress`) | Foundation | W0-E1-1 précondition |
| **G-M7** | Feature Registry ratifié (`docs/frontend/feature-registry.md` S1) | App Shell + Foundation | W0-E1-1 précondition |
| **G1** | Frontmatter pack 02/05 : signatures AD-10 ratifiées + Zustand ratifié (gating vague 1 UI) | DS team | W0-E1-1 |
| **OQ-03** | Valeurs d'env (noms de buckets, régions, provider account IDs) — structure AD-16a fixée, **valeurs** = données wave 0 | Foundation | W0-E3-1 |
| **G-D10..D14** | 4 gaps additifs de traçabilité (voir §5) — pas de spine change, ADR additif conventions ; à intégrer dans le scaffolding wave 0 sans blocage | Foundation | W0-E1-1..W0-E5-x |

⚠️ Un agent qui commence à scaffolder **sans** avoir OQ-01/OQ-02 tranchés viole
le gate du SPEC. Trancher = noter la décision (additive) dans ce frontmatter
`§5 Décisions récentes`, pas dans le spine (read-only).

## 5. Décisions récentes (zone de log, additif — pas de modification du spine)

<!-- Ajoutez ici : date — décision — par qui. Un écart de contrat = ADR additif. -->

- 2026-09-21 — AD-17 figé (système de thèmes v2 : 10 vivants + 3 presets, règle
  thème/sémantique, SSoT `packages/ui/src/themes/` JSON) — pack 05 final.
- 2026-09-21 — OQ-14/15/16 tranchées (thèmes V1 = 10+3, adaptations locales =
  Focus Mode only, Nocturne = preset autonome).
- 2026-09-22 — OQ-17 (Focus DPC v1.8) = **OPEN, blocant** pour le figage Focus ;
  mode dégradé = 04 §4.1 si le téléphone ne peut pas être provisionné.
- 2026-09-23 — `project-context.md` créé (ce fichier) ; Reversa **annulé**
  (génie inverse non requis — projet spec-first, pas legacy).
- 2026-09-23 — G-D10 (run 2 readiness) : Vercel AI SDK = détail d'implémentation
  du kernel, **additif** (AD-1 boundary : SDK uniquement dans `packages/agent`),
  pas de spine change ; à documenter comme décision wave 3.
- 2026-09-23 — G-D11 : `Agnes Image 2.5 Flash` (docs/ai/providers/agnes-image.md)
  à ajouter au Model Registry seed (W0-E5-2) — capability `image-generation`,
  snapshot de prix 2026-09-22 (all free, **pas de SLA**, OQ-12 appliqué).
- 2026-09-23 — G-D12 : 3 nouveaux packages engineering
  (`engineering-core`, `engineering-solvers`, `engineering-adapters`) à ajouter
  au layout pnpm ratifié par OQ-01 — additif, pas de spine change (AD-1 boundary :
  aucun SDK de fournisseur hors adapters).
- 2026-09-23 — G-D13 : 4 entités `GoalProject`, `SubGoal`, `FeaturePlacement`,
  `GoalProgress` (dynamic-goal-engine.md) à ajouter à `packages/domain` (AD-15)
  en **ADR additif** (spine Consistency Conventions : additive = intégration
  normale, pas de code).
- 2026-09-23 — G-D14 : 4 champs à ajouter à `UserContext` (wave 0, Identity) :
  `region`, `disciplines`, `professional_target`, `budget_constraint`
  (data-driven filtering de Discovery, pas de hardcoding Benin —
  `docs/knowledge/discovery-gap-pipeline.md`).
- 2026-10-07 — **Vérif live post-RC (Dyad)** : 4 jobs pg_cron `aurora_*` à
  0 échec (fix heartbeat v1.10 confirmé, `keep_alive.last_ping` 10-07),
  `job_queue` vide, `skill_catalog` = 607, `canvas_sessions.locked` + FORCE
  RLS ✅, 14/14 vues `v_*` → `service_role` ✅. **Finding Low → FIXÉ live
  10-07** : `ALTER TABLE skill_catalog FORCE ROW LEVEL SECURITY` appliqué +
  confirmé (`forced=true`) — aligne la convention wave 0 (51/51 RLS+FORCE) ;
  le `service_role` (BYPASSRLS) reste borné mais conserve l'accès `ALL` via
  `skill_catalog_service_write` (qual nulle) → EF non impactées. **Reste
  (monorepo)** : 1 ligne FORCE à resyncer dans le SSoT
  `supabase/migrations/0021` (ou migration `0024` additif) ; input W6-E1-1.
- 2026-10-07 — **P1-2 tranché (brouillon, à ratifier standup)** : résolu
  `DISCOVERY_JOB_HANDLERS` côté EF par **copie vendée**
  (`supabase/functions/_shared/veille-pipeline.ts`) + **gate de drift CI** ;
  l'Option A (esbuild bundle) reste en backlog. Additif, pas de spine change
  (`docs/plans/ef-bundling-p1-2.md`).
- 2026-10-07 — **Parking lot Phase 2 = brouillons de recommandation** :
  Electron / Yjs / STT local = **différer** ; microservices = **rejeté**
  sauf échelle multi-produit. Chaque tranché = ADR additif ici (§5), jamais
  de modif du spine (additive = normal, breaking = PR dédié + review)
  (`docs/plans/phase2-parking-lot.md`).
- 2026-09-26 — **OQ-01 ré-ratifié (layout réel 16 packages + 2 apps)** :
  le pnpm workspace contient 4 packages module-owner wave 2
  (`learning`, `productivity`, `progress`, `discovery`/`focus`) +
  `engineering-registry` (4ᵉ package G-D12) au-delà de l'OQ-01
  original. **Convention module-owner (OQ-02)** : chaque équipe de
  module possède son `packages/{module}` (implémentation wave 2+) ;
  le SSoT des types reste `packages/domain` (AD-15) — un module
  **consomme** les types, n'en crée jamais (nouvelle entité =
  ADR additif → `packages/domain` d'abord). **Non-bloquant pour
  wave 3** : la ré-ratification ne bloque que l'addition de
  **nouveaux** packages, pas l'implémentation des features existantes.

## 6. Checklists DoD par vague (à cocher avant de déclarer une vague finie)

### Wave 0 (W0-E1..W0-E5)
- [ ] `pnpm install` OK sur tous les packages + tsconfig strict
- [ ] `packages/domain` compile **sans aucun** import (grep + build)
- [ ] 24+ entités AD-15 + 9 événements + envelopes (`ApiEnvelope`,
      `AIResponseEnvelope`, `AppError`) dans `packages/domain`
- [ ] ESLint `import/no-restricted-paths` + `no-restricted-imports` + greps
      vendor/secrets = CI vert
- [ ] OQ-01/OQ-02/G-M7/G1 notés dans §5
- [ ] Supabase 3 envs (dev/staging/prod) + RLS policies par module + tables
      fondatrices (`user_context`, `events`, `job_queue`, `job_logs`,
      `model_registry`)
- [ ] R2 buckets 3 envs + presigned (15 min get / 5 min upload) testé
- [ ] `packages/ui` : 10+3 thèmes JSON + `resolveToken` + 9 composants data +
      5 contrats renderer AD-10 (engine imports = 0 hors `packages/ui`)
- [x] Test de pénétration RLS (01 §7) passe sur toutes les tables
      (effectué 2026-09-26 : isolement A vs B complet en `authenticated` —
      lire le changelog pour l'anomalie `service_role` = artefact de simulation)
- [ ] G-D10..D14 intégrés : Vercel AI SDK (agent-only), Agnes Image dans Model
      Registry seed, 3 packages engineering dans le layout OQ-01, 4 entités
      GoalProject en ADR additif, 4 champs UserContext (G-D14)

### Wave 1 (W1-E1..W1-E3)
- [x] Migrations wave 0 appliquées + tracées au tracker Supabase (marker
      additif `0200_aurora_wave0_schema_applied`, version live
      `20260925234343` — vérifié objet par objet via MCP 2026-09-26)
- [ ] PowerSync relay + vues publiques + bridge RQ↔watch (03 §5.8) fonctionnel
      (état 2026-09-26 : **relay DÉPLOYÉ sur Aurora Dev** `6ab1612e…`
      via `powersync deploy` — slot actif, lag 0 ; sync-config = 12 flux
      edition 3 par module owner (wave 1 ×10 + `user_goals` + `ascent`,
      ajout 2026-09-26) ; `PS_ADMIN_TOKEN` = token PowerSync
      Cloud de l'org **Aurora** (PAT de l'org du projet, pas Lumina —
      2026-09-26 redeploy validé). À ancrer
      côté app : `fetchCredentials()`/`uploadData()` + test round-trip
      `powersync/test/roundtrip.md`. **Résidu** : les 31 warnings
      « table not found » de `powersync status` (le secret
      `default_password` du Cloud ne correspond plus au mot de passe
      courant du DB — à corriger côté dashboard ; cf
      `powersync/README.md` § Wave 1 status).)
- [ ] Offline : lecture locale OK, write local → upsync au reconnect, kill-app
      relaunch = état intact (03 §5.9)
- [ ] CRDT OR-Set merge testé ; single-writer test (AD-7) passe
- [ ] Supabase Auth (email + OAuth) + RLS actif sur toutes les tables
- [ ] Job system end-to-end : dispatch → claim → résultat, idempotence testée
      (état 2026-09-27 : **scheduler live DEV** — les 4 jobs
      `aurora_keep_alive`/`aurora_fsrs_tick`/`aurora_skill_recompute`/
      `aurora_event_dispatch` (jobids 7–10) sont actifs via
      `cron.schedule()` ; reste le test de dispatch/claim/idempotence)
- [ ] OneSignal + local notifications : pas de double-push pour le même objet
      (test 04 §7.2)

### Wave 2 (W2-E1..W2-E6)
- [ ] Chaque feature : 5 états UX présents (review blocking)
- [ ] `TaskCompleted` → Progress + Learning + Agent (event wiring AD-9)
- [ ] Focus Mode : timer offline + DPC `setPackagesSuspended` (si OQ-17 OK)
      + 13 scénarios testés (`docs/testing/matrix.md` §2)
- [ ] Flashcards FSRS déterministe (server job, état miroir local)
- [ ] Arbre sémantique : 1000 nœuds à 30 fps + versioning `semantic_tree_version`
- [ ] Mirror Cognitive = job serveur, **jamais** local ; provenance `SourceRef`
      sur chaque détection (AD-11)
- [ ] Scientific engine : calculs déterministes (unités/dimensions) vérifiés
- [ ] Artifacts : `ArtifactGenerated` émis **après** upload R2 uniquement (F-06)

### Wave 3 (W3-E1 + W3-E2)
- [ ] Kernel serveur : Intent Engine (TaskProfile typé, **jamais** mots-clés de
      prompt) + Context Builder (9 forms) + Capability/Tool Registries
- [ ] Vérification critique = ScientificEngine (job serveur) + KB check
- [ ] `AIResponseEnvelope` sur **chaque** appel modèle (trace AD-5 : provider,
      modèle, tentatives, raison, qualité attendue)
- [ ] Expert Skills : garde-fous (contradiction, obsolescence, correction user)
      testés ; `expert_skills` = **serveur uniquement** (AD-3, jamais syncé)
- [ ] `AgentRunState` stream vers l'UI ; agent **n'importe** jamais de React
- [ ] 20 E2E scenarios `docs/agent/e2e-agent-scenarios.md` passent
- [ ] Ascent (W3-E2) : `AscentLearningIR` = data, pas d'UI ; adaptative sur
      `ProgressEvidence` (reorder/remediation/depth) ; tables `ascent_*` =
      **serveur uniquement** (AD-3, comme `expert_skills`) ; Slide-Ascent S-41
      (progressive disclosure 3 niveaux) = **lecture seule** via PowerSync
- [ ] Ascent déclarée feature `ascent` dans le Feature Registry (G-M7) ;
      désactivation = dégradation AD-1 (pas de rupture, data préservée)

### Wave 4 (W4-E1)
- [ ] 23 workflows composites (`docs/workflows/composite-workflows.md`) testés
- [ ] Orchestration multi-modules : rollback sur échec partiel (error-recovery S9)
- [ ] Écouteur événementiel : `since_event_id` incrémental, **pas** de broker

### Wave 5 (W5-E1)
- [ ] Adaptation locale Focus Mode (OQ-15, AD-17) : surfaces atténuées +
      focus ring renforcé ; **autres écrans inchangés**
- [ ] 6 product modes rendus correctement ; command palette liste les
      capabilities disponibles (pas toutes)
- [ ] Budgets perf **mesurés** (Sentry) : ≤300 Ko gz, ≤1,5 s TTI, 30 fps
      (device = Pixel 4a, OQ-11)

### Wave 6 (W6-E1)
- [ ] Deep review : AD-1..AD-17 vérifiés ; **pas** de `if user === Horeb`
      (finding review, mission) ; agent n'importe jamais de React ; pas de
      secret dans le bundle
- [ ] Matrice de tests 100 % couverte (todo : gaps = nouvelle story)

### Wave 7 (W7-E1)
- [ ] E2E Android (Playwright + Capacitor driver, OQ-08 ; Appium si échec
      Android 14) : 20 scenarios agent + 23 workflows + 8 scenarios DPC
- [ ] CI/CD : build + test + deploy (Supabase, CF Workers, R2) staging → prod
- [ ] `OQ-03` valeurs prod confirmées

## 7. Où chercher quoi (pointeurs, pas de recopie)

| Besoin | Référence |
|---|---|
| Invariants du projet (AD-1..AD-16) | `_bmad-output/…/ARCHITECTURE-SPINE.md` (read-only) |
| Décisions produit/architecture §1–§26 | `_bmad-output/…/adr-extract.md` (gelé v1.7) |
| Contract Pack par dimension | `_bmad-output/…/dimensions/01..05-*.md` |
| Plan de vagues + OQ-01..OQ-17 | `docs/epics-stories.md` + `…/SPEC.md` |
| Guide scannable des règles | `AI_RULES.md` (maintenu par un autre agent — **ne pas modifier** ici) |
| Matrice de tests | `docs/testing/matrix.md` |
| Matrice de permissions | `docs/architecture/permission-matrix.md` |
| Registre de secrets | `docs/architecture/secrets-checklist.md` |
| Register de gaps ouverts | `docs/architecture/gap-register.md` + `docs/architecture/evolution.md` |

## 8. Rappels d'anti-patterns agents (ce qui a déjà cassé des revues)

- ✗ Re-déclarer un type de domaine dans un feature (`Task` existant ≠ nouveau
  `TaskRow` sans `extends Pick`) → **bloque** (AD-15).
- ✗ Écrire une table d'un autre module « parce que c'est plus simple » →
  **bloque** (AD-2/AD-7/F-03).
- ✗ Ajouter un 10ᵉ événement « pour le cas » → **bloque** (AD-9) ;
  nouvelle = ADR additif.
- ✗ Importer `KaTeX` dans une feature pour « afficher le formules » →
  **bloque** (AD-10) ; passer par `MathRenderer` de `packages/ui`.
- ✗ Mettre une clé AI dans `apps/mobile/.env` « en dev seulement » →
  **bloque** (AD-3, grep CI).
- ✗ `if (user.email === 'horeb@…')` n'importe où → finding review (mission §21.6).
- ✗ Promettre du « free tier » sans date de snapshot → **bloque** (OQ-12, spine
  silent = intentional) ; versionner dans Model Registry, pas dans le spine.
- ✗ Ajouter un adapter Electron « pour le futur » en V1 → **bloque** (ADR §23.1/
  §23.3, pack 04 R8) : la Phase 2 = adapter ajouté, pas réécriture ;
  core = platform-agnostic.
