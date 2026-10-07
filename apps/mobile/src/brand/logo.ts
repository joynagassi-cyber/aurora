/**
 * Brand assets — SSoT = the 4 official files at the repo root `assets/`
 * (docs/ui-libraries.md §9, "Brand Assets"). Every in-app logo usage
 * imports from this module, never a hardcoded string / custom SVG.
 *
 * The 4 official files + their permitted roles (§9):
 *  - `aurora_icon_a_integre_dans_l'applciation.png` — logo SANS fond
 *    (papillon coloré transparent) : **in-app default** — header/top bar,
 *    page center (empty states, onboarding, in-app splash), footer.
 *  - `aurora_logo_icon_d'affichage_l'applicaiton.png` — full logo with
 *    background : **external app icon ONLY** (Capacitor, Play Store,
 *    splash/install screens) — NEVER inside the app UI (§9 l.352–353).
 *  - `lg_aurora_vs_monochrome.png` — raster fallback / document exports.
 *  - `vs_monochrome_en_svg.svg` — monochrome variant (forbidden in living
 *    empty states, §9.1 l.391).
 *
 * Forbidden everywhere (§9 l.367–392): recolor, redraw, crop, background
 * behind the transparent version.
 */
// In-app logo (COLORED, transparent) — header, page-center empty states,
// footer. Vite bundles the asset; the repo-root `assets/` is the SSoT.
import inAppLogo from "../../../../assets/aurora_icon_a_integre_dans_l'applciation.png";

/**
 * The in-app logo URL (COLORED without-background, §9 SSoT). 20px in the
 * global app header, 64px centered on the 404, 20px in the goal-dashboard
 * header band (S9 l.352–353).
 */
export const IN_APP_LOGO: string = inAppLogo;

/** The `data-asset` marker value the SSoT rules pin (§9, build-time pin). */
export const IN_APP_LOGO_ASSET = "aurora_icon_a_integre_dans_l'applciation";
