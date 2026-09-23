// CRDT OR-Set merge invariant (03 S5.3, 03 S7): lossless union, observed
// removes, no resurrection of a concurrently-added element.
//
// Run: node --experimental-strip-types --no-warnings packages/data/test/crdt-merge.test.ts

import {
  addOrSetElement,
  removeOrSetElement,
  orSetLive,
  mergeOrSets,
  mergeLocalWithServer,
} from '../src/index.ts';
import type { OrSet, OrSetValue } from '@aurora/domain';

let failures = 0;
function check(cond: boolean, msg: string): void {
  if (!cond) {
    failures++;
    console.error(`FAIL: ${msg}`);
  } else {
    console.log(`ok: ${msg}`);
  }
}

function values(els: OrSetValue[]): string[] {
  return els.map((e) => e.v).sort();
}

function main(): void {
  // two clients add DISTINCT tags concurrently → union (no clobber).
  // Each add is only seen by its origin (the other client never observed
  // it), so no implicit remove is synthesized and both survive.
  const clientA: OrSet = { userId: 'cA', elements: [{ v: 'physics', ts: 10, c: 'cA' }] };
  const clientB: OrSet = { userId: 'cB', elements: [{ v: 'chem', ts: 20, c: 'cB' }] };
  const merged = mergeOrSets(clientA, clientB);
  check(
    JSON.stringify(values(merged.merged)) === JSON.stringify(['chem', 'physics']),
    'concurrent distinct adds union losslessly',
  );
  check(merged.conflict === false, 'string-valued OR-Set never reports a residual conflict');

  // one-sided removal → the element is gone on the merged state: b observed
  // the add (lastSeenTs marker covers it) but its live set excludes it, so
  // the merge synthesizes the observed-remove. No resurrection.
  const clientA2: OrSet = { userId: 'cA', elements: [{ v: 'physics', ts: 10, c: 'cA' }] };
  const clientB2: OrSet = { userId: 'cB', elements: [], lastSeenTs: 10 };
  const merged2 = mergeOrSets(clientA2, clientB2);
  check(
    JSON.stringify(values(merged2.merged)) === JSON.stringify([]),
    'a one-sided removal is respected on merge (no resurrection)',
  );

  // observed-remove: B removes "physics" while A concurrently re-adds it
  // with a NEWER add-token (not observed by the remove) → it survives.
  let state = { added: [], removed: [] };
  state = addOrSetElement(state, 'physics', 'cA', 10);
  state = removeOrSetElement(state, 'physics', 'cB', 20); // observes ts=10
  state = addOrSetElement(state, 'physics', 'cA', 30); // concurrent, un-observed
  const live = orSetLive(state);
  check(
    live.some((e) => e.v === 'physics' && e.ts === 30),
    'concurrent un-observed add is NOT resurrected-then-killed (it survives)',
  );
  check(
    !live.some((e) => e.ts === 10),
    'the observed (swallowed) add is gone',
  );

  // local + server merge: server-side adds union in, server removes win
  const localState = addOrSetElement({ added: [], removed: [] }, 'src-1', 'cA', 5);
  const localRemoved = removeOrSetElement(localState, 'src-1', 'cA', 6);
  const serverAdds: OrSetValue[] = [{ v: 'src-2', ts: 7, c: 'cB' }];
  const serverMerge = mergeLocalWithServer(localRemoved, serverAdds, []);
  check(
    JSON.stringify(values(serverMerge.merged)) === JSON.stringify(['src-2']),
    'server-downstream merge: local-removed element does not re-appear, server add unions in',
  );

  if (failures > 0) {
    console.error(`crdt-merge: ${failures} failure(s)`);
    process.exit(1);
  }
  console.log('crdt-merge: all invariants hold');
}

main();
