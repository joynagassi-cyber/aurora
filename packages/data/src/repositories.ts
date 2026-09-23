// =============================================================================
// LocalQueryRepository / LocalCommandRepository — the read/write contracts
// (03 S3.1, owner `packages/data`).
//
// "L'UI lit UNIQUEMENT SQLite via ces repositories ; l'ecriture passe par
// le module owner" (03 S3.1, AD-7/F-03). The store never exposes a raw
// table to the UI; these two interfaces are the ONLY public surface.
//
//   - LocalQueryRepository<T>: getById / list / watch — local-only, no
//     network on the render path (AD-7, 02 S9).
//   - LocalCommandRepository: apply(ownerModule, cmd) — partial
//     DomainCommand routed to the owning module (single-writer, F-03);
//     the kernel never writes a table, it emits commands/events (F-09).
// =============================================================================

import type { LocalFilter, LocalRow, Unsubscribe } from './local-filter';
import type { LocalStore } from './local-store';
import type { DomainCommand } from './commands';
import { commandEntity, OWNER_MODULE_BY_ENTITY } from './commands';
import { UpsyncQueue } from './upsync-queue';

/** `WriteResult` (03 S3.1 contract). */
export type WriteResult =
  | { ok: true; queuedForUpsync: number }
  | { ok: false; error: { code: string; message: string } };

export interface LocalQueryRepository<T extends LocalRow = LocalRow> {
  /** local-only read by id (AD-7: the UI reads local state first). */
  getById(id: string): Promise<T | undefined>;
  /** local-only filtered list (03 S3.1). */
  list(filter: LocalFilter<T>): Promise<T[]>;
  /** reactive local-only watcher (03 S3.1 / S5.2.2) — no network. */
  watch(filter: LocalFilter<T>, onChange: (rows: T[]) => void): Unsubscribe;
}

export interface LocalCommandRepository {
  /**
   * Route a partial command to the owning module (03 S3.1). The mutation
   * is applied to the local store IMMEDIATELY (03 S5.1.1) and queued for
   * upsync (`WriteResult.queuedForUpsync`). Full-entity PUTs are rejected —
   * single-writer (F-03).
   */
  apply(
    ownerModule: string,
    cmd: DomainCommand | DomainCommand[],
  ): Promise<WriteResult>;
}

// ---------------------------------------------------------------------------
// LocalQueryRepository — the read surface (store-backed, SQLite in prod)
// ---------------------------------------------------------------------------

export class SqliteQueryRepository<T extends LocalRow = LocalRow>
  implements LocalQueryRepository<T>
{
  constructor(
    private readonly store: LocalStore,
    private readonly entity: string,
  ) {}

  async getById(id: string): Promise<T | undefined> {
    const row = this.store.row(this.entity, id);
    return row === undefined ? undefined : (row as T);
  }

  async list(filter: LocalFilter<T>): Promise<T[]> {
    // re-target the filter at this repository's entity (single-module
    // owner, 03 S4.2) — a cross-entity list is not a valid local query.
    const rows = this.store
      .allRows(this.entity)
      .filter((row) => matchWhere(row, filter.where));
    return orderAndPage(rows, filter) as T[];
  }

  watch(filter: LocalFilter<T>, onChange: (rows: T[]) => void): Unsubscribe {
    const targeted: LocalFilter = { ...filter, entity: this.entity };
    const deliver = (rows: LocalRow[]): void => {
      onChange(rows as T[]);
    };
    // seed with the current projection, then subscribe to changes
    // (03 S5.2.2: reactive, local-only, no network).
    deliver(this.projection(targeted));
    return this.store.watch(targeted, deliver);
  }

  private projection(filter: LocalFilter): LocalRow[] {
    const rows = this.store.allRows(filter.entity).filter((r) =>
      matchWhere(r, filter.where),
    );
    return orderAndPage(rows, filter);
  }
}

// ---------------------------------------------------------------------------
// LocalCommandRepository — the write surface (routes to the module owner)
// ---------------------------------------------------------------------------

/**
 * Applies partial commands to the owning module's rows in the local store,
 * queues them for upsync, and enforces single-writer (F-03): a command
 * aimed at the wrong owner module is rejected.
 */
export class SqliteCommandRepository implements LocalCommandRepository {
  constructor(
    private readonly store: LocalStore,
    private readonly queue: UpsyncQueue,
  ) {}

  async apply(
    ownerModule: string,
    cmd: DomainCommand | DomainCommand[],
  ): Promise<WriteResult> {
    const cmds = Array.isArray(cmd) ? cmd : [cmd];
    let queued = 0;
    for (const c of cmds) {
      const entity = commandEntity(c.op);
      if (!entity) {
        return {
          ok: false,
          error: {
            code: 'unknown_op',
            message: `no mirror entity for op "${c.op}"`,
          },
        };
      }
      // single-writer check (F-03): the caller must name the owning module
      const owner = OWNER_MODULE_BY_ENTITY[entity];
      if (owner !== undefined && owner !== ownerModule) {
        return {
          ok: false,
          error: {
            code: 'single_writer_violation',
            message: `entity "${entity}" is owned by "${owner}", not "${ownerModule}" (F-03)`,
          },
        };
      }
      this.applyOne(ownerModule, c, entity);
      queued += 1;
    }
    return { ok: true, queuedForUpsync: queued };
  }

  private applyOne(ownerModule: string, c: DomainCommand, entity: string): void {
    // delete (03 S5.2: the server delete propagates locally too)
    if (c.op.endsWith('.delete')) {
      this.store.deleteRow(entity, c.id);
      this.queue.enqueue(entity, c.id, ownerModule, {}, true, Date.now());
      return;
    }

    const patch = (c as { patch?: Record<string, unknown> }).patch ?? {};
    const existing = this.store.row(entity, c.id);

    if (existing) {
      // update: merge the partial patch (never a full-entity PUT)
      const base: LocalRow = { ...existing };
      for (const [k, v] of Object.entries(patch)) {
        if (v === undefined) continue;
        base[k] = v;
      }
      base.serverUpdatedAtMs = base.serverUpdatedAtMs ?? 0;
      this.store.upsert(entity, base);
    } else {
      // create (or an update that seeds the row locally): the server
      // re-stamps `updated_at` canonically on acknowledgement (03 S4.2 r3)
      const base: LocalRow = { id: c.id, userId: c.userId, serverUpdatedAtMs: 0 };
      for (const [k, v] of Object.entries(patch)) {
        if (v === undefined) continue;
        base[k] = v;
      }
      this.store.upsert(entity, base);
    }

    this.queue.enqueue(entity, c.id, ownerModule, patch, false, Date.now());
  }
}

// ---------------------------------------------------------------------------
// helpers
// ---------------------------------------------------------------------------

function matchWhere(row: LocalRow, where?: Record<string, unknown>): boolean {
  if (!where || Object.keys(where).length === 0) return true;
  return Object.entries(where).every(([k, v]) => row[k] === v);
}

function orderAndPage(rows: LocalRow[], filter: LocalFilter): LocalRow[] {
  let out = rows;
  if (filter.orderBy) {
    const { field, direction = 'asc' } = filter.orderBy;
    out = [...out].sort((a, b) => {
      const av = a[field];
      const bv = b[field];
      if (av === bv) return 0;
      if (av === undefined || av === null) return 1;
      if (bv === undefined || bv === null) return -1;
      const cmp = av < bv ? -1 : 1;
      return direction === 'asc' ? cmp : -cmp;
    });
  }
  if (filter.offset) out = out.slice(filter.offset);
  if (filter.limit !== undefined) out = out.slice(0, filter.limit);
  return out;
}
