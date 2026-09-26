/**
 * Components 4-6 — Capability Registry + Tool Registry + Tool Resolver
 * (kernel.md S12/S14).
 *
 * The Capability Registry DISCOVERS module capabilities from the
 * Contract Packs each module declares (kernel S14: "the kernel
 * discovers, never hardcodes a growing condition list"). The Tool
 * Registry maps capabilities to typed tool functions with declared
 * read/write scopes. The Tool Resolver picks the tool for a plan step
 * given context + availability (AD-1 last paragraph: graceful
 * degradation when a provider/capability is absent).
 *
 * The registry is the RUNTIME surface of the `CapabilityRegistry`
 * domain contract (packages/domain/registries.ts) — the kernel builds
 * it from the module Contract Pack declarations.
 */
import type { AgentCapability, CapabilityRegistry as DomainCapabilityRegistry } from '@aurora/domain';
import type { AgentContext } from './types.ts';

/**
 * A capability entry in the registry (kernel S14 `AgentCapability`
 * shape — the rich form; the domain's `AgentCapability` is the
 * minimal SSoT form, the kernel extends it with scopes + platform).
 */
export interface CapabilityEntry {
  /** canonical id ("task.create", "focus.start", "calendar.schedule" …) */
  id: string;
  name: string;
  description: string;
  /** the tool function id this capability maps to */
  tool: string;
  readScopes: string[];
  writeScopes: string[];
  /** platform permissions the capability needs (e.g. DPC for focus.block) */
  permissions: string[];
  /** capability / provider ids required for this to be usable */
  dependencies: string[];
  requiresConfirmation: boolean;
  destructive: boolean;
  supportsNaturalLanguage: boolean;
  platform?: 'shared' | 'android' | 'desktop';
  /** planner must not place online-only steps into offline windows */
  offlineClass?: 'offline-capable' | 'online-required' | 'hybrid';
  /** the compensating action (kernel S13 rollback) */
  compensation?: Record<string, unknown>;
}

/**
 * `DefaultCapabilityRegistry` — builds the runtime registry from the
 * module Contract Pack declarations + the domain `CapabilityRegistry`.
 * The kernel never hardcodes the list: it DISCOVERS (kernel S14).
 */
export class DefaultCapabilityRegistry {
  private entries: CapabilityEntry[] = [];

  constructor() {
    this.seedDefaults();
  }
  /** Register a capability from a module's Contract Pack. */
  register(c: CapabilityEntry): void {
    this.entries = [...this.entries.filter((e) => e.id !== c.id), c];
  }

  /** The 8 kernel tools (Vercel AI SDK) — the canonical capability set. */
  private seedDefaults(): void {
    type Seed = Partial<CapabilityEntry> & { id: string; tool: string; description: string };
    const base: Seed[] = [
      {
        id: 'planning.daily',
        tool: 'planDay',
        description: 'Compose the day plan (time-blocking + task ordering)',
        writeScopes: ['productivity:write'],
        readScopes: ['productivity:read'],
        destructive: false,
        requiresConfirmation: false,
      },
      {
        id: 'calendar.schedule',
        tool: 'schedule',
        description: 'Schedule / reorder time blocks on the calendar',
        writeScopes: ['productivity:write'],
        readScopes: ['productivity:read'],
        destructive: false,
        requiresConfirmation: false,
      },
      {
        id: 'focus.start',
        tool: 'startFocus',
        description: 'Start a focus session (timer + optional blocklist)',
        writeScopes: ['productivity:write'],
        readScopes: ['productivity:read'],
        destructive: false,
        requiresConfirmation: true, // important action (ADR S5)
        permissions: ['POST_NOTIFICATIONS'],
      },
      {
        id: 'focus.block',
        tool: 'blockApps',
        description: 'Block apps during a focus session (DPC — android + DPC-provisioned, OQ-17)',
        writeScopes: ['productivity:write'],
        readScopes: ['productivity:read'],
        destructive: false,
        requiresConfirmation: true,
        platform: 'android',
        offlineClass: 'offline-capable',
        permissions: ['DEVICE_POLICY_CONTROLLER'],
      },
      {
        id: 'research.query',
        tool: 'research',
        description: 'Run a typed multi-source research query (ResearchProvider)',
        writeScopes: [],
        readScopes: ['discovery:read'],
        destructive: false,
        requiresConfirmation: false,
        offlineClass: 'online-required',
        dependencies: ['research-provider'],
      },
      {
        id: 'learning.qcm',
        tool: 'qcm_generate',
        description: 'Generate QCM items for a skill (artifact_gen job, AD-8)',
        writeScopes: ['learning:write'],
        readScopes: ['learning:read', 'progress:read'],
        destructive: false,
        requiresConfirmation: false,
      },
      {
        id: 'learning.mirror',
        tool: 'mirror_analyze',
        description: 'Cognitive mirror analysis of a session (agent_run job, AD-8)',
        writeScopes: ['learning:write'],
        readScopes: ['learning:read', 'knowledge:read'],
        destructive: false,
        requiresConfirmation: false,
        dependencies: ['knowledge-base'],
      },
      {
        id: 'scientific.verify',
        tool: 'scientific_verify',
        description: 'Deterministic scientific / engineering verification (job, AD-8)',
        writeScopes: [],
        readScopes: ['engineering:read'],
        destructive: false,
        requiresConfirmation: false,
        dependencies: ['scientific-engine'],
        offlineClass: 'offline-capable',
      },
    ];
    for (const b of base) {
      this.register({
        id: b.id,
        name: b.id,
        description: b.description,
        tool: b.tool,
        readScopes: b.readScopes ?? [],
        writeScopes: b.writeScopes ?? [],
        permissions: b.permissions ?? [],
        dependencies: b.dependencies ?? [],
        requiresConfirmation: b.requiresConfirmation ?? false,
        destructive: b.destructive ?? false,
        supportsNaturalLanguage: true,
        ...(b.platform ? { platform: b.platform } : {}),
        ...(b.offlineClass ? { offlineClass: b.offlineClass } : {}),
        ...(b.compensation ? { compensation: b.compensation } : {}),
      });
    }
  }

  /** The domain-shaped view (for the UI shell, registries S10). */
  toDomain(): DomainCapabilityRegistry {
    const list = (): AgentCapability[] =>
      this.entries.map((e) => ({
        id: e.id,
        title: e.name,
        tool: e.tool,
        risk: e.destructive ? 'high' : e.requiresConfirmation ? 'high' : e.writeScopes.length ? 'medium' : 'low',
        effects: e.description,
      }));
    return {
      list,
      available: list, // the per-user gate is applied by the FeatureRegistry (Identity)
      get: (id) => list().find((c) => c.id === id),
    };
  }

  /** All entries (read-only view). */
  all(): CapabilityEntry[] {
    return [...this.entries];
  }

  /** Resolve by capability id. */
  get(id: string): CapabilityEntry | undefined {
    return this.entries.find((e) => e.id === id);
  }

  /** Resolve by tool id (the 8 kernel tools). */
  byTool(tool: string): CapabilityEntry | undefined {
    return this.entries.find((e) => e.tool === tool);
  }
}

/** The Tool Resolver (component 6): given a tool id + context, return the
 * CapabilityEntry — `undefined` when unavailable (provider absent,
 * feature disabled, platform mismatch, offline window). The Planner
 * then marks the step skipped rather than failing the whole run
 * (AD-1 last paragraph: optional capabilities degrade when absent). */
export function resolveTool(
  tool: string,
  ctx: AgentContext,
  registry: Pick<DefaultCapabilityRegistry, 'byTool'>,
): CapabilityEntry | undefined {
  const entry = registry.byTool(tool);  if (!entry) return undefined;
  // Platform gate: focus.block is android-only.
  if (entry.platform && entry.platform === 'android') {
    const dpcAvailable = (ctx.permission as Record<string, unknown>)['devicePolicyAvailable'] === true;
    if (!dpcAvailable) return undefined; // degrade to restriction-only (focus spec §4)
  }
  // Offline gate: online-required tools are unavailable offline.
  if (entry.offlineClass === 'online-required' && ctx.tool.availability === 'offline') {
    return undefined;
  }
  // Dependency gate: required capability absent → unavailable.
  const available = (ctx.tool as unknown as Record<string, unknown>).available as string[] | undefined;
  if (entry.dependencies.length && available) {
    const hasAll = entry.dependencies.every((d) => available.includes(d));
    if (!hasAll) return undefined;
  }
  return entry;
}

export interface ToolResolver {
  resolve(tool: string, ctx: AgentContext, registry: Pick<DefaultCapabilityRegistry, 'byTool'>): CapabilityEntry | undefined;
}

export { classifyAction } from './permission.ts';
