/**
 * App entry — wires the Ionic shell, the router (17 pages), and the
 * React Query provider over the local data bridge (AD-7).
 *
 * The `dataProvider` prop is the DI seam: the app shell builds it with
 * the real PowerSync-backed repositories at boot (wave 1 data impl);
 * tests inject in-memory repositories. No vendor import here (AD-1).
 * The `onLocalChange` hook (03 S5.8 watch → invalidate bridge) is wired
 * exactly once inside `createMobileQueryClient`.
 */
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { RouterProvider } from 'react-router-dom';
import { useState } from 'react';
import { appRouter } from './router';
import { createMobileQueryClient, type MobileDataProvider } from './query/query-client';
import { AgentBus } from './shell/AgentBus';

export interface AuroraAppProps {
  dataProvider: MobileDataProvider;
}

export function AuroraApp({ dataProvider }: AuroraAppProps) {
  // The QueryClient is stateful — created exactly once per app mount so
  // the cache survives re-renders (03 S5.8).
  const [client] = useState<QueryClient>(() => createMobileQueryClient(dataProvider));

  return (
    <QueryClientProvider client={client}>
      {/* The single application Command Bus (02 §4, kernel S15): agent
          UI effects dispatch here — mounted under the router so the
          executor can navigate (details over the current tab, §6.1). */}
      <AgentBus />
      <RouterProvider router={appRouter} />
    </QueryClientProvider>
  );
}
