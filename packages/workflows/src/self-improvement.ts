/**
 * self-improvement.ts — the Expert Skill feedback loop
 * (docs/agent/expert-skills-extensions.md, ADR S14 + extensions).
 *
 * The 6-stage loop (section 3 of the doc):
 *   1. PROGRESS detects a gap -> 2. SELF-IMPROVEMENT triages (causal
 *   analysis) -> 3. DISCOVERY runs (optional research) -> 4. Expert Skill
 *   revised / hypothesis generated -> 5. next session applies the
 *   updated skill -> 6. PROGRESS records the outcome -> loop continues.
 *
 * Deterministic data + formulas, not prose:
 *   - confidence decay is a closed-form formula (§2.2, NOT an LLM judgment)
 *   - anti-regression firewall: an established skill (conf >= 0.5, active)
 *     CANNOT be modified on a single anomalous cycle; minimum 3 independent
 *     cycles with the same motif (§2.4)
 *   - no one-shot promotion: minimum 2 contrastive pairs before confidence
 *     may exceed 0.6 (§2.1)
 *   - hypotheses are temporary + low-confidence (< 0.3 at creation);
 *     rejected hypotheses are data points, never active skills (§2.3)
 *
 * Authority: ADR S14.5 guardrails, kernel S12 Memory, 01 S4.7
 * (expert_skills server-only, AD-3), ADR S18.4 (correlation != causation).
 */
import type { SelfImprovementStage } from './types.ts';

/* ------------------------------------------------------------------ */
/* §2.2 Confidence decay — closed-form, per-skill-type lambda          */
/* ------------------------------------------------------------------ */

/** Per-skill-type decay rates (per 30 days), §2.2 table. */
export type SkillType = 'planning' | 'learning' | 'discipline';

/** lambda per 30 days, calibrated per skill type (§2.2). */
export const DECAY_LAMBDA: Record<SkillType, number> = {
  planning: 0.3,
  learning: 0.1,
  discipline: 0.5,
};

export interface ConfidenceDecayInput {
  /** confidence at last validation */
  confidence0: number;
  /** days since last validation (t - t_validation) */
  daysSinceValidation: number;
  /** skill type (selects lambda) */
  type: SkillType;
  /** +0.1 if a ProgressEvidence in the last 7 days re-confirms the skill */
  recencyBoost?: boolean;
}

/**
 * confidence(t) = confidence_0 * exp(-lambda * (days/30)) * recency_boost
 * (recency_boost multiplies by 1.1 when true, capped at 1.0).
 * Deterministic math, not an LLM judgment (§2.2).
 */
export function confidenceAt(input: ConfidenceDecayInput): number {
  const lambda = DECAY_LAMBDA[input.type];
  const decayed = input.confidence0 * Math.exp((-lambda * input.daysSinceValidation) / 30);
  const boosted = input.recencyBoost ? decayed * 1.1 : decayed;
  // clamp to [0,1] — confidence is a bounded value
  return Math.max(0, Math.min(1, boosted));
}

/** §2.2 thresholds. */
export const REEVALUATION_THRESHOLD = 0.3;
export const AUTO_ARCHIVE_THRESHOLD = 0.1;

export interface DecayVerdict {
  confidence: number;
  /** flag for user re-evaluation when confidence < 0.3 (but >= 0.1) */
  flagForReevaluation: boolean;
  /** auto-archive (no prompt, retained in data, not active) when < 0.1 */
  autoArchive: boolean;
}

/** Apply the §2.2 thresholds to a decayed confidence value. */
export function decayVerdict(input: ConfidenceDecayInput): DecayVerdict {
  const confidence = confidenceAt(input);
  return {
    confidence,
    flagForReevaluation: confidence < REEVALUATION_THRESHOLD && confidence >= AUTO_ARCHIVE_THRESHOLD,
    autoArchive: confidence < AUTO_ARCHIVE_THRESHOLD,
  };
}

/* ------------------------------------------------------------------ */
/* §2.1 Contrastive strategy evaluation                                */
/* ------------------------------------------------------------------ */

export interface ContrastivePairInput {
  successSnapshotId: string;
  failureSnapshotId: string;
  /** which context variables diverge between the two paired sessions */
  divergentVariables: string[];
  conclusion: string;
  /** +0.1 / -0.1 applied to the skill */
  confidenceDelta: number;
}

/**
 * §2.1 rule: minimum 2 pairs before a skill's confidence can exceed 0.6.
 * One success is NOT a skill. Returns the adjusted confidence.
 */
export function contrastiveConfidence(
  baseConfidence: number,
  pairs: readonly ContrastivePairInput[],
): { confidence: number; promotable: boolean } {
  if (pairs.length < 2) {
    return { confidence: Math.min(baseConfidence, 0.6), promotable: false };
  }
  let c = baseConfidence;
  for (const p of pairs) c += p.confidenceDelta;
  c = Math.max(0, Math.min(1, c));
  return { confidence: c, promotable: pairs.length >= 2 && c > 0.6 };
}

/* ------------------------------------------------------------------ */
/* §2.3 Auto-generated triage hypotheses                               */
/* ------------------------------------------------------------------ */

export interface HypothesisInput {
  trigger: string;
  proposedAction: string;
  /** evidence window (14-day default) */
  evidenceWindowDays?: number;
}

export interface TriageHypothesis {
  trigger: string;
  proposedAction: string;
  /** always < 0.3 at creation (§2.3) */
  confidence: number;
  status: 'hypothesis';
  /** days until auto-expiry if not validated */
  evidenceWindowDays: number;
}

/**
 * §2.3: when Progress detects stagnation, generate a low-confidence
 * HYPOTHESIS (not a skill yet) to test. Hypotheses NEVER pollute the
 * longitudinal profile if rejected.
 */
export function generateHypothesis(input: HypothesisInput): TriageHypothesis {
  return {
    trigger: input.trigger,
    proposedAction: input.proposedAction,
    confidence: 0.2,
    status: 'hypothesis',
    evidenceWindowDays: input.evidenceWindowDays ?? 14,
  };
}

/** §2.3 lifecycle: inside window + supporting evidence -> validated 0.5. */
export function resolveHypothesis(
  h: TriageHypothesis,
  evidence: 'supports' | 'contradicts' | 'absent',
  daysElapsed: number,
): { status: 'validated' | 'rejected' | 'expired'; confidence: number } {
  const expired = daysElapsed >= h.evidenceWindowDays;
  if (evidence === 'supports') return { status: 'validated', confidence: 0.5 };
  if (evidence === 'contradicts') return { status: 'rejected', confidence: h.confidence };
  // absent -> auto-expire if past window, else still testing
  if (expired) return { status: 'expired', confidence: h.confidence };
  return { status: 'rejected', confidence: h.confidence };
}

/* ------------------------------------------------------------------ */
/* §2.4 Cognitive-drift firewall (anti-regression)                    */
/* ------------------------------------------------------------------ */

export interface AnomalyCycle {
  /** ISO date of the cycle (e.g., a week) */
  at: string;
  /** the motif observed (e.g., "skipped after 2-hour lecture") */
  motif: string;
}

export interface FirewallInput {
  /** the established skill's current confidence (>= 0.5 to be "established") */
  confidence: number;
  status: 'active' | 'archived';
  /** independent anomalous cycles with the same motif */
  anomalousCycles: readonly AnomalyCycle[];
}

export const FIREWALL_MIN_CYCLES = 3;
export const ESTABLISHED_THRESHOLD = 0.5;

export interface FirewallVerdict {
  /** whether the skill may be modified (archived / confidence reduced) */
  skillAdjustable: boolean;
  /** reason */
  reason: string;
  /** anomalies below the threshold are logged as incidents, not skill evidence */
  logAsIncident: boolean;
}

/**
 * §2.4: an established skill (conf >= 0.5, active) CANNOT be modified on a
 * single anomalous cycle. Minimum 3 independent cycles with the same motif.
 * Below 3 cycles: the anomaly is an "incident" (ProgressEvidence
 * type='exception'), NOT evidence against the skill.
 */
export function firewallVerdict(input: FirewallInput): FirewallVerdict {
  const established = input.confidence >= ESTABLISHED_THRESHOLD && input.status === 'active';
  if (!established) {
    // non-established skills have no firewall protection; anomalies flow
    return { skillAdjustable: true, reason: 'skill is not established (< 0.5 or not active)', logAsIncident: false };
  }
  const sameMotif = input.anomalousCycles.filter((c) => c.motif === input.anomalousCycles[0]?.motif).length;
  if (sameMotif >= FIREWALL_MIN_CYCLES) {
    return { skillAdjustable: true, reason: `${sameMotif} independent cycles with the same motif (>= ${FIREWALL_MIN_CYCLES})`, logAsIncident: false };
  }
  return {
    skillAdjustable: false,
    reason: `firewall: ${sameMotif} anomalous cycle(s) < ${FIREWALL_MIN_CYCLES} minimum — logged as incident`,
    logAsIncident: true,
  };
}

/**
 * §2.4 exception: user EXPLICITLY says "stop using this strategy" ->
 * immediate archive (user authority > firewall). Bypasses the 3-cycle rule.
 */
export function userOverride(input: { userExplicitlyStopped: boolean }): { archiveImmediately: boolean } {
  return { archiveImmediately: input.userExplicitlyStopped };
}

/* ------------------------------------------------------------------ */
/* The full 6-stage loop (section 3)                                   */
/* ------------------------------------------------------------------ */

export interface LoopContext {
  /** 1. PROGRESS detected gap (SkillState level) */
  gapSkillId: string;
  /** 2. SELF-IMPROVEMENT triage: causal conclusion */
  causalConclusion?: string;
  /** 3. DISCOVERY: optional research discovery item */
  discoveryItemId?: string;
  /** 4. EXPERT SKILL revised or hypothesis generated */
  revisedSkillKey?: string;
  /** 5. NEXT SESSION: the Agent applied the updated skill */
  applied?: boolean;
  /** 6. PROGRESS recorded outcome (new SkillState level) */
  outcomeLevel?: string;
}

/** Map a loop context to the stage it is currently at (section 3). */
export function loopStage(ctx: LoopContext): SelfImprovementStage {
  if (ctx.applied && ctx.outcomeLevel) return 'progress-recorded';
  if (ctx.applied) return 'next-session-applied';
  if (ctx.revisedSkillKey) return 'skill-revised';
  if (ctx.discoveryItemId) return 'discovery';
  if (ctx.causalConclusion) return 'self-improve-triage';
  return 'progress-gap';
}

/** The closed 6-stage sequence, in order (used by the E2E self-improve test). */
export const SELF_IMPROVEMENT_STAGES: readonly SelfImprovementStage[] = [
  'progress-gap',
  'self-improve-triage',
  'discovery',
  'skill-revised',
  'next-session-applied',
  'progress-recorded',
];

/**
 * A skill may be re-validated (confidence reset to 0.6, §2.2) only when the
 * user explicitly re-validates; otherwise decay governs.
 * `fromConfidence` is the confidence being replaced (audit provenance).
 */
export function revalidate(fromConfidence: number): number {
  void fromConfidence;
  return 0.6;
}
