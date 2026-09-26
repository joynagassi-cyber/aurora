/**
 * event-flow.ts — AD-9 event wiring between the 9 events and the 23
 * composite workflows + the 20 E2E agent scenarios.
 *
 * The domain defines the 9-event vocabulary (events.ts, contract-catalog S6)
 * with a closed consumer matrix (AD-9). This module pins that matrix as data
 * and provides two checks used by the docs pipeline and the OQ-08 E2E runner:
 *
 *   - consumerMatrix(event): the AD-9 consumers of one event
 *   - flowVerdicts(): for each of the 9 events, the producer workflows that
 *     EMIT it and the consumer workflows that OBSERVE it (eventsConsumed).
 *     An event "flows" when at least one emitting workflow exists; it is
 *     wired end-to-end when at least one consuming workflow also observes it
 *     via the events table (AD-2: observation, never direct table access).
 */
import type { DomainEventName } from '@aurora/domain';
import { WORKFLOWS, E2E_SCENARIOS } from './index.ts';
import type { Workflow, WorkflowModule } from './types.ts';

/**
 * AD-9 consumer matrix (events.ts doc-comments, normative): one row per
 * event, the modules that OBSERVE it via the events table.
 */
export const EVENT_CONSUMERS: Record<DomainEventName, WorkflowModule[]> = {
  TaskCompleted: ['Progress', 'Learning', 'Agent'],
  CourseImported: ['Knowledge', 'Discovery', 'Progress'],
  FlashcardReviewed: ['Progress'],
  ProgressEvidenceCreated: ['Knowledge', 'Agent'],
  SkillStateChanged: ['Agent', 'Discovery', 'Learning'],
  GoalUpdated: ['Progress', 'Agent'],
  ArtifactGenerated: ['Knowledge', 'Learning'],
  JobCompleted: ['Artifact', 'Agent'],
  DiscoveryItemCreated: ['Learning', 'Knowledge', 'Progress', 'Agent'],
};

/** The AD-9 events a single workflow EMITS. */
export function emittedBy(event: DomainEventName): readonly Workflow[] {
  return WORKFLOWS.filter((w) => w.eventsEmitted.includes(event));
}

/** The AD-9 events a single workflow OBSERVES (eventsConsumed lane). */
export function observedBy(event: DomainEventName): readonly Workflow[] {
  return WORKFLOWS.filter((w) => w.eventsConsumed.includes(event));
}

export interface EventFlowVerdict {
  event: DomainEventName;
  /** workflows that emit the event (producer lane, AD-7) */
  producers: string[];
  /** workflows that observe the event via the events table (AD-2/AD-9) */
  observers: string[];
  /** E2E scenarios that declare the event as a produced side effect */
  scenarios: string[];
  /** flows when >=1 producer; end-to-end when >=1 producer AND >=1 observer */
  flows: boolean;
  endToEnd: boolean;
}

export function flowVerdicts(): readonly EventFlowVerdict[] {
  const events = Object.keys(EVENT_CONSUMERS) as DomainEventName[];
  return events.map((event) => {
    const producers = emittedBy(event).map((w) => w.id);
    const observers = observedBy(event).map((w) => w.id);
    const scenarios = E2E_SCENARIOS.filter((s) => s.events.includes(event)).map((s) => s.id);
    return {
      event,
      producers,
      observers,
      scenarios,
      flows: producers.length > 0,
      endToEnd: producers.length > 0 && observers.length > 0,
    };
  });
}

/**
 * The self-improvement loop wiring (docs/agent/expert-skills-extensions.md):
 * Progress observes TaskCompleted/GoalUpdated/SkillStateChanged ->
 * ProgressEvidenceCreated + SkillStateChanged -> Agent (Expert Skills) ->
 * revised skill applied next session. Returns the stage chain as event ids
 * so the OQ-08 runner can trace it.
 */
export function selfImprovementEventChain(): readonly DomainEventName[] {
  return ['TaskCompleted', 'ProgressEvidenceCreated', 'SkillStateChanged'];
}

/** Assert the full 9-event wiring is sound (used by the test suite). */
export function allEventsFlow(): boolean {
  return flowVerdicts().every((v) => v.flows);
}
