/**
 * Boot receiver — crash/reboot recovery reconciliation (spec S7).
 *
 * Device policy (suspension state) is SYSTEM state and survives process
 * death + reboot. The BOOT_COMPLETED receiver (native side, custom
 * plugin) invokes this pure reconciliation to decide what to do with
 * the last persisted session row. Default policy = un-suspend
 * everything + offer resume/close to the user (never silent).
 *
 * This module reads ONLY the session row passed in (persisted by
 * ATLAS/Productivity) — it never writes focus_sessions itself
 * (chevauchement rule). The caller applies the returned actions.
 */
import type { DpcBridge } from './dpc.ts';

export type SessionRow = {
  id: string;
  /** 'active' | 'interrupted' | 'completed' | 'restoring' */
  status: string;
  /** the exact package set suspended (systemStateSnapshot, spec S6) */
  systemStateSnapshot: string[];
  endedAt: string | null;
};

export type RecoveryDecision =
  | { action: 'none'; reason: string }
  | { action: 'unsuspend'; packages: string[]; offerResume: boolean }
  | { action: 'unsuspend'; packages: string[]; offerResume: false };

/**
 * Reconcile a persisted session row against the live DPC state.
 *
 * Rules (spec S7):
 * - session row not active (completed/restoring) AND system state
 *   clean → no-op.
 * - session interrupted/active + system still suspending → default
 *   un-suspend everything, offer resume (re-apply suspension).
 * - system already clean → no-op (reboot already restored or the
 *   session ended normally).
 */
export async function reconcileOnBoot(
  session: SessionRow | null,
  bridge: DpcBridge,
): Promise<RecoveryDecision> {
  const systemSuspended = await bridge.getPackagesSuspended();

  if (!session || (session.status !== 'active' && session.status !== 'interrupted')) {
    // Nothing of ours to recover; if the system still has suspensions
    // from a lost session, default = un-suspend (crash path, spec S7).
    if (systemSuspended.length > 0) {
      return { action: 'unsuspend', packages: systemSuspended, offerResume: false };
    }
    return { action: 'none', reason: 'no active/interrupted session; system clean' };
  }

  const toRestore = session.systemStateSnapshot.filter(
    (p) => systemSuspended.includes(p),
  );
  if (toRestore.length === 0) {
    return { action: 'none', reason: 'system already restored (no suspension left)' };
  }
  // Default crash/reboot policy: un-suspend everything, offer resume.
  return { action: 'unsuspend', packages: toRestore, offerResume: true };
}

/**
 * Apply a recovery decision through the bridge (caller owns the
 * follow-up UI: resume/close offer). Returns the applied/rejected
 * result so the caller can log it.
 */
export async function applyRecovery(
  decision: RecoveryDecision,
  bridge: DpcBridge,
): Promise<{ applied: string[]; rejected: { pkg: string; reason: string }[] }> {
  if (decision.action !== 'unsuspend') {
    return { applied: [], rejected: [] };
  }
  const res = await bridge.setPackagesSuspended(decision.packages, false);
  return res;
}
