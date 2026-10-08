/**
 * image-theme.tsx — image-theme consumer layer (05 §5.4-annexe, 10-07).
 *
 * The catalog (packages/ui IMAGE_THEMES + resolveImageThemeFile) is data;
 * THIS is the wiring: the chosen theme (ui-state, persisted) becomes
 *   1. a full-screen BACKGROUND of the app — the image itself is the
 *      canvas (ni teinte, ni flouté, §5.4-annexe) + a style-driven
 *      readability scrim (token --aurora-bg-image-scrim) behind the
 *      content;
 *   2. an ACCENT source: the theme's « chromatic anchor » overrides the
 *      accent variables (--aurora-accent-*) ON TOP of the active color
 *      theme (AD-17: the image is a skin — the neutral canvas values and
 *      the semantic states success/warning/danger/info NEVER move).
 *
 * Unknown slugs / 'none' → every override is removed (the color theme
 * regains control, honest state, never a crash). The image file is
 * served from `apps/mobile/public/themes/` (52 files, batch 2026-10-B);
 * orientation is tracked live (landscape → `paysage` variant, fallback
 * portrait — resolveImageThemeFile, catalog-only rule).
 */
import { useEffect, useState } from 'react';
import {
  NEUTRAL_STYLES,
  accentInk,
  getImageTheme,
  resolveImageThemeFile,
} from '@aurora/ui';
import { useUiStateStore } from '../state/ui-state';

/** The CSS variables the layer owns (removed on 'none' / unmount). */
const LAYER_VARS = [
  '--aurora-bg-image',
  '--aurora-accent-primary',
  '--aurora-accent-secondary',
  '--aurora-accent-punctual',
  '--aurora-accent-focus-ring',
  '--aurora-accent-on-primary',
] as const;

export function ImageThemeLayer() {
  const imageTheme = useUiStateStore((s) => s.auroraImageTheme);
  const rawStyle = useUiStateStore((s) => s.theme);
  // A7 (main.tsx): DARK only when explicitly chosen — 'auto' = light.
  const style = rawStyle === 'dark' ? 'dark' : 'light';

  const [landscape, setLandscape] = useState(
    () =>
      typeof window !== 'undefined' &&
      window.matchMedia('(orientation: landscape)').matches,
  );
  useEffect(() => {
    const mq = window.matchMedia('(orientation: landscape)');
    const onChange = (e: MediaQueryListEvent) => setLandscape(e.matches);
    mq.addEventListener('change', onChange);
    return () => mq.removeEventListener('change', onChange);
  }, []);

  useEffect(() => {
    const doc = document.documentElement;
    const body = document.body;
    const orientation = landscape ? 'landscape' : 'portrait';
    const entry = imageTheme !== 'none' ? getImageTheme(imageTheme) : undefined;
    const file = entry ? resolveImageThemeFile(entry.slug, orientation) : undefined;

    if (!entry || !file) {
      // 'none' / unknown slug: the color theme regains full control.
      for (const v of LAYER_VARS) doc.style.removeProperty(v);
      delete doc.dataset.auroraImageTheme;
      body.style.backgroundImage = '';
      body.style.backgroundSize = '';
      body.style.backgroundAttachment = '';
      return;
    }

    const neutral = NEUTRAL_STYLES[style];
    const anchor = entry.anchorColor;
    const styleInk = neutral['text-primary'];
    // Pure palettes (owner 10-07): the opposite ink is pure black / pure white.
    const oppositeInk = style === 'dark' ? '#000000' : '#FFFFFF';

    doc.dataset.auroraImageTheme = entry.slug;
    doc.style.setProperty('--aurora-bg-image', `url("/themes/${file}")`);
    doc.style.setProperty('--aurora-accent-primary', anchor);
    doc.style.setProperty('--aurora-accent-secondary', anchor);
    doc.style.setProperty('--aurora-accent-punctual', anchor);
    doc.style.setProperty('--aurora-accent-focus-ring', anchor);
    // Readable ink over the anchor accent (WCAG auto-pick, 05 §5.4.1).
    doc.style.setProperty('--aurora-accent-on-primary', accentInk(anchor, styleInk, oppositeInk));

    // The image IS the canvas: scrim (token) + image, behind the content.
    body.style.backgroundImage =
      'linear-gradient(var(--aurora-bg-image-scrim), var(--aurora-bg-image-scrim)), var(--aurora-bg-image)';
    body.style.backgroundSize = '100% 100%, cover';
    body.style.backgroundPosition = 'center, center';
    body.style.backgroundAttachment = 'fixed, fixed';

    return () => {
      for (const v of LAYER_VARS) doc.style.removeProperty(v);
      delete doc.dataset.auroraImageTheme;
      body.style.backgroundImage = '';
      body.style.backgroundSize = '';
      body.style.backgroundAttachment = '';
    };
  }, [imageTheme, landscape, style]);

  // Headless: the layer writes CSS variables / body background only.
  return null;
}
