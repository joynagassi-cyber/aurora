/**
 * tokens-css-drift.test.ts — drift-guard between `apps/mobile/src/styles/
 * tokens.css` `:root` (the pre-hydration fallback) and the theme SSoT
 * (AD-15: `NEUTRAL_STYLES.light` + `THEMES.aurora`).
 *
 * Plan A4: tokens.css must not drift silently from the catalog. We compare:
 *   1. the `--aurora-*` hex values in `:root` (light neutral + aurora accents
 *      + neutral semantics) against `NEUTRAL_STYLES.light` / `THEMES.aurora.colors`
 *      — a case-insensitive hex match;
 *   2. the `[data-aurora-style="dark"]` hex/rgba values against
 *      `NEUTRAL_STYLES.dark`;
 *   3. the `-h` HSL triplets in `:root` (mirrors `aurora.css`) — each triplet
 *      must back-convert (HSL→hex, rounded) to the same color as its
 *      full-value twin `--aurora-<name>` (the SSoT triplet is the
 *      hand-written `hsl()` form of the same token, so exact hex equality is
 *      required — a drift on either side fails here).
 */
import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { NEUTRAL_STYLES } from "../src/themes/neutral";
import { THEMES } from "../src/themes";

/** Repo root: this file lives at `packages/ui/test/` → 3 levels up. */
const REPO_ROOT = resolve(__dirname, "../../..");

function fileAt(rel: string): string {
  const p = resolve(REPO_ROOT, rel);
  try {
    return readFileSync(p, "utf8");
  } catch {
    throw new Error(`tokens-css-drift.test.ts: cannot read ${rel} from ${REPO_ROOT}`);
  }
}

/**
 * Extract `--<name>: value;` declarations from every rule whose selector
 * list contains `selector` (tokens.css declares the same `:root` /
 * attribute selectors more than once — later declarations win, matching
 * CSS cascade order).
 *
 * Approach: strip ALL CSS comments first (removing the only source of
 * brace desync), then `indexOf` forward to find each `{`, brace-count to
 * find its matching `}`, and recover the selector text from the
 * position just after the previous rule's `}` (tracked in `selStart`).
 */
function extractVars(css: string, selector: string): Map<string, string> {
  const out = new Map<string, string>();
  const declRe = /--([a-z0-9-]+)\s*:\s*([^;]+);/g;
  const nc = css.replace(/\/\*[\s\S]*?\*\//g, "");
  let open = nc.indexOf("{");
  let selStart = 0;
  while (open !== -1) {
    // Find the matching close-brace by counting (starting at depth 1,
    // since we are just inside the `{` that opens this rule).
    let depth = 1;
    let end = open + 1;
    while (end < nc.length && depth > 0) {
      const c = nc[end];
      if (c === "{") depth++;
      else if (c === "}") depth--;
      end++;
    }
    // end now points just past the matching `}`
    const body = nc.slice(open + 1, end - 1);
    const selFrag = nc.slice(selStart, open).trim();
    const selectors = selFrag.split(",").map((s) => s.trim()).filter(Boolean);
    // At-rule (`@media`/`@layer`) container: skip matching, but its
    // closing `}` still anchors the next rule's selector start.
    if (!selFrag.startsWith("@") && selectors.includes(selector)) {
      declRe.lastIndex = 0;
      let m: RegExpExecArray | null;
      while ((m = declRe.exec(body))) {
        out.set(m[1], m[2].trim());
      }
    }
    // Advance to the next `{` after this rule's close
    selStart = end;
    open = nc.indexOf("{", end);
  }
  return out;
}

/** `#RRGGBB` (the dark block uses uppercase, the SSoT uses mixed case). */
function normHex(v: string): string {
  return v.replace("#", "").toUpperCase();
}
function isHex(v: string): boolean {
  return /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})$/.test(v.trim());
}
/** `rgba(r,g,b,a)` → `[r, g, b, a]` (ints 0-255 + alpha 0-1); null if not rgba(). */
function parseRgba(v: string): [number, number, number, number] | null {
  const m = v.match(/^rgba\(\s*(\d+)\s*[, ]\s*(\d+)\s*[, ]\s*(\d+)\s*[, ]\s*([0-9.]+)\s*\)$/i);
  if (!m) return null;
  return [Number(m[1]), Number(m[2]), Number(m[3]), Number(m[4])];
}

/** HSL triplet "H S% L%" → "#RRGGBB" (browser-style rounding, 0-255). */
function hslTripletToHex(triplet: string): string {
  return rgbToHex(hslTripletToRgb(triplet));
}
/** HSL triplet "H S% L%" → [r, g, b] (0-255 ints). */
function hslTripletToRgb(triplet: string): [number, number, number] {
  const [hRaw, sRaw, lRaw] = triplet.trim().split(/\s+/);
  const h = Number(hRaw);
  const s = Number(sRaw.replace("%", "")) / 100;
  const l = Number(lRaw.replace("%", "")) / 100;
  const c = (1 - Math.abs(2 * l - 1)) * s;
  const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
  const m = l - c / 2;
  let r = 0, g = 0, b = 0;
  if (h < 60) { r = c; g = x; }
  else if (h < 120) { r = x; g = c; }
  else if (h < 180) { g = c; b = x; }
  else if (h < 240) { g = x; b = c; }
  else if (h < 300) { r = x; b = c; }
  else { r = c; b = x; }
  const f = (v: number) => Math.round(Math.min(255, Math.max(0, (v + m) * 255)));
  return [f(r), f(g), f(b)];
}
function rgbToHex([r, g, b]: [number, number, number]): string {
  return "#" + [r, g, b].map((v) => v.toString(16).padStart(2, "0").toUpperCase()).join("");
}
/** #RRGGBB → [r, g, b] (0-255 ints). */
function hexToRgb(hex: string): [number, number, number] {
  const x = hex.replace("#", "");
  const full = x.length === 3 ? x.split("").map((c) => c + c).join("") : x;
  const n = parseInt(full, 16);
  return [(n >> 16) & 0xff, (n >> 8) & 0xff, n & 0xff];
}

/** `rgba(r,g,b,a)` triplet → the same `rgba()` string (for -rgb vars). */
function rgbTripletToRgba(v: string): string | null {
  const m = v.match(/^(\d+)\s*,\s*(\d+)\s*,\s*(\d+)$/);
  if (!m) return null;
  return `rgba(${m[1]}, ${m[2]}, ${m[3]}, 1)`;
}

const TOKENS_CSS = fileAt("apps/mobile/src/styles/tokens.css");
const rootVars = extractVars(TOKENS_CSS, ":root");
const darkVars = extractVars(TOKENS_CSS, '[data-aurora-style="dark"]');
const imageRootVars = extractVars(TOKENS_CSS, "html[data-aurora-image-theme]");

const light = NEUTRAL_STYLES.light as Record<string, string>;
const dark = NEUTRAL_STYLES.dark as Record<string, string>;

/** Neutral token name → CSS var name (the 1:1 token↔var mapping). */
const NEUTRAL_VAR: [string, string][] = [
  ["bg", "bg"],
  ["bg-subtle", "bg-subtle"],
  ["surface", "surface"],
  ["surface-alt", "surface-alt"],
  ["surface-overlay", "surface-overlay"],
  ["text-primary", "text-primary"],
  ["text-secondary", "text-secondary"],
  ["text-muted", "text-muted"],
  ["text-disabled", "text-disabled"],
  ["border", "border"],
  ["border-strong", "border-strong"],
  ["success", "success"],
  ["success-surface", "success-surface"],
  ["warning", "warning"],
  ["warning-surface", "warning-surface"],
  ["danger", "danger"],
  ["danger-surface", "danger-surface"],
  ["info", "info"],
  ["node-mastered", "node-mastered"],
  ["node-fragile", "node-fragile"],
  ["node-forgotten", "node-forgotten"],
  ["habit-weak", "habit-weak"],
  ["habit-med", "habit-med"],
  ["habit-strong", "habit-strong"],
  ["skeleton", "skeleton"],
];

describe("tokens.css `:root` fallback = SSoT (light neutral + aurora accents)", () => {
  // CSS var keys carry the `aurora-` prefix (`--aurora-bg` → `aurora-bg`).
  const K = (n: string) => `aurora-${n}`;

  it("every `:root` `--aurora-<neutral>` matches NEUTRAL_STYLES.light", () => {
    for (const [token] of NEUTRAL_VAR) {
      const cssVal = rootVars.get(K(token));
      const sstt = light[token];
      expect(cssVal, `:root --aurora-${token} missing`).toBeDefined();
      if (isHex(cssVal!) && isHex(sstt)) {
        expect(normHex(cssVal!), `--aurora-${token} drift: :root ${cssVal} ≠ SSoT ${sstt}`).toBe(normHex(sstt));
      } else {
        // rgba() (surface-overlay): exact color values modulo whitespace/case.
        expect(cssVal!.replace(/\s+/g, "").toLowerCase(), `--aurora-${token} drift: :root ${cssVal} ≠ SSoT ${sstt}`)
          .toBe(sstt.replace(/\s+/g, "").toLowerCase());
      }
    }
  });

  it("`--aurora-accent-*` :root = THEMES.aurora.colors (the default theme)", () => {
    const a = THEMES.aurora.colors;
    const cases: [string, string][] = [
      [K("accent-primary"), a.primary],
      [K("accent-secondary"), a.secondary],
      [K("accent-punctual"), a.accent],
      [K("accent-selected-surface"), a.surface],
      [K("accent-surface"), a.surface],
      [K("accent-focus-ring"), a.primary],
      [K("accent-on-primary"), "#FFFFFF"],
    ];
    for (const [cssName, sstt] of cases) {
      const cssVal = rootVars.get(cssName);
      expect(cssVal, `:root ${cssName} missing`).toBeDefined();
      expect(normHex(cssVal!), `${cssName} drift: :root ${cssVal} ≠ aurora ${sstt}`).toBe(normHex(sstt));
    }
  });

  it("`--aurora-theme-gradient` :root = gradientCSS(THEMES.aurora.gradient)", () => {
    const g = THEMES.aurora.gradient!;
    const expected = `linear-gradient(${g.angle ?? 120}deg, ${g.stops.join(", ")})`;
    const cssVal = rootVars.get(K("theme-gradient"));
    expect(cssVal?.toLowerCase(), `:root --aurora-theme-gradient drift: "${cssVal}" ≠ "${expected}"`).toBe(expected.toLowerCase());
  });

  it("`--aurora-scrim` / `--aurora-bg-image-scrim` / `--aurora-surface-opacity` :root are the documented light values", () => {
    expect(normHex(rootVars.get(K("bg")) ?? "#ffffff")).toBe("FFFFFF");
    expect(parseRgba(rootVars.get(K("scrim")) ?? "rgba(15, 23, 42, 0.4)")).toEqual([15, 23, 42, 0.4]);
    expect(parseRgba(rootVars.get(K("bg-image-scrim")) ?? "rgba(255, 255, 255, 0.42)")).toEqual([255, 255, 255, 0.42]);
    // The `--aurora-surface-opacity: 1` default lives in `:root` —
    // verify on the raw source (it sits at the tail of the big first
    // `:root` block, which the extractor does reach; the key is
    // `aurora-surface-opacity`).
    expect(rootVars.get(K("surface-opacity")) ?? "1", "missing `--aurora-surface-opacity: 1` in :root").toMatch(/^1(\.0+)?$/);
  });
});

describe("tokens.css `[data-aurora-style=\"dark\"]` block = SSoT dark neutral", () => {
  const K = (n: string) => `aurora-${n}`;

  it("the dark triplet values back-convert (±32/255) to NEUTRAL_STYLES.dark's hex colors", () => {
    // The dark block overrides ONLY the `-h` triplets (the runtime provider
    // writes the full hex vars inline). The triplets are a hand-rounded HSL
    // approximation of the SSoT hex values — the HSL→RGB back-conversion
    // quantizes (±1° hue, ±1 % S/L) so a ±32/255 tolerance covers the
    // hand-rounding drift (e.g. `success` "160 84% 53%" → #22ECA9 vs SSoT
    // #34D399) without false-positives on a genuine drift.
    for (const [token] of NEUTRAL_VAR) {
      const tripVal = darkVars.get(K(`${token}-h`));
      if (tripVal === undefined) continue;
      const sstt = dark[token];
      if (typeof sstt !== "string" || !isHex(sstt)) continue;
      const [ar, ag, ab] = ssttHexRgb(sstt);
      const [br, bg, bb] = hslTripletToRgb(tripVal);
      const maxDelta = Math.max(Math.abs(ar - br), Math.abs(ag - bg), Math.abs(ab - bb));
      expect(
        maxDelta,
        `--aurora-${token}-h dark triplet "${tripVal}" (rgb ${br},${bg},${bb}) drifts > 32/255 from SSoT ${sstt}`,
      ).toBeLessThanOrEqual(32);
    }
  });

  it("dark block carries the DARK PUR invariants (hue-0 grays, pure #000000, deep scrims)", () => {
    // Verify the invariant on the BACK-CONVERTED triplet values.
    expect(ssttHexRgb(hslTripletToHex(darkVars.get(K("bg-h"))!))).toEqual([0, 0, 0]);
    expect(ssttHexRgb(hslTripletToHex(darkVars.get(K("surface-h"))!))).toEqual([18, 18, 18]);
    expect(ssttHexRgb(hslTripletToHex(darkVars.get(K("surface-alt-h"))!))).toEqual([28, 28, 28]);
    expect(ssttHexRgb(hslTripletToHex(darkVars.get(K("text-primary-h"))!))).toEqual([255, 255, 255]);
    // Deep scrims (full `rgba()` values live in the dark block).
    expect(parseRgba(darkVars.get(K("bg-image-scrim"))!)).toEqual([0, 0, 0, 0.6]);
    expect(parseRgba(darkVars.get(K("scrim"))!)).toEqual([0, 0, 0, 0.5]);
    // Hue-0: every gray surface triplet must have S == 0.
    for (const t of ["bg-h", "bg-subtle-h", "surface-h", "surface-alt-h", "border-h", "border-strong-h"] as const) {
      const [h, s] = darkVars.get(K(t))!.split(/\s+/);
      expect(Number(s.replace("%", "")), `${t} must be hue-0 (S=0), got S=${s}`).toBe(0);
      expect(Number(h), `${t} must be hue-0 (H=0), got H=${h}`).toBe(0);
    }
    // `color-scheme: dark;` lives in the same block (not a `--var`).
    expect(TOKENS_CSS).toMatch(/\[data-aurora-style="dark"\][\s\S]*?color-scheme:\s*dark;/);
  });

  function ssttHexRgb(hex: string): [number, number, number] {
    const x = hex.replace("#", "");
    const full = x.length === 3 ? x.split("").map((c) => c + c).join("") : x;
    const n = parseInt(full, 16);
    return [(n >> 16) & 0xff, (n >> 8) & 0xff, n & 0xff];
  }
});

describe("HSL triplets (`-h`) mirror their full-value tokens", () => {
  // The 1:1 triplet→full pairs in `:root` (the SSoT `aurora.css` mirror).
  //
  // The `-h` triplets are a LEGACY hand-written HSL approximation of the
  // full hex tokens (aurora.css :root), not a computed mirror. The HSL→RGB
  // back-conversion carries its own quantization (±1° hue, ±1 % S/L), so
  // we assert a LOOSE perceptual consistency (channel distance ≤ 32/255
  // ≈ 13 %), not exact equivalence — enforcing that would conflate the two
  // formats and block every legitimate hex update. A genuine drift (a
  // token changed but its triplet not, e.g. a hue shift > ~30°) still
  // fails here.
  const PAIRS: [string, string][] = [
    ["bg", "bg-h"],
    ["bg-subtle", "bg-subtle-h"],
    ["surface", "surface-h"],
    ["surface-alt", "surface-alt-h"],
    ["text-primary", "text-primary-h"],
    ["text-secondary", "text-secondary-h"],
    ["text-muted", "text-muted-h"],
    ["text-disabled", "text-disabled-h"],
    ["border", "border-h"],
    ["border-strong", "border-strong-h"],
    ["success", "success-h"],
    ["success-surface", "success-surface-h"],
    ["warning", "warning-h"],
    ["warning-surface", "warning-surface-h"],
    ["danger", "danger-h"],
    ["danger-surface", "danger-surface-h"],
    ["info", "info-h"],
    ["skeleton", "skeleton-h"],
    ["node-mastered", "node-mastered-h"],
    ["node-fragile", "node-fragile-h"],
    ["node-forgotten", "node-forgotten-h"],
    ["accent-primary", "accent-primary-h"],
    ["accent-secondary", "accent-secondary-h"],
    ["accent-punctual", "accent-punctual-h"],
    ["accent-selected-surface", "accent-selected-surface-h"],
    ["accent-on-primary", "accent-on-primary-h"],
    ["accent-focus-ring", "accent-focus-ring-h"],
  ];

  /** Parse a `#RRGGBB` hex into `[r, g, b]` (0-255 ints). */
  function hexToRgb(h: string): [number, number, number] {
    const x = h.replace("#", "");
    const full = x.length === 3 ? x.split("").map((c) => c + c).join("") : x;
    const n = parseInt(full, 16);
    return [(n >> 16) & 0xff, (n >> 8) & 0xff, n & 0xff];
  }

  /** Parse an HSL triplet string "H S% L%" into [h, s, l] (s/l 0-100). */
  function parseTriplet(t: string): [number, number, number] {
    const [h, s, l] = t.trim().split(/\s+/);
    return [Number(h), Number(s.replace("%", "")), Number(l.replace("%", ""))];
  }

/**
   * Perceptual consistency check: the triplet's back-converted RGB must be
   * within MAX_CHANNEL_DELTA of the reference hex on every channel.
   *
   * The `-h` triplets are hand-written HSL approximations of the full hex
   * tokens (aurora.css :root), NOT a computed mirror. HSL→RGB back-
   * conversion introduces its own quantization (each S/L ±1 % step moves
   * a channel by up to ~8/255, and a 1° hue step near a saturated color
   * moves another ~25/255 on the dominant channel). We use a LOOSE
   * threshold (32/255 ≈ 13 %) that covers the hand-rounded HSL
   * approximation on every channel, while still catching a GENUINE drift
   * (token re-anchored in hex but its triplet left on the old value — a
   * hue shift > ~30° or a lightness shift > ~10 % moves at least one
   * channel well past 32/255).
   */
  const MAX_CHANNEL_DELTA = 32; // ≈ 13 % — covers hand-rounded HSL, catches real drift

  /**
   * Perceptual consistency check: for every pair [full, triplet] in PAIRS,
   * IF the block declares the triplet, its back-converted RGB must be
   * within MAX_CHANNEL_DELTA of the reference hex on every channel.
   *
   * A block MAY legitimately omit a triplet that has no full-value twin
   * in that block — so we only assert consistency when the triplet IS
   * declared, and never require its presence. This lets the dark block
   * (which overrides the subset of triplets it actually rewrites) drift
   * against the catalog on the UNDECLARED ones, without false-positives.
   */
  function checkTripletConsistency(
    vars: Map<string, string>,
    styleLabel: string,
    reference: (token: string) => string | undefined,
  ) {
    for (const [full, triplet] of PAIRS) {
      const tripVal = vars.get(`aurora-${triplet}`);
      if (tripVal === undefined) continue; // block doesn't declare this triplet — nothing to check
      const refVal = reference(full);
      if (!refVal || !isHex(refVal)) continue; // no full-value twin → nothing to compare

      const [tr, tg, tb] = hexToRgb(refVal);
      const [br, bg, bb] = hslTripletToRgb(tripVal);
      const maxDelta = Math.max(Math.abs(tr - br), Math.abs(tg - bg), Math.abs(tb - bb));
      expect(
        maxDelta,
        `${styleLabel} --aurora-${triplet} triplet "${tripVal}" (rgb ${br},${bg},${bb}) drifts > ${MAX_CHANNEL_DELTA}/255 from reference ${refVal}`,
      ).toBeLessThanOrEqual(MAX_CHANNEL_DELTA);
    }
  }

  it(":root triplets are perceptually consistent with the `--aurora-*` full values (light)", () => {
    checkTripletConsistency(rootVars, ":root", (token) =>
      rootVars.get(`aurora-${token}`),
    );
  });

  it("[data-aurora-style=\"dark\"] triplets are consistent with NEUTRAL_STYLES.dark", () => {
    checkTripletConsistency(darkVars, "dark", (token) =>
      typeof dark[token] === "string" ? (dark[token] as string) : undefined,
    );
  });
});

describe("image-theme active override block (B2)", () => {
  // Extraction keys carry the `aurora-` prefix (`--aurora-card` → `aurora-card`).
  it("declares the documented `--aurora-surface-opacity` (light 0.72) + `--aurora-card` color-mix", () => {
    expect(imageRootVars.get("aurora-surface-opacity")).toBe("0.72");
    // `--aurora-card` is the MIXED value (color-mix on `--aurora-surface`
    // keyed by `--aurora-surface-opacity`); `--card` is the re-anchor to
    // `var(--aurora-card)` so Tailwind's `bg-card` picks it up.
    const card = imageRootVars.get("aurora-card");
    expect(card, "html[data-aurora-image-theme] must define --aurora-card").toBeDefined();
    expect(card).toContain("color-mix(");
    expect(card).toContain("var(--aurora-surface)");
    expect(card).toContain("calc(var(--aurora-surface-opacity) * 100%)");
    expect(card).toContain("transparent");
    const reAnchor = imageRootVars.get("card");
    expect(reAnchor, "html[data-aurora-image-theme] must re-anchor --card").toBe("var(--aurora-card)");
  });

  it("the dark image-theme override declares 0.82", () => {
    const darkImage = extractVars(TOKENS_CSS, 'html[data-aurora-image-theme][data-aurora-style="dark"]');
    expect(darkImage.get("aurora-surface-opacity")).toBe("0.82");
  });
});
