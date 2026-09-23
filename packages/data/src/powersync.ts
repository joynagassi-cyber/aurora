// =============================================================================
// PowerSync glue (03 S4.1 / S4.2 — the frozen mirror mapping, device side).
//
// The device store is a MIRROR of the AD-15 entities (03 S4.1: "le store
// local est un MIRROR des entites, pas une re-invention du schema").
// This module binds the vendor engine (`@powersync/client`, AD-1: vendors
// live in this adapter package) to the frozen wave-0 `powersync/schema.json`
// (relay + RLS read the module PUBLIC VIEWS under service_role; the device
// engine materializes `MIRROR_TABLES` locally).
//
// Wave-1 scope: the schema is DECLARED here (single source, consumed by the
// PowerSync engine at store init). The engine SWAP behind `LocalStore`
// (03 S8.1: relay operational) happens in the same package; until then the
// `InMemoryLocalStore` reference engine runs the invariants in tests.
//
// `crdtLists` (03 S5.3): merge lists are OR-Set jsonb on `crdt_added` /
// `crdt_removed` — the SSoT types come from `@aurora/domain` (frozen,
// 03 S5.3); the schema comment's wave-1 TODO "align sur CRDT SSoT
// packages/domain" is exactly this module (the runtime impl is
// `crdt-orset.ts`, one implementation only).
// =============================================================================

/** The frozen PowerSync schema (03 S4.2 — consumed by the relay + engine). */
export interface PowerSyncSchema {
  name: string;
  version: string;
  /** exactly one scope per module owner (03 S5.4) */
  scopes: readonly {
    name: string;
    ownerModule: string;
    type: 'custom';
    sql: string;
  }[];
  /** mirror table per scope (single module owner, 03 S4.2) */
  mirrorTables: Readonly<Record<string, string[]>>;
  /** excludedFromMirror + reasons (AD-3, 01 S4.7-8, AD-16b) */
  excludedFromMirror: Readonly<Record<string, string>>;
}

/**
 * The frozen wave-0 schema (mirrors `powersync/schema.json` — keep the two
 * in sync; a schema change is an AD-15 event). `crdtLists` is the 03 S5.3
 * OR-Set (observed-removes, lossless union) — see `crdt-orset.ts`.
 */
export const POWERSYNC_SCHEMA: PowerSyncSchema = {
  name: 'aurora-sync',
  version: '0.1.0-wave1',
  scopes: [
    { name: 'productivity', ownerModule: 'Productivity', type: 'custom', sql: 'SELECT * FROM v_productivity_scope' },
    { name: 'learning', ownerModule: 'Learning', type: 'custom', sql: 'SELECT * FROM v_learning_scope' },
    { name: 'knowledge', ownerModule: 'Knowledge', type: 'custom', sql: 'SELECT * FROM v_knowledge_scope' },
    { name: 'progress', ownerModule: 'Progress', type: 'custom', sql: 'SELECT * FROM v_progress_scope' },
    { name: 'discovery', ownerModule: 'Discovery', type: 'custom', sql: 'SELECT * FROM v_discovery_scope' },
    { name: 'artifact', ownerModule: 'Artifact', type: 'custom', sql: 'SELECT * FROM v_artifact_scope' },
    { name: 'integrations', ownerModule: 'Integrations', type: 'custom', sql: 'SELECT * FROM v_integrations_scope' },
    { name: 'identity', ownerModule: 'Identity', type: 'custom', sql: 'SELECT * FROM v_identity_scope' },
  ],
  mirrorTables: {
    productivity: [
      'tasks', 'milestones', 'projects', 'goals', 'habits', 'routines',
      'focus_sessions', 'decisions', 'calendar_events',
    ],
    knowledge: [
      'notes', 'resources', 'semantic_nodes', 'semantic_edges',
      'semantic_bridges', 'node_state', 'source_refs',
    ],
    learning: ['courses', 'subjects', 'skills', 'learning_sessions', 'reviews'],
    progress: ['skill_states', 'progress_snapshots'],
    discovery: ['discovery_items', 'gaps'],
    artifact: ['artifacts'],
    integrations: ['automations'],
    identity: ['user_context'],
  },
  excludedFromMirror: {
    expert_skills: 'AD-3 / 01 S4.7: agent memory is server-only, never synced to device',
    events: 'Event History (01 S4.8, AD-6/F-10): audit-only, NOT Event Sourcing, no local table',
    progress_evidences: '03 S4.2: consumed server-side; evidence_refs[] stay in owner entities CRDT lists',
    progress_events: 'server-only (F-10)',
    progress_trends: 'recomputed server-side (01 S4.4)',
    model_registry: 'Foundation registry, server-only (AD-16b)',
    ai_usage: 'Foundation registry, server-only (AD-16b)',
    ai_health: 'Foundation registry, server-only (AD-16b)',
  },
};

/** Every mirror table (flattened, single source for the engine + tests). */
export function allMirrorTableNames(): string[] {
  return Object.values(POWERSYNC_SCHEMA.mirrorTables).flat();
}

/** The scope that owns a mirror table (03 S4.2 / F-03 single writer). */
export function ownerScopeForTable(
  table: string,
): string | undefined {
  for (const [scope, tables] of Object.entries(POWERSYNC_SCHEMA.mirrorTables)) {
    if (tables.includes(table)) return scope;
  }
  return undefined;
}

/**
 * Whether a table is mirrorable (server-syncable) at all — `false` for
 * `excludedFromMirror` entries (AD-3/F-10: agent memory + event history
 * NEVER reach the device; 03 S4.2 "exclus".).
 */
export function isMirrorable(table: string): boolean {
  return allMirrorTableNames().includes(table);
}

/**
 * The device engine is NOT imported at module load: the vendor
 * (`@powersync/client`) is swapped in when the relay is operational
 * (03 S8.1) — until then this module only carries the frozen schema +
 * helpers so the in-memory reference engine (tests / spine) needs zero
 * dependency (AD-1: the vendor binding is the ONLY thing that stays out
 * of the reference path).
 */
export interface PowerSyncEngineOptions {
  /** the PowerSync relay URL (03 S8.1, from the platform config — never
   *  hardcoded here; AD-3: secrets stay in the env, not the package). */
  serverUrl: string;
  /** the app user's token (signed-in user; RLS-scoped, 01 S2.2). */
  token: string;
}

/**
 * The engine contract (03 S8.1 device binding). The production implementation
 * wraps `@powersync/client` (`PowerSyncClient`) with `POWERSYNC_SCHEMA` as
 * the mirror definition and `serverUrl` + `token` as the relay auth; the
 * reference implementation (`ReferencePowerSyncEngine`) runs the same
 * surface against an injected transport so the invariants are testable.
 */
export interface PowerSyncEngine {
  /** open the store + apply the mirror schema (03 S4.1 store init). */
  init(options: PowerSyncEngineOptions): Promise<void>;
  /** subscribe a scope (03 S5.4: exactly one scope per module owner). */
  addScope(scope: string): Promise<void>;
  /**
   * The current downsync cursor for a scope — the "last applied server
   * position" (03 S5.2). Exposed so a full re-sync (03 S5.5.4) can detect
   * a long outage and force a reload.
   */
  lastAppliedPosition(scope: string): number;
  /** Close the store (app kill — the offline state must survive, AD-7). */
  close(): Promise<void>;
}

/**
 * The reference (zero-vendor) engine: same surface, transport injected.
 * Used by the spine test + the 03 S7 invariant tests; it proves the schema
 * + sync logic WITHOUT a device / PowerSync runtime.
 */
export class ReferencePowerSyncEngine implements PowerSyncEngine {
  private readonly positions = new Map<string, number>();
  private open = false;

  async init(_options: PowerSyncEngineOptions): Promise<void> {
    this.open = true;
  }

  async addScope(scope: string): Promise<void> {
    if (!this.open) throw new Error('engine not initialized');
    if (!this.positions.has(scope)) this.positions.set(scope, 0);
  }

  lastAppliedPosition(scope: string): number {
    return this.positions.get(scope) ?? 0;
  }

  /** Test hook: advance a scope's downsync cursor (03 S5.2). */
  advance(scope: string, position: number): void {
    this.positions.set(scope, position);
  }

  async close(): Promise<void> {
    this.open = false;
  }
}
