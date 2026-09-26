// Engine-swap surface test (03 S8.1, 03 S7): the production PowerSync
// binding (SupabaseBackendConnector + LocalStore bridge) is exercised with
// a FAKE Supabase client — no network, no Capacitor runtime — so it runs
// under the Node type-stripping CI gate like every other invariant test.
//
// Run: node --experimental-strip-types --no-warnings packages/data/test/engine-swap.test.ts

import {
  EngineLocalStoreBridge,
} from '../src/local-store-bridge.ts';
import {
  createSupabaseBackendConnector,
  type SupabaseConnectorOptions,
} from '../src/supabase-connector.ts';
import type { LocalRow } from '../src/local-filter.ts';
import type { SupabaseClient } from '@supabase/supabase-js';

let failures = 0;
function check(cond: boolean, msg: string): void {
  if (!cond) {
    failures++;
    console.error(`FAIL: ${msg}`);
  } else {
    console.log(`ok: ${msg}`);
  }
}

// ---------------------------------------------------------------------------
// A fake Supabase client (just enough surface for the connector)
// ---------------------------------------------------------------------------

function makeFakeClient(upsertImpl?: (table: string, row: Record<string, unknown>) => unknown) {
  const client = {
    from(table: string) {
      return {
        async upsert(row: Record<string, unknown>) {
          const e = upsertImpl?.(table, row);
          return { error: e ?? null, data: [] };
        },
        update(patch: Record<string, unknown>) {
          return {
            async eq(_col: string, _v: string) {
              const e = upsertImpl?.(table, patch);
              return { error: e ?? null, data: [] };
            },
          };
        },
        delete() {
          return {
            async eq(_col: string, _v: string) {
              return { error: null, data: [] };
            },
          };
        },
      };
    },
    auth: {
      async getSession() {
        return {
          data: { session: { access_token: 'jwt-test-token', expires_at: Math.floor(Date.now() / 1000) + 3600 } },
          error: null,
        };
      },
    },
  };
  return client as unknown as SupabaseClient;
}

function makeOpts(extra?: Partial<SupabaseConnectorOptions>): SupabaseConnectorOptions {
  return {
    endpoint: 'https://test.powersync.journeyapps.com',
    client: () => makeFakeClient(),
    ...extra,
  };
}

// ---------------------------------------------------------------------------
// A fake CRUD transaction (the shape `uploadData` consumes)
// ---------------------------------------------------------------------------

function makeCrudTransaction() {
  let completed = 0;
  const crud = [
    {
      clientId: 1,
      id: 'task-1',
      op: 'PUT' as const,
      opData: { user_id: 'u1', subject: 'round-trip task', status: 'todo', active: 1 },
      table: 'tasks',
      transactionId: 1,
    },
  ];
  return {
    crud,
    complete: async () => { completed++; },
    completed,
    get completedCount() { return completed; },
  };
}

function txCompleted(tx: ReturnType<typeof makeCrudTransaction>): number {
  // The getter returns the live counter
  return (tx as { completedCount: number }).completedCount;
}

async function main(): Promise<void> {
  // 1) fetchCredentials returns the session JWT + relay endpoint
  const connector = createSupabaseBackendConnector(makeOpts());
  const creds = await connector.fetchCredentials();
  check(creds.token === 'jwt-test-token', 'fetchCredentials returns the session JWT');
  check(creds.endpoint === 'https://test.powersync.journeyapps.com', 'fetchCredentials returns the relay endpoint');
  check(creds.expiresAt !== undefined, 'fetchCredentials returns expiresAt');

  // 2) uploadData: PUT path + transaction.complete() (queue advances)
  const conn2 = createSupabaseBackendConnector(makeOpts());
  const tx = makeCrudTransaction();
  const fakeDb = {
    getNextCrudTransaction: async () => tx,
  } as unknown as Parameters<typeof conn2.uploadData>[0];
  await conn2.uploadData(fakeDb);
  check(txCompleted(tx) === 1, 'uploadData: transaction.complete() called (queue advances)');

  // 3) uploadData: RLS 42501 = permanent → complete + onUploadFailure, no throw
  const rlsErr = { code: '42501', message: 'permission denied for table tasks' };
  let failedLogged = 0;
  const conn3 = createSupabaseBackendConnector(
    makeOpts({
      client: () => makeFakeClient((table) => (table === 'tasks' ? rlsErr : null)),
      onUploadFailure: () => { failedLogged++; },
    }),
  );
  const txRls = makeCrudTransaction();
  const fakeDbRls = {
    getNextCrudTransaction: async () => txRls,
  } as unknown as Parameters<typeof conn3.uploadData>[0];
  await conn3.uploadData(fakeDbRls); // must NOT throw
  check(txCompleted(txRls) === 1, 'uploadData: RLS 42501 → complete() (queue unblocks)');
  check(failedLogged === 1, 'uploadData: RLS failure surfaced via onUploadFailure');

  // 4) uploadData: transient (no code) → throws (PowerSync backs off + retries)
  const clientTransient = () => makeFakeClient(() => new Error('network down'));
  const conn4 = createSupabaseBackendConnector(makeOpts({ client: clientTransient }));
  const txT = makeCrudTransaction();
  const fakeDbT = {
    getNextCrudTransaction: async () => txT,
  } as unknown as Parameters<typeof conn4.uploadData>[0];
  let threw = false;
  try {
    await conn4.uploadData(fakeDbT);
  } catch {
    threw = true;
  }
  check(threw, 'uploadData: transient failure throws (retry with backoff)');
  check(txCompleted(txT) === 0, 'uploadData: transient failure does NOT complete the queue');

  // 5) LocalStore bridge: server-wins downstream apply (03 S4.2 rule 3)
  const bridge = new EngineLocalStoreBridge({
    allRows: async () => [] as Record<string, unknown>[],
    watch: () => () => {},
  });
  bridge.upsert('tasks', { id: 't9', userId: 'u1', status: 'todo', serverUpdatedAtMs: 1000 } as LocalRow);
  const applied = bridge.applyDownstream({
    entity: 'tasks',
    upserts: [{ id: 't9', userId: 'u1', status: 'done' } as unknown as LocalRow],
    serverUpdatedAtMs: 9000,
  });
  check(applied === true, 'bridge: newer downstream batch applied (server-wins)');
  check(bridge.row('tasks', 't9')?.status === 'done', 'bridge: row reflects the server value');
  const stale = bridge.applyDownstream({
    entity: 'tasks',
    upserts: [{ id: 't9', userId: 'u1', status: 'todo' } as unknown as LocalRow],
    serverUpdatedAtMs: 500,
  });
  check(stale === false, 'bridge: stale downstream batch rejected (server-wins)');

  // 6) Bridge local mutation is pending upsync
  bridge.upsert('tasks', { id: 't-new', userId: 'u1', status: 'todo' } as LocalRow);
  check(bridge.pendingUpsyncCount() === 1, 'bridge: local mutation tracked as pending upsync');

  if (failures > 0) {
    console.error(`engine-swap: ${failures} failure(s)`);
    process.exit(1);
  }
  console.log('engine-swap: all invariants hold');
}

void main();
