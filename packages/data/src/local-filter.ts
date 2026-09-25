// =============================================================================
// LocalFilter / Unsubscribe — shared read contracts (03 S3.1).
//
// The UI reads ONLY through `LocalQueryRepository` (03 S3.1, AD-7/F-03):
// getById / list / watch. `LocalFilter` is the query surface; it is a
// structural projection, never a raw SQL string (the store is the only
// surface that sees the mirror tables, 03 S4.1 "miroir des entites AD-15").
// =============================================================================

/**
 * A structural projection of one mirror table row. Every AD-15 entity the
 * local store persists carries `id` + `userId` (RLS isolation survives to
 * the device: the store only ever holds the signed-in user's rows, 01 S2.2).
 */
export interface LocalRow {
  id: string;
  userId: string;
  [field: string]: unknown;
}

/**
 * Row-level query filter for `list` / `watch` (03 S3.1).
 *
 * - `entity`: the mirror table / AD-15 entity name (single-module owner).
 * - `where`: optional equality predicate over row fields (e.g.
 *   `{ status: 'todo', goalId: 'g1' }`). Absent = all rows of the entity.
 * - `orderBy` / `limit` / `offset`: presentation options (deterministic
 *   ordering matters for `watch` diffs and for stable query keys in the
 *   React Query bridge, 03 S5.8).
 *
 * No JOIN across entities (F-03): a filter addresses ONE entity table;
 * cross-module data flows through the source module's own rows (public view
 * semantics, 01 S3.4), never through a local join.
 */
export interface LocalFilter<T extends LocalRow = LocalRow> {
  entity: string;
  where?: Partial<Record<keyof T, unknown>>;
  orderBy?: { field: keyof T & string; direction?: 'asc' | 'desc' };
  limit?: number;
  offset?: number;
}

/** A reactive unsubscribe handle (03 S3.1 `watch`). */
export type Unsubscribe = () => void;
