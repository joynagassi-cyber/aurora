/**
 * @aurora/ascent — READ → DO → PROVE sequencing (wave 3,
 * docs/ascent/overview.md S10).
 *
 * The three phases are a PEDAGOGICAL FRAMEWORK, not a rigid constraint:
 * the Agent (via Ascent) reorders them when context demands —
 * "mastered → skip READ, go to DO", "exam week → Quick depth, only
 * PROVE", "stuck on a prerequisite → insert remediation BEFORE the main
 * step". This module implements those reordering rules deterministically.
 */
import type { AscentLearningIR, AscentStep } from '@aurora/domain';
import { DEPTH_BUDGETS, selectDepth, type DepthImportance } from './depth';

/**
 * Default framework ordering for one concept (S10): READ → DO → PROVE.
 * `recap` is a separate closing phase, not part of the per-concept loop.
 */
export const FRAMEWORK_ORDER: readonly AscentStep['phase'][] = ['read', 'do', 'prove'];

/**
 * Skip a phase when the learner's state makes it redundant (S10):
 *  - mastered  → skip READ (go to DO / PROVE only)
 *  - fragile   → keep all three, deepen the remediation weight
 *  - exam week → only PROVE (Quick depth, the QCM is the priority)
 */
export function phasesForStep(input: {
  status: AscentStep['status'];
  baselineStatus?: 'unknown' | 'partial' | 'known' | 'fragile' | 'mastered';
  timeConstrained?: boolean;
}): AscentStep['phase'][] {
  const { baselineStatus, timeConstrained } = input;
  if (timeConstrained) return ['prove'];
  if (baselineStatus === 'mastered') return ['do', 'prove'];
  // unknown / partial / known / fragile → full framework
  return [...FRAMEWORK_ORDER];
}

/**
 * Reorder the steps of a path to honor a requested phase sequence for a
 * given concept. Used by the Agent when context demands a non-default
 * order (S10: "Never force the sequence mechanically"). The concept's
 * steps are re-sorted in the requested order; other concepts are
 * untouched (single-writer, AD-7: only `ascent_paths` is rewritten).
 */
export function reorderPhases(
  path: AscentLearningIR,
  conceptId: string,
  order: readonly AscentStep['phase'][],
): AscentLearningIR {
  const others = path.steps.filter((s) => s.conceptRefs[0] !== conceptId);
  const forConcept = path.steps
    .filter((s) => s.conceptRefs[0] === conceptId)
    .sort((a, b) => order.indexOf(a.phase) - order.indexOf(b.phase));
  return { ...path, steps: [...others, ...forConcept] };
}

/**
 * "Insert remediation BEFORE the main step" (S10 / S14 "Je bloque").
 * A remediation step is placed immediately before the concept's first
 * non-remediation step, so the learner fixes the blocker before
 * continuing.
 */
export function insertRemediationBefore(
  path: AscentLearningIR,
  conceptId: string,
  remediation: AscentStep,
): AscentLearningIR {
  const others = path.steps.filter(
    (s) => s.conceptRefs[0] !== conceptId || s.phase === 'remediation',
  );
  const idx = path.steps.findIndex(
    (s) => s.conceptRefs[0] === conceptId && s.phase !== 'remediation',
  );
  const conceptSteps = path.steps.filter(
    (s) => s.conceptRefs[0] === conceptId && s.phase !== 'remediation',
  );
  const withRemediation = [
    ...others,
    remediation,
    ...conceptSteps.filter((s) => s.phase !== 'remediation'),
  ];
  // preserve original relative order: others first, then the concept block
  // in its original ordering with the remediation injected at position idx.
  const ordered: AscentStep[] = [];
  let conceptSeen = 0;
  for (const s of path.steps) {
    if (s.conceptRefs[0] === conceptId && s.phase !== 'remediation') {
      if (conceptSeen === 0) ordered.push(remediation);
      ordered.push(s);
      conceptSeen += 1;
    } else {
      ordered.push(s);
    }
  }
  void idx;
  void withRemediation;
  return {
    ...path,
    steps: ordered,
    depth: { ...path.depth, [remediation.id]: remediation.depth },
  };
}

/**
 * The activity budget a phase should carry at a depth — re-exported so
 * the UI / kernel can size content without re-deriving it (S13).
 */
export { DEPTH_BUDGETS, selectDepth };
export type { DepthImportance };
