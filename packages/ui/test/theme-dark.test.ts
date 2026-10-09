/**
 * theme-dark.test.ts — 05 §5.4 contrast calibration (roadmap 10-07).
 *
 * The 10 expressive themes now carry a `colorsDark` variant: on the dark
 * neutral canvas (#121212) resolution switches to the recalibrated
 * accents (brighter accents, a DARK surface tint instead of the light
 * chip) while the theme identity (hues) is preserved. `accent.on-primary`
 * is auto-picked (WCAG) over the resolved accent. Catalog-only image
 * theme helper `resolveImageThemeFile` is covered too.
 */
import { describe, expect, it } from "vitest";
import { THEMES } from "../src/themes";
import { resolveImageThemeFile } from "../src/themes/image-themes";
import {
  accentInk,
  contrastRatio,
  hexLuminance,
  resolveToken,
} from "../src/themes/resolve";

/** The 10 expressive theme names (05 §5.4). */
const EXPRESSIVE_THEMES = Object.keys(THEMES) as Array<keyof typeof THEMES>;

describe("style-aware theme resolution (05 §5.4 calibration)", () => {
  it("light style keeps the base accent palette", () => {
    for (const name of EXPRESSIVE_THEMES) {
      const t = THEMES[name];
      expect(resolveToken(name, "light", "accent.primary")).toBe(t.colors.primary);
      expect(resolveToken(name, "light", "accent.surface")).toBe(t.colors.surface);
    }
  });

  it("every expressive theme ships a colorsDark variant", () => {
    for (const name of EXPRESSIVE_THEMES) {
      expect(THEMES[name].colorsDark, `theme ${name} lacks colorsDark`).toBeDefined();
    }
  });

  it("dark style resolves the recalibrated accents (not the light ones)", () => {
    for (const name of EXPRESSIVE_THEMES) {
      const t = THEMES[name];
      expect(resolveToken(name, "dark", "accent.primary")).toBe(t.colorsDark?.primary ?? t.colors.primary);
      // The dark surface is a DARK tint (lower luminance than the light chip).
      const darkSurface = t.colorsDark?.surface ?? t.colors.surface;
      // A dark-canvas variant must be a DARK tint (lightness < 0.55):
      // the light-canvas `surface` chip would be light (e.g. `#B8DFFF`
      // ≈ 0.87) — the dark variant must not be.
      const lum = hexLuminance(darkSurface);
      expect(lum, `theme ${name} colorsDark.surface too bright (${darkSurface})`).toBeLessThan(0.55);
    }
  });

  it("neutral tokens stay style-driven (theme never redefines semantics)", () => {
    expect(resolveToken("aurora", "dark", "bg")).toBe("#000000");
    expect(resolveToken("aurora", "light", "bg")).toBe("#FFFFFF");
    // success/warning/danger are theme-independent (blocking rule 05 §5.1).
    expect(resolveToken("citrus", "light", "success")).toBe(resolveToken("aurora", "light", "success"));
    expect(resolveToken("citrus", "dark", "danger")).toBe(resolveToken("aurora", "dark", "danger"));
  });

  it("dark canvas is PURE #000000 with a neutral (hue-0) gray ramp, no blue cast", () => {
    // owner 10-07: the dark neutral is the deepest black + pure grays.
    expect(resolveToken("aurora", "dark", "bg")).toBe("#000000");
    expect(resolveToken("aurora", "dark", "surface")).toBe("#121212");
    expect(resolveToken("aurora", "dark", "text-primary")).toBe("#FFFFFF");
    // A hue-0 color has R==G==B (no blue/slate tint).
    const isNeutral = (hex: string) => {
      const h = hex.replace("#", "").toUpperCase();
      const r = h.slice(0, 2), g = h.slice(2, 4), b = h.slice(4, 6);
      return r === g && g === b;
    };
    for (const key of ["bg", "bg-subtle", "surface", "surface-alt"] as const) {
      expect(isNeutral(resolveToken("aurora", "dark", key)), `dark ${key} must be hue-0`)
        .toBe(true);
    }
  });
});

describe("auto on-primary ink (WCAG)", () => {
  it("picks the higher-contrast ink over the accent background", () => {
    // Dark ink on a light-ish amber ≈ 7:1 vs light ink ≈ 1.6:1 → dark wins.
    expect(accentInk("#F0A82C", "#0F172A", "#F1F5F9")).toBe("#0F172A");
    // Light ink on a dark surface tint ≈ high vs dark ink → light wins.
    expect(accentInk("#14324F", "#F1F5F9", "#0F172A")).toBe("#F1F5F9");
  });

  it("contrastRatio is the WCAG formula (≥ the picked pair's ratio)", () => {
    const bg = "#14324F";
    const picked = accentInk(bg, "#F1F5F9", "#0F172A");
    expect(contrastRatio(bg, picked)).toBeGreaterThanOrEqual(4.5);
  });
});

describe("resolveImageThemeFile (orientation, catalog-only)", () => {
  it("picks the paysage variant on landscape when present", () => {
    expect(resolveImageThemeFile("new_york", "landscape")).toBe("new_york_paysage.png");
  });
  it("picks the portrait variant on portrait", () => {
    expect(resolveImageThemeFile("tokyo", "portrait")).toBe("tokyo_portrait.png");
  });
  it("returns undefined for an unknown slug (caller degrades, no crash)", () => {
    expect(resolveImageThemeFile("does_not_exist", "portrait")).toBeUndefined();
  });
});
