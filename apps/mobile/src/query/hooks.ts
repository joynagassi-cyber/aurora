/**
 * React Query hooks — local reads (AD-7, 02 S6.2: NO network on mount).
 *
 * Each hook reads from the injected `MobileDataProvider`'s local repositories
 * (SQLite mirror). The 5 canonical UX states (AD-13) are derived from the
 * React Query status: `isPending` -> loading, `isError` -> error,
 * `data.length === 0` -> empty, plus the `offline` / `killed` states from the
 * NetworkStatusAdapter / AppLifecycleAdapter (P3).
 */
import { useQuery } from '@tanstack/react-query';
import type { GoalProject, Task } from '@aurora/domain';
import { qk, type MobileDataProvider } from './query-client';
import { useMobileData } from './context';

export function useGoals() {
  const { goals } = useMobileData();
  return useQuery({
    queryKey: qk.goal.list(),
    queryFn: async () => (await goals.list({})).filter((g): g is GoalProject => g.status === 'active'),
  });
}

export function useGoal(goalId: string | undefined) {
  const { goals } = useMobileData();
  return useQuery({
    queryKey: qk.goal.detail(goalId ?? ''),
    queryFn: async () => (goalId ? goals.getById(goalId) : undefined),
    enabled: goalId !== undefined,
  });
}

export function useTasks(filter?: { userId?: string }) {
  const { tasks } = useMobileData();
  return useQuery({
    queryKey: qk.task.list(filter?.userId),
    queryFn: async () => tasks.list({ userId: filter?.userId }) as Promise<Task[]>,
  });
}

export function useTask(taskId: string | undefined) {
  const { tasks } = useMobileData();
  return useQuery({
    queryKey: qk.task.detail(taskId ?? ''),
    queryFn: async () => (taskId ? tasks.getById(taskId) : undefined),
    enabled: taskId !== undefined,
  });
}

export type { MobileDataProvider };
