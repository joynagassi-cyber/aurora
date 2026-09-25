// Server-wins + per-entity timestamp (AD-7, 03 S7) + upsync dedup (03 S5.1.3, AD-8).
//
// Run: node --experimental-strip-types --no-warnings packages/data/test/server-wins.test.ts

import {
  InMemoryLocalStore,
  SqliteCommandRepository,
  UpsyncQueue,
  resolveServerWins,
  UlidGenerator,
} from '../src/index.ts';

let failures = 0;
function check(cond: boolean, msg: string): void {
  if (!cond) {
    failures++;
    console.error(`FAIL: ${msg}`);
  } else {
    console.log(`ok: ${msg}`);
  }
}

async function main(): Promise<void> {
  const store = new InMemoryLocalStore();
  const queue = new UpsyncQueue();
  const tasks = new SqliteCommandRepository(store, queue);

  // local row with an older canonical ts; server pushes a newer value
  store.upsert('tasks', { id: 't1', userId: 'u1', status: 'todo', serverUpdatedAtMs: 1000 });
  const local = store.row('tasks', 't1')!;
  const server = { id: 't1', userId: 'u1', status: 'done', serverUpdatedAtMs: 2000 };

  const winner = resolveServerWins(local, server);
  check(winner.status === 'done', 'newer server value wins (silently, no alert)');
  check(winner.serverUpdatedAtMs === 2000, 'winner carries the canonical server ts');

  // a LOCAL-newer row is NOT clobbered by a stale server value
  const localNewer = { id: 't2', userId: 'u1', status: 'todo', serverUpdatedAtMs: 3000 };
  const staleServer = { id: 't2', userId: 'u1', status: 'done', serverUpdatedAtMs: 2000 };
  const keepLocal = resolveServerWins(localNewer, staleServer);
  check(keepLocal.status === 'todo', 'local-newer row survives a stale server push');

  // downstream batch with a NEWER server ts replaces the local row
  const changed = store.applyDownstream({
    entity: 'tasks',
    upserts: [{ id: 't2', status: 'done', serverUpdatedAtMs: 4000 }],
    serverUpdatedAtMs: 4000,
  });
  check(changed && store.row('tasks', 't2')?.status === 'done', 'newer downstream batch replaces the row');

  // dedup (03 S5.1.3): a re-queued identical mutation is not doubled
  const ulids = new UlidGenerator({ now: () => 1_700_000_000_000 });
  const dq = new UpsyncQueue(ulids);
  const a = dq.enqueue('tasks', 't3', 'productivity', { status: 'doing' });
  const b = dq.enqueue('tasks', 't3', 'productivity', { status: 'doing' });
  check(a === b && dq.size() === 1, 'identical mutation collapses to one queue entry (AD-8)');

  // apply + re-queue through the repository: the write is idempotent
  await tasks.apply('productivity', { op: 'task.update', id: 't3', userId: 'u1', patch: { status: 'doing' } });
  check(queue.size() === 1, 'queued mutations are FIFO-deduped on identical patch');

  if (failures > 0) {
    console.error(`server-wins: ${failures} failure(s)`);
    process.exit(1);
  }
  console.log('server-wins: all invariants hold');
}

void main();
