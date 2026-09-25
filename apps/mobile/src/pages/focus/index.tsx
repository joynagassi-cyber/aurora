/**
 * Focus session screen (05 §4.4.2, focus-mode spec S6).
 *
 * Timer ring (Pomodoro, system clock — AD-7) + blocklist UI (per-package
 * status: suspendable / not / aurora-protected). DPC detection
 * (`isBlockingAvailable` = detection, NOT a constant — OQ-17). 7 states:
 * scheduled → starting → prechecking → active → paused → ending →
 * completed / interrupted, restoring, failed.
 *
 * Local theme adaptation (OQ-15, V1 = Focus only): secondary nodes
 * attenuated (40% opacity), active node + progress bar at full contrast
 * (goal-dashboard-ui.md S4 local adaptation rule).
 *
 * `POST_NOTIFICATIONS` permission requested at first use (04 S4).
 * Focus suppression = `reduceForFocus` (focus spec S8, LocalNotificationAdapter).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useUiStateStore } from '../../state/ui-state';

export function FocusPage() {
  const focusActive = useUiStateStore((s) => s.focusActive);

  return (
    <>
      <IonHeader>
        <IonTitle>Focus</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-focus-session="true" data-active={focusActive} data-state={focusActive ? 'active' : 'scheduled'}>
          <span>Session non démarrée</span>
        </div>
      </IonContent>
    </>
  );
}
