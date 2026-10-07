/**
 * auth.ts — minimal Supabase Auth surface for the shell (P1-4 unblock, 10-07).
 *
 * Single-client design (AD-3, 03 S8.1): `main.tsx` owns ONE shared
 * `AuroraSupabaseClient` (publishable-only) and injects it here via
 * `setAuthClient` — the SAME instance backs the PowerSync relay connector
 * (`boot-data.ts` `clientFactory`). So a sign-in here is immediately visible
 * to the relay's `fetchCredentials` retry (~5 s) without a reload: the browser
 * `storage` event does not sync two separate GoTrueClient instances in the
 * same tab, so sharing the instance is what makes live sign-in work.
 *
 * AD-1: the shell consumes the `@aurora/data` surface ONLY — never imports
 * `@supabase/supabase-js` directly. `createAuroraSupabaseClient` is the sole
 * client construction site. AD-3: publishable key only (env-injected,
 * 03 S2.1 / OQ-03) — RLS is the enforcement layer; service_role never ships.
 */
import { createAuroraSupabaseClient, type AuroraSupabaseClient } from '@aurora/data';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL ?? '';
const supabasePublishableKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ?? '';

/** OQ-03: absent env values degrade to the local-mirror shell (AD-7, honest state). */
export const authAvailable = Boolean(supabaseUrl && supabasePublishableKey);

/** The boot's shared client (injected by `main.tsx`); `null` until then. */
let sharedClient: AuroraSupabaseClient | null = null;

/**
 * Wire the shared Supabase client (single-instance design, AD-3 / 03 S8.1).
 * Call once at boot BEFORE the relay starts reconnecting.
 */
export function setAuthClient(client: AuroraSupabaseClient): void {
  sharedClient = client;
}

/** Shared instance when available, else a standalone client (env-present). */
function resolveClient(): AuroraSupabaseClient | undefined {
  if (sharedClient) return sharedClient;
  if (!authAvailable) return undefined;
  return createAuroraSupabaseClient({ env: { supabaseUrl, supabasePublishableKey } });
}

/** The active session (restored from device-local storage on boot). */
export async function currentSession() {
  const client = resolveClient();
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
  const client = resolveClient();
  if (!client) throw new Error('Aucun accès Supabase configuré (OQ-03).');
  const { data, error } = await client.auth.signInWithPassword({ email, password });
  if (error) throw new Error(error.message);
  // Diagnostic (AD-7): the relay's `fetchCredentials` retry sees this session
  // on the SAME client instance within ~5 s — the "No Supabase session" spam
  // must stop (no reload required).
  console.log('[Aurora] sign-in réussi — relay PowerSync se connecte sous ~5 s', {
    user: data.session?.user?.email,
  });
  if (data.session?.user) {
    await client.from('user_context').upsert(
      { user_id: data.session.user.id },
      { onConflict: 'user_id' },
    );
  }
}

export async function signOut(): Promise<void> {
  const client = resolveClient();
  if (!client) return;
  await client.auth.signOut();
}

/**
 * Inscription (sign-up, 10-07) : création du user par GoTrue lui-même
 * (admin-canonique) — jamais par INSERT SQL brut (leçon P1-4 : audience,
 * hash et identité email doivent être celles du projet). Deux issues :
 *  - session immédiate (confirmation email désactivée) → le seed de
 *    `user_context` (scope identity, AD-14) s'applique et l'app peut
 *    recharger ;
 *  - `needsEmailConfirmation` (confirm-required projet) → l'app montre
 *    l'état honnête « vérifie ta boîte mail » (AD-13), jamais un faux
 *    succès.
 */
export async function signUp(email: string, password: string): Promise<{ needsEmailConfirmation: boolean }> {
  const client = resolveClient();
  if (!client) throw new Error('Aucun accès Supabase configuré (OQ-03).');
  const { data, error } = await client.auth.signUp({ email: email.trim(), password });
  if (error) throw new Error(error.message);
  if (data.session?.user) {
    await client.from('user_context').upsert(
      { user_id: data.session.user.id },
      { onConflict: 'user_id' },
    );
    console.log('[Aurora] sign-up réussi — session active, relay PowerSync sous ~5 s', {
      user: data.session.user.email,
    });
    return { needsEmailConfirmation: false };
  }
  console.log('[Aurora] sign-up — confirmation email requise avant 1er sign-in', {
    user: email,
  });
  return { needsEmailConfirmation: true };
}
