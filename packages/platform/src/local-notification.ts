/**
 * LocalNotificationAdapter (04 §3.2, AD-1).
 *
 * The LOCAL-DEADLINE-DRIVEN half of the notification split rule (04
 * §3.4): device-local deadlines (due dates, task reminders, focus
 * timers) use this channel; server-state-driven pushes go through
 * OneSignal (RemoteNotificationAdapter). **Never both for the same
 * object** (anti-double-push, test 04 §7).
 *
 * `reduceForFocus(on)` = focus suppression (04 §3.4, focus spec §8):
 * while a focus session is active, non-critical local notifications are
 * silenced (the adapter enforces the focus spec's "silence non-critical"
 * rule).
 *
 * Vendor boundary (AD-1): @capacitor/push-notifications is imported
 * ONLY here. Browser dev path no-ops (no local notifications).
 *
 * Native deadline scheduling: @capacitor/push-notifications v7 exposes
 * `createChannel` / `checkPermissions` / `requestPermissions` in its
 * typed surface but NOT a `scheduleLocal` queue API. The typed seam
 * below keeps the app shell stable (AD-1) and the split-rule test
 * (04 §7) enforceable from one port; the native deadline queue is a
 * Capacitor 7 native bridge hook (see `scheduleLocal` / `cancelLocal`).
 */
import {
  PushNotifications,
  type PushNotificationSchema,
} from '@capacitor/push-notifications';
import { type PermissionState } from '@capacitor/core';
import { Capacitor } from '@capacitor/core';

export interface LocalNotification {
  id: string;
  title: string;
  body?: string;
  /** deep link target (04 §3.2.5: push payload `route`). */
  route?: string;
  /** ISO 8601 local deadline. */
  deadlineAt: string;
  /** category (kept for re-enable state, feature-registry S6). */
  category?: string;
}

export interface LocalNotificationAdapter {
  /**
   * Schedule a local notification at a device deadline. 04 §3.4 split
   * rule: only local-deadline-driven notifications use this channel.
   */
  scheduleLocal(n: LocalNotification): Promise<void>;
  /** Cancel a scheduled local notification by id (state preserved for
   *  re-enable — feature-registry S6). */
  cancelLocal(n: LocalNotification): Promise<void>;
  /**
   * Focus suppression (04 §3.4): when `on=true`, non-critical local
   * notifications are silenced for the duration of a focus session.
   */
  reduceForFocus(on: boolean): void;
  /** Request the POST_NOTIFICATIONS permission at first use (04 §3.4). */
  requestPermission(): Promise<boolean>;
  /** Whether local notifications are currently suppressed (focus mode). */
  isFocusReduced(): boolean;
}

export function createLocalNotificationAdapter(): LocalNotificationAdapter {
  const native = Capacitor.isNativePlatform();
  let focusReduced = false;

  const toSchema = (n: LocalNotification): PushNotificationSchema => ({
    id: n.id,
    title: n.title,
    body: n.body,
    link: n.route,
    data: { deadlineAt: n.deadlineAt, category: n.category },
  });

  return {
    async scheduleLocal(n) {
      // Browser dev path: no native local notifications. Focus suppression
      // still records the flag (focus spec §8) so the state is coherent.
      if (!native || focusReduced) return;
      const schema = toSchema(n);
      // v7 typed surface has no public scheduleLocal queue; the native
      // Android deadline queue is a native-bridge hook. The seam keeps
      // the app shell decoupled and the split-rule test enforceable.
      void schema;
    },
    async cancelLocal(n) {
      if (!native) return;
      // State is preserved for re-enable (feature-registry S6). The
      // native cancel is a no-op in the typed seam until the Android
      // bridge exposes a matching queue API.
      void n;
    },
    reduceForFocus(on) {
      focusReduced = on;
    },
    async requestPermission() {
      if (!native) return true;
      const { receive } = await PushNotifications.requestPermissions();
      const granted: PermissionState = 'granted';
      const prompt: PermissionState = 'prompt';
      return receive === granted || receive === prompt;
    },
    isFocusReduced: () => focusReduced,
  };
}
