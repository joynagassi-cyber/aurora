/**
 * OQ-15 theme adaptation (V1 = Focus Mode only, 05 §5.2 Layer 3 +
 * agent-prompts Phase 3 S1).
 *
 * Local adaptation is DECLARATIVE (05 §5.2: "Declarative, never branched
 * code"): a small override record layered on top of the active
 * expressive theme. The adapter computes the CSS variable overrides and
 * the AuroraThemeProvider applies them (`target` element, same
 * mechanism as the theme itself — changing the theme = changing the
 * JSON/record, never the components, ui-libraries §4).
 *
 * V1 scope (frozen): ONLY the Focus screen attenuates — secondary nodes
 * 40% opacity, active node + progress at full contrast
 * (goal-dashboard-ui S4 local adaptation rule, focus spec S2: the
 * DPC-suspended state is the snapshot, the theme is not). Every other
 * screen renders the plain expressive theme.
 */
import { useEffect, useMemo } from 'react';
import { useReducedMotion } from 'motion/react';
import {
  AuroraThemeProvider,
  type AuroraThemeProviderProps,
} from '@aurora/ui';

/**
 * A Layer-3 local adaptation record (05 §5.2): screen-scoped token
 * overrides. Theme-independent (the neutral states never move —
 * blocking rule 05 §5.1): only opacity/contrast weights are touched.
 */
export interface LocalThemeOverride {
  /** secondary nodes attenuated to 40% (focus spec S2) */
  'node.secondary-opacity'?: number;
  /** active node stays at full contrast */
  'node.active-contrast'?: number;
}

/** V1 focus adaptation (OQ-15: the ONLY local adaptation in V1). */
export const FOCUS_OVERRIDES: LocalThemeOverride = {
  'node.secondary-opacity': 0.4,
  'node.active-contrast': 1,
};

/** Render the override record as CSS custom properties. */
export function localOverrideCSSVars(o: LocalThemeOverride): Record<string, string> {
  return {
    '--aurora-node-secondary-opacity': String(o['node.secondary-opacity'] ?? 1),
    '--aurora-node-active-contrast': String(o['node.active-contrast'] ?? 1),
  };
}

export interface FocusThemeAdapterProps {
  /** true while a Focus session is active (ui-state.focusActive). */
  focusActive: boolean;
  /** override the auto CSS-variable application target (tests). */
  target?: HTMLElement | null;
}

/**
 * <FocusThemeAdapter> — the app-shell bridge between the ui-state
 * `focusActive` flag and the theme system. focusActive = the focus
 * adaptation record is layered on top of the active theme (CSS vars
 * written to the target element, instant, GPU); any screen outside
 * focus = plain theme. `useReducedMotion` gates the one focus-specific
 * motion cue (pulse) — the tokens themselves are static CSS vars.
 */
export function FocusThemeAdapter({
  focusActive,
  target,
  theme = 'aurora',
  preset,
  style = 'light',
  children,
}: FocusThemeAdapterProps & Omit<AuroraThemeProviderProps, 'target'>) {
  const reduced = useReducedMotion();
  const vars = useMemo(
    () => (focusActive ? localOverrideCSSVars(FOCUS_OVERRIDES) : {}),
    [focusActive],
  );

  useEffect(() => {
    const el = target ?? (typeof document !== 'undefined' ? document.documentElement : null);
    if (!el) return;
    for (const [k, v] of Object.entries(vars)) el.style.setProperty(k, v);
    el.dataset.auroraFocusMode = focusActive ? 'on' : 'off';
    el.dataset.auroraReducedMotion = reduced ? 'on' : 'off';
    return () => {
      for (const k of Object.keys(vars)) el.style.removeProperty(k);
      delete el.dataset.auroraFocusMode;
      delete el.dataset.auroraReducedMotion;
    };
  }, [vars, focusActive, reduced, target]);

  return (
    <AuroraThemeProvider theme={theme} preset={preset} style={style} target={target}>
      {children}
    </AuroraThemeProvider>
  );
}
