/**
 * useDynamicTheme — Dynamic Theming (Dynamic Theming, 10-09).
 *
 * L'utilisateur choisit une image de fond parmi le catalogue. Ce hook
 * extrait la couleur dominante (le pixel moyen) de cette image et
 * retourne :
 *   - `accentColor` : la couleur RGB sous forme `rgb(r, g, b)` (utilisée
 *     pour le FAB, les dates actives, les points timeline, les icônes
 *     d'onglet actives) ;
 *   - `isLightBackground` : le contraste est déterminé par la FORMULE
 *     DE LUMINANCE `(0.299*R + 0.587*G + 0.114*B) / 255` (règle
 *     utilisateur) : si elle est `>= 0.5`, le fond est considéré CLAIR
 *     → le texte passe en noir (et la couche « verre » en translucide
 *     clair) ; sinon le texte passe en blanc (couche translucide sombre).
 *
 * Extraction via CANVAS NATIF (aucune lib externe, pas de
 * react-color-extractor / colorthief à installer) : l'image est chargée
 * dans un `<img>` crossOrigin (les fichiers du catalogue sont servis en
 * même origine via `/themes/…`), redessinée sur un canvas 1×1 et la
 * couleur moyenne est lue. Les valeurs sont clampées 0–255.
 *
 * Le hook expose aussi `applyTheme()` : la fonction qui injecte les
 * variables CSS (`--dynamic-accent`, `--ion-color-primary`,
 * `--text-main`, `--text-muted`, `--glass-bg`, `--glass-border`) sur
 * `document.documentElement` — le cœur du système dynamique, appelé
 * dans le composant qui consomme le hook (le `useEffect` du composant
 * calendrier, jamais ici, pour que le hook reste pur/retour de valeurs).
 */
import { useEffect, useMemo, useRef, useState } from 'react';

export interface DynamicTheme {
  /** La couleur d'accentuation extraite de l'image (ex. `rgb(30, 64, 175)`). */
  accentColor: string;
  /** `true` si le fond extrait est clair (la luminance `>= 0.5`). */
  isLightBackground: boolean;
  /** Le composant RGB brut, pour re-calculer / re-injecter. */
  rgb: { r: number; g: number; b: number } | null;
  /** `true` tant que l'image est en cours de chargement/analyse. */
  loading: boolean;
}

interface Rgb {
  r: number;
  g: number;
  b: number;
}

/**
 * La formule de luminance de l'utilisateur :
 * `(0.299*R + 0.587*G + 0.114*B) / 255` — la borne `0.5` = le seuil
 * clair/sombre (la luminance `>= 0.5` = le fond est perçu comme CLAIR,
 * le texte doit passer en noir pour rester lisible).
 */
export function luminanceOf({ r, g, b }: Rgb): number {
  return (0.299 * r + 0.587 * g + 0.114 * b) / 255;
}

/**
 * Moyenne R/G/B d'une image via canvas (1×1 pour la moyenne globale du
 * pixel : l'image est redessinée entière sur un canvas 1×1, le
 * `drawImage` fait le downsampling/moyennage natif). Cross-origin
 * (l'URL du catalogue est même origine, `/themes/…`, donc
 * `crossOrigin="anonymous"` est suffisant et le canvas reste
 * non-tainted → `getImageData` fonctionne).
 */
async function sampleAverageRgb(src: string): Promise<Rgb | null> {
  const img = new Image();
  img.crossOrigin = 'anonymous';
  img.src = src;

  await img.decode().catch(() => {
    /* decode peut rejecter sur format inconnu — on retombe sur `load`. */
  });
  await new Promise<void>((resolve) => {
    if (img.complete && img.naturalWidth > 0) {
      resolve();
      return;
    }
    img.addEventListener('load', () => resolve(), { once: true });
    img.addEventListener('error', () => resolve(), { once: true });
  });

  if (img.naturalWidth === 0 || img.naturalHeight === 0) return null;

  const canvas = document.createElement('canvas');
  canvas.width = 1;
  canvas.height = 1;
  const ctx = canvas.getContext('2d', { willReadFrequently: true });
  if (!ctx) return null;
  ctx.drawImage(img, 0, 0, 1, 1);

  try {
    const { data } = ctx.getImageData(0, 0, 1, 1);
    return {
      r: data[0] ?? 0,
      g: data[1] ?? 0,
      b: data[2] ?? 0,
    };
  } catch {
    /* Canvas tainted (cross-origin non autorisé) — on abandonne silencieusement. */
    return null;
  }
}

/**
 * Le hook : prend l'URL de l'image sélectionnée (ou `null`/`undefined`
 * quand aucune image n'est choisie → le thème retombe sur le neutral,
 * les variables ne sont PAS injectées : le composant qui consomme le
 * hook ne doit appeler `applyTheme()` que si `rgb` est défini).
 */
export function useDynamicTheme(imageUrl: string | null | undefined): DynamicTheme {
  const [rgb, setRgb] = useState<Rgb | null>(null);
  const [loading, setLoading] = useState(false);
  const cancelled = useRef(false);

  useEffect(() => {
    cancelled.current = false;
    if (!imageUrl) {
      setRgb(null);
      setLoading(false);
      return;
    }
    setLoading(true);
    let alive = true;
    sampleAverageRgb(imageUrl).then((res) => {
      if (!alive || cancelled.current) return;
      setRgb(res);
      setLoading(false);
    });
    return () => {
      alive = false;
      cancelled.current = true;
    };
  }, [imageUrl]);

  const accentColor = useMemo(
    () => (rgb ? `rgb(${rgb.r}, ${rgb.g}, ${rgb.b})` : 'transparent'),
    [rgb],
  );
  const isLightBackground = useMemo(
    () => (rgb ? luminanceOf(rgb) >= 0.5 : false),
    [rgb],
  );

  return { accentColor, isLightBackground, rgb, loading };
}

/**
 * La fonction d'injection (le cœur du système dynamique) : le composant
 * qui consomme le hook l'appelle dans son propre `useEffect` (la règle
 * « dans le composant principal, applique via useEffect +
 * `document.documentElement.style.setProperty` » de l'architecture).
 * Jamais un état React ici : ce sont des variables CSS globales, pas
 * du state.
 */
export function applyDynamicThemeVariables(theme: DynamicTheme): void {
  if (!theme.rgb) return; // Pas d'image choisie → on ne touche à rien.
  const { r, g, b } = theme.rgb;
  const root = document.documentElement;

  root.style.setProperty('--dynamic-accent', `rgb(${r}, ${g}, ${b})`);
  root.style.setProperty('--ion-color-primary', `rgb(${r}, ${g}, ${b})`);

  if (theme.isLightBackground) {
    root.style.setProperty('--text-main', '#1a1a1a');
    root.style.setProperty('--text-muted', 'rgba(0, 0, 0, 0.5)');
    root.style.setProperty('--glass-bg', 'rgba(255, 255, 255, 0.6)');
    root.style.setProperty('--glass-border', 'rgba(0, 0, 0, 0.1)');
  } else {
    root.style.setProperty('--text-main', '#ffffff');
    root.style.setProperty('--text-muted', 'rgba(255, 255, 255, 0.6)');
    root.style.setProperty('--glass-bg', 'rgba(0, 0, 0, 0.4)');
    root.style.setProperty('--glass-border', 'rgba(255, 255, 255, 0.15)');
  }
}

/**
 * Nettoie les variables (appelé au démontage du composant, quand on
 * revient sur un thème non-image) : le calendrier retourne alors sur le
 * `--ion-color-primary` / `--aurora-accent-primary` canonique, porté par
 * le reste de l'app (le hook seul ne possède PAS la variable du reste
 * de l'interface — c'est le calendrier qui l'émet pour soi-même).
 */
export function clearDynamicThemeVariables(): void {
  const root = document.documentElement;
  for (const v of [
    '--dynamic-accent',
    '--ion-color-primary',
    '--text-main',
    '--text-muted',
    '--glass-bg',
    '--glass-border',
  ]) {
    root.style.removeProperty(v);
  }
}
