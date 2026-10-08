/**
 * React Query ↔ @aurora/data local repositories bridge (03 S5.8).
 *
 * AD-7 (local-first): every queryKey here resolves to a `LocalQueryRepository`
 * read (SQLite). NO network on the render path. The `watch()` subscription
 * is wired into the QueryClient so upsync events invalidate local reads.
 *
 * The `dataProvider` injection pattern keeps this file hexagonal: the app
 * shell builds the provider with the real PowerSync-backed repositories at
 * boot; tests inject in-memory repositories. No vendor import here (AD-1:
 * vendor SDKs stay in packages/data, apps/mobile consumes the contract).
 */
import { QueryClient } from '@tanstack/react-query';
import type { LocalQueryRepository, LocalFilter } from '@aurora/data';
import type { AscentLearningIR, GoalProject, Task } from '@aurora/domain';
import { markFirstLocalReadSeen } from '../hooks/use-killed';
import type { AgentClient } from '../lib/agent-client';
import type { CanvasClient } from '../lib/canvas-client';
import type { IntegrationClient } from '../lib/integrations-client';
import type { SkillClient } from '../lib/skills-client';

/** The injected data provider — one repository per entity family. */
export interface MobileDataProvider {
  goals: LocalQueryRepository<GoalProject>;
  tasks: LocalQueryRepository<Task>;
  /** Ascent local mirror (wave 3): the read-only `ascent_paths` table. */
  ascent?: LocalQueryRepository<AscentLearningIR>;
  /**
   * The device-side agent client (AD-3: publishable scope only). Present
   * when the shell has Supabase env values — the /agent page enqueues
   * kernel runs through it (`fn-agent-run`, AD-12/F-09).
   */
  agent?: AgentClient;
  /**
   * The device-side integrations client (AD-3: publishable scope only).
   * The /integrations page connects external apps through it
   * (`fn-integrations`, Composio v3.1 sessions).
   */
  integrations?: IntegrationClient;
  /**
   * The device-side skills marketplace client (AD-3: publishable scope only).
   * The /skills page reads the catalog + manages the user's activated skills
   * through it (`fn-skills`, Task 1: multi-source skill marketplace).
   */
  skills?: SkillClient;
  /**
   * The device-side canvas client (AD-3: publishable scope only, 0022).
   * The /canvas page reads/writes canvas sessions + comments through it
   * (Supabase PostgREST, per-user RLS).
   */
  canvas?: CanvasClient;
  /**
   * The local `LocalStore` (PowerSync/SQLite, 03 S8.1) — read side of the
   * families that don't have their own `LocalQueryRepository` yet (AD-7 /
   * 03 S3.1): today `semantic_nodes` / `semantic_edges` / `node_state`
   * (knowledge, `knowledge-repo.ts`). NO network on this path; the store is
   * a local snapshot. Absent when the provider has no local engine (e.g.
   * tests injecting fake repos without the boot provider).
   */
  store?: import('@aurora/data').LocalStore;
  /** optional: reactive channel that invalidates the QueryClient on upsync. */
  onLocalChange?: (invalidate: () => void) => void;
}
/**
 * Query-key factory (02 S6.1 context-preserving: ids + scope live in the
 * key, so two screens reading the same entity with different contexts get
 * different caches).
 */
export const qk = {
  goal: {
    all: () => ['goal'] as const,
    list: (userId?: string) => [...qk.goal.all(), 'list', userId ?? 'me'] as const,
    detail: (goalId: string) => [...qk.goal.all(), 'detail', goalId] as const,
  },
  task: {
    all: () => ['task'] as const,
    list: (userId?: string, filter?: LocalFilter<Task>) =>
      [...qk.task.all(), 'list', userId ?? 'me', JSON.stringify(filter ?? {})] as const,
    detail: (taskId: string) => [...qk.task.all(), 'detail', taskId] as const,
  },
  // Ascent local mirror (ascent_paths, read-only — AD-7/AD-12). The current
  // path is the newest 'active' row per user (Slide-Ascent, wave 3).
  ascent: {
    all: () => ['ascent'] as const,
    list: (userId?: string) => [...qk.ascent.all(), 'list', userId ?? 'me'] as const,
  },
  // agent_runs mirror (AD-7 read side, 0008): per-run polling while
  // the kernel job is in flight (02 §4 / F-09).
  agent: {
    all: () => ['agent'] as const,
    run: (runId: string) => [...qk.agent.all(), 'run', runId] as const,
    // PRD-AI-01 (Conversations) : the user's run history (read-only, AD-7).
    list: () => [...qk.agent.all(), 'list'] as const,
  },
  // Canvas (0022): per-session queries (load + save + comments).
  canvas: {
    all: () => ['canvas'] as const,
    session: (sessionId: string) =>
      [...qk.canvas.all(), 'session', sessionId] as const,
  },
};

/**
 * Build a QueryClient wired to a data provider. The `onLocalChange` hook
 * (if provided) registers a subscription that invalidates on local-store
 * change — the React Query ↔ watch bridge (03 S5.8).
 */
export function createMobileQueryClient(provider: MobileDataProvider): QueryClient {
  const client = new QueryClient({
    defaultOptions: {
      queries: {
        // local store: data is always "fresh enough"; retry is cheap and
        // safe (SQLite read, no network — AD-7).
        staleTime: 60_000,
        retry: 1,
      },
    },
  });

  if (provider.onLocalChange) {
    provider.onLocalChange(() => {
      client.invalidateQueries({ queryKey: qk.goal.all() });
      client.invalidateQueries({ queryKey: qk.task.all() });
      // A2: the Ascent local mirror invalidates on the ascent_paths watch.
      client.invalidateQueries({ queryKey: qk.ascent.all() });
    });
  }

  // G-M2 (04 S6.1): the "first local re-read done" clear signal is NOT
  // wired here. React Query's internal subscription surface
  // (`queryCache.subscribe` / `query.subscribe`) is fragile across
  // bundled builds (the `client.queryCache` property / `query.state`
  // shape changed between versions → repeated `undefined.subscribe`
  // crashes). Instead the signal is dispatched at the LOCAL-READ SSoT
  // path — the repository wrapper in `mobileDataProviderFrom` below
  // (`withFirstLocalReadSignal`, 03 S5.8). That is exactly where the
  // "first local re-read" happens and it uses only `Promise.then`
  // (no library internals, no crash path).

  return client;
}

/**
 * G-M2 (04 S6.1) — the "first local re-read done" signal. Wraps a
 * `LocalQueryRepository` so the FIRST successful local read
 * (`list` / `getById`) dispatches `aurora:first-local-read` EXACTLY ONCE.
 * This is the 03 S5.8 local-read bridge itself (no network, SQLite), so it
 * is the honest "re-read complete" moment that clears the killed-state
 * skeleton (`useKilledDetection`). A local flag + the module flag
 * (`markFirstLocalReadSeen`) keep later hook mounts informed after the
 * one-shot event has already fired.
 */
function withFirstLocalReadSignal<T>(repo: LocalQueryRepository<T>): LocalQueryRepository<T> {
  let signaled = false;
  const signal = () => {
    if (signaled) return;
    signaled = true;
    markFirstLocalReadSeen();
    if (typeof window !== 'undefined') {
      window.dispatchEvent(new Event('aurora:first-local-read'));
    }
  };
  return {
    getById: (id) => {
      const p = repo.getById(id);
      void p.then(signal, () => undefined);
      return p;
    },
    list: (filter) => {
      const p = repo.list(filter);
      void p.then(signal, () => undefined);
      return p;
    },
    watch: (filter, onChange) => repo.watch(filter, onChange),
  };
}

/**
 * Build a `MobileDataProvider` from the production data provider
 * (`createAuroraDataProvider`, 03 S8.1). The `onLocalChange` channel is
 * wired to the `AuroraDataProvider.store()` watch — the bridge that
 * surfaces engine downstream batches to the QueryClient (03 S5.8).
 */
export function mobileDataProviderFrom(
  provider: import('../lib/boot-data').AuroraDataProvider,
  agent?: AgentClient,
  integrations?: IntegrationClient,
  skills?: SkillClient,
  canvas?: CanvasClient,
): MobileDataProvider {
  // G-M2: wrap the local read SSoT so the FIRST successful local read
  // dispatches `aurora:first-local-read` (the killed-clear signal). Pure
  // `Promise.then` — no React Query internals, no crash path (03 S5.8).
  const goals = withFirstLocalReadSignal(provider.goals);
  const tasks = withFirstLocalReadSignal(provider.tasks);
  const ascent = provider.ascent
    ? withFirstLocalReadSignal(provider.ascent)
    : undefined;
  return {
    goals,
    tasks,
    // A2: expose the Ascent local-mirror repo (snake→camel-mapped, AD-15).
    ascent,
    // AD-3: the publishable-scope agent client (kernel enqueue + mirror read).
    agent,
    // AD-3: the publishable-scope integrations client (Composio v3.1
    // sessions via `fn-integrations`; connected accounts + tool execution).
    integrations,
    // AD-3: the publishable-scope skills client (multi-source marketplace
    // via `fn-skills`; catalog read + user skill activation, Task 1).
    skills,
    // AD-3: the publishable-scope canvas client (0022: canvas sessions +
    // comments via PostgREST, per-user RLS).
    canvas,
    // AD-7 / 03 S3.1: expose the local store read side so the knowledge
    // family (semantic_nodes / semantic_edges / node_state) can read its
    // mirror without a dedicated repository (knowledge-repo.ts).
    store: provider.store(),
    onLocalChange: (invalidate) => {
      // The bridge watches the mirror tables; invalidate on downstream
      // batches (03 S5.8). goals + the ascent_paths read-only mirror (A2).
      provider.store().watch({ entity: 'goals' }, () => invalidate());
      provider.store().watch({ entity: 'ascent_paths' }, () => invalidate());
      // Knowledge mirror (AD-7): semantic_nodes / semantic_edges /
      // node_state downstream batches invalidate the knowledge query key.
      provider.store().watch({ entity: 'semantic_nodes' }, () => invalidate());
      provider.store().watch({ entity: 'semantic_edges' }, () => invalidate());
      provider.store().watch({ entity: 'node_state' }, () => invalidate());
    },
  };
}
