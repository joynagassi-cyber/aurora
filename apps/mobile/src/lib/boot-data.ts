// boot-data.ts — the app-shell data-provider boot (03 S8.1 "relay
// operational", the engine SWAP behind `LocalStore`).
//
// AD-1: NO vendor import here — the shell consumes the `@aurora/data`
// production surface only. AD-3: URLs/keys come from the env (injected
// from `.env.local` at build time), never hardcoded.
//
// Gating: `connect()` requires an ACTIVE Supabase auth session (the
// connector's `fetchCredentials` reads `client.auth.getSession()`).
// On logout / user switch call `dispose(true)` (→ `disconnectAndClear()`,
// 03 S5.5.6), then build a fresh provider.

import {
  createAuroraSupabaseClient,
  createPowerSyncClientEngine,
  EngineLocalStoreBridge,
  SqliteQueryRepository,
  UpsyncQueue,
  type AuroraSupabaseClient,
  type LocalQueryRepository,
  type LocalStore,
  type PowerSyncClientEngine,
} from '@aurora/data';
import type { AscentLearningIR, GoalProject, Task, Automation, VeilleVault } from '@aurora/domain';
import { createAscentRepo } from './ascent-repo';
import { createAutomationsRepo } from './automations-repo';
import { createDiscoveryVaultRepo } from './discovery-vault-repo';

/**
 * The `LocalStore`-backed provider the shell boots (03 S8.1). One per
 * signed-in user; `dispose(true)` wipes local data on logout / user
 * switch, `dispose(false)` on app kill (offline state survives in
 * SQLite, AD-7).
 */
export interface AuroraDataProvider {
  /** local-only read (03 S3.1): `goals` mirror table. */
  goals: LocalQueryRepository<GoalProject>;
  /** local-only read (03 S3.1): `tasks` mirror table. */
  tasks: LocalQueryRepository<Task>;
  /** Ascent local mirror (wave 3, read-only AD-7/AD-12): `ascent_paths`. */
  ascent: LocalQueryRepository<AscentLearningIR>;
  /**
   * Discovery vault local mirror (discovery-vault plan 2026-10-10, Lot 4,
   * read-only AD-7): `discovery_vault` (the evolving VAULT.md + the
   * append-only run manifest — the SSoT the card renders offline).
   */
  discoveryVault?: LocalQueryRepository<VeilleVault>;
  /**
   * Automations local mirror (discovery-vault plan 2026-10-10, Lot 4,
   * read-only AD-7): `automations` (the veille program = a
   * `jobKind:'research'` automation whose name/cron feed the card title
   * + subtitle).
   */
  automations?: LocalQueryRepository<Automation>;
  /** the upsync queue (03 S5.1 — the command repository's write side). */
  upsync: UpsyncQueue;
  /** the production engine (`@powersync/capacitor`), null before init. */
  engine: PowerSyncClientEngine;
  /**
   * Kick off the sync loop: init the store, `connect` (fire-and-forget) +
   * `waitForFirstSync` as the readiness gate (03 S8.1). Throws when no
   * Supabase session (sign the user in first, 01 S2.2).
   */
  connect(): Promise<void>;
  /** Tear down: release engine watches, disconnect (or wipe). */
  dispose(clear?: boolean): Promise<void>;
  /** The local `LocalStore` bridge (read side for the repositories). */
  store(): LocalStore;
}

/** The env surface (values from `.env.local`, injected by the build tool). */
export interface AuroraDataEnv {
  /** `SUPABASE_URL`. */
  supabaseUrl: string;
  /** `SUPABASE_PUBLISHABLE_KEY` (publishable only, AD-3). */
  supabasePublishableKey: string;
  /** `POWERSYNC_URL` (the relay, 03 S8.1). */
  powersyncUrl: string;
  /** Device-scoped DB filename (AD-7 offline state survives). */
  dbFilename?: string;
  /**
   * Build with a pre-made client factory (tests inject a fake). Named via
   * the `AuroraSupabaseClient` alias exported by `@aurora/data` so the
   * shell never imports `@supabase/supabase-js` directly (AD-1).
   */
  clientFactory?: () => AuroraSupabaseClient;
}

/**
 * Build the production data provider for the shell (03 S8.1).
 *
 * 1. Supabase client: publishable key only (AD-3 — RLS is the enforcement
 *    layer; the service_role key never reaches the app).
 * 2. Engine: constructed, NOT connected — `connect()` is the boot
 *    readiness gate (03 S8.1: no render before the first sync).
 * 3. Store: `EngineLocalStoreBridge` over the engine's store adapter
 *    (03 S8.1 swap); repositories read local-only through it (03 S3.1).
 */
export function createAuroraDataProvider(env: AuroraDataEnv): AuroraDataProvider {
  const clientFactory: () => AuroraSupabaseClient =
    env.clientFactory ??
    (() =>
      createAuroraSupabaseClient({
        env: {
          supabaseUrl: env.supabaseUrl,
          supabasePublishableKey: env.supabasePublishableKey,
        },
        powersyncUrl: env.powersyncUrl,
      }));

  const engine = createPowerSyncClientEngine({
    endpoint: env.powersyncUrl,
    createClient: clientFactory,
    dbFilename: env.dbFilename,
  });

  // The `LocalStore` swap (03 S8.1): repositories keep the reference
  // `LocalStore` contract; the bridge re-projects engine rows into it.
  const bridge = new EngineLocalStoreBridge(engine.storeAdapter());
  const upsync = new UpsyncQueue();

  const goals = new SqliteQueryRepository<GoalProject>(bridge, 'goals');
  const tasks = new SqliteQueryRepository<Task>(bridge, 'tasks');
  // A2: the Ascent local-mirror repo (snake→camel + JSON.parse, confined here).
  const ascent = createAscentRepo(bridge);
  // Discovery-vault (Lot 4): the two read-only mirrors the card renders
  // offline (VAULT.md + manifest, and the research automation program).
  const discoveryVault = createDiscoveryVaultRepo(bridge);
  const automations = createAutomationsRepo(bridge);

  return {
    goals,
    tasks,
    ascent,
    discoveryVault,
    automations,
    upsync,
    engine,

    async connect(): Promise<void> {
      await engine.init(); // AD-7: the local mirror is ALWAYS available (offline shell)
      // Relay gate (03 S8.1): without a Supabase session the relay cannot be
      // authenticated — skip `addScope` so the PowerSync 5-second retry loop
      // (`fetchCredentials`) does not spam "No Supabase session" errors while
      // signed out. After sign-in the app reloads (login page → `location.assign('/')`)
      // and `connect()` runs with the restored session (persistSession); the
      // local-mirror shell keeps working meanwhile (AD-7 degraded state, honest).
      const { data: { session } } = await clientFactory().auth.getSession();
      if (!session) {
        console.warn(
          '[Aurora] no Supabase session — local-mirror shell only (AD-7); sign in to enable relay sync.',
        );
        return;
      }
      // `auto_subscribe` streams (sync-config.yaml) — no manual
      // `addScope` at the relay; `addScope` triggers `connect`
      // (`db.connect`, fire-and-forget) + `waitForFirstSync` as the
      // readiness gate (03 S8.1: identity first paint = priority 1,
      // OQ-11/AD-14). The gate fails cleanly when the device is not
      // signed in yet (no Supabase session for `fetchCredentials`) —
      // `boot-data.ts#connect()` catches that and degrades to the
      // local-mirror shell (AD-7), so the shell always paints.
      await engine.addScope('identity');
      await engine.addScope('productivity');
      // A2: the ascent local-mirror stream (ascent_paths, read-only AD-7).
      await engine.addScope('ascent');
      // Knowledge local-mirror stream (semantic_nodes / semantic_edges /
      // node_state / semantic_bridges / source_refs, read-only AD-7 —
      // the `embedding` column is NOT mirrored, 0004 §4.2 / AD-12).
      await engine.addScope('knowledge');
      // Discovery local-mirror stream (discovery_items + discovery_vault,
      // read-only AD-7, discovery-vault plan 2026-10-10 Lot 4): the card
      // renders the evolving VAULT.md + manifest offline.
      await engine.addScope('discovery');
      // Integrations local-mirror stream (automations, read-only AD-7 —
      // the Discovery card's program title/subtitle come from a
      // jobKind:'research' automation; the write side is the
      // Integrations module via G2/G3 typed commands).
      await engine.addScope('integrations');
      // Bind the engine's reactive row stream into the bridge cache (03
      // S5.2.2) so repository reads stay live without a poll; the UI's
      // QueryClient invalidation rides on this channel (03 S5.8).
      void bridge.bindEngineWatch('goals');
      void bridge.bindEngineWatch('tasks');
      void bridge.bindEngineWatch('ascent_paths');
      // Knowledge mirror (AD-7): the tree reads semantic_nodes/edges +
      // node_state through the same reactive channel (03 S5.8).
      void bridge.bindEngineWatch('semantic_nodes');
      void bridge.bindEngineWatch('semantic_edges');
      void bridge.bindEngineWatch('node_state');
      // Discovery vault + programs (AD-7, Lot 4): the card re-renders on
      // the vault manifest + automation program downstream batches.
      void bridge.bindEngineWatch('discovery_vault');
      void bridge.bindEngineWatch('automations');
    },

    async dispose(clear = false): Promise<void> {
      bridge.releaseEngineWatches();
      await engine.close(clear);
    },

    store(): LocalStore {
      return bridge;
    },
  };
}
