// =============================================================================
// SyncStatus / SyncState — the sync state surface for the UI (03 S3.2).
//
// States (frozen): 'idle' | 'syncing' | 'conflict' | 'degraded' (+ 'pending'
// in the task brief = a local write has been queued and upsync has not
// started yet; it is the sub-state of `idle` before the first upsync tick).
//
// The UI SURFACES this (read-only) to render the 5th canonical UX state
// `offline` (02 S7 / AD-7: offline = first-class state, not a failure mode).
// It never ACTS on it: network calls live exclusively in the sync engine
// (PowerSync), never in the render path (02 S9).
//
// `conflict` is reachable ONLY on an un-mergeable CRDT type collision
// (residual case, 03 S3.2 comment): scalar server-wins is silent, never
// surfaced. The queue is never lost (AD-7/F-03) — a stuck `conflict` keeps
// the pending mutations and the alert until resolution.
// =============================================================================

export type SyncState = 'pending' | 'syncing' | 'idle' | 'conflict' | 'degraded';

export interface SyncStatus {
  /** network detection (02 S7, @capacitor/network via packages/platform) */
  online: boolean;
  /** local mutations awaiting upstream (03 S3.2) */
  pendingUpstream: number;
  /** last successful full sync (upstream drained + downstream applied) */
  lastSyncAt: Date | null;
  state: SyncState;
}

export interface SyncStatusChange {
  from: SyncState;
  to: SyncState;
  at: Date;
}

/** A partial status update — `lastSyncAt` preserved unless given. */
type PartialSyncUpdate = {
  state: SyncState;
  pendingUpstream?: number;
  lastSyncAt?: Date | null;
};

/**
 * The state machine. Pure logic — no vendor imports, zero network, so it
 * is unit-testable under the Node type-stripping runner (03 S7 tests).
 *
 * Transition rules (03 S3.2 / S5.5 / S6):
 *  - offline: the store keeps working (local reads + queued writes, AD-7).
 *  - online + queued mutations: `pending` -> `syncing` on upsync start.
 *  - upsync fails transiently: `syncing` -> `degraded` (bounded retry,
 *    AD-5; queue persists, never dropped — 03 S6).
 *  - CRDT un-mergeable collision: any state -> `conflict` (alert, retry
 *    the lossless merge; residual only, 03 S3.2).
 *  - queue drained + downstream applied: -> `idle`, `lastSyncAt` set.
 */
export class SyncStatusMachine {
  private state: SyncState = 'idle';
  private online = true;
  private pendingUpstream = 0;
  private lastSyncAt: Date | null = null;
  private readonly listeners = new Set<(s: SyncStatus) => void>();
  /** history for diagnostics / observability (03 S6: observable) */
  readonly history: SyncStatusChange[] = [];

  snapshot(): SyncStatus {
    return {
      online: this.online,
      pendingUpstream: this.pendingUpstream,
      lastSyncAt: this.lastSyncAt,
      state: this.state,
    };
  }

  subscribe(cb: (s: SyncStatus) => void): () => void {
    this.listeners.add(cb);
    return () => {
      this.listeners.delete(cb);
    };
  }

  private set(update: PartialSyncUpdate): void {
    const prev = this.state;
    this.state = update.state;
    if (update.pendingUpstream !== undefined) this.pendingUpstream = update.pendingUpstream;
    if (update.lastSyncAt !== undefined) this.lastSyncAt = update.lastSyncAt;
    if (prev !== update.state) {
      this.history.push({ from: prev, to: update.state, at: new Date() });
    }
    const s = this.snapshot();
    for (const l of [...this.listeners]) l(s);
  }

  /** Network detection (03 S5.5.1, @capacitor/network via platform). */
  setOnline(online: boolean): void {
    this.online = online;
    if (online && this.pendingUpstream > 0 && this.state !== 'degraded') {
      // reconnect with a non-empty queue: kick the upsync (03 S5.5.2)
      this.set({ state: 'syncing', pendingUpstream: this.pendingUpstream });
    }
  }

  /** Reconcile the pending counter with the engine's authoritative queue
   *  WITHOUT a state transition (used between upsync batches, 03 S5.1.4). */
  reconcilePending(count: number): void {
    this.pendingUpstream = count;
  }

  /**
   * A local mutation was applied + queued (03 S5.1.1 immediate apply) and
   * acknowledged at the store level: increment pending, and if offline
   * stay in `pending`; if online transition to `syncing` (an upsync tick
   * is due, 03 S5.5.2).
   */
  mutationQueued(): void {
    this.pendingUpstream += 1;
    const target: SyncState = this.online ? 'syncing' : 'pending';
    this.set({ state: target, pendingUpstream: this.pendingUpstream });
  }

  /** Upsync start / batch sent (03 S5.1.4). */
  upsyncStarted(): void {
    if (!this.online) return;
    this.set({ state: 'syncing', pendingUpstream: this.pendingUpstream });
  }

  /** A batch of n mutations was acknowledged upstream (deduplicated, 03 S5.1.3). */
  upsyncAcked(count: number): void {
    this.pendingUpstream = Math.max(0, this.pendingUpstream - count);
    const drained = this.pendingUpstream === 0;
    this.set({
      state: drained ? 'idle' : 'syncing',
      pendingUpstream: this.pendingUpstream,
      lastSyncAt: drained ? new Date() : this.lastSyncAt,
    });
  }

  /** Transient upsync failure (03 S6: bounded retry, queue persists). */
  upsyncFailed(): void {
    this.set({ state: 'degraded', pendingUpstream: this.pendingUpstream });
  }

  /** Residual un-mergeable CRDT collision (03 S3.2: the only `conflict`). */
  crdtCollision(): void {
    this.set({ state: 'conflict', pendingUpstream: this.pendingUpstream });
  }

  /** Collision resolved / retry drain finished (03 S3.2). */
  conflictResolved(): void {
    const target: SyncState = this.pendingUpstream > 0 ? 'syncing' : 'idle';
    this.set({ state: target, pendingUpstream: this.pendingUpstream });
  }

  /** Re-sync after long outage complete (03 S5.5.4). */
  resyncComplete(): void {
    this.pendingUpstream = 0;
    this.set({ state: 'idle', pendingUpstream: 0, lastSyncAt: new Date() });
  }

  /** Sync engine backoff re-attempt started (degraded -> syncing). */
  retryStarted(): void {
    this.set({ state: 'syncing', pendingUpstream: this.pendingUpstream });
  }
}
