/**
 * FocusControllerPort — the Focus Mode contract (04 S4.2 base + v1.8
 * DPC additive, spec S10).
 *
 * 04 S4.2 rule: the UI NEVER shows a block CTA when
 * `isBlockingAvailable()` is false (consumer fallback = restriction
 * only). Under v1.8 the method is DETECTION, not a constant: true when
 * the DPC is operational (device owner) AND the blocklist pre-check
 * passed.
 */
import type {
  FocusNotificationPolicy,
  FocusSession,
  FocusSessionBilan,
} from '@aurora/domain';

/** Options for starting a focus session. */
export interface FocusSessionOptions {
  /** the owner (RLS scope) */
  userId: string;
  /** 'pomodoro' | 'timer' | 'open' */
  mode: 'pomodoro' | 'timer' | 'open';
  /** planned duration in seconds (timer / pomodoro focus block) */
  plannedDurationSec?: number;
  /** block profile id (the user-selected blocklist, spec S1) */
  blockProfile?: string;
  /** linked task ids (03 S4.2) */
  taskIds?: string[];
  /** the notification policy for the session (04 S3.4) */
  notificationPolicy?: FocusNotificationPolicy;
  /**
   * The concentration sound id (focus-mode spec, "sons de concentration").
   * A focused profile picks one of the 15+ catalog sounds; only Aurora
   * may emit notifications during the session (Aurora-only rule).
   */
  focusSound?: string;
  /** Pomodoro pause duration in seconds (the auto-scheduled next block). */
  pomodoroPauseSec?: number;
}

/**
 * Per-package precheck outcome for a blocklist (spec S4/S9.2). Mirrors
 * `@aurora/platform`'s `PrecheckPackage` so the contract stays
 * vendor-free; the platform layer implements it.
 */
export interface FocusPrecheckPackage {
  packageName: string;
  suspendable: boolean;
  rejectReason?: string;
}

/** Aggregate precheck result. */
export interface FocusPrecheck {
  ok: boolean;
  packages: FocusPrecheckPackage[];
  allSuspendable: boolean;
  rejected: { pkg: string; reason: string }[];
}

/**
 * `FocusControllerPort` — the port implemented by the platform DPC
 * layer + the in-app focus service (timer/Pomodoro/blocklist).
 *
 * Base (04 S4.2, unchanged) + v1.8 additive DPC extension. The
 * interface is additive-per-Conventions: consumers may depend on the
 * base four methods; the DPC two are the v1.8 candidate extension
 * (ratify OQ-17 before freezing).
 */
export interface FocusControllerPort {
  // --- base (04 S4.2) ------------------------------------------------------
  /** Open the session, run the pre-check, apply the suspension. */
  startSession(opts: FocusSessionOptions): Promise<FocusSession>;
  /** End the session (manual/expiry), un-suspend the exact set. */
  endSession(): Promise<FocusSessionBilan>;
  /** Reduce Aurora's own notifications (04 S3.4). */
  reduceNotifications(on: boolean): Promise<void>;
  /**
   * v1.8: DETECTION (DPC + pre-check), not a constant. False → the UI
   * falls back to restriction mode and NEVER shows a block CTA.
   */
  isBlockingAvailable(): Promise<boolean>;
  // --- v1.8 additive (spec S10) ------------------------------------------
  /** per-package suspendable/reason report for a candidate blocklist */
  precheckBlocklist(names: string[]): Promise<FocusPrecheck>;
  /** apply/restore the suspension set (on=false = total restore). */
  applyBlocklist(
    names: string[],
    on: boolean,
  ): Promise<{ applied: string[]; rejected: { pkg: string; reason: string }[] }>;
}
