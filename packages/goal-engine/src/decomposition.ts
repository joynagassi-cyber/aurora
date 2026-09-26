/**
 * Goal decomposition -> GoalProject assembly (dynamic-goal-engine.md).
 *
 * The LLM decomposes the NL goal into sub-goals; the Planner maps each
 * sub-goal to features; this module ASSEMBLES the result into a valid
 * `GoalProject` (frozen AD-15 types). It is the Result Normalizer check:
 * deterministic, pure, testable — no LLM call, no registry access here
 * (feature availability is validated by the caller against the
 * CapabilityRegistry before calling `assembleGoalProject`).
 */
import type {
  FeaturePlacement,
  GoalProgress,
  GoalProject,
  SubGoal,
  TimelineBlock,
} from '@aurora/domain';

/**
 * A decomposition spec — the typed output of the agent's goal
 * decomposition (LLM step). The planner hands it here; the assembled
 * `GoalProject` is then CONFIRMED with the user (CONFIRMATION_REQUIRED)
 * before it becomes active.
 */
export interface GoalDecomposition {
  /** the NL objective, verbatim */
  objective: string;
  /** measurable success criteria ("QCM >= 80%", "8/8 normes documentées") */
  successCriteria: string;
  /** optional deadline (ISO 8601) */
  targetDate?: string;
  horizon: GoalProject['horizon'];
  /** the sub-goals (the decomposition) */
  subGoals: Array<{
    label: string;
    /** the features that serve this sub-goal */
    features: string[];
    /** ordering hint (parallel = same sequence number) */
    sequence?: number;
    successCriteria: string;
  }>;
  /** explicit feature placements (role/frequency/position + config). */
  placements?: FeaturePlacement[];
  /** timeline blocks (feature / sub-goal scheduling). */
  timeline?: TimelineBlock[];
  /** the recognized composition pattern (hints for the UI layout). */
  pattern?: GoalProjectLayoutTag;
}

/**
 * The goal-shape tag rendered by the dashboard (goal-dashboard-ui.md S2).
 * The 5 patterns are internal composition hints, NOT user-facing labels —
 * the tag drives the LAYOUT only.
 */
export type GoalProjectLayoutTag =
  | 'preparation'
  | 'practice'
  | 'curation'
  | 'delivery'
  | 'adaptation'
  | 'custom';

export interface AssembleInput {
  /** the agent's decomposition */
  decomposition: GoalDecomposition;
  userId: string;
  /** the GoalProject row id (ULID/uuid generated at creation time) */
  goalId: string;
  /** now (server time, ISO 8601 — deterministic for tests) */
  now: string;
}

/**
 * Assemble a valid `GoalProject` from a decomposition spec.
 *
 * Invariants (Result Normalizer):
 *  - every sub-goal's features are placed exactly once in `features`
 *    (union across sub-goals, deduplicated, order-preserving);
 *  - sequence numbers are normalized (parallel = same number);
 *  - initial sub-goal statuses: first sequence = 'active', rest 'pending';
 *  - initial `GoalProgress`: 0% everywhere, empty OR-Set evidence refs
 *    (Progress will fill it — F-07 sole producer).
 */
export function assembleGoalProject(input: AssembleInput): GoalProject {
  const { decomposition: d, userId, goalId, now } = input;

  if (!d.objective.trim()) {
    throw new Error('goal-engine/empty_objective');
  }

  // Normalize sub-goals (dedupe ids by index, sequence auto-assigned).
  const subGoals: SubGoal[] = d.subGoals.map((s, i) => {
    if (!s.label.trim()) {
      throw new Error(`goal-engine/empty_subgoal_label: index ${i}`);
    }
    return {
      id: `sg_${i + 1}`,
      label: s.label,
      features: [...s.features],
      sequence: s.sequence ?? i + 1,
      successCriteria: s.successCriteria,
      status: i === 0 ? 'active' : 'pending',
    };
  });

  // Union of sub-goal features, deduplicated, order-preserving; explicit
  // placements (when provided) win, otherwise a default placement per
  // feature (role/frequency/position filled by the planner later).
  const unionFeatures = unique(
    subGoals.flatMap((s) => s.features),
  );
  const placements: FeaturePlacement[] =
    d.placements && d.placements.length > 0
      ? d.placements
      : unionFeatures.map((featureId) => ({
          featureId,
          role: 'default',
          frequency: 'on-event',
          position: '',
          config: {},
        }));

  // Validation: an explicit placement must reference a known feature of a
  // sub-goal (the Normalizer's "inputs match outputs" check, AD-15 shapes).
  const known = new Set(unionFeatures);
  for (const p of placements) {
    if (!known.has(p.featureId) && d.placements?.length) {
      throw new Error(`goal-engine/unknown_placement_feature: ${p.featureId}`);
    }
  }

  const progress: GoalProgress = {
    overallPct: 0,
    subGoalProgress: Object.fromEntries(subGoals.map((s) => [s.id, 0])),
    lastUpdated: now,
    evidenceRefs: [], // empty OR-Set — Progress fills it (F-07 sole producer)
  };

  return {
    id: goalId,
    userId,
    objective: d.objective,
    successCriteria: d.successCriteria,
    targetDate: d.targetDate,
    horizon: d.horizon,
    subGoals,
    features: placements,
    timeline: d.timeline ?? [],
    progress,
    status: 'active',
    createdAt: now,
    updatedAt: now,
  };
}

/**
 * Recompose (ADR S13: "recalcul du planning restant sans détruire
 * l'historique"): replace the composition (sub-goals/placements/timeline)
 * of an EXISTING GoalProject while PRESERVING progress + history. The
 * recomposition is recorded (`recomposedAt`); sub-goal ids of still-matching
 * sub-goals keep their progress, new sub-goals start at 0.
 */
export function recomposeGoalProject(
  current: GoalProject,
  spec: GoalDecomposition,
  now: string,
): GoalProject {
  if (current.status === 'completed' || current.status === 'abandoned') {
    throw new Error(`goal-engine/recompose_on_terminal_goal: ${current.status}`);
  }
  const fresh = assembleGoalProject({
    decomposition: spec,
    userId: current.userId,
    goalId: current.id,
    now,
  });

  // Carry over progress for sub-goals whose label survives the recomposition
  // (history is never destroyed — ADR S13).
  const byLabel = new Map(current.subGoals.map((s) => [s.label, s]));
  const subGoalProgress: Record<string, number> = {};
  for (const s of fresh.subGoals) {
    const kept = byLabel.get(s.label);
    const prev = current.progress.subGoalProgress[s.id];
    subGoalProgress[s.id] = kept
      ? (kept.id !== s.id ? current.progress.subGoalProgress[kept.id] : prev) ?? 0
      : (prev ?? 0);
  }
  const overallPct =
    Object.keys(subGoalProgress).length === 0
      ? 0
      : Math.round(
          Object.values(subGoalProgress).reduce((a, b) => a + b, 0) /
            Object.keys(subGoalProgress).length,
        );

  return {
    ...fresh,
    status: current.status === 'paused' ? 'paused' : 'active',
    progress: {
      ...fresh.progress,
      overallPct,
      subGoalProgress,
      lastUpdated: now,
    },
    recomposedAt: now,
    createdAt: current.createdAt,
  };
}

/** Validate a `GoalProject` for persistence (the Normalizer gate). */
export function validateGoalProject(g: GoalProject): string[] {
  const problems: string[] = [];
  if (!g.id) problems.push('missing_id');
  if (!g.userId) problems.push('missing_user_id');
  if (!g.objective.trim()) problems.push('empty_objective');
  if (g.subGoals.length === 0) problems.push('no_sub_goals');
  const ids = new Set<string>();
  for (const s of g.subGoals) {
    if (ids.has(s.id)) problems.push(`duplicate_sub_goal:${s.id}`);
    ids.add(s.id);
    if (s.features.length === 0) problems.push(`sub_goal_without_features:${s.id}`);
  }
  const fids = new Set<string>();
  for (const p of g.features) {
    if (fids.has(p.featureId)) problems.push(`duplicate_placement:${p.featureId}`);
    fids.add(p.featureId);
  }
  if (g.progress.overallPct < 0 || g.progress.overallPct > 100) {
    problems.push('overall_pct_out_of_range');
  }
  return problems;
}

/** Unique, order-preserving. */
function unique<T>(arr: readonly T[]): T[] {
  return [...new Set(arr)];
}
