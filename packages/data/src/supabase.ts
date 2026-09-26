// =============================================================================
// supabase.ts — Supabase client factory (AD-3, AD-1).
//
// `packages/data` is one of the 5 adapter packages where vendor SDKs live
// (AD-1); the Supabase JS client is constructed here — nowhere else in the
// monorepo imports `@supabase/supabase-js` directly (domain/ui stay clean).
//
// Client-side ONLY: the publishable key (AD-3, OQ-03) — RLS is the
// enforcement layer (01 S2.2), never a client secret. The `SUPABASE_SECRET_KEY`
// (service_role) is for server-side execution (jobs, relay) — it must never
// reach this package / the app bundle.
// =============================================================================

import { createClient, type SupabaseClient } from '@supabase/supabase-js';

/**
 * Environment surface (03 S2.1 / OQ-03 — values from `.env.local`, never
 * hardcoded; the platform layer injects these at app init).
 */
export interface SupabaseEnv {
  /** `SUPABASE_URL` (project REST/DB URL). */
  supabaseUrl: string;
  /** `SUPABASE_PUBLISHABLE_KEY` (public key, safe in the app bundle). */
  supabasePublishableKey: string;
}

/** The client options (publishable key, no service_role — AD-3). */
export interface SupabaseClientOptions {
  env: SupabaseEnv;
  /**
   * Enable auto session persistence (device-local encrypted storage).
   * Default: `true` — the local-first store IS the device cache (AD-7);
   * a fresh app boot must restore the signed-in user's session so PowerSync
   * can reconnect without re-login.
   */
  persistSession?: boolean;
  /**
   * The PowerSync endpoint (`POWERSYNC_URL`, 03 S8.1). Carried here so the
   * connector factory and the client factory share one env source; the
   * value itself is passed to the connector, not baked into the client.
   */
  powersyncUrl?: string;
}

/**
 * The single construction site for the app's Supabase client (signed-in
 * user scope). One instance per user; on user switch, dispose + rebuild
 * (or rely on the SDK's `auth.onAuthStateChange` persistence).
 */
export function createAuroraSupabaseClient(opts: SupabaseClientOptions): SupabaseClient {
  const { env } = opts;
  return createClient(env.supabaseUrl, env.supabasePublishableKey, {
    auth: {
      persistSession: opts.persistSession ?? true,
      autoRefreshToken: true,
    },
  });
}

/** The relay URL for the PowerSync connector (`POWERSYNC_URL`, 03 S8.1). */
export function powersyncEndpoint(opts: SupabaseClientOptions): string | undefined {
  return opts.powersyncUrl;
}
