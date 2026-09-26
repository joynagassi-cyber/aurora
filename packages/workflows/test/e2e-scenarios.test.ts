import assert from 'node:assert/strict';
import { test } from 'node:test';
import { E2E_SCENARIOS, scenarioById } from '../src/index.ts';

/** Task 2: the 20 E2E agent scenarios exist and trace the 11 lanes.
 *  OQ-08 Playwright-on-device: these specs are what the device runner replays. */
test('E2E_SCENARIOS: 20 scenarios S1..S20, each traces the lanes', () => {
  assert.equal(E2E_SCENARIOS.length, 20);
  for (let i = 1; i <= 20; i++) {
    assert.ok(E2E_SCENARIOS.some((s) => s.id === `S${i}`), `missing S${i}`);
  }
  for (const s of E2E_SCENARIOS) {
    assert.ok(s.utterance.length > 0, `${s.id} utterance empty`);
    assert.ok(s.intent.length > 0, `${s.id} intent empty`);
    assert.ok(s.context.length > 0, `${s.id} context empty`);
    assert.ok(s.capabilities.length > 0, `${s.id} capabilities empty`);
    assert.ok(s.tools.length > 0, `${s.id} tools empty`);
    assert.ok(s.modules.length > 0, `${s.id} modules empty`);
    assert.ok(s.backend.length > 0, `${s.id} backend empty`);
    assert.ok(s.ui.length > 0, `${s.id} ui empty`);
    assert.ok(s.result.length > 0, `${s.id} result empty`);
    assert.ok(s.progress.length > 0, `${s.id} progress empty`);
  }
});

test('E2E_SCENARIOS: confirmation + offline classes are typed', () => {
  // confirmation points from the doc: S1, S3, S4, S5, S13, S19, S20
  for (const id of ['S1', 'S3', 'S4', 'S5', 'S13', 'S19', 'S20']) {
    assert.equal(scenarioById(id)?.confirmation, 'confirm', `${id} should confirm`);
  }
  // offline-capable: S1, S3, S4, S16, S17 (local mirrors)
  for (const id of ['S1', 'S3', 'S4', 'S16']) {
    assert.ok(
      ['offline-capable', 'hybrid'].includes(scenarioById(id)?.offline ?? ''),
      `${id} offline class`,
    );
  }
  // online-required: S2, S8, S9, S12, S14, S20
  for (const id of ['S2', 'S8', 'S9', 'S12', 'S14', 'S20']) {
    assert.equal(scenarioById(id)?.offline, 'online-required', `${id} offline`);
  }
});
