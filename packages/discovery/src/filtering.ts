/**
 * Discovery module — filtering policy (discovery-gap-pipeline S5).
 *
 * "The agent does NOT evaluate relevance by LLM guess." It reads the
 * UserContext (disciplines, region, budget, goals — data-driven, NO
 * hardcoded identity checks in code) and applies deterministic rules:
 *   1. DOMAIN MATCH — the hit's discipline is in the active set.
 *   2. INFRASTRUCTURE REALITY — regional feasibility + budget.
 *   3. CAREER RELEVANCE — closes a known gap / required by target role.
 * Not actionable → stored as `not_actionable_currently` (NOT deleted).
 * Undecidable → `UNCERTAINTY` (ADR S13.7), user decides.
 */
import type { Skill, SkillState, Gap, DiscoveryProfile } from '@aurora/domain';
import type { ResearchResult } from './research-provider.ts';

/** The structured, data-driven context the filter reads (UserContext-derived).
 *  All fields optional: the engine is generic, data is per-user. */
export interface DiscoveryFilterContext {
  /** active disciplines (UserContext.discoveryProfile.disciplines) */
  disciplines: string[];
  /** region identifier (UserContext.discoveryProfile.region, e.g. 'benin') */
  region?: string;
  /** target profession (e.g. 'bureau_etudes') */
  professionalTarget?: string;
  /** budget constraint (e.g. 'student' → free/open-source preferred) */
  budget?: string;
  /** examination period → reduced discovery cadence (ADR S13) */
  examinationPeriod?: boolean;
  /** tools known to be available on the user's infrastructure */
  availableTools?: string[];
}

/**
 * Maps the user's discovery profile (UserContext.discoveryProfile,
 * AD-15 SSoT shape `DiscoveryProfile` in packages/domain) to the
 * engine's `DiscoveryFilterContext`. Pure, per-user.
 *
 * Only the fields that EXIST on both sides are induced — nothing is
 * invented: `disciplines` is required on the profile (absent → `[]`,
 * AD-1 degradation, the filter still runs with an empty discipline
 * set instead of throwing). `region` / `professionalTarget` /
 * `budget` (profile `budgetConstraint`) map 1:1. `examinationPeriod`
 * and `availableTools` are NOT on the typed profile (open ADR S13.1
 * signals, not part of the `DiscoveryProfile` SSoT yet) — they stay
 * unset here and remain available to callers that build the context
 * by hand.
 */
export function buildFilterCtx(
  profile: DiscoveryProfile,
): DiscoveryFilterContext {
  const disciplines = Array.isArray(profile.disciplines)
    ? profile.disciplines
    : [];
  const ctx: DiscoveryFilterContext = { disciplines };
  if (typeof profile.region === 'string') ctx.region = profile.region;
  if (typeof profile.professionalTarget === 'string') {
    ctx.professionalTarget = profile.professionalTarget;
  }
  if (typeof profile.budgetConstraint === 'string') {
    ctx.budget = profile.budgetConstraint;
  }
  return ctx;
}

/** The verdict of a filter step (S5 result semantics). */
export type FilterVerdict =
  | 'relevant'
  | 'not_actionable_currently'
  | 'uncertain'
  | 'discarded';

export interface FilterDecision {
  verdict: FilterVerdict;
  /** which rule produced the verdict (traceability, 01 S9 observability) */
  rule: 'domain-match' | 'infrastructure-reality' | 'career-relevance' | 'novel';
  /** 0..1 */
  confidence: number;
  /** open question surfaced when verdict === 'uncertain' */
  openQuestion?: string;
  /** the gap that a 'relevant' hit closes (S5: "Does it close a known Gap?") */
  closesGapId?: string;
}

export interface FilterableItem {
  /** the discipline the item belongs to */
  discipline: string;
  /** tool / method / norm the item references (matched vs availableTools) */
  tool?: string;
  /** annual cost in USD (infrastructure reality: "is $5000/year accessible?") */
  costPerYearUsd?: number;
  /** whether the item is free / open source (budget-aware) */
  openSource?: boolean;
  /** the gap(s) the item closes, by id */
  closesGapIds?: string[];
}

/** A research hit + its filterable fields. */
export type FilterableResearchResult = ResearchResult & FilterableItem;

const STUDENT_BUDGET_CAP_USD = 100;

/**
 * The deterministic filter (S5). Pure: same input → same verdict. The LLM
 * is only invoked by callers for the NOVEL case (no rule fired) which is
 * then flagged `uncertain` per ADR S13.7.
 */
export function applyDiscoveryFilters(
  ctx: DiscoveryFilterContext,
  item: FilterableItem,
  gaps: readonly Pick<Gap, 'id' | 'kind' | 'description'>[] = [],
): FilterDecision {
  // Rule 1 — DOMAIN MATCH (S5.1): discipline must be in the active set.
  if (!ctx.disciplines.includes(item.discipline)) {
    return {
      verdict: 'discarded',
      rule: 'domain-match',
      confidence: 0.9,
    };
  }

  // Rule 3 — CAREER RELEVANCE (S5.3): closes a known gap?
  const closed = item.closesGapIds?.[0];
  const knownGap = closed !== undefined ? gaps.find((g) => g.id === closed) : undefined;
  if (item.closesGapIds !== undefined && item.closesGapIds.length > 0) {
    if (knownGap !== undefined) {
      return {
        verdict: 'relevant',
        rule: 'career-relevance',
        confidence: 0.9,
        closesGapId: knownGap.id,
      };
    }
    // References a gap id the caller does not know → undecidable.
    return {
      verdict: 'uncertain',
      rule: 'career-relevance',
      confidence: 0.4,
      openQuestion: `Cette découverte référence un écart inconnu (${closed}). À confirmer.`,
    };
  }

  // Rule 2 — INFRASTRUCTURE REALITY (S5.2, data-driven via ctx.region/budget).
  if (item.tool !== undefined && ctx.availableTools !== undefined && item.tool !== '' && !ctx.availableTools.includes(item.tool)) {
    // Known tool set and the item's tool is not available → still stored,
    // not actionable in current context (S5: "stored, NOT deleted").
    return {
      verdict: 'not_actionable_currently',
      rule: 'infrastructure-reality',
      confidence: 0.8,
    };
  }
  if (item.costPerYearUsd !== undefined) {
    const affordable =
      ctx.budget === undefined ||
      item.openSource === true ||
      item.costPerYearUsd <= STUDENT_BUDGET_CAP_USD;
    if (!affordable) {
      // e.g. "$5000/year license" + budget 'student' → not actionable now,
      // kept for later (S5 test case).
      return {
        verdict: 'not_actionable_currently',
        rule: 'infrastructure-reality',
        confidence: 0.9,
      };
    }
  }

  // Passed all deterministic rules → relevant for this user context.
  return {
    verdict: 'relevant',
    rule: 'career-relevance',
    confidence: 0.7,
  };
}

/**
 * The cadence rule (ADR S13: user-controlled cadence; S5 "examination_period
 * → reduced cadence"). Pure schedule computation, no vendor.
 */
export function discoveryCadence(ctx: DiscoveryFilterContext, now: string): {
  /** days between runs */
  intervalDays: number;
  reduced: boolean;
} {
  void now;
  if (ctx.examinationPeriod === true) {
    return { intervalDays: 14, reduced: true };
  }
  return { intervalDays: 3, reduced: false };
}

/**
 * The competence-profile signal that drives recommendations (ADR S13.1:
 * "mastered/fragile/missing skills"). Fragile + missing skills get
 * priority; mastered skills get horizon/scenario content instead.
 */
export function prioritySkills(
  skills: readonly Skill[],
  states: readonly SkillState[],
): { fragile: Skill[]; missing: Skill[]; mastered: Skill[] } {
  const byId = new Map(skills.map((s) => [s.id, s]));
  const fragile: Skill[] = [];
  const missing: Skill[] = [];
  const mastered: Skill[] = [];
  for (const st of states) {
    const skill = byId.get(st.skillId);
    if (skill === undefined) continue;
    const lvl = st.level;
    if (lvl === 'mastered' || lvl === 'expert') mastered.push(skill);
    else if (st.confidence !== undefined && st.confidence < 0.5) fragile.push(skill);
    else missing.push(skill);
  }
  return { fragile, missing, mastered };
}
