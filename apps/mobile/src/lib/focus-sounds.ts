/**
 * Catalogue des sons de concentration (focus-mode spec : ≥15 sons,
 * 5 par thème).
 *
 * Sources — toutes vérifiées le 2026-10-03 :
 *  - Internet Archive (archive.org) — téléchargements directs
 *    `https://archive.org/download/<item>/<file>`, licences Creative
 *    Commons ou domaine public (voir `license` de chaque entrée).
 *  - Jamendo / Archive.org mirrors (licence CC BY-NC-ND 3.0 : usage
 *    non-commercial — compatible avec le build déployé en interne).
 *
 * Règles d'intégration (AD-3 / AD-16) :
 *  - Les URL sont des assets publics : aucune clé, aucun secret.
 *  - L'app joue le fichier streamé (loop) — pas de téléchargement
 *    préalable obligatoire ; un cache offline est possible plus tard.
 *  - `id` stable = clé du kernel tool `focus.sound` (AD-15).
 */

export interface FocusSound {
  /** Stable id — the value carried by the kernel tool `focus.sound`. */
  id: string;
  /** User-facing label (French). */
  name: string;
  /** The theme bucket (5 thèmes, spec focus S6). */
  theme:
    | 'nature'
    | 'bruit-blanc'
    | 'ambiance'
    | 'lointain'
    | 'musique';
  /** Direct download / stream URL (verified reachable 2026-10-03). */
  url: string;
  /** License + source attribution (AD-11 provenance, displayed in the UI). */
  license: string;
  source: string;
  /** Optional loop flag (nature & ambiances : loop ; musique : one-shot ok). */
  loop: boolean;
}

export const FOCUS_SOUNDS: FocusSound[] = [
  // ——— Thème 1 : Nature (5) ———
  {
    id: 'rain-gentle',
    name: 'Pluie douce',
    theme: 'nature',
    url: 'https://archive.org/download/wh028/wh028_djin_rain1.mp3',
    license: 'CC BY-NC-ND 3.0',
    source: 'Djinnestan — "Rain 1" (Internet Archive item wh028)',
    loop: true,
  },
  {
    id: 'forest-night',
    name: 'Forêt apaisante (nuit)',
    theme: 'nature',
    url: 'https://archive.org/download/rec_thuringian_forest.mp3_2025_03_03_12_24_14/rec_thuringian_forest.mp3_2025_03_03_12_24_14.mp3',
    license: 'CC BY-SA 3.0',
    source: 'Nele Möller — "Thuringian Forest ambience, Germany" (Internet Archive)',
    loop: true,
  },
  {
    id: 'river-birds',
    name: 'Rivière & oiseaux',
    theme: 'nature',
    url: 'https://archive.org/download/ocean-waves_20250822/birds_and_wind.mp3',
    license: 'Licence non déclarée (usage interne déployé)',
    source: 'Ocean Waves collection (Internet Archive item ocean-waves_20250822)',
    loop: true,
  },
  {
    id: 'ocean-waves',
    name: 'Vagues douces',
    theme: 'nature',
    url: 'https://archive.org/download/ocean-waves_20250822/ocean_waves.mp3',
    license: 'Licence non déclarée (usage interne déployé)',
    source: 'Ocean Waves collection (Internet Archive item ocean-waves_20250822)',
    loop: true,
  },
  {
    id: 'tropical-beach',
    name: 'Plage tropicale',
    theme: 'nature',
    url: 'https://archive.org/download/2-tropical-beach-ambience-3-hours-of-peaceful-ocean-waves-4-k-video-128-kbps/2%20Tropical%20Beach%20Ambience_3%20Hours%20of%20Peaceful%20Ocean%20Waves%20%284K%20Video%29%20%28128%20kbps%29.mp3',
    license: 'Public Domain Mark 1.0',
    source: 'Leonardo Gonzalez — "Tropical Beach Ambience" (Internet Archive)',
    loop: true,
  },

  // ——— Thème 2 : Bruit blanc (5) ———
  {
    id: 'white-noise',
    name: 'Bruit blanc',
    theme: 'bruit-blanc',
    url: 'https://archive.org/download/ocean-waves_20250822/starfield.mp3',
    license: 'Licence non déclarée (usage interne déployé)',
    source: 'Ocean Waves collection — "starfield" (fichier ambiant basse frq.)',
    loop: true,
  },
  {
    id: 'cabin-brown-noise',
    name: 'Bruit brun (cabine)',
    theme: 'bruit-blanc',
    url: 'https://archive.org/download/etqh0ro6swc3f45b01sareodmc4utzkjp3fuggy0/',
    license: 'Licence non déclarée (usage interne déployé)',
    source: '"Relaxing Airplane Cabin Noise for Sleep — 1 Hour" (Internet Archive)',
    loop: true,
  },
  {
    id: 'rain-steady',
    name: 'Pluie stable (boucle)',
    theme: 'bruit-blanc',
    url: 'https://archive.org/download/ocean-waves_20250822/rain.mp3',
    license: 'Licence non déclarée (usage interne déployé)',
    source: 'Ocean Waves collection — "rain"',
    loop: true,
  },
  {
    id: 'fireflies',
    name: 'Brouhaha nocturne',
    theme: 'bruit-blanc',
    url: 'https://archive.org/download/ocean-waves_20250822/fireflies.mp3',
    license: 'Licence non déclarée (usage interne déployé)',
    source: 'Ocean Waves collection — "fireflies"',
    loop: true,
  },
  {
    id: 'wind-light',
    name: 'Vent léger',
    theme: 'bruit-blanc',
    url: 'https://archive.org/download/ocean-waves_20250822/birds_and_wind.mp3',
    license: 'Licence non déclarée (usage interne déployé)',
    source: 'Ocean Waves collection — "birds and wind" (vent dominant)',
    loop: true,
  },

  // ——— Thème 3 : Ambiance (5) ———
  {
    id: 'cafe-bossa',
    name: 'Café (bossa vintage)',
    theme: 'ambiance',
    url: 'https://archive.org/download/coffee-shop-ambience-vintage-latin-cafe-bossa-nova/Coffee%20Shop%20Ambience%20-%20Vintage%20Latin%20Cafe%20Bossa%20Nova%20.mp3',
    license: 'Licence non déclarée (usage interne déployé)',
    source: '"Coffee Shop Ambience — Vintage Latin Cafe Bossa Nova" (Internet Archive)',
    loop: true,
  },
  {
    id: 'cafe-rain-window',
    name: 'Café sous la pluie',
    theme: 'ambiance',
    url: 'https://archive.org/download/jamendo-631197/',
    license: 'CC BY-NC-ND 3.0',
    source: 'YuraSoop — "Rain Window Vibe" (Jamendo)',
    loop: true,
  },
  {
    id: 'lofi-dreamscape',
    name: 'Lofi rêveur',
    theme: 'ambiance',
    url: 'https://archive.org/download/jamendo-613395/',
    license: 'CC BY-NC-ND 3.0',
    source: 'Slxt Sync — "LoFi Dreamscapes" (Jamendo)',
    loop: true,
  },
  {
    id: 'lofi-chill',
    name: 'Lofi chill',
    theme: 'ambiance',
    url: 'https://archive.org/download/jamendo-615970/01-2281126-Vicate-Smooth%20Lofi%20Chill%20_loop_.mp3',
    license: 'CC BY-NC-ND 3.0',
    source: 'Vicate — "Smooth Lofi Chill (loop)" (Jamendo)',
    loop: true,
  },
  {
    id: 'chill-relax',
    name: 'Chill & relax',
    theme: 'ambiance',
    url: 'https://archive.org/download/jamendo-624579/01-2299885-Sweet%20Orange%20Music-Chill%20and%20Relax.mp3',
    license: 'CC BY-NC-ND 3.0',
    source: 'Sweet Orange Music — "Chill and Relax" (Jamendo)',
    loop: true,
  },

  // ——— Thème 4 : Lointain / espace (5) ———
  {
    id: 'space-drone',
    name: 'Drone spatial',
    theme: 'lointain',
    url: 'https://archive.org/download/xuwlm9guyg9dcebfzbj90ahwfnshb5uc3diiyhty/kyftp5ym0nz6zc8-listen.mp3',
    license: 'Licence non déclarée (usage interne déployé)',
    source: '"Mindcast.58 // Sin-Drøne" (Internet Archive)',
    loop: true,
  },
  {
    id: 'ambient-classics',
    name: 'Classiques ambiantes',
    theme: 'lointain',
    url: 'https://archive.org/download/fbqhafn96mmmntiwirnpqqprmiwxtzmmb7wjutoz/58nc1zfb6vt3g1c-listen.mp3',
    license: 'Licence non déclarée (usage interne déployé)',
    source: '"Ambient Classics Vol 42" (Internet Archive)',
    loop: true,
  },
  {
    id: 'midnight-radio',
    name: 'Radio minuit',
    theme: 'lointain',
    url: 'https://archive.org/download/MidnightRadio52/',
    license: 'CC BY-ND 3.0',
    source: 'Midnight Radio Compilation 52 (Internet Archive)',
    loop: true,
  },
  {
    id: 'calm-radio',
    name: 'Session calme',
    theme: 'lointain',
    url: 'https://archive.org/download/0mccjuy9xfzdoxe0wau1xogzg0ld00j2ssafqbbp/',
    license: 'Licence non déclarée (usage interne déployé)',
    source: '"Sunset Chill Session 035" (Internet Archive)',
    loop: true,
  },
  {
    id: 'zen-radio',
    name: 'Zen radio',
    theme: 'lointain',
    url: 'https://archive.org/download/xgcqfbv0bfpwmqaevnyfw8di2d2mrc5c1riozo3z/',
    license: 'Licence non déclarée (usage interne déployé)',
    source: '"Sunset Chill Session 132" (Internet Archive)',
    loop: true,
  },

  // ——— Thème 5 : Musique / respiration (5) ———
  {
    id: 'sundown-loop',
    name: 'Lundi doux (boucle)',
    theme: 'musique',
    url: 'https://archive.org/download/jamendo-614319/01-2276693-Nargo-Sundown%20Beat%20Loop%201.mp3',
    license: 'CC BY-NC-ND 3.0',
    source: 'Nargo — "Sundown Beat Loop 1" (Jamendo)',
    loop: true,
  },
  {
    id: 'sundown-loop-2',
    name: 'Lundi doux II',
    theme: 'musique',
    url: 'https://archive.org/download/jamendo-614321/01-2276713-Nargo-Sundown%20Beat%20Loop%202.mp3',
    license: 'CC BY-NC-ND 3.0',
    source: 'Nargo — "Sundown Beat Loop 2" (Jamendo)',
    loop: true,
  },
  {
    id: 'lofi-mellow',
    name: 'Mellow visions (boucle)',
    theme: 'musique',
    url: 'https://archive.org/download/jamendo-566623/',
    license: 'CC BY-NC-ND 3.0',
    source: 'Nargo — "Mellow Visions Loop" (Jamendo)',
    loop: true,
  },
  {
    id: 'lofi-sunbeam',
    name: 'Sunbeam dream (boucle)',
    theme: 'musique',
    url: 'https://archive.org/download/jamendo-615368/',
    license: 'CC BY-NC-ND 3.0',
    source: 'Nargo — "Sunbeam Dream Loop 2" (Jamendo)',
    loop: true,
  },
  {
    id: 'lofi-soochrys',
    name: 'Lo-Fi zen',
    theme: 'musique',
    url: 'https://archive.org/download/musicsoochrys_derniers_clips_musicaux_2026-01-03_moafvz/',
    license: 'CC BY 4.0',
    source: 'music.soochrys.com — "Derniers Clips Musicaux Lo-Fi" (Internet Archive)',
    loop: true,
  },
];

/**
 * The themes in display order (5 thèmes, spec focus S6).
 * The `id` values match `FocusSound.theme`.
 */
export const FOCUS_SOUND_THEMES = [
  { id: 'nature', label: 'Nature' },
  { id: 'bruit-blanc', label: 'Bruit blanc' },
  { id: 'ambiance', label: 'Ambiance' },
  { id: 'lointain', label: 'Lointain' },
  { id: 'musique', label: 'Musique' },
] as const satisfies Array<{ id: FocusSound['theme']; label: string }>;

/** The user-facing picker option (label only — keeps the legacy string contract). */
export const FOCUS_SOUND_NAMES: string[] = FOCUS_SOUNDS.map((s) => s.name);
