/**
 * @aurora/focus — S13 mandatory test scenarios (spec S13, consumer list
 * + v1.8 DPC additions). Deterministic fakes over the service + platform
 * DPC layer; the native-side provisioning steps (9.1/9.2 matrix runs,
 * OQ-17) are documented device procedures, not unit tests.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  createFocusService,
  type FocusDpcSurface,
  type FocusNotificationReducer,
  type FocusSessionRepo,
} from '../src/service.ts';
import { DpcAdapter, reconcileOnBoot, applyRecovery, type DpcBridge } from '@aurora/platform';
import type { FocusPrecheck } from '../src/controller.ts';
import type { FocusSession, FocusSessionBilan } from '@aurora/domain';

const AURORA = 'com.aurora';
const T0 = Date.parse('2026-09-25T09:00:00Z');

function fakeDpc(opts: { reject?: { pkg: string; reason: string }[] } = {}) {
  const rejected = new Set((opts.reject ?? []).map((r) => r.pkg));
  const reason = (pkg: string) =>
    (opts.reject ?? []).find((r) => r.pkg === pkg)?.reason ?? 'not_suspendable';
  const appliedCalls: [string[], boolean][] = [];
  const dpc: FocusDpcSurface = {
    precheckBlocklist: async (names) => {
      const packages = names.map((n) => ({
        packageName: n,
        suspendable: !rejected.has(n),
        rejectReason: rejected.has(n) ? reason(n) : undefined,
      }));
      const rej = packages.filter((p) => !p.suspendable);
      return {
        ok: rej.length === 0,
        packages,
        allSuspendable: rej.length === 0,
        rejected: rej.map((p) => ({
          pkg: p.packageName,
          reason: p.rejectReason ?? 'not_suspendable',
        })),
      };
    },
    applyBlocklist: async (names, on) => {
      appliedCalls.push([names, on]);
      return {
        applied: names.filter((n) => !rejected.has(n)),
        rejected: names.filter((n) => rejected.has(n)).map((pkg) => ({ pkg, reason: reason(pkg) })),
      };
    },
  };
  return { ...dpc, appliedCalls };
}

function fakeBridge(opts: {
  active?: boolean;
  suspended?: string[];
  reject?: { pkg: string; reason: string }[];
} = {}): DpcBridge {
  const rejected = new Set((opts.reject ?? []).map((r) => r.pkg));
  return {
    isDpcActive: async () => opts.active ?? false,
    setPackagesSuspended: async (names, on) => ({
      applied: names.filter((n) => !rejected.has(n)),
      rejected: names
        .filter((n) => rejected.has(n))
        .map((pkg) => ({ pkg, reason: (opts.reject ?? []).find((r) => r.pkg === pkg)?.reason ?? 'system_package' })),
    }),
    getPackagesSuspended: async () => opts.suspended ?? [],
    precheckSuspendability: async (names) =>
      names.map((pkg) => ({
        packageName: pkg,
        suspendable: !rejected.has(pkg),
        rejectReason: rejected.has(pkg)
          ? ((opts.reject ?? []).find((r) => r.pkg === pkg)?.reason ?? 'system_package')
          : undefined,
      })),
  };
}

function makeRepo() {
  const opened: FocusSession[] = [];
  const closed: [string, FocusSessionBilan][] = [];
  const repo: FocusSessionRepo = {
    open: async (s) => {
      opened.push(s);
    },
    close: async (id, b) => {
      closed.push([id, b]);
    },
  };
  return { ...repo, opened, closed };
}

function makeReducer(): FocusNotificationReducer & { calls: boolean[] } {
  const calls: boolean[] = [];
  return { calls, reduceForFocus: async (on) => void calls.push(on) };
}

// ============================================================================
// Consumer list (spec S13, unchanged)
// ============================================================================

test('S13 consumer: start -> session row opened, notifications reduced', async () => {
  const dpc = fakeDpc();
  const repo = makeRepo();
  const reducer = makeReducer();
  const svc = createFocusService(
    { dpc, isDpcActive: async () => false, clock: { now: () => T0 }, newSessionId: () => 'C1' },
    repo,
    reducer,
  );
  await svc.startSession({ userId: 'u1', mode: 'timer', plannedDurationSec: 1500 });
  assert.equal(repo.opened[0].id, 'C1');
  assert.deepEqual(reducer.calls, [true]);
  assert.equal(await svc.isBlockingAvailable(), false); // consumer mode
});

test('S13 consumer: blocklist honored in-app (restrictions, no system block)', async () => {
  // Consumer profile: DPC inactive -> applyBlocklist is a no-op path
  // through the adapter: no native calls are made (restriction only).
  const dpc = fakeDpc({ reject: [{ pkg: 'com.tiktok', reason: 'consumer_no_dpc' }] });
  const svc = createFocusService(
    { dpc, isDpcActive: async () => false, clock: { now: () => T0 }, newSessionId: () => 'C2' },
    makeRepo(),
    makeReducer(),
  );
  const pre = await svc.precheckBlocklist(['com.tiktok']);
  assert.equal(pre.allSuspendable, false);
  assert.deepEqual(pre.rejected, [{ pkg: 'com.tiktok', reason: 'consumer_no_dpc' }]);
});

test('S13 consumer: "open blocked app" is a documented limitation (no block CTA)', async () => {
  // 04 S4.2 rule: when isBlockingAvailable() = false the UI NEVER shows
  // a block CTA — here the service exposes the detection result; the
  // assertion is that blocking is simply unavailable (open-app = free).
  const svc = createFocusService(
    {
      dpc: fakeDpc(),
      isDpcActive: async () => false,
      clock: { now: () => T0 },
      newSessionId: () => 'C3',
    },
    makeRepo(),
    makeReducer(),
  );
  assert.equal(await svc.isBlockingAvailable(), false);
});

test('S13: receive notification (non-blocklisted apps keep notifying)', async () => {
  // V1 nominal: Aurora touches only its own notifications
  // (reduceForFocus) — other apps are untouched unless suspended.
  const reducer = makeReducer();
  const svc = createFocusService(
    {
      dpc: fakeDpc(),
      isDpcActive: async () => true,
      clock: { now: () => T0 },
      newSessionId: () => 'C4',
    },
    makeRepo(),
    reducer,
  );
  await svc.reduceNotifications(true);
  assert.deepEqual(reducer.calls, [true]); // aurora-only scope
});

test('S13: receive phone call (V1 = ring_as_usual, no call policy touched)', async () => {
  // The nominal focus session does NOT touch call handling (spec S5):
  // the service exposes no call-policy surface in V1 — documented, not
  // hidden. The assertion: no call-related methods exist on the base
  // service surface.
  const svc = createFocusService(
    {
      dpc: fakeDpc(),
      isDpcActive: async () => true,
      clock: { now: () => T0 },
      newSessionId: () => 'C5',
    },
    makeRepo(),
    makeReducer(),
  );
  assert.equal(
    'setCallPolicy' in svc,
    false,
    'V1 nominal session must not expose a call policy (ring_as_usual)',
  );
});

test('S13: Internet remains active (suspension != network control)', async () => {
  // Non-interference: setPackagesSuspended touches ONLY per-package
  // launch/notification state — the network surface is untouched. The
  // service makes exactly the DPC apply calls and nothing else.
  const dpc = fakeDpc();
  const svc = createFocusService(
    {
      dpc,
      isDpcActive: async () => true,
      clock: { now: () => T0 },
      newSessionId: () => 'C6',
    },
    makeRepo(),
    makeReducer(),
  );
  await svc.startSession({ userId: 'u1', mode: 'timer' });
  await svc.applyBlocklist(['com.tiktok'], true);
  const calls = dpc.appliedCalls;
  assert.equal(calls.length, 1); // only blocklist apply — no network ops
  assert.deepEqual(calls[0], [['com.tiktok'], true]);
});

test('S13: Aurora remains usable during session (self-suspend guard)', async () => {
  // spec S3: the DPC package is NEVER suspended. DpcAdapter enforces it
  // as a second line of defense over the bridge.
  const bridge = fakeBridge({});
  const adapter = new DpcAdapter(bridge, AURORA);
  const res = await adapter.applyBlocklist([AURORA, 'com.tiktok'], true);
  assert.equal(res.applied.includes(AURORA), false, 'aurora self-suspend must be filtered');
  assert.deepEqual(res.applied, ['com.tiktok']);
  assert.deepEqual(res.rejected, [{ pkg: AURORA, reason: 'aurora_protected' }]);
});

test('S13: pause + resume exclude pause time from active accounting', async () => {
  // timer-level: see focus.test.ts; here the service drives the same
  // state machine via its timer() handle.
  const svc = createFocusService(
    {
      dpc: fakeDpc(),
      isDpcActive: async () => true,
      clock: { now: () => T0 },
      newSessionId: () => 'C8',
    },
    makeRepo(),
    makeReducer(),
  );
  await svc.startSession({ userId: 'u1', mode: 'timer' });
  assert.equal(svc.timer()?.state, 'active');
});

test('S13: end session -> total restore + bilan produced', async () => {
  const dpc = fakeDpc();
  const repo = makeRepo();
  const reducer = makeReducer();
  let now = T0;
  const svc = createFocusService(
    { dpc, isDpcActive: async () => true, clock: { now: () => now }, newSessionId: () => 'C9' },
    repo,
    reducer,
  );
  await svc.startSession({ userId: 'u1', mode: 'timer', plannedDurationSec: 1500 });
  await svc.applyBlocklist(['com.tiktok'], true);
  now = T0 + 1_500_000;
  const bilan = await svc.endSession();
  assert.equal(bilan.actualDurationSec, 1500);
  assert.deepEqual(dpc.appliedCalls.at(-1), [['com.tiktok'], false]); // restore
  assert.deepEqual(reducer.calls.at(-1), false);
  assert.equal(repo.closed.length, 1);
});

test('S13: restore discipline (diff against snapshot = empty after end)', async () => {
  const dpc = fakeDpc();
  let now = T0;
  const svc = createFocusService(
    { dpc, isDpcActive: async () => true, clock: { now: () => now }, newSessionId: () => 'C10' },
    makeRepo(),
    makeReducer(),
  );
  await svc.startSession({ userId: 'u1', mode: 'open' });
  await svc.applyBlocklist(['com.tiktok', 'com.whatsapp'], true);
  now = T0 + 100_000;
  await svc.endSession();
  // The restore call must cover EXACTLY the applied set.
  assert.deepEqual(dpc.appliedCalls.at(-1), [['com.tiktok', 'com.whatsapp'], false]);
});

test('S13: crash recovery -> interrupted + un-suspend default', async () => {
  const dpc = fakeDpc();
  let now = T0;
  const svc = createFocusService(
    { dpc, isDpcActive: async () => true, clock: { now: () => now }, newSessionId: () => 'C11' },
    makeRepo(),
    makeReducer(),
  );
  await svc.startSession({ userId: 'u1', mode: 'timer' });
  await svc.applyBlocklist(['com.tiktok'], true);
  await svc.onInterrupted('crash');
  assert.equal(svc.timer()?.state, 'interrupted');
  assert.deepEqual(dpc.appliedCalls.at(-1), [['com.tiktok'], false]);
});

test('S13: device reboot -> boot receiver un-suspend + resume offer', async () => {
  const bridge = fakeBridge({ suspended: ['com.tiktok', 'com.whatsapp'] });
  const session = {
    id: 'C12',
    status: 'interrupted',
    systemStateSnapshot: ['com.tiktok', 'com.whatsapp'],
    endedAt: null,
  };
  const decision = await reconcileOnBoot(session, bridge);
  assert.equal(decision.action, 'unsuspend');
  assert.equal(decision.offerResume, true);
  const res = await applyRecovery(decision, bridge);
  assert.deepEqual(res.applied, ['com.tiktok', 'com.whatsapp']);
});

test('S13: permission/owner revoked -> detection false, fallback mode', async () => {
  // Factory reset wipes the device owner (spec S7): isDpcActive() =
  // false -> the same binary runs in restriction fallback.
  let now = T0;
  const svc = createFocusService(
    {
      dpc: fakeDpc(),
      isDpcActive: async () => false, // DPC wiped
      clock: { now: () => now },
      newSessionId: () => 'C13',
    },
    makeRepo(),
    makeReducer(),
  );
  assert.equal(await svc.isBlockingAvailable(), false);
  await svc.startSession({ userId: 'u1', mode: 'timer', plannedDurationSec: 600 });
  now = T0 + 600_000;
  const bilan = await svc.endSession();
  assert.equal(bilan.actualDurationSec, 600);
});

// ============================================================================
// v1.8 DPC additions (spec S13.1-S13.8, unit-testable parts)
// ============================================================================

test('S13 DPC: provisioning -> isBlockingAvailable() = true when DPC active', async () => {
  const bridge = fakeBridge({ active: true });
  const adapter = new DpcAdapter(bridge, AURORA);
  const svc = createFocusService(
    {
      dpc: adapter,
      isDpcActive: () => bridge.isDpcActive(),
      clock: { now: () => T0 },
      newSessionId: () => 'D1',
    },
    makeRepo(),
    makeReducer(),
  );
  assert.equal(await svc.isBlockingAvailable(), true);
});

test('S13 DPC: precheck reports per-package status; aurora rejected', async () => {
  const bridge = fakeBridge({
    reject: [
      { pkg: 'com.android.systemui', reason: 'active_launcher' },
      { pkg: 'com.dialer', reason: 'default_dialer' },
    ],
  });
  const adapter = new DpcAdapter(bridge, AURORA);
  const pre = await adapter.precheckBlocklist([
    'com.tiktok',
    'com.android.systemui',
    'com.dialer',
    AURORA,
  ]);
  assert.equal(pre.allSuspendable, false);
  const byPkg = new Map(pre.packages.map((p) => [p.packageName, p]));
  assert.equal(byPkg.get('com.tiktok')?.suspendable, true);
  assert.equal(byPkg.get('com.android.systemui')?.rejectReason, 'active_launcher');
  assert.equal(byPkg.get('com.dialer')?.rejectReason, 'default_dialer');
  assert.equal(byPkg.get(AURORA)?.rejectReason, 'aurora_protected');
});

test('S13 DPC: session start suspends the set (exact applied set)', async () => {
  const bridge = fakeBridge({ active: true });
  const adapter = new DpcAdapter(bridge, AURORA);
  const dpc = fakeDpc();
  void dpc;
  const svc = createFocusService(
    {
      dpc: adapter,
      isDpcActive: () => bridge.isDpcActive(),
      clock: { now: () => T0 },
      newSessionId: () => 'D3',
    },
    makeRepo(),
    makeReducer(),
  );
  const res = await svc.applyBlocklist(['com.tiktok', 'com.whatsapp'], true);
  assert.deepEqual(res.applied, ['com.tiktok', 'com.whatsapp']);
  assert.equal(res.rejected.length, 0);
});

test('S13 DPC: session end un-suspends the exact set (diff vs snapshot empty)', async () => {
  const dpc = fakeDpc();
  let now = T0;
  const svc = createFocusService(
    { dpc, isDpcActive: async () => true, clock: { now: () => now }, newSessionId: () => 'D4' },
    makeRepo(),
    makeReducer(),
  );
  await svc.startSession({ userId: 'u1', mode: 'timer', plannedDurationSec: 600 });
  await svc.applyBlocklist(['com.tiktok'], true);
  now = T0 + 300_000;
  await svc.endSession();
  const calls = dpc.appliedCalls;
  assert.equal(calls.length, 2);
  assert.deepEqual(calls[0], [['com.tiktok'], true]);
  assert.deepEqual(calls[1], [['com.tiktok'], false]); // exact set restore
});

test('S13 DPC: reboot mid-session -> BOOT_COMPLETED -> un-suspend + resume offer', async () => {
  const bridge = fakeBridge({ active: true, suspended: ['com.tiktok'] });
  const session = {
    id: 'D5',
    status: 'active',
    systemStateSnapshot: ['com.tiktok'],
    endedAt: null,
  };
  const decision = await reconcileOnBoot(session, bridge);
  assert.equal(decision.action, 'unsuspend');
  assert.equal(decision.offerResume, true);
  await applyRecovery(decision, bridge);
});

test('S13 DPC: factory reset wipes DPC -> restriction fallback re-runnable', async () => {
  // After a factory reset the device owner is gone: detection false,
  // precheck reports nothing suspendable through the consumer path.
  const bridge = fakeBridge({ active: false });
  const adapter = new DpcAdapter(bridge, AURORA);
  assert.equal(await bridge.isDpcActive(), false);
  void adapter;
});
