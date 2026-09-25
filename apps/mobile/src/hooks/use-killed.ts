/**
 * Killed-state detection (04 §6.1, G-M2) — no reliable "killed" signal
 * exists on Android (kill = taskbar swipe). The heuristic:
 *
 *   - `document.visibilityState` was `hidden` for a long stretch with no
 *     lifecycle `background` event captured in-session → the app was
 *     killed, not backgrounded.
 *   - On visibility return to `visible`, the screen RE-READS the local
 *     store (AD-7) — "retour foreground = re-sync, pas de crash".
 *
 * This hook exposes `killed` to the 5 UX states (P3) and clears it as
 * soon as the first local re-read completes (auto-resync, 04 S6.1).
 * It is the UI-only face; the native lifecycle events themselves are
 * delivered by P5's AppLifecycleAdapter (@aurora/platform).
 */
import { useEffect, useState } from 'react';

export function useKilledDetection(resync: () => void): boolean {
  const [killed, setKilled] = useState(false);

  useEffect(() => {
    // Track the last time we saw visibility=hidden. If the browser is
    // re-shown after a hidden gap > threshold with no `App` state event
    // (i.e. no in-memory record of having gone to background), we treat
    // it as a return-from-kill. P5's AppLifecycleAdapter will flip this
    // when it observes a native background event; until then the constant
    // stays `false` (the webview-only path has no background signal).
    const backgroundedInSession = false;
    let lastHiddenAt: number | null = null;

    const onVisibility = () => {
      if (document.visibilityState === 'hidden') {
        lastHiddenAt = Date.now();
      } else if (document.visibilityState === 'visible' && lastHiddenAt !== null) {
        const gapMs = Date.now() - lastHiddenAt;
        // 5 min heuristic: Android kills memory-pressure tasks quickly;
        // a short background/foreground flip (tab switch, phone call) is
        // NOT a kill. Above the threshold with no in-session background
        // event = the JS context was restarted → killed.
        const KILL_GAP_MS = 5 * 60 * 1000;
        if (!backgroundedInSession && gapMs > KILL_GAP_MS) {
          setKilled(true);
        }
        lastHiddenAt = null;
      }
    };

    document.addEventListener('visibilitychange', onVisibility);

    // First paint: if the session boot itself was a cold start, the local
    // store re-read happens on the screen's first query (AD-7); mark
    // killed so the 5 UX states render the "Reconnexion…" skeleton for
    // exactly that first pass, then clear it.
    setKilled(true);
    resync();

    const onFirstData = () => setKilled(false);
    window.addEventListener('aurora:first-local-read', onFirstData);

    return () => {
      document.removeEventListener('visibilitychange', onVisibility);
      window.removeEventListener('aurora:first-local-read', onFirstData);
    };
  }, [resync]);

  return killed;
}
