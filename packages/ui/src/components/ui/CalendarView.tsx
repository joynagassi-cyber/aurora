/**
 * CalendarView — docs/ui-libraries.md §1/§5: FullCalendar v6, NOT
 * ion-calendar. Time blocking (agent-prompts Phase 2.3): colored blocks
 * per type (etude / focus / projet), conflict = double red border,
 * focus sessions = blocklist icon. Mobile: day/week views only, 44px
 * tap targets. AD-13 5 states: loading (skeleton) / error (callout +
 * retry) / empty / offline (last-known stays).
 */
import * as React from "react";
import { useCallback } from "react";
import FullCalendar from "@fullcalendar/react";
import dayGridPlugin from "@fullcalendar/daygrid";
import timeGridPlugin from "@fullcalendar/timegrid";
import listPlugin from "@fullcalendar/list";
import interactionPlugin from "@fullcalendar/interaction";
import type {
  EventInput,
  EventClickArg,
  EventDropArg,
} from "@fullcalendar/core";
import { cn } from "src/lib/utils";
import type {
  CalendarViewProps,
  RenderCalendarEvent,
} from "src/renderers/contracts";

// Block type -> theme token colors (agent-prompts Phase 2.3).
// NOT semantic states (blocking rule 05 §5.1): these are schedule
// types, success/warning/danger/info stay in the neutral layer.
const BLOCK_COLORS: Record<string, { bg: string; border: string }> = {
  etude: { bg: "hsl(var(--aurora-accent-primary-h))", border: "hsl(var(--aurora-accent-primary-h))" },
  focus: { bg: "hsl(var(--aurora-accent-secondary-h))", border: "hsl(var(--aurora-accent-secondary-h))" },
  projet: { bg: "hsl(var(--aurora-accent-punctual-h))", border: "hsl(var(--aurora-accent-punctual-h))" },
};

const BLOCK_FALLBACK = { bg: "hsl(var(--aurora-border-strong-h))", border: "hsl(var(--aurora-border-strong-h))" };

function toFullCalendarEvent(ev: RenderCalendarEvent): EventInput {
  const c = BLOCK_COLORS[ev.blockType ?? ""] ?? BLOCK_FALLBACK;
  const conflicted = ev.conflicting;
  return {
    id: ev.id,
    title: ev.title,
    start: ev.start,
    end: ev.end,
    allDay: ev.allDay,
    backgroundColor: conflicted ? "transparent" : c.bg,
    borderColor: conflicted ? "hsl(var(--aurora-danger-h))" : c.border,
    borderWidth: conflicted ? 2 : 1,
    borderStyle: conflicted ? "double" : "solid",
    color: "hsl(var(--aurora-accent-on-primary-h))",
    // Focus sessions = blocklist icon (agent-prompts Phase 2.3)
    classNames: (
      [
        "aurora-event",
        ev.focusSession ? "aurora-event-focus" : null,
        conflicted ? "aurora-event-conflict" : null,
      ].filter(Boolean) as string[]
    ),
    extendedProps: ev,
  };
}

export function CalendarView({
  events,
  initialView = "timeGridWeek",
  height = "auto",
  mobile = false,
  conflictDetection = true,
  onEventClick,
  onEventDrop,
  dayCellContent,
  loading,
  errorMessage,
  onRetry,
  // `emptyMessage` (10-09) : le paramètre reste dans le contrat (retro-
  // compatibilité des 5 états AD-13) mais le calendrier n'en a plus
  // besoin à l'état vide : la grille s'affiche toujours vide (7
  // colonnes × jours), le sélecteur de vue se superpose dessus —
  // jamais un message factice qui masque la structure du calendrier
  // (constat utilisateur 10-09). Conservé dans la signature, jamais
  // rendu : préfixe `_` pour silencer TS6133 (variable jamais lue).
  emptyMessage: _emptyMessage,
  className,
}: CalendarViewProps & { className?: string }) {
  // The in-page SegmentedControl view switcher is owned by the PAGE
  // (apps/mobile pages/calendar/index.tsx), not by this engine — this
  // component is the render target that receives the selected view.
  const view = initialView;

  const handleEventClick = useCallback(
    (info: EventClickArg) => {
      const ev = info.event.extendedProps as RenderCalendarEvent;
      onEventClick?.(ev);
    },
    [onEventClick],
  );

  const handleEventDrop = useCallback(
    (info: EventDropArg) => {
      const ev = info.event.extendedProps as RenderCalendarEvent;
      const newStart = info.event.start ? info.event.start.toISOString() : ev.start;
      onEventDrop?.(ev, newStart);
    },
    [onEventDrop],
  );

  const fcEvents = React.useMemo(
    () => events.map(toFullCalendarEvent),
    [events],
  );

  // --- Year + 3-day views --------------------------------------------
  // `yearGrid` = custom native renderer (12 mini-months, events = dots —
  // FullCalendar v6 has no native year view). `threeDayGrid` = the
  // week grid restricted to 3 day-columns via FullCalendar's
  // `daysOfWeek` filter option.
  const fcView: "dayGridMonth" | "timeGridWeek" | "timeGridDay" | "listWeek" =
    view === "threeDayGrid" ? "timeGridWeek" : view === "yearGrid" ? "dayGridMonth" : (view as "dayGridMonth" | "timeGridWeek" | "timeGridDay" | "listWeek");

  const plugins = [dayGridPlugin, timeGridPlugin, listPlugin, interactionPlugin];

  // The 12 mini-months of the year view (rendered when `view === "yearGrid"`).
  const yearMiniMonths = React.useMemo(() => {
    if (view !== "yearGrid") return [];
    const now = new Date();
    const year = now.getFullYear();
    return Array.from({ length: 12 }, (_, i) => {
      const monthEvents = events.filter((ev) => {
        const d = new Date(ev.start);
        return d.getFullYear() === year && d.getMonth() === i;
      });
      return {
        label: ["jan.", "févr.", "mars", "avr.", "mai", "juin", "juil.", "août", "sept.", "oct.", "nov.", "déc."][i],
        events: monthEvents,
      };
    });
  }, [view, events]);

  const renderYearView = () => (
    <div className="grid grid-cols-2 gap-2 p-3 sm:grid-cols-3 md:grid-cols-4">
      {yearMiniMonths.map(({ label, events: evts }) => (
        <div
          key={label}
          className="rounded-md border border-border bg-card p-2 text-xs"
        >
          <div className="mb-1 font-medium text-foreground">{label}</div>
          <div className="flex flex-wrap gap-0.5">
            {evts.length === 0 ? (
              <span className="text-muted-foreground">—</span>
            ) : (
              evts.slice(0, 8).map((ev, i) => (
                <span
                  key={i}
                  title={ev.title}
                  className="inline-block h-2 w-2 rounded-full"
                  style={{ backgroundColor: BLOCK_COLORS[ev.blockType ?? ""]?.bg ?? BLOCK_FALLBACK.bg }}
                />
              ))
            )}
          </div>
        </div>
      ))}
    </div>
  );

  // Mobile: day/week only (docs/ui-libraries.md §5). FullCalendar v6
  // exposes all views; the app picks via `initialView` + `headerToolbar`.
  return (
    <div
      data-aurora-component="CalendarView"
      data-state={loading ? "loading" : errorMessage ? "error" : events.length === 0 ? "empty" : "idle"}
      className={cn("space-y-2", className)}
    >
      {loading ? (
        <div className="h-64 rounded-md border border-border bg-card p-4">
          <div className="h-full w-full animate-pulse-skeleton rounded bg-muted" />
        </div>
      ) : errorMessage ? (
        <div role="alert" className="flex items-center justify-between rounded-md border border-danger bg-danger-surface p-3 text-sm text-danger">
          <span>{errorMessage}</span>
          {onRetry ? (
            <button type="button" onClick={onRetry} className="rounded border border-danger/40 px-2 py-1 text-xs hover:bg-danger/20">
              Réessayer
            </button>
          ) : null}
        </div>
      ) : null}

      {/* La grille s'affiche TOUJOURS (état vide compris, 10-09) : le
          calendrier respire à vide (7 colonnes × les jours), le
          sélecteur de vue se superpose dessus. L'ancienne logique
          masquait la grille quand `events.length === 0` et n'affichait
          qu'un message « Aucun événement » — le calendrier lui-même
          (la grille) manquait à l'état vide, ce qui cassait l'expectation
          utilisateur (« le calendrier doit s'afficher, vide, et le
          sélecteur se superposer dessus »). L'état vide honnête (AD-7)
          reste porté par la grille elle-même (0 événement = 0 bloc),
          jamais un message factice qui masque la structure. */}
      {(loading || !errorMessage) && (
        <div
          className={cn(
            "rounded-md border border-border bg-card",
          )}
        >
          {view === "yearGrid" ? (
            renderYearView()
          ) : (
            <FullCalendar
              plugins={plugins}
              events={fcEvents}
              initialView={fcView}
              height={height}
              dayMaxEventRows={mobile ? 2 : 4}
              fixedWeekCount={false}
              nowIndicator
              eventOverlap={conflictDetection}
              eventDrop={handleEventDrop}
              eventClick={handleEventClick}
              dayCellContent={dayCellContent}
              dayMinWidth={view === "threeDayGrid" ? 100 : undefined}
              headerToolbar={
                mobile
                  ? { start: "today prev", center: "title", end: "next" }
                  : {
                      start: "prev",
                      center: "title",
                      end: "today next",
                    }
              }
            />
          )}
        </div>
      )}

      {/* FullCalendar event styling — block colors, focus badge, conflict */}
      <style>{`
        .aurora-event {
          font-size: 12px;
          font-weight: 500;
          border-radius: 4px;
        }
        .aurora-event-conflict {
          background-color: transparent !important;
          border: 2px double hsl(var(--aurora-danger-h)) !important;
        }
        .fc .fc-toolbar .fc-button {
          min-height: 44px;
          min-width: 44px;
          font-size: 13px;
        }
        .fc .fc-daygrid-event, .fc .fc-timegrid-event {
          min-height: 24px;
        }
      `}</style>
    </div>
  );
}

export type { CalendarViewProps, RenderCalendarEvent };
