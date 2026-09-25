/**
 * Progress module — conditional trajectories (ADR S18.5) + causal analysis
 * (ADR S18.4).
 *
 * Trajectories are PLANNING AIDS, NOT predictions (S18.5 discipline):
 * "maintain current pace / more time / strategy change / reduced load /
 * unblock". Causal analysis distinguishes correlation from causation
 * (S18.4): factors are tagged, and the output carries an explicit
 * `correlationOnly` flag so the UI never over-claims.
 */
import type {
  ProgressTrajectoryScenario,
  SkillState,
} from '@aurora/domain';

/** The hypothesis vocabulary (ADR S18.5). */
export type TrajectoryHypothesis =
  | 'maintain-pace'
  | 'increase-time'
  | 'change-strategy'
  | 'reduce-load'
  | 'unblock';

export const TRAJECTORY_HYPOTHESES: readonly TrajectoryHypothesis[] = [
  'maintain-pace',
  'increase-time',
  'change-strategy',
  'reduce-load',
  'unblock',
];

/** A causal factor tag (ADR S18.4 discipline: factor vs outcome). */
export type CausalFactor =
  | 'strategy'
  | 'time-available'
  | 'regularity'
  | 'difficulty'
  | 'load'
  | 'interruptions'
  | 'resource-quality'
  | 'recurring-errors'
  | 'prior-understanding'
  | 'plan-change';

export const CAUSAL_FACTORS: readonly CausalFactor[] = [
  'strategy',
  'time-available',
  'regularity',
  'difficulty',
  'load',
  'interruptions',
  'resource-quality',
  'recurring-errors',
  'prior-understanding',
  'plan-change',
];

export interface TrajectoryInput {
  userId: string;
  /** the skill / goal the scenario is about */
  subject: string;
  /** the current state the scenario starts from (S18.5) */
  state: SkillState;
  /** the hypothesis (the condition that changes the path) */
  hypothesis: TrajectoryHypothesis;
  /** minutes available per week, for time-based scenarios */
  minutesPerWeek?: number;
  now: string;
}

/**
 * Project a conditional trajectory from the observed state (S18.5).
 * Deterministic: same input → same projection. The projection is a
 * straight-line level walk over a 12-week horizon, scaled by the
 * hypothesis multiplier. It is a planning aid — callers must render it
 * as "if X, then Y", never as a forecast.
 */
export function projectTrajectory(input: TrajectoryInput): ProgressTrajectoryScenario {
  const step: Record<TrajectoryHypothesis, number> = {
    'maintain-pace': 1,
    'increase-time': 1.5,
    'change-strategy': 1.2,
    'reduce-load': 0.8,
    unblock: 2,
  };
  const startOrdinal = ordinalOf(input.state.level);
  const mult = step[input.hypothesis] ?? 1;
  const horizonWeeks = 12;
  const points: ProgressTrajectoryScenario['projectedPoints'] = [];
  for (let w = 0; w <= horizonWeeks; w += 3) {
    const level = ordinalToLevel(startOrdinal + Math.round(w * 0.1 * mult));
    points.push({
      at: isoWeeksLater(input.now, w),
      level,
      confidence: Math.max(0, 1 - w / horizonWeeks),
    });
  }
  return {
    id: '',
    userId: input.userId,
    subject: input.subject,
    hypothesis: input.hypothesis,
    projectedPoints: points,
    nextAction: nextActionFor(input.hypothesis),
    createdAt: input.now,
  };
}

/** The recommended next action for each hypothesis (S18.5 "what next?"). */
export function nextActionFor(h: TrajectoryHypothesis): string {
  const a: Record<TrajectoryHypothesis, string> = {
    'maintain-pace': 'Conserver le rythme actuel',
    'increase-time': 'Libérer du temps (time-blocking)',
    'change-strategy': 'Changer de stratégie d’apprentissage',
    'reduce-load': 'Réduire la charge pour consolider',
    unblock: 'Débloquer le point fragile identifié',
  };
  return a[h];
}

/**
 * Causal analysis (S18.4): tag the factors that explain a stagnation /
 * regression. The discipline: each factor is marked `correlationOnly`
 * unless a controlled contrast backs it — we NEVER claim causation from
 * raw co-occurrence.
 */
export interface CausalAnalysisInput {
  userId: string;
  subject: string;
  /** observed direction (a stagnation/regression window) */
  direction: 'plateau' | 'regressing' | 'forgotten';
  /** the candidate factors observed in the window */
  factors: CausalFactor[];
  /** which factors have a controlled contrast (true causation signal) */
  controlled?: CausalFactor[];
  now: string;
}

export interface CausalFinding {
  factor: CausalFactor;
  /** true when only co-occurrence was observed (no controlled contrast) */
  correlationOnly: boolean;
  /** the action that would test this factor (turning correlation into
   *  causation — the "next experiment" the user can run) */
  experiment?: string;
}

export interface CausalAnalysis {
  userId: string;
  subject: string;
  direction: CausalAnalysisInput['direction'];
  findings: CausalFinding[];
  /** the factor most likely to explain the window (for the drill-down) */
  primaryFactor?: CausalFactor;
  at: string;
}

/** Run the causal analysis (S18.4 discipline: correlation ≠ causation). */
export function causalAnalysis(input: CausalAnalysisInput): CausalAnalysis {
  const controlled = new Set(input.controlled ?? []);
  const findings: CausalFinding[] = input.factors.map((f) => ({
    factor: f,
    correlationOnly: !controlled.has(f),
    experiment: experimentFor(f),
  }));
  // Primary = first controlled factor, else first factor (best-effort,
  // deterministic order = input order, no invented ranking).
  const primary =
    input.factors.find((f) => controlled.has(f)) ?? input.factors[0];
  return {
    userId: input.userId,
    subject: input.subject,
    direction: input.direction,
    findings,
    primaryFactor: primary,
    at: input.now,
  };
}

/** The experiment that would test a given factor (S18.4: test, don't
 *  assume). */
export function experimentFor(f: CausalFactor): string {
  const m: Record<CausalFactor, string> = {
    strategy: 'Tester une autre méthode sur le même chapitre 2 semaines',
    'time-available': 'Mesurer le temps réellement disponible vs planifié',
    regularity: 'Fixer 3 créneaux fixes et mesurer le respect',
    difficulty: 'Relancer des exercices un cran au-dessus du niveau actuel',
    load: 'Réduire la charge 1 semaine et observer la retenue',
    interruptions: 'Quantifier les interruptions pendant un créneau focus',
    'resource-quality': 'Réétudier avec une ressource de référence vérifiée',
    'recurring-errors': 'Réviser les erreurs récurrentes avant de passer au suivant',
    'prior-understanding': 'Valider les prérequis avant le chapitre',
    'plan-change': 'Stabiliser le plan 30 jours avant de comparer',
  };
  return m[f] ?? '';
}

// — internal helpers (level scale shared with dashboard.ts) —

const ORDINALS: readonly SkillState['level'][] = [
  'discovered',
  'comprehended',
  'recalled',
  'guided-application',
  'autonomous-application',
  'novel-problem',
  'mastered',
  'expert',
];

function ordinalOf(level: SkillState['level']): number {
  const i = ORDINALS.indexOf(level);
  return i < 0 ? 0 : i;
}
function ordinalToLevel(n: number): SkillState['level'] {
  const clamped = Math.max(0, Math.min(ORDINALS.length - 1, n));
  return ORDINALS[clamped] ?? 'discovered';
}
function isoWeeksLater(iso: string, weeks: number): string {
  const d = new Date(Date.parse(iso) + weeks * 7 * 86_400_000);
  return d.toISOString();
}
