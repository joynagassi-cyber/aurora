/**
 * @aurora/ui — Theme system types (AD-17, 05-design-system §5 v2).
 *
 * Architecture: 3 resolution layers (05 §5.2):
 *   Layer 1 — Neutral Style (Light `#FFFFFF` / Dark `#000000` pure): plain
 *     white / the deepest pure-black canvas (owner 10-07; hue-0 grays,
 *     no blue cast) — frozen semantic
 *     tokens §2.1.2/§2.1.3 (surfaces, text, borders, semantic states
 *     success/warning/danger/info, node states, habit streaks).
 *   Layer 2 — Expressive Theme (10 living themes §5.4 or 1 of 3 presets
 *     §5.5): accent colors, gradients, shapes, icon/selection/focus
 *     treatments, chart palette, motion mood, illustration mood.
 *   Layer 3 — Local adaptation (module/screen-scoped overrides; V1 =
 *     Focus Mode only, OQ-15). Declarative, never branched code.
 *
 * Blocking rule (05 §5.1): a theme NEVER redefines success/warning/danger/
 * info — semantic states live in the neutral layer only.
 *
 * SSoT: these JSON files are the theme catalog (AD-15 SSoT, owner =
 * Design System team). Adding a theme = adding a JSON file + one line in
 * the catalog index, no code change (05 §5.8).
 */

/** The 10 neutral-style semantic color tokens (05 §2.1.2 / §2.1.3). */
export type NeutralStyle = "light" | "dark";

/** Semantic token keys resolved by `resolveToken` (05 §5.3). */
export interface NeutralTokens {
  // Surfaces & backgrounds (style layer only)
  "bg": string;
  "bg-subtle": string;
  "surface": string;
  "surface-alt": string;
  "surface-overlay": string;
  // Text (style layer only)
  "text-primary": string;
  "text-secondary": string;
  "text-muted": string;
  "text-disabled": string;
  // Borders (style layer only)
  "border": string;
  "border-strong": string;
  // Semantic states — theme-independent (blocking rule 05 §5.1)
  "success": string;
  "success-surface": string;
  "warning": string;
  "warning-surface": string;
  "danger": string;
  "danger-surface": string;
  "info": string;
  // Node states (05 §2.1.2: 3 strong colors only)
  "node-mastered": string;
  "node-fragile": string;
  "node-forgotten": string;
  // Habit streaks (05 §2.1.2: 5 levels)
  "habit-weak": string;
  "habit-med": string;
  "habit-strong": string;
  // Skeleton
  "skeleton": string;
}

/** Accent token keys owned by the expressive theme layer (05 §5.3). */
export interface ThemeAccentTokens {
  "accent.primary": string;
  "accent.secondary": string;
  "accent.punctual": string;
  "accent.selected-surface": string;
  "accent.on-primary": string;
  "accent.focus-ring": string;
  "accent.surface": string;
}

/**
 * A full expressive theme: the 4 accent colors + the 10 dimensions of
 * 05 §5.4 (a visual universe, not a 3-color palette).
 */
export interface AuroraTheme {
  name: string;
  /** Universe / world the theme evokes (05 §5.4: "ciel à l'aube", …). */
  universe: string;
  /** Is this the default theme? (Aurora = true) */
  isDefault?: boolean;
  /** The 4 accent colors (05 §5.4.1). */
  colors: {
    primary: string;
    secondary: string;
    accent: string;
    surface: string;
  };
  /**
   * Dark-canvas variant of the 4 accent colors (05 §5.4 contrast
   * calibration, roadmap 10-07): when the neutral style is `dark`,
   * resolution picks these values per-token (falling back to `colors`
   * when a key is absent). The theme's identity (hues / universe) is NOT
   * changed — only the calibration for the pure-black `#000000` canvas
   * (owner 10-07): accents a
   * touch brighter, `surface` (the selection chip) a dark tint of the
   * theme hue instead of the light one. `accent.on-primary` ink is
   * picked automatically against the resolved accent (resolve.ts), so a
   * dark variant never fights the ink.
   */
  colorsDark?: {
    primary?: string;
    secondary?: string;
    accent?: string;
    surface?: string;
  };
  /**
   * Theme-owned gradient (05 §5.4: "propriétaire du thème") — the
   * CONSUMABLE, code-ready version: angle + hex stops (used by
   * `resolveThemeCSSVars` to emit `--aurora-theme-gradient`, the swatch
   * preview on the settings screen, and any decorative surface). This is
   * the source of truth for the CSS value; `gradients` below stays a free
   * descriptive string (documentation / mood), never parsed by code.
   */
  gradient?: {
    /** Angle in CSS degrees (default 120 when omitted). */
    angle?: number;
    /** 2+ hex stops, the theme's own palette (05 §5.4.1) — no re-invented colors. */
    stops: string[];
  };
  /** Theme-owned gradient (05 §5.4: "propriétaire du thème") — descriptive. */
  gradients: string;
  illustrationMood: string;
  iconTreatment: string;
  selectionTreatment: string;
  focusTreatment: string;
  /** Chart palette for AntV G2 (AD-10, G-M5) — coherent with the theme. */
  chartPalette: string[];
  decorativeShapes: string;
  /** Motion mood: durations / curves (AD-10, 05 §2.6: smooth, 150–250ms). */
  motionMood: string;
  /** Recommended emotional usage — suggested, never imposed (05 §5.4). */
  usageEmotionnelRecommande: string;
}

/**
 * A specialized preset (05 §5.5): a technical mode that combines with any
 * expressive theme. Not a full universe — accent-only adjustments.
 */
export interface AuroraPreset {
  name: string;
  kind: "preset";
  /** Role of the preset (05 §5.5). */
  role: string;
  colors?: Partial<AuroraTheme["colors"]>;
  /** Optional neutral-style override (Nocturne forces dark canvas). */
  styleOverride?: NeutralStyle;
  focusRingWidth?: number;
  tapTargetPx?: number;
  note?: string;
}

/** Every expressive theme name (10 living themes, 05 §5.4). */
export type ExpressiveThemeName =
  | "aurora"
  | "lagoon"
  | "boreal"
  | "sakura"
  | "vesper"
  | "solara"
  | "terra"
  | "verdant"
  | "citrus"
  | "cosmos";

/** Every preset name (05 §5.5). */
export type PresetName = "slate" | "nocturne" | "high-contrast";

/** Every theme name (10 expressive + 3 presets). */
export type ThemeName = ExpressiveThemeName | PresetName;

export const EXPRESSIVE_THEMES: readonly [
  "aurora", "lagoon", "boreal", "sakura", "vesper",
  "solara", "terra", "verdant", "citrus", "cosmos",
] = [
  "aurora", "lagoon", "boreal", "sakura", "vesper",
  "solara", "terra", "verdant", "citrus", "cosmos",
] as const;

export const PRESETS: readonly ["slate", "nocturne", "high-contrast"] = [
  "slate", "nocturne", "high-contrast",
] as const;

/** Neutral style catalog: Light (#FFFFFF) / Dark (#000000 pure) — owner 10-07. */
export type NeutralStyleCatalog = Record<NeutralStyle, NeutralTokens>;

/** The theme catalog: expressive themes + presets, keyed by name. */
export type ThemeCatalog = Record<string, AuroraTheme | AuroraPreset>;

/**
 * Public shape consumed by `DataVisualizationRenderer` (AD-10, G-M5).
 * Apps pass a ChartSpec through packages/ui — never raw G2 (05 §3.6).
 *
 * G-M5 (gap-register, figé 2026-09-26): the SSoT shape is frozen in this
 * file — owner = packages/ui (AD-15/AD-10). The `id` field is a
 * **dedicated chart identifier** (05 §3.6.9: "focusBilan", "progression",
 * "science-result", …) — the set is **closed** (a new `id` = ADR
 * additif, AD-9 analogy). `type` is one of 6 mark families (bar /
 * line / area / pie / radar / heatmap) — G2 resolves the rendering,
 * the app passes only the spec (AD-1 boundary: never raw G2 outside
 * packages/ui).
 *
 * This re-exports the contract so `packages/ui` is the only place G2 is
 * touched (AD-1); `apps/mobile` imports from `@aurora/ui`, never from
 * `@antv/g2` directly (CI boundary lint).
 */
export interface ChartSpec {
  /** Dedicated chart id (05 §3.6.9: "focusBilan", "progression", …). */
  id: string;
  /** One of: bar / line / area / pie / radar / heatmap. */
  type:
    | "bar"
    | "line"
    | "area"
    | "pie"
    | "radar"
    | "heatmap";
  /** Title rendered above the chart (`md`, 600 — 05 §2.2 hierarchy). */
  title?: string;
  /** Data series. `seriesName` groups multiple series for the legend. */
  series: {
    seriesName?: string;
    values: { label: string; value: number; unit?: string }[];
  }[];
  /** Scientific data rule (05 §2.6 rule 1): the VALUE never animates. */
  animateValues?: false;
  /** Theme palette override (AD-10 G-M5: default = active theme's chartPalette). */
  palette?: string[];
  /** Accessibility: data labels vs hover only (mobile default = hover). */
  labels?: "on" | "off";
}
