/**
 * Mobile data provider context — bridges the React Query cache to the
 * injected `MobileDataProvider` (local repositories, AD-7).
 *
 * The app shell (Shell.tsx) wraps the router in `<MobileDataProvider>` so
 * feature pages call `useGoals()` / `useTasks()` and get local reads without
 * any vendor import (AD-1: PowerSync/SQLite stay in @aurora/data).
 */
import { createContext, useContext, type ReactNode } from 'react';
import type { MobileDataProvider } from './query-client';

const Ctx = createContext<MobileDataProvider | null>(null);

export function MobileDataCtx({ value, children }: { value: MobileDataProvider; children: ReactNode }) {
  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useMobileData(): MobileDataProvider {
  const v = useContext(Ctx);
  if (!v) throw new Error('useMobileData must be used under <MobileDataCtx>');
  return v;
}
