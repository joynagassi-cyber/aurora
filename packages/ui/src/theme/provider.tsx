/**
 * @aurora/ui — AuroraThemeProvider (AD-17, 05 §5.8).
 *
 * The provider resolves the full token set for (theme, preset?, neutral
 * style) and injects the values as CSS variables on the root element
 * (`<html data-aurora-theme=… data-aurora-style=…>`). Components read the
 * CSS variables — changing the theme = changing the JSON, never the
 * components (docs/ui-libraries.md §4).
 *
 * 05 §2.1 rule (non-surprise): the theme is PERSISTED by the app (UI
 * store, persist middleware); this provider only applies it. Never a
 * silent theme change on foreground return — the switch is decided
 * upstream, the provider is stateless.
 *
 * Usage:
 *   <AuroraThemeProvider theme="vesper" style="dark">
 *     <App />
 *   </AuroraThemeProvider>
 *
 *   // or with a preset combined on top (05 §5.5):
 *   <AuroraThemeProvider theme="cosmos" style="dark" preset="high-contrast">
 */

import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";

import {
  PRESETS,
  THEMES,
} from "../themes";
import type {
  ExpressiveThemeName,
  PresetName,
} from "../themes/types";
import {
  resolveThemeCSSVars,
  toShadcnVars,
} from "../themes/resolve";
import type {
  NeutralStyle,
  ThemeName,
} from "../themes/types";

export interface AuroraThemeContextValue {
  /** Active expressive theme name. */
  theme: ThemeName;
  /** Optional preset applied on top (05 §5.5). */
  preset?: ThemeName;
  /** Active neutral style. */
  style: NeutralStyle;
  /** Resolved CSS variables (`--aurora-*` + shadcn aliases). */
  cssVars: Record<string, string>;
  /**
   * Resolve a single token at runtime (05 §5.3) — for non-React
   * consumers (AD-10 renderers, e.g. chart palette).
   */
  resolveToken: (tokenKey: string) => string;
}

const AuroraThemeContext = createContext<AuroraThemeContextValue | null>(null);

export interface AuroraThemeProviderProps {
  theme?: ThemeName;
  preset?: ThemeName;
  style?: NeutralStyle;
  /**
   * Target element for the CSS variables. Defaults to document.documentElement
   * (React web/Capacitor webview). Pass a ref for test isolations.
   */
  target?: HTMLElement | null;
  children: ReactNode;
}

export function AuroraThemeProvider({
  theme = "aurora",
  preset,
  style = "light",
  target,
  children,
}: AuroraThemeProviderProps) {
  const value = useMemo(() => {
    const cssVars = resolveThemeCSSVars(theme, style, preset);
    const flat = { ...cssVars, ...toShadcnVars(cssVars) };
    return {
      theme,
      preset,
      style,
      cssVars: flat,
      resolveToken: (tokenKey: string) => flat[`--aurora-${tokenKey}`] ?? "",
    };
  }, [theme, preset, style]);

  useEffect(() => {
    const el = target ?? document.documentElement;
    if (!el) return;
    el.setAttribute("data-aurora-theme", theme);
    el.setAttribute("data-aurora-style", style);
    const isDefault = Boolean(
      (THEMES[theme as ExpressiveThemeName] ??
        PRESETS[theme as PresetName])?.isDefault,
    );
    el.setAttribute("data-aurora-default", isDefault ? "true" : "false");
    for (const [k, v] of Object.entries(value.cssVars)) {
      el.style.setProperty(k, v);
    }
    return () => {
      for (const k of Object.keys(value.cssVars)) {
        el.style.removeProperty(k);
      }
    };
  }, [value, target, theme, style]);

  return (
    <AuroraThemeContext.Provider value={value}>
      {children}
    </AuroraThemeContext.Provider>
  );
}

export function useAuroraTheme(): AuroraThemeContextValue {
  const ctx = useContext(AuroraThemeContext);
  if (!ctx) {
    throw new Error(
      "useAuroraTheme must be used inside <AuroraThemeProvider>.",
    );
  }
  return ctx;
}

/**
 * Reduced-motion hook (05 §2.6 rule 2, AD-13 DoD): every slow/normal
 * animation → instant when prefers-reduced-motion: reduce.
 */
export function useReducedMotion(): boolean {
  const [reduced, setReduced] = useState<boolean>(
    () =>
      typeof window !== "undefined" &&
      window.matchMedia("(prefers-reduced-motion: reduce)").matches,
  );
  useEffect(() => {
    if (typeof window === "undefined") return;
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    const onChange = (e: MediaQueryListEvent) => setReduced(e.matches);
    mq.addEventListener("change", onChange);
    return () => mq.removeEventListener("change", onChange);
  }, []);
  return reduced;
}
