/**
 * @aurora/platform — minimal tests (node:test). DPC adapter invariants,
 * boot-receiver reconciliation, and the G-H1 bilan score. No DOM.
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  applyRecovery,
  computeFocusBilanScore,
  DpcAdapter,
  reconcileOnBoot,
  type DpcBridge,
} from '../src/index.ts';

const AURORA_PKG = 'com.aurora';

/** A deterministic fake bridge for tests. */
function fakeBridge(opts: {
  suspended?: string[];
  rejectPkgs?: string[];
  rejectReason?: string;
} = {}): DpcBridge {
  const rejected = new Set(opts.rejectPkgs ?? []);
  return {
    isDpcActive: async () => true,
    setPackagesSuspended: async (names, suspended) => ({
      applied: names.filter((n) => !rejected.has(n)),
      rejected: names
        .filter((n) => rejected.has(n))
        .map((pkg) => ({ pkg, reason: opts.rejectReason ?? 'system_package' })),
    }),
    getPackagesSuspended: async () => opts.suspended ?? [],
    precheckSuspendability: async (names) =>
      names.map((pkg) => ({
        packageName: pkg,
        suspendable: !rejected.has(pkg),
        rejectReason: rejected.has(pkg)
          ? (opts.rejectReason ?? 'system_package')
          : undefined,
      })),
  };
}

// --- DpcAdapter (invariants, spec S3) --------------------------------------

test('dpc: applyBlocklist never suspends the aurora package (S3 invariant)', async () => {
  const adapter = new DpcAdapter(fakeBridge(), AURORA_PKG);
  const res = await adapter.applyBlocklist(
    ['com.tiktok', AURORA_PKG],
    true,
  );
  assert.equal(res.applied.includes(AURORA_PKG), false);
  assert.deepEqual(res.applied, ['com.tiktok']);
  assert.deepEqual(res.rejected, [
    { pkg: AURORA_PKG, reason: 'aurora_protected' },
  ]);
});

test('dpc: precheckBlocklist forces aurora_protected + reports rejects', async () => {
  const bridge = fakeBridge({
    rejectPkgs: ['com.android.systemui'],
    rejectReason: 'active_launcher',
  });
  const adapter = new DpcAdapter(bridge, AURORA_PKG);
  const pre = await adapter.precheckBlocklist([
    'com.tiktok',
    'com.android.systemui',
    AURORA_PKG,
  ]);
  assert.equal(pre.allSuspendable, false);
  assert.deepEqual(
    pre.rejected.map((r) => r.pkg).sort(),
    [AURORA_PKG, 'com.android.systemui'].sort(),
  );
  const aurora = pre.packages.find((p) => p.packageName === AURORA_PKG);
  assert.equal(aurora?.suspendable, false);
  assert.equal(aurora?.rejectReason, 'aurora_protected');
});

// --- Boot receiver (spec S7) ------------------------------------------------

test('boot: interrupted session + live suspensions -> unsuspend + offer resume', async () => {
  const bridge = fakeBridge({ suspended: ['com.tiktok', 'com.whatsapp'] });
  const session = {
    id: '01',
    status: 'interrupted',
    systemStateSnapshot: ['com.tiktok', 'com.whatsapp', 'com.youtube'],
    endedAt: null,
  };
  const decision = await reconcileOnBoot(session, bridge);
  assert.equal(decision.action, 'unsuspend');
  // reconcile to the LIVE system state (youtube was already un-suspended)
  assert.deepEqual(decision.packages, ['com.tiktok', 'com.whatsapp']);
  assert.equal(decision.offerResume, true);
  const applied = await applyRecovery(decision, bridge);
  assert.deepEqual(applied.applied, ['com.tiktok', 'com.whatsapp']);
});

test('boot: lost session, system still suspending -> unsuspend, NO resume offer', async () => {
  const bridge = fakeBridge({ suspended: ['com.tiktok'] });
  const decision = await reconcileOnBoot(null, bridge);
  assert.equal(decision.action, 'unsuspend');
  assert.equal(decision.offerResume, false);
  assert.deepEqual(decision.packages, ['com.tiktok']);
});

test('boot: session clean + system clean -> no-op', async () => {
  const bridge = fakeBridge({});
  const decision = await reconcileOnBoot(
    { id: '01', status: 'completed', systemStateSnapshot: [], endedAt: 'x' },
    bridge,
  );
  assert.equal(decision.action, 'none');
});

// --- Bilan score (G-H1) ------------------------------------------------------

test('bilan: perfect session = 100, interruptions penalize', () => {
  const perfect = computeFocusBilanScore({
    plannedMinutes: 30,
    actualMinutes: 30,
    interruptions: 0,
    plannedTaskCount: 2,
    completedTaskCount: 2,
  });
  assert.equal(perfect.score, 100);
  const interrupted = computeFocusBilanScore({
    plannedMinutes: 30,
    actualMinutes: 45,
    interruptions: 2,
  });
  // 100*0.5 + 70*0.3 + 100*0.2 = 91
  assert.equal(interrupted.score, 91);
  assert.equal(interrupted.interruptionPenalty, 70);
});
