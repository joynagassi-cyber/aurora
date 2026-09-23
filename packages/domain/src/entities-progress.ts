/**
 * Progress entities (AD-15 SSoT, 01 S4.4, ADR S18.8).
 *
 * Progress MEASURES real transformation (not a counter): state, evolution,
 * causes, documented gaps, evidence, and the next useful trajectory.
 * Progress only EMITS events; it never writes Knowledge tables (AD-2/F-02).
 */
import type { OrSetValue } from './crdt';

/**
 * ProgressEvidence — a piece of observable evidence tied to a skill or goal.
 * Model (ADR S18.3): QCM, active recall, standard exercise, new exercise,
 * personal explanation, error correction, project, professional
 * application, successful repetition.
 */
export interface ProgressEvidence {
  id: string;
  userId: string;
  /** the skill or goal the evidence belongs to */
  skillId?: string;
  goalId?: string;
  /** evidence kind (ADR S18.3) */
  type:
    | 'qcm'
    | 'active-recall'
    | 'standard-exercise'
    | 'new-exercise'
    | 'personal-explanation'
    | 'error-correction'
    | 'project'
    | 'professional-application'
    | 'successful-repetition';
  /** observed level (ADR S18.2 scale) */
  level:
    | 'discovered'
    | 'comprehended'
    | 'recalled'
    | 'guided-application'
    | 'autonomous-application'
    | 'novel-problem'
    | 'mastered'
    | 'expert';
  /** 0..1 */
  confidence: number;
  /** the source event that produced this evidence (AD-9 traceability) */
  sourceEventId?: string;
  /** when observed */
  observedAt: string;
  /** context of the observation */
  context?: string;
}

/** ProgressSnapshot — observed state at a point in time (ADR S18.8).
 *  Mirrored to device (03 S4.2: one of the two limited Progress mirrors). */
export interface ProgressSnapshot {
  id: string;
  userId: string;
  /** when the snapshot was taken */
  takenAt: string;
  /** what was snapshotted (skill, goal, domain…) */
  subject: string;
  /** the observed level */
  level:
    | 'discovered'
    | 'comprehended'
    | 'recalled'
    | 'guided-application'
    | 'autonomous-application'
    | 'novel-problem'
    | 'mastered'
    | 'expert';
  /** 0..1 */
  confidence?: number;
  /** the evidence backing this snapshot */
  evidenceRefs: OrSetValue[]; // CRDT list
}

/** SkillState — current level, freshness, confidence, evidence, history
 *  (ADR S18.8). Mirrored to device. Progress owns it (AD-6). */
export interface SkillState {
  id: string;
  userId: string;
  skillId: string;
  /** observed level */
  level:
    | 'discovered'
    | 'comprehended'
    | 'recalled'
    | 'guided-application'
    | 'autonomous-application'
    | 'novel-problem'
    | 'mastered'
    | 'expert';
  /** how recent the last evidence is (freshness, ADR S18.2) */
  freshness?: number;
  /** 0..1 */
  confidence?: number;
  /** evidence backing the current state */
  evidenceRefs: OrSetValue[];
  /** short history of level changes */
  history?: Array<{ level: string; at: string }>;
  updatedAt: string;
}

/** ProgressTrend — aggregated evolution over a period (ADR S18.8).
 *  Server-only; recomputed (no device mirror). */
export interface ProgressTrend {
  id: string;
  userId: string;
  /** skill / goal / domain the trend describes */
  subject: string;
  /** window: 7d / 30d / semester / year / multi-year (ADR S18.2) */
  window: '7d' | '30d' | 'semester' | 'year' | 'multi-year';
  /** trajectory: improving / plateau / regressing / forgotten (ADR S18.1) */
  direction: 'improving' | 'plateau' | 'regressing' | 'forgotten';
  /** the observed points */
  points: Array<{ at: string; level: string; confidence?: number }>;
  /** computed server-side */
  computedAt: string;
}

/**
 * ProgressEvent — a significant learning/execution/error/success/change
 * event (ADR S18.8). Server-only (Event History, no mirror, 03 S4.2).
 */
export interface ProgressEvent {
  id: string;
  userId: string;
  /** what happened */
  kind:
    | 'learning'
    | 'execution'
    | 'error'
    | 'success'
    | 'change';
  /** the affected skill / goal */
  skillId?: string;
  goalId?: string;
  /** causal factors (ADR S18.4: strategy, time, regularity, difficulty,
   *  load, interruptions, resource quality, recurring errors, prior
   *  understanding, plan change). Distinguish correlation from causality. */
  causalFactors?: string[];
  /** the source event (AD-9) */
  sourceEventId?: string;
  /** context */
  context?: string;
  at: string;
}

/**
 * ProgressTrajectoryScenario — conditional trajectory from the observed
 * state (ADR S18.5): keep current pace, more time available, strategy
 * change, reduced load, unblock a blocker. A planning aid, NOT a
 * prediction.
 */
export interface ProgressTrajectoryScenario {
  id: string;
  userId: string;
  /** the state the scenario starts from */
  subject: string;
  /** the hypothesis (ADR S18.5: the condition that changes the path) */
  hypothesis:
    | 'maintain-pace'
    | 'increase-time'
    | 'change-strategy'
    | 'reduce-load'
    | 'unblock';
  /** the projected path */
  projectedPoints: Array<{ at: string; level: string; confidence?: number }>;
  /** the action the scenario recommends */
  nextAction?: string;
  createdAt: string;
}

/**
 * Gap — a documented difference between current state and target state
 * (ADR S13.4, S18.1). `gaps` rows owned by Progress, definitions in
 * packages/domain (data-event-job-catalog S1/S2).
 */
export interface Gap {
  id: string;
  userId: string;
  /** gap kind (ADR S13.4: program vs practice, local vs international,
   *  technological, methodological, portfolio, veille, depth) */
  kind:
    | 'program-vs-practice'
    | 'local-vs-international'
    | 'technological'
    | 'methodological'
    | 'portfolio'
    | 'veille'
    | 'depth'
    | 'skill'
    | 'other';
  /** what is missing / weak */
  description: string;
  /** the affected skill */
  skillId?: string;
  /** documented evidence for the gap (ADR S13.4: each gap carries
   *  evidence, source, practical consequence) */
  evidence?: string;
  /** the documented consequence */
  consequence?: string;
  /** a progression path (ADR S13.4) */
  remediationPath?: string;
  /** distinguishing a documented requirement vs a frequent practice vs an
   *  interpretation (ADR S13.4) */
  confidence?: 'documented-requirement' | 'frequent-practice' | 'interpretation';
  createdAt: string;
  updatedAt: string;
}
