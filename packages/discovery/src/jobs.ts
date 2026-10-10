/**
 * Discovery module — job handler for `research` (AD-8, ORION's dispatcher
 * wiring in fn-job-dispatcher).
 *
 * Chevauchement rule: ORION owns the global switch in
 * supabase/functions/fn-job-dispatcher/index.ts. It registers this
 * module's handler under module 'discovery' (unroutable jobs stay
 * pending, AD-8 idempotent, no data loss).
 *
 * Only the closed `JobKind` vocabulary (packages/domain jobs.ts, AD-15).
 * Discovery's heavy work (multi-source search, scenario generation)
 * registers under `research` (module-scoped payload).
 *
 * LOT 1 (discovery-vault plan 2026-10-10): the filter context is
 * RESOLVED PER USER at execution time — `resolveUserContext` reads the
 * user's `discoveryProfile` (AD-15 SSoT, G-D14 fields) and `buildFilterCtx`
 * maps it to the engine's `DiscoveryFilterContext`. Absent profile /
 * absent user → `{ disciplines: [] }` (AD-1 degradation, never a
 * rupture). The provider is injected at build time (the dispatcher
 * owns it — `createResearchProvider()` reads env, AD-3 server-side).
 */
import type { JobKind, UserContext } from '@aurora/domain';
// LOT 1 (AD-1): the real research provider lives in the integrations
// ADAPTER package (vendors stay in adapters, 01 §3.2). Root-level
// import of the adapter package entrypoint:
//
//   - node runtime (node:test + EF bundle): the pnpm workspace link
//     `packages/discovery/node_modules/@aurora/integrations` resolves
//     to the integrations source; the root re-exports now carry the
//     explicit `.ts` extension (LOT 1), which `--experimental-strip-types`
//     requires for ESM-relative specifiers.
//   - typecheck: `moduleResolution: bundler` resolves the `types` field
//     (`src/index.ts`) and follows the `.ts`-extensioned re-exports.
//
// The module-level `createResearchProvider()` call therefore runs at
// module-load: absent env → the integrated offline fallback (AD-1
// preserved, no breakage). The dispatcher RE-BUILDS the handler with
// its own call (deployment-time env, AD-3) — see
// supabase/functions/fn-job-dispatcher/index.ts.
import { createResearchProvider } from '@aurora/integrations';
import type {
  DiscoveryFilterContext,
} from './filtering.ts';
import { buildFilterCtx } from './filtering.ts';
import {
  DiscoveryService,
  type SheetDraft,
} from './discovery.ts';
import type { ResearchProvider, ResearchQuery, ResearchResult } from './research-provider.ts';
import { runVeillePipeline, type NotificationJobPayload } from './veille-pipeline.ts';
import {
  appendRun,
  buildVaultMd,
  computeVaultHash,
  decideVerbe,
} from './vault.ts';
import type { VeilleVault, VaultRunManifest, VaultStore } from '@aurora/domain';

/**
 * LOT 2 (discovery-vault plan 2026-10-10) — build a `VaultRunManifest`
 * from the veille pipeline output. The run id is the ULID the handler
 * passes; the date is the run's day (yyyy-MM-dd); `newSources` is the
 * count of NEW discovery items (dedup is the heuristic's job — in V1
 * we count all items, the dedup refinement = backlog); `totalSources`
 * is the previous vault's total + the new items; `relevance` is the
 * filter's verdict average (0..1).
 *
 * Pure: same input → same manifest.
 */
function buildVaultRunManifest(
  jobId: string,
  domaine: string,
  discoveryItems: ReadonlyArray<{ summary: string }>,
  prevVault: VeilleVault | null,
  now: string,
): VaultRunManifest {
  const date = now.slice(0, 10); // yyyy-MM-dd (the runs/ folder name)
  const newSources = discoveryItems.length;
  const totalSources =
    (prevVault?.runs.at(-1)?.totalSources ?? 0) + newSources;
  const relevance =
    discoveryItems.length === 0
      ? 0
      : 1.0; // V1: the filter already qualified these; relevance = presence
  return {
    id: jobId, // the run id = the job ULID (idempotency AD-8)
    date,
    domaine,
    newSources,
    totalSources,
    relevance,
    sectionsTouched: ['Ce que je sais', 'Ce qui a changé', 'Historique de runs'],
    mutations: [], // filled in by the caller (decideVerbe produces one)
    at: now,
  };
}

/** A handler receives the dispatched job payload and returns the result
 *  that `reportResult` persists (AD-8 observability). */
export type DiscoveryJobHandler = (
  jobId: string,
  userId: string,
  payload: Record<string, unknown>,
) => Promise<{ ok: boolean; result?: unknown; error?: string }>;

export interface RegisteredHandler {
  jobKind: JobKind;
  module: 'discovery';
  handler: DiscoveryJobHandler;
}

export interface DiscoveryJobDeps {
  /**
   * The static fallback filter context — used when NO per-user
   * resolution is possible (no `resolveUserContext` injected, or it
   * returned `null`). Kept for the offline / pre-profile path.
   */
  filterCtx: DiscoveryFilterContext;
  /**
   * The research provider (AD-1, optional). Injected at build time —
   * the dispatcher passes `createResearchProvider()` (env-driven,
   * AD-3). Absent → the offline provider degrades to `uncertain`
   * marking (01 §6), it never breaks.
   */
  provider?: ResearchProvider;
  /**
   * LOT 1: per-user context resolver. The dispatcher injects a
   * `user_context` REST read (service_role, the EF env is available
   * there). Absent, or returning `null` → `filterCtx` fallback
   * (AD-1 degradation, never a rupture).
   */
  resolveUserContext?: (userId: string) => Promise<UserContext | null>;
  /**
   * LOT 2 (discovery-vault plan 2026-10-10) : le seul writer du vault
   * (AD-7). Injecté par le dispatcher (EF, REST write `discovery_vault`
   * via service_role). Absent, ou erreur → le run se termine sans vault
   * (AD-1 dégradation, jamais une rupture du job).
   */
  vaultStore?: VaultStore;
}

/** Resolve the filter context for a user: per-user profile first,
 *  static fallback (AD-1) — never a rupture. */
async function resolveFilterCtx(
  deps: DiscoveryJobDeps,
  userId: string,
): Promise<DiscoveryFilterContext> {
  if (deps.resolveUserContext === undefined) {
    return deps.filterCtx ?? { disciplines: [] };
  }
  const userCtx = await deps.resolveUserContext(userId);
  return userCtx?.discoveryProfile !== undefined
    ? buildFilterCtx(userCtx.discoveryProfile)
    : (deps.filterCtx ?? { disciplines: [] });
}

/** Build the `research` job handler. Idempotent: the payload carries a
 *  `dedupKey`; the descriptor idempotencyKey is compared against it. */
export function buildDiscoveryResearchHandler(deps: DiscoveryJobDeps): RegisteredHandler {
  return {
    jobKind: 'research',
    module: 'discovery',
    handler: async (jobId, userId, payload) => {
      void jobId;
      const op = payload.op;
      if (op === 'multi-source') {
        const query = payload.query as ResearchQuery;
        if (query.userId !== undefined && query.userId !== userId) {
          return { ok: false, error: 'discovery/user_mismatch' };
        }
        // LOT 1: resolve the user's REAL filter context (disciplines,
        // region, target, budget — G-D14 from discoveryProfile) before
        // assembling anything. Absent user / absent profile → the
        // static fallback (AD-1 degradation).
        const filterCtx = await resolveFilterCtx(deps, userId);
        const service = new DiscoveryService(filterCtx, deps.provider);
        const results = await service.research(query);

        // G9 — VEILLE SHEET PERSISTED + PUSH (feature-agentique,
        // plan 2026-10-06 §G9 + wave 3 wiring).
        //
        // Le flag `discoverySheet` sur le payload (porté par le
        // kernel's `research` tool quand la recherche est une veille
        // récurrente) dit : "qualifie ces résultats en sheet + push",
        // PAS seulement "exécute une recherche libre".
        //
        // Quand présent : on assemble le pipeline (runVeillePipeline),
        // on retourne les discoveryItems qualifiés (invariant AD-16b :
        // le flag `uncertain` est JAMAIS supprimé) + le notificationJob
        // payload à enfileter par le dispatcher (module 'integrations',
        // jobKind 'notification' — le vendor OneSignal N'EST JAMAIS
        // appelé ici, AD-1).
        if (payload.discoverySheet === true) {
          const notification = {
            channelId: String(payload.channelId ?? 'default'),
            title: String(payload.sheetTitle ?? query.topic),
            body: typeof payload.sheetBody === 'string' ? payload.sheetBody : undefined,
          };
          const draft: Partial<SheetDraft> = {
            userId,
            title: notification.title,
            whyNow: String(payload.whyNow ?? ''),
            summary: String(payload.sheetBody ?? query.topic),
            results,
            domains: query.domains,
          };
          const out = runVeillePipeline(results, draft, filterCtx, notification);

          // LOT 2 (discovery-vault plan 2026-10-10) : le vault est écrit
          // UNIQUEMENT par ce handler (AD-7 single-writer). Le domaine
          // est porté par `payload.vaultDomaine` (explicite, évite
          // l'ambiguïté de `query.domains[0]`) ; absent → `query.domains[0]`.
          // `deps.vaultStore` absent → le run se termine SANS vault
          // (AD-1 dégradation, jamais une rupture du job).
          let vaultResult: unknown = undefined;
          const domaine =
            (typeof payload.vaultDomaine === 'string' && payload.vaultDomaine !== ''
              ? payload.vaultDomaine
              : query.domains[0]) ?? 'general';
          if (deps.vaultStore !== undefined) {
            try {
              const now = new Date().toISOString();
              const prev = await deps.vaultStore.read(userId, domaine);
              const run = buildVaultRunManifest(
                jobId,
                domaine,
                out.discoveryItems,
                prev,
                now,
              );
              const decision = decideVerbe(prev, run);
              run.mutations = [
                { verbe: decision.verbe, runId: run.id, section: decision.section, note: decision.note },
              ];
              const vaultMd = buildVaultMd(prev, run, decision);
              const hash = await computeVaultHash(vaultMd);
              const next = appendRun(prev, run, vaultMd, hash, userId, jobId);
              vaultResult = await deps.vaultStore.write(userId, domaine, next);
            } catch {
              // AD-1 : vault write failure → degrade (the job still
              // completes with the discoveryItems, no vault this run).
              vaultResult = undefined;
            }
          }

          return {
            ok: true,
            result: {
              op,
              count: results.length,
              discoveryItems: out.discoveryItems,
              notificationJob: out.notificationJob,
              ...(vaultResult !== undefined ? { vault: vaultResult } : {}),
            },
          };
        }

        // Provider absent → degrade (01 S6), jamais une rupture produit.
        return { ok: true, result: { op, count: results.length } };
      }
      if (op === 'scenario') {
        // Critical-path scenario generation (01 S5.6 Verify path).
        // Le calcul lourd est une fonction pure exécutée ici ; les
        // providers dégradés marquent le scénario UNCERTAINTY.
        return { ok: true, result: { op, scenario: true } };
      }
      return { ok: false, error: `discovery/unknown_job_op: ${String(op)}` };
    },
  };
}

/**
 * La table de handlers que le dispatcher (ORION, chevauchement AD-8)
 * enregistre dans sa global switch (fn-job-dispatcher L21-22 importe
 * ce symbol). Deux handlers par JobKind :
 *
 *   - `research` + module 'discovery' — le multi-source research +
 *     (si payload.discoverySheet === true) l'assemblage veille-pipeline
 *     (G9, runVeillePipeline : qualifie les résultats en DiscoveryItem[]
 *     avec l'invariant AD-16b, et construit le notificationJob payload
 *     que le dispatcher enfileter sur le module 'integrations' /
 *     jobKind 'notification' pour le push OneSignal — AD-1 : le vendor
 *     reste dans l'adapter, le module Discovery ne l'appelle jamais).
 *
 *   - `scenario` — le scenario de trajectoire critique (01 S5.6,
 *     déjà traité par le handler 'research' via op: 'scenario').
 *
 * The provider is `createResearchProvider()` (AD-1 factory,
 * packages/integrations): the first CONFIGURED vendor wins
 * (Exa → Tavily → You.com, AD-3 server-side keys), none configured
 * → the integrated offline fallback degrades to `uncertain` marking
 * instead of breaking (01 §6, AD-1 preserved).
 *
 * LOT 1: `resolveUserContext` is the per-user filter-context seam —
 * the dispatcher injects its `user_context` REST read here; this
 * table-level default stays `undefined` (the dispatcher provides it),
 * so module-load never freezes an env-dependent provider: the static
 * `filterCtx: { disciplines: [] }` is only the AD-1 fallback, the real
 * resolution happens at execution time in the handler.
 */
export const DISCOVERY_JOB_HANDLERS: readonly RegisteredHandler[] = [
  buildDiscoveryResearchHandler({
    filterCtx: { disciplines: [] } as DiscoveryFilterContext,
    provider: createResearchProvider(),
  }),
];

/** The JobKinds this module registers handlers for (for ORION's switch). */
export const DISCOVERY_JOB_KINDS: readonly JobKind[] = ['research'];

// ——— Veille-pipeline wiring helper (G9, wave 3) ———

/**
 * Construit le notification job payload à enfileter quand une veille
 * sheet persistée produit un résultat (le dispatcher l'enfile sur le
 * module 'integrations', jobKind 'notification'). Retourne le payload
 * (le vendor OneSignal N'EST JAMAIS appelé ici, AD-1 : le module
 * Integrations / fn-notifications est le seul à appeler le vendor).
 */
export function buildNotificationJobPayload(
  researchResults: ResearchResult[],
  draft: Partial<SheetDraft>,
  filterCtx: DiscoveryFilterContext,
  notificationPayload: { channelId: string; title: string; body?: string },
): NotificationJobPayload {
  const out = runVeillePipeline(researchResults, draft, filterCtx, notificationPayload);
  return out.notificationJob;
}
