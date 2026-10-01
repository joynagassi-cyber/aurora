/**
 * Calendar family view (02 S6.1, 05 §4.4.2). Time-block editor + event
 * detail. View mode (day/week/month/agenda) is a T4 ui-state (cosmetic,
 * persistent). NOT ion-calendar — FullCalendar v6+ (docs/ui-libraries §1).
 *
 * AD-10: the calendar is now the real `CalendarView` (@aurora/ui contract,
 * FullCalendar engine). The view switcher re-mounts on change (`key`) since
 * FullCalendar's `initialView` is set-once. Events come from the calendar
 * mirror (AD-7) — not yet wired → the engine renders its honest empty
 * state ("Aucun événement") and pops in as soon as events land.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useState } from 'react';
import { CalendarView } from '@aurora/ui';
import type { CalendarViewName, RenderCalendarEvent } from '@aurora/ui';

const CALENDAR_VIEWS = [
  ['week', 'Semaine'],
  ['month', 'Mois'],
  ['day', 'Jour'],
  ['agenda', 'Agenda'],
] as const;

type ViewKey = (typeof CALENDAR_VIEWS)[number][0];

/** View key → FullCalendar view (docs/ui-libraries.md §1: day/week/month/agenda). */
const FULLCAL: Record<ViewKey, CalendarViewName> = {
  week: 'timeGridWeek',
  month: 'dayGridMonth',
  day: 'timeGridDay',
  agenda: 'listWeek',
};

export function CalendarPage() {
  const [view, setView] = useState<ViewKey>('week');
  // AD-7: events come from the calendar mirror (not yet wired → empty).
  const events: RenderCalendarEvent[] = [];

  return (
    <>
      <IonHeader>
        <IonTitle>Calendrier</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-calendar="true" className="cal-page">
          {/* T4 view mode (cosmetic, persistent ui-state in a full build). */}
          <div className="segmented" role="tablist" aria-label="Vue calendrier">
            {CALENDAR_VIEWS.map(([value, label]) => (
              <button
                key={value}
                type="button"
                role="tab"
                aria-selected={view === value}
                className={
                  view === value ? 'segmented-item active' : 'segmented-item'
                }
                onClick={() => setView(value)}
              >
                {label}
              </button>
            ))}
          </div>

          {/* AD-10: FullCalendar mounted via the @aurora/ui contract.
              `key={view}` re-mounts on view switch (initialView is per-view). */}
          <CalendarView
            key={view}
            events={events}
            initialView={FULLCAL[view]}
            mobile
            height={view === 'month' ? 380 : 420}
            emptyMessage="Aucun événement — planifiez un bloc."
          />

          <a className="aurora-btn aurora-btn--primary aurora-tap" href="/inbox">
            Planifier
          </a>
        </div>
      </IonContent>
    </>
  );
}
