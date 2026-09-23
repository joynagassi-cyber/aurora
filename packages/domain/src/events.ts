/**
 * 9-event vocabulary (AD-9 SSoT, contract-catalog S6 / data-event-job-catalog S4).
 *
 * Exactly 9 named events, each with ONE producer and declared consumers
 * (AD-9 matrix). A new event = additive ADR. Payloads are the EXACT
 * shapes from contract-catalog S6 "Minimal payload".
 *
 * Transport V1: insertion into the producer's `events` table (Event
 * History); consumers observe via Postgres trigger -> job, or
 * incremental `since_event_id` reads. No broker.
 */

/** Common envelope every Aurora domain event carries. */
interface EventBase {
  /** monotonic event id in the producer's `events` table */
  eventId: string;
  /** when produced (server time) */
  occurredAt: string;
}

/** `TaskCompleted` — Producer: Productivity. Consumers: Progress,
 *  Learning, Agent. */
export interface TaskCompletedEvent extends EventBase {
  type: 'TaskCompleted';
  payload: {
    taskId: string;
    userId: string;
    completedAt: string;
    evidenceRefs?: string[];
  };
}

/** `CourseImported` — Producer: Learning. Consumers: Knowledge,
 *  Discovery, Progress. */
export interface CourseImportedEvent extends EventBase {
  type: 'CourseImported';
  payload: {
    courseId: string;
    userId: string;
    source: string;
    importedAt: string;
  };
}

/** `FlashcardReviewed` — Producer: Learning (FSRS). Consumers: Progress. */
export interface FlashcardReviewedEvent extends EventBase {
  type: 'FlashcardReviewed';
  payload: {
    cardId: string;
    userId: string;
    /** FSRS rating */
    rating: number;
    nextDueAt: string;
    /** the fsrs_state snapshot at review */
    fsrsState: {
      stability: number;
      difficulty: number;
      retrievability?: number;
      lapses: number;
    };
  };
}

/**
 * `ProgressEvidenceCreated` — Producer: PROGRESS ONLY (aggregates/qualifies
 * learning events). Consumers: Knowledge (NodeState), Agent. Learning
 * NEVER creates a ProgressEvidence row directly (F-07).
 */
export interface ProgressEvidenceCreatedEvent extends EventBase {
  type: 'ProgressEvidenceCreated';
  payload: {
    evidenceId: string;
    userId: string;
    skillId?: string;
    goalId?: string;
    /** evidence type (ProgressEvidence.type) */
    type: string;
    /** observed level (ProgressEvidence.level) */
    level: string;
    /** 0..1 */
    confidence: number;
    /** the source event that produced this evidence (AD-9 traceability) */
    sourceEventId: string;
  };
}

/**
 * `SkillStateChanged` — Producer: PROGRESS. Consumers: Agent
 * (Expert Skills), Discovery (competence profile), Learning
 * (targeted revision).
 */
export interface SkillStateChangedEvent extends EventBase {
  type: 'SkillStateChanged';
  payload: {
    skillId: string;
    userId: string;
    /** new SkillState.level */
    newState: string;
    /** freshness (0..1 or ms) */
    freshness: number;
    /** 0..1 */
    confidence: number;
  };
}

/** `GoalUpdated` — Producer: Productivity. Consumers: Progress
 *  (trajectory), Agent. */
export interface GoalUpdatedEvent extends EventBase {
  type: 'GoalUpdated';
  payload: {
    goalId: string;
    userId: string;
    changedAt: string;
    /** which fields changed */
    fields: string[];
  };
}

/**
 * `ArtifactGenerated` — Producer: ARTIFACT module, after R2 upload ONLY
 * (F-06). Consumers: Knowledge (SourceRef), Learning (proof), [+ UI
 * per OQ-05]. The Agent Kernel NEVER emits this — it only requests
 * generation.
 */
export interface ArtifactGeneratedEvent extends EventBase {
  type: 'ArtifactGenerated';
  payload: {
    artifactId: string;
    userId: string;
    /** Artifact.kind */
    kind: string;
    /** R2 object key (binaries in R2, metadata in Postgres) */
    r2Key: string;
    sizeBytes: number;
    generatedAt: string;
    /** the generating job */
    jobId: string;
  };
}

/**
 * `JobCompleted` — Producer: Job system. Consumers: Artifact, UI
 * (success state). F-08: payload is opaque without jobId+jobKind;
 * both are MANDATORY.
 */
export interface JobCompletedEvent extends EventBase {
  type: 'JobCompleted';
  payload: {
    /** MANDATORY (F-08) */
    jobId: string;
    /** MANDATORY (F-08) */
    jobKind: string;
    userId: string;
    status: 'done' | 'failed';
    result?: unknown;
  };
}

/** `DiscoveryItemCreated` — Producer: Discovery. Consumers: Learning
 *  (activity creation), Knowledge (tree links), Progress (measurement),
 *  Agent (next recommendations). */
export interface DiscoveryItemCreatedEvent extends EventBase {
  type: 'DiscoveryItemCreated';
  payload: {
    discoveryItemId: string;
    userId: string;
    /** the discovery topic */
    topic: string;
    /** typed source ids (DiscoverySource) */
    sources: string[];
    createdAt: string;
  };
}

/** The closed 9-event union (AD-9: vocabulary is closed). */
export type DomainEvent =
  | TaskCompletedEvent
  | CourseImportedEvent
  | FlashcardReviewedEvent
  | ProgressEvidenceCreatedEvent
  | SkillStateChangedEvent
  | GoalUpdatedEvent
  | ArtifactGeneratedEvent
  | JobCompletedEvent
  | DiscoveryItemCreatedEvent;

/** Event type names — the exact 9 (AD-9). */
export type DomainEventName = DomainEvent['type'];

/**
 * EvidenceRef — a lightweight pointer to a ProgressEvidence (ADR S25.3).
 * Used inside OR-Set lists on entities (evidence_refs, evidenceRefIds).
 */
export interface EvidenceRef {
  /** the ProgressEvidence id */
  evidenceId: string;
  /** display / context label */
  label?: string;
  /** 0..1 */
  confidence?: number;
  /** ISO 8601 */
  at: string;
}
