/**
 * Goal mutations (AD-7 single-writer: this package writes ONLY its own
 * GoalProject composition data; it never touches other modules' tables).
 *
 * `goal.feature.add` / `goal.feature.remove` update the composition
 * (FeaturePlacement + SubGoal.features union). Cross-goal conflict
 * rule (dynamic-goal-engine.md test "Cross-goal"): when 2 active goals
 * both need the same feature at the same time, the goals are SEQUENCED,
 * never run in parallel.
 */
import type { GoalProject } from '@aurora/domain';

/** Add a feature to a GoalProject's composition (idempotent: no dupes). */
export function addFeatureToGoal(
  g: GoalProject,
  featureId: string,
  opts: { subGoalId?: string; now: string },
): GoalProject {
  if (g.features.some((p) => p.featureId === featureId)) {
    return g; // idempotent
  }
  const sub = opts.subGoalId
    ? g.subGoals.find((s) => s.id === opts.subGoalId)
    : undefined;
  const subGoals = sub
    ? g.subGoals.map((s) =>
        s.id === sub.id
          ? { ...s, features: [...new Set([...s.features, featureId])] }
          : s,
      )
    : g.subGoals;
  return {
    ...g,
    subGoals,
    features: [
      ...g.features,
      {
        featureId,
        role: 'default',
        frequency: 'on-event',
        position: '',
        config: {},
      },
    ],
    updatedAt: opts.now,
  };
}

/** Remove a feature from a GoalProject's composition. */
export function removeFeatureFromGoal(
  g: GoalProject,
  featureId: string,
  now: string,
): GoalProject {
  const subGoals = g.subGoals.map((s) => ({
    ...s,
    features: s.features.filter((f) => f !== featureId),
  }));
  return {
    ...g,
    subGoals,
    features: g.features.filter((p) => p.featureId !== featureId),
    updatedAt: now,
  };
}

/**
 * Cross-goal sequencing: given 2+ active goals, any feature shared by
 * several of them must be SEQUENCED (one active slot per feature at a
 * time) — the agent serializes, it does not parallelize
 * (dynamic-goal-engine.md "Cross-goal" test).
 *
 * Returns the goals ordered so that shared-feature slots never overlap:
 * goal A's shared features are scheduled AFTER goal B's when B claims
 * them first (deterministic: by `updatedAt` desc, then id asc).
 */
export function sequenceSharedFeatures(goals: GoalProject[]): GoalProject[] {
  const active = goals.filter((g) => g.status === 'active');
  if (active.length <= 1) return goals;

  const featureOwners = new Map<string, string[]>();
  for (const g of active) {
    for (const p of g.features) {
      const owners = featureOwners.get(p.featureId) ?? [];
      owners.push(g.id);
      featureOwners.set(p.featureId, owners);
    }
  }
  const shared = [...featureOwners.entries()].filter(([, o]) => o.length > 1);

  // Deterministic order: goals are sequenced by last-activity, so the
  // most recently active goal gets first claim on shared features.
  const order = [...active].sort(
    (a, b) =>
      b.updatedAt.localeCompare(a.updatedAt) || a.id.localeCompare(b.id),
  );
  const claim = new Map<string, number>(); // goalId -> slot index
  order.forEach((g, i) => claim.set(g.id, i));

  return goals.map((g) => {
    if (g.status !== 'active') return g;
    const slot = claim.get(g.id);
    if (slot === undefined) return g;
    // Mark shared placements with a deterministic slot so the UI
    // renders "Attends: Focus en cours sur …" (goal-dashboard-ui.md S7).
    const features = g.features.map((p) =>
      shared.some(([fid]) => fid === p.featureId)
        ? { ...p, config: { ...p.config, goalSlot: slot } }
        : p,
    );
    return { ...g, features };
  });
}
