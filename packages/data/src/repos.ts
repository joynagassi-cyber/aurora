/**
 * @aurora/data — local-first data layer (03 S3, owner Data team).
 *
 * Frozen contracts (contract-catalog §4, owner `packages/data`):
 * `LocalQueryRepository` (SQLite reads, no network on render path — AD-7) and
 * `LocalCommandRepository` (writes queued for upsync, AD-7/F-03). The
 * implementations ship in wave 1 (PowerSync/SQLite); this file is the SSoT of
 * the shapes every React Query queryKey factory types against.
 */
import type { Unsubscribe } from './watch';

/** A filter on local rows. The shape is intentionally minimal (03 S3). */
export interface LocalFilter<T> {
  /** only rows whose id is in the set */
  ids?: string[];
  /** owner user (RLS scope, AD-15) */
  userId?: string;
  /** module-prefixed status / kind filter, e.g. "task.status=todo" */
  where?: Partial<T>;
  orderBy?: { field: keyof T; dir: 'asc' | 'desc' };
  limit?: number;
  offset?: number;
}

/**
 * `LocalQueryRepository` (contract-catalog §4, 03 S3).
 *
 * UI reads ONLY through this port (AD-7: SQLite, no network on the render
 * path). `watch` is the local-only reactive channel that the React Query
 * bridge in `apps/mobile` uses to invalidate queries on upsync events.
 */
export interface LocalQueryRepository<T extends { id: string }> {
  getById(id: string): Promise<T | undefined>;
  list(filter: LocalFilter<T>): Promise<T[]>;
  watch(filter: LocalFilter<T>, onChange: (rows: T[]) => void): Unsubscribe;
}

/** Write result of a local mutation (03 S3.2: mutation is queued for upsync). */
export type WriteResult =
  | { ok: true; queuedForUpsync: number }
  | { ok: false; error: { code: string; message: string } };

/**
 * `LocalCommandRepository` (contract-catalog §4, 03 S3.2).
 *
 * UI writes ONLY through this port; single-writer per entity (AD-7/F-03).
 * `ownerModule` is the AD-13 module that owns the command's intent.
 */
export interface LocalCommandRepository {
  apply(ownerModule: string, cmd: unknown): Promise<WriteResult>;
}
