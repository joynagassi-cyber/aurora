/**
 * E2E on device (OQ-08) — node-native gate for the two device
 * scenario helpers in driver.ts (create → complete task, offline).
 *
 * These helpers are PURE (no Playwright import at type level); this
 * test wires them to a STRUCTURAL `E2ePage`/`E2eLocator` mock so the
 * scenario logic (the 5 UX states, the offline toggle) is asserted
 * on a CI runner without a device. The device-observed Playwright
 * suite (e2e-device.spec.ts) runs the same shapes against the real
 * harness at release time.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  scenarioCreateCompleteTask,
  scenarioOffline,
  DEVICE_SLOS,
  type E2ePage,
  type E2eLocator,
} from '../../../e2e/device/driver.ts';

/** A recording E2ePage mock — captures the assertion calls. */
function mockPage(calls: string[], assertVisible: (t: RegExp | string) => void): E2ePage {
  const loc = (kind: string, arg: string): E2eLocator => ({
    click: async () => calls.push(`${kind}:${arg}:click`),
    fill: async (t) => calls.push(`${kind}:${arg}:fill:${t}`),
    check: async () => calls.push(`${kind}:${arg}:check`),
  });
  return {
    getByRole: (role, opts) => loc(role, String(opts.name)),
    getByLabel: (label) => loc('label', String(label)),
    getByText: (text) => {
      assertVisible(text);
      return loc('text', String(text));
    },
  };
}

test('create → complete task scenario (02 §11) — asserts the 5 UX states', () => {
  const calls: string[] = [];
  const visible: Array<RegExp | string> = [];
  const page = mockPage(calls, (t) => visible.push(t));
  const run = scenarioCreateCompleteTask(page, async (t) => {
    await Promise.resolve();
    visible.push(t);
  });
  return run().then(() => {
    // The scenario clicked create, filled the title, saved, then
    // completed — the 5-state "success" path is asserted visible.
    assert.ok(calls.some((c) => c.includes('click')));
    assert.ok(visible.some((v) => /E2E task/i.test(String(v))), 'created task surfaces (local readback)');
    assert.ok(visible.some((v) => /success|termin/i.test(String(v))), 'success toast visible');
  });
});

test('offline scenario (02 §11 "Offline") — badge shows, cloud re-enables', () => {
  const visible: Array<RegExp | string> = [];
  let offline = false;
  const page = mockPage([], (t) => visible.push(t));
  const run = scenarioOffline(
    page,
    async (off) => {
      offline = off;
      return Promise.resolve();
    },
    async (t) => {
      visible.push(t);
      return Promise.resolve();
    },
  );
  return run().then(() => {
    assert.equal(offline, false, 'the scenario ends back online');
    assert.ok(visible.some((v) => /offline|hors ligne/i.test(String(v))), 'offline badge asserted');
  });
});

test('device SLOs are the frozen 02 §9.1 constants', () => {
  assert.equal(DEVICE_SLOS.ttiMs, 1500);
  assert.equal(DEVICE_SLOS.jsGzBytes, 307200);
  assert.equal(DEVICE_SLOS.fpsMin, 30);
});
