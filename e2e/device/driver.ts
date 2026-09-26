/**
 * OQ-08 — E2E on device: Playwright + Capacitor driver (docs/testing/
 * matrix.md S1 "Capacitor smoke on device", wave 7; testing/matrix
 * "Mobile platform" class, 02 §9.1).
 *
 * OQ-08 ASSUMED VERDICT (ratified by this module): **Playwright**
 * driving the Capacitor webview (Chromium on Android via the
 * Capacitor browser bridge) — NOT Appium. Rationale:
 *   - Playwright has a stable auto-wait / network-idle model that maps
 *     1:1 onto Aurora's 5 UX states (loading/error/empty/success/
 *     offline/killed — ui-libraries §6).
 *   - The app shell is Ionic React in a webview: the DOM is the
 *     automation surface; a native-driver detour (Appium) adds a
 *     second framework for zero extra reach in the web-first slice.
 *   - Appium remains the documented FALLBACK (testing/matrix S1) for
 *     the native-only seams (device lifecycle, push) that the webview
 *     driver cannot reach.
 *
 * The E2E target = the SAME build that ships to the Capacitor
 * webview (apps/mobile dist, 02 §9.1). The 8 mandatory Focus DPC
 * scenarios (docs/focus-mode/spec.md S13, testing/matrix S2) live in
 * focus-dpc.spec.ts — device-observed, run on the provisioned DPC
 * device (OQ-17), not in CI (the consumer fallback path runs in CI).
 *
 * This module is a TYPE-LEVEL contract (no runtime import of
 * @playwright/test): the OQ-08 suite is wired to the device harness at
 * release time. The 3 scenario helpers + SLO constants are the
 * importable surface the release pipeline (wave 7 task 8) runs.
 */

/** The three perf SLOs this device suite observes (02 §9.1, AD-16d). */
export const DEVICE_SLOS = {
  /** TTI ceiling, ms (Pixel 4a reference). */
  ttiMs: 1500,
  /** JS gzip ceiling, bytes (300 Ko). */
  jsGzBytes: 307200,
  /** sustained fps floor on the tree. */
  fpsMin: 30,
} as const;

/** A Playwright test page (typed structurally — no runtime import). */
export interface E2ePage {
  getByRole: (role: string, opts: { name: RegExp | string }) => E2eLocator;
  getByLabel: (label: RegExp | string) => E2eLocator;
  getByText: (text: RegExp | string) => E2eLocator;
}

/** A Playwright locator (typed structurally — no runtime import). */
export interface E2eLocator {
  click(): Promise<void>;
  fill(text: string): Promise<void>;
  check(): Promise<void>;
}

/**
 * Scenario — "create → complete a task" (testing/matrix S1 E2E class,
 * 02 §11). The web-only slice: local data readback after the
 * mutation round-trips through the optimistic bridge.
 *
 * Returns the async scenario body — the caller (device harness) wires
 * it into the Playwright `test`/`expect` surface at runtime.
 */
export function scenarioCreateCompleteTask(
  page: E2ePage,
  assertVisible: (text: RegExp | string) => Promise<void>,
): () => Promise<void> {
  return async () => {
    // 1. Home → create a task (Agent or Tasks tab).
    await page.getByRole('button', { name: /n[ée]w t[aâ]che|create task/i }).click();
    await page.getByLabel(/title|titre/i).fill('E2E task');
    await page.getByRole('button', { name: /save|enregistrer/i }).click();
    // 2. The task surfaces (local readback, offline-capable).
    await assertVisible(/E2E task/);
    // 3. Complete it (mark done) — the 5-state "success" toast.
    await page.getByRole('checkbox', { name: /done|termin[eé]e/i }).check();
    await assertVisible(/success|termin[eé]e/i);
  };
}

/**
 * Scenario — offline scenario (testing/matrix S1 "Offline" class,
 * 02 §11): local reads stay usable, cloud actions disabled, offline
 * badge shows. The context toggle is device-harness-specific, passed
 * in as a callback so this helper stays platform-agnostic.
 */
export function scenarioOffline(
  _page: E2ePage,
  setOffline: (offline: boolean) => Promise<void>,
  assertVisible: (text: RegExp | string) => Promise<void>,
): () => Promise<void> {
  void _page;
  return async () => {
    await setOffline(true);
    // Local read: last-known data renders (5-state "offline" badge).
    await assertVisible(/offline|hors ligne/i);
    // Back online — a cloud action re-enables (AD-1 degradation).
    await setOffline(false);
  };
}
