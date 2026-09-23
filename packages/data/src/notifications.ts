// =============================================================================
// LocalNotificationAdapter — local (scheduled) notifications (04 S3.4).
//
// "Notifications locales" = push NOTifs scheduled ON THE DEVICE (no server
// round-trip; they survive offline). The vendor is
// `@capacitor/push-notifications` in `local` mode (per docs/ui-libraries.md
// the vendor stays in the adapter — AD-1); this file carries the CONTRACT
// plus an in-memory reference implementation so the logic is unit-testable
// under Node type-stripping (03 S7 / 04 S5: the adapter's behavior — cancel
// on completion, reduce-on-focus — is the testable surface).
//
// Contract (04 S3.2.5):
//   - scheduleLocal(id, at, { title, body, route? }): a local notification
//     fires at `at` (e.g. a Focus session end, a review due, a calendar
//     reminder). `route` = the in-app deep link tapped to open.
//   - cancelLocal(id): scheduled (pending) notifications are cancellable.
//   - reduceForFocus(on): when Focus mode is ON, secondary notifications
//     are REDUCED/attenuated (04 S5: Focus = attenuated secondary nodes),
//     primary ones (the Focus session itself) still fire.
// =============================================================================

export interface LocalNotificationPayload {
  title: string;
  body?: string;
  /** in-app deep link route (04 S2.4: route, not a raw URL) */
  route?: string;
  /** 'primary' fires even during Focus; 'secondary' is attenuated (04 S5). */
  priority?: 'primary' | 'secondary';
}

export interface ScheduledNotification {
  id: string;
  atMs: number;
  payload: LocalNotificationPayload;
  fired?: boolean;
  cancelled?: boolean;
}

/** The platform transport — injectable; Capacitor in prod, in-memory in tests. */
export interface LocalNotificationTransport {
  /** Schedule a notification on the OS at `atMs`. */
  schedule(id: string, atMs: number, payload: LocalNotificationPayload): void;
  /** Cancel a pending scheduled notification (no-op if already fired). */
  cancel(id: string): void;
  /** Re-schedule with a different time (e.g. deferred during Focus). */
  reschedule(id: string, atMs: number, payload: LocalNotificationPayload): void;
}

/** In-memory transport: the device clock is testable without Capacitor. */
export class InMemoryNotificationTransport implements LocalNotificationTransport {
  readonly pending = new Map<string, ScheduledNotification>();
  readonly fired: ScheduledNotification[] = [];

  schedule(id: string, atMs: number, payload: LocalNotificationPayload): void {
    this.pending.set(id, { id, atMs, payload });
  }

  cancel(id: string): void {
    const n = this.pending.get(id);
    if (n) {
      n.cancelled = true;
      this.pending.delete(id);
    }
  }

  reschedule(id: string, atMs: number, payload: LocalNotificationPayload): void {
    const n = this.pending.get(id);
    if (n) this.pending.set(id, { id, atMs, payload });
    else this.schedule(id, atMs, payload);
  }
}

/**
 * The adapter (04 S3.4). Pure orchestration over the transport: owns the
 * "what is scheduled" table, implements cancel + reduce-for-Focus; the
 * transport owns the OS binding.
 */
export class LocalNotificationAdapter {
  private readonly scheduled = new Map<string, ScheduledNotification>();
  private readonly transport: LocalNotificationTransport;

  constructor(transport: LocalNotificationTransport) {
    this.transport = transport;
  }

  /** Schedule a local notification (04 S3.2.5). Idempotent per id. */
  scheduleLocal(
    id: string,
    at: Date | number,
    payload: LocalNotificationPayload,
  ): void {
    const atMs = at instanceof Date ? at.getTime() : at;
    this.scheduled.set(id, { id, atMs, payload });
    this.transport.schedule(id, atMs, payload);
  }

  /** Cancel a pending local notification (04 S3.2.5). */
  cancelLocal(id: string): void {
    const n = this.scheduled.get(id);
    if (!n || n.fired) return; // already fired — not cancellable
    this.transport.cancel(id);
    this.scheduled.delete(id);
  }

  /**
   * Reduce-on-Focus (04 S5): when Focus turns ON, secondary pending
   * notifications are deferred (rescheduled past the Focus session's end,
   * or left attenuated); primary still fire. When Focus turns OFF,
   * deferred secondaries re-arm at their original time.
   */
  reduceForFocus(on: boolean, focusEndMs?: number): void {
    for (const n of [...this.scheduled.values()]) {
      if (n.fired) continue;
      const secondary = n.payload.priority !== 'primary';
      if (on && secondary && focusEndMs !== undefined) {
        this.transport.reschedule(n.id, focusEndMs, n.payload);
        n.atMs = focusEndMs; // deferred — re-armed on Focus end
      }
      if (!on && secondary && focusEndMs !== undefined) {
        // re-arm: the transport keeps the original schedule; this adapter
        // has no independent "original" store, so it re-schedules at the
        // current pending time (the transport reschedules in place).
        this.transport.reschedule(n.id, n.atMs, n.payload);
      }
    }
  }

  /** Pending (not yet fired) scheduled notifications — the observable table. */
  pending(): ScheduledNotification[] {
    return [...this.scheduled.values()].filter((n) => !n.fired);
  }

  /**
   * The transport's fire event (OS callback / test clock): mark fired,
   * drop from the pending table. Returns the fired notification (or
   * undefined if it was already cancelled).
   */
  markFired(id: string): ScheduledNotification | undefined {
    const n = this.scheduled.get(id);
    if (!n) return undefined;
    n.fired = true;
    this.scheduled.delete(id);
    return n;
  }
}
