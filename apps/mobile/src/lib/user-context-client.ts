/**
 * user-context-client.ts — device-side `user_context.features` access
 * (G-M7 feature registry, AD-3 publishable scope).
 *
 * `user_context` is the identity scope (AD-14 first paint): one row per
 * user, RLS `user_context_user_isolation` bounds every op to
 * `auth.uid()` — the device never sends a user id of someone else.
 *
 * The feature flags are the ONE column this client reads/merges:
 * `features jsonb` (roadmap 10-07) = `{ calendar: false, … }`. Reads are
 * lightweight (one row); the WRITE is a read-modify-merge upsert (AD-8:
 * the sync is fire-and-forget from the UI — the toggle never blocks the
 * render, an offline write degrades to the next read).
 *
 * AD-1: the vendor SDK is named ONLY through `AuroraSupabaseClient`
 * (@aurora/data) — this file touches no vendor type.
 */
import type { AuroraSupabaseClient } from '@aurora/data';

/** The persisted user feature overrides (user_context.features jsonb). */
export type UserFeatures = Record<string, boolean>;

export interface UserContextClient {
  /** The user's persisted feature overrides (`null` = no row / no session). */
  getFeatures(): Promise<UserFeatures | null>;
  /** Persist one feature override (optimistic from the UI; AD-8 non-blocking). */
  setFeature(featureId: string, enabled: boolean): Promise<void>;
}

/** Module-level holder (same pattern as `lib/auth.ts` — one shared client). */
let shared: UserContextClient | undefined;

/** Wire the client at boot (before the first feature read). */
export function setUserContextClient(client: UserContextClient): void {
  shared = client;
}

/** The boot client; `undefined` when the shell has no Supabase env (OQ-03). */
export function getUserContextClient(): UserContextClient | undefined {
  return shared;
}

/**
 * Build the device-side user-context client on the shared publishable
 * client (single GoTrue instance, AD-3 / 03 S8.1).
 */
export function createUserContextClient(client: AuroraSupabaseClient): UserContextClient {
  type RawRow = { user_id: string; features?: unknown };

  /** The current user's row (`null` when signed out — honest state, AD-7). */
  async function readRow(): Promise<RawRow | null> {
    const { data: session } = await client.auth.getSession();
    const userId = session?.user?.id;
    if (!userId) return null;
    const { data, error } = await client
      .from('user_context')
      .select('user_id, features')
      .eq('user_id', userId)
      .limit(1);
    if (error) throw new Error(`user_context read: ${error.message}`);
    return ((data as RawRow[] | null) ?? [])[0] ?? null;
  }

  function toBoolMap(raw: unknown): UserFeatures {
    if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return {};
    const out: UserFeatures = {};
    for (const [key, value] of Object.entries(raw as Record<string, unknown>)) {
      if (typeof value === 'boolean') out[key] = value;
    }
    return out;
  }

  return {
    async getFeatures() {
      const row = await readRow();
      if (!row) return null;
      return toBoolMap(row.features);
    },

    async setFeature(featureId, enabled) {
      const current = toBoolMap((await readRow())?.features);
      const merged: UserFeatures = { ...current, [featureId]: enabled };
      const { data: session } = await client.auth.getSession();
      const userId = session?.user?.id;
      if (!userId) throw new Error('Non connecté — connecte-toi pour sauvegarder.');
      const { error } = await client
        .from('user_context')
        .upsert({ user_id: userId, features: merged }, { onConflict: 'user_id' });
      if (error) throw new Error(`user_context write: ${error.message}`);
    },
  };
}
