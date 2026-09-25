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
import type { GoalProject, Task } from '@aurora/domain';

/** The injected data provider — one repository per entity family. */
export interface MobileDataProvider {
  goals: LocalQueryRepository<GoalProject>;
  tasks: LocalQueryRepository<Task>;
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
    });
  }

  return client;
}
