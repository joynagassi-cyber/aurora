/**
 * @aurora/ui — Image-theme catalog (05 §5.4-annexe, nouvelle règle 2026-10).
 *
 * 26 thèmes d'illustration en complément des 10 thèmes couleur
 * (`themes/*.json`) — batch 2026-10-B : 19 générés/téléchargés, tous
 * complets P+L. Chaque thème image :
 *   - fournit une image de fond de l'application (portrait ou paysage,
 *     selon l'orientation de l'écran) ;
 *   - accentue sa couleur principale (« chromatic anchor », SSoT =
 *     `.stitch/prompts_v4.md`, table des couleurs phares) : le canvas
 *     reste l'image elle-même (ni teinte, ni flouté), le style neutre
 *     (clair `#FFFFFF` / dark `#121212`) reste inchangé ; la couleur
 *     anchor pilote les accents / primary.
 *
 * Batch 2026-10-B (régénération professionnelle « plus précise et
 * professionnelle », 2026-10-02) : 19 thèmes téléversés, tous complets
 * P+L (38 fichiers) — voir `.stitch/theme_index.json` (état actualisé à
 * chaque re-téléchargement). Les 7 thèmes restants de la liste de 26
 * (printemps, ete, automne, hiver, volcans, glacier, dunes) ne sont PAS
 * encore inclus, en attente de génération / téléchargement.
 *
 * Convention de nommage des fichiers (source de vérité : `.stitch/images/`) :
 *   `<slug>_<portrait|paysage>.png`  ex. `jazz_portrait.png`,
 *   `new_york_paysage.png`.
 *
 * CATALOG ONLY (data + types, no React/rendering) — the consumption
 * layer (which image to load for the current orientation + screen, and
 * how to inject the anchor color into the theme provider) is a
 * separate concern, to be wired in when image-theme support is
 * implemented (05 §5.4-annexe, TODO).
 */

export interface ImageThemeEntry {
  /** Stable slug, used verbatim in the `.stitch/images/<slug>_<orient>.png` filenames. */
  slug: string;
  /** Human-readable display name (French, matches `.stitch/prompts_v4.md` table). */
  label: string;
  /**
   * The theme's dominant « chromatic anchor » color — the color that gets
   * ACCENTED in the design system when this image theme is applied on top of
   * the current neutral style (light/dark canvas stays as-is; the image is
   * the background, the anchor drives accents/primary).
   */
  anchorColor: string;
}

/**
 * The 26 image themes (05 §5.4-annexe, SSoT = `.stitch/prompts_v4.md`
 * « TABLE DES COULEURS PHARES »). Order matches that table. Only the
 * 19 themes actually downloaded as of 2026-10-B are listed here; the
 * remaining 7 (printemps, ete, automne, hiver, volcans, glacier,
 * dunes) will be appended here as soon as their files are
 * (re)generated / downloaded.
 */
export const IMAGE_THEMES: readonly ImageThemeEntry[] = [
  { slug: "new_york", label: "New York", anchorColor: "#2563EB" },
  { slug: "tokyo", label: "Tokyo", anchorColor: "#E23B45" },
  { slug: "paris", label: "Paris", anchorColor: "#3D6FD8" },
  { slug: "londres", label: "Londres", anchorColor: "#12A878" },
  { slug: "dubai", label: "Dubaï", anchorColor: "#19A7A8" },
  { slug: "sydney", label: "Sydney", anchorColor: "#00A9C7" },
  { slug: "noel", label: "Noël", anchorColor: "#C92F50" },
  { slug: "paques", label: "Pâques", anchorColor: "#D987B5" },
  { slug: "nouvel_an", label: "Nouvel An", anchorColor: "#704CFF" },
  { slug: "fete", label: "Fête", anchorColor: "#F23DAA" },
  { slug: "paix", label: "Paix", anchorColor: "#78B29A" },
  { slug: "impressionnisme", label: "Impressionnisme", anchorColor: "#62B59F" },
  { slug: "jazz", label: "Jazz", anchorColor: "#7657D9" },
  { slug: "street_art", label: "Street Art", anchorColor: "#E83D7C" },
  { slug: "ballet", label: "Ballet", anchorColor: "#B69ADF" },
  { slug: "sculpture", label: "Sculpture", anchorColor: "#4E8BCE" },
  { slug: "jungle", label: "Jungle", anchorColor: "#22B36F" },
  { slug: "ponts", label: "Ponts", anchorColor: "#D8444B" },
  { slug: "afrique", label: "Afrique", anchorColor: "#C96F4A" },
] as const;

export type ImageThemeSlug = (typeof IMAGE_THEMES)[number]["slug"];

export interface ImageThemeOrientation {
  /** Portrait variant file (`.stitch/images/<slug>_portrait.png`). */
  portrait?: string;
  /** Paysage variant file (`.stitch/images/<slug>_paysage.png`). */
  paysage?: string;
}

/**
 * Which orientation files actually exist for each theme, as of the
 * 2026-10-B download batch (38 files, all 19 listed themes complete
 * P+L — see `.stitch/theme_index.json` for the exact list, re-generated
 * whenever images are (re)downloaded).
 */
export const IMAGE_THEME_FILES: Record<ImageThemeSlug, ImageThemeOrientation> = {
  new_york: { portrait: "new_york_portrait.png", paysage: "new_york_paysage.png" },
  tokyo: { portrait: "tokyo_portrait.png", paysage: "tokyo_paysage.png" },
  paris: { portrait: "paris_portrait.png", paysage: "paris_paysage.png" },
  londres: { portrait: "londres_portrait.png", paysage: "londres_paysage.png" },
  dubai: { portrait: "dubai_portrait.png", paysage: "dubai_paysage.png" },
  sydney: { portrait: "sydney_portrait.png", paysage: "sydney_paysage.png" },
  noel: { portrait: "noel_portrait.png", paysage: "noel_paysage.png" },
  paques: { portrait: "paques_portrait.png", paysage: "paques_paysage.png" },
  nouvel_an: { portrait: "nouvel_an_portrait.png", paysage: "nouvel_an_paysage.png" },
  fete: { portrait: "fete_portrait.png", paysage: "fete_paysage.png" },
  paix: { portrait: "paix_portrait.png", paysage: "paix_paysage.png" },
  impressionnisme: { portrait: "impressionnisme_portrait.png", paysage: "impressionnisme_paysage.png" },
  jazz: { portrait: "jazz_portrait.png", paysage: "jazz_paysage.png" },
  street_art: { portrait: "street_art_portrait.png", paysage: "street_art_paysage.png" },
  ballet: { portrait: "ballet_portrait.png", paysage: "ballet_paysage.png" },
  sculpture: { portrait: "sculpture_portrait.png", paysage: "sculpture_paysage.png" },
  jungle: { portrait: "jungle_portrait.png", paysage: "jungle_paysage.png" },
  ponts: { portrait: "ponts_portrait.png", paysage: "ponts_paysage.png" },
  afrique: { portrait: "afrique_portrait.png", paysage: "afrique_paysage.png" },
};

/** Look up an image theme by slug (returns `undefined` for unknown slugs). */
export function getImageTheme(slug: string): ImageThemeEntry | undefined {
  return IMAGE_THEMES.find((t) => t.slug === slug);
}
