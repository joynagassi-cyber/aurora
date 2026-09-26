// =============================================================================
// SupabaseBackendConnector — the PowerSync relay connector (03 S8.1).
//
// `fetchCredentials()` returns the signed-in user's Supabase session JWT
// (`supabase.auth.getSession().access_token`) — the relay is configured with
// `client_auth.supabase: true` (service.yaml, AD-3), which auto-detects the
// Supabase project JWKS (`SUPABASE_JWKS_URL`) + audience `authenticated`.
// No shared secret ever ships in the client (RS256/ES256 keys only).
//
// `uploadData()` writes local CRDT/OR-Set mutations back to Supabase through
// the RLS policies (01 S2.2: `user_id = auth.uid()`), with the frozen error
// strategy (03 S5.1, S5.5.6):
//   - transient (network / 5xx)   → `throw` : PowerSync backs off + retries;
//   - permanent (RLS `42501`, constraint) → `complete()` + log: skip so the
//     upload queue never stalls (4xx blocks the queue permanently).
//
// `transaction.complete()` is MANDATORY on both paths — without it
// `getNextCrudTransaction()` returns the same transaction forever.
// =============================================================================

import type { SupabaseClient } from '@supabase/supabase-js';
// Type-only vendor imports (AD-1: types stay compile-time in this adapter;
// `@powersync/common` runtime classes are only present in the Capacitor
// build — this module must stay loadable under the Node type-stripping
// runner without the vendor runtime).
import type {
  AbstractPowerSyncDatabase,
  PowerSyncBackendConnector,
  PowerSyncCredentials,
} from '@powersync/common';

/**
 * PUT / PATCH / DELETE — the CRUD op tags the upload queue emits
 * (`@powersync/common` `UpdateType`, mirrored locally so the `switch`
 * stays literal-string based and the module stays vendor-runtime-free,
 * AD-1: the reference path must never import vendor values).
 */
const UPDATE_TYPE = {
  PUT: 'PUT',
  PATCH: 'PATCH',
  DELETE: 'DELETE',
} as const;

/**
 * The relay endpoint (03 S8.1, from the platform config — never hardcoded,
 * AD-3: secrets/URLs live in `.env.local`, the app reads them from env).
 */
export interface SupabaseConnectorOptions {
  /** `POWERSYNC_URL` env value (`https://<instance-id>.powersync.journeyapps.com`). */
  endpoint: string;
  /**
   * A lazily resolved Supabase client for the SIGNED-IN user (publishable
   * key, AD-3). A factory so the connector tracks the session (user switch
   * → `disconnectAndClear()` + re-`connect()`, 03 S5.5.6).
   */
  client: () => SupabaseClient;
  /**
   * Local-sink for permanent upload failures (validation / RLS denials).
   * The UI surfaces these via a local-only table or the sync-status banner
   * (03 S3.2 `uploadError`). Never throws — must not block the queue.
   */
  onUploadFailure?: (error: unknown, table: string, id: string) => void;
}

/**
 * The production `PowerSyncBackendConnector` (03 S8.1). One instance per
 * signed-in user; on logout / user switch, call
 * `db.disconnectAndClear()` then build a fresh connector (03 S5.5.6).
 */
export class SupabaseBackendConnectorImpl implements PowerSyncBackendConnector {
  private readonly opts: SupabaseConnectorOptions;
  constructor(opts: SupabaseConnectorOptions) {
    this.opts = opts;
  }

  /**
   * Fresh Supabase session token on every call (PowerSync invokes it every
   * few minutes + on reconnect). A missing session throws — the app MUST
   * sign the user in before `db.connect(connector)` (03 S8.1).
   */
  async fetchCredentials(): Promise<PowerSyncCredentials> {
    const { data: { session }, error } = await this.opts.client().auth.getSession();
    if (error || !session) {
      throw error ?? new Error('No Supabase session — sign in before PowerSync connect');
    }
    return {
      endpoint: this.opts.endpoint,
      token: session.access_token,
      expiresAt: session.expires_at ? new Date(session.expires_at * 1000) : undefined,
    };
  }

  /**
   * One CRUD transaction's local changes → Supabase tables (RLS applies:
   * only this user's rows, `user_id = auth.uid()`, 01 S2.2).
   *
   * Value coercion: the SQLite mirror stores PowerSync types — booleans as
   * 0/1 integers, jsonb (CRDT lists) as text. The live Supabase tables have
   * native `boolean` / `jsonb`, so coerce on write (SDK doc, "Note").
   */
  async uploadData(database: AbstractPowerSyncDatabase): Promise<void> {
    const transaction = await database.getNextCrudTransaction();
    if (!transaction) return;

    let lastTable = '';
    let lastId = '';
    try {
      for (const op of transaction.crud) {
        lastTable = op.table;
        lastId = op.id;
        const coerced = this.coerceForServer(op.opData);
        switch (op.op) {
          case UPDATE_TYPE.PUT:
            await this.upsertRow(op.table, op.id, coerced);
            break;
          case UPDATE_TYPE.PATCH:
            await this.patchRow(op.table, op.id, coerced);
            break;
          case UPDATE_TYPE.DELETE:
            await this.deleteRow(op.table, op.id);
            break;
        }
      }
      // MANDATORY: advance the queue (03 S5.1 — no `complete()` = stall).
      await transaction.complete();
    } catch (error) {
      const isPermanent = this.isPermanentFailure(error);
      if (isPermanent) {
        // RLS denial (42501) / constraint violation: permanent — skip this
        // transaction so the queue keeps flowing; surface to the user.
        this.opts.onUploadFailure?.(error, lastTable, lastId);
        await transaction.complete();
        return;
      }
      // Transient (network / 5xx): throw — PowerSync retries with backoff.
      throw error;
    }
  }

  // ------------------------------------------------------------------------
  // Supabase writes
  // ------------------------------------------------------------------------

  private async upsertRow(table: string, id: string, data: Record<string, unknown>) {
    const { error } = await this.opts.client()
      .from(table)
      .upsert({ ...data, id });
    if (error) throw error;
  }

  private async patchRow(table: string, id: string, data: Record<string, unknown>) {
    const { error } = await this.opts.client()
      .from(table)
      .update(data)
      .eq('id', id);
    if (error) throw error;
  }

  private async deleteRow(table: string, id: string) {
    const { error } = await this.opts.client()
      .from(table)
      .delete()
      .eq('id', id);
    if (error) throw error;
  }

  /**
   * Mirror → live value coercion (SQLite stringly-typed → Postgres native):
   * - columns declared `column.integer` for Postgres booleans arrive as
   *   0/1 → `true`/`false` (the SDK note: "convert before writing").
   * - jsonb OR-Set columns (`crdt_added`/`crdt_removed`, `tags`, …) are
   *   stored as text on the mirror → parse back to objects (no-op when
   *   already JSON-safe).
   */
  private coerceForServer(opData?: Record<string, unknown>): Record<string, unknown> {
    if (!opData) return {};
    const out: Record<string, unknown> = { ...opData };
    for (const key of Object.keys(out)) {
      const v = out[key];
      if (v === undefined) continue;
      if (key === 'crdt_added' || key === 'crdt_removed') {
        out[key] = this.parseJsonMaybe(v);
      } else if (
        // Known boolean mirror columns (03 S4.2 / live schema)
        (key === 'active' || key === 'completed' || key === 'done') &&
        (v === 0 || v === 1)
      ) {
        out[key] = v === 1;
      } else if (
        // numeric mirror columns arriving as strings
        (key === 'priority' || key === 'rating' || key === 'size' || key === 'attempts') &&
        typeof v === 'string' &&
        v !== ''
      ) {
        const n = Number(v);
        if (!Number.isNaN(n)) out[key] = n;
      }
    }
    return out;
  }

  private parseJsonMaybe(v: unknown): unknown {
    if (typeof v !== 'string') return v;
    try {
      return JSON.parse(v);
    } catch {
      return v; // not JSON (plain scalar) — leave as-is
    }
  }

  /**
   * Permanent-failure detector (03 S5.1, S5.5.6): RLS denials surface as
   * Postgres `42501` (insufficient_privilege) through the PostgREST client;
   * constraint / validation errors carry Postgres codes in the 2xxx range.
   * Everything else (network, 5xx, RLS-unreachable) is transient.
   */
  private isPermanentFailure(error: unknown): boolean {
    const code = (error as { code?: string; message?: string } | null)?.code;
    if (typeof code === 'string') {
      if (code === '42501' || code === '23505' || code === '23503' || code === '23514' || code === '22P02') {
        return true;
      }
    }
    // Supabase-js encodes some 4xx payloads as plain Error with the status in
    // the message ("400"…) — treat an explicit 4xx mention as permanent too.
    const msg = String((error as { message?: unknown })?.message ?? '');
    return /^4\d\d/.test(msg);
  }
}

/**
 * Factory — the single construction site for a user-bound connector
 * (03 S8.1). `createClient` returns the Supabase client for the signed-in
 * user (from `supabase.ts` in this package, publishable key only, AD-3).
 */
export function createSupabaseBackendConnector(
  opts: SupabaseConnectorOptions,
): PowerSyncBackendConnector {
  return new SupabaseBackendConnectorImpl(opts);
}
