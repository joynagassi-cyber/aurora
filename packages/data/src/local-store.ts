// =============================================================================
// LocalStore — the storage engine behind the repositories (03 S4 / S5).
//
// Two engines:
//   - `InMemoryLocalStore` — pure JS, zero dependency. Same observable
//     contract as SQLite; the test runner and the Node type-stripping spine
//     use it so the wave-1 invariants (single-writer, server-wins, CRDT
//     merge, re-sync) are verifiable without a device / PowerSync runtime.
//   - PowerSync/SQLite engine — production path. `packages/data` is the
//     single owner of the sync layer (AD-7): when the PowerSync engine +
//     relay are operational (03 S8.1), the app swaps the engine behind the
//     same `LocalStore` contract. The vendor binding stays in this package
//     (AD-1: vendors only in the 5 adapters; `packages/data` is one of
//     them).
//
// The store holds ONLY the signed-in user's rows (RLS survives to the
// device — the device never receives other users' data, 01 S2.2) and is
// the UI's source of truth (AD-7: "the UI reads local state first").
// =============================================================================

import type { LocalFilter, LocalRow, Unsubscribe } from './local-filter';

/** One engine operation batch — a server push (03 S5.2 downstream). */
export interface DownstreamBatch {
  /** table name (mirror entity, single module owner) */
  entity: string;
  /** new / updated rows to UPSERT */
  upserts?: LocalRow[];
  /** ids to delete (server-side deletions) */
  deletes?: string[];
  /** canonical server timestamp of this batch (03 S4.2 rule 3) */
  serverUpdatedAtMs?: number;
}

/**
 * The storage engine contract. Implementations: `InMemoryLocalStore`
 * (tests / spine) and the PowerSync/SQLite engine (production).
 */
export interface LocalStore {
  /** All rows of one mirror entity (single module owner). */
  allRows(entity: string): LocalRow[];
  /** One row by entity + id. */
  row(entity: string, id: string): LocalRow | undefined;
  /** Apply a single upsert (local write, 03 S5.1.1 immediate apply). */
  upsert(entity: string, row: LocalRow): void;
  /** Delete one row. */
  deleteRow(entity: string, id: string): void;
  /**
   * Apply a downstream server batch with per-entity server-wins (03 S5.2):
   * a row is replaced ONLY when the batch's `serverUpdatedAtMs` is >= the
   * row's own `serverUpdatedAtMs` (canonical server `updated_at`, 03 S4.2
   * rule 3). Deletions apply unconditionally (server is the authority).
   *
   * @returns true when at least one row actually changed (so callers can
   *         skip no-op notifications).
   */
  applyDownstream(batch: DownstreamBatch): boolean;
  /** Reactive local-only watcher (03 S3.1 `watch` / 03 S5.2.2). */
  watch(
    filter: LocalFilter,
    onChange: (rows: LocalRow[]) => void,
  ): Unsubscribe;
  /**
   * Number of rows still pending upsync (carries
   * `localMutationId` but not yet acknowledged by the server).
   */
  pendingUpsyncCount(): number;
  /** The most recent `serverUpdatedAtMs` observed per entity. */
  lastServerTs(entity: string): number | undefined;
}

// ---------------------------------------------------------------------------
// InMemoryLocalStore — zero-dependency reference engine
// ---------------------------------------------------------------------------

function safeCompare(a: unknown, b: unknown): number {
  if (a === undefined && b === undefined) return 0;
  if (a === undefined || a === null) return 1;
  if (b === undefined || b === null) return -1;
  if (a === b) return 0;
  return a < b ? -1 : 1;
}

interface Watcher {
  filter: LocalFilter;
  onChange: (rows: LocalRow[]) => void;
}

export class InMemoryLocalStore implements LocalStore {
  private readonly rows = new Map<string, Map<string, LocalRow>>();
  private readonly watchers: Watcher[] = [];
  /** entities with a local mutation not yet acknowledged upstream */
  private readonly pendingUpsync = new Set<string>();
  private readonly serverTs = new Map<string, number>();
  private notifyScheduled = false;

  private rowsOf(entity: string): Map<string, LocalRow> {
    let m = this.rows.get(entity);
    if (!m) {
      m = new Map();
      this.rows.set(entity, m);
    }
    return m;
  }

  allRows(entity: string): LocalRow[] {
    return [...this.rowsOf(entity).values()];
  }

  row(entity: string, id: string): LocalRow | undefined {
    return this.rowsOf(entity).get(id);
  }

  upsert(entity: string, row: LocalRow): void {
    this.rowsOf(entity).set(row.id, { ...row });
    this.notify();
  }

  deleteRow(entity: string, id: string): void {
    if (this.rowsOf(entity).delete(id)) this.notify();
  }

  applyDownstream(batch: DownstreamBatch): boolean {
    let changed = false;
    const ts = batch.serverUpdatedAtMs ?? 0;
    for (const row of batch.upserts ?? []) {
      const existing = this.rowsOf(batch.entity).get(row.id);
      // server-wins per entity (03 S4.2 rule 3): replace only when the
      // incoming batch is not older than what we already hold.
      if (existing) {
        const existingTs = (existing.serverUpdatedAtMs as number | undefined) ?? 0;
        if (ts < existingTs) continue; // stale server value — keep local
      }
      this.rowsOf(batch.entity).set(row.id, { ...row, serverUpdatedAtMs: ts });
      this.pendingUpsync.delete(row.id);
      changed = true;
    }
    for (const id of batch.deletes ?? []) {
      const delExisting = this.rowsOf(batch.entity).get(id);
      // server-wins on delete too (03 S4.2 rule 3): a locally-newer row
      // (a pending upsync mutation) survives; the stale delete is a no-op.
      if (delExisting) {
        const localTs = (delExisting.serverUpdatedAtMs as number | undefined) ?? 0;
        if (ts > 0 && localTs > ts) continue;
      }
      if (this.rowsOf(batch.entity).delete(id)) {
        this.pendingUpsync.delete(id);
        changed = true;
      }
    }
    if (changed) {
      if (ts > 0) this.serverTs.set(batch.entity, Math.max(this.serverTs.get(batch.entity) ?? 0, ts));
      this.notify();
    }
    return changed;
  }

  watch(filter: LocalFilter, onChange: (rows: LocalRow[]) => void): Unsubscribe {
    const watcher: Watcher = { filter, onChange };
    this.watchers.push(watcher);
    // fire immediately with the current projection (03 S5.2.2: reactive,
    // local-only — no network)
    onChange(this.query(filter));
    return () => {
      const i = this.watchers.indexOf(watcher);
      if (i >= 0) this.watchers.splice(i, 1);
    };
  }

  pendingUpsyncCount(): number {
    return this.pendingUpsync.size;
  }

  lastServerTs(entity: string): number | undefined {
    return this.serverTs.get(entity);
  }

  /** Test/diagnostic hook: mark a row as pending upsync. */
  markPendingUpsync(entity: string, id: string): void {
    this.pendingUpsync.add(id);
    void entity;
  }

  /** Query a `LocalFilter` projection (used by `list` / `watch`). */
  private query(filter: LocalFilter): LocalRow[] {
    const all = this.rowsOf(filter.entity).values();
    const where = filter.where;
    let out: LocalRow[] = [...all];
    if (where && Object.keys(where).length > 0) {
      out = out.filter((row) =>
        Object.entries(where).every(([k, v]) => row[k] === v),
      );
    }
    if (filter.orderBy) {
      const { field, direction = 'asc' } = filter.orderBy;
      out = [...out].sort((a, b) => {
        const av = a[field];
        const bv = b[field];
        if (av === bv) return 0;
        const cmp = safeCompare(av, bv);
        return direction === 'asc' ? cmp : -cmp;
      });
    }
    if (filter.offset) out = out.slice(filter.offset);
    if (filter.limit !== undefined) out = out.slice(0, filter.limit);
    return out;
  }

  private notify(): void {
    if (this.notifyScheduled) return;
    this.notifyScheduled = true;
    queueMicrotask(() => {
      this.notifyScheduled = false;
      for (const w of [...this.watchers]) w.onChange(this.query(w.filter));
    });
  }
}
