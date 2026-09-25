/**
 * RemoteNotificationAdapter — OneSignal (04 §3.2, AD-1, AD-3).
 *
 * The SERVER-STATE-DRIVEN half of the notification split rule (04 §3.4):
 * OneSignal owns server-driven pushes (reminders, coach check-ins, job
 * completions) via the `fn-notifications` Edge Function. The app side
 * holds ONLY the `appKey` (in `capacitor.config.ts` — AD-3: the server
 * key / any secret never ships to the device).
 *
 * Vendor boundary (AD-1): OneSignal's Cordova/React SDK is NOT published
 * on the npm registry in this environment (04 §3.1 whitelists
 * `@onesignal/cordova` / `@onesignal/react`; neither resolves here).
 * This adapter therefore exposes the typed port surface and delegates to
 * a native bridge hook — `window.Capacitor` OneSignal plugin when
 * present on the device — so the app shell stays decoupled and the
 * split-rule test (04 §7: never both for the same object) stays
 * enforceable from a single typed seam.
 */
import { Capacitor, type Plugin } from '@capacitor/core';

export interface OneSignalNotification {
  id: string;
  title: string;
  body?: string;
  deepLink?: string;
  category?: string;
  scheduledFor?: string;
}

export interface RemoteNotificationAdapter {
  /**
   * Initialize OneSignal with the appKey read from `capacitor.config.ts`
   * (AD-3: appKey only). No-ops in the browser dev path.
   */
  init(): Promise<void>;
  /** subscribe to foreground notification events (04 §3.2). */
  onForegroundNotification(cb: (n: OneSignalNotification) => void): Promise<() => void>;
  /** read / set the push subscription state (04 §3.2). */
  getSubscribed(): Promise<boolean>;
  setSubscribed(sub: boolean): Promise<void>;
}

type OneSignalBridge = Plugin & {
  init?: (opts: { appId: string }) => Promise<void>;
  isNotificationPermissionGranted?: () => Promise<{ value: boolean }>;
  subscribe?: () => Promise<void>;
  unsubscribe?: () => Promise<void>;
};

export function createRemoteNotificationAdapter(appKey: string): RemoteNotificationAdapter {
  const native = Capacitor.isNativePlatform();
  // The OneSignal plugin is registered under `OneSignal` by the native
  // Cordova plugin (04 §3.1 whitelist). Resolve it via the generic
  // Capacitor bridge seam so the typed port surface is stable even
  // though the SDK is not importable.
  const bridge = Capacitor.isPluginAvailable('OneSignal')
    ? (Capacitor as unknown as { registerPlugin: (n: string) => Plugin }).registerPlugin(
        'OneSignal',
      ) as OneSignalBridge
    : undefined;

  return {
    async init() {
      if (!native || !bridge?.init) return;
      await bridge.init({ appId: appKey });
    },
    async onForegroundNotification(cb) {
      if (!native || !bridge) return () => {};
      const sub = Capacitor.addListener?.(
        'OneSignal',
        'foregroundNotification',
        (n) => cb(n as unknown as OneSignalNotification),
      );
      return () => {
        if (sub?.remove) sub.remove();
      };
    },
    async getSubscribed() {
      if (!native || !bridge?.isNotificationPermissionGranted) return true;
      const { value } = await bridge.isNotificationPermissionGranted();
      return value;
    },
    async setSubscribed(sub) {
      if (!native) return;
      if (sub) await bridge?.subscribe?.();
      else await bridge?.unsubscribe?.();
    },
  };
}
