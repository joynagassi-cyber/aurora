/**
 * DPC (Device Policy Controller) layer — types + the FocusControllerDpc
 * port (spec S10). Android-specific: setPackagesSuspended is API 29+
 * and requires Aurora to be the device owner (v1.8 candidate, spec S0).
 *
 * The port is declared here in @aurora/platform because it IS the
 * platform layer (custom native module, Foundation owner). Apps and
 * domain depend on this interface; the native binding (Capacitor
 * custom plugin) implements `DpcBridge`.
 */

/** Per-package result of the suspendability precheck (spec S4/S9.2). */
export interface PrecheckPackage {
  packageName: string;
  suspendable: boolean;
  /**
   * Reason when not suspendable — 'system_package' | 'active_launcher'
   * | 'default_dialer' | 'aurora_protected' | ... (OQ-17 matrix).
   */
  rejectReason?: string;
}

/** Aggregate precheck result for a candidate blocklist. */
export interface BlocklistPrecheck {
  ok: boolean;
  packages: PrecheckPackage[];
  /** true when every package is suspendable */
  allSuspendable: boolean;
  /** packages rejected by the platform, with their reason */
  rejected: { pkg: string; reason: string }[];
}

/** Result of an apply/restore call. */
export interface DpcSuspendResult {
  /** packages the platform actually suspended / un-suspended */
  applied: string[];
  /** packages the platform refused, with the reason */
  rejected: { pkg: string; reason: string }[];
}

/**
 * `DpcBridge` — the native surface the Capacitor custom plugin binds.
 * Everything here is a DevicePolicyManager call (API 29+, device owner).
 */
export interface DpcBridge {
  /** true when Aurora reports itself as the device owner (spec S2) */
  isDpcActive(): Promise<boolean>;
  /** suspend / un-suspend the exact package set (spec S4/S7) */
  setPackagesSuspended(
    packageNames: string[],
    suspended: boolean,
  ): Promise<DpcSuspendResult>;
  /** current system state — packages the system has suspended */
  getPackagesSuspended(): Promise<string[]>;
  /** per-package suspendability precheck (spec S9.2 matrix, OQ-17) */
  precheckSuspendability(
    packageNames: string[],
  ): Promise<PrecheckPackage[]>;
}

/**
 * `FocusControllerDpc` — v1.8 additive extension of the FocusController
 * contract (spec S10). Additive per the Consistency Conventions; the
 * base contract (startSession/endSession/reduceNotifications/
 * isBlockingAvailable) stays unchanged (04 S4.2).
 */
export interface FocusControllerDpc {
  /** per-package suspendable/reason report for a candidate blocklist */
  precheckBlocklist(names: string[]): Promise<BlocklistPrecheck>;
  /**
   * apply/restore the suspension set. `on=false` = total restore
   * (spec S7 restoration discipline: Aurora restores what Aurora
   * suspended).
   */
  applyBlocklist(
    names: string[],
    on: boolean,
  ): Promise<{ applied: string[]; rejected: { pkg: string; reason: string }[] }>;
}
