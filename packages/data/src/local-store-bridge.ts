// =============================================================================
// local-store-bridge.ts — `LocalStore` bridge over the PowerSync engine.
//
// 03 S8.1 "engine swap behind LocalStore": the production store adapter.
// Repositories (repositories.ts) keep the same `LocalStore` contract —
// the `InMemoryLocalStore` reference engine runs the invariants in tests,
// and this bridge runs them on the real SQLite mirror (offline-first,
// AD-7).
//
// Downstream flow (03 S5.2): PowerSync applies sync ops to the SQLite
// mirror itself; the bridge observes the engine's state and re-projects
// into `LocalRow` objects for the repositories. The bridge holds a
// minimal cache (entity → rows) kept in sync with the engine's
// last-synced state, updated on `applyDownstream` and the engine's
// reactive watch (03 S5.2.2).
//
// This file is vendor-bound (AD-1): it imports the engine types, never
// the reference path.
// =============================================================================

import type { LocalFilter, LocalRow, Unsubscribe } from './local-filter';
import type { DownstreamBatch, LocalStore } from './local-store';

/**
 * A `LocalStore` implementation backed by a real sync engine. The engine
 * is behind a narrow adapter interface so the bridge stays unit-testable
 * with a fake (and stays usable whether the engine is the Capacitor
 * PowerSync client or a Node test double).
 */
export interface EngineStoreAdapter {
  /** All rows of one mirror table (synced + local writes materialized). */
  allRows(entity: string): Promise<Record<string, unknown>[]>;
  /** Reactively watch a mirror table (03 S3.1 `watch` / 03 S5.2.2). */
  watch(entity: string, onChange: (rows: Record<string, unknown>[]) => void): Unsubscribe;
}

/**
 * The `LocalStore` bridge over an engine (03 S8.1). Rows arrive in
 * mirror (snake_case) shape — the repositories' `LocalRow` surface is
 * the same shape, so the bridge only does bookkeeping (server-wins
 * timestamps, pending-upsync tracking), never renames columns.
 */
export class EngineLocalStoreBridge implements LocalStore {
  private readonly cache = new Map<string, Map<string, LocalRow>>();
  private readonly watchers: { entity: string; onChange: (rows: LocalRow[]) => void }[] = [];
  private readonly pendingUpsync = new Set<string>();
  private readonly serverTs = new Map<string, number>();
  private readonly unwatches: Unsubscribe[] = [];

  constructor(engine: EngineStoreAdapter) {
    this.engine = engine;
    // Subscribe the bridge's cache to the engine's reactive rows (03 S5.2.2
    // downstream apply). The engine pushes new row projections; we mirror
    // them into the cache + notify local watchers.
  }

  private readonly engine: EngineStoreAdapter;

  allRows(entity: string): LocalRow[] {
    return [...(this.cache.get(entity) ?? new Map()).values()];
  }

  row(entity: string, id: string): LocalRow | undefined {
    return this.cache.get(entity)?.get(id);
  }

  upsert(entity: string, row: LocalRow): void {
    this.ensureCache(entity).set(row.id, { ...row });
    this.pendingUpsync.add(row.id);
    this.notify(entity);
  }

  deleteRow(entity: string, id: string): void {
    if (this.ensureCache(entity).delete(id)) {
      this.pendingUpsync.delete(id);
      this.notify(entity);
    }
  }

  /**
   * Apply a downstream server batch with server-wins (03 S5.2): a row is
   * replaced only when the batch's `serverUpdatedAtMs` >= the row's own
   * (03 S4.2 rule 3). Deletions apply unless a local mutation is newer.
   */
  applyDownstream(batch: DownstreamBatch): boolean {
    let changed = false;
    const ts = batch.serverUpdatedAtMs ?? 0;
    const rows = this.ensureCache(batch.entity);
    for (const row of batch.upserts ?? []) {
      const existing = rows.get(row.id);
      if (existing) {
        const existingTs = (existing.serverUpdatedAtMs as number | undefined) ?? 0;
        if (ts < existingTs) continue; // stale — keep local
      }
      rows.set(row.id, { ...row, serverUpdatedAtMs: ts });
      this.pendingUpsync.delete(row.id);
      changed = true;
    }
    for (const id of batch.deletes ?? []) {
      const delExisting = rows.get(id);
      if (delExisting) {
        const localTs = (delExisting.serverUpdatedAtMs as number | undefined) ?? 0;
        if (ts > 0 && localTs > ts) continue; // local mutation wins this delete
      }
      if (rows.delete(id)) {
        this.pendingUpsync.delete(id);
        changed = true;
      }
    }
    if (changed) {
      if (ts > 0) this.serverTs.set(batch.entity, Math.max(this.serverTs.get(batch.entity) ?? 0, ts));
      this.notify(batch.entity);
    }
    return changed;
  }

  /**
   * Reactive local watcher (03 S3.1 `watch`). The bridge layers local
   * mutations + applied downstream batches on top of the engine's own
   * reactive stream (03 S5.2.2) so the UI sees both in one subscription.
   */
  watch(filter: LocalFilter, onChange: (rows: LocalRow[]) => void): Unsubscribe {
    const entry = { entity: filter.entity, onChange };
    this.watchers.push(entry);
    // Seed with the current projection (reactive, local-only).
    onChange(this.projection(filter));
    return () => {
      const i = this.watchers.indexOf(entry);
      if (i >= 0) this.watchers.splice(i, 1);
    };
  }

  pendingUpsyncCount(): number {
    return this.pendingUpsync.size;
  }

  lastServerTs(entity: string): number | undefined {
    return this.serverTs.get(entity);
  }

  /**
   * Pull the engine's current rows for an entity into the cache (bridge
   * bootstrap + post-sync refresh). Called at store init and after a
   * full re-sync (03 S5.5.4).
   */
  async refreshFromEngine(entity: string): Promise<void> {
    const rows = await this.engine.allRows(entity);
    const map = this.ensureCache(entity);
    map.clear();
    for (const r of rows) map.set(String(r.id), r as LocalRow);
    this.notify(entity);
  }

  /** Subscribe the cache to the engine's reactive row stream (03 S5.2.2). */
  async bindEngineWatch(entity: string): Promise<Unsubscribe> {
    const unsubscribe = this.engine.watch(entity, (rows) => {
      const map = this.ensureCache(entity);
      map.clear();
      for (const r of rows) map.set(String(r.id), r as LocalRow);
      this.notify(entity);
    });
    this.unwatches.push(unsubscribe);
    return unsubscribe;
  }

  /** Release every engine subscription (app kill / user switch). */
  releaseEngineWatches(): void {
    for (const u of this.unwatches.splice(0)) u();
  }

  private ensureCache(entity: string): Map<string, LocalRow> {
    let m = this.cache.get(entity);
    if (!m) {
      m = new Map();
      this.cache.set(entity, m);
    }
    return m;
  }

  private projection(filter: LocalFilter): LocalRow[] {
    let out = this.allRows(filter.entity);
    const where = filter.where;
    if (where && Object.keys(where).length > 0) {
      out = out.filter((row) =>
        Object.entries(where).every(([k, v]) => row[k] === v),
      );
    }
    return out;
  }

  private notify(entity: string): void {
    for (const w of this.watchers) {
      if (w.entity === entity) w.onChange(this.projection(w as unknown as LocalFilter));
    }
  }
}
