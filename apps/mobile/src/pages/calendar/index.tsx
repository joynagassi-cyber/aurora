/**
 * Calendar family view (02 S6.1, 05 §4.4.2). Time-block editor + event
 * detail. View mode (day/week/month/agenda) is ui-state (cosmetic,
 * persistent). NOT ion-calendar — FullCalendar v6+ with shadcn Popover
 * (docs/ui-libraries.md S1: "ion-calendar = vieux", replace with
 * FullCalendar). 44px min tap targets (04 S3 mobile adaptation).
 *
 * `POST_NOTIFICATIONS` permission is requested at first use (04 S4),
 * never at boot.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useUiStateStore } from '../../state/ui-state';

export function CalendarPage() {
  const theme = useUiStateStore((s) => s.theme);

  return (
    <>
      <IonHeader>
        <IonTitle>Calendrier</IonTitle>
      </IonHeader>
      <IonContent>
        {/* FullCalendar mount point (installed in P4 over the shadcn Popover
            date picker; views: jour, semaine, mois, agenda — touch-optimized) */}
        <div data-calendar="true" data-theme={theme} data-state="empty">
          Semaine vide
        </div>
      </IonContent>
    </>
  );
}
