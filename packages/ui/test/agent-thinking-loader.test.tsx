/**
 * AgentThinkingLoader — the "agent is thinking" state (docs/ui-libraries.md
 * §9.3). Organic organism (3 morphing blobs, GPU transform+opacity) +
 * optional static monochrome butterfly mark (S9: mark never animated).
 *
 * Asserted via structure + `data-*` flags (docs/ui-libraries.md §6:
 * AD-13 states are data-driven, testable via data attributes).
 */
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import * as React from "react";
import { AgentThinkingLoader } from "src/components/ui/AgentThinkingLoader";
import { render } from "./render";

/** Simulate `prefers-reduced-motion` (jsdom matchMedia → always false). */
function mockReducedMotion(reduced: boolean) {
  const orig = window.matchMedia;
  window.matchMedia = ((query: string) => ({
    matches: reduced && query.includes("prefers-reduced-motion"),
    media: query,
    onchange: null,
    addEventListener: () => {},
    removeEventListener: () => {},
    addListener: () => {},
    removeListener: () => {},
    dispatchEvent: () => false,
  })) as unknown as typeof window.matchMedia;
  return () => {
    window.matchMedia = orig;
  };
}

describe("AgentThinkingLoader (ui-libraries §9.3)", () => {
  let restore: () => void;

  beforeEach(() => {
    restore = mockReducedMotion(false);
  });
  afterEach(() => {
    restore();
  });

  it("renders the 3-blob organism + default label, role=status", () => {
    const { container, unmount } = render(<AgentThinkingLoader />);
    const root = container.querySelector<HTMLElement>("[data-agent-thinking]");
    expect(root).not.toBeNull();
    expect(root?.getAttribute("data-thinking-state")).toBe("thinking");
    expect(root?.getAttribute("data-reduced-motion")).toBe("false");
    expect(root?.getAttribute("role")).toBe("status");
    expect(root?.getAttribute("aria-live")).toBe("polite");
    // 3 organic blob layers (SVG paths)
    expect(container.querySelectorAll("svg path").length).toBe(3);
    // default label
    expect(
      container.querySelector("[data-thinking-label]")?.textContent,
    ).toBe("Agent réfléchit…");
    unmount();
  });

  it("renders the static butterfly mark when provided (S9: not animated)", () => {
    const { container, unmount } = render(
      <AgentThinkingLoader
        butterfly={<img src="aurora-mono.svg" alt="" data-mark />}
      />,
    );
    const mark = container.querySelector<HTMLElement>(
      "[data-thinking-butterfly]",
    );
    expect(mark).not.toBeNull();
    expect(mark?.querySelector("img[data-mark]")).not.toBeNull();
    unmount();
  });

  it("supports idle + exiting states (data-driven, §9.3 states)", () => {
    for (const state of ["idle", "exiting"] as const) {
      const { container, unmount } = render(
        <AgentThinkingLoader state={state} label="" />,
      );
      const root = container.querySelector<HTMLElement>("[data-agent-thinking]");
      expect(root?.getAttribute("data-thinking-state")).toBe(state);
      // no label rendered when label="" (non-interactive minimal)
      expect(container.querySelector("[data-thinking-label]")).toBeNull();
      expect(root?.getAttribute("aria-live")).toBe(null);
      unmount();
    }
  });

  it("reduced-motion ON = static marker (05 §2.6 rule 2)", () => {
    restore();
    const restore2 = mockReducedMotion(true);
    const { container, unmount } = render(<AgentThinkingLoader />);
    const root = container.querySelector<HTMLElement>("[data-agent-thinking]");
    expect(root?.getAttribute("data-reduced-motion")).toBe("true");
    // organism still present (static fallback), no crash
    expect(container.querySelectorAll("svg path").length).toBe(3);
    unmount();
    restore2();
  });
});
