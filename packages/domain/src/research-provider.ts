/**
 * ResearchProvider — the vendor port (AD-1 SSoT, 01 §3.2/§6, ADR §13.2).
 *
 * `ResearchProvider` is an OPTIONAL capability. The concrete adapters
 * (Exa, Tavily, You.com) live in `packages/integrations` (vendors ONLY
 * in adapters, AD-1). When no provider is configured, results carry the
 * `uncertain` credibility marking (01 §6 degradation rule) — the product
 * never breaks, it degrades.
 *
 * This file is ADDITIVE to packages/domain (chevauchement rule, wave 2
 * ORION): new port contract, no modification of any existing domain type.
 */

/** A typed source family a research hit belongs to (ADR §13.2). */
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

/** Provenance / credibility marking (ADR §13.2 "information encore
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
  /** typed source family (multi-source cross-check, ADR §13.2) */
  kind: ResearchSourceKind;
  title: string;
  url?: string;
  /** factual summary (kept textually dominant, AD-11) */
  summary: string;
  /** 0..1 provider-level confidence */
  confidence: number;
  /** provenance marking; `uncertain` when the provider degraded (01 §6) */
  credibility: ResearchCredibility;
  /** raw provenance (AD-11: source citations preserved) */
  provenance?: Record<string, unknown>;
}

/** The research request — a search scope resolved from the discovery
 *  profile (data-driven UserContext, NO hardcoded user checks). */
export interface ResearchQuery {
  userId: string;
  /** the topic / open question being investigated */
  topic: string;
  /** the disciplines / domains in scope */
  domains: string[];
  /** requested source families (cross-checked, ADR §13.2) */
  kinds: ResearchSourceKind[];
  /** regional scoping (e.g. 'benin') — drives local filters, data-driven */
  region?: string;
  /** horizon for scenario generation (ADR §13.7) */
  horizon?: 'now' | '2030' | '2040' | '2050';
  /** budget / infrastructure constraints (UserContext, data-driven) */
  constraints?: {
    /** e.g. 'student' — free/open-source preference */
    budget?: string;
    /** e.g. ['epanet', 'opensees'] */
    availableTools?: string[];
    /** exam period → reduced cadence (ADR §13) */
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
  /** provider id (exa | tavily | you-dot-com | offline) */
  readonly id: string;
  /** whether the provider is currently configured (keys present, AD-3
   *  server-only secrets). Absent provider = degraded results, not
   *  product break. */
  isConfigured(): boolean;
  /** run a typed multi-source query. Implementations MUST degrade to
   *  `uncertain`-marked hits when rate-limited / quota-drift (G-U4). */
  search(query: ResearchQuery): Promise<ResearchResult[]>;
}
