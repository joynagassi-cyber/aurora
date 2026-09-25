/**
 * Network status flag for the 5th UX state (offline, 03 S3.2).
 *
 * UI-only bridge: P5's `NetworkStatusAdapter` (@aurora/platform) owns the
 * native signal (Capacitor Network plugin); this hook mirrors `navigator.onLine`
 * as the webview fallback so the offline badge renders even before the
 * adapter is wired. The `offline` state renders LAST-KNOWN data (AD-7:
 * the local mirror), never an error.
 */
import { useEffect, useState } from 'react';

export function useOnlineStatus(): boolean {
  const [online, setOnline] = useState<boolean>(
    typeof navigator !== 'undefined' ? navigator.onLine : true,
  );

  useEffect(() => {
    if (typeof window === 'undefined') return;
    const onUp = () => setOnline(true);
    const onDown = () => setOnline(false);
    window.addEventListener('online', onUp);
    window.addEventListener('offline', onDown);
    return () => {
      window.removeEventListener('online', onUp);
      window.removeEventListener('offline', onDown);
    };
  }, []);

  return online;
}
