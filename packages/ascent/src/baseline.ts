/**
 * @aurora/ascent — baseline (wave 3, W3-E2, docs/ascent/overview.md S6.2).
 *
 * Computes the `LearnerBaseline` from Progress `SkillState` rows (01 S4.4,
 * 03 S4.2 limited mirror: `skill_states` + `progress_snapshots`).
 *
 * Invariants:
 *  - AD-15: projects the domain `SkillState` — never re-declares its
 *    vocabulary (the 8-level `level` scale maps ONTO the 5 baseline
 *    states; the mapping is Ascent's, the scale is Progress').
 *  - 5-state rule (overview S6.2): NEVER a single 0-100 score. The
 *    `dimensions` are derived, optional, and each stays 0..1.
 *  - ASSENT = READ-ONLY consumer of Progress: this file writes nothing.
 */
import type {
  LearnerBaseline,
  SkillState,
} from '@aurora/domain';

/**
 * Map the Progress 8-level scale (ADR S18.2) onto the baseline's 5 states.
 * The mapping is monotone: higher observed level → stronger state.
 *
 *   discovered / comprehended  -> unknown | partial (seen but not usable)
 *   recalled / guided-app      -> known     (retrievable / guided)
 *   autonomous-app / novel     -> fragile   (usable, not yet robust)
 *   mastered / expert          -> mastered
 *
 * `recalled` splits on confidence: >= 0.5 → 'known', below → 'partial'.
 */
export function mapLevelToBaselineState(
  level: SkillState['level'],
  confidence?: number,
): LearnerBaseline['skillStates'][number]['status'] {
  switch (level) {
    case 'discovered':
      return 'unknown';
    case 'comprehended':
      return 'partial';
    case 'recalled':
      return (confidence ?? 0.5) >= 0.5 ? 'known' : 'partial';
    case 'guided-application':
      return 'known';
    case 'autonomous-application':
      return 'fragile';
    case 'novel-problem':
      return 'fragile';
    case 'mastered':
      return 'mastered';
    case 'expert':
      return 'mastered';
    default:
      // closed AD-9/ADR S18.2 vocabulary — unreachable; be loud.
      throw new Error(`ascent/unknown_skill_level: ${String(level)}`);
  }
}

/**
 * Derive the optional multi-dimensional picture (S6.2). Each dimension is
 * a 0..1 heuristic off the observed level + confidence — NEVER a global
 * score. A skill "mastered in understanding but fragile in application"
 * must stay expressible, so understanding and application diverge.
 */
function deriveDimensions(
  state: LearnerBaseline['skillStates'][number]['status'],
  confidence: number,
): LearnerBaseline['skillStates'][number]['dimensions'] {
  const c = clamp01(confidence);
  switch (state) {
    case 'unknown':
      return { understanding: c * 0.2, recall: 0, application: 0, autonomy: 0, retention: 0 };
    case 'partial':
      return { understanding: 0.4, recall: c * 0.3, application: 0.1, autonomy: 0, retention: c * 0.2 };
    case 'known':
      return { understanding: 0.8, recall: c, application: c * 0.4, autonomy: c * 0.2, retention: c * 0.5 };
    case 'fragile':
      return { understanding: 0.9, recall: 0.8, application: c, autonomy: c * 0.6, retention: c * 0.5 };
    case 'mastered':
      return { understanding: 1, recall: 0.9, application: c, autonomy: c, retention: c * 0.9 };
  }
}

function clamp01(n: number): number {
  return Math.max(0, Math.min(1, n));
}

/**
 * Build a `LearnerBaseline` from the user's Progress skill states.
 *
 * - One entry per `SkillState`; state + dimensions derived (above).
 * - `lastEvidence` = the state's newest evidence ref (evidenceRefs are a
 *   CRDT OR-Set of `{v, ts, c}` — v = evidence id).
 * - `freshness` = the state's `updatedAt` (03 S4.2: skill_states are
 *   mirrored, so `updatedAt` is the honest staleness marker).
 * - Gaps/fragiles/mastered are the DERIVED buckets (S6.2), computed from
 *   `status` — not hand-maintained lists.
 */
export function computeLearnerBaseline(
  userId: string,
  skillStates: SkillState[],
  now: string,
): LearnerBaseline {
  const skillStatesOut: LearnerBaseline['skillStates'] = skillStates.map((s) => {
    const confidence = s.confidence ?? 0.5;
    const status = mapLevelToBaselineState(s.level, s.confidence);
    const evidenceRefs = s.evidenceRefs;
    const lastEvidence = evidenceRefs.length
      ? evidenceRefs.reduce((latest, ref) =>
          ref.ts > latest.ts ? ref : latest,
        ).v
      : '';
    return {
      skillId: s.skillId,
      status,
      dimensions: deriveDimensions(status, confidence),
      lastEvidence,
      freshness: s.updatedAt,
    };
  });

  const byStatus = (pred: (s: (typeof skillStatesOut)[number]) => boolean) =>
    skillStatesOut.filter(pred).map((s) => s.skillId);

  return {
    userId,
    skillStates: skillStatesOut,
    gaps: byStatus((s) => s.status === 'unknown' || s.status === 'partial'),
    fragiles: byStatus((s) => s.status === 'fragile'),
    mastered: byStatus((s) => s.status === 'mastered'),
    computedAt: now,
  };
}
