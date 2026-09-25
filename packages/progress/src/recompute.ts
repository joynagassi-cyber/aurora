/**
 * Progress module — SkillState recompute (ADR S18.8, 01 S5.2 `skill_recompute`).
 *
 * Triggered by `progress_evidences` inserts (01 S5.2). The recompute is
 * the aggregation that turns new evidence into an updated SkillState:
 * level = strongest level supported by recent evidence, freshness =
 * recency of the last evidence, confidence = agreement of sources.
 * Progress is the sole writer of `skill_states` (AD-7); it EMITS
 * `SkillStateChanged` (AD-9) — Knowledge consumes it to update NodeState.
 */
import type {
  OrSetValue,
  ProgressEvidence,
  ProgressEvidenceCreatedEvent,
  SkillStateChangedEvent,
  SkillState,
} from '@aurora/domain';
import {
  clamp01,
  evidenceFromFlashcardReviewed,
  evidenceFromTaskCompleted,
  levelIndex,
  type EvidenceLevel,
} from './evidence.ts';

/** Freshness buckets (ADR S18.2 freshness, S18.5). */
export type Freshness = 'fresh' | 'stale' | 'forgotten';

const FRESH_DAYS = 14;
const FORGOTTEN_DAYS = 90;

/** Compute freshness from the recency of the last evidence. */
export function computeFreshness(lastEvidenceAt: string, now: string): Freshness {
  const days = (Date.parse(now) - Date.parse(lastEvidenceAt)) / 86_400_000;
  if (days > FORGOTTEN_DAYS) return 'forgotten';
  if (days > FRESH_DAYS) return 'stale';
  return 'fresh';
}

export interface RecomputeInput {
  userId: string;
  skillId: string;
  /** the existing state (if any) */
  current?: SkillState;
  /** all evidence for this skill, newest last */
  evidences: readonly ProgressEvidence[];
  now: string;
}

export interface RecomputeOutput {
  state: SkillState;
  /** true when the level actually changed (drives SkillStateChanged emit) */
  changed: boolean;
}

/**
 * The pure, deterministic recompute (01 S5.2, idempotent AD-8). Strongest
 * recent evidence wins; recency-weighted confidence. Idempotent: running
 * twice on the same input yields the same state.
 */
export function recomputeSkill(input: RecomputeInput): RecomputeOutput {
  const { userId, skillId, current, evidences, now } = input;

  let best: ProgressEvidence | undefined;
  let confidence = 0;
  for (const e of evidences) {
    if (best === undefined || levelIndex(e.level) > levelIndex(best.level)) {
      best = e;
    }
    // Recency-weighted confidence: latest evidence weighs most.
    const recency = recencyWeight(e.observedAt, now);
    confidence = Math.max(confidence, clamp01(e.confidence * recency));
  }

  const level: EvidenceLevel = best?.level ?? 'discovered';
  const fresh =
    best === undefined ? 'forgotten' : computeFreshness(best.observedAt, now);

  const nowMs = Date.parse(now);
  const next: SkillState = {
    id: current?.id ?? '',
    userId,
    skillId,
    level,
    freshness: fresh === 'fresh' ? 1 : fresh === 'stale' ? 0.5 : 0,
    confidence,
    evidenceRefs:
      best === undefined
        ? current?.evidenceRefs ?? []
        : mergeEvidenceRefs(current?.evidenceRefs, [best], nowMs, 'progress'),
    history: [
      ...(current?.history ?? []),
      { level, at: now },
    ],
    updatedAt: now,
  };

  const changed =
    current === undefined ||
    current.level !== level ||
    (current.confidence ?? 0) !== next.confidence;
  return { state: next, changed };
}

/** Recency weight 0..1 (01 S4.4 freshness): recent evidence weighs more. */
function recencyWeight(observedAt: string, now: string): number {
  const days = (Date.parse(now) - Date.parse(observedAt)) / 86_400_000;
  if (days <= FRESH_DAYS) return 1;
  if (days <= FORGOTTEN_DAYS) return 0.5;
  return 0.2;
}

/** Append evidence refs without duplicating (CRDT OR-Set, 03 S5.3:
 *  element = { v, ts, c }). */
function mergeEvidenceRefs(
  existing: OrSetValue[] | undefined,
  added: readonly ProgressEvidence[],
  nowMs: number,
  clientId: string,
): OrSetValue[] {
  const set = new Map<string, OrSetValue>();
  for (const o of existing ?? []) {
    if (o.v !== '') set.set(o.v, o);
  }
  for (const e of added) {
    if (e.id !== '') set.set(e.id, { v: e.id, ts: nowMs, c: clientId });
  }
  return [...set.values()];
}

/** Build the `SkillStateChanged` event (AD-9 SSoT shape), emitted only
 *  when the level actually changed (idempotent, AD-8). */
export function buildSkillStateChanged(
  state: SkillState,
  now: string,
): SkillStateChangedEvent {
  return {
    eventId: '',
    occurredAt: now,
    type: 'SkillStateChanged',
    payload: {
      skillId: state.skillId,
      userId: state.userId,
      newState: state.level,
      freshness: state.freshness ?? 0,
      confidence: state.confidence ?? 0,
    },
  };
}

/**
 * The event builders Progress produces (AD-9: PROGRESS owns exactly two
 * events of the closed 9-event vocabulary).
 */
export const PROGRESS_PRODUCED_EVENTS = [
  'ProgressEvidenceCreated',
  'SkillStateChanged',
] as const;
export type ProgressProducedEvent = (typeof PROGRESS_PRODUCED_EVENTS)[number];

/** The events Progress CONSUMES (declared only, AD-9 matrix):
 *  `TaskCompleted`, `FlashcardReviewed`, `GoalUpdated`,
 *  `DiscoveryItemCreated`. */
export const PROGRESS_CONSUMED_EVENTS = [
  'TaskCompleted',
  'FlashcardReviewed',
  'GoalUpdated',
  'DiscoveryItemCreated',
] as const;
export type ProgressConsumedEvent = (typeof PROGRESS_CONSUMED_EVENTS)[number];

/** Build the `ProgressEvidenceCreated` event (AD-9 SSoT shape).
 *  Emitted ONCE per evidence row (idempotency guard in the repository, AD-8). */
export function buildProgressEvidenceCreated(
  e: ProgressEvidence,
  now: string,
): ProgressEvidenceCreatedEvent {
  return {
    eventId: '',
    occurredAt: now,
    type: 'ProgressEvidenceCreated',
    payload: {
      evidenceId: e.id,
      userId: e.userId,
      skillId: e.skillId,
      goalId: e.goalId,
      type: e.type,
      level: e.level,
      confidence: e.confidence,
      sourceEventId: e.sourceEventId ?? '',
    },
  };
}

// Re-export the two event-qualification helpers so the job handler (jobs.ts)
// and consumers can build evidence from raw events without importing
// cross-module packages (AD-2).
export { evidenceFromTaskCompleted, evidenceFromFlashcardReviewed };
