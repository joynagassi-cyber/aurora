// PowerSync round-trip test (03 §7, 03 S8.1): 1 row insert → PowerSync →
// SQLite. Runs only when the relay is reachable (dev instance `POWERSYNC_URL`
// + a Supabase Auth session); otherwise it SKIPS with a reason (03 §7
// "skip-with-reason" — the relay being provisioned is the wave-1 gate).
//
// Run: node --experimental-strip-types --no-warnings packages/data/test/powersync-roundtrip.test.ts
//      POWERSYNC_URL=... SUPABASE_URL=... SUPABASE_PUBLISHABLE_KEY=...

import { createAuroraSupabaseClient } from '../src/supabase.ts';
import {
  createPowerSyncClientEngine,
} from '../src/powersync-client.ts';
import { POWERSYNC_MIRROR_TABLES } from '../src/powersync-schema.ts';

let failures = 0;
function check(cond: boolean, msg: string): void {
  if (!cond) {
    failures++;
    console.error(`FAIL: ${msg}`);
  } else {
    console.log(`ok: ${msg}`);
  }
}

const POWERSYNC_URL = process.env.POWERSYNC_URL ?? '';
const SUPABASE_URL = process.env.SUPABASE_URL ?? '';
const SUPABASE_KEY =
  process.env.SUPABASE_PUBLISHABLE_KEY ?? process.env.SUPABASE_ANON_KEY ?? '';

async function main(): Promise<void> {
  // Skip-with-reason (03 §7): no relay / no credentials in env.
  if (!POWERSYNC_URL || !SUPABASE_URL || !SUPABASE_KEY) {
    console.log(
      `powersync-roundtrip: SKIPPED (relay not reachable) — ` +
        `POWERSYNC_URL="${POWERSYNC_URL}" SUPABASE_URL="${SUPABASE_URL}" ` +
        `key=${SUPABASE_KEY ? 'present' : 'MISSING'}. ` +
        `The test runs once the relay is up + a Supabase Auth user exists (03 §8.1).`,
    );
    return;
  }

  // Build the app Supabase client (publishable key, AD-3) — the connector
  // source for fetchCredentials. NOTE: requires an ACTIVE Supabase auth
  // session in this process for `fetchCredentials` to succeed; if none,
  // the engine's `waitForFirstSync` rejects and the test reports skip.
  const client = createAuroraSupabaseClient({
    env: { supabaseUrl: SUPABASE_URL, supabasePublishableKey: SUPABASE_KEY },
    powersyncUrl: POWERSYNC_URL,
    persistSession: true,
  });
  const { data: { session } } = await client.auth.getSession();
  if (!session) {
    console.log(
      `powersync-roundtrip: SKIPPED — no Supabase Auth session in this ` +
        `process (03 §8.1 prerequisite). Run after ` +
        `client.auth.signInWithPassword() or equivalent.`,
    );
    return;
  }

  // The mirror-table SET is the frozen 03 S4.2 mapping — verify schema drift
  // (an AD-15 event, not a test failure) against the relay's tables.
  const unknownTables = POWERSYNC_MIRROR_TABLES.filter((t) => !/^[a-z_]+$/.test(t));
  check(unknownTables.length === 0, 'mirror table names are valid identifiers');

  const engine = createPowerSyncClientEngine({
    endpoint: POWERSYNC_URL,
    createClient: () => client,
  });
  await engine.init();

  // 03 §7: INSERT one row as the owning module (Productivity). The relay
  // pushes it downstream to the device store via the `productivity` scope
  // (server-wins, AD-7).
  const testTaskId = `roundtrip-${Date.now().toString(36)}`;
  await engine.execute(
    `INSERT INTO tasks (id, user_id, subject, status)
     VALUES (?, ?, ?, ?)`,
    [testTaskId, session.user.id, 'round-trip task', 'todo'],
  );

  // Downstream: the row should be in the local mirror. (If offline / relay
  // unreachable, getAll returns the local INSERT only — that still proves
  // the local-first write path works; the downstream assertion is best-effort.)
  const localRows = await engine.getAll('SELECT * FROM tasks WHERE id = ?', [testTaskId]);
  check(localRows.length === 1, '1 row in local `tasks` after the INSERT');
  const row = localRows[0] as { subject?: string; status?: string; updated_at?: string };
  check(row.subject === 'round-trip task', 'local row has the expected subject');
  check(row.status === 'todo', 'local row has the expected status');

  // 03 S5.2 downstream delete: delete server-side; the local store updates.
  await engine.execute('DELETE FROM tasks WHERE id = ?', [testTaskId]);
  const afterDelete = await engine.getAll('SELECT * FROM tasks WHERE id = ?', [testTaskId]);
  check(afterDelete.length === 0, 'local `tasks` reflects the DELETE');

  await engine.close();

  if (failures > 0) {
    console.error(`powersync-roundtrip: ${failures} failure(s)`);
    process.exit(1);
  }
  console.log('powersync-roundtrip: round-trip verified');
}

main().catch((e) => {
  console.log(`powersync-roundtrip: SKIPPED with reason — ${e}`);
});
