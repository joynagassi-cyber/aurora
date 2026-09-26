/**
 * Perf budgets — the 02 §9.1 / §9.4 SLOs (Sentry perf, AD-16d) for the
 * Pixel 4a reference device:
 *
 *   - JS bundle < 300 Ko gzipped (02 §9.1)
 *   - TTI (Time To Interactive) < 1.5 s
 *   - 30 fps sustained on the app tree
 *
 * This module is the STATIC check (CI + local gate): it measures the
 * apps/mobile declaration output (the `dist` that the bundle tool
 * consumes) against the 300 Ko budget. The TTI / 30fps SLOs are
 * device-observed (Sentry performance monitor, OQ-08 E2E wave 7) —
 * they cannot be asserted in a type-only gate and are kept here as
 * the *declared* budget constants the dashboard/alerts compare to.
 */

/** The three frozen perf budgets (02 §9.1/§9.4, AD-16d SLOs). */
export const PERF_BUDGETS = {
  /** JS gzip size ceiling (02 §9.1, Sentry SLO). 300 Ko = 307200 bytes. */
  jsGzBytes: 307200,
  /** Time To Interactive ceiling in ms (02 §9.1). */
  ttiMs: 1500,
  /** sustained frames-per-second floor on the Pixel 4a tree. */
  fpsMin: 30,
} as const;

export interface BudgetCheck {
  budget: number;
  actual: number;
  ok: boolean;
  detail?: string;
}

/** Assert a byte budget (JS gz). actual > budget = failure. */
export function checkBytes(budget: number, actual: number, detail?: string): BudgetCheck {
  return { budget, actual, ok: actual <= budget, detail };
}

/** Assert the TTI budget in ms. */
export function checkTti(budgetMs: number, actualMs: number): BudgetCheck {
  return { budget: budgetMs, actual: actualMs, ok: actualMs <= budgetMs, detail: 'tti_ms' };
}

/** Assert the fps floor (device-observed, OQ-08). */
export function checkFps(min: number, measured: number): BudgetCheck {
  return { budget: min, actual: measured, ok: measured >= min, detail: 'fps' };
}

/**
 * Combine budget checks — the gate passes only if ALL hold
 * (02 §9.1 "perf budgets" = the three SLOs together).
 */
export function allBudgetsPass(checks: readonly BudgetCheck[]): boolean {
  return checks.length > 0 && checks.every((c) => c.ok);
}
