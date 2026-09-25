/**
 * DpcAdapter — concrete FocusControllerDpc bound to a DpcBridge
 * (the Capacitor custom module). Keeps the aurora-protected invariant
 * (spec S3: never suspend its own package) as a second line of
 * defense. No vendor SDKs — only the typed bridge (AD-1).
 */
import type {
  BlocklistPrecheck,
  DpcBridge,
  DpcSuspendResult,
  FocusControllerDpc,
  PrecheckPackage,
} from './dpc.ts';

export class DpcAdapter implements FocusControllerDpc {
  private readonly bridge: DpcBridge;
  private readonly auroraPackageName: string;

  constructor(bridge: DpcBridge, auroraPackageName: string) {
    this.bridge = bridge;
    this.auroraPackageName = auroraPackageName;
  }

  async precheckBlocklist(names: string[]): Promise<BlocklistPrecheck> {
    const results: PrecheckPackage[] = await this.bridge.precheckSuspendability(
      names,
    );
    for (const r of results) {
      if (r.packageName === this.auroraPackageName && r.suspendable) {
        // aurora-protected invariant (spec S3)
        r.suspendable = false;
        r.rejectReason = 'aurora_protected';
      }
    }
    return {
      ok: results.every((r) => r.suspendable),
      packages: results,
      allSuspendable: results.every((r) => r.suspendable),
      rejected: results
        .filter((r) => !r.suspendable)
        .map((r) => ({ pkg: r.packageName, reason: r.rejectReason ?? 'not_suspendable' })),
    };
  }

  async applyBlocklist(
    names: string[],
    on: boolean,
  ): Promise<{
    applied: string[];
    rejected: { pkg: string; reason: string }[];
  }> {
    // Invariant: never suspend the DPC package itself (spec S3).
    const filtered = on
      ? names.filter((n) => n !== this.auroraPackageName)
      : names;
    const res: DpcSuspendResult = await this.bridge.setPackagesSuspended(
      filtered,
      on,
    );
    const rejected =
      !on || res.rejected.length > 0
        ? res.rejected
        : names
            .filter((n) => n === this.auroraPackageName)
            .map((pkg) => ({ pkg, reason: 'aurora_protected' }));
    return { applied: res.applied, rejected };
  }
}

/** Convenience for the app wiring: build the adapter from a bridge. */
export function createDpcAdapter(
  bridge: DpcBridge,
  auroraPackageName: string,
): DpcAdapter {
  return new DpcAdapter(bridge, auroraPackageName);
}
