/**
 * GoalProgress evaluation (dynamic-goal-engine.md + F-07).
 *
 * Progress is the SOLE producer of `progress_evidences` +
 * `ProgressEvidenceCreated` (F-07). This module does NOT emit events — it
 * computes the `GoalProgress` value that the Progress module persists:
 * overall % from per-sub-goal %, and the next-action / suggestion
 * derivations the dashboard context strip needs (goal-dashboard-ui.md S4:
 * the suggestion is a NL sentence, not a system message).
 */
import type { GoalProject, SubGoal } from '@aurora/domain';

/** Compute overall % as the mean of sub-goal % (rounded). */
export function overallProgress(g: GoalProject): number {
  const values = Object.values(g.progress.subGoalProgress);
  if (values.length === 0) return 0;
  return Math.round(values.reduce((a, b) => a + b, 0) / values.length);
}

/** Sub-goals sorted by sequence (ties broken by label for determinism). */
export function orderedSubGoals(g: GoalProject): SubGoal[] {
  return [...g.subGoals].sort(
    (a, b) =>
      a.sequence - b.sequence ||
      a.label.localeCompare(b.label),
  );
}

/** The first pending/active sub-goal in sequence order (the "next" one). */
export function nextSubGoal(g: GoalProject): SubGoal | undefined {
  const ordered = orderedSubGoals(g).filter(
    (s) => s.status === 'active' || s.status === 'pending',
  );
  return ordered[0];
}

/**
 * Whether the success criteria are met: overall 100% AND every sub-goal
 * done/skipped with 100% (a skipped sub-goal does not block completion —
 * the agent re-planned it away, ADR S13).
 */
export function isGoalComplete(g: GoalProject): boolean {
  if (g.status === 'completed') return true;
  const allDone = g.subGoals.every(
    (s) =>
      (s.status === 'done' && (g.progress.subGoalProgress[s.id] ?? 0) >= 100) ||
      s.status === 'skipped',
  );
  return allDone && overallProgress(g) >= 100;
}

/**
 * Detect a progress stall (recomposition trigger, ADR S13 +
 * dynamic-goal-engine.md "si sub-goal 5 shows < 70% after 2 months").
 * A stall = a sub-goal stuck < `stallThresholdPct` while the goal is
 * active. Pure heuristic on the GoalProgress snapshot; the Agent decides
 * whether to recompose.
 */
export function detectStall(
  g: GoalProject,
  thresholdPct = 70,
): SubGoal[] {
  if (g.status !== 'active') return [];
  return g.subGoals.filter((s) => {
    if (s.status === 'skipped' || s.status === 'done') return false;
    return (g.progress.subGoalProgress[s.id] ?? 0) < thresholdPct;
  });
}

/**
 * The context-strip suggestion (goal-dashboard-ui.md S4: natural-language
 * sentence, NOT a system message). Deterministic from the snapshot — the
 * LLM may enrich it later; the shape contract is fixed.
 */
export function goalSuggestion(g: GoalProject): string | null {
  const next = nextSubGoal(g);
  if (!next) return null;
  const stall = detectStall(g);
  if (stall.length > 0) {
    return `« ${next.label} » avance lentement (${
      g.progress.subGoalProgress[next.id] ?? 0
    }%) — je te propose de replanifier ce sous-objectif.`;
  }
  const featureLabel = g.features.find((p) =>
    next.features.includes(p.featureId),
  );
  return featureLabel
    ? `Prochain pas : ${featureLabel.featureId} pour « ${next.label} ».`
    : `Prochain sous-objectif : « ${next.label} ».`;
}
