/**
 * Ascent — Pedagogical Trajectory Engine domain types (AD-15 SSoT, wave 3).
 *
 * Authority: docs/ascent/overview.md S6 (AscentLearningIR + supporting
 * types), implementation.md Step 1. EXACT shapes from the doc; this file
 * is ADDITIVE (AD-15) — no existing type is modified or re-declared.
 *
 * Invariants respected here:
 *  - AD-9: Ascent CONSUMES the existing 9-event vocabulary (the 6 listed in
 *    overview.md S17); it EMITS NO new event. `AscentAdaptation` is internal
 *    log data, not a vocabulary entry.
 *  - AD-7: Ascent is the sole writer of `ascent_paths`; the IR references
 *    Knowledge/Progress objects by ID only (no re-declaration, AD-6).
 *  - 5-state baseline (overview S6.2): NEVER reduced to a single 0-100
 *    score; the `dimensions` are optional but preferred.
 *
 * 80/20 persistence (overview S20): one table `ascent_paths` — steps,
 * depth, baseline snapshot and adaptation log are JSONB columns; the IR
 * shape below is the TypeScript projection of that single row.
 */

/**
 * Depth level per concept (overview S13). Three levels modify CONTENT,
 * not architecture — the 3 levels share the same IR shape.
 */
export type DepthLevel = 'quick' | 'standard' | 'deep';

/**
 * READ → DO → PROVE phase of a step (overview S10). This is a FRAMEWORK,
 * not a rigid constraint: the Agent (via Ascent) may reorder it when
 * context demands (mastered → skip READ; exam week → Quick depth, only
 * PROVE; blocked prerequisite → remediation BEFORE the main step).
 */
export type AscentStepPhase = 'read' | 'do' | 'prove' | 'remediation' | 'recap';

/** Status of a step inside the trajectory. */
export type AscentStepStatus = 'pending' | 'active' | 'done' | 'skipped' | 'remediation';

/** Status of the whole path (frozen lifecycle). */
export type AscentPathStatus = 'active' | 'paused' | 'completed' | 'abandoned';

/**
 * AscentActivity — what a step delegates to Learning / Knowledge
 * (overview S6.1). Ascent never generates content itself: it tells
 * Learning "generate a QCM on concept X, depth Standard, 10 items".
 */
export interface AscentActivity {
  id: string;
  /** activity kind (frozen vocabulary, overview S6.1) */
  type:
    | 'read'
    | 'practice'
    | 'quiz'
    | 'flashcard'
    | 'mirror'
    | 'exercise'
    | 'review'
    | 'remediation'
    | 'recap';
  /**
   * LearningCommand (domain command, AD-7) — the work delegated to the
   * Learning module. Ascent NEVER writes Learning tables itself.
   */
  learningCommand?: {
    action:
      | 'generate_qcm'
      | 'generate_flashcards'
      | 'create_exercise'
      | 'start_mirror'
      | 'review_due';
    /** depth, item_count, topic … (free-form per action) */
    params: Record<string, unknown>;
  };
  /** what to read in Knowledge (AD-6: reference by ID, never content) */
  knowledgeRef?: {
    type: 'concept' | 'formula' | 'document' | 'source';
    id: string;
  };
}

/**
 * AscentStep — one unit of the trajectory (overview S6.1). Content comes
 * from Knowledge via refs; practice comes from Learning via activities.
 */
export interface AscentStep {
  id: string;
  /** "Flexion simple — poutre appui simple" */
  label: string;
  /** Knowledge concept_ids (NOT content — AD-6) */
  conceptRefs: string[];
  /** Progress skill_id (optional) */
  skillRef?: string;
  /** SourceRef ids (AD-11 provenance, source-hierarchy levels A–D) */
  sourceRefs: string[];
  /** what to DO (delegated to Learning) */
  activities: AscentActivity[];
  /** READ → DO → PROVE (framework, not rigid) */
  phase: AscentStepPhase;
  /** depth for this step */
  depth: DepthLevel;
  status: AscentStepStatus;
}

/**
 * AscentAdaptation — the path's change log (overview S6.3). Append-only
 * audit trail; an adaptation is LOG DATA, not an AD-9 event.
 */
export interface AscentAdaptation {
  id: string;
  pathId: string;
  /** "ProgressEvidence: RDM.flexion QCM 50% < 80%" */
  trigger: string;
  action:
    | 'reorder'
    | 'accelerate'
    | 'slow_down'
    | 'insert_remediation'
    | 'skip'
    | 'deepen'
    | 'shallow'
    | 'revisit'
    | 'recompose';
  /** "Moved step 'FEM validation' after 'manual flexion'…" */
  detail: string;
  /** stepIds changed */
  affectedSteps: string[];
  createdAt: string;
  /** PROVENANCE: the ProgressEvidence ids that triggered this */
  evidenceRefs: string[];
}

/**
 * LearnerBaseline — what the user already knows (overview S6.2).
 * Source: Progress `skill_states` (01 S4.4). Ascent READS it, never
 * writes it. The 5 states are NEVER a single score (rule S6.2).
 */
export interface LearnerBaseline {
  userId: string;
  /** per-skill state, projected from Progress SkillState (not re-declared) */
  skillStates: {
    skillId: string;
    status: 'unknown' | 'partial' | 'known' | 'fragile' | 'mastered';
    /**
     * Multi-dimensional (NOT a single score). All optional; a concept can
     * be "mastered in understanding but fragile in application".
     */
    dimensions?: {
      understanding?: number; // 0-1 (can explain it)
      recall?: number; // 0-1 (can retrieve it)
      application?: number; // 0-1 (can use it in a problem)
      autonomy?: number; // 0-1 (without help)
      retention?: number; // 0-1 (after 1 week)
    };
    /** ProgressEvidence id that grounds this state */
    lastEvidence: string;
    /** ISO date — how recent the evidence is */
    freshness: string;
  }[];
  /** derived: skill_ids with status 'unknown' | 'partial' */
  gaps: string[];
  /** derived: skill_ids with status 'fragile' */
  fragiles: string[];
  /** derived: skill_ids with status 'mastered' */
  mastered: string[];
  /** when this snapshot was computed */
  computedAt: string;
}

/**
 * AscentLearningIR — the path itself (overview S6.1). The IR is DATA:
 * consumed by the Agent Kernel Context Builder (01 S5.6) and rendered by
 * Slide-Ascent (UI format, not the engine). It is NOT an AD-9 event.
 *
 * Persistence: one row in `ascent_paths` (80/20, overview S20) —
 * `steps` JSONB = AscentStep[], `depth` JSONB = the depth record,
 * `baseline` JSONB = the LearnerBaseline snapshot, `adaptations` JSONB
 * = the append-only AscentAdaptation[].
 */
export interface AscentLearningIR {
  /** ULID */
  id: string;
  userId: string;
  /** "Master RDM by exam day" (NL, verbatim) */
  goal: string;
  /** skill_id (Progress) if applicable */
  targetSkill?: string;
  /** optional deadline */
  targetDate?: string;

  /** what to learn (ordered) */
  steps: AscentStep[];
  /** how to learn (per step, adaptive) — stepId -> DepthLevel */
  depth: Record<string, DepthLevel>;

  /** starting point */
  baseline: LearnerBaseline;

  /** prerequisites (must be mastered before proceeding) */
  prerequisites: {
    stepId: string;
    /** stepIds or skill_ids */
    requires: string[];
    status: 'met' | 'pending' | 'remediation_needed';
  }[];

  /** progression criteria */
  passageCriteria: {
    stepId: string;
    /** "QCM >= 80%", "all FSRS due items reviewed" */
    criterion: string;
    /** which Progress metric to check */
    metric: string;
    threshold: number;
  }[];

  /** adaptation log (audit trail, append-only) */
  adaptations: AscentAdaptation[];

  status: AscentPathStatus;
  createdAt: string;
  updatedAt: string;
}

/**
 * The 6 AD-9 events Ascent CONSUMES (closed vocabulary, AD-9 — Ascent
 * emits nothing new). Declared here for the event-driven adapter; the
 * types themselves live in `events.ts` (SSoT, no re-declaration).
 */
export type AscentConsumedEvent =
  | 'ProgressEvidenceCreated'
  | 'SkillStateChanged'
  | 'DiscoveryItemCreated'
  | 'GoalUpdated'
  | 'TaskCompleted'
  | 'ArtifactGenerated';

/**
 * AscentSourceLevel — the source hierarchy (overview S16, AD-11).
 * Rule: Level D NEVER overrides Level A/B/C; conflicts are flagged in
 * the path, never silent.
 */
export type AscentSourceLevel = 'A' | 'B' | 'C' | 'D';

/**
 * Level 1 of progressive disclosure (overview S11) — a PURE VIEW over the
 * IR, shared by the Slide-Ascent UI and the kernel's Context Builder so the
 * plan and the render never disagree. Level 1 = the always-visible
 * "what to learn next" = CURRENT + NEXT step, and nothing else.
 */
export interface Level1View {
  /** the current (active) step, or the first pending step */
  current: AscentStep | undefined;
  /** the next step after `current` */
  next: AscentStep | undefined;
  /** the goal (verbatim, NL) */
  goal: string;
}

/**
 * Derive the Level 1 view from a path (pure, deterministic). "Current" =
 * the step with status `active`, else the first `pending` step. "Next" =
 * the step immediately after it.
 */
export function level1(path: AscentLearningIR): Level1View {
  const activeIdx = path.steps.findIndex((s) => s.status === 'active');
  const startIdx = activeIdx >= 0 ? activeIdx : path.steps.findIndex((s) => s.status === 'pending');
  const current = startIdx >= 0 ? path.steps[startIdx] : undefined;
  const next = current !== undefined ? path.steps[startIdx + 1] : undefined;
  return {
    current,
    next,
    goal: path.goal,
  };
}
