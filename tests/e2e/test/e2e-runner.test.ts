import assert from 'node:assert/strict';
import { test } from 'node:test';
import { E2E_SCENARIOS, runAllScenarios, allEmittedEvents } from '../src/index.ts';

/** Task 2: the 20 E2E agent scenarios replay against a device stub (OQ-08
 *  Playwright runner). This test pins the runner contract + AD-9 guard. */

test('E2E runner: 20 scenarios replay deterministically against a stub', async () => {
  assert.equal(E2E_SCENARIOS.length, 20);
  // a deterministic stub device: returns the scenario result, emits no events
  const results = await runAllScenarios({
    runScenario: async (s) => ({ result: s.result, events: s.events }),
  });
  assert.equal(results.length, 20);
  for (let i = 0; i < 20; i++) {
    assert.ok(results[i]?.startsWith(`S${i + 1}:`), `result ${i} prefix`);
  }
});

test('E2E runner: unknown event is an AD-9 violation and throws', async () => {
  const known = new Set(allEmittedEvents());
  assert.rejects(
    runAllScenarios({
      runScenario: async () => ({ result: 'ok', events: ['BogusEvent'] as never }),
    }),
    /AD-9 violation/,
  );
  void known;
});
