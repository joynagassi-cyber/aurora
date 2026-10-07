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
 * soon as the first local re-read completes. The clear signal is the
 * `aurora:first-local-read` window event, dispatched EXACTLY ONCE by
 * the query bridge (`createMobileQueryClient`, 03 S5.8) when the first
 * local query reaches `success` — that is the moment the local store
 * re-read has completed (G-M2: "clear it as soon as the first local
 * re-read completes"). The module flag below keeps the fact for hook
 * instances that mount AFTER the one-shot event already fired.
 * It is the UI-only face; the native lifecycle events themselves are
 * delivered by P5's AppLifecycleAdapter (@aurora/platform).
 */
import { useEffect, useRef, useState } from 'react';

/**
 * Module-level memory of the first local read (survives the one-shot
 * window event). Set by `markFirstLocalReadSeen` (called by the query
 * bridge) and by the event listener itself.
 */
let firstLocalReadSeen = false;

/** The query bridge (03 S5.8) calls this when the first local read succeeds. */
export function markFirstLocalReadSeen(): void {
  firstLocalReadSeen = true;
}

export function useKilledDetection(resync: () => void): boolean {
  // Cold start (G-M2): the first local re-read happens on this screen's
  // first query — mark killed so the 5 UX states render the "Reconnexion…"
  // skeleton for exactly that first pass, then clear on the bridge event.
  // If the first read already happened (tab re-mount, deep link), the
  // flag says so and no killed pass is rendered at all.
  const [killed, setKilled] = useState(firstLocalReadSeen ? false : true);

  // Stable handle: callers pass `() => refetch()` (fresh closure per
  // render); the effect must NOT re-run on that identity or the
  // resync + killed marking loops on every render.
  const resyncRef = useRef(resync);
  resyncRef.current = resync;

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
          resyncRef.current();
        }
        lastHiddenAt = null;
      }
    };

    document.addEventListener('visibilitychange', onVisibility);

    // Cold start (G-M2): the local store re-read happens on the screen's
    // first query (AD-7). The bridge clears us when it completes.
    if (!firstLocalReadSeen) {
      resyncRef.current();
    }
    const onFirstData = () => {
      firstLocalReadSeen = true;
      setKilled(false);
    };
    window.addEventListener('aurora:first-local-read', onFirstData);

    // If the one-shot event already fired before this listener attached
    // (first read completed on another screen), clear immediately.
    if (firstLocalReadSeen) setKilled(false);

    return () => {
      document.removeEventListener('visibilitychange', onVisibility);
      window.removeEventListener('aurora:first-local-read', onFirstData);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps -- mount-once:
    // resync is read through the ref (stable across renders).
  }, []);

  return killed;
}
