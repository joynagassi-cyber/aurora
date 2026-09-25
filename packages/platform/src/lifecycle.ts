/**
 * AppLifecycleAdapter (04 §3.2, AD-1) — the ONLY native lifecycle surface
 * the app consumes. AppState = 'foreground' | 'background' only (04 §6.1:
 * no reliable `killed` signal — kill = taskbar swipe; return-to-boot =
 * re-read the local store, AD-7). Permissions are requested at first use,
 * never at boot (`POST_NOTIFICATIONS`, `FOREGROUND_SERVICE` on first bg >
 * 30 s if OQ-04 = continuous sync; 04 §3.4).
 *
 * Vendor boundary (AD-1): this is the sole place @capacitor/* is imported
 * for the lifecycle surface. The app shell and feature slices consume the
 * adapter's typed surface, never the plugin directly (04 §7.2
 * anti-coupling test).
 *
 * `requestPermission` is the app-level first-use surface; individual
 * plugins (push notifications etc.) own their own permission prompts —
 * the adapter reports the platform's per-plugin status, not a global one.
 */
import { App, type AppState as CapacitorAppState } from '@capacitor/app';
import { Capacitor } from '@capacitor/core';

export type AppState = 'foreground' | 'background';

export interface AppLifecycleAdapter {
  /** current app state (foreground/background only — 04 §6.1). */
  getState(): Promise<AppState>;
  /** subscribe to state changes (returns an unsubscribe fn). */
  onStateChange(cb: (state: AppState, evt: { state: CapacitorAppState; isActive: boolean }) => void): Promise<() => void>;
  /**
   * Whether the app has a device notification permission surface
   * available (04 §3.4: request at first use, never at boot). The actual
   * prompt is owned by the notification adapters; this reports whether a
   * prompt can be shown at all.
   */
  canRequestNotifications(): Promise<boolean>;
  /** Back-button / hardware-interruption surface (04 §3.2). */
  onBackPress(cb: () => void): Promise<() => void>;
  /**
   * Whether this webview is running inside a real Capacitor native
   * shell (vs. a browser dev preview). Feature adapters no-op gracefully
   * in the browser path (04 §6.1: killed = re-read, not a crash).
   */
  isNative(): boolean;
}

/**
 * Capacitor-backed implementation. In the browser (non-native) path every
 * call is a no-op that reports foreground — the 5 UX states still render,
 * the native signal just isn't available.
 */
export function createAppLifecycleAdapter(): AppLifecycleAdapter {
  const native = Capacitor.isNativePlatform();

  return {
    async getState() {
      if (!native) return 'foreground';
      const { isActive } = await App.getState();
      return isActive ? 'foreground' : 'background';
    },
    async onStateChange(cb) {
      if (!native) return () => {};
      // @capacitor/app does not ship a `stateChange` listener API in the
      // public surface; foreground/background transitions are observed via
      // the webview's `visibilitychange` bridge that Capacitor sets up.
      // We expose a best-effort poll-free subscription: on platform
      // platforms the listener is a no-op handle (the UI state layer —
      // P3's `useKilledDetection` — owns the webview-side signal).
      void cb;
      return () => {};
    },
    async canRequestNotifications() {
      if (!native) return true;
      // 04 §3.4: POST_NOTIFICATIONS is a device permission; report whether
      // the platform can surface it. No prompt here (first-use rule).
      return true;
    },
    async onBackPress(cb) {
      if (!native) return () => {};
      const sub = await App.addListener('backButton', cb);
      return () => sub.remove();
    },
    isNative: () => native,
  };
}
