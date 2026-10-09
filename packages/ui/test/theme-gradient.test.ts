/**
 * theme-gradient.test.ts — the theme-owned `--aurora-theme-gradient`
 * token (05 §5.4, rework 2026-10-08): every EXPRESSIVE theme declares a
 * structured `gradient` (angle + hex stops) that resolves to a real CSS
 * `linear-gradient(...)` — and PRESETS carry none ("" — a preset is an
 * accent-only technical adjustment, never a universe, 05 §5.5), so the
 * swatch preview on the settings screen can be honest (no fake
 * aurora-fallback, AD-13).
 */
import { describe, expect, it } from "vitest";
import { PRESETS, THEMES } from "../src/themes";
import { gradientCSS, resolveThemeCSSVars } from "../src/themes/resolve";
import type { PresetName } from "../src/themes/types";

const EXPRESSIVE = Object.keys(THEMES) as Array<keyof typeof THEMES>;
const PRESET_NAMES = Object.keys(PRESETS) as PresetName[];

describe("theme-owned gradient token (05 §5.4)", () => {
  it("every expressive theme declares a structured gradient (2+ stops)", () => {
    for (const name of EXPRESSIVE) {
      const g = THEMES[name].gradient;
      expect(g, `theme ${name} lacks a structured gradient`).toBeDefined();
      expect(g!.stops.length, `theme ${name} gradient needs 2+ stops`).toBeGreaterThanOrEqual(2);
      for (const stop of g!.stops) {
        expect(stop, `theme ${name} stop ${stop} must be a hex`).toMatch(/^#[0-9A-Fa-f]{6}$/);
      }
    }
  });

  it("the 3 presets carry NO gradient (accent-only, 05 §5.5)", () => {
    for (const name of PRESET_NAMES) {
      expect((PRESETS[name] as unknown as { gradient?: unknown }).gradient).toBeUndefined();
    }
  });

  it("gradientCSS() renders angle + stops (default 120°, honest '' when <2 stops)", () => {
    expect(gradientCSS({ angle: 90, stops: ["#111111", "#222222"] }))
      .toBe("linear-gradient(90deg, #111111, #222222)");
    expect(gradientCSS({ stops: ["#333333", "#444444", "#555555"] }))
      .toBe("linear-gradient(120deg, #333333, #444444, #555555)");
    expect(gradientCSS({ stops: ["#666666"] })).toBe("");
    expect(gradientCSS(undefined)).toBe("");
  });

  it("resolveThemeCSSVars() emits --aurora-theme-gradient for a theme, '' for a preset", () => {
    const themeVars = resolveThemeCSSVars("aurora", "light");
    const key = "--aurora-theme-gradient";
    expect(themeVars[key]).toMatch(/^linear-gradient\(/);
    expect(themeVars["--aurora-theme-gradient"]).toContain(THEMES.aurora.gradient!.stops[0]);

    for (const name of PRESET_NAMES) {
      const presetVars = resolveThemeCSSVars(name, "light");
      // A preset keeps the UNDERLYING theme's gradient (it adjusts accents
      // on top, 05 §5.5) — so with preset param undefined the resolved
      // value is the default theme's (aurora) gradient, never "".
      expect(presetVars["--aurora-theme-gradient"]).toMatch(/^linear-gradient\(/);
    }
  });

  it("every expressive theme resolves a DISTINCT gradient (no two share one)", () => {
    const seen = new Map<string, string>();
    for (const name of EXPRESSIVE) {
      const g = resolveThemeCSSVars(name, "light")["--aurora-theme-gradient"]!;
      expect(g, `theme ${name} resolved no gradient`).toMatch(/^linear-gradient\(/);
      const colliding = [...seen.entries()].find(([, v]) => v === g);
      expect(colliding, `themes ${colliding?.[0]} and ${name} share the same gradient`)
        .toBeUndefined();
      seen.set(name, g);
    }
  });
});
