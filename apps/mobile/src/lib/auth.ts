/**
 * auth.ts — minimal Supabase Auth surface for the shell (P1-4 unblock, 10-07).
 *
 * AD-1: the shell consumes the `@aurora/data` surface ONLY — never imports
 * `@supabase/supabase-js` directly. `createAuroraSupabaseClient` is the sole
 * client construction site (packages/data, supabase.ts).
 * AD-3: publishable key only (env-injected, 03 S2.1 / OQ-03) — RLS is the
 * enforcement layer; the service_role secret never reaches the device.
 *
 * The engine's PowerSync connector reads `client.auth.getSession()` from a
 * client built with `persistSession: true` (default) at boot — so a session
 * signed in here is restored on the next boot and the sync loop connects.
 */
import { createAuroraSupabaseClient, type AuroraSupabaseClient } from '@aurora/data';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL ?? '';
const supabasePublishableKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ?? '';

/** OQ-03: absent env values degrade to the local-mirror shell (AD-7, honest state). */
export const authAvailable = Boolean(supabaseUrl && supabasePublishableKey);

const client: AuroraSupabaseClient | undefined = authAvailable
  ? createAuroraSupabaseClient({ env: { supabaseUrl, supabasePublishableKey } })
  : undefined;

/** The active session (restored from device-local storage on boot). */
export async function currentSession() {
  if (!client) return null;
  const { data } = await client.auth.getSession();
  return data.session;
}

/**
 * Sign in with email + password, then seed the caller's `user_context` row
 * (identity scope, AD-14 first paint) via the publishable-scope client.
 * RLS: `user_context_user_isolation` allows the user to upsert their OWN row.
 */
export async function signIn(email: string, password: string): Promise<void> {
  if (!client) throw new Error('Aucun accès Supabase configuré (OQ-03).');
  const { data, error } = await client.auth.signInWithPassword({ email, password });
  if (error) throw new Error(error.message);
  if (data.session?.user) {
    await client.from('user_context').upsert(
      { user_id: data.session.user.id },
      { onConflict: 'user_id' },
    );
  }
}

export async function signOut(): Promise<void> {
  if (!client) return;
  await client.auth.signOut();
}
