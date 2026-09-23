/**
 * @aurora/ui — Design System: tokens, components, AD-10 renderer
 * implementations, themes JSON SSoT (AD-17, G-M5).
 *
 * Consumes @aurora/domain types (AD-15 SSoT); vendors only where AD-1
 * allows (AD-10 engines + UI libraries per docs/ui-libraries.md).
 */

// --- Theme system (AD-17, 05 §5 v2) ---------------------------------------
export * from "./themes/types";
export { THEMES, PRESETS, THEME_CATALOG } from "./themes/index";
export { NEUTRAL_STYLES } from "./themes/neutral";
export {
  resolveToken,
  resolveThemeCSSVars,
  toShadcnVars,
} from "./themes/resolve";
export {
  AuroraThemeProvider,
  useAuroraTheme,
  useReducedMotion,
  type AuroraThemeProviderProps,
  type AuroraThemeContextValue,
} from "./theme/provider";

export {};
