/**
 * @aurora/ui — vitest config (AD-1 / AD-10).
 *
 * 1 project, jsdom env (full DOM: `document`, `matchMedia`,
 * `ResizeObserver`-less — AG Grid / FullCalendar components need the
 * DOM). The headless DAGRE_CACHE logic tests run fine under jsdom
 * too (no DOM required).
 *
 * `src/*` aliases mirror tsconfig.paths.json — components import
 * `src/lib/utils` etc. and must resolve in the test runtime too.
 *
 * Coverage policy (AD-1): ONLY `src/components/ui/AgGridTable.tsx`
 * and `src/components/ui/CalendarView.tsx` are tracked — everything
 * else is excluded. Rationale: AG Grid + FullCalendar are the
 * vendor-heavy data components of this commit; their own source is
 * small, and CI tracking 2 focused files keeps the signal loud.
 * The 30fps DEVICE test (02 §9.2 pixel 4a @4x) lives in
 * `scripts/semantic-tree-30fps.mts` — run on hardware, not CI.
 */
import { defineConfig } from "vitest/config";
import path from "node:path";

export default defineConfig({
  resolve: {
    alias: {
      src: path.resolve(__dirname, "./src"),
    },
  },
  test: {
    environment: "jsdom",
    include: ["src/**/*.test.{ts,tsx}", "test/**/*.test.{ts,tsx}"],
    exclude: ["node_modules", "dist"],
    setupFiles: ["./test/setup.ts"],
    coverage: {
      provider: "v8",
      // AD-1 policy: only the 2 vendor-heavy data components tracked.
      include: [
        "src/components/ui/AgGridTable.tsx",
        "src/components/ui/CalendarView.tsx",
      ],
      exclude: [
        "src/**/*.test.{ts,tsx}",
        "test/**",
        "node_modules/**",
        "dist/**",
      ],
      reporter: ["text", "html"],
      thresholds: {
        lines: 80,
        statements: 80,
        functions: 80,
        branches: 70,
      },
    },
  },
});
