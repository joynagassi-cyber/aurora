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
 * A stall = a sub-goal that HAS evidence of work (progress > 0) but is
 * stuck below `stallThresholdPct` while the goal is active. A pending
 * sub-goal at 0% is not a stall — it has simply not started.
 */
export function detectStall(
  g: GoalProject,
  thresholdPct = 70,
): SubGoal[] {
  if (g.status !== 'active') return [];
  return g.subGoals.filter((s) => {
    if (s.status === 'skipped' || s.status === 'done') return false;
    const pct = g.progress.subGoalProgress[s.id] ?? 0;
    return pct > 0 && pct < thresholdPct;
  });
}

/**
 * `goal.pause` / `goal.resume` — the agent's goal-state commands
 * (dynamic-goal-engine.md "Agent capabilities"). Pause stops the goal's
 * active features (jobs stop, notifications mute — the command bus /
 * dispatcher observes the status; this module only mutates the GoalProject
 * data, AD-7). Resume is only legal from `paused` (completed/abandoned
 * are terminal). Paused goals keep ALL progress + history — pause never
 * touches `progress` (ADR S13: history is never destroyed).
 */
export function pauseGoal(g: GoalProject, now: string): GoalProject {
  if (g.status !== 'active') {
    throw new Error(`goal-engine/pause_invalid_status: ${g.status}`);
  }
  return { ...g, status: 'paused', updatedAt: now };
}

export function resumeGoal(g: GoalProject, now: string): GoalProject {
  if (g.status !== 'paused') {
    throw new Error(`goal-engine/resume_invalid_status: ${g.status}`);
  }
  return { ...g, status: 'active', updatedAt: now };
}

/**
 * `goal.complete` — mark the goal completed. The agent requests the
 * completion; the check (success criteria met) is the Progress module's
 * job (F-07 sole producer of the evidence + `ProgressEvidenceCreated`).
 * Terminal: no further mutation of a completed goal.
 */
export function completeGoal(g: GoalProject, now: string): GoalProject {
  if (g.status === 'completed' || g.status === 'abandoned') {
    throw new Error(`goal-engine/complete_on_terminal_goal: ${g.status}`);
  }
  const subGoalProgress: Record<string, number> = { ...g.progress.subGoalProgress };
  for (const s of g.subGoals) subGoalProgress[s.id] = 100;
  return {
    ...g,
    status: 'completed',
    subGoals: g.subGoals.map((s) =>
      s.status === 'pending' || s.status === 'active'
        ? { ...s, status: 'skipped' as const }
        : s,
    ),
    progress: {
      ...g.progress,
      overallPct: 100,
      subGoalProgress,
      lastUpdated: now,
    },
    updatedAt: now,
  };
}

/**
 * `goal.abandon` — mark abandoned (dynamic-goal-engine.md: "data
 * preserved, features deactivated"). The GoalProject row + all progress
 * stay readable (AD-15 additive: no data destroyed); only the status
 * deactivates the goal's features. Terminal: no further mutation.
 */
export function abandonGoal(g: GoalProject, now: string): GoalProject {
  if (g.status === 'completed' || g.status === 'abandoned') {
    throw new Error(`goal-engine/abandon_on_terminal_goal: ${g.status}`);
  }
  return { ...g, status: 'abandoned', updatedAt: now };
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
