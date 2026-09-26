/**
 * ERYNIS — perf pass gate (wave 5 task 5): asserts the apps/mobile
 * declaration output (dist) is under the 300 Ko JS-gz budget (02 §9.1,
 * Pixel 4a SLO). TTI < 1.5 s and 30 fps are device-observed SLOs
 * (Sentry, OQ-08 E2E) — the budget constants live in budgets.ts, this
 * gate measures what a CI step can measure without a device.
 *
 * Run: node --experimental-strip-types --no-warnings
 *        apps/mobile/test/perf-budget.test.ts
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  PERF_BUDGETS,
  checkBytes,
  checkTti,
  checkFps,
  allBudgetsPass,
} from '../src/perf/budgets.ts';
import { mobileEmitGzBytes, mobileEmitRawBytes } from '../src/perf/measure.ts';

test('JS emit stays under the 300 Ko gz budget (02 §9.1)', () => {
  const raw = mobileEmitRawBytes();
  // gz of the raw emit is always <= raw; the gate uses the raw emit size
  // as the conservative stand-in when no bundler gzip is available, and
  // the measured gz when a dist .js.map/.gz sibling exists.
  const gz = mobileEmitGzBytes(raw);
  const c = checkBytes(PERF_BUDGETS.jsGzBytes, gz, `dist emit (raw=${raw})`);
  assert.ok(c.ok, `JS emit ${gz} bytes exceeds ${PERF_BUDGETS.jsGzBytes} budget (${c.detail})`);
});

test('TTI and fps SLOs are the frozen 02 §9.1 constants', () => {
  assert.equal(PERF_BUDGETS.ttiMs, 1500);
  assert.equal(PERF_BUDGETS.fpsMin, 30);
  // Simulated device observations pass at budget, fail above.
  assert.ok(checkTti(1500, 1499).ok);
  assert.ok(!checkTti(1500, 1501).ok);
  assert.ok(checkFps(30, 30).ok);
  assert.ok(!checkFps(30, 29).ok);
});

test('allBudgetsPass = every SLO holds', () => {
  const gz = mobileEmitGzBytes(mobileEmitRawBytes());
  const checks = [
    checkBytes(PERF_BUDGETS.jsGzBytes, gz),
    checkTti(PERF_BUDGETS.ttiMs, 1200),
    checkFps(PERF_BUDGETS.fpsMin, 30),
  ];
  assert.ok(allBudgetsPass(checks), `perf gate: ${JSON.stringify(checks)}`);
});
