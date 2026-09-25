/**
 * Minimal test render helper for @aurora/ui smoke tests.
 *
 * Uses React 18 `act` + `createRoot` into a DOM node (jsdom env).
 * No RTL dependency — assertions are on structure / `data-state`
 * flags, not interaction (docs/ui-libraries.md §6: AD-13 states are
 * data-driven, testable via `data-state` attributes).
 */
import * as React from "react";
import { createRoot } from "react-dom/client";

// React 18.3: `act` is available on the `react` package itself — the
// `react-dom/test-utils` re-export is deprecated and logs a warning.
const act = React.act;
import { createRoot } from "react-dom/client";

export function render(element: React.ReactElement): {
  container: HTMLElement;
  unmount: () => void;
} {
  const container = document.createElement("div");
  document.body.appendChild(container);
  const root = createRoot(container);
  // act() flushes React work synchronously → DOM is ready when
  // `render` returns. No microtask races, no pending-timer leaks.
  act(() => {
    root.render(element);
  });
  return {
    container,
    unmount: () => {
      act(() => {
        root.unmount();
      });
      container.remove();
    },
  };
}
