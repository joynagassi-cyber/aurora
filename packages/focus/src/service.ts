/**
 * FocusService — the in-app FocusController implementation (spec
 * S4/S10).
 *
 * Wires the pure pieces of this package (timer state machine, bilan
 * score) to the DPC surface and produces `FocusSessionBilan` on end.
 *
 * Boundaries (chevauchement rules):
 * - this module NEVER writes `focus_sessions` / `focus_bilan` rows
 *   (AD-7 single-writer = ATLAS/Productivity). The service accepts a
 *   `repo` seam so the caller injects the ATLAS-owned writers.
 * - The DPC surface (device-policy-manager calls, API 29+) is the
 *   `FocusControllerDpc` port declared in @aurora/platform
 *   (custom native module, Foundation owner — AD-1: no vendor, no
 *   DOM here; this package stays vendor-free and declares its own
 *   minimal port so the contract layer has no downward dependency on
 *   the platform package).
 *
 * Lifecycle (spec S4, v1.8):
 *   startSession: open session (persist via the repo seam)
 *     -> precheckBlocklist -> applyBlocklist(true) (blocking mode only,
 *        when isBlockingAvailable() = true)
 *     -> timer markActive
 *   endSession: timer end -> applyBlocklist(false) (total restore, S7)
 *     -> reduceNotifications(false) -> FocusSessionBilan (score G-H1).
 *
 * Detection (S2/S10): `isBlockingAvailable()` = DPC active (device
 * owner) AND the blocklist pre-check passed. False -> restriction
 * fallback; the UI NEVER shows a block CTA in that case (04 S4.2).
 */
import type {
  FocusSession,
  FocusSessionBilan,
  OrSetValue,
} from '@aurora/domain';
import type {
  FocusPrecheck,
  FocusSessionOptions,
} from './controller.ts';
import { computeFocusBilanScore } from './bilan.ts';
import {
  beginStart,
  endSession as endTimer,
  markActive,
  markInterrupted,
  newFocusTimer,
  type FocusTimerConfig,
  type FocusTimerState,
} from './timer.ts';

/**
 * Minimal DPC surface used by the service (mirrors
 * @aurora/platform's `FocusControllerDpc` — declared locally so the
 * contract package never depends on the platform package; the
 * platform `DpcAdapter` satisfies this shape structurally).
 */
export interface FocusDpcSurface {
  precheckBlocklist(names: string[]): Promise<FocusPrecheck>;
  applyBlocklist(
    names: string[],
    on: boolean,
  ): Promise<{ applied: string[]; rejected: { pkg: string; reason: string }[] }>;
}

/** Persistence seam — the ATLAS/Productivity writers (AD-7). */
export interface FocusSessionRepo {
  open(session: FocusSession): Promise<void>;
  close(sessionId: string, bilan: FocusSessionBilan): Promise<void>;
}

/** Notification reduction seam (04 S3.4, platform adapters). */
export interface FocusNotificationReducer {
  reduceForFocus(on: boolean): Promise<void>;
}

export interface FocusServiceConfig {
  /** the DPC implementation (platform `createDpcAdapter(bridge, pkg)`) */
  dpc: FocusDpcSurface;
  /** DETECTION: true when the device is provisioned as Aurora's owner */
  isDpcActive(): Promise<boolean>;
  /** timer clock (system time — the persisted row is the SSoT, AD-7) */
  clock: FocusTimerConfig;
  /** session id generator (injectable for tests) */
  newSessionId?(): string;
}

export interface FocusControllerService {
  startSession(opts: FocusSessionOptions): Promise<FocusSession>;
  endSession(): Promise<FocusSessionBilan>;
  reduceNotifications(on: boolean): Promise<void>;
  isBlockingAvailable(): Promise<boolean>;
  precheckBlocklist(names: string[]): Promise<FocusPrecheck>;
  applyBlocklist(
    names: string[],
    on: boolean,
  ): Promise<{ applied: string[]; rejected: { pkg: string; reason: string }[] }>;
  /** crash/reboot: the boot-receiver (platform) drives this. */
  onInterrupted(reason: 'crash' | 'reboot'): Promise<void>;
  /** the live timer state (the UI ticks; kills lose nothing — SSoT row). */
  timer(): FocusTimerState | null;
}

function defaultSessionId(): string {
  const t = Date.now().toString(36).padStart(8, '0');
  let r = '';
  for (let i = 0; i < 8; i++) {
    r += Math.floor(Math.random() * 16).toString(16);
  }
  return `${t}${r}`.toUpperCase();
}

/**
 * Build the FocusController service.
 */
export function createFocusService(
  cfg: FocusServiceConfig,
  repo: FocusSessionRepo,
  reducer: FocusNotificationReducer,
): FocusControllerService {
  let timer: FocusTimerState | null = null;
  let session: FocusSession | null = null;
  /** the exact suspension set applied (systemStateSnapshot, spec S6). */
  let snapshot: string[] = [];

  const newId = cfg.newSessionId ?? defaultSessionId;

  async function startSession(opts: FocusSessionOptions): Promise<FocusSession> {
    const nowMs = cfg.clock.now();
    const nowIso = new Date(nowMs).toISOString();
    const s: FocusSession = {
      id: newId(),
      userId: opts.userId,
      startedAt: nowIso,
      mode: opts.mode,
      plannedDurationSec: opts.plannedDurationSec,
      blockProfile: opts.blockProfile,
      linkedTaskIds: (opts.taskIds ?? []).map(
        (v): OrSetValue => ({ v, ts: nowMs, c: 'focus' }),
      ),
      createdAt: nowIso,
      updatedAt: nowIso,
    };
    timer = markActive(
      beginStart(newFocusTimer(opts.plannedDurationSec ?? 0)),
      cfg.clock,
    );
    await repo.open(s);
    // Aurora's own notifications reduced for the session (04 S3.4).
    await reducer.reduceForFocus(true);
    session = s;
    return s;
  }

  async function endSession(): Promise<FocusSessionBilan> {
    if (!session || !timer) {
      throw new Error('FocusService: no active focus session');
    }
    const settled = endTimer(timer, cfg.clock, 'manual');
    const plannedMin = Math.round((session.plannedDurationSec ?? 0) / 60);
    const actualMin = Math.round(settled.activeSec / 60);
    // total restore (spec S7): Aurora un-suspends exactly its snapshot.
    if (snapshot.length > 0) {
      await cfg.dpc.applyBlocklist(snapshot, false);
      snapshot = [];
    }
    await reducer.reduceForFocus(false);
    const bilan: FocusSessionBilan = {
      id: `${session.id}-bilan`,
      userId: session.userId,
      focusSessionId: session.id,
      completedAt: new Date(cfg.clock.now()).toISOString(),
      plannedDurationSec: session.plannedDurationSec,
      actualDurationSec: settled.activeSec,
      interruptions: 0,
      metrics: {
        score: computeFocusBilanScore({
          plannedMinutes: plannedMin,
          actualMinutes: actualMin,
          interruptions: 0,
        }),
      },
    };
    await repo.close(session.id, bilan);
    timer = null;
    session = null;
    return bilan;
  }

  return {
    startSession,
    endSession,
    reduceNotifications(on) {
      return reducer.reduceForFocus(on);
    },
    async isBlockingAvailable() {
      // DETECTION (S2/S10): the DPC is operational = device-owner state.
      // Pre-check rejection handling belongs to precheckBlocklist()
      // (the UI excludes non-suspendable packages before starting).
      return cfg.isDpcActive();
    },
    precheckBlocklist(names) {
      return cfg.dpc.precheckBlocklist(names);
    },
    async applyBlocklist(names, on) {
      const res = await cfg.dpc.applyBlocklist(names, on);
      // the snapshot IS the applied set (systemStateSnapshot, spec S6):
      // S7 restoration discipline — Aurora restores what it suspended.
      snapshot = on ? res.applied : [];
      return res;
    },
    async onInterrupted(reason: 'crash' | 'reboot') {
      // Boot receiver (platform) calls this after reading the session
      // row; default restore = un-suspend the snapshot (spec S7).
      if (timer) {
        timer = markInterrupted(timer, reason);
      }
      if (snapshot.length > 0) {
        await cfg.dpc.applyBlocklist(snapshot, false);
        snapshot = [];
      }
    },
    timer() {
      return timer;
    },
  };
}
