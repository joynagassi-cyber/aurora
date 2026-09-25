/**
 * Discovery module — core service: discovery sheets (ADR S13.8) + the
 * `DiscoveryItemCreated` event builder (AD-9, PRODUCTION = Discovery only).
 *
 * The loop (ADR S13.9): observe → need → multi-source search → compare &
 * qualify → select → explain → link → create activity → measure → improve.
 * This module owns steps "qualify / select / explain / link"; the search
 * itself is a persisted `research` job (AD-8, ORION's dispatcher wires it).
 */
import type {
  DiscoveryItem,
} from '@aurora/domain';
import type {
  DiscoveryFilterContext,
  FilterableItem,
} from './filtering.ts';
import {
  applyDiscoveryFilters,
  type FilterDecision,
} from './filtering.ts';
import type {
  ResearchProvider,
  ResearchQuery,
  ResearchResult,
} from './research-provider.ts';
import {
  OfflineResearchProvider,
  degradeToUncertain,
  crossCheck,
} from './research-provider.ts';

/** The typed separation (ADR S13.7): every sheet classifies its content. */
export type DiscoveryItemKind =
  | 'FACT'
  | 'TREND'
  | 'ANALYSIS'
  | 'SCENARIO'
  | 'UNCERTAINTY';

export const DISCOVERY_ITEM_KINDS = [
  'FACT',
  'TREND',
  'ANALYSIS',
  'SCENARIO',
  'UNCERTAINTY',
] as const;

/** A discovery sheet draft — the inputs to `createSheet`. */
export interface SheetDraft {
  userId: string;
  title: string;
  question?: string;
  whyNow: string;
  summary: string;
  kind: DiscoveryItemKind;
  /** research hits that back the sheet (typed families cross-checked) */
  results: ResearchResult[];
  /** typed source families to include */
  domains: string[];
  /** the open questions carried forward */
  openQuestions?: string[];
  /** semantic tree nodes / goal links (ADR S13.8) */
  semanticNodeIds?: string[];
  relatedGoalIds?: string[];
  relatedCourseIds?: string[];
  relatedSkillIds?: string[];
  domainRef?: string;
  confirmsOrContradicts?: string;
  now?: string;
}

export interface SheetWithDecision {
  item: DiscoveryItem;
  decision: FilterDecision;
}

/**
 * The single-writer factory for `DiscoveryItem` (AD-7): Discovery is the
 * only module that inserts `discovery_items` rows. `now` is injectable so
 * the builders stay pure / deterministic (testable).
 */
export function buildDiscoveryItem(
  draft: SheetDraft,
  decision: FilterDecision,
): DiscoveryItem {
  const now = draft.now ?? new Date().toISOString();
  const nowMs = Date.parse(now);
  // OR-Set encoding (03 S5.3): { v, ts, c } — server ts + client id.
  const sourceIds = draft.results.map((r) => r.title);
  const sources = sourceIds.map((v) => ({ v, ts: nowMs, c: 'discovery' }));
  const mkOr = (vals?: string[]) =>
    (vals ?? []).map((v) => ({ v, ts: nowMs, c: 'discovery' }));
  const uncertain =
    decision.verdict === 'uncertain' ||
    draft.kind === 'UNCERTAINTY' ||
    draft.results.some((r) => r.credibility === 'uncertain');
  return {
    id: '',
    userId: draft.userId,
    title: draft.title,
    question: draft.question,
    whyNow: draft.whyNow,
    summary: uncertain ? `${draft.summary} (uncertain)` : draft.summary,
    sources,
    confirmsOrContradicts: draft.confirmsOrContradicts,
    relatedCourseIds: mkOr(draft.relatedCourseIds),
    domainRef: draft.domainRef,
    relatedSkillIds: mkOr(draft.relatedSkillIds),
    openQuestions: draft.openQuestions,
    recommendedActions:
      decision.verdict === 'relevant'
        ? ['read', 'practice']
        : decision.verdict === 'not_actionable_currently'
          ? ['ignore-for-now']
          : ['follow'],
    semanticNodeIds: mkOr(draft.semanticNodeIds),
    relatedGoalIds: mkOr(draft.relatedGoalIds),
    createdAt: now,
    updatedAt: now,
  };
}

/**
 * `DiscoveryService` — qualifies research results into a discovery sheet
 * and the event that propagates it (AD-9). Pure logic: the `research` job
 * (AD-8) runs the provider; this service is what the worker invokes.
 */
export class DiscoveryService {
  readonly provider: ResearchProvider;
  readonly filterCtx: DiscoveryFilterContext;

  constructor(
    filterCtx: DiscoveryFilterContext,
    provider: ResearchProvider = new OfflineResearchProvider(),
  ) {
    this.filterCtx = filterCtx;
    this.provider = provider;
  }

  /** Run the research provider, cross-check, and degrade-if-absent
   *  (01 S6: no provider → `uncertain` marking, never product break). */
  async research(query: ResearchQuery): Promise<ResearchResult[]> {
    let results: ResearchResult[];
    if (this.provider.isConfigured()) {
      results = await this.provider.search(query);
    } else {
      results = [];
    }
    const checked = crossCheck(results, 2);
    if (!this.provider.isConfigured()) {
      return degradeToUncertain(checked, 'no-provider-configured');
    }
    return checked;
  }

  /** Qualify one hit into a sheet + its filter decision (ADR S13.9 step
   *  "compare & qualify → select → explain → link"). */
  qualify(
    userId: string,
    hit: ResearchResult & FilterableItem,
    kind: DiscoveryItemKind,
  ): SheetWithDecision {
    const decision = applyDiscoveryFilters(this.filterCtx, hit, []);
    const item = buildDiscoveryItem(
      {
        userId,
        title: hit.title,
        whyNow: decision.verdict === 'relevant' ? hit.summary : 'Contexte à clarifier',
        summary: hit.summary,
        kind,
        results: [hit],
        domains: this.filterCtx.disciplines,
      },
      decision,
    );
    return { item, decision };
  }
}
