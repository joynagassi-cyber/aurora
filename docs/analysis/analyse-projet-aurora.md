# Aurora — Analyse du projet (rapport de compréhension)

> **But du document :** permettre à un humain (ou à un agent) de comprendre *ce qu'est Aurora, comment c'est construit, où c'est, et dans quel état réel c'est* — en une lecture.
> **Méthode :** lecture directe du code et des fichiers (pas des seules docs), commandes en lecture seule, trois explorations parallèles (packages / apps+backend / gouvernance+docs). Chaque affirmation est étiquetée **[vérifié]** (lu dans le tree ou mesuré) ou **[déclaré]** (affirmé par une doc, non vérifiable ici).
> **Règle appliquée :** le tree gagne sur les docs. Toutes les divergences doc↔code trouvées sont listées au §9.
> **Date :** 2026-10-09/10 · **Branche :** `lot-1/kernel-safety` · **HEAD :** `812b88a`

---

## 1. Synthèse exécutive

**Aurora est une suite personnelle « productivité + apprentissage + orchestration agentique »**, livrée **Phase 1 en mobile-only (Android)**, sur une architecture composite gelée (ADR v1.7, spine AD-1…AD-17).

| | |
|---|---|
| **Nature** | Monorepo pnpm : **19 packages + 2 apps** + `supabase/` + `powersync/` + `packages/workflows` (23 workflows) |
| **Volume (vérifié)** | **2 498 fichiers suivis** ; ~**43 100 lignes** TS/TSX dans `packages/` ; ~**14 800 lignes** TS/TSX dans `apps/mobile/src` + ~8 200 lignes CSS ; **173 fichiers `.md`** sous `docs/` |
| **Stack** | Ionic React + Capacitor (Android) · PowerSync + SQLite (local-first) · Supabase (Postgres + Auth + Edge Functions + pg_cron + pgvector) · Cloudflare R2 + AI Gateway · Vercel AI SDK · Sentry + PostHog |
| **État affiché** | RC **v0.1.0** (waves 0→7 livrées) + travail en cours « LOT 1-bis » (sécurité du kernel) |
| **État réel mesuré** | Architecture **réellement appliquée** (hexagone propre, vendors confinés, AD-10 respecté dans les packages) — **mais deux des trois portes de qualité annoncées sont rouges sur HEAD** (§8), et l'enforcement des frontières a un trou systémique sur les fichiers `.tsx` |

**Verdict en une phrase :** le *design* est d'un niveau très supérieur à la moyenne (décisions tracées, frontières typées, SSoT unique), mais *la preuve automatisée que ce design tient* est en partie fictive — les gates sont à la fois plus faibles que ce qui est annoncé **et** actuellement en échec.

**Les 5 constats les plus importants**

1. 🔴 **`pnpm -r lint` échoue sur HEAD** — un fichier commité viole AD-10 (moteur `motion` importé hors `packages/ui`). **[vérifié, reproductible]**
2. 🔴 **Le typecheck de `apps/mobile` échoue sur HEAD** — 8 erreurs TypeScript dans 6 fichiers commités. **[vérifié, reproductible]**
3. 🔴 **Les règles de frontière ESLint ne couvrent que `**/*.ts`, jamais `**/*.tsx`** — donc 48 fichiers `.tsx` dans `apps/mobile` et 58 dans `packages/ui` (c.-à-d. quasi toute l'UI) échappent à AD-1 / AD-10 / AD-6. Prouvé par sonde `--stdin-filename`. **[vérifié]**
4. 🟠 **La documentation est structurellement en retard** : 24 vs 25+60 migrations, 6 vs 8 Edge Functions, un fichier de test référencé par la CI qui n'existe pas (et qui ferait échouer le release), `vitest.config.ts` racine absent, tag `v0.1.0` inexistant, `apps/server` = stub de 6 lignes.
5. 🟠 **Le travail en cours le plus sensible est le moins documenté** : le durcissement `LOT 1 / LOT 1-bis` (confirmation gating, reprise serveur liée au contenu, canal interne `x-aurora-internal` + `INTERNAL_FN_SECRET`) n'existe que dans des commentaires de code, des noms de tests et une ligne de checklist.

---

## 2. Identité produit — à quoi sert Aurora

**[vérifié]** `docs/architecture/00-overview.md` + `AI_RULES.md` + `pack/*` décrivent une application unique qui agrège :

- **Productivité** : tâches/sous-tâches, listes, matrice d'Eisenhower, calendrier multi-vues, habitudes *streaks*, routines, compte à rebours, revues (jour/semaine/mois), projets (Kanban / Rapports / Gantt / Timeline / Liste).
- **Apprentissage** : FSRS (répétition espacée), QCM, récupération active, arbre sémantique de connaissances, miroir cognitif, *study sheets*, import de cours.
- **Objectifs & progression** : *Dynamic Goal Engine* (décomposition de GoalProject), tableaux de bord adaptatifs, preuves de progression, trajectoires, écarts de compétence. **`packages/progress` est le seul producteur de progression (F-07).**
- **Agent IA** : un **Agent Kernel unique** (conversations, artefacts, canvas TipTap, bibliothèque de fichiers, capacités, connecteurs, compétences expertes / marketplace).
- **Focus** : minuteur Pomodoro/chrono, blocklist, DPC Android v1.8.
- **Découverte** : veille multi-sources, analyse d'écarts, horizons.

**Origine produit — le dossier `pack/` [vérifié]** : 4 PRD Markdown (1 128 / 601 / 302 / 180 lignes) + 128 captures dans `pack/images/`, décrivant **4 applications de référence** et ≈**164 écrans** :

| PRD | Nom de travail | Écrans |
|---|---|---|
| `PRD_1_Productivite.md` | FocusFlow | ≈107 |
| `PRD_2_Bible.md` | Lumen Bible | ≈36 |
| `PRD_3_Assistant_IA.md` | AssistPro | ≈15 |
| `PRD_4_Gestion_de_projet.md` | BoardWorks | 6 |

La consigne structurante de ce pack : **la capture d'écran fait foi** pour la structure/composants/disposition ; couleurs, polices, logos et textes de marque sont libres mais **doivent être remplacés par du contenu original** (aucune reprise de marque tierce). Contrainte licencing explicite dans le PRD 2 : les textes bibliques doivent venir de sources de domaine public ou sous licence éditeur.

**[vérifié]** Ce pack est **en cours d'implémentation active** : le routeur mobile contient des routes ajoutées en 10-08/10-09 explicitement référencées `PRD-AI-01/05/06`, `PRD-1 §4.5`, `PRD-CD-01`, « lot C v3 2026-10-08 ».

---

## 3. Architecture — le spine AD-1…AD-17

**[vérifié]** `_bmad-output/architecture/architecture-aurora-2026-09-21/ARCHITECTURE-SPINE.md` (264 lignes, `status: final`) fixe un paradigme composite :

> **Modular Monolith + Vertical Slices + Hexagonal (Ports & Adapters) + Local-First + Targeted Event-Driven + Agent Kernel central**

| # | Invariant | Enforcement annoncé | Réalité mesurée |
|---|---|---|---|
| **AD-1** | Isolation vendors — aucun SDK/framework/modèle concret dans domain/app | ESLint `no-restricted-imports` + `check-boundaries.sh` G1/G2 | ✅ **tient dans `packages/`** : `@supabase/*`+`@powersync/*` → `packages/data` seul ; `@capacitor/*` → `platform` seul ; `ai`/`@ai-sdk/*` → `agent` seul ; `ag-grid`/`@xyflow`/`@antv`/`katex`/`motion` → `ui` seul. ⚠️ **ne s'applique pas aux `.tsx`** (§8.3) |
| **AD-2** | Frontière de module — jamais les tables d'un autre module | RLS + `check-rls.sh` + `check-view-joins.ts` | 🟡 RLS réelle (ENABLE+FORCE quasi partout) ; mais `check-rls.sh` (a) est quasi tautologique et (c) FORCE n'est qu'un WARN ; `check-view-joins.ts` **ignore tout `.sql` dont le chemin ne nomme pas 1 des 10 modules** |
| **AD-3** | Aucune clé/secret sur le device | R2 presign, OneSignal appKey seule exception, G2 | ✅ `apps/mobile/.env.local` = **3 variables `VITE_*` publishable uniquement** ; tout le reste est côté serveur |
| **AD-4/5** | Pipeline IA multi-fournisseur, Agnes primaire, 429 jamais contourné | Router + Gateway + `model_registry` | 🟡 **déclaratif** : le code existe (`router.ts`, `gateway.ts`, `providers.ts`), le comportement runtime n'est pas exerçable ici |
| **AD-6** | Split de la couche data (Postgres = SoT, pgvector, R2) | ESLint `ui` → pas de `data`/`platform` | ✅ vérifié (aucun import) — mais règle `.ts` seulement |
| **AD-7** | Local-first + **single-writer** | PowerSync/SQLite, server-wins, OR-Set | ✅ codé (`crdt-orset.ts`, `server-wins.ts`, `upsync-queue.ts`, `react-query-bridge.ts`) |
| **AD-8** | Tout travail lourd = job persistant/idempotent/retryable | `0010_jobs` + `fn-job-dispatcher` + pg_cron | ✅ design solide (clé d'idempotence + trigger `pg_notify`) |
| **AD-9** | Exactement **9** événements, 1 producteur + consommateurs déclarés | `domain/events.ts` + `event-flow.ts` | ✅ **9 événements confirmés** dans `domain/src/events.ts` |
| **AD-10** | Les 5 moteurs de viz confinés à `packages/ui` | ESLint + « grep G-gates » | ❌ **le grep ne couvre pas les moteurs** (seuls les vendors sont dans G1) et **ESLint ne voit pas les `.tsx`** → enforcement ≈ inexistant |
| **AD-11** | Fidélité de corpus & provenance | extensions Tiptap `SourceRefInline` / `CorpusBadge` | 🟡 non vérifié en profondeur |
| **AD-12** | Un seul Agent Kernel (15 composants), device = `AgentRunState` | `check-boundaries.sh` G4 | ✅ 15 composants + G4 en place |
| **AD-13** | 1 story = 1 commit = 1 rollback ; main buildable | Protocole + PR | ❌ **contredit par l'état réel** (lint + typecheck rouges, cf. §8) |
| **AD-14** | Invariant Home — « What matters now? », composition fixe | `apps/mobile/src/pages/home/` | ✅ 7 slots fixes identifiés |
| **AD-15** | Un seul SSoT par type (`packages/domain`) | `tests/spine` | 🟡 `tests/spine` **a ses imports `@aurora/domain` commentés** → vérifie que deux structures *locales* s'accordent, pas le SSoT |
| **AD-16** | Enveloppe opérationnelle gelée (3 envs, registres, propriété CI, SLO jobs) | `set-secrets.ps1` + registres | 🟡 partiellement |
| **AD-17** | Thèmes multiples, états sémantiques invariants | `resolveToken` + JSON SSoT | ✅ 13 fichiers JSON de thème dans `packages/ui/src/themes/` |

### Le layering réellement mesuré **[vérifié]**

Tous les imports `@aurora/*` extraits de `src/` :

```
domain, engineering-core, engineering-registry, engineering-solvers → (rien)
platform                                                           → (aucun @aurora ; @capacitor/* uniquement)
ui                                                                 → @aurora/domain
agent, ascent, data, discovery, goal-engine, integrations,
learning, productivity, progress, scientific-engine, workflows      → @aurora/domain
engineering-adapters                                               → @aurora/scientific-engine
focus                                                              → domain, platform, productivity
```

**Hexagone réel : tout dépend de `domain` ; rien ne dépend de `data`, `ui`, `agent` ni `workflows`.** C'est propre et rare.

**Trois écarts au règles annoncées :**
- `focus/src/pomodoro.ts` **ré-exporte** la machine à états Pomodoro de `@aurora/productivity`, et `focus/src/service.ts` type-importe depuis `@aurora/platform` — or `focus` et `productivity` sont tous deux présentés comme des « vertical slices » dans la même doc. C'est déclaré dans `package.json` et documenté, donc **intentionnel — mais la règle telle qu'écrite est fausse**.
- **Cycle de packages** : `engineering-adapters → scientific-engine` (runtime) vs `scientific-engine → engineering-adapters` (devDependency, utilisé par son test).
- **`tsconfig.json` racine ne référence que 12 des 19 packages** (il omet `focus, productivity, learning, progress, discovery, ascent, workflows`).

---

## 4. Cartographie du monorepo

### 4.1 Les 19 packages **[vérifié]**

| Package | Rôle (vérifié dans le code) | Fichiers src | LOC src | Tests |
|---|---|---|---|---|
| `domain` | **SSoT** de tous les types gelés : enveloppes, CRDT, 11 modules d'entités (40+), **9 événements**, **14 ports**, 8 contrats AI-pipeline, 7 registres. **N'importe rien.** | 22 | 2 744 | ❌ **aucun** |
| `ui` | Design system : tokens, ~38 composants shadcn/Radix, data-components, **5 renderers AD-10**, 13 thèmes JSON | 67 | 7 878 | 9 (Vitest) |
| `agent` | **Agent Kernel** (15 composants) + 27 tools + couche Vercel AI SDK (seule exception AD-1) | 29 | 7 133 | 13 |
| `data` | PowerSync/SQLite, sync engine, CRDT OR-Set, server-wins, migrations, Model Registry, pont React-Query | 20 | 3 918 | 10 |
| `workflows` | 23 workflows composites `w1…w23` + `event-flow` + `error-recovery` + `self-improvement` + 20 scénarios E2E | 32 | 2 021 | 7 |
| `productivity` | tâches, habitudes, routines, projets/objectifs, Eisenhower, calendrier, inbox, revues, focus | 11 | 1 900 | 1 |
| `scientific-engine` | moteurs math/unités + LaTeX + 6 registres + validation 5 étapes + poutre RDM | 12 | 1 794 | 1 |
| `learning` | FSRS, QCM, retrieval, arbre sémantique, miroir cognitif, import de cours | 8 | 1 237 | 1 |
| `ascent` | trajectoire pédagogique Slide-Ascent (path-builder, baseline, depth, read-do-prove) | 8 | 1 248 | 3 |
| `integrations` | Composio (client REST maison — **pas de SDK**), notifications OneSignal, automatisations | 5 | 1 103 | 4 |
| `goal-engine` | Dynamic Goal Engine : décomposition, layout de dashboard, mutations, patterns, progression | 6 | 1 044 | 5 |
| `discovery` | feed de découverte, gaps, filtrage, research-provider, pipeline de veille | 8 | 934 | 2 |
| `progress` | dashboard, preuves, recompute idempotent, trajectoires — **seul producteur (F-07)** | 6 | 808 | 1 |
| `platform` | adaptateurs Capacitor derrière interfaces (lifecycle, notifications, réseau, DPC, boot) | 9 | 662 | 1 |
| `focus` | **SSoT de `FocusControllerPort`**, timer, pomodoro, bilan, service | 6 | 577 | 3 |
| `engineering-adapters` | `SymPyBackend` (avec probe + fallback numérique) | 2 | 84 | 1 |
| `engineering-core` | ⚠️ **stub mort de 5 lignes** (`export {};`) | 1 | 5 | ❌ |
| `engineering-registry` | ⚠️ **stub mort de 5 lignes** | 1 | 5 | ❌ |
| `engineering-solvers` | ⚠️ **stub mort de 5 lignes** | 1 | 5 | ❌ |
| **Total** | | **254** | **35 100** | **62 fichiers de test (55 suites)** |

**Fait notable :** `AI_RULES.md` crédite les trois `engineering-*` de « Problem IR + 6 registries + 5-stage validation + deterministic execution ». **Ce contenu est en réalité dans `scientific-engine`** (`registries.ts` 418 L, `validation.ts` 171 L, `beam.ts` 138 L) et `engineering-adapters/sympy.ts` (78 L). Les trois packages ne contiennent qu'un `export {};`.

### 4.2 Les 2 apps + l'infra

- **`apps/mobile`** — Ionic React + Capacitor, **95 fichiers / 22 963 lignes** dans `src` (dont 17 CSS / 8 171 lignes). ~30 pages, ~40 routes. Dépendances : `@ionic/react ^8.8`, `@capacitor/core` + `@capacitor/android ^7.6.9` (**pas d'iOS, pas de CLI Capacitor**), TipTap, TanStack Query, Zustand, `motion ^13.4`, `@supabase/supabase-js`, 7 packages `@aurora/*`. Pas de script `test`.
- **`apps/server`** — ⚠️ **stub** : `src/index.ts` fait **6 lignes** (un commentaire + `export {};`). Sa `package.json` annonce « Supabase Edge Functions + Cloudflare Workers » et des SDK vendors **qui ne sont pas dans les dépendances**. Le serveur réel vit dans `supabase/functions/` (Deno) et `packages/*`. Le `dist/` compilé (vide) est **commité**.
- **`supabase/`** — le backend réel (§5).
- **`powersync/`** — relay : `relay.sql`, `schema.json`, `sync-config.yaml`, `service.yaml` (client_auth, JWKS auto-detect), `roundtrip.md`.
- **`scripts/`** — les gates statiques + outils skills (`check-boundaries.sh`, `check-rls.sh`, `check-view-joins.ts`, `r2-presign.ts`, `skills-seed.ts` 13 KB, `skills-qa.ts` 24 KB, `sql-lots-runner.mjs`).
- **`tests/`** — `spine/` (2 équipes → 1 contrat), `e2e/` (Playwright + runner node), `rls-penetration.sql` (runbook DEV).
- **`docs/`** — **173 fichiers `.md`** (~196 fichiers avec HTML/CSS), organisés en 34 dossiers thématiques.
- **`_bmad-output/`** — 118 fichiers : la **chaîne d'autorité gelée** (spine, ADR v1.7, SPEC, packs 01–05, revues, rapport de readiness, journal de contexte).
- **Dossiers d'outillage/état** : `.agents` (skill pack Stitch, suivi), `.stitch` (60 fichiers d'artefacts design), `.reversa` + `_reversa_sdd` (outil d'ingénierie inverse — **annulé le 09/23**, recyclé en journal), `.codegraph` (**stale** : dit « pre-Wave-0, pas de code source »), `.dyad` (**non suivi**, état de session de l'IDE).

---

## 5. Backend & modèle de données

### 5.1 Migrations **[vérifié]**

**25 fichiers `.sql` au niveau supérieur** (`0001`…`0024` **+ `0200_aurora_wave0_schema_applied.sql`**) **+ 60 fichiers `.sql` dans `0021_lots/`** (le seed du catalogue de compétences découpé en lots) = **85 fichiers SQL**.

| Migration | Contenu |
|---|---|
| `0001_extensions_identity` | extensions (vector, pg_cron, pgcrypto), `user_context`, `set_updated_at()` |
| `0002_productivity` | projects, goals, milestones, tasks, habits, routines, focus_sessions, decisions, calendar_events |
| `0003_learning` | subjects, skills, courses, learning_sessions, flashcards, reviews, course_imports |
| `0004_knowledge` | knowledge_documents, document_chunks (**vector(768)** + hnsw + FTS gin), semantic_nodes/edges/bridges, node_state, semantic_tree_version, source_refs, notes, resources |
| `0005_progress` | progress_snapshots, progress_evidences, skill_states, progress_trends, progress_events, trajectory_scenarios, gaps |
| `0006_discovery` | discovery_items, discovery_source_profiles, domain_timeline |
| `0007_artifact` | artifacts, artifact_files (métadonnées + `r2_key` seulement) |
| `0008_agent_integrations` | agent_runs, agent_actions, expert_skills, integrations, automations, notification_preferences |
| `0009_event_history` | events_history (rétention 2 ans documentée, **non appliquée**) |
| `0010_jobs` | **job_queue** (clé d'idempotence unique) + job_logs + `notify_job_dispatcher()` SECURITY DEFINER + trigger `AFTER INSERT → pg_notify` |
| `0011_registres` | model_registry, ai_usage, ai_health (service_role uniquement, justifié) |
| `0012_public_views` | 3 vues `v_*_public` en `security_invoker = on` |
| `0013_productivity_subtasks` | subtasks (**corrige un défaut réel** : le code upsertait une table inexistante) |
| `0014_cron_placeholders` | 3 entrées `cron.job` (fsrs_tick 02:00, skill_recompute 03:00, event_dispatch */5 min) |
| `0015_powersync_relay_views` | 8 vues `v_*_scope` + GRANT SELECT à service_role |
| `0016_ascent` | ascent_paths (tout l'IR en JSONB ; le split en 4 tables est différé) |
| `0017_user_goals` | user_goals (GoalProject en un doc JSONB) + 2 vues |
| `0018_keep_alive_heartbeat` | keep_alive (1 ligne, REPLICA IDENTITY FULL) + cron `aurora_keep_alive` 00:00 |
| `0019_user_skills` | skill_catalog + user_skills + seed de 15 templates |
| `0020_expert_skills_extensions` | skill_hypotheses, contrastive_pairs, skill_validation_log |
| `0021_marketplace_skills` | **~79 600 lignes** : seed de **589 compétences marketplace** (le plus gros fichier du repo) |
| `0022_canvas` | canvas_sessions, canvas_comments |
| `0023_canvas_locked` | colonne additive `locked` |
| `0024_agent_runs_pending_plan` | colonne additive `pending_plan` jsonb (**LOT 1-bis**) |
| `0200_…schema_applied` | marqueur de suivi (ne crée rien) ; son en-tête affirme l'état live : **51 tables / 123 policies / 46 triggers / 3 extensions / 3 vues / vector(768)** **[déclaré]** |

**Verdict RLS :** toutes les tables métier sont **ENABLE + FORCE**, **sauf trois** : `keep_alive` (ENABLE seul, **zéro policy** — délibéré), `skill_catalog` et `user_skills` (**ENABLE mais pas FORCE**). L'affirmation de `0001` selon laquelle FORCE est appliqué à *toutes* les tables métier est donc littéralement fausse pour ces trois-là. À noter : le plan de finalisation signale que le `FORCE` sur `skill_catalog` **a été appliqué au live** mais **n'est pas resync dans le SSoT** — la ligne manque toujours dans le monorepo. **[vérifié]**

### 5.2 Edge Functions **[vérifié]**

**8 fonctions + `_shared`** (les docs en annoncent 6) :

| Fonction | Rôle |
|---|---|
| `fn-agent-run` | Point d'entrée de l'agent. Contrat `{intent, contextRefs, taskProfile, decisions?, resumeFrom?}`. **Rejette un `resumeFrom.pendingPlan` fourni par le client** (`agent/plan_not_accepted`). Identité **uniquement** depuis le Bearer validé auprès de `/auth/v1/user`. Crée la ligne `agent_runs` puis enfile un job `agent_run` avec `idempotency_key = agent:<agentRunId>` |
| `fn-canvas` | **Seul writer** de `canvas_*`. Verbes `read/write/comment/create/lock/rename`. Identité acceptée sur **deux canaux** : JWT device **ou** serveur-à-serveur (`x-aurora-internal` + `x-aurora-user-id`, comparaison à temps constant), fail-closed 401 |
| `fn-job-dispatcher` | **Le seul dispatcher.** Ne crée jamais de job. Lit les jobs dus par PostgREST, `route()` par `(payload.kind, payload.module)`, `claim()` pending→running, `report()` done/failed. Un job non routable **reste pending** (rien n'est perdu) |
| `fn-import-course` | `{courseId, fileRefs[]}` → 202 `{jobId}` ; l'OCR/chunk/embed lourd est un job (AD-8) |
| `fn-integrations` | Couture Composio v3.1 : `discover_tools`, `list_accounts`, `execute_tool`, `connect` ; dégrade en `integrations/not_configured` |
| `fn-skills` | Marketplace sur `skill_catalog` + `user_skills`. Verbes publics non authentifiés (dégradent proprement sans env), verbes authentifiés `activate/deactivate/create/delete`. **N'écrit jamais `skill_catalog`** |
| `fn-notifications` | Sender OneSignal REST v2 ; dégrade honnêtement (`delivered:false` + `reason`) |
| `fn-dev-auth` | ⚠️ **DEV-ONLY, auto-étiqueté « SUPPRIMER AVANT v1.0 »** : `list-users` / `set-password` / `test-signin` via l'API admin GoTrue avec `service_role`, **CORS `*`**, `verify_jwt=false` |
| `_shared/fn-agent-bootstrap.ts` (900 L) | Les coutures serveur du kernel : endpoints + catalogue modèles, Context Builder, Memory Engine, JobPort, `buildAgentKernel()`, `loadPendingPlan()`, et **`selUser(view, …)`** (helper de lecture filtrée par utilisateur — LOT 1 Story 1.3) |

### 5.3 Jobs & ordonnancement **[vérifié]**

Deux chemins de réveil : (a) le balayage pg_cron, (b) le trigger `AFTER INSERT` sur `job_queue` → `pg_notify('aurora_job_dispatcher', NEW.id)`. Le dispatcher consomme, route, écrit le résultat ; les jobs non routables restent en attente.

⚠️ **Deux SSoT concurrents pour l'ordonnancement** : `supabase/config.toml` déclare `[pg_cron]` avec **des noms et intervalles différents** (`fsrs-tick-daily 0 6 * * *`, `event-dispatch */15 * * * *`, `skill-states-recompute 0 */6 * * *`, `progress-evidences-recompute 0 4 * * *`) et **sans `keep_alive`**, alors que les migrations `0014`/`0018` déclarent les jobs réellement appliqués. Le fichier dit lui-même que ses intervalles sont des **hypothèses wave-0**. De plus : les clés `[functions.*]` utilisent des **underscores** (`fn_job_dispatcher`) alors que les dossiers utilisent des **tirets** ; 3 des 8 fonctions ne sont pas déclarées ; **il n'y a aucun bloc `[auth]`**.

---

## 6. Couche IA / Agent Kernel

**[vérifié]** Chaîne gelée (AD-4) :

```
Kernel → Context Builder → Task Classifier → AI Router → AI Policy/Budget
      → Cloudflare AI Gateway → Provider Adapter → modèle
```

- **Agnes est toujours primaire**, retour à Agnes après tout fallback ; Workers AI = 2ᵉ pool ; Groq/Cerebras/OpenRouter = optionnels ; dernier recours = Worker CF dédié **sans logique métier**.
- **AD-5** : retry seulement sur faute transitoire ; un **429 n'est jamais contourné** par rotation de clés ; chaque réponse est traçable (provider, modèle, tentative, raison, qualité attendue) via `AIResponseEnvelope`.
- **Le device ne voit jamais l'IA** (AD-3/F-09) : `fn-agent-run` crée la ligne `agent_runs`, enfile un job, et le mobile **poll le miroir local de ses `agent_runs` toutes les 3 s** jusqu'à un état terminal.
- **27 tools** (et non 8 : `agent/src/index.ts` exporte les 8 d'origine **plus 19 ajouts ultérieurs**).
- **Document tools** (4) avec deux directions strictes, jamais mélangées : TEXT→DOC = **Pandoc** (`docs.generate`) + **python-docx** (`docs.refine`) ; DOC→TEXT = **mammoth** (`docs.inspect`, .docx only) + **Docling** (`docs.parse`). Règle dure : **un générateur ne parse jamais, un lecteur ne génère jamais.**
- **Marketplace de compétences** : `skill_catalog` = 607 lignes live **[déclaré]** (18 builtin + 589 marketplace), seedé depuis `anthropic-skills/` (snapshot de curation, **pas du code applicatif**), appliqué au live par un chemin **hors migration** (`0021_lots/run-lots.mjs` + `run-lot.cjs` qui lisent `.env.local` et postent en PostgREST).

---

## 7. Front mobile

**[vérifié]** `apps/mobile/src/router.tsx` : `createBrowserRouter`, un `<Shell />` parent, **~40 entrées de route** :

- **5 onglets primaires** : `/home`, `/tasks`, `/learn`, `/progress`, `/agent`
- **Détails en overlay** : `/tasks/:id`, `/learn/:id`, `/progress/:id`, `/artifacts/:id`
- **Famille Agent** : `/agent/conversations`, `/agent/capacites`, `/agent/bibliotheque`, `/canvas/:id`
- **Familles** : `/goals` (+ `:id` + `/features/:fid` + `/ascent`), `/knowledge` (+ `:nodeId`), `/projects`, `/calendar`, `/focus`, `/discovery`, `/skills`, `/integrations`, `/habits`, `/routines`, `/reviews`, `/retro`, `/countdown`, `/inbox`, `/settings`, `/login`, `/onboarding`, `*`

**Les 8 modules « gated »** (via `<FeatureGate>`), désactivables par utilisateur et **persistés dans `user_context.features`** : `calendar, focus, knowledge, discovery, skills, integrations, inbox, canvas`. Un deep-link vers un module désactivé rend l'état « module désactivé », **jamais un 404**.

**Flux d'état — règle tenue [vérifié] :**
- **Zustand = état UI uniquement** (`ui-state.ts`, 188 L, persisté en localStorage) : onglet actif, mode de vue, thème, période, panneaux, tris… `partialize` exclut `focusActive`/`killed`. **Jamais une entité métier.**
- **TanStack Query = données**, lisant **uniquement** le store local via `packages/data` (aucun réseau sur le chemin de rendu) ; `store().watch → invalidateQueries`.
- **6 états UX** implémentés (`ux-states.tsx`, 176 L) : `loading / empty / success / error / offline / killed`, précédence `killed > offline > status`. L'état `success` est un simple wrapper (**le toaster de succès a été retiré comme code mort**).
- **Beaucoup d'états vides honnêtes** : countdown, habits, learn, discovery affichent un état vide + CTA plutôt qu'une fausse donnée quand le miroir local n'est pas câblé.

⚠️ **`apps/mobile/src/modes/` est un dossier VIDE** (0 fichier), et **aucune occurrence du mot « modes »** dans `apps/mobile/src`. La « couche modes » décrite par la doc n'existe pas en code ; le comportement est dispersé dans `ui-state.ts`, `feature-registry.ts` et `ux/feature-gate.tsx`. (`apps/mobile/dist/modes` est un artefact de build.)

---

## 8. Vérification — l'état réel des portes de qualité ⭐

C'est la partie la plus importante : **ce que la CI prétend garantir vs ce qui est vrai aujourd'hui.**

### 8.1 La porte annoncée **[vérifié]**

`AI_RULES.md` §9 + `docs/ci/gate.md` + `.github/workflows/ci.yml` :

```bash
pnpm install
pnpm -r typecheck                        # tsc --noEmit
pnpm -r lint                             # eslint --max-warnings=0
pnpm -r test                             # vitest
sh scripts/check-boundaries.sh           # G1 vendors · G2 secrets · G3 user hardcodé · G4 DOM-in-agent
sh scripts/check-rls.sh                  # forme RLS statique
node --experimental-strip-types scripts/check-view-joins.ts
node --experimental-strip-types tests/spine/spine.test.ts
node --experimental-strip-types --test apps/mobile/test/{e2e-device,focus-dpc,perf-budget,product-modes}.test.ts
```

### 8.2 Preuve n°1 — **le lint échoue sur HEAD** 🔴

```
$ node node_modules/eslint/bin/eslint.js apps/mobile/src/ux/use-horizontal-swiper.ts
  20:1  error  'motion/react' import is restricted from being used by a pattern.
              AD-10: the 5 frozen viz engines are restricted to packages/ui only
✖ 1 problem (1 error, 0 warnings)
```

Ce fichier est **commité** (le `git status` ne le liste pas comme modifié). Or `apps/mobile` déclare `"lint": "eslint src capacitor.config.ts --max-warnings 0"` → **`pnpm -r lint` échoue.** C'est une violation AD-10 réelle et non détectée au moment du commit.

### 8.3 Preuve n°2 — **le typecheck échoue sur HEAD** 🔴

```
$ node node_modules/typescript/bin/tsc --noEmit -p apps/mobile/tsconfig.json
apps/mobile/src/feature-registry.ts(306,48)   TS2322  boolean | undefined → boolean
apps/mobile/src/feature-registry.ts(307,50)   TS2322  boolean | undefined → boolean
apps/mobile/src/lib/user-context-client.ts(53,29)   TS2339  'user' does not exist
apps/mobile/src/lib/user-context-client.ts(84,31)   TS2339  'user' does not exist
apps/mobile/src/pages/agent/conversations.tsx(95,9) TS2322  data: AgentRunRow[] | undefined
apps/mobile/src/pages/goals/index.tsx(159,36)       TS2345  string | undefined → string
apps/mobile/src/pages/home/index.tsx(105,34)        TS18048 'goals' is possibly 'undefined'
apps/mobile/src/pages/onboarding/index.tsx(53,50)   TS2345  Session | null
EXIT=1
```

C'est **exactement la commande que le script `typecheck` de `apps/mobile` exécute**, et c'est la commande que la CI lance (`pnpm -r exec tsc --noEmit`). 8 erreurs dans 6 fichiers tous commités. **`pnpm typecheck` échoue donc à la racine.**

### 8.4 Preuve n°3 — **les frontières ESLint ne couvrent pas les `.tsx`** 🔴

Sonde décisive (même import interdit, deux extensions) :

```
$ 'import { motion } from "motion/react";' | eslint --stdin --stdin-filename apps/mobile/src/Probe.tsx
   → 0 erreur, exit 0
$ 'import { motion } from "motion/react";' | eslint --stdin --stdin-filename apps/mobile/src/Probe.ts
   → 1 erreur AD-10, exit 1
```

**Cause [vérifié]** : tous les blocs de `eslint.config.js` ciblent `**/*.ts` — **jamais `**/*.tsx`**. Conséquences mesurées :

| Zone | `.ts` | `.tsx` | Couvert par les règles de frontière ? |
|---|---|---|---|
| `apps/mobile/src` | 28 | **48** | ❌ les 48 `.tsx` (donc toutes les pages/composants) |
| `packages/ui` | 22 | **58** | ❌ les 58 `.tsx` (donc le design system) |
| `packages/{data,platform,integrations,scientific-engine,productivity,learning,progress,discovery,focus,goal-engine,ascent,workflows,engineering-*}` et `apps/server` | — | — | ❌ **aucun bloc ESLint n'existe pour eux** |

Il y a donc **deux trous cumulés** : (a) l'extension `.tsx` échappe partout, (b) 13 des 19 packages + `apps/server` n'ont aucune règle de frontière du tout. Le seul filet restant pour AD-1 est le grep G1 de `check-boundaries.sh`, qui **ne couvre pas les moteurs AD-10** (il ne cherche que les vendors). Donc **`AI_RULES.md` §7 « les 5 moteurs ailleurs = CI-rouge » est faux dans les faits.**

### 8.5 Preuve n°4 — les gates ne sont pas exécutables dans cet environnement

- `sh scripts/check-boundaries.sh` → **échec MSYS** : `fatal error - NtCreateDirectoryObject(...): 0xC0000022` (les objets partagés MSYS sont bloqués par le sandbox).
- `node --experimental-strip-types --test "test/*.test.ts"` (dans `packages/focus`) → **`spawn EPERM`** ×3 : le runner natif de Node spawn des enfants avec pipes, ce que le sandbox interdit.
- `pnpm -v` ne répond pas en < 120 s ici.

**Conséquence honnête :** je **ne peux pas** confirmer le chiffre « 236 tests / 0 échec » annoncé par `AI_RULES.md` **[déclaré]**. En revanche, `tsc` et `eslint` — exécutés comme **processus uniques** — ont fonctionné, ce qui rend les preuves 8.2 et 8.3 solides.

### 8.6 Récapitulatif : porte annoncée vs porte réelle

| Étape | Annoncée | État réel mesuré |
|---|---|---|
| `pnpm -r typecheck` | ✅ passe | ❌ **échoue** (8 erreurs, `apps/mobile`) |
| `pnpm -r lint` | ✅ passe, `--max-warnings=0` | ❌ **échoue** (1 erreur AD-10 commitée) |
| `pnpm -r test` / vitest | ✅ 236 tests | ⚠️ **non exécutable ici.** Surtout : **seul `packages/ui` a un `vitest.config.ts`** ; 17 packages utilisent `node --test` et **4 packages n'ont aucun test** (dont `domain`, le SSoT) |
| `check-boundaries.sh G1–G4` | ✅ | ⚠️ non exécutable ici ; **G1 ne couvre pas AD-10** ; G2/G3/G4 = greps étroits |
| `check-rls.sh` | ✅ | ⚠️ **(a)** passe si *une* migration contient un `ENABLE RLS` **n'importe où** et que le nom de table apparaît **quelque part** → quasi tautologie ; **(c)** `FORCE RLS` = **WARN, non bloquant** |
| `check-view-joins.ts` | ✅ | ⚠️ **ignore tout `.sql` dont le chemin ne nomme pas 1 des 10 modules** |
| `tests/spine/spine.test.ts` | ✅ gate AD-15 | ⚠️ les imports `@aurora/domain` sont **commentés** → prouve que deux structures *locales* s'accordent |
| `apps/mobile/test/product-modes.test.ts` | ✅ référence | ❌ **le fichier n'existe pas** (le dossier contient `canvas-client, canvas-tools, e2e-device, feature-flags, focus-dpc, perf-budget, release-gate`). `ci.yml` l'ignore via `hashFiles` ; **`release.yml` le lance sans garde → un tag `v*` échouerait** |
| `vitest.config.ts` racine | implicite | ❌ **absent** → l'étape « Tests (vitest) » de `ci-gate` ne s'exécute jamais |
| Étape « Build » | build | ⚠️ **c'est le typecheck répété** (`tsc --noEmit`) — aucun build réel |
| Tag `v0.1.0` | « le tag existe déjà » | ❌ **`git tag` ne renvoie rien** |

---

## 9. Dette documentaire & incohérences

Le projet a une **architecture documentaire à deux étages assumée** (autorité gelée + `AI_RULES.md`/changelog « vivants »). Le problème : **l'étage vivant est lui-même périmé**, et l'étage gelé contient encore des affirmations « pas de code » dans au moins 5 fichiers.

| # | Affirmé | Réel [vérifié] | Gravité |
|---|---|---|---|
| 1 | « 24 migrations appliquées (0001…0023) » | **25 `.sql`** au niveau supérieur (`0001…0024` **+ `0200`**) **+ 60 lots** sous `0021_lots/` | Moyenne |
| 2 | « 6 Edge Functions » | **8** (+ `fn-notifications`, `fn-dev-auth`) + `_shared` (qui contient `fn-agent-bootstrap.ts`, pas seulement `envelope`) | Moyenne |
| 3 | `AI_RULES` §9 liste `apps/mobile/test/product-modes.test.ts` | **n'existe pas** → `release.yml` échouerait à un tag | **Haute** |
| 4 | « 19 packages + 2 apps » | ✅ **vrai** | — |
| 5 | « 8 kernel tools » | **27** fonctions d'outil exportées | Basse |
| 6 | « 9 contrats AI-pipeline » | **8** (et `domain/src/index.ts` dit « 8 » deux fois) | Basse |
| 7 | « `packages/engineering-*` = Problem IR + 6 registres + validation » | **3 stubs de 5 lignes** ; le contenu est dans `scientific-engine` | Moyenne |
| 8 | `router.tsx` s'auto-décrit « 17-page router / inventaire gelé de 17 pages » | **~40 routes / ~30 pages** ; 11 routes absentes de la liste « gelée » | Moyenne |
| 9 | `docs/ci/gate.md` nomme `tests/spine/equipe-{a,b}.test.ts` | les fichiers sont `equipe-{a,b}.contract.ts` | Basse |
| 10 | Le « spine test » comme gate AD-15 | imports `@aurora/domain` **commentés** (squelette) | **Haute** |
| 11 | `apps/server` = « Edge Functions + Cloudflare Workers » | **stub de 6 lignes**, `dist/` vide commité, aucun SDK vendor en dépendance | Moyenne |
| 12 | La doc décrit une couche « modes » | `apps/mobile/src/modes/` est **vide**, 0 référence à « modes » | Basse |
| 13 | « 236 unit tests pass / 0 fail » | **[déclaré]** non vérifiable ici ; les seuls compteurs in-tree sont `agent 112 / discovery 15 / productivity 16` | Moyenne |
| 14 | Tag `v0.1.0` | **aucun tag dans le repo** | Moyenne |
| 15 | `config.toml [pg_cron]` = 4 jobs | **contredit** les migrations `0014`/`0018` (noms, intervalles, `keep_alive` absent) → **2 SSoT concurrents** | Moyenne |
| 16 | `AI_RULES` : RLS FORCE sur toutes les tables métier | 3 exceptions (`keep_alive`, `skill_catalog`, `user_skills`) ; le `FORCE` live de `skill_catalog` **n'est pas resync dans le SSoT** | Basse |
| 17 | `.codegraph/status.json` : « pre-Wave-0, pas de code source » | 19 packages + 2 apps existent ; son propre trigger de re-vérification a expiré | Basse |
| 18 | `docs/architecture/gap-register.md`, `docs/testing/matrix.md`, `_reversa_sdd/inventory.md` : « pas de code applicatif » / « tests non exécutables » | idem — baseline périmée | Basse |
| 19 | `tests/spine` + `gap-register` | `AI_RULES` ne nomme pas ces fichiers dans son avertissement de doc-lag : il ne le signale que de façon générique | Basse |

**Structure du changelog [vérifié]** : `docs/release/changelog.md` (84 lignes) n'a qu'**une seule section de release** (`## Upcoming (v0.1.0)`) et un « Wave history » qui est explicitement *un miroir du git log, pas des release notes*. Le contenu des release notes s'arrête aux waves 5 et 7 — **les waves 6 (deep review) et l'essentiel de 7 n'y sont pas**.

---

## 10. Travail en cours

### 10.1 LOT 1 / LOT 1-bis — durcissement du kernel ⭐ **[vérifié dans le code]**

Derniers commits de la branche `lot-1/kernel-safety` :

| Commit | Story | Contenu |
|---|---|---|
| `667ebb3` | LOT 1 / 1.1 | **Confirmation gating** : décisions normalisées, vocabulaire fermé, entrées invalides écartées — **jamais d'auto-confirmation** |
| `1678701` | LOT 1 / 1.2 | Propagation du JWT utilisateur `fn-agent-run → fn-canvas`, **fail-closed** |
| `618ebba` | LOT 1 / 1.3 | `selUser(view, …)` : **les lectures de contexte sont filtrées par utilisateur à la base** |
| `3dd6661` | LOT 1-bis / 1.1-bis | **Reprise serveur** : colonne additive `agent_runs.pending_plan` (`0024`), hash `computeStepHash` **lié au contenu** ; une décision n'est honorée que si le hash correspond ; un `pendingPlan` forgé dans le body → rejet ; la reprise d'un run d'un autre utilisateur → 404 |
| `753fdcb` | LOT 1-bis / 1.2-bis | **Second canal serveur-à-serveur** pour `fn-canvas` : header `x-aurora-internal` + `INTERNAL_FN_SECRET` (env seulement), comparaison à temps constant, 401 fail-closed ; le canal device (JWT) reste inchangé ; test concurrent prouvant que deux runs de deux utilisateurs ne fuient pas |

**⚠️ Ce travail est sous-documenté au regard de son risque :**
- **Aucun document de plan** n'existe : « kernel-safety » n'apparaît **nulle part** dans le repo, et « LOT 1 / LOT 1-bis » n'a **qu'une seule occurrence en Markdown** (`supabase/manual-secrets-checklist.md:48`).
- **Action opérationnelle pendante** : définir `INTERNAL_FN_SECRET` (~32+ caractères, jamais dans le repo) et **redéployer `fn-canvas` + `fn-job-dispatcher`**.
- Le plan de finalisation (`G1`) dit que **les 6 EF ne sont pas déployées** : le code déployé sur Supabase serait une **édition antérieure**, et le runtime Deno **ne voit pas `packages/*`**. C'est **le point d'attention n°1 du projet** : tout ce durcissement peut être *écrit et testé en local* sans être *actif en production*.

### 10.2 Design system WIP **[vérifié]**

- Commit `812b88a` (10-09) : « Design system WIP: dynamic theming calendar + focus/home page cleanup » — introduit `useDynamicTheme.ts`, `focus-service.ts`, `dynamic-theme.css` (thématisation dynamique à partir de la couleur dominante d'une image de fond).
- **1 fichier encore non commité** : `apps/mobile/src/pages/calendar/index.tsx` (**775 insertions / 729 suppressions**) — refonte lourde de la page calendrier en cours.

### 10.3 Les trois « trackers » se contredisent **[vérifié]**

| Source | Ce qu'elle dit être en cours |
|---|---|
| `docs/plans/finalisation-v1.md` (10-07) | 7 phases, ≈17 j·homme, **quasiment toutes les cases `[ ]` ouvertes**, G1 = « 6 EF non déployées » |
| `.dyad/todos/54.json` + plan chat-54 | lot PRD-3 `/agent` **terminé** ; « comptes à rebours » en parking |
| `progress/CLAUDE.md` | **2 cases ouvertes seulement** (Canvas wave 2, RLS live positive) |

**Aucun des trois ne mentionne le travail LOT 1-bis daté du 10-09.** Un lecteur ne peut pas savoir lequel fait autorité pour « ce qui est en cours aujourd'hui ».

---

## 11. Risques classés

### 🔴 Critique
1. **La porte de qualité ne passe pas sur HEAD** (typecheck + lint rouges). Le projet croit être « CI-vert » sans l'être — ce qui invalide la garantie AD-13 « main toujours buildable ».
2. **Le durcissement sécurité du kernel (LOT 1-bis) n'est probablement pas déployé.** Un secret partagé + un canal d'authentification serveur-à-serveur existent en code, mais le plan indique que les EF live sont une version antérieure. Le risque est un **faux sentiment de sécurité**.
3. **`fn-dev-auth` est une porte dérobée de dev** (listage d'utilisateurs via service_role, reset de mot de passe, `CORS *`, `verify_jwt=false`) qui **doit être supprimée avant tout tag** — c'est écrit dans son propre en-tête et dans le plan (P6-6), mais elle est toujours dans le tree.

### 🟠 Haute
4. **Enforcement des frontières aveugle sur `.tsx` + 13 packages sans règles** : AD-1/AD-6/AD-10 ne sont pas réellement garantis, alors qu'ils sont présentés comme « CI-rouge sinon ».
5. **Le gate AD-15 (`tests/spine`) est un squelette** (imports commentés) — il donne l'illusion d'une vérification du SSoT.
6. **`check-rls.sh` quasi tautologique et FORCE non bloquant** : la seule preuve RLS réelle est un **runbook manuel** (`tests/rls-penetration.sql`) qui n'est pas automatisé.
7. **Double SSoT d'ordonnancement** (`config.toml` vs migrations) : risque de divergence silencieuse des jobs.
8. **`release.yml` échouerait à un tag `v*`** (fichier de test inexistant, lancé sans garde) ; et « Build APK » n'est en réalité qu'un `tsc --noEmit`.

### 🟡 Moyenne
9. **Doc-lag à deux étages** : l'étage « vivant » est périmé sur des chiffres durs ; l'étage gelé porte encore « pas de code ».
10. **`skill_catalog`/`user_skills` non FORCE RLS dans le SSoT** (appliqué au live, non resync).
11. **`apps/server` est un stub commité avec son `dist/` vide** : fausse piste pour tout nouveau contributeur.
12. **`domain` n'a aucun test** alors qu'il est le SSoT dont 18 packages dépendent.
13. **3 packages `engineering-*` morts** mais référencés par le `tsconfig` racine et des deps déclarées.

### 🟢 Basse
14. `packages/productivity/src/eisenhower.ts` n'est **pas de l'UTF-8 valide** (un octet `§` en Latin-1 à l'offset 5265) — fragile pour tout outil strict.
15. `agent/src/prompt.ts` n'est pas exporté par le barrel (atteignable seulement via `model.ts`).
16. Le cycle `engineering-adapters ↔ scientific-engine` et l'arête morte `platform → @aurora/domain`.
17. `.codegraph`, `gap-register`, `testing/matrix`, `_reversa_sdd` portent des baselines périmées.
18. Résidus : `hs_err_pid*.log` (3 crash logs JVM), `replay_pid*.log`, 6 PNG de debug à la racine, `apps/mobile/dist/` commité.

---

## 12. Guide de démarrage rapide

**Ordre de lecture recommandé (de l'essentiel vers le détail) :**

1. `AI_RULES.md` — la carte « vivante » : réalité, carte de décisions, invariants, roster d'agents, la porte. **Lire le §1 « Reality check » en premier** — puis vérifier ses chiffres avec ceux du §9 de ce rapport.
2. `_bmad-output/architecture/…/ARCHITECTURE-SPINE.md` — les 17 invariants gelés (264 lignes, très dense, très bon).
3. `packages/domain/src/` — 22 fichiers : c'est le vocabulaire du projet. Commencer par `ports.ts`, `events.ts`, `index.ts`.
4. `packages/agent/src/kernel.ts` + `index.ts` (la carte des 15 composants) + `tools.ts`.
5. `apps/mobile/src/router.tsx` — l'inventaire réel des écrans (et l'écart avec la doc).
6. `supabase/migrations/0002` … `0010` — le modèle de données et le pattern RLS ; `0010_jobs` pour l'asynchrone.
7. `docs/plans/finalisation-v1.md` — l'état des lieux de finalisation (le seul doc qui liste honnêtement les gaps) + `supabase/manual-secrets-checklist.md` pour LOT 1-bis.

**Avant de toucher au code, savoir que :**

- `domain` **n'importe rien** (et c'est vérifié par ESLint + le gate) → tout type partagé y va.
- `ui` ne peut pas importer `data`/`platform` ; `data` est le **seul** endroit pour `@supabase/*` et `@powersync/*` ; `platform` le seul pour `@capacitor/*` ; `agent` le seul pour `ai`/`@ai-sdk/*` ; `ui` le seul pour les 5 moteurs AD-10. **Mais ces règles ne s'appliquent pas aux `.tsx`** → ne pas s'y fier pour se croire protégé (§8.4).
- **Ne jamais écrire directement dans une table SQLite** (single-writer AD-7) : émettre une commande/événement, le module propriétaire applique.
- **1 story = 1 commit = 1 rollback.**
- Les secrets vivent dans `.env.local` (**gitignoré**) et dans les secrets GitHub Actions ; `set-secrets.ps1` pousse le contrat.

**Commandes utiles (sachant que `sh` et le runner Node natif sont bloqués dans ce sandbox Windows) :**

```bash
pnpm install
pnpm -r typecheck                  # ⚠️ échoue aujourd'hui sur apps/mobile
pnpm -r lint                       # ⚠️ échoue aujourd'hui (1 erreur AD-10)
node node_modules/typescript/bin/tsc --noEmit -p apps/mobile/tsconfig.json   # reproduit la preuve §8.3
node node_modules/eslint/bin/eslint.js apps/mobile/src/ux/use-horizontal-swiper.ts  # reproduit §8.2
git log --oneline -5               # état réel des livraisons
```

---

## 13. Conclusion — faut-il faire confiance à ce projet ?

**Oui sur le design, non sur la preuve.**

Ce qui est **excellent et réellement en place** : un hexagone propre vérifié par extraction d'imports (`domain` sans dépendance, `ui` pur, vendors confinés), un SSoT unique de types, 9 événements fermés et un producteur par entité, un modèle RLS ENABLE+FORCE quasi systématique, un dispatcher de jobs idempotent avec deux chemins de réveil, un Agent Kernel serveur unique avec `AgentRunState` comme seule surface device, des états UX honnêtes (vides plutôt que fausses données), et un travail de durcissement sécurité (LOT 1-bis) de bonne facture.

Ce qui **doit être traité avant toute confiance de niveau production** :
1. rendre la porte verte (typecheck + lint) — sinon « main buildable » est un slogan ;
2. élargir les règles ESLint aux `.tsx` **et** aux 13 packages non couverts — sinon AD-1/AD-10 sont des intentions ;
3. déployer réellement les EF + `INTERNAL_FN_SECRET`, sinon le durcissement du kernel n'existe qu'en local ;
4. supprimer `fn-dev-auth` et réparer `release.yml` avant tout tag ;
5. corriger le doc-lag (chiffres durs, `product-modes.test.ts`, tag `v0.1.0`, baselines « pas de code »).

Les points 1 à 3 sont, de loin, les plus rentables : ils transforment une architecture *déclarée* en architecture *prouvée*.
