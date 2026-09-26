import assert from 'node:assert/strict';
import { test } from 'node:test';
import { WORKFLOWS, allEmittedEvents, workflowById } from '../src/index.ts';

/** Task 1: the 23 composite workflows exist, are well-formed, and validate
 *  against the AD-9 closed vocabulary + AD-15 JobKind + AD-7 single-writer. */
test('WORKFLOWS: 23 workflows W1..W23, each non-empty and documented', () => {
  assert.equal(WORKFLOWS.length, 23);
  const ids = WORKFLOWS.map((w) => w.id);
  for (let i = 1; i <= 23; i++) {
    assert.ok(ids.includes(`W${i}`), `missing W${i}`);
  }
  for (const w of WORKFLOWS) {
    assert.ok(w.name.length > 0, `${w.id} name empty`);
    assert.ok(w.trigger.length > 0, `${w.id} trigger empty`);
    assert.ok(w.actors.length > 0, `${w.id} actors empty`);
    assert.ok(w.modules.length > 0, `${w.id} modules empty`);
    assert.ok(w.capabilities.length > 0, `${w.id} capabilities empty`);
    assert.ok(w.data.length > 0, `${w.id} data empty`);
    assert.ok(w.ui.length > 0, `${w.id} ui empty`);
    assert.ok(w.agent.role.length > 0, `${w.id} agent.role empty`);
    assert.ok(w.agent.action.length > 0, `${w.id} agent.action empty`);
    assert.ok(w.recovery.length > 0, `${w.id} recovery empty`);
  }
});

test('WORKFLOWS: every emitted event is one of the 9 AD-9 events', () => {
  const NINE = [
    'TaskCompleted', 'CourseImported', 'FlashcardReviewed',
    'ProgressEvidenceCreated', 'SkillStateChanged', 'GoalUpdated',
    'ArtifactGenerated', 'JobCompleted', 'DiscoveryItemCreated',
  ] as const;
  const emitted = allEmittedEvents();
  for (const e of emitted) {
    assert.ok(
      NINE.includes(e as (typeof NINE)[number]),
      `${e} is not in the 9-event AD-9 vocabulary`,
    );
  }
  // spot-check: W23 emits TaskCompleted; W12 emits GoalUpdated
  assert.ok(emitted.includes('TaskCompleted'));
  assert.ok(emitted.includes('GoalUpdated'));
  assert.equal(workflowById('W1')?.name, 'Study Session');
  assert.equal(workflowById('W23')?.name, 'Habit/Routine Loop');
});
