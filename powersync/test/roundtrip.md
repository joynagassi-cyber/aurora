# PowerSync round-trip test (03 §7) — 1 row insert → PowerSync → SQLite

**Status: WRITTEN — skipped-with-reason (relay operational = wave 1, 03 §8.1).**

This test is runnable once the PowerSync relay is provisioned (wave 1). It is
documented here in wave 0 together with the schema + relay-scoped views it
exercises.

## Test

```
1. Prereq: relay operational (wave 1) with the wave-0 scope views
   (powersync/relay.sql) loaded and the sync schema (powersync/schema.json).
2. INSERT one row into a mirrored table as the owning module, e.g.:
       INSERT INTO tasks (user_id, subject, status)
       VALUES ($TEST_USER, 'round-trip task', 'todo');
   The row is owned by Productivity (single-writer, AD-7/F-03).
3. PowerSync downstream (03 S5.2): the relay pushes the new row to the
   device store via the `productivity` scope view (server-wins, AD-7).
4. Assert on the SQLite local store: exactly 1 row in local `tasks` with
   subject = 'round-trip task' and status = 'todo', and a server canonical
   `updated_at` (03 S4.2 rule 3).
5. Delete the row server-side; assert the local store is updated (03 S5.2
   downstream delete).
```

## Skip-with-reason (wave 0)

The relay is **not provisioned in wave 0** (03 §8.1: "sync engine (relay +
triggers + RLS) opérationnel = vague 1"). Wave 0 ships the prerequisites
(schema + views + RLS + config). Executing this test requires the live relay,
so it is skipped here and runs in wave 1.

## Run command (wave 1, when relay is up)

```
# 1. Provision the relay (Data team, 03 S8.1)
# 2. Run the round-trip (a test harness owning packages/data)
pnpm --filter data test powersync-roundtrip
# expected: 1 local row appears, canonical updated_at, delete propagates
```

If the relay is not reachable at test time: **skip-with-reason** + log the
relay URL from `POWERSYNC_URL` (env, `.env.local`) so the next CI run can
retry. Never assert success without the relay actually connected.
