// =============================================================================
// Server-wins conflict resolution (03 S5.1 / S5.3 — the frozen canonical rule).
//
// "server-wins + horodatage serveur par entite": when a local mutation
// (queued for upstream) collides with a newer server value (same entity,
// newer server `updated_at`), the SERVER WINS. The resolution is SILENT —
// no user alert (01 S6: "le conflit est resolu silencieusement par
// PowerSync"). The client NEVER dates its own mutations canonically
 // (03 S4.2 rule 3): the local mutation's ts is only for upsync FIFO; the
// server rewrites `updated_at` on application.
//
// Lists are the exception (03 S5.3): merge losslessly via the OR-Set CRDT
// instead of clobbering — a concurrent add from another client is unioned,
// not overwritten.
// =============================================================================

import type { LocalRow } from './local-filter';
import type { OrSetState } from './crdt-orset';
import { mergeOrSetValues } from './crdt-orset';
import type { OrSetValue } from '@aurora/domain';

/** The fields of a mirror row that carry CRDT OR-Set lists (03 S5.3). */
export const CRDT_LIST_FIELDS: ReadonlySet<string> = new Set([
  'tags',
  'dependencies',
  'evidenceRefs',
  'sourceRefIds',
  'sources',
]);

/**
 * Resolve a collision between a locally-queued row (applied optimistically)
 * and the server's canonical row for the same id.
 *
 * @returns the winning row:
 *  - scalars: the server row, when its `serverUpdatedAtMs` is newer
 *    (03 S4.2 rule 3 — canonical server timestamp). When the local mutation
 *    is NEWER (it was applied after the server value we had, and the server
 *    has not yet re-stamped it), keep local — it is still queued and the
 *    server will re-stamp on acknowledgement.
 *  - CRDT list fields: union of both sides' live sets (lossless, 03 S5.3).
 */
export function resolveServerWins(
  localRow: LocalRow,
  serverRow: LocalRow,
  crdtState?: OrSetState,
): LocalRow {
  const localTs = (localRow.serverUpdatedAtMs as number | undefined) ?? 0;
  const serverTs = (serverRow.serverUpdatedAtMs as number | undefined) ?? 0;

  const winner: LocalRow = { ...localRow };

  // scalars: server wins on newer canonical ts
  if (serverTs > localTs) {
    for (const [k, v] of Object.entries(serverRow)) {
      if (k === 'id') continue; // id is stable, never overwritten
      winner[k] = v;
    }
    winner.id = localRow.id;
  }

  // CRDT lists: lossless union regardless of ts (03 S5.3) — per-field
  // OR-Set, observed-removes from the local CRDT state survive.
  for (const field of CRDT_LIST_FIELDS) {
    const localList = asOrSetValueList(localRow[field]);
    const serverList = asOrSetValueList(serverRow[field]);
    if (localList.length === 0 && serverList.length === 0) continue;
    winner[field] = mergeOrSetValues(localList, serverList, crdtState?.removed ?? []);
  }

  return winner;
}

function asOrSetValueList(value: unknown): OrSetValue[] {
  if (!Array.isArray(value)) return [];
  return value.filter(
    (el): el is OrSetValue =>
      el !== null &&
      typeof el === 'object' &&
      'v' in el &&
      'ts' in el &&
      'c' in el,
  );
}
