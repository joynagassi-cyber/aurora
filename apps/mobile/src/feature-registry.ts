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
