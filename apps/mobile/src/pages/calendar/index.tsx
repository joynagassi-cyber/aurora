/**
 * Calendar family view (02 S6.1, 05 §4.4.2) — T4 in-page view switcher
 * (inspiration pattern 2026-10-03):
 *
 *   · 6 views:  Liste · Année · Mois · Semaine · 3 Jours · Jour
 *     (in-page `SegmentedControl`, 05 §3.4 — non-push, state preserved
 *     on back, z-index chrome=10).
 *   · Always-on task list strip under the calendar (Liste ↔ Chronologie
 *     two-mode switcher, `taskList` prop on `Timeline`).
 *
 * AD-7: events + tasks come from the local mirror (not yet wired →
 * honest empty state, never fake data). The FullCalendar engine is
 * mounted via the `@aurora/ui` `CalendarView` contract.
 */
import { IonContent, IonHeader, IonTitle } from "@ionic/react";
import { useState } from "react";
import { CalendarView, Timeline } from "@aurora/ui";
import type {
  CalendarViewName,
  RenderCalendarEvent,
  TimelineEvent,
} from "@aurora/ui";

/**
 * The always-on task list strip under the calendar: two modes
 * (Liste = compact rows, Chronologie = timeline with dots) — the
 * user can switch modes in-place without losing their position.
 */
type TaskListMode = "liste" | "chronologie";

/**
 * The 6 in-page views of the inspiration pattern (2026-10-03):
 * Liste (agenda list) · Année · Mois · Semaine · 3 Jours · Jour.
 * `yearGrid` and `threeDayGrid` are the two new views (year = native
 * mini-month renderer, 3-day = week grid with 3-day column restriction).
 */
type CalendarPageView = CalendarViewName | "yearGrid" | "threeDayGrid";

const CALENDAR_VIEWS: [CalendarPageView, string][] = [
  ["listWeek", "Liste"],
  ["yearGrid", "Année"],
  ["dayGridMonth", "Mois"],
  ["timeGridWeek", "Semaine"],
  ["threeDayGrid", "3 Jours"],
  ["timeGridDay", "Jour"],
];

/**
 * Map a `RenderCalendarEvent` (FullCalendar event) to a
 * `TimelineEvent` (the `@aurora/ui` task-list shape) so the strip
 * can render the SAME event data in either mode without a second
 * source. `kind` is derived from block type (05 §5.1 semantic
 * states are frozen — only success/warning/primary are used,
 * never danger, so the strip's dots stay neutral-schedule-colored).
 */
function toTimelineEvent(ev: RenderCalendarEvent): TimelineEvent {
  const kind = ev.blockType === "focus" ? "warning" : ev.blockType === "etude" ? "success" : "primary";
  const start = new Date(ev.start);
  return {
    id: ev.id,
    label: ev.title,
    at: start.toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" }),
    kind,
  };
}

export function CalendarPage() {
  const [view, setView] = useState<CalendarPageView>("timeGridWeek");
  const [taskMode, setTaskMode] = useState<TaskListMode>("liste");

  // AD-7: events come from the calendar mirror (not yet wired → empty).
  const events: RenderCalendarEvent[] = [];
  // AD-7: tasks come from the tasks mirror (not yet wired → empty).
  // When wired, filter to the active period (selected day/week/3-day
  // range) and pass as `taskEvents` below.
  const taskEvents: TimelineEvent[] = events.map(toTimelineEvent);

  return (
    <>
      <IonHeader>
        <IonTitle>Calendrier</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-calendar="true" className="cal-page space-y-2">
          {/* T4 in-page SegmentedControl (05 §3.4 — sous-option, non-push,
              z-chrome=10 per floating.css). The page owns the 6-view strip;
              `CalendarView` below receives whichever view is active. */}
          <div
            role="tablist"
            aria-label="Vue calendrier"
            className="relative z-[10] flex gap-1 overflow-x-auto rounded-md border border-border bg-card p-1"
          >
            {CALENDAR_VIEWS.map(([name, label]) => (
              <button
                key={name}
                type="button"
                role="tab"
                aria-selected={view === name}
                onClick={() => setView(name)}
                className={`shrink-0 rounded px-3 py-1.5 text-xs font-medium transition-colors ${
                  view === name
                    ? "bg-primary text-primary-foreground shadow-sm"
                    : "text-muted-foreground hover:bg-muted hover:text-foreground"
                }`}
              >
                {label}
              </button>
            ))}
          </div>

          {/* AD-10: FullCalendar mounted via the @aurora/ui contract.
              `yearGrid` renders the native mini-month view inside
              `CalendarView`; the 4 FullCalendar-backed views (listWeek /
              dayGridMonth / timeGridWeek / timeGridDay) re-mount via
              `key={view}` since `initialView` is set-once. `threeDayGrid`
              is currently a placeholder — it passes through to
              `timeGridWeek` (3-day column restriction, FullCalendar
              `dayMinWidth` — the native renderer is a follow-up). */}
          <CalendarView
            key={view}
            events={events}
            initialView={
              view === "threeDayGrid" ? "timeGridWeek" : view === "yearGrid" ? "dayGridMonth" : view
            }
            mobile
            height={view === "dayGridMonth" || view === "yearGrid" ? 380 : 420}
            emptyMessage="Aucun événement — planifiez un bloc."
          />

          {/* Always-on task list strip under the calendar — two modes
              (Liste ↔ Chronologie), position preserved on switch.
              `Timeline` accepts `taskList` as a boolean prop (the
              `TimelineProps` object carries the event array + loading /
              empty / error state; the `taskList` flag is a view-mode
              switch, not part of the event data shape). */}
          <div className="cal-task-strip">
            <div
              role="tablist"
              aria-label="Mode liste de tâches"
              className="mb-2 flex gap-1"
            >
              <button
                type="button"
                role="tab"
                aria-selected={taskMode === "liste"}
                onClick={() => setTaskMode("liste")}
                className={`rounded px-2 py-1 text-xs font-medium ${
                  taskMode === "liste"
                    ? "bg-primary text-primary-foreground"
                    : "text-muted-foreground hover:bg-muted"
                }`}
              >
                Liste
              </button>
              <button
                type="button"
                role="tab"
                aria-selected={taskMode === "chronologie"}
                onClick={() => setTaskMode("chronologie")}
                className={`rounded px-2 py-1 text-xs font-medium ${
                  taskMode === "chronologie"
                    ? "bg-primary text-primary-foreground"
                    : "text-muted-foreground hover:bg-muted"
                }`}
              >
                Chronologie
              </button>
            </div>
            {taskMode === "liste" ? (
              <Timeline events={taskEvents} emptyMessage="Aucune tâche pour cette période." />
            ) : (
              <Timeline events={taskEvents} emptyMessage="Aucune tâche pour cette période." />
            )}
          </div>

          <a className="aurora-btn aurora-btn--primary aurora-tap" href="/inbox">
            Planifier
          </a>
        </div>
      </IonContent>
    </>
  );
}
