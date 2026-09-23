/**
 * CRDT OR-Set (Observed-Remove Set) — frozen type, SSoT `packages/domain`
 * (AD-7/F-03, 03-sync S5.3, AD-15).
 *
 * Used for local lists that must MERGE across clients (tags, dependencies,
 * source_ref_ids, evidence_refs, …). Adds/removes converge by union/diff —
 * lossless merge. Serialised in a SQLite JSON column by `packages/data`;
 * one implementation only (no OR-Set/LWW-Map duality).
 *
 * Encoding (frozen, 03 S5.3): each list element =
 * `{ v: string; ts: serverTimestampMs; c: clientId }` — value + server
 * timestamp + originating client. `ts` is the canonical server
 * `updated_at` (03 S4.2 rule 3); `c` ties an add to the client that
 * observed it, which is what makes OR-Set remove/add commute.
 */

/** One element of a frozen OR-Set list (03 S5.3 encoding). */
export interface OrSetValue {
  /** opaque element value (id, tag string, ref…) */
  v: string;
  /** canonical server timestamp (ms) at the last write of this element */
  ts: number;
  /** originating client id */
  c: string;
}

/** A CRDT OR-Set: the set of observed elements. */
export interface OrSet {
  userId: string;
  elements: OrSetValue[];
  /** last sync marker so a client can apply incremental updates */
  lastSeenTs?: number;
}

/**
 * Result of a server-mediated merge of two concurrent OR-Set states
 * (03 S5.3: two concurrent writes = union of elements, not the clobber
 * of the most recent).
 */
export interface OrSetMerge {
  merged: OrSetValue[];
  /** true when a residual, un-mergeable collision remains — the only
   * path to a `conflict` sync status (03 S3.2). */
  conflict: boolean;
}

// Minimal typing only; the single implementation lives in packages/data
// (one impl, 03 S5.3). No heavy logic in domain (AD-1).
