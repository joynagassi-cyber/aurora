/**
 * OneNotifications module — OneSignal server client + split rules
 * (04 §3.4, mission §49 "Notification system — complete picture").
 *
 * Normative split (overview.md §11):
 *   - server-state-driven → OneSignal push (this module; the server key
 *     lives ONLY here / in fn-notifications, 04 §3.2.5, anti-leak
 *     test 04 §7.2e: the server key is NEVER in the mobile bundle).
 *   - local-deadline-driven → Capacitor local notifications (device
 *     side; `scheduleLocal` marker, §3.2.5).
 *   **NEVER both for the same object** (anti-double-push, 04 §7):
 *   `decideChannel()` is the single decision point; a notification
 *   request is routed to EXACTLY one of {push, local, in-app}, and
 *   `NotificationPlan` records that decision so the UI layer can
 *   assert single-channel delivery.
 *
 * OneSignal key split (04 §3.2.5): the per-app `appKey` (allowed in
 * capacitor.config.ts, owner Foundation) is distinct from the
 * REST API key (server-only, env, never in the bundle).
 *
 * Vendor SDK isolation (AD-1): plain `fetch` to the OneSignal REST
 * v0.1 notifications endpoint; the adapter degrades to
 * `{accepted:false, reason:'onesignal_not_configured'}` when the key
 * is missing (AD-1 last paragraph — optional capability, no crash,
 * delivery is best-effort).
 */
import type {
  IntegrationsState,
  NotificationPreference,
} from '@aurora/domain';

/** One delivery channel — the split target (overview.md §11). */
export type NotificationChannel = 'push' | 'local' | 'in-app';

/**
 * The decision a notification request routes to. EXACTLY ONE channel
 * is chosen (anti-double-push, 04 §7): the plan is the artifact a
 * test asserts on.
 */
export interface NotificationPlan {
  /** the single chosen channel */
  channel: NotificationChannel;
  /** server-side delivery target (OneSignal REST key is server-only, AD-3) */
  onesignal?: {
    appId: string;
    userIds: string[];
    title: string;
    body: string;
    deepLink?: string;
    /** quiet-hours deferral: when the push is delayed, this is the
     *  first allowed send time (ADR §13 coaching silence). */
    deliveryTimeForced?: string;
  };
  /** device-side marker: the Capacitor local adapter owns scheduling;
   *  the server MUST NOT also push this object (§3.4, never both). */
  local?: {
    scheduledFor: string;
    title: string;
    body: string;
  };
  /** suppressed instead of delivered */
  suppressed?: 'quiet-hours' | 'disabled' | 'silence-window';
}

/** A notification request (as it flows through the split). */
export interface NotificationRequest {
  userId: string;
  title: string;
  body: string;
  deepLink?: string;
  /** priority vocabulary (overview.md §11: reminder / coach /
   *  job-result / alert). */
  priority: 'reminder' | 'coach' | 'job-result' | 'alert';
  /** local-deadline-driven source? deadline reminders, Focus/Pomodoro
   *  end (04 §2.4/§2.8) → local channel, not push. */
  localDeadline?: string;
  /** now (server time, ISO 8601) */
  nowIso: string;
}

/** Parse "HH:MM-HH:MM" time-of-day windows (AD-13 style quiet hours,
 *  entities-integrations NotificationPreference). */
export function isWithinQuietHours(
  quietHours: string[] | undefined,
  nowIso: string,
): boolean {
  if (quietHours === undefined || quietHours.length === 0) return false;
  const d = new Date(nowIso);
  const mins = d.getUTCHours() * 60 + d.getUTCMinutes();
  return quietHours.some((win) => {
    const m = /^(\d{2}):(\d{2})-(\d{2}):(\d{2})$/.exec(win);
    if (m === null) return false;
    const from = Number(m[1]) * 60 + Number(m[2]);
    const to = Number(m[3]) * 60 + Number(m[4]);
    // cross-midnight window (e.g. "22:00-07:00")
    return from <= to ? mins >= from && mins < to : mins >= from || mins < to;
  });
}

/**
 * The single channel decision point (anti-double-push, 04 §7).
 *
 * Rules (overview.md §11 + 04 §3.4, in priority order):
 *  1. notification prefs globally disabled → suppressed (state, not
 *     deletion: nothing is queued, the request is simply dropped per
 *     user kill-switch §15).
 *  2. local-deadline-driven request (`localDeadline` set) → LOCAL
 *     channel only. The server never pushes this object. This is the
 *     anti-double-push core: one object, one channel.
 *  3. quiet hours active + a deferred send time exists → push is
 *     deferred to it (deliveryTimeForced), still ONE channel.
 *  4. fallback: in-app (foreground surface, 02 §7) — no push at all.
 *
 * Invariant asserted by tests: a plan NEVER carries both `onesignal`
 * and `local` fields.
 */
export function decideChannel(
  req: NotificationRequest,
  pref: Pick<NotificationPreference, 'enabled' | 'quietHours' | 'channels'>,
): NotificationPlan {
  if (pref.enabled === false) {
    return { channel: 'in-app', suppressed: 'disabled' };
  }
  // Rule 2: local-deadline-driven → local ONLY (§3.4).
  if (req.localDeadline !== undefined) {
    return {
      channel: 'local',
      local: {
        scheduledFor: req.localDeadline,
        title: req.title,
        body: req.body,
      },
    };
  }
  // Rule 3: quiet hours — defer, don't drop (suppression = state, §15).
  if (isWithinQuietHours(pref.quietHours, req.nowIso)) {
    // first allowed send = 07:00 (window end); cross-midnight → +1 day.
    const now = new Date(req.nowIso);
    const deferred = new Date(now);
    deferred.setUTCHours(7, 0, 0, 0);
    if (deferred.getTime() <= now.getTime()) deferred.setDate(deferred.getDate() + 1);
    return {
      channel: 'push',
      suppressed: 'quiet-hours',
      onesignal: {
        appId: '',
        userIds: [req.userId],
        title: req.title,
        body: req.body,
        deepLink: req.deepLink,
        deliveryTimeForced: deferred.toISOString(),
      },
    };
  }
  // Rule 4: in-app surface (foreground). No push — single channel.
  if ((pref.channels ?? []).includes('push') === false) {
    return { channel: 'in-app', suppressed: 'silence-window' };
  }
  return {
    channel: 'push',
    onesignal: {
      appId: '',
      userIds: [req.userId],
      title: req.title,
      body: req.body,
      deepLink: req.deepLink,
    },
  };
}

/**
 * Anti-double-push assertion (04 §7 test): a plan must NEVER carry
 * both a OneSignal delivery and a local schedule for the same object.
 * Exported so the test suite and the UI layer share one check.
 */
export function assertNoDoublePush(plan: NotificationPlan): boolean {
  return !(plan.onesignal !== undefined && plan.local !== undefined);
}

/**
 * OneSignal server client (adapter, AD-1). The REST API key is
 * server-only: it is read from env (04 §3.2.5) and NEVER placed in
 * the mobile bundle (test 04 §7.2e). Degraded delivery: unconfigured
 * or failing → `{accepted:false, reason}` (best-effort, §17).
 */
export class OneSignalServerClient {
  private readonly appId: string;
  private readonly restKey: string;
  private readonly url: string;

  constructor() {
    this.appId = process.env.ONESIGNAL_APP_ID ?? '';
    // Server key — MUST stay server-side (AD-3, 04 §7.2e anti-leak).
    this.restKey = process.env.ONESIGNAL_REST_API_KEY ?? '';
    this.url =
      process.env.ONESIGNAL_URL ?? 'https://onesignal.com/api/v1/notifications';
  }

  /** appKey (device-side, capacitor.config.ts, owner Foundation) —
   *  distinct from the REST key by design (04 §3.2.5 key split). */
  isConfigured(): boolean {
    return this.appId !== '' && this.restKey !== '';
  }

  /** Send a push for a user-ids list. Returns accepted/queued or a
   *  degraded reason — never throws (§17: bounded, best-effort). */
  async send(plan: NotificationPlan): Promise<{
    accepted: boolean;
    reason?: string;
    externalId?: string;
  }> {
    const os = plan.onesignal;
    if (os === undefined) {
      // Not a push plan: the local/in-app channel owns delivery.
      return { accepted: plan.local !== undefined, reason: 'not_push_channel' };
    }
    if (!this.isConfigured()) {
      // AD-1 degrade: optional capability absent, no product break.
      return { accepted: false, reason: 'onesignal_not_configured' };
    }
    // Build the OneSignal v0.1 payload without leaking the REST key into
    // the body (it travels only in the Authorization header, 04 §3.2.5).
    const payload: Record<string, unknown> = {
      app_id: os.appId !== '' ? os.appId : this.appId,
    };
    if (os.userIds.length > 0) payload.include_player_ids = os.userIds;
    if (os.title !== undefined) {
      const alert: Record<string, unknown> = { alert: os.title };
      if (os.body !== undefined) alert.content = os.body;
      if (os.deepLink !== undefined) alert.launch_url = os.deepLink;
      payload.alert = alert;
    }
    if (os.deliveryTimeForced !== undefined) {
      payload.delivery_time_forced = os.deliveryTimeForced;
    }
    const res = await fetch(this.url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Basic ${this.restKey}`,
      },
      body: JSON.stringify(payload),
    });
    if (!res.ok) {
      return { accepted: false, reason: `http_${res.status}` };
    }
    const data = (await res.json().catch(() => ({}))) as {
      id?: string;
    };
    return {
      accepted: true,
      externalId: data.id,
      ...(os.deliveryTimeForced !== undefined
        ? { reason: 'quiet-hours-deferred' }
        : {}),
    };
  }
}

/** Factory: the only way to obtain the server client (AD-1). */
export function createOneSignalServerClient(): OneSignalClient {
  return new OneSignalServerClient();
}

/** The public surface (callers depend on the port, not the vendor
 *  class, AD-1). */
export interface OneSignalClient {
  isConfigured(): boolean;
  send(plan: NotificationPlan): Promise<{
    accepted: boolean;
    reason?: string;
    externalId?: string;
  }>;
}

/**
 * Map a OneSignal delivery outcome to the module's SSoT shape
 * (IntegrationsState, 01 §4.7): the integrations table is written
 * ONLY by this module (AD-7 single-writer) — other modules may read
 * the view, never write the table.
 */
export function toOneSignalIntegrationsState(
  userId: string,
  ok: { accepted: boolean; reason?: string },
): IntegrationsState {
  return {
    userId,
    vendor: 'onesignal',
    connection: 'push',
    status: ok.accepted ? 'connected' : 'disconnected',
    updatedAt: new Date().toISOString(),
  };
}
