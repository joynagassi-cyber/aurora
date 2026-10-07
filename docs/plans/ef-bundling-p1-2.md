# P1-2 — Résolution `DISCOVERY_JOB_HANDLERS` côté EF (décision d'exécution)

> **Contexte** (point signalé owner, 2026-10-07) : le commit wave-3 `4fd7644` a fait pointer
> l'import de `fn-job-dispatcher` vers `packages/discovery/src/jobs.ts`
> (`DISCOVERY_JOB_HANDLERS` + `buildDiscoveryResearchHandler` → `runVeillePipeline`).
> **Le runtime Deno d'une EF déployée ne voit que `supabase/functions/`** (le
> `supabase functions deploy` pousse le dossier tel quel) : le chemin relatif vers
> `packages/*` est **non résolvable en prod**. Le wiring ① n'existe que dans le
> repo TypeScript ; il ne s'exécute pas tant que le code n'est pas visible par l'EF.
> Le G1 du plan [finalisation-v1.md](finalisation-v1.md) (EF non déployées) en dépend.

## Options

| Option | Description | Pros | Cons |
|---|---|---|---|
| **A. Bundle esbuild** | Étape de build (esbuild, target Deno) qui inliné les imports `packages/*` dans l'artefact EF avant `supabase functions deploy` | SSoT unique (`packages/discovery`), drift impossible, versionné | Nouvel outil de build sur le chemin EF (esbuild + resolve alias pour `https://deno.land/std`), artefacts à produire avant chaque deploy |
| **B. Copie vendée + gate de drift** ✅ | Copie du handler dans `supabase/functions/_shared/veille-pipeline.ts` (motif déjà en place : `_shared/envelope`), + **gate CI** qui détecte le drift | Zéro build step, déployable tel quel, cohérent avec l'existant (`_shared`) | Drift manuel possible → compensé par le gate (checksum/bloc source comparé, sinon CI-rouge) |
| **C. Logique en SQL/trigger** | `runVeillePipeline` en Postgres | — | `runVeillePipeline` est du TS qui appelle le `ResearchProvider` (AD-1 vendor) → **portable pas en SQL**. Rejetée |

## Décision (à ratifier standup)

**B pour v1.0** (chemin le plus court, zéro nouvel outil, motif `_shared` déjà ratifié)
+ **A en backlog** (refactor post-v1.0, si ≥ 2 EF importent `packages/*`).

## Étapes concrètes (monorepo `aurora-2`)

1. **Créer** `supabase/functions/_shared/veille-pipeline.ts` :
   - inline de `DISCOVERY_JOB_HANDLERS` + `buildDiscoveryResearchHandler` + `runVeillePipeline`
     (source : `packages/discovery/src/jobs.ts` / `veille-pipeline.ts`)
   - adaptation Deno : zéro import `packages/*` ; le `ResearchProvider` reste un port
     (AD-1 : le vendor n'entre que dans l'adapter EF, jamais dans le module).
2. **Pointer** `fn-job-dispatcher` (L21) sur `../_shared/veille-pipeline.ts`.
3. **Gate CI** (node-native, dans `.github/workflows/ci.yml`) :
   - `scripts/ef-drift-check.ts` — compare le bloc inliné (`_shared/veille-pipeline.ts`)
     au source (`packages/discovery`) via empreinte du corps de fonction ; drift =
     échec CI avec le message « re-sync `_shared` depuis `packages/discovery` ».
   - s'ajoute à la suite du gate existant (`check-boundaries`, `check-rls`,
     `check-view-joins`, spine test — AI_RULES §9).
4. **Déployer** : `supabase functions deploy` × 6 (cf P1-1, [finalisation-v1.md](finalisation-v1.md) Phase 1).
5. **Smoke test** (après déploy) :
   - `fn-canvas` : verbes `create / lock / rename` (curl authed + 409 sur `locked`).
   - `fn-job-dispatcher` : enfilement d'un job `research` avec `payload.discoverySheet = true`
     → P1-3 du plan (dispatch → claim → résultat + idempotence `source_local_mutation_id`).

## Contraintes (invariants)

- **AD-1** : le handler dupliqué doit rester vendor-free (port `ResearchProvider`,
  pas d'import de provider concret dans le module).
- **AD-7/F-03 single-writer** : le module Discovery émet des événements / enfile
  les jobs, n'écrit pas les tables d'un autre module ; le flag `uncertain` est
  **jamais supprimé** (invariant AD-16b — commit wave-3 ①).
- **AD-8** : le pipeline de veille reste un job persisté/idempotent (pas de travail
  lourd synchrone dans l'EF).
- **1 story = 1 commit = 1 rollback** (AD-13) : steps 1–3 = 1 story `fix(ef): vend
   discovery handlers + drift gate`.

**Owner** : Orion (EF) + Discovery (source) + Foundation (gate CI) — **est. 0,5 j + le déploy P1-1.**
