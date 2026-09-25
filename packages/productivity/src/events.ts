/**
 * Productivity module — event emission (AD-9, producer = Productivity ONLY).
 *
 * The module is the SOLE producer of exactly two events of the closed
 * 9-event vocabulary (AD-9, packages/domain/src/events.ts):
 *   - `TaskCompleted` (consumers: Progress, Learning, Agent)
 *   - `GoalUpdated`   (consumers: Progress, Agent)
 *
 * Transport (AD-9 V1): insertion into the producer's `events` table
 * (Event History, 0009_event_history.sql). Consumers observe via the
 * `events` table / Postgres trigger -> job / incremental `since_event_id`
 * reads (EventsPort). This module NEVER imports a consumer module —
 * consumers depend on the events table, not on this package (AD-2).
 *
 * The builders here are pure: they produce the frozen payload shapes.
 * The `eventId` (monotonic, per the `events` SSoT) and `occurredAt`
 * (server time, 03 S4.2 rule 3) are supplied by the persisting side
 * (packages/data repository + upsync), because event ids are allocated
 * server-side — the local mirror is read-only for the events table
 * (AD-7: local module writes its OWN tables only).
 */
import type {
  DomainEvent,
  GoalUpdatedEvent,
  TaskCompletedEvent,
} from '@aurora/domain';

/**
 * Build a `TaskCompleted` event (AD-9 SSoT shape).
 *
 * Emitted exactly ONCE per task completion — the idempotency guard
 * lives in the repository (`done_at` already set -> no re-emit, AD-8
 * idempotent rule).
 *
 * @param taskId the completed task
 * @param userId the owner (RLS scope, 01 S2.2)
 * @param completedAt server time of completion (ISO 8601)
 * @param evidenceRefs optional evidence pointers (03 S4.2 mirror rule)
 */
export function buildTaskCompleted(
  taskId: string,
  userId: string,
  completedAt: string,
  evidenceRefs?: string[],
): TaskCompletedEvent {
  return {
    eventId: '', // allocated server-side in the `events` table (AD-9 transport)
    occurredAt: completedAt,
    type: 'TaskCompleted',
    payload: {
      taskId,
      userId,
      completedAt,
      ...(evidenceRefs && evidenceRefs.length > 0
        ? { evidenceRefs }
        : {}),
    },
  };
}

/**
 * Build a `GoalUpdated` event (AD-9 SSoT shape).
 *
 * Emitted on every goal field change (status, targetDate, horizon…).
 * `fields` = the exact changed column names (AD-9 payload contract).
 */
export function buildGoalUpdated(
  goalId: string,
  userId: string,
  changedAt: string,
  fields: string[],
): GoalUpdatedEvent {
  return {
    eventId: '',
    occurredAt: changedAt,
    type: 'GoalUpdated',
    payload: { goalId, userId, changedAt, fields },
  };
}

/**
 * The two events this module produces — the closed producer list
 * (AD-9: the vocabulary has exactly 9 events; Productivity owns 2).
 */
export const PRODUCTIVITY_PRODUCED_EVENTS = ['TaskCompleted', 'GoalUpdated'] as
  const;

export type ProductivityEvent = TaskCompletedEvent | GoalUpdatedEvent;

/** Narrowing helper: is a domain event one of our two? */
export function isProductivityEvent(e: DomainEvent): e is ProductivityEvent {
  return e.type === 'TaskCompleted' || e.type === 'GoalUpdated';
}
