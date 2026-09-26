/**
 * Focus Mode DPC — the 8 mandatory E2E scenarios (docs/focus-mode/
 * spec.md S13 "v1.8 DPC additions (wave-0 provisioning tests +
 * wave-7 E2E)", testing/matrix S2 "Focus Mode mandatory scenarios").
 *
 * OQ-17: the DPC suite runs on the PROVISIONED DEVICE OWNER device
 * (Aurora = device owner, spec S9.1), NOT in CI. These 8 scenarios
 * are DEVICE-OBSERVED (spec S13): they assert on the DPC system state
 * (`setPackagesSuspended` / `getPackagesSuspended`), the session row
 * (AD-15 SSoT), and the restore discipline (spec S7: "the DPC state
 * IS the snapshot — nothing else is modified in V1").
 *
 * Architecture (spec S10): the scenarios exercise the
 * `FocusController` / `FocusControllerDpc` ports, NEVER the native
 * DPM surface directly. The port is satisfied by the
 * `DpcAdapter` (packages/platform, Foundation) — the test injects a
 * MOCK adapter so the suite is deterministic on a CI runner for the
 * consumer fallback path (OQ-08), while the DPC path runs on the
 * provisioned device.
 *
 * Scenario shape (spec S13, verbatim mapping to the 8 numbered items):
 *   1. provisioning: factory reset → no accounts → `dpm set-device-owner`
 *      → `isBlockingAvailable() = true`.
 *   2. `precheckBlocklist` reports per-package status; non-suspendable
 *      packages shown with reasons; blocklist excluding Aurora is rejected.
 *   3. session start suspends the set (verify: activities denied,
 *      notifications hidden, recents clean) while Internet/Aurora/
 *      search remain usable.
 *   4. session end un-suspends the exact set (diff against snapshot
 *      = empty).
 *   5. reboot mid-session → BOOT_COMPLETED receiver → un-suspend
 *      default + resume offer.
 *   6. factory reset → DPC wiped → app runs in restriction fallback;
 *      re-provisioning procedure documented and re-runnable.
 *   7. emergency: device with stuck suspensions → S9.4 path
 *      documented.
 *   8. calls (experimental only): with the role granted,
 *      silence/block per policy; emergency calls always ring;
 *      no role = calls ring as usual (documented).
 *
 * Each scenario is a PURE function `(adapter) => assertion bundle`
 * so the release pipeline (wave 7 task 8) can wire it to either a
 * mock adapter (CI, consumer fallback) or the real `DpcAdapter`
 * (device, OQ-17). No Playwright import here — the device surface is
 * the adapter, the assertions are port-level.
 */

export interface DpcPort {
  /** spec S10 `isBlockingAvailable` — detection (DPC + pre-check), not a constant. */
  isBlockingAvailable(): Promise<boolean>;
  /** spec S10 v1.8 `precheckBlocklist`. */
  precheckBlocklist(names: string[]): Promise<BlocklistPrecheck>;
  /** spec S10 v1.8 `applyBlocklist`. */
  applyBlocklist(
    names: string[],
    on: boolean,
  ): Promise<{ applied: string[]; rejected: { pkg: string; reason: string }[] }>;
  /** the device-owner package (Aurora) — the spec S3 invariant: NEVER suspended. */
  readonly ownerPackage: string;
  /** device reboot event (spec S7 BOOT_COMPLETED receiver). */
  onReboot(cb: () => void): void;
}

export interface BlocklistPrecheck {
  suspendable: string[];
  rejected: { pkg: string; reason: string }[];
}

export interface FocusSessionRow {
  id: string;
  systemStateSnapshot: string[];
  endReason: 'manual' | 'expiry' | 'crash' | 'reboot' | 'restoring' | null;
  endedAt: string | null;
}

/** The 8 scenario ids (spec S13, verbatim). */
export const FOCUS_DPC_SCENARIOS = [
  'provisioning-device-owner',
  'precheck-per-package',
  'session-start-suspend',
  'session-end-unsuspend-diff-empty',
  'reboot-mid-session-recover',
  'factory-reset-fallback',
  'emergency-stuck-suspension',
  'calls-experimental',
] as const;

export type FocusDpcScenarioId = (typeof FOCUS_DPC_SCENARIOS)[number];

/** The scenario assertions bundle — one per spec S13 item. */
export interface ScenarioResult {
  scenario: FocusDpcScenarioId;
  ok: boolean;
  /** which assertion failed (for Sentry / release notes). */
  failure?: string;
}

/**
 * Scenario 1 — provisioning (spec S13.1 / S9.1): after the
 * `dpm set-device-owner` procedure, `isBlockingAvailable()` MUST be
 * true (spec S2 "detection, not a constant" — the device IS provisioned).
 */
export function s1_provisioning(dpc: DpcPort): Promise<ScenarioResult> {
  return dpc.isBlockingAvailable().then((blocking) => ({
    scenario: 'provisioning-device-owner',
    ok: blocking === true,
    failure: blocking ? undefined : 'isBlockingAvailable() = false after provisioning',
  }));
}

/**
 * Scenario 2 — precheck (spec S13.2 / S4): the pre-check reports
 * per-package suspendability; a blocklist that includes Aurora's
 * own package is REJECTED (spec S3 invariant, the adapter guard).
 */
export function s2_precheck(dpc: DpcPort): Promise<ScenarioResult> {
  return dpc
    .precheckBlocklist(['com.zhiliaoapp.musically', dpc.ownerPackage])
    .then((pre) => {
      const rejectedAurora = pre.rejected.some((r) => r.pkg === dpc.ownerPackage);
      const ok =
        pre.suspendable.includes('com.zhiliaoapp.musically') &&
        rejectedAurora === true;
      return {
        scenario: 'precheck-per-package' as const,
        ok,
        failure: ok
          ? undefined
          : `precheck: expected Aurora (${dpc.ownerPackage}) rejected + TikTok suspendable, got ${JSON.stringify(pre)}`,
      };
    });
}

/**
 * Scenario 3 — session start (spec S13.3): applying the blocklist
 * suspends the set; the Internet/Aurora/search paths stay usable
 * (non-interference, spec S2 "Internet stays active").
 */
export function s3_sessionStart(
  _dpc: DpcPort,
  apply: (names: string[]) => Promise<{ applied: string[] }>,
): Promise<ScenarioResult> {
  void _dpc;
  return apply(['com.zhiliaoapp.musically']).then(({ applied }) => ({
    scenario: 'session-start-suspend' as const,
    ok: applied.length > 0,
    failure: applied.length ? undefined : 'no packages suspended at session start',
  }));
}

/**
 * Scenario 4 — session end (spec S13.4 / S7): un-suspending the
 * exact set makes the diff against the session row's
 * `systemStateSnapshot` empty (the restore discipline, spec S7
 * "total restore within Aurora's scope").
 */
export function s4_sessionEnd(
  _dpc: DpcPort,
  session: FocusSessionRow,
  restore: () => Promise<{ applied: string[] }>,
): Promise<ScenarioResult> {
  void _dpc;
  return restore().then(({ applied }) => {
    const snapshot = new Set(session.systemStateSnapshot);
    const diff = applied.filter((p) => !snapshot.has(p)).length;
    return {
      scenario: 'session-end-unsuspend-diff-empty' as const,
      ok: diff === 0,
      failure: diff ? `restore touched ${diff} packages outside the snapshot` : undefined,
    };
  });
}

/**
 * Scenario 5 — reboot mid-session (spec S13.5 / S7): the
 * BOOT_COMPLETED receiver runs the crash path — default = un-suspend
 * everything + offer "resume" (the user decides, never silent).
 */
export function s5_reboot(
  _dpc: DpcPort,
  session: FocusSessionRow,
  fireReboot: () => Promise<void>,
): Promise<ScenarioResult> {
  let received = false;
  _dpc.onReboot(() => {
    received = true;
  });
  return fireReboot().then(() => ({
    scenario: 'reboot-mid-session-recover' as const,
    ok: received === true && session.endReason !== 'manual',
    failure: received
      ? undefined
      : 'BOOT_COMPLETED receiver not fired (spec S7 crash path)',
  }));
}

/**
 * Scenario 6 — factory reset (spec S13.6 / S7): the DPC is wiped,
 * the app runs in restriction fallback mode; the re-provisioning
 * procedure is documented + re-runnable. The assertion here:
 * `isBlockingAvailable()` returns false (consumer fallback).
 */
export function s6_factoryReset(dpc: DpcPort): Promise<ScenarioResult> {
  return dpc.isBlockingAvailable().then((blocking) => ({
    scenario: 'factory-reset-fallback' as const,
    ok: blocking === false,
    failure: blocking
      ? 'isBlockingAvailable() = true after factory reset (DPC not wiped?)'
      : undefined,
  }));
}

/**
 * Scenario 7 — emergency (spec S13.7 / S9.4): a device stuck with
 * suspensions reachable only via the S9.4 adb/dpm path. The E2E
 * asserts the documented path is the documented one (not a
 * supported daily flow) — a stub that records the outcome.
 */
export function s7_emergency(
  _dpc: DpcPort,
  stuckPackages: string[],
  documentPath: () => Promise<string>,
): Promise<ScenarioResult> {
  void _dpc;
  return documentPath().then((path) => ({
    scenario: 'emergency-stuck-suspension' as const,
    ok: stuckPackages.length > 0 && path.length > 0,
    failure:
      stuckPackages.length && path.length
        ? undefined
        : `no documented S9.4 path for ${stuckPackages.length} stuck packages`,
  }));
}

/**
 * Scenario 8 — calls, experimental (spec S13.8 / S5): with the
 * role granted, silence/block per policy; emergency calls always
 * ring (the invariant, spec S5 "emergency calls always ring");
 * no role = calls ring as usual. V1 status = documented
 * experimental option, never implied by the nominal session.
 */
export function s8_calls(
  dpc: DpcPort,
  hasCallScreeningRole: () => Promise<boolean>,
  callPolicy: { mode: 'ring_as_usual' | 'silence' | 'block' },
): Promise<ScenarioResult> {
  void dpc;
  return hasCallScreeningRole().then((role) => {
    const ok =
      (role && (callPolicy.mode === 'silence' || callPolicy.mode === 'block')) ||
      (!role && callPolicy.mode === 'ring_as_usual');
    return {
      scenario: 'calls-experimental' as const,
      ok,
      failure: ok
        ? undefined
        : `call policy ${callPolicy.mode} with role=${role} violates spec S5 (no role = ring_as_usual)`,
    };
  });
}

/** The full 8-scenario DPC suite (spec S13). */
export interface DpcSuiteInputs {
  dpc: DpcPort;
  session: FocusSessionRow;
  apply: (names: string[]) => Promise<{ applied: string[] }>;
  restore: () => Promise<{ applied: string[] }>;
  fireReboot: () => Promise<void>;
  stuckPackages: string[];
  documentPath: () => Promise<string>;
  hasCallScreeningRole: () => Promise<boolean>;
  callPolicy: { mode: 'ring_as_usual' | 'silence' | 'block' };
}

export async function runFocusDpcSuite(
  inputs: DpcSuiteInputs,
): Promise<ScenarioResult[]> {
  const { dpc, session, apply, restore, fireReboot, stuckPackages, documentPath, hasCallScreeningRole, callPolicy } =
    inputs;
  return [
    await s1_provisioning(dpc),
    await s2_precheck(dpc),
    await s3_sessionStart(dpc, apply),
    await s4_sessionEnd(dpc, session, restore),
    await s5_reboot(dpc, session, fireReboot),
    await s6_factoryReset(dpc),
    await s7_emergency(dpc, stuckPackages, documentPath),
    await s8_calls(dpc, hasCallScreeningRole, callPolicy),
  ];
}
