// =============================================================================
// SyncEngine — the device-side orchestration of upsync/downsync (03 S5.1 /
// S5.2 / S5.5). This is the "PowerSync/Supabase adapter" logic WITHOUT the
// vendor import (03 S5.1.5: the engine owns the network; the UI never does):
// a production build swaps `http` for the PowerSync SDK inside this package
// (AD-1: vendors stay in `packages/data`); the test runner injects an
// in-memory transport.
//
// Offline → online cycle (03 S5.5, F-03):
//   1. offline: local mutations are applied immediately and queued
//      (`queue.enqueue`, 03 S5.1.1); the store keeps working (AD-7).
//   2. online: `run()` drains the queue FIFO by `localMutationId` (ULID,
//      chronological — 03 S5.5.6), in bounded batches (03 S5.5.5),
//      idempotently (acked entries are skipped — 03 S5.1.3 dedup).
//   3. downstream: the transport replies with new rows + deletions; the
//      engine applies them with per-entity server-wins (`applyDownstream`,
//      03 S5.2 / S4.2 rule 3).
//   4. on drain + downstream applied: `resyncComplete` → idle (03 S5.5.4).
//
// Failure: transient errors leave the queue intact (`upsyncFailed` →
// degraded, bounded retry AD-5); the queue is NEVER dropped (03 S6).
// =============================================================================

import type { DownstreamBatch, LocalStore } from './local-store';
import { SyncStatusMachine } from './sync-status';
import type { UpsyncQueue } from './upsync-queue';

/** The transport's upstream acknowledgement (03 S5.1.3). */
export interface UpsyncResponse {
  /** which mutations the server accepted (deduped by `localMutationId`) */
  acked: string[];
  /** downstream rows to apply (03 S5.2) */
  downsync?: DownstreamBatch[];
}

/** The upstream transport — injectable; production = PowerSync/Supabase. */
export interface SyncTransport {
  /** Send one bounded batch upstream. Idempotent: server dedups by the
   *  `localMutationId` carried in each entry (03 S5.5.6, AD-8). */
  upsync(batch: {
    localMutationId: string;
    entity: string;
    id: string;
    ownerModule: string;
    patch: Record<string, unknown>;
    isDelete?: boolean;
    localAppliedAtMs: number;
    attempts: number;
  }[]): Promise<UpsyncResponse>;
}

export interface SyncEngineOptions {
  /** max mutations per upstream request (03 S5.5.5: bounded) */
  batchSize?: number;
}

/**
 * Orchestrates queue → transport → store → status. Pure logic: no vendor,
 * no network, zero timers — so it is fully unit-testable (03 S7).
 */
export class SyncEngine {
  constructor(
    private readonly store: LocalStore,
    private readonly queue: UpsyncQueue,
    private readonly transport: SyncTransport,
    private readonly status: SyncStatusMachine,
    private readonly options: SyncEngineOptions = {},
  ) {}

  /**
   * One upsync tick (03 S5.1.4 / S5.5.2): drain the queue FIFO in bounded
   * batches, apply each batch's downsync, reconcile status.
   *
   * @returns the total number of mutations acknowledged on this tick.
   */
  async run(): Promise<number> {
    const size = this.options.batchSize ?? 500;
    this.status.upsyncStarted();
    let ackedTotal = 0;
    let batch = this.queue.nextBatch(size);
    while (batch.length > 0) {
      this.queue.recordAttempt(batch.map((e) => e.localMutationId));
      try {
        const res = await this.transport.upsync(batch);
        this.queue.ack(res.acked);
        for (const b of res.downsync ?? []) {
          this.store.applyDownstream(b);
        }
        ackedTotal += res.acked.length;
      } catch {
        // transient failure: queue stays intact (03 S6), bounded retry
        // (AD-5) — surface as degraded, keep the pending mutations.
        this.status.upsyncFailed();
        this.status.reconcilePending(this.queue.size());
        return ackedTotal;
      }
      batch = this.queue.nextBatch(size);
    }
    this.queue.pruneAcked();
    this.status.reconcilePending(this.queue.size());
    if (this.queue.isEmpty()) {
      this.status.resyncComplete(); // → idle + lastSyncAt (03 S5.5.4)
    } else {
      this.status.retryStarted();
    }
    return ackedTotal;
  }
}
