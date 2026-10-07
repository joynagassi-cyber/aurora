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

export interface AuroraAppProps {
  dataProvider: MobileDataProvider;
}

export function AuroraApp({ dataProvider }: AuroraAppProps) {
  // The QueryClient is stateful — created exactly once per app mount so
  // the cache survives re-renders (03 S5.8).
  // The single application Command Bus (02 §4, kernel S15) is mounted at
  // the router root (<Shell />) — `useNavigate` requires the <Router>
  // context, so it cannot live beside <RouterProvider>.
  const [client] = useState<QueryClient>(() => createMobileQueryClient(dataProvider));

  return (
    <QueryClientProvider client={client}>
      <RouterProvider router={appRouter} />
    </QueryClientProvider>
  );
}
