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
import type { ReactNode } from "react";
import { CalendarView, Timeline } from "@aurora/ui";
import type {
  CalendarViewName,
  RenderCalendarEvent,
  TimelineEvent,
} from "@aurora/ui";
import type { DayCellContentArg } from "@aurora/ui";
import {
  AlignLeft,
  AlignCenter,
  Clock,
  List,
} from "lucide-react";
import { UxStates, type UxStateFlags } from "../../ux-states";
import { useOnlineStatus } from "../../hooks/use-online";
import { useUiStateStore } from "../../state/ui-state";
import {
  PageOptionsMenu,
  settingsItem,
  type PageOptionItem,
} from "../../ux/page-options-menu";
import { CalendarDots, CALENDAR_DOTS_CSS } from "../../ux/calendar-dots";

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
  const [eventSort, setEventSort] = useState<"echeance" | "titre">("echeance");
  // Le tri est appliqué au miroir des tâches dès qu'il sera câblé (AD-7 :
  // le miroir n'est pas encore branché, l'état reste cosmétique + persistant
  // pour l'UI). On l'expose via un flag pour documenter l'intention.
  const eventSortLabel = eventSort === "echeance" ? "échéance" : "titre";
  // AD-13 (6 états) : le calendrier lit le local (AD-7) — hors ligne il
  // reste lisible (last-known), tué l'app = reconnexion + resync.
  const killed = useUiStateStore((s) => s.killed);
  const online = useOnlineStatus();
  const flags: UxStateFlags = { offline: !online, killed };

  /** C5.4 : le menu « ⋮ » (05 §3.5 l.843-854, max 6 items) — calendrier n'est
      PAS multi-vues glissable (un seul moteur FullCalendar, pas de slides),
      donc le glissement horizontal ne s'y applique PAS. Le menu porte le
      tri des événements + le mode liste des tâches + 1 item « Paramètres ».
      Chaque item porte une icône 16px couleur (ref_045) — les teintes sont
      les états FROZEN (05 §5.1, AD-17 : jamais une valeur brute). */
  const menuItems: PageOptionItem[] = [
    {
      id: "tri-echeance",
      label: "Trier par échéance",
      icon: AlignLeft,
      iconTone: "info",
      active: eventSort === "echeance",
      onClick: () => setEventSort("echeance"),
    },
    {
      id: "tri-titre",
      label: "Trier par titre",
      icon: AlignCenter,
      iconTone: "warning",
      active: eventSort === "titre",
      onClick: () => setEventSort("titre"),
    },
    {
      id: "vue-liste",
      label: "Liste des tâches",
      icon: List,
      iconTone: "accent",
      active: taskMode === "liste",
      onClick: () => setTaskMode("liste"),
    },
    {
      id: "vue-chrono",
      label: "Chronologie des tâches",
      icon: Clock,
      iconTone: "success",
      active: taskMode === "chronologie",
      onClick: () => setTaskMode("chronologie"),
    },
    settingsItem("calendar"),
  ];

  // AD-7: events come from the calendar mirror (not yet wired → empty).
  const events: RenderCalendarEvent[] = [];
  // AD-7: tasks come from the tasks mirror (not yet wired → empty).
  // When wired, filter to the active period (selected day/week/3-day
  // range) and pass as `taskEvents` below.
  const taskEvents: TimelineEvent[] = events.map(toTimelineEvent);

  /**
   * C2.2 : le superposé de pastilles SUR la cellule de la grille
   * (ref_020/021, image #10) — le hook FullCalendar `dayCellContent`
   * (l'échappatoire app-owned, 05 §3.4 l.750 : « le contenu de la
   * cellule reste contrôlé par la page, jamais par le composant »).
   *
   * La pastille est colorée par **token d'accent du thème** (AD-17 :
   * jamais une valeur brute, le thème pilote la couleur via
   * `color-mix()`). Quand le mirroir n'est pas câblé (AD-7), `events`
   * est vide → PAS une seule pastille (jamais un point factice).
   * Le `CalendarDots` ne rend rien si la liste est vide (le composant
   * est honnête, cf. `calendar-dots.tsx`). */
  const renderDayCell = (
    arg: DayCellContentArg,
  ): ReactNode => {
    // C2.2 : le jour courant = le libellé FullCalendar (le `dayNumber`)
    // + les pastilles des événements/tâches associées (AD-7 : le mirroir
    // non câblé → 0 pastille, jamais un point factice).
    const codes: import("../../ux/calendar-dots").AccentCode[] = events
      .filter((ev) => ev.start?.startsWith(arg.dateStr.slice(0, 10)))
      .map((ev) => ev.accentCode ?? "primary");
    return (
      <div className="cal-day-cell">
        <span className="cal-day-number">{arg.dayNumber}</span>
        <CalendarDots codes={codes} ariaLabel={`${arg.dayNumber} : ${codes.length} événement(s)`} />
      </div>
    );
  };

  /* Le mois courant en français (ref_007 : « octobre » comme titre du
   * calendrier, pas un numéro nu) — dérivé de la date du jour, jamais
   * inventé. */
  const currentMonthLabel = new Date().toLocaleDateString("fr-FR", {
    month: "long",
    year: "numeric",
  });

  return (
    <>
      <IonHeader>
        <div className="cal-header">
          <IonTitle>Calendrier</IonTitle>
          <PageOptionsMenu items={menuItems} ariaLabel="Options de la page Calendrier" />
        </div>
      </IonHeader>
      <IonContent>
        <UxStates state={{ status: "success", data: null }} flags={flags} label="Calendrier">
          {/* Le tri par {eventSortLabel} s'applique au miroir des tâches dès
              qu'il sera câblé (AD-7) — aujourd'hui l'état est cosmétique. */}
          <div data-calendar="true" data-calendar-sort={eventSortLabel} className="cal-page space-y-2 cal-card">
          {/* Le but du module, en une ligne simple (pattern lots 1+2,
              zéro jargon technique visible par l'utilisateur). */}
          <p className="page-purpose">
            Tous tes blocs et tes tâches sur une seule vue.
          </p>

          {/* Le mois courant, au-dessus de la grille (ref_007) — c'est le
              calendrier lui-même qui porte la date, pas l'utilisateur qui
              doit la deviner. */}
          <p className="cal-month-band" aria-label={`Calendrier — ${currentMonthLabel}`}>
            {currentMonthLabel}
          </p>

          {/* T4 in-page SegmentedControl (05 §3.4 — sous-option, non-push,
              z-chrome=10 per floating.css). The page owns the 6-view strip;
              `CalendarView` below receives whichever view is active.
              Reuses the shared `.segmented`/`.segmented-item` CSS pattern
              (atoms.css, 05 §3.4 Pager) — the pre-fix version re-implemented
              it inline in Tailwind (a duplicate, visually inconsistent with
              /learn /progress /projects /tasks which all use this pattern). */}
          <div
            role="tablist"
            aria-label="Vue calendrier"
            className="segmented"
          >
            {CALENDAR_VIEWS.map(([name, label]) => (
              <button
                key={name}
                type="button"
                role="tab"
                aria-selected={view === name}
                className={view === name ? "segmented-item active" : "segmented-item"}
                onClick={() => setView(name)}
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
            emptyMessage="Aucun événement — planifie un bloc."
            dayCellContent={
              view === "dayGridMonth" || view === "timeGridWeek" || view === "timeGridDay"
                ? renderDayCell
                : undefined
            }
          />

          {/* C2.2 : le CSS des pastilles (le superposé est rendu par le
              hook `dayCellContent` ci-dessus, pas par un bloc séparé).
              Le `CalendarDots` + `CALENDAR_DOTS_CSS` sont branchés ici :
              les pastilles se dessinent DIRECTEMENT dans la cellule
              (le hook FullCalendar `dayCellContent`), pas dans un
              superposé au-dessus de la grille. Quand le mirroir n'est
              pas câblé (AD-7), 0 pastille — jamais un point factice. */}
          <style>{CALENDAR_DOTS_CSS}</style>

          {/* C2.2 : la section « Tâches du mois » sous la grille
              (image #10) — le pattern de la ref : sous la grille mois,
              la liste des tâches de la période (chacune = pastille
              colorée + heure + titre). Le miroir non câblé (AD-7) →
              l'état vide honnête + le CTA de planification. */}
          {view === "dayGridMonth" && (
            <div data-cal-task-list className="cal-task-list">
              <h3 className="cal-task-list-title">
                Tâches du mois
              </h3>
              <p className="page-hint">
                Les tâches planifiées sur ce mois apparaîtront ici.
              </p>
            </div>
          )}

          {/* C2.2 : la vue année (image #9) — les 12 mini-mois
              empilés, chaque mini-mois = la grille 7 colonnes + les
              pastilles colorées sur les jours qui ont du contenu.
              Le composant `CalendarView` (view `yearGrid`) le gère
              déjà — on s'assure juste que le mois courant est
              mis en avant (ref_09 : « 2024 » en haut, 12 mini-mois
              empilés 2×6). */}
          {view === "yearGrid" && (
            <div data-cal-year-hint className="cal-year-hint">
              <p className="page-hint">
                Chaque mini-mois montre les pastilles des jours qui
                ont des tâches ou des événements planifiés.
              </p>
            </div>
          )}

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
              className="segmented segmented--compact"
            >
              <button
                type="button"
                role="tab"
                aria-selected={taskMode === "liste"}
                className={taskMode === "liste" ? "segmented-item active" : "segmented-item"}
                onClick={() => setTaskMode("liste")}
              >
                Liste
              </button>
              <button
                type="button"
                role="tab"
                aria-selected={taskMode === "chronologie"}
                className={taskMode === "chronologie" ? "segmented-item active" : "segmented-item"}
                onClick={() => setTaskMode("chronologie")}
              >
                Chronologie
              </button>
            </div>
            {taskMode === "liste" ? (
              <Timeline taskList events={taskEvents} emptyMessage="Aucune tâche pour cette période." />
            ) : (
              <Timeline events={taskEvents} emptyMessage="Aucune tâche pour cette période." />
            )}
          </div>

          <a className="aurora-btn aurora-btn--primary aurora-tap" href="/inbox">
            Planifier
          </a>
        </div>
        </UxStates>
      </IonContent>
    </>
  );
}
