/**
 * Goal entities (AD-15 SSoT, dynamic-goal-engine.md).
 *
 * `GoalProject` is what the AGENT creates/mutates when decomposing a goal
 * (dynamic composition of features + timeline + progress tracker) — NOT a
 * pre-defined domain entity the user builds. Progress owns the rows
 * (`user_goals`), F-07 sole-producer of goal progress.
 */
import type { OrSetValue } from './crdt';

export interface GoalProject {
  id: string;
  userId: string;
  /** the NL goal (verbatim, dynamic — not a fixed category) */
  objective: string;
  /** measurable success criteria (e.g. "QCM >= 80%", "8/8 normes documentées") */
  successCriteria: string;
  targetDate?: string;
  horizon: 'daily' | 'weekly' | 'monthly' | 'quarterly' | 'semester' | 'yearly';

  subGoals: SubGoal[];
  features: FeaturePlacement[];
  timeline: TimelineBlock[];
  progress: GoalProgress;
  status: 'active' | 'paused' | 'completed' | 'abandoned';
  /** re-planning history (ADR S13: recalcul sans détruire l'historique) */
  recomposedAt?: string;
  createdAt: string;
  updatedAt: string;
}

export interface SubGoal {
  id: string;
  label: string;
  /** feature ids that serve this sub-goal */
  features: string[];
  /** ordering (can be parallel) */
  sequence: number;
  /** e.g. "skill_state >= fragile" */
  successCriteria: string;
  status: 'pending' | 'active' | 'done' | 'skipped';
}

export interface FeaturePlacement {
  /** e.g. "qcm_generate", "focus_session" */
  featureId: string;
  /** "practice", "verification", "scheduling" … */
  role: string;
  /** "daily", "per-block", "weekly", "on-event" */
  frequency: string;
  /** "before: mirror_analyze", "after: course_import" */
  position: string;
  /** feature-specific params */
  config: Record<string, unknown>;
}

export interface TimelineBlock {
  /** the feature / sub-goal this block schedules */
  featureId?: string;
  subGoalId?: string;
  startAt: string;
  endAt?: string;
  /** the time actually available (plan/réalité, ADR S2.4) */
  plannedDurationMin?: number;
}

export interface GoalProgress {
  /** 0..100 */
  overallPct: number;
  /** subGoalId -> 0..100 */
  subGoalProgress: Record<string, number>;
  lastUpdated: string;
  /** ProgressEvidence ids (F-07: Progress is the sole producer) */
  evidenceRefs: OrSetValue[];
}
