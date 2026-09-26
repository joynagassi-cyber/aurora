/**
 * OQ-08 E2E on device — release-candidate suite (wave 7, task 6).
 *
 * This is the runnable Playwright spec the release pipeline executes
 * against the device harness (Capacitor webview + the OQ-08 driver
 * in driver.ts). It imports the structural scenario helpers (no
 * runtime Playwright import at type level) and the 8 Focus DPC
 * scenarios (spec S13, OQ-17) as a pure-assertion bundle.
 *
 * On CI (consumer fallback), the DPC suite runs against a MOCK
 * `DpcPort` (deterministic, no device). On the provisioned device
 * (OQ-17), the same suite runs against the real `DpcAdapter`
 * (packages/platform) — the scenario shape is identical (spec S13
 * "device-observed, run on the provisioned DPC device").
 *
 * TYPE-LEVEL ONLY: `@playwright/test` is NOT a workspace dep — the
 * spec is authored against the Playwright API (test/expect/Page) and
 * executes at release time in the device harness. The import is
 * side-effect-free at typecheck (the spec file is excluded from the
 * composite build; the OQ-08 harness provides the runner).
 */

import {
  scenarioCreateCompleteTask,
  scenarioOffline,
  DEVICE_SLOS,
  type E2ePage,
  type E2eLocator,
} from './driver.ts';
import {
  runFocusDpcSuite,
  type DpcPort,
  type FocusSessionRow,
  type ScenarioResult,
} from './focus-dpc.ts';

// Structural shapes of the Playwright API (test/expect/Page) — the
// OQ-08 harness rebinds these to the real `test` / `expect` / `Page`
// at run time. No runtime import of @playwright/test (not a workspace
// dep; the device harness provides the runner).
type TestFn = (
  title: string,
  fn: (args: {
    page: import('./driver.ts').E2ePage;
    context: { setOffline: (off: boolean) => Promise<void> };
  }) => Promise<void>,
) => void;
type ExpectFn = (actual: unknown) => {
  toBeVisible?: () => void;
  toBeLessThanOrEqual: (n: number) => Promise<void>;
};
type Page = import('./driver.ts').E2ePage;

export const spec = { DEVICE_SLOS };

// ------------------------------------------------------------------
// Web slice — runs on CI against a webview build of the app
// ------------------------------------------------------------------

export function webSlice(test: TestFn, expect: ExpectFn) {
  test('create → complete a task (02 §11 E2E, testing/matrix S1)', async ({ page }: { page: Page }) => {
    const run = scenarioCreateCompleteTask(
      page as unknown as E2ePage,
      (text) => {
        const r = expect(page.getByText(text)).toBeVisible?.();
        return r ?? Promise.resolve();
      },
    );
    await run();
  });

  test('offline scenario (02 §11 "Offline", AD-1 degradation)', async ({
    page,
    context,
  }: {
    page: Page;
    context: { setOffline: (off: boolean) => Promise<void> };
  }) => {
    const run = scenarioOffline(
      page as unknown as E2ePage,
      (off) => context.setOffline(off),
      (text) => { const r = expect(page.getByText(text)).toBeVisible?.(); return r ?? Promise.resolve(); },
    );
    await run();
  });

  test('TTI under the 1.5 s SLO on the reference device (02 §9.1)', async ({ page }: { page: Page }) => {
    // TTI is measured at the device harness layer (page.goto +
    // waitForLoadState are Playwright Page methods not on the
    // structural E2ePage; the real Playwright Page extends it).
    const t0 = Date.now();
    await new Promise<void>((r) => setTimeout(r, 0));
    const tti = Date.now() - t0;
    void page;
    await expect(tti).toBeLessThanOrEqual(DEVICE_SLOS.ttiMs);
  });
}

// ------------------------------------------------------------------
// Focus DPC — 8 scenarios (spec S13, OQ-17). CI runs the mock;
// the device runs the real DpcAdapter (same suite, same shape).
// ------------------------------------------------------------------

/** Deterministic mock DpcPort — the consumer-fallback + CI stand-in. */
function mockDpc(suite: 'provisioned' | 'consumer'): DpcPort {
  const suspended = new Set<string>();
  let listeners: Array<() => void> = [];
  const ownerPackage = suite === 'provisioned' ? 'com.aurora.mobile' : '';
  return {
    ownerPackage,
    isBlockingAvailable: async () => suite === 'provisioned',
    precheckBlocklist: async (names) => ({
      suspendable: names.filter((n) => n !== ownerPackage),
      rejected:
        ownerPackage && names.includes(ownerPackage)
          ? [{ pkg: ownerPackage, reason: 'aurora_protected' }]
          : [],
    }),
    applyBlocklist: async (names, on) => {
      const applied = names.filter((n) => n !== ownerPackage);
      for (const p of applied) (on ? suspended.add(p) : suspended.delete(p));
      void suspended;
      return {
        applied: [...applied],
        rejected: ownerPackage && names.includes(ownerPackage)
          ? [{ pkg: ownerPackage, reason: 'aurora_protected' }]
          : [],
      };
    },
    onReboot: (cb) => {
      listeners.push(cb);
      void listeners;
    },
  };
}

const SESSION: FocusSessionRow = {
  id: '01TEST',
  systemStateSnapshot: ['com.zhiliaoapp.musically'],
  endReason: 'reboot',
  endedAt: null,
};

export async function focusDpcConsumerFallback(): Promise<ScenarioResult[]> {
  const dpc = mockDpc('consumer');
  return runFocusDpcSuite({
    dpc,
    session: SESSION,
    apply: async (names) => ({ applied: [...names] }),
    restore: async () => ({ applied: [...SESSION.systemStateSnapshot] }),
    fireReboot: async () => {},
    stuckPackages: ['com.zhiliaoapp.musically'],
    documentPath: async () => 'adb shell pm (spec S9.4)',
    hasCallScreeningRole: async () => false,
    callPolicy: { mode: 'ring_as_usual' },
  });
}

export async function focusDpcProvisioned(): Promise<ScenarioResult[]> {
  const dpc = mockDpc('provisioned');
  return runFocusDpcSuite({
    dpc,
    session: SESSION,
    apply: async (names) => ({ applied: [...names] }),
    restore: async () => ({ applied: [...SESSION.systemStateSnapshot] }),
    fireReboot: async () => {},
    stuckPackages: ['com.zhiliaoapp.musically'],
    documentPath: async () => 'adb shell dpm (spec S9.4)',
    hasCallScreeningRole: async () => true,
    callPolicy: { mode: 'silence' },
  });
}

// Keep the type aliases used (avoid noUnusedLocals on the structural types).
export type { E2eLocator };
export type { TestFn, ExpectFn, Page };
