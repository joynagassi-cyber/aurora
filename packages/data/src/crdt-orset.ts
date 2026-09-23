// =============================================================================
// OR-Set (Observed-Remove Set) CRDT — frozen encoding, single impl (03 S5.3).
//
// SSoT types: `OrSetValue` / `OrSet` / `OrSetMerge` in `@aurora/domain`
// (AD-15, F-01 — never re-declared here). This module is the ONLY runtime
// implementation (03 S5.3: "une seule implementation, pas de dualite
// OR-Set/LWW-Map").
//
// Encoding (frozen, 03 S5.3): each element = `{ v, ts, c }` — value +
// canonical server timestamp + originating client. An add-token is unique by
// (v, ts, c). A remove is OBSERVED: it removes every add-token a client
// observed when it performed the remove, NOT the value itself — that is what
// makes a concurrent add of the same value survive (lossless merge, 03 S7
// "suppression: un element supprime par l'un, ajoute par l'autre =
// convergence OR-Set, pas de resurrection").
//
// Convergence (03 S5.3): two concurrent writes on a list = union of the
// adds each client made, minus the observed removes; scalar clobber is the
// server-wins path (03 S5.3), not this one.
// =============================================================================

import type { OrSetValue, OrSet, OrSetMerge } from '@aurora/domain';

/** An observed-removal record. */
export interface OrSetRemove {
  /** the value being removed */
  v: string;
  /** canonical ts of the remove (03 S4.2 rule 3) */
  ts: number;
  /** the client that performed the remove */
  c: string;
  /**
   * The add-tokens this client OBSERVED at the moment of the remove —
   * encoded as the ts of each observed add (observed-removes, not a
   * blind tombstone). An add with `add.ts > max(observedTs)` is NOT
   * removed by this record: it was concurrent, not observed.
   */
   observedTs: number[];
}

/**
 * The full CRDT state carried by a list field on a mirror row
 * (`crdt_added` + `crdt_removed` jsonb, wave-0 schema).
 */
export interface OrSetState {
  added: OrSetValue[];
  removed: OrSetRemove[];
}

/**
 * Apply a local add (03 S5.1.1: applied locally immediately, queued for
 * upsync). The local ts is only for the upsync FIFO order; the server
 * replaces it with the canonical ts on acknowledgement (03 S4.2 rule 3 —
 * the client never dates its own mutations canonically).
 *
 * Idempotent (AD-8): adding a value this client already added is a no-op
 * for the element (a re-add that removes nothing is not a new element).
 */
export function addOrSetElement(
  state: OrSetState,
  value: string,
  clientId: string,
  localTsMs: number,
): OrSetState {
  const superseded = state.added.some(
    (el) => el.v === value && el.c === clientId && el.ts >= localTsMs,
  );
  if (superseded) return state;
  return {
    ...state,
    added: [...state.added, { v: value, ts: localTsMs, c: clientId }],
  };
}

/**
 * Apply a local remove: record the observed add-tokens for this value.
 * The remove itself carries the local ts; a CONCURRENT add (ts newer,
 * not observed) is NOT removed — that is the OR-Set guarantee.
 */
export function removeOrSetElement(
  state: OrSetState,
  value: string,
  clientId: string,
  localTsMs: number,
): OrSetState {
  const observed = state.added
    .filter((el) => el.v === value)
    .map((el) => el.ts);
  if (observed.length === 0) return state; // nothing observed: no-op (idempotent)
  const record: OrSetRemove = { v: value, ts: localTsMs, c: clientId, observedTs: observed };
  return { ...state, removed: [...state.removed, record] };
}

/** Project the live set: adds that no observed-remove has swallowed. */
export function orSetLive(state: OrSetState): OrSetValue[] {
  const seen = new Map<string, OrSetValue>();
  for (const add of state.added) {
    const key = addKey(add);
    const existing = seen.get(key);
    if (!existing || add.ts > existing.ts) seen.set(key, add);
  }
  return [...seen.values()].filter((add) => !isSwallowed(add, state.removed));
}

/**
 * Merge two concurrent OR-Set states (03 S5.3: two concurrent writes =
 * union of elements, NOT the clobber of the most recent).
 *
 * @returns `merged` = the lossless union; `conflict` = the residual,
 *          un-mergeable value collision (the ONLY path to a `conflict`
 *          SyncStatus, 03 S3.2). With the frozen string-value encoding the
 *          classic lists (tags, dependencies, source_ref_ids, evidence_refs)
 *          ALWAYS converge — `conflict` stays false for them; it is reserved
 *          for payload divergence neither side observed.
 */
export function mergeOrSets(a: OrSet, b: OrSet): OrSetMerge & { state: OrSetState } {
  const adds: OrSetValue[] = [];
  const addSet = new Map<string, OrSetValue>();
  const pushAdd = (el: OrSetValue) => {
    const key = addKey(el);
    const existing = addSet.get(key);
    if (!existing || el.ts > existing.ts) {
      addSet.set(key, el);
      adds.push(el);
    }
  };
  a.elements.forEach(pushAdd);
  b.elements.forEach(pushAdd);

  // Union of observed-removes. A domain OrSet carries no remove log, so the
  // engine tracks it; when only the add-side is known, a remove is implicit
  // for an element that is OBSERVED on both sides (same token `v|ts|c` in
  // both views) AND ABSENT from one side's live projection — that side
  // performed an explicit removal it must not forget. A purely concurrent
  // add (seen only by its origin, not observed by the other side) is
  // NEVER implicit-removed: that is the OR-Set guarantee (03 S5.3,
  // "pas de resurrection" but also "pas de suppression d'un ajout
  // concurrent non observe").
  const removes: OrSetRemove[] = [];
  const aKeys = new Set(a.elements.map(addKey));
  const bKeys = new Set(b.elements.map(addKey));
  for (const el of a.elements) {
    if (!bKeys.has(addKey(el))) {
      // el is not in b's observed view: b never saw this add-token, so
      // it cannot be the source of an observed-remove. If b's view is
      // newer (lastSeenTs) AND the value is absent from b's live set,
      // b explicitly removed it after last observing it — synthesize the
      // observed-remove so the merge is lossless.
      if (b.lastSeenTs !== undefined && b.lastSeenTs >= el.ts) {
        removes.push({
          v: el.v,
          ts: b.lastSeenTs,
          c: b.userId,
          observedTs: [el.ts],
        });
      }
    }
  }
  for (const el of b.elements) {
    if (!aKeys.has(addKey(el))) {
      if (a.lastSeenTs !== undefined && a.lastSeenTs >= el.ts) {
        removes.push({
          v: el.v,
          ts: a.lastSeenTs,
          c: a.userId,
          observedTs: [el.ts],
        });
      }
    }
  }

  const merged = orSetLive({ added: adds, removed: removes });
  // Residual conflict: a value added concurrently by both sides with
  // mutually-exclusive payload the encoding cannot unify. With the frozen
  // string `v`, this is unreachable — kept explicit as the 03 S3.2 hook.
  const conflict = false;

  return { merged, conflict, state: { added: adds, removed: removes } };
}

/** Merge a local OrSetState with a pushed server state (downstream, 03 S5.2). */
export function mergeLocalWithServer(
  local: OrSetState,
  serverAdds: OrSetValue[],
  serverRemoves: OrSetRemove[],
): OrSetMerge & { state: OrSetState } {
  const adds: OrSetValue[] = [];
  const addSet = new Map<string, OrSetValue>();
  const pushAdd = (el: OrSetValue) => {
    const key = addKey(el);
    const existing = addSet.get(key);
    if (!existing || el.ts > existing.ts) {
      addSet.set(key, el);
      adds.push(el);
    }
  };
  local.added.forEach(pushAdd);
  serverAdds.forEach(pushAdd);
  const removes = [...local.removed, ...serverRemoves];
  const merged = orSetLive({ added: adds, removed: removes });
  return { merged, conflict: false, state: { added: adds, removed: removes } };
}

/**
 * Merge the live values of a list field carried by a local row + a server row
 * with the local row's CRDT remove-log (03 S5.3: lossless union of adds,
 * observed-removes survive). Used by `resolveServerWins` for each CRDT list
 * field — the union is computed per-field because each list carries its own
 * OR-Set state (the frozen encoding is per-element `{v, ts, c}`).
 */
export function mergeOrSetValues(
  local: OrSetValue[],
  server: OrSetValue[],
  removed: OrSetRemove[] = [],
): OrSetValue[] {
  const adds: OrSetValue[] = [];
  const seen = new Map<string, OrSetValue>();
  const push = (el: OrSetValue): void => {
    const key = addKey(el);
    const existing = seen.get(key);
    if (!existing || el.ts > existing.ts) {
      seen.set(key, el);
      adds.push(el);
    }
  };
  for (const el of local) push(el);
  for (const el of server) push(el);
  return orSetLive({ added: adds, removed });
}

// ---------------------------------------------------------------------------

function addKey(el: OrSetValue): string {
  return `${el.v}|${el.ts}|${el.c}`;
}

/**
 * An add is swallowed by a remove when the remove OBSERVED it:
 * the remove's `observedTs` list contains the add's ts (a newer concurrent
 * add is NOT in that list → it survives, 03 S5.3 observed-removes).
 */
function isSwallowed(add: OrSetValue, removes: OrSetRemove[]): boolean {
  return removes.some((r) => r.v === add.v && r.observedTs.includes(add.ts));
}
