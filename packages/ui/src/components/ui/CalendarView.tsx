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
  loading,
  errorMessage,
  onRetry,
  emptyMessage,
  className,
}: CalendarViewProps & { className?: string }) {
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

  const plugins = [dayGridPlugin, timeGridPlugin, listPlugin, interactionPlugin];

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
      ) : events.length === 0 ? (
        <div className="rounded-md border border-info bg-info-surface p-3 text-sm text-foreground">
          {emptyMessage ?? "Aucun événement"}
        </div>
      ) : null}

      {(loading || !errorMessage || events.length > 0) && (
        <div
          className={cn(
            "rounded-md border border-border bg-card",
            !loading && !errorMessage && events.length === 0 && "hidden",
          )}
        >
          <FullCalendar
            plugins={plugins}
            events={fcEvents}
            initialView={initialView}
            height={height}
            dayMaxEventRows={mobile ? 2 : 4}
            eventOverlap={conflictDetection}
            eventDrop={handleEventDrop}
            eventClick={handleEventClick}
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
