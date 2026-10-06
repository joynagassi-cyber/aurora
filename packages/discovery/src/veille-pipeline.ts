/**
 * Discovery module — the veille pipeline (G9, feature-agentique plan
 * 2026-10-06 §G9): `research` → `discovery sheet` → `notification` push.
 *
 * C'est l'assemblage, pas un thin emitter (contrairement aux outils
 * kernel G10/G11). Le `research` job existe déjà (CONNECTED) ; cette
 * fonction pure QUALIFIE ses résultats en `DiscoveryItem[]` (via
 * `buildDiscoveryItem`, `discovery.ts` L82) + BÂTIT le payload du
 * `notification` job (push OneSignal, `fn-notifications`), le
 * dispatcher l'enfile.
 *
 * INVARIANT AD-16b : le résultat de recherche (source tierce) est du
 * contenu non fiable → chaque `DiscoveryItem` porte le suffixe
 * `"(uncertain)"` (ADR §13.7) AVANT toute insertion dans le KB. Le
 * flag `uncertain` sur le `NotificationJobPayload` est JAMAIS
 * supprimé (même quand le verdict est `relevant` mais la crédibilité
 * source est `uncertain`) — c'est l'invariant exact de
 * `buildDiscoveryItem` L93-96 (verdict `uncertain` OU
 * `credibility === 'uncertain'` OU `kind === 'UNCERTAINTY'`).
 *
 * AD-1 : cette fonction N'APPELE JAMAIS le vendor OneSignal — elle
 * retourne uniquement le payload ; le dispatcher / `fn-notifications`
 * (module Integrations, l'adapter du vendor) est seul autorisé à
 * appeler le vendor (AD-1: vendor stays in the adapter).
 *
 * // TODO(dispatcher): wire research handler → runVeillePipeline
 *   Le handler `research` du `fn-job-dispatcher` (le chevauchement
 *   AD-8) doit appeler cette fonction quand le résultat du job a le
 *   flag `discoverySheet` (une veille, pas une recherche libre), et
 *   enfileter le `notificationJob` retourné (module 'integrations',
 *   jobKind 'notification'). Ce wiring dispatcher est un SUIVEUR
 *   (hors scope de ce batch) — G9 fournit ici uniquement la fonction
 *   pipeline + son contrat pur.
 */
import type { DiscoveryItem } from '@aurora/domain';
import {
  buildDiscoveryItem,
  DiscoveryService,
  type DiscoveryItemKind,
  type SheetDraft,
} from './discovery.ts';
import type {
  DiscoveryFilterContext,
  FilterableItem,
} from './filtering.ts';
import type { ResearchResult } from './research-provider.ts';

/**
 * Le payload du `notification` job enfilé par le dispatcher (AD-8 :
 * un descriptor, pas l'appel vendor). `uncertain` porte l'invariant
 * AD-16b — il est JAMAIS supprimé, même si le verdict est `relevant`.
 */
export interface NotificationJobPayload {
  /** le module propriétaire du vendor (Integrations, AD-1) */
  module: 'integrations';
  /** le JobKind fermé (AD-15) — 'notification' */
  jobKind: 'notification';
  /** le channel OneSignal (l'adapter résout l'identifiant) */
  channelId: string;
  /** le titre du push */
  title: string;
  /** le body du push (optionnel) */
  body?: string;
  /** AD-16b : true si le verdict EST `uncertain` OU si au moins une
   *  source EST `credibility === 'uncertain'` (JAMAIS supprimé). */
  uncertain: boolean;
}

export interface VeillePipelineOutput {
  /** les `DiscoveryItem[]` qualifiés (insertion `discovery_items`, AD-7 single-writer) */
  discoveryItems: DiscoveryItem[];
  /** le payload du `notification` job à enfileter (le dispatcher l'exécute, AD-8) */
  notificationJob: NotificationJobPayload;
}

/**
 * `runVeillePipeline` — la fonction pure + SYNCHRONE d'assemblage (G9).
 *
 * 1. Pour chaque hit non-discardé, appelle `DiscoveryService.qualify`
 *    (inline : `applyDiscoveryFilters` + `buildDiscoveryItem`,
 *    `discovery.ts` L158) pour obtenir le `DiscoveryItem` + le
 *    `FilterDecision`. Les hits écartés (verdict `discarded` — hors
 *    discipline) ne produisent PAS d'item, mais leur crédibilité brute
 *    compte pour le flag AD-16b (le flag regarde la source, JAMAIS le
 *    verdict post-filtrage).
 * 2. BÂTIT le `NotificationJobPayload` (module 'integrations',
 *    jobKind 'notification', channelId + title + body optionnelle) —
 *    `uncertain` = (verdict du premier hit `uncertain`) OU (au moins
 *    un hit `credibility === 'uncertain'`) : l'invariant AD-16b
 *    exact de `buildDiscoveryItem` L93-96.
 * 3. Retourne `{ discoveryItems, notificationJob }`.
 *
 * La `draft` est un `Partial<SheetDraft>` : le caller fournit ce qui
 * est déjà connu (userId, title, …), le pipeline déduit le reste des
 * hits + le `filterCtx`. `kind` défaut = 'TREND' (la veille est par
 * nature du contenu de tendance). `results` du item final = tous les
 * hits transmis (la source SSoT du item, `buildDiscoveryItem` L89-90).
 */
export function runVeillePipeline(
  researchResults: ResearchResult[],
  draft: Partial<SheetDraft>,
  filterCtx: DiscoveryFilterContext,
  notificationPayload: { channelId: string; title: string; body?: string },
): VeillePipelineOutput {
  const service = new DiscoveryService(filterCtx);
  const userId = draft.userId ?? '';
  const kind: DiscoveryItemKind = draft.kind ?? 'TREND';

  // AD-16b (invariant `buildDiscoveryItem` L93-96) : le flag regarde la
  // crédibilité BRUTE des hits + le verdict, JAMAIS le verdict
  // post-filtrage. Un hit hors-discipline (discarded) mais
  // `uncertain`-credibility compte tout de même pour le flag.
  const anyUncertainSource = researchResults.some(
    (r) => r.credibility === 'uncertain',
  );

  // Qualify chaque hit ; les hits écartés (verdict 'discarded') ne
  // produisent pas d'item, mais on garde leur decision pour le flag.
  const discoveryItems: DiscoveryItem[] = [];
  let anyUncertainVerdict = false;
  for (const hit of researchResults) {
    const filterable = hit as unknown as ResearchResult & FilterableItem;
    const { item, decision } = service.qualify(userId, filterable, kind);
    if (decision.verdict === 'uncertain') anyUncertainVerdict = true;
    if (decision.verdict !== 'discarded') {
      discoveryItems.push(item);
    }
  }

  // Dégradation AD-1 (01 §6) : AUCUN hit qualifiable (résultat vide, ou
  // tous écartés) → le pipeline ne peut pas qualifier → verdict par
  // défaut 'uncertain' (l'absence de source n'éclate jamais le produit,
  // elle le marque uncertain). C'est la branche du test « résultat
  // vide = flag uncertain true ».
  const noQualifiedSource = researchResults.length === 0 || discoveryItems.length === 0;
  const uncertain =
    noQualifiedSource || anyUncertainVerdict || anyUncertainSource;

  return {
    discoveryItems,
    notificationJob: {
      module: 'integrations',
      jobKind: 'notification',
      channelId: notificationPayload.channelId,
      title: notificationPayload.title,
      body: notificationPayload.body,
      uncertain,
    },
  };
}

// `buildDiscoveryItem` est re-exporté ici pour le consommateur
// dispatcher (G9) qui assemble l'insertion `discovery_items` — la
// fonction pipeline ci-dessus l'utilise déjà via `service.qualify`,
// mais l'export reste disponible pour le wiring TODO(dispatcher).
export { buildDiscoveryItem };
