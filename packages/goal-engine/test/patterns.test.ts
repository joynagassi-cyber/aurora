/**
 * Goal Engine — 5 composition pattern tests (wave 3, HEPHAESTUS task 2).
 * The patterns are HINTS for the Planner: typed, combinable, advisory.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  COMPOSITION_PATTERNS,
  matchPatterns,
  PATTERN_TEMPLATES,
  patternTemplate,
  primaryPattern,
  type GoalSignature,
} from '../src/patterns.ts';

function sig(over: Partial<GoalSignature> = {}): GoalSignature {
  return {
    hasDeadline: false,
    hasDomain: false,
    isRepetitive: false,
    isCollecting: false,
    hasMilestones: false,
    isBehaviorChange: false,
    ...over,
  };
}

test('the vocabulary is closed at 5 patterns (dynamic-goal-engine.md)', () => {
  assert.deepEqual([...COMPOSITION_PATTERNS], [
    'preparation',
    'practice',
    'curation',
    'delivery',
    'adaptation',
  ]);
  assert.equal(PATTERN_TEMPLATES.length, 5);
});

test('every template is coherent (timeline rows reference the placements)', () => {
  for (const t of PATTERN_TEMPLATES) {
    // Each timeline row references a feature present in the placements.
    for (const block of t.timeline) {
      if (block.featureId) {
        assert.ok(
          t.placements.some((p) => p.featureId === block.featureId),
          `timeline ${block.featureId} not in placements of ${t.pattern}`,
        );
      }
      assert.ok(
        block.featureId || block.subGoalId,
        'a timeline block must reference a feature or sub-goal',
      );
    }
    // Icon + layout belong to the pattern (goal-dashboard-ui.md S2/S3).
    assert.equal(t.layout, t.pattern);
    assert.ok(t.timeline.length > 0, 'a template must carry a timeline');
  }
});

test('deadline + domain goal -> preparation ranks first', () => {
  const ranked = matchPatterns(sig({ hasDeadline: true, hasDomain: true }));
  assert.equal(primaryPattern(sig({ hasDeadline: true, hasDomain: true })), 'preparation');
  assert.ok(ranked.length > 0);
});

test('ongoing repetitive goal -> practice ranks first', () => {
  assert.equal(primaryPattern(sig({ isRepetitive: true, hasDomain: true })), 'practice');
});

test('knowledge collecting goal -> curation ranks first', () => {
  assert.equal(primaryPattern(sig({ isCollecting: true, isRepetitive: true })), 'curation');
});

test('milestone project goal -> delivery ranks first', () => {
  assert.equal(
    primaryPattern(sig({ hasMilestones: true, hasDeadline: true, hasDomain: true })),
    'delivery',
  );
});

test('behavior change goal -> adaptation ranks first', () => {
  assert.equal(
    primaryPattern(sig({ isBehaviorChange: true, isRepetitive: true, hasDomain: true })),
    'adaptation',
  );
});

test('empty signature -> no pattern (the LLM must invent a composition)', () => {
  assert.equal(primaryPattern(sig()), null);
  assert.deepEqual(matchPatterns(sig()), []);
});

test('unknown pattern id throws (closed vocabulary)', () => {
  assert.throws(
    () => patternTemplate('fixed-need-7' as never),
    /unknown_pattern/,
  );
});
