/**
 * Focus service wiring (app layer) — the concrete `service` the /focus
 * screen takes as a prop (05 §4.4.2, focus-mode spec S6/S10). Until now
 * the router passed `service={null}`, which left the primary CTA
 * permanently disabled (the screen was inert).
 *
 * The service itself stays in `@aurora/focus` (contract + pure session
 * state machine). This module only supplies its three seams:
 *
 * - DPC surface: `@aurora/platform`'s `createDpcAdapter(bridge, PKG)`
 *   binds the Android custom module (`setPackagesSuspended`, API 29+,
 *   device owner). No native bridge is wired in the app yet, so the
 *   surface is the honest `noDevicePolicy` below: `isBlockingAvailable()`
 *   = false, which IS the documented consumer fallback (04 S4.2 rule —
 *   the block CTA is never offered, the page renders « régime de
 *   restriction »). Nothing pretends system blocking is available.
 * - Session repo: the local `focus_sessions` mirror row (sqlite-schema
 *   owner = productivity) written through the documented local-write
 *   path (`LocalStore.upsert`, 03 S5.1.1 immediate apply). The row is the
 *   SSoT of a running session — an app kill loses nothing (AD-7). It is
 *   marked pending upsync (`local_mutation_id`); the server writer stays
 *   ATLAS/Productivity's (this seam never invents server persistence).
 * - Notification reducer: the platform notification adapters are not
 *   wired in the app yet → a no-op seam (the session still runs; the
 *   reduce-for-focus behaviour arrives with the platform wiring).
 */
import type { FocusSessionBilan } from '@aurora/domain';
import type { FocusControllerDpc } from '@aurora/platform';
import {
  createFocusService,
  type FocusControllerService,
  type FocusSessionRepo,
} from '@aurora/focus';
import type { LocalStore } from '@aurora/data';

/** The mirror entity (sqlite-schema `focus_sessions`, owner productivity). */
const ENTITY = 'focus_sessions';

/**
 * No device-policy surface: without the Android device-owner binding
 * nothing can be suspended. `applyBlocklist(names, false)` reports an
 * empty applied set — the restoration discipline (spec S7) only ever
 * restores what Aurora actually suspended.
 */
const noDevicePolicy: FocusControllerDpc = {
  async precheckBlocklist(names) {
    return {
      ok: false,
      packages: names.map((packageName) => ({
        packageName,
        suspendable: false,
        rejectReason: 'no_device_policy',
      })),
      allSuspendable: false,
      rejected: names.map((pkg) => ({ pkg, reason: 'no_device_policy' })),
    };
  },
  async applyBlocklist(names, on) {
    return {
      applied: [],
      rejected: on
        ? names.map((pkg) => ({ pkg, reason: 'no_device_policy' }))
        : [],
    };
  },
};

/**
 * The `focus_sessions` local write seam. `open` writes the running row
 * (`status: 'active'`); `close` merges the terminal fields + the bilan
 * JSON onto that same row (one writer, one table — AD-7).
 */
function localFocusRepo(store: LocalStore): FocusSessionRepo {
  return {
    async open(session) {
      store.upsert(ENTITY, {
        id: session.id,
        userId: session.userId,
        user_id: session.userId,
        started_at: session.startedAt,
        ended_at: null,
        planned_minutes: Math.round((session.plannedDurationSec ?? 0) / 60),
        actual_minutes: null,
        status: 'active',
        session_bilan: '{}',
        created_at: session.createdAt,
        server_updated_at_ms: 0,
        local_mutation_id: session.id,
        local_ts_ms: Date.now(),
      });
    },
    async close(sessionId: string, bilan: FocusSessionBilan) {
      const row = store.row(ENTITY, sessionId);
      store.upsert(ENTITY, {
        ...(row ?? { id: sessionId }),
        id: sessionId,
        userId: row?.userId ?? bilan.userId,
        ended_at: bilan.completedAt,
        actual_minutes: Math.round((bilan.actualDurationSec ?? 0) / 60),
        status: 'done',
        session_bilan: JSON.stringify(bilan),
        local_ts_ms: Date.now(),
      });
    },
  };
}

/**
 * Build the app Focus service over the injected local store (AD-7: the
 * session row lives on the device; no network on this path).
 */
export function createAppFocusService(
  store: LocalStore,
): FocusControllerService {
  return createFocusService(
    {
      dpc: noDevicePolicy,
      isDpcActive: async () => false,
      // System clock: the persisted row is the SSoT, an app kill or a
      // backgrounded webview keeps the session honest (spec S4).
      clock: { now: () => Date.now() },
    },
    localFocusRepo(store),
    {
      async reduceForFocus() {
        // Platform notification adapter not wired in the app yet.
      },
    },
  );
}
