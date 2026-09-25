/**
 * @aurora/focus — service + DPC surface tests (node --experimental-
 * strip-types + node:test). Deterministic fakes, no DOM, no vendor.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  createFocusService,
  type FocusDpcSurface,
  type FocusNotificationReducer,
  type FocusSessionRepo,
} from '../src/service.ts';
import type { FocusPrecheck } from '../src/controller.ts';
import type { FocusSession, FocusSessionBilan } from '@aurora/domain';

function fakeDpc(opts: {
  reject?: { pkg: string; reason: string }[];
} = {}) {
  const rejected = new Set((opts.reject ?? []).map((r) => r.pkg));
  const reason = (pkg: string) =>
    (opts.reject ?? []).find((r) => r.pkg === pkg)?.reason ?? 'not_suspendable';
  const appliedCalls: [string[], boolean][] = [];
  const dpc: FocusDpcSurface = {
    precheckBlocklist: async (names): Promise<FocusPrecheck> => {
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
        rejected: names
          .filter((n) => rejected.has(n))
          .map((pkg) => ({ pkg, reason: reason(pkg) })),
      };
    },
  };
  return { ...dpc, appliedCalls };
}

function makeRepo(): FocusSessionRepo & {
  opened: FocusSession[];
  closed: [string, FocusSessionBilan][];
} {
  const opened: FocusSession[] = [];
  const closed: [string, FocusSessionBilan][] = [];
  return {
    opened,
    closed,
    open: async (s) => {
      opened.push(s);
    },
    close: async (id, b) => {
      closed.push([id, b]);
    },
  };
}

function makeReducer(): FocusNotificationReducer & { calls: boolean[] } {
  const calls: boolean[] = [];
  return {
    calls,
    reduceForFocus: async (on) => {
      calls.push(on);
    },
  };
}

const T0 = Date.parse('2026-09-25T09:00:00Z');

test('service: start -> apply blocklist -> end restores the exact snapshot set', async () => {
  const dpc = fakeDpc({ reject: [{ pkg: 'com.system', reason: 'system_package' }] });
  const repo = makeRepo();
  const reducer = makeReducer();
  let now = T0;
  const svc = createFocusService(
    {
      dpc,
      isDpcActive: async () => true,
      clock: { now: () => now },
      newSessionId: () => 'S1',
    },
    repo,
    reducer,
  );

  assert.equal(await svc.isBlockingAvailable(), true);
  const s = await svc.startSession({
    userId: 'u1',
    mode: 'timer',
    plannedDurationSec: 300,
    taskIds: ['t1'],
  });
  assert.equal(s.id, 'S1');
  assert.equal(repo.opened.length, 1);
  assert.equal(reducer.calls[0], true);

  // blocking mode: apply the suspendable subset, exclude the rejected.
  const pre = await svc.precheckBlocklist(['com.tiktok', 'com.system']);
  assert.equal(pre.allSuspendable, false);
  assert.deepEqual(pre.rejected, [
    { pkg: 'com.system', reason: 'system_package' },
  ]);
  const applied = await svc.applyBlocklist(['com.tiktok', 'com.system'], true);
  assert.deepEqual(applied.applied, ['com.tiktok']);
  assert.equal(applied.rejected.length, 1);

  // advance the clock 5 minutes before ending.
  now = T0 + 300_000;

  // end: total restore of the snapshot set (only what was applied).
  const bilan = await svc.endSession();
  assert.equal(bilan.focusSessionId, 'S1');
  assert.equal(bilan.actualDurationSec, 300); // timer settled to now-T0
  const lastCall = dpc.appliedCalls.at(-1);
  assert.deepEqual(lastCall, [['com.tiktok'], false]);
  assert.equal(reducer.calls.at(-1), false);
  assert.equal(repo.closed.length, 1);
  assert.equal(svc.timer(), null);
});

test('service: no blocklist applied -> end still closes the session', async () => {
  const dpc = fakeDpc();
  const repo = makeRepo();
  let now = T0;
  const svc = createFocusService(
    {
      dpc,
      isDpcActive: async () => false,
      clock: { now: () => now },
      newSessionId: () => 'S2',
    },
    repo,
    makeReducer(),
  );
  assert.equal(await svc.isBlockingAvailable(), false);
  await svc.startSession({ userId: 'u1', mode: 'open' });
  now = T0 + 120_000;
  const bilan = await svc.endSession();
  assert.equal(bilan.actualDurationSec, 120);
  assert.equal(dpc.appliedCalls.length, 0);
});

test('service: onInterrupted marks the timer crashed + un-suspends snapshot', async () => {
  const dpc = fakeDpc();
  const repo = makeRepo();
  const svc = createFocusService(
    {
      dpc,
      isDpcActive: async () => true,
      clock: { now: () => T0 },
      newSessionId: () => 'S3',
    },
    repo,
    makeReducer(),
  );
  await svc.startSession({ userId: 'u1', mode: 'pomodoro', plannedDurationSec: 1500 });
  await svc.applyBlocklist(['com.tiktok'], true);
  await svc.onInterrupted('crash');
  assert.equal(svc.timer()?.state, 'interrupted');
  assert.equal(svc.timer()?.endReason, 'crash');
  assert.deepEqual(dpc.appliedCalls.at(-1), [['com.tiktok'], false]);
});

test('service: timer is null before start, active after start', () => {
  const svc = createFocusService(
    {
      dpc: fakeDpc(),
      isDpcActive: async () => false,
      clock: { now: () => T0 },
    },
    makeRepo(),
    makeReducer(),
  );
  assert.equal(svc.timer(), null);
  void svc.startSession({ userId: 'u1', mode: 'timer' });
  assert.equal(svc.timer()?.state, 'active');
});
