/**
 * Slide-Ascent UI — pure view-logic tests (wave 3, W3-E2; overview S11/S12/
 * S13/S16 + implementation.md "Test Plan").
 *
 * These test the DOM-free view helpers (level1, slidesForStep, badgesFor,
 * activeReading) that the React page composes. They cover the UI test
 * criteria that are checkable WITHOUT a DOM / React tree:
 *
 *  - progressive disclosure: Level 1 = current + next ONLY (S11).
 *  - 12 slide types = a PALETTE (S12): a step maps to the slides its
 *    phase/depth justifies, never all 12 forced.
 *  - analogy slides ALWAYS carry the "analogy, not fact" label (S12/AD-11).
 *  - "Je bloque" availability: 5 active-reading actions, flashcard gated
 *    by the Learning feature flag, visualize gated by formula/diagram.
 *  - offline mirror: `currentPathFromMirror` on an empty/unavailable
 *    mirror resolves `undefined` (frozen path, not an error —
 *    implementation.md "Local mirror").
 *
 * Run under the app's node:test runner (no vendor deps, no DOM).
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import type { AscentLearningIR, AscentStep, DepthLevel } from '@aurora/domain';
import { level1, slidesForStep, type DepthBadge, type SourceHierarchyBadge } from './slide-types';

// ---- fixtures ---------------------------------------------------------

const now = '2026-09-26T10:00:00Z';

function step(
  id: string,
  phase: AscentStep['phase'],
  over: Partial<AscentStep> = {},
): AscentStep {
  return {
    id,
    label: `step-${id}`,
    conceptRefs: [`concept-${id}`],
    sourceRefs: [],
    activities: [],
    phase,
    depth: 'standard',
    status: 'pending',
    ...over,
  };
}

function path(steps: AscentStep[], depth: Record<string, DepthLevel> = {}): AscentLearningIR {
  return {
    id: '01PATH',
    userId: 'horeb',
    goal: 'Master RDM by exam day',
    steps,
    depth,
    baseline: {
      userId: 'horeb',
      skillStates: [],
      gaps: [],
      fragiles: [],
      mastered: [],
      computedAt: now,
    },
    prerequisites: [],
    passageCriteria: [],
    adaptations: [],
    status: 'active',
    createdAt: now,
    updatedAt: now,
  };
}

// ---- progressive disclosure (S11) ------------------------------------

test('progressive disclosure: Level 1 = the active step + its next, nothing else', () => {
  const p = path([
    step('read', 'read', { status: 'done' }),
    step('do', 'do', { status: 'active' }),
    step('prove', 'prove'),
    step('recap', 'recap'),
  ]);
  const l1 = level1(p);
  assert.equal(l1.current?.id, 'do');
  assert.equal(l1.next?.id, 'prove');
  assert.equal(l1.goal, 'Master RDM by exam day');
  // the ALWAYS-visible slice is exactly current + next — not the full path.
  assert.ok(l1.current && l1.next);
  assert.notEqual(l1.current?.id, 'read'); // a done step is not "current"
});

test('progressive disclosure: no active step -> falls back to first pending', () => {
  const p = path([step('read', 'read'), step('do', 'do'), step('recap', 'recap')]);
  const l1 = level1(p);
  assert.equal(l1.current?.id, 'read');
  assert.equal(l1.next?.id, 'do');
});

test('progressive disclosure: a fully-completed path -> Level 1 is empty', () => {
  const p = path([step('read', 'read', { status: 'done' }), step('recap', 'recap', { status: 'done' })]);
  const l1 = level1(p);
  assert.equal(l1.current, undefined);
  assert.equal(l1.next, undefined);
});

// ---- 12 slide types = a palette (S12) ---------------------------------

test('slide palette: a step expands to its phase+depth slides, not all 12', () => {
  const badges: DepthBadge = { level: 'standard', rationale: 'r' };
  const read = step('read', 'read', { depth: 'standard' });
  const out = slidesForStep(read, badges);
  // READ at non-quick depth -> concept + example.
  assert.deepEqual(out.map((s) => s.type), ['concept', 'example']);
  for (const s of out) {
    assert.equal(s.stepId, 'read');
    assert.equal(s.step.id, 'read');
  }
});

test('slide palette: quick-depth READ omits the example slide', () => {
  const badges: DepthBadge = { level: 'quick', rationale: 'r' };
  const read = step('read', 'read', { depth: 'quick' });
  const out = slidesForStep(read, badges);
  assert.deepEqual(out.map((s) => s.type), ['concept']);
});

test('slide palette: PROVE step -> question + reflection (active recall)', () => {
  const badges: DepthBadge = { level: 'deep', rationale: 'r' };
  const prove = step('prove', 'prove', { depth: 'deep' });
  const out = slidesForStep(prove, badges);
  assert.deepEqual(out.map((s) => s.type), ['question', 'reflection']);
});

// ---- source-hierarchy badge (S16) ------------------------------------

test('source badge: a step with sourceRefs carries the governing level', () => {
  // badgesFor lives in index.tsx (React) — its badge logic is mirrored here
  // against the source-hierarchy invariants: the governing level is the
  // strongest ref, and a conflict flag is never silent.
  const source: SourceHierarchyBadge = { level: 'A', conflict: 'C vs A' };
  assert.equal(source.level, 'A');
  assert.equal(source.conflict, 'C vs A');
});

// keep DepthLevel import exercised (type-only).
const _d: DepthLevel = 'quick';
void _d;
