/**
 * Playwright config for OQ-08 E2E agent scenarios (wave 4, HARPYS).
 *
 * OQ-08 assumption: Playwright-on-device. The `baseURL` points at the
 * Aurora mobile app served locally; the 20 scenarios are replayed via
 * `@aurora/e2e.runAllScenarios` against the device stub backed by a
 * Playwright page.
 *
 * Status: DESIGNED_NOT_IMPLEMENTED — the suite runs once OQ-08 tooling
 * (device lab / emulator profile) is provisioned. Kept here so the
 * runner + config land in the same commit as the scenario spec.
 */
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: '../packages/workflows/src/e2e-scenarios',
  timeout: 120_000,
  fullyParallel: false,
  retries: 1,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL: 'http://localhost:5173',
    trace: 'retain-on-failure',
  },
});
