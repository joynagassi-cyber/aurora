/**
 * Calendar family view (02 S6.1, 05 §4.4.2). Time-block editor + event
 * detail. View mode (day/week/month/agenda) is a T4 ui-state (cosmetic,
 * persistent). NOT ion-calendar — FullCalendar v6+ (docs/ui-libraries §1).
 *
 * FullCalendar (`CalendarView` @aurora/ui) mounts here once the mobile
 * Tailwind build is stood up; this turn ships the token-styled surface +
 * pager + honest empty state (events mirror not yet wired → AD-7 empty).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useState } from 'react';

const CALENDAR_VIEWS = [
  ['day', 'Jour'],
  ['week', 'Semaine'],
  ['month', 'Mois'],
  ['agenda', 'Agenda'],
] as const;

type CalendarView = (typeof CALENDAR_VIEWS)[number][0];

/** A token-styled month grid (the surface FullCalendar replaces). */
function MonthGrid({ view }: { view: CalendarView }) {
  const weeks = 6;
  const days = 7;
  return (
    <div className="cal-grid" data-calendar-mount data-view={view}>
      <div className="cal-dow" aria-hidden>
        {['L', 'M', 'M', 'J', 'V', 'S', 'D'].map((d, i) => (
          <span key={i}>{d}</span>
        ))}
      </div>
      <div className="cal-days">
        {Array.from({ length: weeks * days }, (_, i) => (
          <span key={i} className="cal-cell" />
        ))}
      </div>
    </div>
  );
}

export function CalendarPage() {
  const [view, setView] = useState<CalendarView>('week');

  return (
    <>
      <IonHeader>
        <IonTitle>Calendrier</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-calendar="true">
          <div className="segmented" role="tablist" aria-label="Vue calendrier">
            {CALENDAR_VIEWS.map(([value, label]) => (
              <button
                key={value}
                role="tab"
                aria-selected={view === value}
                className={
                  view === value
                    ? 'segmented-item active'
                    : 'segmented-item'
                }
                onClick={() => setView(value)}
              >
                {label}
              </button>
            ))}
          </div>

          <MonthGrid view={view} />

          {/* Events mirror not wired → the honest empty (AD-7). */}
          <div data-state="empty" className="cal-empty">
            <p>Semaine vide</p>
            <a className="aurora-btn aurora-btn--primary aurora-tap" href="/inbox">
              Planifier
            </a>
          </div>
        </div>
      </IonContent>
    </>
  );
}
