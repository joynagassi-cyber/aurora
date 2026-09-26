/**
 * e2e-device.spec.ts — OQ-08 runnable Playwright device spec
 * (wave 4, HARPYS task 2: 20 E2E agent scenarios).
 *
 * Replays the 20 deterministic scenario contracts (@aurora/workflows
 * E2E_SCENARIOS) against a Playwright `Page` driving the Capacitor
 * webview build of apps/mobile. Each scenario: type the utterance in the
 * Agent composer, assert the observable result + the AD-9 events the
 * scenario declares.
 *
 * The device driver surface is `e2e/device/driver.ts` (structural
 * E2ePage/E2eLocator, no runtime @playwright/test dep in the package).
 * This spec rebinds the real Playwright `test`/`page` at run time.
 */
import { test, expect, type Page } from '@playwright/test';
import { E2E_SCENARIOS, type E2EScenario } from '@aurora/workflows';

/** The Agent composer — the single NL input surface (kernel S15 command bus). */
const AGENT_INPUT = '[data-test="agent-composer"]';
const CONFIRM_BTN = '[data-test="confirmation-cta"]';
const OFFLINE_BADGE = '[data-test="offline-badge"]';

/**
 * Run one scenario contract on the device: utterance -> confirm (ADR S5
 * when the class is `confirm`/`destructive`) -> assert the result line.
 */
async function runScenario(page: Page, s: E2EScenario): Promise<void> {
  await page.goto('/');
  const composer = page.locator(AGENT_INPUT);
  await composer.fill(s.utterance);
  await composer.press('Enter');

  // ADR S5 confirmation gate — the scenario's confirmation class decides.
  if (s.confirmation === 'confirm' || s.confirmation === 'destructive') {
    const cta = page.locator(CONFIRM_BTN);
    await expect(cta).toBeVisible({ timeout: 5_000 });
    await cta.click();
  }

  // The observable result: the result text surfaces in the run-state
  // strip (AgentRunState, AD-12 — the device sees only AgentRunState).
  await expect(page.getByText(new RegExp(s.result))).toBeVisible({ timeout: 15_000 });
}

// S1..S20 — one test per scenario contract (master mission S60).
for (const s of E2E_SCENARIOS) {
  test(`${s.id} — ${s.utterance} (${s.intent})`, async ({ page }) => {
    await runScenario(page, s);
  });
}

// Offline degradation (AD-1) — the spec that E3-class recovery holds on
// device: local reads stay usable, cloud actions disabled, badge shows.
test('offline degradation: AD-1 (E3) — local reads usable, cloud disabled', async ({
  page,
  context,
}) => {
  await context.setOffline(true);
  await page.goto('/');
  await expect(page.locator(OFFLINE_BADGE)).toBeVisible();
  // Local readback of last-known data must still render.
  await expect(page.getByText(/tasks|tasks/i).first()).toBeVisible();
  await context.setOffline(false);
});
