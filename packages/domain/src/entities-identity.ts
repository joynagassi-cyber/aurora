/**
 * Identity entities (AD-15 SSoT, 01 S2.1).
 *
 * `user_context` = the root table driving every module's RLS policy
 * (data-ownership-matrix S Cross-Module Write). Identity is the sole
 * writer (AD-15, 03 S4.2).
 *
 * AD-17 v2 (themes): `theme` carries the `AuroraTheme` enum (10 expressive
 * universes + 3 presets), `themeStyle` carries the light/dark axis. The
 * enum + its binary→enum migrator live HERE in `packages/domain` (AD-15
 * SSoT); Identity consumes the enum, it does not define it.
 */

/** The 10 expressive theme universes (05 S5.4) + 3 technical presets (05 S5.5). */
export type AuroraTheme =
  // 10 living themes
  | 'aurora' // default
  | 'lagoon'
  | 'boreal'
  | 'sakura'
  | 'vesper'
  | 'solara'
  | 'terra'
  | 'verdant'
  | 'citrus'
  | 'cosmos'
  // 3 presets (combine with any expressive theme)
  | 'slate'
  | 'nocturne'
  | 'high-contrast';

export interface UserContext {
  id: string;
  /** Supabase Auth user id */
  userId: string;
  /** display name / profile (01 S2.1) */
  displayName?: string;
  /** AD-17: expressive theme (enum, SSoT domain); 'aurora' is the default */
  theme: AuroraTheme;
  /** AD-17: the light/dark axis, orthogonal to the theme */
  themeStyle: 'light' | 'dark';
  /**
   * Coaching permissions (ADR S13): cadence, silence windows,
   * intervention level — controlled by the user.
   */
  coachCadence: 'off' | 'low' | 'normal' | 'high';
  quietHours?: string[];
  /**
   * Feature-registry seed (feature-registry.md S1: "seed in
   * user_context"). The FeatureDescriptor[] activation state.
   */
  featureState?: FeatureSeedState;
  /**
   * Discovery profile (ADR S13.1: domain of predilection, courses,
   * mastered/fragile/missing competencies, time constraints).
   */
  discoveryProfile?: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

/** Minimal seed of the Feature Registry persisted on the user context. */
export interface FeatureSeedState {
  /** feature id -> enabled */
  enabled: Record<string, boolean>;
  /** feature id -> visible */
  visible: Record<string, boolean>;
}

/**
 * Binary ('light'|'dark') → AuroraTheme enum migrator, consumed by
 * Identity (AD-17: "the binary→enum migrator lives in packages/domain,
 * not in a module"). Legacy rows without a theme map to 'aurora'.
 */
export interface ThemeMigrationInput {
  legacyTheme?: 'light' | 'dark' | string;
}
export interface ThemeMigrationResult {
  theme: AuroraTheme;
  themeStyle: 'light' | 'dark';
}
