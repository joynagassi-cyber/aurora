/**
 * Discovery module — events (AD-9, producer = Discovery ONLY).
 *
 * The module is the SOLE producer of exactly ONE event of the closed
 * 9-event vocabulary (AD-9, packages/domain/src/events.ts):
 *   - `DiscoveryItemCreated` (consumers: Learning, Knowledge, Progress, Agent)
 *
 * Transport (AD-9 V1): insertion into the producer's `events` table
 * (Event History, 0009_event_history.sql). Consumers observe via the
 * `events` table / Postgres trigger -> job / incremental `since_event_id`
 * reads (EventsPort). This module NEVER imports a consumer module —
 * consumers depend on the events table, not on this package (AD-2).
 *
 * Builders are pure: `eventId` (monotonic, server-allocated) and
 * `occurredAt` (server time, 03 S4.2 rule 3) are supplied by the
 * persisting side — event ids are allocated server-side (AD-7: local
 * module writes its OWN tables only).
 */
import type {
  DiscoveryItem,
  DiscoveryItemCreatedEvent,
  DomainEvent,
} from '@aurora/domain';

/** Build the `DiscoveryItemCreated` event (AD-9 SSoT shape).
 *  Emitted exactly ONCE per sheet — idempotency guard in the repository
 *  (AD-8). */
export function buildDiscoveryItemCreated(
  item: DiscoveryItem,
  now: string,
): DiscoveryItemCreatedEvent {
  return {
    eventId: '',
    occurredAt: now,
    type: 'DiscoveryItemCreated',
    payload: {
      discoveryItemId: item.id,
      userId: item.userId,
      topic: item.title,
      sources: item.sources.map((s) => String(s.v)),
      createdAt: now,
    },
  };
}

/** The one event this module produces — the closed producer list
 *  (AD-9: 9-event vocabulary; Discovery owns exactly 1). */
export const DISCOVERY_PRODUCED_EVENTS = ['DiscoveryItemCreated'] as const;
export type DiscoveryProducedEvent = (typeof DISCOVERY_PRODUCED_EVENTS)[number];

/** The events this module CONSUMES (declared only, AD-9 matrix):
 *  `SkillStateChanged` (competence profile) + `CourseImported` (gaps). */
export const DISCOVERY_CONSUMED_EVENTS = ['SkillStateChanged', 'CourseImported'] as const;
export type DiscoveryConsumedEvent = (typeof DISCOVERY_CONSUMED_EVENTS)[number];

/** Narrowing helper: is a domain event one we consume? */
export function isDiscoveryConsumedEvent(
  e: DomainEvent,
): e is (DomainEvent & { type: DiscoveryConsumedEvent }) {
  return e.type === 'SkillStateChanged' || e.type === 'CourseImported';
}
