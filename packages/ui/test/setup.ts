/**
 * Vitest setup — enables React 18's `act()` environment so the test
 * `render` helper (test/render.ts) flushes work synchronously without
 * the "not configured to support act" warning.
 */
(globalThis as unknown as { IS_REACT_ACT_ENVIRONMENT?: boolean })
  .IS_REACT_ACT_ENVIRONMENT = true;
