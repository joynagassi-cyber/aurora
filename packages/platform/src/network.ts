/**
 * NetworkStatusAdapter (04 §3.2, AD-1) — the native network-signal surface.
 *
 * `isOnline` + `onNetworkChange`. In the browser dev path it falls back to
 * `navigator.onLine` / `window` online-offline events so the 5th UX state
 * (offline) renders even before the native plugin is available (03 S3.2:
 * offline = last-known data).
 *
 * Vendor boundary (AD-1): @capacitor/network is imported ONLY here.
 */
import { Network } from '@capacitor/network';
import { Capacitor } from '@capacitor/core';

export interface NetworkStatusAdapter {
  /** current connectivity. */
  isOnline(): Promise<boolean>;
  /** subscribe to connectivity changes (returns an unsubscribe fn). */
  onNetworkChange(cb: (online: boolean) => void): Promise<() => void>;
}

export function createNetworkStatusAdapter(): NetworkStatusAdapter {
  const native = Capacitor.isNativePlatform();

  return {
    async isOnline() {
      if (native) {
        const { connected } = await Network.getStatus();
        return connected;
      }
      // Browser dev path: navigator.onLine (DOM lib, typecast kept out of
      // the shared lib so the package stays pure ES2022 + Capacitor).
      if (typeof navigator !== 'undefined') {
        const nav = navigator as Navigator & { onLine?: boolean };
        if (typeof nav.onLine === 'boolean') return nav.onLine;
      }
      return true;
    },
    async onNetworkChange(cb) {
      if (native) {
        const sub = await Network.addListener('networkStatusChange', (evt) =>
          cb(evt.connected),
        );
        return () => sub.remove();
      }
      // Browser dev path: window online/offline events.
      type Win = {
        addEventListener(t: string, cb: () => void): void;
        removeEventListener(t: string, cb: () => void): void;
      };
      const w = (globalThis as { window?: Win }).window;
      if (!w) return () => {};
      const onUp = () => cb(true);
      const onDown = () => cb(false);
      w.addEventListener('online', onUp);
      w.addEventListener('offline', onDown);
      return () => {
        w.removeEventListener('online', onUp);
        w.removeEventListener('offline', onDown);
      };
    },
  };
}
