/**
 * AgentThinkingLoader — the "agent is thinking" state (docs/ui-libraries.md
 * §9.3). Organic organism (3 morphing blobs, GPU transform+opacity) +
 * rotating thinking-verbs (Claude "Pondering/Ruminating" pattern) +
 * optional static monochrome butterfly mark (S9: mark never animated) +
 * optional "Réflexion · Ns" elapsed chip ("Thought for Ns" pattern).
 *
 * Asserted via structure + `data-*` flags (docs/ui-libraries.md §6:
 * AD-13 states are data-driven, testable via data attributes).
 */
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import * as React from "react";
import {
  AgentThinkingLoader,
  DEFAULT_THINKING_WORDS,
} from "src/components/ui/AgentThinkingLoader";
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

  it("renders the 3-blob organism + rotating thinking-words + stable SR label", () => {
    const { container, unmount } = render(<AgentThinkingLoader />);
    const root = container.querySelector<HTMLElement>("[data-agent-thinking]");
    expect(root).not.toBeNull();
    expect(root?.getAttribute("data-thinking-state")).toBe("thinking");
    expect(root?.getAttribute("data-reduced-motion")).toBe("false");
    expect(root?.getAttribute("role")).toBe("status");
    expect(root?.getAttribute("aria-live")).toBe("polite");
    // 3 organic blob layers (SVG paths)
    expect(container.querySelectorAll("svg path").length).toBe(3);
    // rotating thinking-words: first word visible + stable SR label
    // (the visible word = the aria-hidden span; the sr-only label is a sibling)
    const wordsBox = container.querySelector<HTMLElement>("[data-thinking-words]");
    expect(wordsBox).not.toBeNull();
    expect(
      wordsBox?.querySelector("span[aria-hidden]")?.textContent?.trim(),
    ).toBe(DEFAULT_THINKING_WORDS[0]);
    expect(DEFAULT_THINKING_WORDS.length).toBeGreaterThanOrEqual(8);
    // no inhale pulse before the first word change
    expect(root?.getAttribute("data-inhale")).toBe("false");
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
        <AgentThinkingLoader state={state} words={[]} />,
      );
      const root = container.querySelector<HTMLElement>("[data-agent-thinking]");
      expect(root?.getAttribute("data-thinking-state")).toBe(state);
      // words=[] → static label fallback (data-thinking-label)
      expect(container.querySelector("[data-thinking-words]")).toBeNull();
      unmount();
    }
  });

  /** All aria-hidden thinking-word spans. In sync AnimatePresence mode a
   *  briefly-exiting word can coexist with the current one for ~200 ms, so
   *  this returns every one (assert membership, not order). The sr-only
   *  label is NOT aria-hidden, so it never appears here. */
  const thinkingWordTexts = (container: HTMLElement) =>
    Array.from(
      container.querySelectorAll("[data-thinking-words] [aria-hidden]"),
    ).map((s) => s.textContent?.trim());

  it("rotates the thinking-words on an interval (Claude pattern)", () => {
    vi.useFakeTimers();
    try {
      const { container, unmount } = render(
        <AgentThinkingLoader words={["A…", "B…", "C…"]} wordIntervalMs={1000} />,
      );
      // initial single word
      expect(thinkingWordTexts(container)).toEqual(["A…"]);
      // act() flushes the interval-driven state update synchronously
      // (React 18 schedules the re-render outside fake timers).
      React.act(() => {
        vi.advanceTimersByTime(1000);
      });
      expect(thinkingWordTexts(container)).toContain("B…");
      // organism "inhale" pulse fired on the word change (retouche 1)
      expect(
        container
          .querySelector<HTMLElement>("[data-agent-thinking]")
          ?.getAttribute("data-inhale"),
      ).toBe("true");
      React.act(() => {
        vi.advanceTimersByTime(1000);
      });
      expect(thinkingWordTexts(container)).toContain("C…");
      React.act(() => {
        vi.advanceTimersByTime(1000); // wraps
      });
      expect(thinkingWordTexts(container)).toContain("A…");
      unmount();
    } finally {
      vi.useRealTimers();
    }
  });

  it("reduced-motion = words stay static (no rotation, 05 §2.6 rule 2)", () => {
    vi.useFakeTimers();
    restore();
    const restore2 = mockReducedMotion(true);
    try {
      const { container, unmount } = render(
        <AgentThinkingLoader words={["A…", "B…"]} wordIntervalMs={1000} />,
      );
      expect(thinkingWordTexts(container)).toEqual(["A…"]);
      vi.advanceTimersByTime(5000);
      expect(thinkingWordTexts(container)).toEqual(["A…"]); // static — no rotation
      // no inhale pulse either (reduced-motion = fully static)
      expect(
        container
          .querySelector<HTMLElement>("[data-agent-thinking]")
          ?.getAttribute("data-inhale"),
      ).toBe("false");
      unmount();
    } finally {
      vi.useRealTimers();
      restore2();
    }
  });

  it("renders the elapsed-seconds chip when provided (Thought-for-Ns)", () => {
    const { container, unmount } = render(
      <AgentThinkingLoader elapsedSeconds={12} />,
    );
    expect(container.querySelector("[data-thinking-elapsed]")?.textContent).toBe(
      "Réflexion · 12 s",
    );
    unmount();
    // default = no chip
    const noChip = render(<AgentThinkingLoader />);
    expect(noChip.container.querySelector("[data-thinking-elapsed]")).toBeNull();
    noChip.unmount();
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
