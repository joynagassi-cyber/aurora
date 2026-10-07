/**
 * Feature Registry (G-M7 — docs/frontend/feature-registry.md, S8
 * FeatureModule).
 *
 * The FeatureRegistry is the SSoT of what's on/off. The module's
 * `FeatureModule` declaration (AD-13 Contract Pack, feature-registry S8)
 * seeds the registry here; the availability policy (S2 chain) composes
 * enabled + dependencies + platform capability + provider presence.
 *
 * `FeatureModule` is the Contract Pack declaration (docs/frontend/
 * feature-registry.md S8) — the module-level seed record consumed at
 * registration time (kept outside `packages/domain` so the hexagon
 * center stays dependency-free, AD-1).
 */
import type { FeatureRegistry, FeatureDescriptor } from '@aurora/domain';

/**
 * S8 FeatureModule — the module's UI surface declaration (Contract Pack,
 * AD-13). One declaration per feature module; the registry builds its
 * seed from all `FeatureModule` declarations + `user_context` overrides.
 */
export interface FeatureModule {
  id: string;
  name: string;
  /** route prefixes owned (02 S6.1 map). */
  routes: string[];
  /** tab / sub-tab / detail entries. */
  navigation: string[];
  /** agent capability ids this module exposes. */
  capabilities: string[];
  /** feature ids required (transitive, validated at activation). */
  dependencies: string[];
  /** core = true; optional = false. */
  enabledByDefault: boolean;
  /** product may hide without breaking core. */
  optional: boolean;
  /** optional providers (AD-1 degradation when absent). */
  optionalProviders?: string[];
  /** platform capability requirements (e.g. focus.block: DPC). */
  platformRequires?: string[];
}

/** Seed descriptor for a module (S8 enabledByDefault + optional). */
function moduleToDescriptor(m: FeatureModule): FeatureDescriptor {
  return {
    id: m.id,
    title: m.name,
    module: m.id,
    status: m.enabledByDefault ? 'stable' : 'beta',
    defaultEnabled: m.enabledByDefault,
    defaultVisible: m.enabledByDefault,
    requires: m.dependencies,
  };
}

/**
 * `InMemoryFeatureRegistry` — the UI-shell implementation of the
 * `FeatureRegistry` port (packages/domain S11). Backed by the module
 * declarations + a user override map (user_context seed, AD-15).
 */
export class InMemoryFeatureRegistry implements FeatureRegistry {
  private readonly descriptors: Map<string, FeatureDescriptor>;
  private readonly overrides: Map<string, Map<string, boolean>>;
  private readonly visibility: Map<string, Map<string, boolean>>;

  constructor(modules: FeatureModule[]) {
    this.descriptors = new Map(modules.map((m) => [m.id, moduleToDescriptor(m)]));
    this.overrides = new Map();
    this.visibility = new Map();
  }

  list(): FeatureDescriptor[] {
    return [...this.descriptors.values()];
  }

  enabled(featureId: string, userId?: string): boolean {
    const d = this.descriptors.get(featureId);
    if (!d) return false;
    if (userId) {
      const ovr = this.overrides.get(featureId)?.get(userId);
      if (ovr !== undefined) return ovr;
    }
    return d.defaultEnabled;
  }

  visible(featureId: string, userId?: string): boolean {
    const d = this.descriptors.get(featureId);
    if (!d) return false;
    if (userId) {
      const ovr = this.visibility.get(featureId)?.get(userId);
      if (ovr !== undefined) return ovr;
    }
    return d.defaultVisible && this.enabled(featureId, userId);
  }

  setEnabled(featureId: string, userId: string, enabled: boolean): void {
    if (!this.overrides.has(featureId)) this.overrides.set(featureId, new Map());
    this.overrides.get(featureId)!.set(userId, enabled);
  }

  get(featureId: string): FeatureDescriptor | undefined {
    return this.descriptors.get(featureId);
  }
}

/**
 * G-M7 seed (S8) — the 15 module declarations: the 7 core modules that
 * already ship a surface + the 8 target modules (calendrier, focus,
 * connaissances, découvertes, compétences, intégrations, inbox, canvas —
 * the frozen 17-page routes, 02 S6.1). Every module starts
 * `enabledByDefault: true` (the flag cuts a module OFF — it never hides
 * the app by default); the user's persisted overrides live in
 * `user_context.features` (identity scope, AD-14 first paint).
 */
export const FEATURE_MODULES: FeatureModule[] = [
  {
    id: 'home',
    name: 'Accueil',
    routes: ['/', '/home'],
    navigation: ['tab:home'],
    capabilities: [],
    dependencies: [],
    enabledByDefault: true,
    optional: false,
  },
  {
    id: 'tasks',
    name: 'Tâches',
    routes: ['/tasks'],
    navigation: ['tab:tasks'],
    capabilities: [],
    dependencies: [],
    enabledByDefault: true,
    optional: false,
  },
  {
    id: 'learn',
    name: 'Apprendre',
    routes: ['/learn'],
    navigation: ['tab:learn'],
    capabilities: [],
    dependencies: [],
    enabledByDefault: true,
    optional: false,
  },
  {
    id: 'progress',
    name: 'Progrès',
    routes: ['/progress'],
    navigation: ['tab:progress'],
    capabilities: [],
    dependencies: [],
    enabledByDefault: true,
    optional: false,
  },
  {
    id: 'agent',
    name: 'Agent',
    routes: ['/agent'],
    navigation: ['tab:agent'],
    capabilities: [],
    dependencies: [],
    enabledByDefault: true,
    optional: false,
  },
  {
    id: 'goals',
    name: 'Objectifs',
    routes: ['/goals'],
    navigation: ['detail:goals'],
    capabilities: [],
    dependencies: [],
    enabledByDefault: true,
    optional: false,
  },
  {
    id: 'projects',
    name: 'Projets',
    routes: ['/projects'],
    navigation: ['detail:projects'],
    capabilities: [],
    dependencies: [],
    enabledByDefault: true,
    optional: false,
  },
  // --- the 8 G-M7 target modules (default ON; the flag cuts, never hides) ---
  {
    id: 'calendar',
    name: 'Calendrier',
    routes: ['/calendar'],
    navigation: ['module:calendar'],
    capabilities: [],
    dependencies: [],
    enabledByDefault: true,
    optional: true,
  },
  {
    id: 'focus',
    name: 'Focus',
    routes: ['/focus'],
    navigation: ['module:focus'],
    capabilities: [],
    dependencies: [],
    enabledByDefault: true,
    optional: true,
  },
  {
    id: 'knowledge',
    name: 'Connaissances',
    routes: ['/knowledge'],
    navigation: ['module:knowledge'],
    capabilities: [],
    dependencies: [],
    enabledByDefault: true,
    optional: true,
  },
  {
    id: 'discovery',
    name: 'Découvertes',
    routes: ['/discovery'],
    navigation: ['module:discovery'],
    capabilities: [],
    dependencies: [],
    enabledByDefault: true,
    optional: true,
  },
  {
    id: 'skills',
    name: 'Compétences',
    routes: ['/skills'],
    navigation: ['module:skills'],
    capabilities: [],
    dependencies: [],
    enabledByDefault: true,
    optional: true,
  },
  {
    id: 'integrations',
    name: 'Intégrations',
    routes: ['/integrations'],
    navigation: ['module:integrations'],
    capabilities: [],
    dependencies: [],
    enabledByDefault: true,
    optional: true,
  },
  {
    id: 'inbox',
    name: 'Inbox',
    routes: ['/inbox'],
    navigation: ['module:inbox'],
    capabilities: [],
    dependencies: [],
    enabledByDefault: true,
    optional: true,
  },
  {
    id: 'canvas',
    name: 'Canvas',
    // /canvas/:id ('new' = creation mode) — gated at the family root.
    routes: ['/canvas'],
    navigation: ['module:canvas'],
    capabilities: [],
    dependencies: [],
    enabledByDefault: true,
    optional: true,
  },
];

/** id → seed default (S8 enabledByDefault). */
export const FEATURE_DEFAULTS: Record<string, boolean> = Object.fromEntries(
  FEATURE_MODULES.map((m) => [m.id, m.enabledByDefault]),
);

/**
 * The 8 module ids gated by `<FeatureGate>` (feature-registry S6: a deep
 * link into a disabled module renders the "module désactivé" state, NOT a
 * 404 / crash). The 5 primary tabs stay on always (frozen chrome, 02 §6.1)
 * — the registry gates the module surfaces, not the shell.
 */
export const GATED_FEATURES = [
  'calendar',
  'focus',
  'knowledge',
  'discovery',
  'skills',
  'integrations',
  'inbox',
  'canvas',
] as const;

export type GatedFeature = (typeof GATED_FEATURES)[number];

/**
 * Pure resolver (unit-testable, no React — node:test):
 *   URL session override > persisted user features (user_context.features)
 *   > seed default (FEATURE_DEFAULTS).
 * The URL override is séance-scoped (QA / deep links, never persisted);
 * only the Settings toggle writes `user_context` (AD-7 single-writer).
 */
export function resolveFeatureEnabled(
  featureId: string,
  userFeatures: Record<string, boolean> | null | undefined,
  urlOverride?: Record<string, boolean> | null,
): boolean {
  if (urlOverride && featureId in urlOverride) return urlOverride[featureId];
  if (userFeatures && featureId in userFeatures) return userFeatures[featureId];
  return FEATURE_DEFAULTS[featureId] ?? false;
}

/**
 * Parse the session-scoped URL overrides `?feature=a,-b` / `?features=a,b`:
 * a bare id forces the module ON; a `-id` forces it OFF. Returns
 * `undefined` when no override param is present.
 */
export function parseFeatureOverride(
  params: Record<string, string | string[] | undefined>,
): Record<string, boolean> | undefined {
  const out: Record<string, boolean> = {};
  let any = false;
  for (const key of ['feature', 'features']) {
    const raw = params[key];
    if (!raw) continue;
    const parts = Array.isArray(raw) ? raw : [raw];
    for (const part of parts) {
      for (const piece of part
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean)) {
        const off = piece.startsWith('-');
        const id = off ? piece.slice(1) : piece;
        if (!id) continue;
        out[id] = !off;
        any = true;
      }
    }
  }
  return any ? out : undefined;
}
