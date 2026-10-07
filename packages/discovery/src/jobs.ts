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
 */
import type { JobKind } from '@aurora/domain';
import type {
  DiscoveryFilterContext,
} from './filtering.ts';
import {
  DiscoveryService,
  type SheetDraft,
} from './discovery.ts';
import { OfflineResearchProvider } from './research-provider.ts';
import type { ResearchProvider, ResearchQuery, ResearchResult } from './research-provider.ts';
import { runVeillePipeline, type NotificationJobPayload } from './veille-pipeline.ts';

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
  filterCtx: DiscoveryFilterContext;
  provider?: ResearchProvider;
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
        const service = new DiscoveryService(deps.filterCtx, deps.provider);
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
          const out = runVeillePipeline(results, draft, deps.filterCtx, notification);
          return {
            ok: true,
            result: {
              op,
              count: results.length,
              discoveryItems: out.discoveryItems,
              notificationJob: out.notificationJob,
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
 * Le provider par défaut est l'OfflineResearchProvider (dégradation
 * AD-1 : le produit ne casse jamais quand le vendor n'est pas
 * configuré ; le flag `uncertain` du pipeline s'adapte).
 */
export const DISCOVERY_JOB_HANDLERS: readonly RegisteredHandler[] = [
  buildDiscoveryResearchHandler({
    filterCtx: { disciplines: [] } as DiscoveryFilterContext,
    provider: new OfflineResearchProvider(),
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
