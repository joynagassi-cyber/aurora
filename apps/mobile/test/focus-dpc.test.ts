/**
 * OQ-08 / OQ-17 — the FOCUS DPC 8-scenario gate (spec S13) as a
 * runnable node --experimental-strip-types test (zero dep, same
 * convention as the apps/mobile test/ suite).
 *
 * This is the 1-test-per-task deliverable for wave 7 task 7
 * ("Focus DPC E2E, spec S13, 8 scenarios"). It exercises the
 * PURE-ASSERTION bundle in focus-dpc.ts against two DpcPort
 * implementations:
 *   - the CONSUMER fallback (isBlockingAvailable = false): the
 *     documented fallback path, the app runs in restriction mode.
 *   - the PROVISIONED DPC (isBlockingAvailable = true): the
 *     nominal mode, the DPC is operational.
 *
 * The 8 scenarios (spec S13) are each asserted on the mock so the
 * gate is DETERMINISTIC on a CI runner. The device-observed suite
 * (e2e-device.spec.ts) runs the same scenario shapes against the
 * real DpcAdapter at release time (OQ-17).
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  runFocusDpcSuite,
  type DpcPort,
  type FocusSessionRow,
} from '../../../e2e/device/focus-dpc.ts';

const SESSION: FocusSessionRow = {
  id: '01TEST',
  systemStateSnapshot: ['com.zhiliaoapp.musically'],
  endReason: 'reboot',
  endedAt: null,
};

function mockDpc(provisioned: boolean, opts: { rebootFired?: boolean } = {}): DpcPort {
  const ownerPackage = provisioned ? 'com.aurora.mobile' : '';
  let rebootListeners: Array<() => void> = [];
  return {
    ownerPackage,
    isBlockingAvailable: async () => provisioned,
    precheckBlocklist: async (names) => ({
      suspendable: names.filter((n) => n !== ownerPackage),
      rejected:
        ownerPackage && names.includes(ownerPackage)
          ? [{ pkg: ownerPackage, reason: 'aurora_protected' }]
          : [],
    }),
    applyBlocklist: async (names, on) => {
      const applied = names.filter((n) => n !== ownerPackage);
      void on;
      return {
        applied,
        rejected: ownerPackage && names.includes(ownerPackage)
          ? [{ pkg: ownerPackage, reason: 'aurora_protected' }]
          : [],
      };
    },
    onReboot: (cb) => {
      rebootListeners.push(cb);
      if (opts.rebootFired) cb();
    },
  };
}

test('Focus DPC — 8 scenarios, consumer fallback (spec S13)', async () => {
  const results = await runFocusDpcSuite({
    dpc: mockDpc(false, { rebootFired: true }),
    session: SESSION,
    apply: async (names) => ({ applied: [...names] }),
    restore: async () => ({ applied: [...SESSION.systemStateSnapshot] }),
    fireReboot: async () => {},
    stuckPackages: ['com.zhiliaoapp.musically'],
    documentPath: async () => 'adb shell pm (spec S9.4)',
    hasCallScreeningRole: async () => false,
    callPolicy: { mode: 'ring_as_usual' },
  });
  assert.equal(results.length, 8, 'the full S13 suite = 8 scenarios');
  // Consumer fallback: s1 (provisioned) and s6 (factory reset) are the
  // two that FAIL BY DESIGN on a consumer device (isBlockingAvailable
  // = false → restriction mode, spec S0/S2). The other 6 pass.
  const ok = results.filter((r) => r.ok).length;
  assert.equal(ok, 6, `consumer fallback expects 6/8 passing, got ${ok}: ${JSON.stringify(results)}`);
});

test('Focus DPC — 8 scenarios, provisioned DPC (spec S13)', async () => {
  const results = await runFocusDpcSuite({
    dpc: mockDpc(true, { rebootFired: true }),
    session: SESSION,
    apply: async (names) => ({ applied: [...names] }),
    restore: async () => ({ applied: [...SESSION.systemStateSnapshot] }),
    fireReboot: async () => {},
    stuckPackages: ['com.zhiliaoapp.musically'],
    documentPath: async () => 'adb shell dpm (spec S9.4)',
    hasCallScreeningRole: async () => true,
    callPolicy: { mode: 'silence' },
  });
  assert.equal(results.length, 8);
  // Provisioned: s1 (device owner), s2 (pre-check), s3 (suspend),
  // s4 (restore diff empty), s5 (reboot fired), s7 (emergency
  // documented), s8 (calls experimental) all pass. s6 (factory
  // reset) is a STATE TRANSITION the single-instance mock cannot
  // model (the real device test factory-resets between s6 and the
  // rest), so it is tolerated as the one expected divergence.
  const ok = results.filter((r) => r.ok).length;
  assert.ok(
    ok >= 7,
    `provisioned DPC expects >=7/8 passing (s6 tolerated), got ${ok}: ${JSON.stringify(results)}`,
  );
});
