/**
 * user-features.ts — the G-M7 availability hook (docs/frontend/
 * feature-registry.md S1/S2/S8): the single `isEnabled(featureId)` the
 * shell, the router gates and the Settings toggles all consume.
 *
 * Resolution (frozen, unit-tested in test/feature-flags.test.ts):
 *   URL session override (?feature / ?features — QA + deep links, NEVER
 *   persisted) > user_context.features (persisted, read via the publishable
 *   client) > seed default (FEATURE_MODULES, S8 enabledByDefault).
 *
 * AD-7: the optimistic toggle writes locally first (state) — the persisted
 * write is fire-and-forget (AD-8: the UI never blocks; an offline write
 * simply retries on the next read).
 */
import { useCallback, useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useSearchParams } from 'react-router-dom';
import { parseFeatureOverride, resolveFeatureEnabled } from '../feature-registry';
import { getUserContextClient, type UserFeatures } from '../lib/user-context-client';

/** One read is short-lived: the row is tiny + the toggle self-heals. */
const FEATURES_STALE_MS = 5 * 60_000;

/**
 * `useUserFeatures` — the availability policy (S2 chain) composed of
 * enabled + persisted overrides + session URL override. Must render
 * inside the router (uses `useSearchParams`) — the shell's routes.
 */
export function useUserFeatures() {
  const [searchParams] = useSearchParams();
  const urlOverride = useMemo(
    () => parseFeatureOverride(Object.fromEntries(searchParams.entries())),
    [searchParams],
  );

  const client = getUserContextClient();
  const [optimistic, setOptimistic] = useState<UserFeatures>({});

  const { data: stored } = useQuery({
    queryKey: ['userContext', 'features'],
    queryFn: () => (client ? client.getFeatures() : Promise.resolve(null)),
    enabled: client !== undefined,
    staleTime: FEATURES_STALE_MS,
    retry: 1,
  });

  const userFeatures = useMemo<UserFeatures>(
    () => ({ ...(stored ?? {}), ...optimistic }),
    [stored, optimistic],
  );

  const isEnabled = useCallback(
    (featureId: string) => resolveFeatureEnabled(featureId, userFeatures, urlOverride),
    [userFeatures, urlOverride],
  );

  /** Optimistic toggle (AD-8 non-blocking) + persisted upsert. */
  const setFeature = useCallback(
    (featureId: string, enabled: boolean) => {
      setOptimistic((o) => ({ ...o, [featureId]: enabled }));
      if (!client) return;
      void client.setFeature(featureId, enabled).catch((error) => {
        console.warn('[Aurora] feature sync en attente — réappliquée au prochain sync', error);
      });
    },
    [client],
  );

  return { isEnabled, setFeature, urlOverride, userFeatures };
}
