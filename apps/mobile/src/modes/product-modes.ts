/**
 * Product modes — one system, six faces (feature-registry.md S7,
 * mission §55). A mode is a NAMED PROFILE over the registries
 * (features x preferences x context x theme x capabilities), NOT five
 * apps. The mode is DECLARED (03 §4.1 user_context / UserContext
 * preferences, AD-15) and APPLIED by the availability policy:
 *
 *   mode profile → emphasis/weight map over feature ids
 *     → NavigationRegistry (02 §6.1) re-orders / de-emphasizes tabs
 *     → Home AD-14 slots re-resolve their composition
 *     → agent suggest-sets follow the same profile (Context form, AD-12)
 *
 * Deactivation effect (feature-registry S6) applies on top of the
 * mode profile: a hidden feature disappears from navigation,
 * shortcuts, command palette, agent capabilities, widgets and
 * dashboards — historical data is never touched.
 *
 * All data-driven, no per-user hardcoding of behavior (mission
 * §15/§16, feature-registry S3).
 */

/** The six product modes (feature-registry S7 table, mission §55). */
export type ProductMode =
  | 'core'
  | 'study'
  | 'exam'
  | 'focus-heavy'
  | 'professional'
  | 'minimal';

export const PRODUCT_MODES: readonly ProductMode[] = [
  'core',
  'study',
  'exam',
  'focus-heavy',
  'professional',
  'minimal',
];

/** Weights over the feature registry ids (03 data-event-job-catalog). */
export type Emphasis = 'front' | 'emphasized' | 'normal' | 'minimized' | 'hidden';

export interface ModeProfile {
  mode: ProductMode;
  /** display name (FR). */
  label: string;
  /** one-line effect summary (feature-registry S7 "Effect" column). */
  effect: string;
  /** feature id -> emphasis, applied by the availability policy. */
  emphasis: Record<string, Emphasis>;
  /** notification suppression scope (focus spec §8, S2 row 2). */
  notificationScope: 'aurora_only' | 'blocklist_wide';
  /** declared context period the mode usually implies (feature-registry S3). */
  contextPeriod?: 'exam' | 'regular';
}

/** Feature ids used by the emphasis maps (registry S1 `id` values). */
const PRODUCTIVITY = 'productivity';
const TASKS = 'tasks';
const CALENDAR = 'calendar';
const LEARNING = 'learning';
const KNOWLEDGE = 'knowledge';
const PROGRESS = 'progress';
const DISCOVERY = 'discovery';
const PROJECTS = 'projects';
const GOALS = 'goals';
const FOCUS = 'focus';
const INBOX = 'inbox';
const AGENT = 'agent';
const ANALYTICS = 'advanced-analytics';
const AUDIO = 'audio-transcription';

/**
 * The six mode profiles (feature-registry S7 table, verbatim mapping).
 * "minimized" = de-emphasized (rendering + suggestion weighting, NOT
 * deletion); "hidden" = removed from the surface, data intact.
 */
export const MODE_PROFILES: Record<ProductMode, ModeProfile> = {
  core: {
    mode: 'core',
    label: 'Core',
    effect:
      'Productivity + Knowledge + Agent core; Learning/Discovery available but de-emphasized',
    emphasis: {
      [PRODUCTIVITY]: 'front',
      [KNOWLEDGE]: 'front',
      [AGENT]: 'front',
      [LEARNING]: 'minimized',
      [DISCOVERY]: 'minimized',
    },
    notificationScope: 'aurora_only',
  },
  study: {
    mode: 'study',
    label: 'Study',
    effect:
      'Learning + Progress + Focus + Calendar emphasized; Discovery/Projects minimized',
    emphasis: {
      [LEARNING]: 'emphasized',
      [PROGRESS]: 'emphasized',
      [FOCUS]: 'emphasized',
      [CALENDAR]: 'emphasized',
      [DISCOVERY]: 'minimized',
      [PROJECTS]: 'minimized',
    },
    notificationScope: 'aurora_only',
    contextPeriod: 'regular',
  },
  exam: {
    mode: 'exam',
    label: 'Exam period',
    effect:
      'Learning/Progress/Focus/Calendar front; Discovery/Projects/Analytics minimized',
    emphasis: {
      [LEARNING]: 'front',
      [PROGRESS]: 'front',
      [FOCUS]: 'front',
      [CALENDAR]: 'front',
      [DISCOVERY]: 'minimized',
      [PROJECTS]: 'minimized',
      [ANALYTICS]: 'minimized',
    },
    notificationScope: 'aurora_only',
    contextPeriod: 'exam',
  },
  'focus-heavy': {
    mode: 'focus-heavy',
    label: 'Focus-heavy',
    effect:
      'Focus cadence up, notification suppression scope widened (focus spec §8), Home slots re-weighted',
    emphasis: {
      [FOCUS]: 'front',
      [TASKS]: 'emphasized',
      [DISCOVERY]: 'minimized',
    },
    notificationScope: 'blocklist_wide',
  },
  professional: {
    mode: 'professional',
    label: 'Professional',
    effect:
      'Goals/Projects/Progress front; exam features de-emphasized',
    emphasis: {
      [GOALS]: 'front',
      [PROJECTS]: 'front',
      [PROGRESS]: 'front',
      [LEARNING]: 'minimized',
    },
    notificationScope: 'aurora_only',
    contextPeriod: 'regular',
  },
  minimal: {
    mode: 'minimal',
    label: 'Minimal',
    effect:
      'Inbox + Tasks + Calendar only; everything else hidden-but-preserved',
    emphasis: {
      [INBOX]: 'front',
      [TASKS]: 'front',
      [CALENDAR]: 'front',
      [PRODUCTIVITY]: 'hidden',
      [LEARNING]: 'hidden',
      [KNOWLEDGE]: 'hidden',
      [PROGRESS]: 'hidden',
      [DISCOVERY]: 'hidden',
      [PROJECTS]: 'hidden',
      [GOALS]: 'hidden',
      [FOCUS]: 'hidden',
      [AGENT]: 'hidden',
      [ANALYTICS]: 'hidden',
      [AUDIO]: 'hidden',
    },
    notificationScope: 'aurora_only',
  },
};

export function getModeProfile(mode: ProductMode): ModeProfile {
  return MODE_PROFILES[mode];
}

/**
 * Compose the effective emphasis for a feature under a mode, honouring
 * the user's registry overrides (feature-registry S1 `featureState`,
 * S6 deactivation effect): an explicitly disabled/hidden feature by the
 * user ALWAYS wins over the mode emphasis (data intact, surface off).
 *
 * @param mode the active product mode
 * @param featureState the user_context seed (FeatureSeedState, AD-15)
 * @param featureId the registry feature id
 * @returns the effective emphasis (default 'normal')
 */
export function effectiveEmphasis(
  mode: ProductMode,
  featureState: { enabled: Record<string, boolean>; visible: Record<string, boolean> } | undefined,
  featureId: string,
): Emphasis {
  // User override wins: explicitly off/hidden = hidden-but-preserved (S6).
  if (featureState) {
    if (featureState.enabled[featureId] === false) return 'hidden';
    if (featureState.visible[featureId] === false) return 'hidden';
  }
  return MODE_PROFILES[mode].emphasis[featureId] ?? 'normal';
}
