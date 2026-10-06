// =============================================================================
// powersync-client.ts — the real `@powersync/capacitor` engine binding
// (03 S8.1 "relay operational" — the engine SWAP behind `LocalStore`).
//
// Production path: `PowerSyncClientEngine` wraps `PowerSyncDatabase`
// (`@powersync/capacitor` → Capacitor WebView SQLite, the Android-only
// Phase 1 target) with `AuroraPowerSyncSchema` (frozen mirror mapping, 03
// S4.2) and the `SupabaseBackendConnector` (relay + RLS, 01 S2.2).
//
// The reference `ReferencePowerSyncEngine` (powersync.ts) keeps running the
// invariants in tests / spine under Node type-stripping — zero vendor
// import on that path (AD-1: the vendor binding is the ONLY thing that
// stays out of the reference path).
//
// Vendor types (`PowerSyncBackendConnector`, `PowerSyncCredentials`,
// `AbstractPowerSyncDatabase`) are TypeScript-only in `@powersync/common`
// — always `import type` (a value import would resolve to `undefined` at
// runtime and bundlers error on it).
// =============================================================================

import { PowerSyncDatabase } from '@powersync/capacitor';
// `PowerSyncBackendConnector` is a TypeScript-only interface: the compiled
// `.js` in `@powersync/common` is `export {};` (no runtime binding), so a
// VALUE import fails ESM instantiation. The engine only names it as a type
// (the `connector` field / `buildConnector` param) → `import type`.
import type { PowerSyncBackendConnector, PowerSyncCredentials, SyncStatus } from '@powersync/common';
import { AuroraPowerSyncSchema } from './powersync-schema';
import { SupabaseBackendConnectorImpl } from './supabase-connector';

/**
 * The engine options for the production PowerSync client (03 S8.1):
 * - `endpoint` : `POWERSYNC_URL` (env, AD-3 — never hardcoded here).
 * - `createClient` : a lazily resolved Supabase client for the SIGNED-IN
 *   user (the connector calls `auth.getSession()` for `fetchCredentials`).
 *   The `SupabaseClient` type is named via the **public** `AuroraSupabaseClient`
 *   alias so consumers outside this package never import the vendor
 *   directly (AD-1: the SDK stays in this adapter).
 */
export type AuroraSupabaseClient = import('@supabase/supabase-js').SupabaseClient;

export interface PowerSyncClientEngineOptions {
  endpoint: string;
  createClient: () => AuroraSupabaseClient;
  /** The app's database filename (device-scoped storage, AD-7 offline). */
  dbFilename?: string;
}

/**
 * The production `PowerSyncEngine` — same surface as
 * `ReferencePowerSyncEngine` (powersync.ts) backed by the real relay.
 *
 * Lifecycle (03 S5.5.6): one engine per signed-in user. On logout / user
 * switch: `close()` (→ `disconnectAndClear()` — local data wiped) then a
 * fresh engine; offline state persists via the SQLite file (AD-7).
 */
export class PowerSyncClientEngine {
  private readonly opts: PowerSyncClientEngineOptions;
  private db: PowerSyncDatabase | null = null;
  private connector: PowerSyncBackendConnector | null = null;

  constructor(opts: PowerSyncClientEngineOptions) {
    this.opts = opts;
  }

  /** Open the store + apply the frozen mirror schema (03 S4.1 store init). */
  async init(_options?: { serverUrl?: string; token?: string }): Promise<void> {
    // The relay URL / token travel through the connector (fetchCredentials),
    // not through the engine options — kept for the shared `PowerSyncEngine`
    // surface (powersync.ts); `options.token` is unused when a Supabase
    // session is the credential source.
    this.db = new PowerSyncDatabase({
      schema: AuroraPowerSyncSchema,
      database: { dbFilename: this.opts.dbFilename ?? 'aurora.db' },
    });
    // The connector is built LAZILY (see `addScope`), not here:
    // `buildConnector()` calls the Supabase client factory, which throws
    // when no publishable-key env value is present (AD-3 / OQ-03 — the
    // publishable-scope shell must still boot without a live Supabase
    // session, AD-7 local-first). `addScope()` builds it on first sync
    // attempt and degrades cleanly (local mirror only) when it cannot.
    this.connector = null;
  }

  /**
   * Start the sync stream + upload loop (fire-and-forget — the SDK doc:
   * `connect()` does NOT resolve when data is ready). `auto_subscribe`
   * streams in `sync-config.yaml` mean no manual `addScope` is needed at
   * the relay; we keep the method as a documented no-op hook for the
   * shared engine surface.
   */
  async addScope(_scope: string): Promise<void> {
    if (!this.db) throw new Error('engine not initialized');
    // Sync Streams (edition 3) are auto-subscribed per user — nothing to
    // do at the relay. Build the connector here (first real sync attempt,
    // NOT at `init()`, so an unauthenticated shell still boots — AD-7):
    // if it throws (no Supabase session yet), catch and fall through to a
    // local-only mirror, never blocking the app shell paint.
    if (!this.connector) {
      try {
        this.connector = this.buildConnector();
      } catch {
        this.connector = null;
      }
    }
    if (this.connector) {
      void this.db.connect(this.connector);
      await this.db.waitForFirstSync();
    }
  }

  /**
   * The current downsync cursor (03 S5.2) — the last synced checkpoint
   * timestamp per scope. Exposed so a full re-sync (03 S5.5.4) can detect
   * a long outage and force a reload.
   */
  lastAppliedPosition(scope: string): number {
    if (!this.db) return 0;
    const status = this.db.currentStatus;
    // `statusForPriority`/stream statuses carry `lastSyncedAt` (ms epoch);
    // the reference engine's monotonically-increasing "position" is approx-
    // imated by the epoch ms of the last successful sync for that stream.
    const entry = status.statusForPriority(
      this.priorityForScope(scope),
    );
    return entry?.lastSyncedAt
      ? new Date(entry.lastSyncedAt).getTime()
      : 0;
  }

  /**
   * One-shot local read (03 S3.1) — used by the round-trip test.
   */
  async getAll<T = Record<string, unknown>>(
    sql: string,
    parameters: unknown[] = [],
  ): Promise<T[]> {
    if (!this.db) throw new Error('engine not initialized');
    return this.db.getAll<T>(sql, parameters);
  }

  /** Local write (03 S5.1.1 immediate apply — offline first, AD-7). */
  async execute(sql: string, parameters: unknown[] = []): Promise<void> {
    if (!this.db) throw new Error('engine not initialized');
    await this.db.execute(sql, parameters);
  }

  /**
   * Watch a query reactively (03 S3.1 `watch`) — returns an unsubscribe
   * handle. The React binding (`@powersync/react` hooks) layers on top in
   * the app; this is the imperative surface for `LocalQueryRepository`.
   */
  watch(sql: string, onData: (rows: Record<string, unknown>[]) => void): () => void {
    if (!this.db) throw new Error('engine not initialized');
    // `db.watch` (SQL watch, `watchWithCallback` surface): source-table
    // detection + re-execute on change; `onResult` receives the row array.
    const rows = (this.db as unknown as {
      watch(
        sql: string,
        parameters?: unknown[],
        handler?: {
          onResult?: (results: unknown) => void;
          onError?: (error: Error) => void;
        },
      ): unknown;
    }).watch(sql, undefined, {
      onResult: (results: unknown) => onData(results as Record<string, unknown>[]),
      onError: (error: Error) => {
        console.error('[aurora:powersync] watch error', error);
      },
    });
    return () => {
      const maybe = rows as unknown as { dispose?: () => void } | undefined;
      if (maybe && typeof maybe.dispose === 'function') maybe.dispose();
    };
  }

  /**
   * Close the store (app kill — offline state survives in SQLite, AD-7).
   * User switch / logout: `disconnectAndClear()` wipes local rows first
   * (03 S5.5.6), so a new user never sees another user's cache.
   */
  async close(clear = false): Promise<void> {
    if (!this.db) return;
    if (clear) await this.db.disconnectAndClear();
    else await this.db.disconnect();
    this.db = null;
    this.connector = null;
  }

  /** The live `SyncStatus` (03 S3.2 sync-state banner — `uploadError`/`downloadError`). */
  currentStatus() {
    if (!this.db) {
      return { connected: false, connecting: false, isSyncing: false, hasSynced: false };
    }
    return this.db.currentStatus;
  }

  // ------------------------------------------------------------------------

  /** Wait for the first full sync (03 S8.1 app boot — gate rendering).
   *  Resolves IMMEDIATELY when no connector is attached yet (the device
   *  has not signed in / built a relay connector): the local-mirror shell
   *  (AD-7) must paint without a successful first sync; a real session
   *  still gates on the sync as before. */
  waitForFirstSync(): Promise<void> {
    if (!this.db) throw new Error('engine not initialized');
    if (!this.connector) return Promise.resolve();
    return this.db.waitForFirstSync();
  }

  /**
   * Status listener registration (03 S3.2 / SDK debug section): surface
   * `uploadError` / `downloadError` to logging (Sentry breadcrumb pattern,
   * SDK doc "Production Logging").
   */
  registerStatusListener(
    listener: (status: SyncStatus) => void,
  ): () => void {
    if (!this.db) throw new Error('engine not initialized');
    return this.db.registerListener({
      statusChanged: (status) => listener(status),
    });
  }

  /** The Supabase-backed connector (relay auth + RLS-scoped upsync). */
  private buildConnector(): PowerSyncBackendConnector {
    return new SupabaseBackendConnectorImpl({
      endpoint: this.opts.endpoint,
      client: this.opts.createClient,
    });
  }

  /**
   * Sync-status snapshot (03 S3.2 banner). Exposed separately from
   * `currentStatus()` which returns the vendor live status; this returns
   * the vendor-agnostic 5-state surface for the UI.
   */
  syncStateSnapshot(): {
    online: boolean;
    pendingUpstream: number;
    lastSyncAt: Date | null;
    state: 'idle' | 'syncing' | 'degraded';
  } {
    if (!this.db) {
      return { online: false, pendingUpstream: 0, lastSyncAt: null, state: 'idle' };
    }
    const s = this.db.currentStatus;
    const hasPending = s.uploading;
    return {
      online: s.connected || s.connecting,
      pendingUpstream: hasPending ? 1 : 0,
      lastSyncAt: s.lastSyncedAt ?? null,
      state: hasPending ? 'syncing' : 'idle',
    };
  }

  /**
   * The `EngineStoreAdapter` shape expected by `EngineLocalStoreBridge`
   * (local-store-bridge.ts) — maps the engine's SQL surface to the
   * entity → rows cache the bridge maintains. One instance per engine.
   */
  storeAdapter(): import('./local-store-bridge').EngineStoreAdapter {
    return {
      allRows: async (entity: string) => {
        return await this.getAll(`SELECT * FROM ${entity}`);
      },
      watch: (entity: string, onChange: (rows: Record<string, unknown>[]) => void) => {
        return this.watch(`SELECT * FROM ${entity}`, onChange);
      },
    };
  }

  /** Map a mirror scope name to its sync-stream priority (sync-config.yaml). */
  private priorityForScope(scope: string): number {
    // OQ-11 / AD-14: identity = 1 (first paint), core = 2, bulk = 3.
    switch (scope) {
      case 'identity':
        return 1;
      case 'productivity':
        return 2;
      default:
        return 3;
    }
  }
}

/**
 * Engine factory (03 S8.1): the single production construction site.
 * `createClient` MUST return a client already bound to the signed-in user
 * (Supabase session storage, AD-3 publishable key only).
 */
export function createPowerSyncClientEngine(
  options: PowerSyncClientEngineOptions,
): PowerSyncClientEngine {
  return new PowerSyncClientEngine(options);
}

// Kept for API-surface parity with the reference engine (powersync.ts) —
// the `PowerSyncEngineOptions` shape; unused here (credentials come from
// the Supabase session, not a static token) but exported so a shared
// `PowerSyncEngine` union type can name it.
export type { PowerSyncCredentials as PowerSyncClientCredentials };
