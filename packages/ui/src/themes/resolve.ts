/**
 * @aurora/ui — resolveToken (05 §5.3, §5.8 — AD-17).
 *
 * Resolution (05 §5.3):
 *   valeur = theme_accent[token] ?? style_neutre[token] ?? défaut_du_thème_par_défaut
 *
 * - Accent tokens (accent.*) come from the expressive theme layer (05 §5.4).
 *   The default theme (aurora) is the ONLY one that must cover every accent
 *   token — it is the fallback.
 * - Neutral tokens (surfaces, text, borders, semantic states) come from the
 *   neutral style (05 §2.1.2/§2.1.3). A theme NEVER redefines
 *   success/warning/danger/info (blocking rule 05 §5.1).
 * - Presets (05 §5.5) adjust accent values on top of the theme when they
 *   define `colors`; Nocturne forces the dark neutral style; High Contrast
 *   widens the focus ring.
 *
 * Components NEVER call resolveToken directly (05 §5.8) — the provider
 * (<AuroraThemeProvider>) resolves all tokens at the root and injects CSS
 * variables. resolveToken is the contract-level primitive for
 * non-React consumers (AD-10 renderers computing chart palettes, …).
 */

import { NEUTRAL_STYLES } from "./neutral";
import { PRESETS, THEMES } from "./index";
import type {
  AuroraTheme,
  ExpressiveThemeName,
  NeutralStyle,
  PresetName,
  ThemeName,
} from "./types";

/** Preset names (05 §5.5) — a ThemeName may be a preset. */
function presetNameOf(name: ThemeName): PresetName | undefined {
  return (Object.keys(PRESETS) as PresetName[]).includes(
    name as PresetName,
  )
    ? (name as PresetName)
    : undefined;
}

/** Token key space: accent.* (theme) + the neutral token names. */
export type TokenKey =
  | "accent.primary"
  | "accent.secondary"
  | "accent.punctual"
  | "accent.selected-surface"
  | "accent.on-primary"
  | "accent.focus-ring"
  | "accent.surface"
  | keyof (typeof NEUTRAL_STYLES)["light"];

// ---- WCAG contrast helpers (05 §5.4 calibration, roadmap 10-07) ----

/** sRGB relative luminance of a `#RRGGBB` hex (WCAG 2.x formula). */
export function hexLuminance(hex: string): number {
  const h = hex.replace("#", "");
  const full = h.length === 3 ? h.split("").map((c) => c + c).join("") : h;
  const n = parseInt(full, 16);
  if (Number.isNaN(n) || full.length !== 6) return 0;
  const channel = (shift: number) => {
    const v = ((n >> shift) & 0xff) / 255;
    return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
  };
  return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0);
}

/** WCAG contrast ratio (1–21) between two hex colors. */
export function contrastRatio(a: string, b: string): number {
  const la = hexLuminance(a);
  const lb = hexLuminance(b);
  const [hi, lo] = la >= lb ? [la, lb] : [lb, la];
  return (hi + 0.05) / (lo + 0.05);
}

/**
 * Pick the readable ink over an accent background (05 §5.4.1): between
 * the neutral-style ink and its opposite (dark `#0F172A` / light
 * `#F1F5F9`), return whichever maximizes the WCAG contrast. This keeps
 * both the light-palette accents AND the brighter dark-variant accents
 * readable — the JSON never hardcodes an `on-primary` per style.
 */
export function accentInk(bgHex: string, styleInk: string, oppositeInk: string): string {
  return contrastRatio(bgHex, styleInk) >= contrastRatio(bgHex, oppositeInk)
    ? styleInk
    : oppositeInk;
}

/**
 * Style-aware accent colors (05 §5.4 calibration, roadmap 10-07): the
 * dark neutral style uses the theme's `colorsDark` variant (per-token,
 * falling back to `colors`), the light style the base palette.
 */
function accentColorsFor(theme: AuroraTheme, style: NeutralStyle): AuroraTheme["colors"] {
  return style === "dark"
    ? { ...theme.colors, ...(theme.colorsDark ?? {}) }
    : theme.colors;
}

/**
 * Resolve a token value for (theme, preset?, neutral style).
 * 05 §5.3: theme layer wins on accent tokens; neutral style wins on
 * neutral tokens; the default theme (aurora) is the final fallback.
 */
export function resolveToken(
  themeName: ThemeName,
  style: NeutralStyle,
  tokenKey: TokenKey,
  presetName?: ThemeName,
): string {
  // A theme name may point at a preset (which carries only accent
  // adjustments) — in that case it acts as a preset on top of the
  // default theme, not as an expressive theme (05 §5.5).
  const themeEntry = THEMES[themeName as ExpressiveThemeName];
  let theme: AuroraTheme =
    themeEntry ?? { ...THEMES["aurora"] };
  let neutralStyle: NeutralStyle = style;

  // Preset (05 §5.5): applies ON TOP of the expressive theme, not instead
  // of it. Nocturne forces the dark neutral style; a preset with colors
  // overrides the theme's accent colors.
  const presetParam: PresetName | undefined =
    presetName !== undefined
      ? (presetName as PresetName | undefined)
      : presetNameOf(themeName);
  if (presetParam && PRESETS[presetParam]) {
    const preset = PRESETS[presetParam];
    if (preset?.styleOverride) neutralStyle = preset.styleOverride;
  }

  const neutral = NEUTRAL_STYLES[neutralStyle];

  // Accent tokens — theme layer (05 §5.3 row 1), style-calibrated
  // (colorsDark on the dark canvas, roadmap 10-07). A preset's accent
  // overrides (05 §5.5 technical modes: slate / high-contrast) apply LAST,
  // on top of the style-selected accents, so a preset wins in BOTH styles.
  const styleAccents = accentColorsFor(theme, neutralStyle);
  const presetColors = presetParam
    ? PRESETS[presetParam]?.colors
    : undefined;
  const accents =
    presetColors && Object.keys(presetColors).length > 0
      ? { ...styleAccents, ...(presetColors as Partial<typeof styleAccents>) }
      : styleAccents;
  // on-primary = the readable ink over the resolved primary accent:
  // auto-picked between the style's ink and its opposite (WCAG, 05 §5.4.1).
  const onPrimaryInk = accentInk(
    accents.primary,
    neutral["text-primary"],
    neutralStyle === "dark" ? "#0F172A" : "#F1F5F9",
  );
  const accentMap: Record<string, string | undefined> = {
    "accent.primary": accents.primary,
    "accent.secondary": accents.secondary,
    "accent.punctual": accents.accent,
    "accent.selected-surface": accents.surface,
    "accent.surface": accents.surface,
    "accent.on-primary": onPrimaryInk,
    // Focus ring = primary accent (05 §5.4.1 "Focus: ring 2px <primary>").
    "accent.focus-ring": accents.primary,
  };
  const themeValue = accentMap[tokenKey];
  if (themeValue !== undefined && tokenKey.startsWith("accent.")) {
    return themeValue;
  }

  // Neutral tokens — style layer only (05 §5.3 rows 2–3).
  const neutralValue = (neutral as unknown as Record<string, string>)[tokenKey];
  if (neutralValue !== undefined) return neutralValue;

  // Fallback: default theme (aurora) — 05 §5.3 "défaut_du_thème_par_défaut".
  const defaultAccent = accentMap[tokenKey];
  if (defaultAccent !== undefined && tokenKey.startsWith("accent.")) {
    return defaultAccent;
  }
  return (NEUTRAL_STYLES["light"] as unknown as Record<string, string>)[
    tokenKey
  ] ?? "";
}

/**
 * Resolve the full token set for a (theme, style, preset?) combination,
 * ready for CSS-variable injection. Returns a flat record:
 * `--aurora-<token>` → value.
 */
export function resolveThemeCSSVars(
  themeName: ThemeName,
  style: NeutralStyle,
  presetName?: ThemeName,
): Record<string, string> {
  const out: Record<string, string> = {};
  const keys: TokenKey[] = [
    "accent.primary",
    "accent.secondary",
    "accent.punctual",
    "accent.selected-surface",
    "accent.on-primary",
    "accent.focus-ring",
    "accent.surface",
    ...(Object.keys(NEUTRAL_STYLES["light"]) as TokenKey[]),
  ];
  for (const key of keys) {
    out[`--aurora-${key}`] = resolveToken(themeName, style, key, presetName);
  }

  // Preset geometric overrides (05 §5.5 / §5.9): focus ring width + tap
  // targets are part of the preset contract, not token colors.
  if (presetName) {
    const preset = PRESETS[presetName as PresetName];
    if (preset?.focusRingWidth) {
      out["--aurora-focus-ring-width"] = `${preset.focusRingWidth}px`;
    }
    if (preset?.tapTargetPx) {
      out["--aurora-tap-target"] = `${preset.tapTargetPx}px`;
    }
  }
  return out;
}

/**
 * Map Aurora tokens → shadcn/ui CSS variable names (05-design-system
 * overview §2: shadcn components use CSS variables which come from the
 * Aurora theme JSON). After this mapping, changing the theme = changing
 * the JSON, never the components (docs/ui-libraries.md §4).
 */
export function toShadcnVars(cssVars: Record<string, string>): Record<string, string> {
  const g = (k: string): string => cssVars[k] ?? "";
  return {
    "--background": g("--aurora-bg"),
    "--foreground": g("--aurora-text-primary"),
    "--card": g("--aurora-surface"),
    "--card-foreground": g("--aurora-text-primary"),
    "--popover": g("--aurora-surface"),
    "--popover-foreground": g("--aurora-text-primary"),
    "--primary": g("--aurora-accent-primary"),
    "--primary-foreground": g("--aurora-accent-on-primary"),
    "--secondary": g("--aurora-surface-alt"),
    "--secondary-foreground": g("--aurora-text-primary"),
    "--muted": g("--aurora-bg-subtle"),
    "--muted-foreground": g("--aurora-text-muted"),
    "--accent": g("--aurora-accent-selected-surface"),
    "--accent-foreground": g("--aurora-text-primary"),
    "--destructive": g("--aurora-danger"),
    "--destructive-foreground": g("--aurora-surface"),
    "--border": g("--aurora-border"),
    "--input": g("--aurora-border-strong"),
    "--ring": g("--aurora-accent-focus-ring"),
    "--success": g("--aurora-success"),
    "--warning": g("--aurora-warning"),
    "--info": g("--aurora-info"),
  };
}
