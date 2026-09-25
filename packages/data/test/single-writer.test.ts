// Single-writer invariant (AD-7 / F-03, 03 S7):
// only the owning module mutes an entity's local rows; the kernel
// (and any caller naming a wrong owner) is rejected.
//
// Run: node --experimental-strip-types --no-warnings packages/data/test/single-writer.test.ts

import {
  InMemoryLocalStore,
  SqliteCommandRepository,
  SqliteQueryRepository,
  UpsyncQueue,
  OWNER_MODULE_BY_ENTITY,
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

  // seed a task row (owner Productivity for the `tasks` mirror)
  await tasks.apply('productivity', {
    op: 'task.create',
    id: 'task-1',
    userId: 'u1',
    patch: { title: 'Waves' },
  });
  check(store.row('tasks', 'task-1') !== undefined, 'owner apply seeds the row locally');

  // wrong owner for `tasks` (owned by Productivity) is rejected — F-03
  const wrongOwner = await tasks.apply('knowledge', {
    op: 'task.update',
    id: 'task-1',
    userId: 'u1',
    patch: { status: 'done' },
  });
  check(wrongOwner.ok === false, 'cross-module command rejected');
  check(
    'error' in wrongOwner && wrongOwner.error.code === 'single_writer_violation',
    'rejection is a single_writer_violation',
  );
  check(
    store.row('tasks', 'task-1')?.status === undefined,
    'the rejected command did NOT mute the row (single-writer preserved)',
  );

  // correct owner can mute
  const ok = await tasks.apply('productivity', {
    op: 'task.update',
    id: 'task-1',
    userId: 'u1',
    patch: { status: 'done' },
  });
  check(ok.ok === true && (ok as { ok: true }).queuedForUpsync === 1, 'owner apply is accepted + queued');
  check(store.row('tasks', 'task-1')?.status === 'done', 'owner apply mutates the row');

  // the owner table is the source of truth (03 S4.2 frozen mapping)
  check(OWNER_MODULE_BY_ENTITY['tasks'] === 'productivity', 'tasks is owned by productivity');

  // the read side is unaffected (queries still work, no write leaked)
  const q = new SqliteQueryRepository(store, 'tasks');
  const rows = await q.list({ entity: 'tasks', where: { status: 'done' } });
  check(rows.length === 1 && rows[0].id === 'task-1', 'read projection reflects owner mutation only');

  if (failures > 0) {
    console.error(`single-writer: ${failures} failure(s)`);
    process.exit(1);
  }
  console.log('single-writer: all invariants hold');
}

void main();
