/**
 * Expert Skills — the 4 self-improvement extensions (ADR S14,
 * docs/agent/expert-skills-extensions.md, wave 3 task 4).
 *
 * The deterministic feedback loop lives in the kernel's Memory
 * component (memory.ts); the 4 extensions are the rules that move a
 * skill through its lifecycle:
 *
 *   §2.1 Contrastive Strategy Evaluation
 *       — one success is NOT a skill. Minimum 2 contrastive pairs
 *         before confidence may exceed 0.6 (causal, not coincidental).
 *   §2.2 Confidence Decay (temporal)
 *       — closed-form, NOT an LLM judgment:
 *         conf(t) = conf0 · exp(-λ·(t-t_val)/30) · recency_boost,
 *         λ per skill type (planning 0.3, learning 0.1, discipline 0.5).
 *       < 0.3 = flag for re-evaluation; < 0.1 = auto-archive.
 *   §2.3 Auto-generated Triage Hypotheses (failing fast)
 *       — stagnation → a LOW-confidence (0.2) HYPOTHESIS with a 14-day
 *         evidence window. Validated → skill (0.5); no evidence →
 *         expired (data kept, NEVER pollutes the profile).
 *   §2.4 Cognitive-Drift Firewall (anti-regression)
 *       — an established skill (conf ≥ 0.5, active) CANNOT be modified
 *         on a single anomalous cycle. Minimum 3 independent cycles
 *         with the same motif. Below 3 → the anomaly is an INCIDENT
 *         (ProgressEvidence type='exception'), not skill evidence.
 *
 * User authority always wins (§2.4 exception): an explicit "stop
 * using this strategy" archives immediately, bypassing the firewall.
 *
 * Data model (01 S4.7, server-only, AD-3 / 03 S4.2):
 *   expert_skills, skill_hypotheses, contrastive_pairs,
 *   skill_validation_log — all RLS-isolated per user, no local mirror.
 *
 * This module is PURE (no I/O) — the server adapters (fn-agent-run)
 * persist through the ports; the rules here are the deterministic
 * core the tests pin.
 */
import type { ExpertSkill } from '@aurora/domain';

/* ------------------------------------------------------------------ */
/* §2.1 Contrastive strategy evaluation                                 */
/* ------------------------------------------------------------------ */

/** A paired session (success A vs failure B) — the ADR S18.4 causal unit. */
export interface ContrastivePair {
  id: string;
  userId: string;
  /** the skill being validated */
  skillId: string;
  successSnapshotId: string;
  failureSnapshotId: string;
  /** which context variables diverge (start_time, energy_level, …) */
  divergentVariables: string[];
  /** the causal conclusion ("timing + energy", NOT "content difficulty") */
  conclusion: string;
  /** +0.1 / -0.1 applied to the skill's confidence */
  confidenceDelta: number;
  createdAt: string;
}

/**
 * §2.1 rule: minimum 2 pairs before a skill's confidence may exceed
 * 0.6. One success is NOT a skill — it is NOT promotable. Returns the
 * confidence adjusted by each pair's delta (clamped 0..1) + whether it
 * may now be promoted (MemoryEngine.promote() enforces the same rule).
 */
export function contrastiveConfidence(
  base: number,
  pairs: readonly ContrastivePair[],
): { confidence: number; promotable: boolean; pairs: number } {
  let c = base;
  for (const p of pairs) c += p.confidenceDelta;
  c = Math.max(0, Math.min(1, c));
  return {
    confidence: c,
    pairs: pairs.length,
    // the 2-pair floor (the hard rule) AND the > 0.6 confidence gate
    promotable: pairs.length >= 2 && c > 0.6,
  };
}

/**
 * The causal read of a pair's divergent variables (ADR S18.4:
 * correlation != causation). The conclusion string is what the skill's
 * constraint will carry ("only activate when energy >= medium AND
 * interruptions < 2 in the prior hour").
 */
export function divergentConclusion(pair: Pick<ContrastivePair, 'divergentVariables'>): string {
  const v = pair.divergentVariables;
  const timing = v.some((x) => x === 'start_time' || x === 'time_of_day');
  const energy = v.some((x) => x === 'energy_level');
  const interruptions = v.some((x) => x === 'interruption_count');
  if (timing && energy) return 'timing + energy';
  if (energy) return 'energy';
  if (interruptions) return 'interruptions';
  if (v.length > 0) return v.join(' + ');
  return 'unknown — no divergent variable (cannot attribute)';
}

/* ------------------------------------------------------------------ */
/* §2.2 Confidence decay (temporal) — closed-form, deterministic        */
/* ------------------------------------------------------------------ */

/** Per-skill-type decay rate λ (per 30 days), §2.2 table. */
export const DECAY_LAMBDA: Record<SkillType, number> = {
  planning: 0.3,
  learning: 0.1,
  discipline: 0.5,
};

export type SkillType = 'planning' | 'learning' | 'discipline';

export interface DecayInput {
  /** confidence at last validation (conf0) */
  confidence0: number;
  /** days since last verification (t - t_validation) */
  daysSinceValidation: number;
  /** selects λ (the type is the calibration, NOT a single constant) */
  type: SkillType;
  /** +0.1 multiplier when a ProgressEvidence in the last 7 days re-confirms */
  recencyBoost?: boolean;
}

/**
 * confidence(t) = conf0 · exp(-λ · (days/30)) · (1.1 if recency).
 * Deterministic math — "the decay is a formula, not the AI thinking it
 * might be outdated" (§2.2). Clamped to [0, 1].
 */
export function confidenceAt(input: DecayInput): number {
  const lambda = DECAY_LAMBDA[input.type];
  const decayed = input.confidence0 * Math.exp((-lambda * input.daysSinceValidation) / 30);
  const boosted = input.recencyBoost ? decayed * 1.1 : decayed;
  return Math.max(0, Math.min(1, boosted));
}

/** §2.2 thresholds. */
export const REEVALUATION_THRESHOLD = 0.3;
export const AUTO_ARCHIVE_THRESHOLD = 0.1;

export interface DecayVerdict {
  confidence: number;
  /** < 0.3 (and ≥ 0.1): the Agent asks "still applicable?" (user decides) */
  flagForReevaluation: boolean;
  /** < 0.1: auto-archive (data kept, NOT deleted, not active) */
  autoArchive: boolean;
}

/** Apply the §2.2 thresholds to the decayed confidence. */
export function decayVerdict(input: DecayInput): DecayVerdict {
  const confidence = confidenceAt(input);
  return {
    confidence,
    flagForReevaluation:
      confidence < REEVALUATION_THRESHOLD && confidence >= AUTO_ARCHIVE_THRESHOLD,
    autoArchive: confidence < AUTO_ARCHIVE_THRESHOLD,
  };
}

/**
 * §2.2 re-validation: the user explicitly re-validates → confidence
 * resets to 0.6 (the floor for an established skill), validation_date
 * = now. The audit log (skill_validation_log) records the transition.
 */
export const REVALIDATE_CONFIDENCE = 0.6;

/* ------------------------------------------------------------------ */
/* §2.3 Auto-generated triage hypotheses (failing fast)                */
/* ------------------------------------------------------------------ */

export interface HypothesisInput {
  userId: string;
  /** null if brand-new (not yet a skill) */
  skillId?: string;
  trigger: string;
  proposedAction: string;
  /** the 14-day evidence window (the default, §2.3) */
  evidenceWindowDays?: number;
  createdAt: string;
}

export interface SkillHypothesis {
  id: string;
  userId: string;
  skillId?: string;
  trigger: string;
  proposedAction: string;
  /** ALWAYS < 0.3 at creation (§2.3: low-confidence, untested) */
  confidence: number;
  status: 'hypothesis' | 'testing' | 'validated' | 'rejected' | 'expired';
  evidenceWindowDays: number;
  createdAt: string;
  resolvedAt?: string;
}

/**
 * §2.3: when Progress detects stagnation, generate a LOW-confidence
 * HYPOTHESIS (not a skill yet) to test in 14 days. A hypothesis NEVER
 * pollutes the longitudinal profile if rejected — it is a data point,
 * not a rule.
 */
export function generateHypothesis(input: HypothesisInput): SkillHypothesis {
  return {
    id: `hyp-${input.userId}-${Date.now()}`,
    userId: input.userId,
    skillId: input.skillId,
    trigger: input.trigger,
    proposedAction: input.proposedAction,
    confidence: 0.2, // always < 0.3 at creation (§2.3)
    status: 'hypothesis',
    evidenceWindowDays: input.evidenceWindowDays ?? 14,
    createdAt: input.createdAt,
  };
}

export type HypothesisEvidence = 'supports' | 'contradicts' | 'absent';

/**
 * §2.3 lifecycle: within the window a supporting ProgressEvidence
 * promotes to `validated` (0.5); negative evidence or window expiry
 * → `rejected` / `expired`. Data is preserved (NOT deleted) so the
 * Agent knows "this was tried and failed."
 */
export function resolveHypothesis(
  h: SkillHypothesis,
  evidence: HypothesisEvidence,
  daysElapsed: number,
  at: string,
): SkillHypothesis {
  const expired = daysElapsed >= h.evidenceWindowDays;
  if (evidence === 'supports' && !expired) {
    return { ...h, status: 'validated', confidence: 0.5, resolvedAt: at };
  }
  if (evidence === 'contradicts') {
    return { ...h, status: 'rejected', resolvedAt: at };
  }
  // absent → auto-expire past the window, else still 'testing'
  if (expired) return { ...h, status: 'expired', resolvedAt: at };
  return { ...h, status: 'testing' };
}

/* ------------------------------------------------------------------ */
/* §2.4 Cognitive-drift firewall (anti-regression)                     */
/* ------------------------------------------------------------------ */

export interface AnomalyCycle {
  /** ISO date of the cycle (a WEEK, not a day) */
  at: string;
  /** the motif observed ("skipped after a 2-hour lecture") */
  motif: string;
}

export interface FirewallInput {
  /** the established skill's current confidence */
  confidence: number;
  status: ExpertSkill['status'];
  /** independent anomalous cycles with the same motif */
  anomalousCycles: readonly AnomalyCycle[];
}

export const FIREWALL_MIN_CYCLES = 3;
export const ESTABLISHED_THRESHOLD = 0.5;

export interface FirewallVerdict {
  /** whether the skill may be modified (archived / confidence reduced) */
  skillAdjustable: boolean;
  /** < min → the anomaly is an INCIDENT (ProgressEvidence type='exception') */
  logAsIncident: boolean;
  reason: string;
}

/**
 * §2.4: an established skill (conf ≥ 0.5, active) CANNOT be modified on
 * a single anomalous cycle. Minimum 3 INDEPENDENT cycles (weeks, not
 * days) with the same motif. Below 3 → incident, not evidence.
 */
export function firewallVerdict(input: FirewallInput): FirewallVerdict {
  const established =
    input.confidence >= ESTABLISHED_THRESHOLD && input.status === 'validated';
  if (!established) {
    // a candidate / low-confidence skill has no firewall protection
    return { skillAdjustable: true, logAsIncident: false, reason: 'not established (no firewall)' };
  }
  const firstMotif = input.anomalousCycles[0]?.motif ?? '';
  const same = input.anomalousCycles.filter((c) => c.motif === firstMotif).length;
  if (same >= FIREWALL_MIN_CYCLES) {
    return {
      skillAdjustable: true,
      logAsIncident: false,
      reason: `${same} independent cycles (≥ ${FIREWALL_MIN_CYCLES}) — adjust the skill`,
    };
  }
  return {
    skillAdjustable: false,
    logAsIncident: true,
    reason: `firewall: ${same} anomalous cycle(s) < ${FIREWALL_MIN_CYCLES} — logged as incident, skill unchanged`,
  };
}

/**
 * §2.4 exception: user EXPLICITLY says "stop using this strategy" →
 * immediate archive (user authority > firewall). Also: the skill's
 * obsolescence condition is met and the context changed → auto-archive
 * (deterministic, not pattern detection).
 */
export function userOverride(input: {
  userExplicitlyStopped?: boolean;
  obsolescenceConditionMet?: boolean;
}): { archiveImmediately: boolean; reason: string } {
  if (input.userExplicitlyStopped) {
    return { archiveImmediately: true, reason: 'user explicit stop (authority > firewall)' };
  }
  if (input.obsolescenceConditionMet) {
    return { archiveImmediately: true, reason: 'obsolescence condition met + context changed' };
  }
  return { archiveImmediately: false, reason: 'no override — firewall governs' };
}

/* ------------------------------------------------------------------ */
/* The 4-extension verdict for one skill (the Memory component seam)   */
/* ------------------------------------------------------------------ */

export interface SkillLifecycleInput {
  skill: Pick<ExpertSkill, 'id' | 'confidence' | 'status'>;
  skillType: SkillType;
  daysSinceValidation: number;
  recencyBoost?: boolean;
  pairs: readonly ContrastivePair[];
  anomalies: readonly AnomalyCycle[];
  userExplicitlyStopped?: boolean;
  obsolescenceConditionMet?: boolean;
}

/**
 * The full 4-extension verdict for a skill: decay → contrastive →
 * hypothesis → firewall, in that order. Returns the next confidence
 * + status + the audit events to log (skill_validation_log).
 * Pure — no I/O.
 */
export function skillLifecycle(input: SkillLifecycleInput): {
  confidence: number;
  status: ExpertSkill['status'];
  /** skill_validation_log events (the ADR S14.5 audit trail) */
  logEvents: Array<{ event: string; detail: Record<string, unknown> }>;
} {
  const logEvents: Array<{ event: string; detail: Record<string, unknown> }> = [];
  let { confidence } = input.skill;
  let status: ExpertSkill['status'] = input.skill.status;

  // 1. user authority (§2.4 exception) — overrides everything
  const ov = userOverride({
    userExplicitlyStopped: input.userExplicitlyStopped,
    obsolescenceConditionMet: input.obsolescenceConditionMet,
  });
  if (ov.archiveImmediately) {
    return { confidence, status: 'deprecated', logEvents: [{ event: 'archived', detail: { reason: ov.reason } }] };
  }

  // 2. temporal decay (§2.2)
  const dec = decayVerdict({
    confidence0: confidence,
    daysSinceValidation: input.daysSinceValidation,
    type: input.skillType,
    recencyBoost: input.recencyBoost,
  });
  confidence = dec.confidence;
  logEvents.push({ event: 'decayed', detail: { confidence } });
  if (dec.autoArchive) {
    logEvents.push({ event: 'archived', detail: { reason: `auto-archive conf ${confidence.toFixed(3)} < 0.1` } });
    return { confidence, status: 'deprecated', logEvents };
  }
  if (dec.flagForReevaluation) {
    logEvents.push({ event: 'reevaluation', detail: { confidence, flag: 're-evaluation' } });
  }

  // 3. contrastive pairs (§2.1)
  const cc = contrastiveConfidence(confidence, input.pairs);
  confidence = cc.confidence;
  if (cc.promotable && status === 'candidate') {
    status = 'validated';
    logEvents.push({ event: 'revalidated', detail: { pairs: cc.pairs, confidence } });
  }

  // 4. cognitive-drift firewall (§2.4) — anomaly-driven reduction only
  const fw = firewallVerdict({
    confidence,
    status: status === 'validated' ? 'validated' : status,
    anomalousCycles: input.anomalies,
  });
  if (fw.logAsIncident) {
    logEvents.push({ event: 'incident', detail: { reason: fw.reason, confidence } });
  } else if (fw.skillAdjustable && input.anomalies.length >= FIREWALL_MIN_CYCLES && confidence >= ESTABLISHED_THRESHOLD) {
    // 3+ cycles: reduce confidence (re-validation floor) — the skill
    // is adjusted, not deleted (data preserved).
    confidence = REVALIDATE_CONFIDENCE;
    logEvents.push({ event: 'revalidated', detail: { reason: fw.reason, confidence } });
  }

  return { confidence, status, logEvents };
}
