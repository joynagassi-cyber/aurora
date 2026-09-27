# Changelog project-context.md

## v1.9 — 2026-09-27 (pg_cron 0014+0018 live — audit de falsification corrigé)

- **Audit pg_cron 0014/0018** : les 3 jobs aurora du 0014
  (`aurora_fsrs_tick`, `aurora_skill_recompute`, `aurora_event_dispatch`)
  **n'étaient PAS au live** — l'ancienne vérification lisait les jobs
  `generate-ai-post-*` d'une autre instance du dashboard partagé
  (fals positif). Corrigé par l'application via `SELECT cron.schedule(…)`
  (le chemin INSERT direct échouait sur le GRANT du rôle MCP) :
  `jobid 7 aurora_keep_alive '0 0 * * *'` (0018), `jobid 8
  aurora_fsrs_tick '0 2 * * *'`, `jobid 9 aurora_skill_recompute
  '0 3 * * *'`, `jobid 10 aurora_event_dispatch '*/5 * * * *'` (0014).
  Commits : `70ddff7` (0018 SSoT + annotations 0014 + heartbeat),
  `58cddd6` (merge ORACLE résiduel), `180c3bc` (docs alignées).
- **§Wave 1 (W1-E3)** : le job system end-to-end passe à l'état
  « scheduler en place » — les 3 jobs 0014 + 1 heartbeat 0018 sont
  actifs au live DEV ; reste à exécuter le test de dispatch (job
  créé par le cron → claim → résultat, idempotence vérifiée).

## v1.8 — 2026-09-26 (Scaffolding wave 0 ratifié : layout réel = 16 packages + 2 apps)

- **Layout ratifié** (OQ-01 ré-amendé) : le pnpm workspace réel contient
  **16 packages + 2 apps** — 9 originels (domain, data, ui, platform,
  agent, scientific-engine, integrations, apps/mobile, apps/server) +
  4 G-D12 (engineering-core/solvers/adapters/registry) + 4 équipes
  module-owner wave 2 (learning, productivity, progress, discovery,
  focus). Les 4 derniers + `engineering-registry` sont des additifs
  non ratifiés par l'OQ-01 original (qui ne mentionnait que 3
  engineering packages) — ré-ratification notée ici.
- **§1 État du projet** : `DESIGNED_NOT_IMPLEMENTED` → `IMPLEMENTING`
  (~15k lignes de code réelles) ; vague courante = wave 1 (PowerSync
  live) + wave 2 modules en parallèle.
- **§2 Monorepo** : ajout de la convention module-owner (OQ-02) :
  chaque équipe possède `packages/{module}` (implémentation wave 2+)
  ; le SSoT des types reste `packages/domain` (AD-15) — un module
  **consomme** les types, n'en crée jamais.
- **§4 Gate OQ-01** : marquée **ré-ratification nécessaire** (le
  layout réel inclut 4 packages module-owner + engineering-registry,
  absents de l'OQ-01 original).
- Impact : le wave 3 (kernel + Ascent) peut démarrer **sans**
  attendre cette ré-ratification (ne bloque que les additions de
  nouveaux packages, pas l'implémentation des features existantes).

## v1.7 — 2026-09-26 (PowerSync déployé sur Aurora Dev + secret GitHub)

- `PS_ADMIN_TOKEN` (nuevo, `jpt_eyJpIjoiNmFiNzRm…`) enregistré dans
  `.env.local` + poussé en secret GitHub `joynagassi-cyber/aurora`
  (`gh secret set PS_ADMIN_TOKEN`, via fichier temporaire — jamais échoé).
  L'ancien token (`jpt_eyJpIjoiNmFiMzJh…`) = instance `6ab32ad1…`,
  org non-cible ; le nouveau est lié à l'instance `6ab74f03…` et couvre
  **l'org Aurora** (`6ab1609e…`) : les deux instances `6ab1612e…` (dev)
  et `6ab1612f…` (prod) y sont visibles.
- `powersync deploy` sur **Development** `6ab1612e8453e7cf8338ef9a` :
  « Deployment operation completed successfully ».
  - Replication slot `powersync_6ab1612e8453e7cf8338ef9a_1_811d` actif,
    lag 0 bytes, initial replication done.
  - ⚠️ **Anomalie résolue** : le status de post-deploy signale
    `replication_id: —` + warning « Table public.<X> not found » —
    disparu au re-statut de 05:08 UTC : le relay a rafraîchi son
    catalog (les 29 tables sont désormais rattachées, slot
    `powersync_6ab1612e8453e7cf8338ef9a_1_811d`, lag 0 bytes).
    Aucune action requise ; re-vérifier au prochain `powersync
    status` si les warnings reviennent.
- DoD wave 1 « PowerSync relay opérationnel » (03 §8.1) = **déployé**,
  reste à exécuter le test round-trip (`powersync/test/roundtrip.md`)
  dès qu'un user Supabase Auth + un client PowerSync sont prêts.
- 0014 (pg_cron jobs) : toujours non appliquée au live (idem v1.5) —
  à faire via le dashboard Supabase.

## v1.6 — 2026-09-26 (Gaps G-M1/M2/M3/M4/M5 fixés en spec, G-L2 tracké en épique)

- **G-M1** (wrapper AnimationController absent) : pack 05 S3.6.13 ajoute `AnimationSlot` + `useAuroraAnimation` (5ᵉ contrat AD-10) — à écrire dans `packages/ui` au cut G1 wave-1 (W0-E2-1).
- **G-M2** (killed app = 6ᵉ état UX implicite) : `killed` ajouté **sous-état de `loading`** (pas un 6ᵉ canonique) — pack 02 S7 (bloc « Sous-état `killed` (G-M2, figé 2026-09-26) ») + pack 05 S3.7 (row `AnimationSlot` + note colonne `killed`) ; pattern SSoT = `docs/ui-libraries.md` n°185 (Skeleton + auto-resync, « Reconnexion… » + shimmer) ; test DoD wave 1 = pack 03 S5.9 « kill-app relaunch = état intact ».
- **G-M3** (AppError SSoT split) : owner tranché = `packages/domain` (AD-15) ; pointer comment déjà présent en pack 01 S3.1 + pack 02 S10 (docs seulement, l'app **importe**, ne redéfinit pas) ; **types à écrire au W0-E1-2 (Foundation)** — pas de code dans ce batch.
- **G-M4** (job_queue SSoT split) : shape complet déjà gelé en pack 01 S5.3 (lines 260-284 : `id` ULID, `user_id`, `kind`, `payload`, `status`, `attempts`, `max_attempts`, `backoff_ms`, `due_at`, `idempotency_key` avec commentaire `source_local_mutation_id`, `result`, timestamps) ; pack 03 S5.5 **pointe seulement** (01 §5.3 `idempotency_key` + `source_local_mutation_id`, lines 370-373) — aucune re-déclaration détectée ; **register fermé, aucune action résiduelle**.
- **G-M5** (ChartSpec SSoT undecided) : owner tranché = `packages/ui` ; shape minimal publié en pack 05 S3.6.12 (bloc « `ChartSpec` — SSoT publié (G-M5, tranché 2026-09-26) ») : `ChartKind` fermé (4 kinds : `bar-planned-vs-actual`, `time-series`, `distribution`, `comparison`) ; `focusBilan` (§3.6.9) = instanciation `bar-planned-vs-actual` ; règle fidèle §2.6 n°1 (pas d'animation compteur, données ≠ effet) ; fallback = `DataTable`/`KeyValueList` si moteur échoue (AD-8 : capacité absente dégrade, ne casse pas) ; **à écrire dans `packages/ui/src/chart/ChartSpec.ts` au W0-E2-1**.
- **G-L2** (49 mockups non produits) : annoté, **pas fermé** — 1 exemple fait (Lagoon×Focus en pack 05 S5.7) ; les 48 restants = deliverable wave-0 Dyad/UI, **tracké comme `W0-E2-2` (XL) dans `docs/epics-stories.md`** (owner Dyad/UI, déjà dans l'index du register) — le register ne promet pas la complétion, seulement la traçabilité.
- Le register de gaps (`docs/architecture/gap-register.md`) : G-M1..G-M5 → statut **RESOLVED 2026-09-26** (actions résiduelles notées ci-dessus) ; G-L2 → statut **ANNOTÉ** (tracé, pas complété).

## v1.6 — 2026-09-26 (Gaps G-M1/M2/M3/M4/M5 fixés en spec, G-L2 tracké en épique)

- **G-M1** (wrapper AnimationController absent) : pack 05 S3.6.13 **ratifie** `AnimationSlot` + `createAnimationController` (le hook `useAuroraAnimation` = extension optionnelle, non normativement exigée par le pack 05) — **code SSoT déjà en place** à `packages/ui/src/renderers/AnimationController.tsx` (verdict G-M1 en commentaire de source, lines 3/81/236).
- **G-M2** (killed app = 6ᵉ état UX implicite) : `killed` ajouté **sous-état de `loading`** (pas un 6ᵉ canonique) — pack 02 S7 (bloc « Sous-état `killed` (G-M2, figé 2026-09-26) ») + pack 05 S3.7 (row `AnimationSlot` + note colonne `killed`) ; pattern SSoT = `docs/ui-libraries.md` n°185 (Skeleton + auto-resync, « Reconnexion… » + shimmer) ; test DoD wave 1 = pack 03 S5.9 « kill-app relaunch = état intact ».
- **G-M3** (AppError SSoT split) : owner tranché = `packages/domain` (AD-15) ; pointer comment déjà présent en pack 01 S3.1 + pack 02 S10 (docs seulement, l'app **importe**, ne redéfinit pas) ; **code SSoT déjà en place** à `packages/domain/src/envelopes.ts` (`AppError` + `AppErrorCode`, lines 33-42, G-M3/C-3 comment).
- **G-M4** (job_queue SSoT split) : shape complet déjà gelé en pack 01 S5.3 (lines 260-284) ; pack 03 S5.5 **pointe seulement** (01 §5.3 `idempotency_key` + `source_local_mutation_id`, lines 370-373) ; **code SSoT déjà en place** à `packages/domain/src/jobs.ts` (`JobQueue.sourceLocalMutationId` line 47, G-M4 comment) — aucune re-déclaration détectée.
- **G-M5** (ChartSpec SSoT undecided) : owner tranché = `packages/ui` ; shape **ratifié** = le `ChartSpec` déjà en `packages/ui/src/themes/types.ts` (lines 164-188 : `id` dédié fermé + `type` bar/line/area/pie/radar/heatmap, `series[].values[] {label, value, unit}`, `animateValues`, `palette`, `labels`) ; ré-export via `packages/ui/src/renderers/contracts.ts` line 163 ; **code SSoT déjà en place**. Règles fidèle §2.6 n°1 (pas d'animation compteur) ; le set des `id` ratifiés = fermé comme le vocabulaire AD-9 (nouvel `id` = ADR additif).
- **G-L2** (49 mockups non produits) : annoté, **pas fermé** — 1 exemple fait (Lagoon×Focus en pack 05 S5.7) ; les 48 restants = deliverable wave-0 Dyad/UI, **tracké comme `W0-E2-2` (XL) dans `docs/epics-stories.md`** (owner Dyad/UI) — le register ne promet pas la complétion, seulement la traçabilité.
- Le register de gaps (`docs/architecture/gap-register.md`) : G-M1..G-M5 → statut **RESOLVED 2026-09-26** (code SSoT déjà aligné sur le docs) ; G-L2 → statut **ANNOTÉ** (tracé, pas complété).

## v1.5 — 2026-09-26 (PowerSync wave 1 : schéma live + sync config prêts, déploiement bloqué sur le token)

- Gap supabase live comblé : `subtasks` (0013, manquante) créée ; les 8 vues
  `v_*_scope` (relay.sql) créées + GRANT service_role ; `publication powersync
  FOR ALL TABLES` existait déjà (0001). 0014 (pg_cron jobs) **pas appliqué** :
  `permission denied` sur `cron.job` pour le rôle du MCP — à faire via le
  dashboard Supabase (ou un rôle avec GRANT sur le schéma cron).
- New `supabase/migrations/0015_powersync_relay_views.sql` (fichier de
  tracking additif ; relay.sql reste le SSoT) — à appliquer au live quand le
  compte Supabase aura le droit cron.
- PowerSync Cloud : instance **Development** `6ab1612e8453e7cf8338ef9a`
  (Aurora org `6ab1609e88083500079d0b68`, project `6ab1612d6860dd00071fcc98`,
  region eu) confirmée = l'instance derrière `POWERSYNC_URL` du `.env.local`.
  `powersync pull instance` OK : cli.yaml + service.yaml écrits.
- `powersync/service.yaml` : `client_auth.supabase: true` (JWKS auto-détecté
  depuis l'URI de réplication, audience `authenticated`, RS256/ES256 du
  projet opagfyspdbhxthlxvlrk — cf `SUPABASE_JWKS_URL`).
- `powersync/sync-config.yaml` : 10 flux Sync Streams (edition 3) générés,
  1 flux = 1 module owner (F-03, pas de cross-module JOIN), per-table
  (pas de UNION ALL), `WHERE user_id = auth.user_id()` (RLS via
  service_role + policies `user_id = auth.uid()`, AD-16), auto_subscribe,
  priorité 1/2/3 (identity / core / bulk, OQ-11 + invariant Home AD-14),
  exclusions server-only respectées (03 §4.2).
- ~~**BLOCANT** : le `PS_ADMIN_TOKEN` actuel du `.env.local` est lié à
  l'org `joynagassi-cyber`~~ → **corrigé (ratifié 2026-09-26)** : le
  `PS_ADMIN_TOKEN` du `.env.local` EST le token PowerSync Cloud de l'org
  **Aurora** (celui du projet). `powersync deploy` exécuté avec succès
  (slot `..._2_4761`, validation OK) ; l'org `joynagassi-cyber`
  correspond aux instances Lumina, sans lien avec le token Aurora.

## v1.4 — 2026-09-26 (Ascent rattaché au Feature Registry + Epic W3-E2)

- Standup wave-0 Freya (ratifications sous délégation Joy) : OQ-01 pnpm layout
  (9 packages + 2 apps, G-D12 inclus), OQ-02 team column, OQ-03 env values
  (placeholder, structure AD-16a fixée), OQ-17 DPC (condition device), G-M7
  Feature Registry (design complet, types AD-15, chaîne + effets désactivation +
  6 modes produit).
- **Rattachement Ascent RATIFIÉ** : Ascent = feature `ascent` dans le
  Feature Registry (G-M7) ; tables `ascent_*` server-only (AD-3, comme
  `expert_skills`) ; ports consommateurs = Knowledge/Progress/Discovery/
  ObjectiveManager + `FeatureRegistry` (docs/ascent/overview.md S7) ;
  S-37 UNRECONCILED tranché (`progress-dashboard` ≡ S-13 `/progress`, ne pas
  dupliquer).
- `docs/epics-stories.md` : patch 09/26 appliqué (4 splits + 3 FR + W3-E2
  Ascent : W3-E2-1 engine core + W3-E2-2 agent capability + Slide-Ascent
  S-41) ; total 67 stories.
- §Wave 3 DoD : ajout Ascent (W3-E2) — `AscentLearningIR` data-only, tables
  server-only, Slide-Ascent lecture seule via PowerSync, feature `ascent`
  dans le Feature Registry.

## v1.2 — 2026-09-26 (vérification + traçabilité Supabase post-wave 1)

- Vérif live Supabase MCP : les 12 migrations wave 0 sont **complètement
  appliquées** (51/51 tables, 51/51 RLS+FORCE, 123/123 policies, 46 triggers,
  3 extensions, 2 fns, 8 index, 3 vues + GRANTs, type aurora_theme,
  vector(768) gelé, 5 policies permissives = exactement les 5 justifiées).
- Gap résolu : tracker live n'avait que les ~150 migrations legacy. Ajout du
  marker additif `0200_aurora_wave0_schema_applied` (version live
  `20260925234343`) + fichier local `supabase/migrations/0200_aurora_wave0_schema_applied.sql`.
- §7 pointeur retiré (plus de pending).

## v1.3 — 2026-09-26 (test d'intrusion RLS live — wave 1)

- Test de pénétration RLS live effectué via MCP (users A `joynagassi` + B `joydatininagassi`, 4 tables seedées).
- Résultat **A vs B (authenticated)** : isolement complet confirmé — B ne voit ni ne peut
  écrire les lignes d'A (goals/tasks/notes/user_context) ; INSERT de B sur une ligne A
  rejeté par la policy (42501), UPDATE = 0 ligne modifiée. DoD wave 1 « test pénétration
  RLS passe » = coché.
- Anomalie observée (artefact de simulation MCP, NON un bug RLS) : en `SET ROLE service_role`
  + `SET request.jwt.claims`, un SELECT voit toutes les lignes alors que
  `auth.uid()` renvoie bien le sub attendu. Cause probable : `service_role` a
  `rolbypassrls=true` ; en Postgres, FORCE RLS borne les BYPASSRLS seulement si les
  policies du rôle s'appliquent — avec claims nuls (service_role n'a JAMAIS de JWT en prod),
  `auth.uid()` = NULL et aucune policy bornée ne s'applique. Conséquence réelle :
  **le relay PowerSync doit tourner avec les claims du user demandé** (ce qu'il fait via
  Supabase Auth service key + impersonation per-user, AD-7/AD-16), jamais en superuser nu.
  Pas de corrective à prendre au schéma : les policies sont correctes, et le comportement
  `authenticated` (vrai client) est conforme.
- Lignes de seed supprimées à la fin du test (retour à l'état zéro données).

## v1.1 — 2026-09-23 (purge post-check-readiness, run 3)

- §4 : ajout de G-D12 (engineering packages) à OQ-01 + G-D13 (entités GoalProject) à OQ-02 + ligne G-D10..D14
- §5 : ajout de 4 entrées (G-D10, G-D11, G-D12, G-D13, G-D14) — additifs sans spine change
- §3 n°12 : correction — ban de Redux = décision pack 02 S3.1 (AD-10), pas AD-1
- §6 Wave 0 : ajout de la case G-D10..D14

## v1 — 2026-09-23

Création initiale.
- §1 État du projet (DESIGNED_NOT_IMPLEMENTED, vague courante = 0)
- §2 Monorepo cible (9 packages) + invariants de frontières AD-13 (à encoder en W0-E1-3)
- §3 15 règles critiques (single-writer AD-7, zéro clé AD-3, SSoT AD-15, RLS, AD-9, AD-8, OR-Set, 5 états UX, tokens, invariant Home AD-14, Zustand UI-only, Agent serveur AD-12, Focus restriction-only, perf budgets OQ-11)
- §4 Gates wave 0 (OQ-01/OQ-02/G-M7/G1/OQ-03)
- §5 Log des décisions récentes (AD-17, OQ-14/15/16, OQ-17 OPEN, création du fichier)
- §6 Checklists DoD par vague (wave 0–7)
- §7 Pointeurs vers les références autoritaires
- §8 Anti-patterns agents (8 exemples concrets de violations)

## v1.9 — 2026-09-26 (Session 4 wave 3, Freya)

Résultats session 4 (SOPHIA + ORACLE), à reporter dans `project-context.md` §5 au prochain standup :
- **SOPHIA (module Ascent, W3-E2-1/2) : COMPLET 6/6** — commits `wave3/sophia:` fusionnés sur main (merge `95fb9b1`) : 6 types SSoT dans `packages/domain/src/ascent.ts` (AD-15), `packages/ascent` (path-builder/adapter/baseline/depth/read-do-prove/source-hierarchy), Slide-Ascent mobile (12 slides, progressive disclosure), migration `0016_ascent.sql` + `v_ascent_scope` (relay) + miroir `ascent_paths` dans `powersync/schema.json` (scope `ascent`).
- **Migration 0016 appliquée au live Supabase DEV via le MCP Supabase : OUI.** 4 vérifications post-apply : `table_ok=1` (`ascent_paths`), `rls_enabled=true` + `rls_forced=true` (FORCE ROW LEVEL SECURITY), `policies=2` (`ascent_paths_user_isolation` USING/WITH CHECK user_id=auth.uid() + `ascent_paths_service_role` SELECT-only), `view_ok=1` (`v_ascent_scope`, security_invoker, GRANT service_role). Annoté dans l'en-tête du fichier 0016 + commit `034e1d9`.
- **Invariants vérifiés adversariallement (3/3 CONFIRMED_PASS)** : AD-9 fermé (Ascent consomme exactement 6 events existants, n'en émet aucun 10e), AD-12+AD-7 (module server-side, écrit uniquement `ascent_paths`, `LearningCommand` délégué au kernel), AD-15 (6 types déclarés uniquement dans `packages/domain`).
- **Flag follow-up (out-of-scope du batch Sophia)** : le repository `ascent` n'est pas câblé dans `AuroraDataProvider` (`apps/mobile/src/lib/boot-data.ts` : goals/tasks seulement, pas de `ascent_paths` ni `provider.ascent`) → Slide-Ascent render « Aucun chemin actif » au boot prod tant que le scope `ascent` n'est pas ajouté à `createAuroraDataProvider.connect()`. Fix minimal à encoder dans le wave mobile suivant (owner : mobile/Dyad).
- **ORACLE (kernel Agent, tâches 1–2) : déjà livré sur main** (`ec00f8d` + `cf02420`, 15 composants kernel S12 + 8 tools Vercel AI SDK dans `packages/agent/src/tools.ts`). **Tâches 3–7 : COMPLÈTES, sur main via merge `58cddd6`** — tâche 3 (router S2.6 Agnes-PRIMARY) vérifiée sans commit (`router.ts` existant déjà conforme) ; tâches 1–4 absorbées par le workflow parallèle (`d072fcb`/`5b52691`/`c9df140`/`4efe68f`/`ed98c0f`) ; le delta résiduel (run-state.ts, run-bus.ts, model.ts, providers.ts, barrel, test — 6 fichiers / 821 lignes, run-state 9/9 tests) grafté comme `8aabfbd` dans `oracle-t27` puis merged sur main comme `58cddd6` (base `0b161ca`). Lenses AD-1 + AD-3 passés post-merge. `pnpm-lock` du delta non repris (déjà couverte par `d072fcb`). Worktree pruned, plus rien d'open côté ORACLE.
- **0014 (pg_cron) : CORRECTIF — APPLIQUÉ au live via le Supabase MCP `cron.schedule()`** (jobids 8/9/10 : `aurora_fsrs_tick` `0 2 * * *`, `aurora_skill_recompute` `0 3 * * *`, `aurora_event_dispatch` `*/5 * * * *`), + **0018 (keep_alive heartbeat) : APPLIQUÉ au live via le Supabase MCP `cron.schedule()`** (jobid 7, `0 0 * * *` quotidien, table `keep_alive` 1 ligne) — anti-pause Supabase Free tier, prévu pour couvrir la pause de développement de 4+ mois. L'annotation 0014 de cette section initiale (« 2/3 présentes / 1 ABSENTE ») était un faux positif : elle avait confondu les 2 jobs `generate-ai-post-*` d'une autre instance du dashboard partagé avec les 3 `aurora_*` 0014, qui en réalité n'étaient PAS appliquées. Réappliquées + heartbeat ajouté, le tout via `SELECT cron.schedule(…)` (le `INSERT INTO cron.job` direct échouait sur le GRANT du rôle MCP ; le wrapper `cron.schedule()` fonctionne). Commité `70ddff7`.

