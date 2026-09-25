/**
 * Progress module — evidence model (ADR S18.3, F-07).
 *
 * Progress is the SOLE producer of `progress_evidences` rows + the
 * `ProgressEvidenceCreated` event (F-07). Other modules emit their own
 * events (TaskCompleted, FlashcardReviewed, GoalUpdated,
 * DiscoveryItemCreated); Progress QUALIFIES them into evidence — no one
 * else writes `progress_evidences` (AD-7 single-writer).
 */
import type {
  FlashcardReviewedEvent,
  ProgressEvidence,
  TaskCompletedEvent,
} from '@aurora/domain';

/** The evidence kinds (ADR S18.3) — domain SSoT. */
export type EvidenceType = ProgressEvidence['type'];

/** The observed levels (ADR S18.2 scale) — domain SSoT. */
export type EvidenceLevel = ProgressEvidence['level'];

const LEVELS: readonly EvidenceLevel[] = [
  'discovered',
  'comprehended',
  'recalled',
  'guided-application',
  'autonomous-application',
  'novel-problem',
  'mastered',
  'expert',
];

export function levelIndex(level: EvidenceLevel): number {
  const i = LEVELS.indexOf(level);
  if (i < 0) throw new Error(`progress/unknown_level: ${level}`);
  return i;
}

export const EVIDENCE_TYPES: readonly EvidenceType[] = [
  'qcm',
  'active-recall',
  'standard-exercise',
  'new-exercise',
  'personal-explanation',
  'error-correction',
  'project',
  'professional-application',
  'successful-repetition',
];

/**
 * Qualify a `TaskCompleted` event into a `ProgressEvidence` (S18.3:
 * evidence minimum dataset = skill/goal, observed level, evidence, date,
 * freshness, context, confidence). Pure + deterministic given `now`.
 */
export function evidenceFromTaskCompleted(
  ev: TaskCompletedEvent,
  opts: { now: string; skillId?: string; confidence?: number; context?: string },
): ProgressEvidence {
  void opts.now;
  return {
    id: '',
    userId: ev.payload.userId,
    skillId: opts.skillId ?? ev.payload.taskId,
    goalId: undefined,
    type: 'successful-repetition',
    level: 'recalled',
    confidence: clamp01(opts.confidence ?? 0.6),
    sourceEventId: ev.eventId,
    observedAt: ev.payload.completedAt,
    context: opts.context ?? `task:${ev.payload.taskId}`,
  };
}

/** Qualify a `FlashcardReviewed` event (memory evidence, S18.2/18.3:
 *  recognition vs recall). */
export function evidenceFromFlashcardReviewed(
  ev: FlashcardReviewedEvent,
  opts: { now: string; skillId?: string; confidence?: number; context?: string },
): ProgressEvidence {
  // Rating scale 0..5 (typical FSRS): >=3 → recalled, else fragile.
  const recalled = ev.payload.rating >= 3;
  return {
    id: '',
    userId: ev.payload.userId,
    skillId: opts.skillId,
    goalId: undefined,
    type: 'active-recall',
    level: recalled ? 'recalled' : 'comprehended',
    confidence: clamp01(opts.confidence ?? (recalled ? 0.8 : 0.5)),
    sourceEventId: ev.eventId,
    observedAt: opts.now,
    context: opts.context ?? `card:${ev.payload.cardId} rating=${ev.payload.rating}`,
  };
}

/**
 * The sole-writer factory for a raw `ProgressEvidence` (AD-7): Progress is
 * the only module that inserts `progress_evidences` rows. `id` + row ids
 * are allocated by the persisting side (server ULID). `now` injectable
 * (deterministic tests).
 */
export function buildEvidence(input: {
  userId: string;
  skillId?: string;
  goalId?: string;
  type: EvidenceType;
  level: EvidenceLevel;
  confidence?: number;
  sourceEventId?: string;
  observedAt: string;
  context?: string;
}): ProgressEvidence {
  if (!EVIDENCE_TYPES.includes(input.type)) {
    throw new Error(`progress/unknown_evidence_type: ${input.type}`);
  }
  return {
    id: '',
    userId: input.userId,
    skillId: input.skillId,
    goalId: input.goalId,
    type: input.type,
    level: input.level,
    confidence: clamp01(input.confidence ?? 0.5),
    sourceEventId: input.sourceEventId,
    observedAt: input.observedAt,
    context: input.context,
  };
}

/** Clamp confidence to 0..1 (domain invariant, 01 S4.4). */
export function clamp01(n: number): number {
  return Math.max(0, Math.min(1, n));
}
