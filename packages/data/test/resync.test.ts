// Re-sync invariant (03 S5.5.4, 03 S7): offline → online drains the upsync
// queue FIFO (bounded, idempotent) and applies the downsync batch with
// per-entity server-wins; status returns to idle with a fresh lastSyncAt.
//
// Run: node --experimental-strip-types --no-warnings packages/data/test/resync.test.ts

import {
  InMemoryLocalStore,
  SqliteCommandRepository,
  SyncEngine,
  SyncStatusMachine,
  UpsyncQueue,
} from '../src/index.ts';
import type { SyncTransport, UpsyncResponse } from '../src/sync-engine.ts';

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
  const status = new SyncStatusMachine();
  const tasks = new SqliteCommandRepository(store, queue);

  // seed a server row the downsync will re-stamp canonically (03 S4.2 r3)
  store.upsert('tasks', { id: 't9', userId: 'u1', status: 'todo', serverUpdatedAtMs: 1000 });

  // offline: queue two local mutations
  status.setOnline(false);
  await tasks.apply('productivity', { op: 'task.create', id: 't1', userId: 'u1', patch: { title: 'a' } });
  status.mutationQueued();
  await tasks.apply('productivity', { op: 'task.update', id: 't1', userId: 'u1', patch: { status: 'doing' } });
  status.mutationQueued();
  check(queue.size() === 2, 'offline: two mutations queued FIFO');
  check(status.snapshot().state === 'pending', 'offline + queued = pending (not idle)');

  // online: ack both; the first batch also carries a downsync row that
  // supersedes the local seed (newer canonical ts, 03 S5.2).
  let transportCalls = 0;
  const transport: SyncTransport = {
    async upsync(batch): Promise<UpsyncResponse> {
      transportCalls++;
      const downsync =
        transportCalls === 1
          ? [{ entity: 'tasks', upserts: [{ id: 't9', status: 'done' }], serverUpdatedAtMs: 9000 }]
          : undefined;
      return { acked: batch.map((e) => e.localMutationId), downsync };
    },
  };
  const engine = new SyncEngine(store, queue, transport, status, { batchSize: 1 });
  status.setOnline(true);
  const acked = await engine.run();

  check(acked === 2, 'both mutations acknowledged upstream');
  check(transportCalls === 2, 'bounded batches (size=1): two transport calls');
  check(queue.isEmpty(), 'queue drained after full upsync');
  check(status.snapshot().state === 'idle', 'drained queue → idle');
  check(status.snapshot().lastSyncAt !== null, 'lastSyncAt set on resync-complete');
  check(store.row('tasks', 't9')?.status === 'done', 'downsync row applied with server-wins ts');

  // a transient failure never drops the queue (03 S6 / AD-5)
  const store2 = new InMemoryLocalStore();
  const queue2 = new UpsyncQueue();
  const status2 = new SyncStatusMachine();
  const tasks2 = new SqliteCommandRepository(store2, queue2);
  await tasks2.apply('productivity', { op: 'task.create', id: 't2', userId: 'u1', patch: { title: 'b' } });
  const failing: SyncTransport = {
    async upsync(): Promise<UpsyncResponse> {
      throw new Error('transient');
    },
  };
  const engine2 = new SyncEngine(store2, queue2, failing, status2);
  const acked2 = await engine2.run();
  check(acked2 === 0 && queue2.size() === 1, 'failure: queue intact, nothing acked');
  check(status2.snapshot().state === 'degraded', 'failure → degraded (bounded retry, 03 S6)');

  if (failures > 0) {
    console.error(`resync: ${failures} failure(s)`);
    process.exit(1);
  }
  console.log('resync: all invariants hold');
}

void main();
