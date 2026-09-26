import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  EVENT_CONSUMERS, flowVerdicts, emittedBy, observedBy,
  selfImprovementEventChain, allEventsFlow,
} from '../src/index.ts';

/** Task 3b: AD-9 event flow — the 9 events wire producer->consumer
 *  (events table observation, AD-2) end-to-end across the 23 workflows. */

test('AD-9: consumer matrix is defined for all 9 events', () => {
  const NINE = [
    'TaskCompleted', 'CourseImported', 'FlashcardReviewed',
    'ProgressEvidenceCreated', 'SkillStateChanged', 'GoalUpdated',
    'ArtifactGenerated', 'JobCompleted', 'DiscoveryItemCreated',
  ] as const;
  assert.equal(Object.keys(EVENT_CONSUMERS).length, 9);
  for (const ev of NINE) {
    assert.ok(ev in EVENT_CONSUMERS, `missing consumer row for ${ev}`);
    assert.ok(EVENT_CONSUMERS[ev].length > 0, `${ev} has no consumers`);
  }
});

test('AD-9: all 9 events flow (>=1 emitting workflow each)', () => {
  assert.equal(allEventsFlow(), true, 'every AD-9 event has a producer workflow');
  for (const v of flowVerdicts()) {
    assert.ok(v.flows, `${v.event} does not flow`);
    assert.ok(v.producers.length > 0, `${v.event} no producer`);
  }
});

test('AD-9: end-to-end wiring — emitting + observing workflows per event', () => {
  const verdicts = flowVerdicts();
  // Each event that is observed by a workflow (eventsConsumed lane) must
  // also be emitted by at least one (the events table is the observation
  // surface, AD-2).
  for (const v of verdicts) {
    if (v.observers.length > 0) {
      assert.ok(v.producers.length > 0, `${v.event} observed but never emitted`);
    }
  }
  // Spot-check the producer/observer split on a well-known event.
  assert.ok(emittedBy('TaskCompleted').length > 0, 'TaskCompleted has emitters');
  // Observer check on an event that is actually consumed via the events
  // table (AD-2 observation lane) — TaskCompleted is observed by the
  // Progress aggregator inside the Progress producer, not by a separate
  // workflow, so only assert the emitters here.
  assert.ok(observedBy('SkillStateChanged').length > 0, 'SkillStateChanged has observers');
});

test('self-improvement loop: the 3-event causal chain is traceable', () => {
  const chain = selfImprovementEventChain();
  assert.deepEqual(chain, ['TaskCompleted', 'ProgressEvidenceCreated', 'SkillStateChanged']);
  // Every chain event flows.
  for (const ev of chain) {
    assert.ok(emittedBy(ev).length > 0, `${ev} not emitted anywhere`);
  }
});
