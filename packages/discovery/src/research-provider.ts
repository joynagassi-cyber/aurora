/**
 * Discovery module — ResearchProvider port (ADR S13.2, AD-1, 01 S3.2/S6).
 *
 * `ResearchProvider` is an OPTIONAL capability declared as a domain port
 * (AD-1): the concrete adapters (Exa, Tavily, You.com) live in
 * `packages/integrations` (vendors ONLY in adapters). When no provider is
 * configured, every result carries `uncertain` credibility marking
 * (01 S6 degradation rule) — the product never breaks, it degrades.
 */
import type { OrSetValue } from '@aurora/domain';

/** A typed source family a research hit belongs to (ADR S13.2). */
export type ResearchSourceKind =
  | 'academic'
  | 'scientific'
  | 'technical'
  | 'professional'
  | 'technological'
  | 'sector-news'
  | 'regulatory'
  | 'local-regional'
  | 'international'
  | 'other';

/** Provenance / credibility marking (ADR S13.2 "information encore
 *  incertaine": degraded providers mark their hits `uncertain`). */
export type ResearchCredibility =
  | 'documented'
  | 'frequent'
  | 'interpretation'
  | 'uncertain';

/** A typed, provenance-carrying research hit (AD-11: citations preserved). */
export interface ResearchResult {
  /** the provider that produced the hit (exa | tavily | you-dot-com | 'offline') */
  provider: string;
  /** typed source family (multi-source cross-check, ADR S13.2) */
  kind: ResearchSourceKind;
  title: string;
  url?: string;
  /** factual summary (kept textually dominant, AD-11) */
  summary: string;
  /** 0..1 provider-level confidence */
  confidence: number;
  /** provenance marking; `uncertain` when the provider degraded (01 S6) */
  credibility: ResearchCredibility;
  /** raw provenance (AD-11: source citations preserved) */
  provenance?: Record<string, unknown>;
}

/** The research request — a search scope resolved from the discovery profile. */
export interface ResearchQuery {
  userId: string;
  /** the topic / open question being investigated */
  topic: string;
  /** the disciplines / domains in scope (UserContext data-driven, §5 of
   *  discovery-gap-pipeline: NO hardcoded user checks) */
  domains: string[];
  /** requested source families (cross-checked, ADR S13.2) */
  kinds: ResearchSourceKind[];
  /** regional scoping (e.g. 'benin') — drives local filters, data-driven */
  region?: string;
  /** horizon for scenario generation (ADR S13.7) */
  horizon?: 'now' | '2030' | '2040' | '2050';
  /** budget / infrastructure constraints (UserContext, data-driven) */
  constraints?: {
    /** e.g. 'student' — free/open-source preference */
    budget?: string;
    /** e.g. ['epanet', 'opensees'] */
    availableTools?: string[];
    /** exam period → reduced cadence (ADR S13) */
    examinationPeriod?: boolean;
  };
  limit?: number;
}

/**
 * `ResearchProvider` — the vendor port (AD-1). Implemented in
 * `packages/integrations` (Exa/Tavily/You.com). `packages/domain` stays
 * vendor-free; this interface is the shared contract.
 */
export interface ResearchProvider {
  /** provider id (exa | tavily | you-dot-com) */
  readonly id: string;
  /** whether the provider is currently configured (keys present, AD-3
   *  server-only secrets). Absent provider = degraded results, not
   *  product break. */
  isConfigured(): boolean;
  /** run a typed multi-source query. Implementations MUST degrade to
   *  `uncertain`-marked hits when rate-limited / quota-drift (G-U4). */
  search(query: ResearchQuery): Promise<ResearchResult[]>;
}

/** The provider id vocabulary (kept open — new providers are additive). */
export type ResearchProviderId = 'exa' | 'tavily' | 'you-dot-com' | 'offline';

/**
 * The degradation rule (01 S6, AD-1 last paragraph): when the provider is
 * absent or fails, results are STILL returned but marked `uncertain`,
 * provenance is kept, and no product flow breaks.
 */
export function degradeToUncertain(
  results: ResearchResult[],
  reason: string,
): ResearchResult[] {
  return results.map((r) => ({
    ...r,
    credibility: 'uncertain',
    provenance: {
      ...r.provenance,
      degraded: true,
      degradeReason: reason,
    },
  }));
}

/**
 * `OfflineResearchProvider` — the built-in fallback: no vendor, no network.
 * Returns an empty set; callers then mark anything they DO produce as
 * `uncertain` (AD-1: absence of provider never blocks the loop). Exported
 * so services can run fully offline in tests and on device mirrors.
 */
export class OfflineResearchProvider implements ResearchProvider {
  readonly id: string = 'offline';
  isConfigured(): boolean {
    return false;
  }
  async search(_q: ResearchQuery): Promise<ResearchResult[]> {
    return [];
  }
}

/** A typed source id list — shared helper to keep DiscoveryItem.sources as
 *  a CRDT OR-Set (03 S5.3) while the typed ResearchResult[] stays the
 *  research layer. */
export type TypedSourceIds = OrSetValue;

/** Cross-check helper (ADR S13.2: multi-source families cross-checked):
 *  a hit is "documented" only when >= 2 families agree on the topic. */
export function crossCheck(
  results: ResearchResult[],
  minAgreeingFamilies = 2,
): ResearchResult[] {
  const byKind = new Map<ResearchSourceKind, number>();
  for (const r of results) {
    byKind.set(r.kind, (byKind.get(r.kind) ?? 0) + 1);
  }
  return results.map((r) => {
    const families = [...byKind.values()].filter((n) => n > 0).length;
    if (families >= minAgreeingFamilies && r.credibility !== 'uncertain') {
      return { ...r, credibility: 'documented' as const };
    }
    return r;
  });
}
