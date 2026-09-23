/**
 * @aurora/ui — Theme catalog index (AD-17, 05 §5.8).
 *
 * SSoT: the 10 expressive themes + 3 presets live as JSON in this
 * directory (AD-15). Adding a theme = adding a JSON file + one line
 * here — no code change (05 §5.8).
 */

import type {
  AuroraPreset,
  AuroraTheme,
  ExpressiveThemeName,
  PresetName,
  ThemeCatalog,
} from "./types";

import aurora from "./aurora.json";
import lagoon from "./lagoon.json";
import boreal from "./boreal.json";
import sakura from "./sakura.json";
import vesper from "./vesper.json";
import solara from "./solara.json";
import terra from "./terra.json";
import verdant from "./verdant.json";
import citrus from "./citrus.json";
import cosmos from "./cosmos.json";
import slate from "./slate.json";
import nocturne from "./nocturne.json";
import highContrast from "./high-contrast.json";

/** The 10 expressive themes (05 §5.4). */
export const THEMES: Record<ExpressiveThemeName, AuroraTheme> = {
  aurora: aurora as AuroraTheme,
  lagoon: lagoon as AuroraTheme,
  boreal: boreal as AuroraTheme,
  sakura: sakura as AuroraTheme,
  vesper: vesper as AuroraTheme,
  solara: solara as AuroraTheme,
  terra: terra as AuroraTheme,
  verdant: verdant as AuroraTheme,
  citrus: citrus as AuroraTheme,
  cosmos: cosmos as AuroraTheme,
};

/** The 3 specialized presets (05 §5.5). */
export const PRESETS: Record<PresetName, AuroraPreset> = {
  slate: slate as AuroraPreset,
  nocturne: nocturne as AuroraPreset,
  "high-contrast": highContrast as AuroraPreset,
};

/** Full catalog (themes + presets), keyed by name. */
export const THEME_CATALOG: ThemeCatalog = {
  ...THEMES,
  ...PRESETS,
};
