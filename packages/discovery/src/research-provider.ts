/**
 * Discovery module — ResearchProvider helpers (AD-1, 01 S6 degradation).
 *
 * The PORT contracts (`ResearchProvider`, `ResearchQuery`,
 * `ResearchResult`, …) live in `packages/domain` (AD-15 SSoT, wave 2
 * ORION additive file `research-provider.ts`). This module re-exports
 * them and adds the module-local pure helpers: the built-in offline
 * fallback + the degradation / cross-check rules (01 S6: no provider →
 * `uncertain`-marked results, product never breaks).
 */
import type {
  OrSetValue,
  ResearchProvider,
  ResearchQuery,
  ResearchResult,
} from '@aurora/domain';

export type {
  ResearchProvider,
  ResearchQuery,
  ResearchResult,
  ResearchSourceKind,
  ResearchCredibility,
} from '@aurora/domain';

/**
 * `OfflineResearchProvider` — the built-in fallback: no vendor, no
 * network. Returns an empty set; callers then mark anything they DO
 * produce as `uncertain` (AD-1: absence of provider never blocks the
 * loop). Exported so services can run fully offline in tests and on
 * device mirrors.
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

/**
 * The degradation rule (01 S6, AD-1 last paragraph): when the provider
 * is absent or fails, results are STILL returned but marked `uncertain`,
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

/** A typed source id list — shared helper to keep DiscoveryItem.sources
 *  as a CRDT OR-Set (03 S5.3) while the typed ResearchResult[] stays
 *  the research layer. */
export type TypedSourceIds = OrSetValue;

/** Cross-check helper (ADR §13.2: multi-source families cross-checked):
 *  a hit is "documented" only when >= 2 families agree on the topic. */
export function crossCheck(
  results: ResearchResult[],
  minAgreeingFamilies = 2,
): ResearchResult[] {
  const byKind = new Map<string, number>();
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
