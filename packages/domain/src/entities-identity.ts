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
   *
   * Typed shape: `DiscoveryProfile` (AD-15 additive, below). The column
   * stays jsonb in SQL — the TS type is the SSoT projection. G-D14
   * fields (`disciplines`, `region`, `professionalTarget`,
   * `budgetConstraint`) are the data-driven inputs of Discovery's
   * filtering (01 S5, discovery-gap-pipeline S5: NO hardcoded identity
   * checks in code).
   */
  discoveryProfile?: DiscoveryProfile;
  createdAt: string;
  updatedAt: string;
}

/**
 * ADDITIVE (AD-15) — no existing type is modified or re-declared.
 *
 * The typed shape of `UserContext.discoveryProfile` (ADR S13.1) — the
 * G-D14 data-driven discovery fields. Consumed by Discovery's
 * `DiscoveryFilterContext` builder (packages/discovery) so the user's
 * real disciplines / region / target drive the filter instead of an
 * empty static ctx.
 *
 * SQL persistence (01 §2.1): `user_context.discovery_profile` is jsonb
 * — the JSON keys are the camelCase field names below; absent keys are
 * simply undefined on the TS side (the filter degrades per AD-1, it
 * never breaks on a partial profile).
 *
 * Open fields: the profile may carry additional ADR S13.1 signals
 * (courses, time constraints…) — `additionalProperties` stay
 * `unknown`-typed via index signature, NOT re-declared elsewhere.
 */
export interface DiscoveryProfile {
  /** G-D14: active disciplines (e.g. ['structures', 'concrete']) */
  disciplines: string[];
  /** G-D14: region identifier (e.g. 'benin') — drives local filters */
  region?: string;
  /** G-D14: target profession (e.g. 'bureau_etudes') */
  professionalTarget?: string;
  /** G-D14: budget constraint (e.g. 'student' → free/open-source preferred) */
  budgetConstraint?: string;
  /** additional ADR S13.1 signals (courses, time constraints, …) */
  [key: string]: unknown;
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
