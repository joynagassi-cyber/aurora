// =============================================================================
// React Query bridge (03 S5.8) — the owner of the RQ ↔ `LocalQueryRepository`
// contract.
//
// `@tanstack/react-query` is the data-state layer declared by `02-frontend`;
// this module is the bridge (owner `packages/data`, AD-7): RQ **consumes**
// `watch`, the local store stays the single source of truth (RQ is a read
// cache ONLY — a second business-data cache would violate AD-7).
//
// The React hooks live in `packages/ui` (the React consumer, AD-10: no
// vendor in this module — `@tanstack/react-query` is NOT imported here so
// the bridge typechecks without React installed; the vendor stays with the
// UI layer). This module owns:
//   - the QUERY-KEY convention `[module, entity, ...filter]` (03 S5.8),
//   - the `LocalQueryClient` protocol that RQ's `useQuery` binds to via
//     `useLocalQuery` (the reactive watch consumed by the cache, 03 S5.8),
//   - the invalidation rule: a sync event invalidates the entity's queries
//     (sync state `SyncStateChanged` → `invalidateQueries`, 03 S5.8 — NOT an
//     AD-9 event; the UI reads the local store, AD-7/F-03).
// =============================================================================

import type { LocalFilter, LocalRow, Unsubscribe } from './local-filter';
import type { LocalQueryRepository } from './repositories';

/**
 * The RQ query-key convention (03 S5.8, owner `packages/data`):
 * `[module, entity, ...filter]` — e.g. `['tasks', 'list', filter]`.
 * `invalidateQueries` targets the entity key prefix `[module, entity]`.
 */
export function localQueryKey(
  module: string,
  entity: string,
  filter?: LocalFilter,
): readonly unknown[] {
  return filter !== undefined ? [module, entity, filter] : [module, entity];
}

/** Alias: `entityQueryKey` (the 03 S5.8 `[module, entity, ...filter]` shape). */
export function entityQueryKey(
  module: string,
  entity: string,
  filter?: LocalFilter,
): readonly unknown[] {
  return localQueryKey(module, entity, filter);
}

/**
 * The reactive consumer RQ binds to (03 S5.8): a `useQuery` whose
 * `queryFn` waits on the FIRST `watch` projection and whose re-fetch is
 * driven by the `watch` subscription (RQ = cache OVER `watch`, not a
 * parallel store — AD-7).
 */
export interface LocalQueryClient {
  /** The first local projection (immediate, no network — AD-7). */
  firstRows(): Promise<LocalRow[]>;
  /** Subscribe to the live projection (03 S5.2.2). */
  subscribe(onChange: (rows: LocalRow[]) => void): Unsubscribe;
}

/**
 * Build a `LocalQueryClient` over a repository + filter. This is the object
 * a `useLocalQuery` hook (in `packages/ui`) passes to RQ: RQ calls
 * `firstRows()` on mount and re-renders on each `subscribe` emission.
 */
export function localQueryClient(
  repo: LocalQueryRepository<LocalRow>,
  filter: LocalFilter,
): LocalQueryClient {
  return {
    async firstRows(): Promise<LocalRow[]> {
      return repo.list(filter);
    },
    subscribe(onChange) {
      return repo.watch(filter, onChange);
    },
  };
}

/**
 * The invalidation surface (03 S5.8): a sync event (03 S3.2 `SyncStateChanged`,
 * internal — not an AD-9 event) invalidates the entity's queries so RQ
 * re-reads the local store. The consumer (RQ `QueryClient.invalidateQueries`)
 * gets the key prefix; `packages/data` owns the rule, 02-frontend just calls.
 */
export function localInvalidationKey(module: string, entity: string): readonly unknown[] {
  return [module, entity];
}
