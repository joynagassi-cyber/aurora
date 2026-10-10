/**
 * MonthView (vue « Mois ») — la grille 7 colonnes des jours du mois
 * courant (l'inspiration pattern 2026-10-03 : les pastilles de
 * tâches colorées sous chaque numéro, le disque accent dynamique
 * sur le jour « aujourd'hui »).
 *
 * 100 % div standards (interdiction IonGrid/IonRow/IonCol/IonList/
 * IonItem/IonCard, 10-09), les couleurs 100 % variables du thème
 * dynamique (`useDynamicTheme` est branché par le parent
 * `CalendarPage` sur `<html>` — ce composant n'est qu'un `<div>`,
 * jamais de `IonPage`/`IonContent` imbriqués).
 *
 * La structure (le prompt 10-09, le grid classique — JAMAIS un
 * flex `calc(100%/7)`):
 *   · `.cal-month-scroll` : le conteneur défilant (height 100%, le
 *     padding-bottom 100px laisse passer la bottom nav locale du
 *     calendrier) ;
 *   · `.cal-month-days-header` : la rangée des jours (L M M J V S
 *     D, 7 cellules alignées sur la grille, 10px, --text-muted,
 *     centré) ;
 *   · `.cal-month-grid` : la grille des jours (7 colonnes, gap 2px)
 *     — chaque `.cal-m-day` (min-height 70px, le numéro + les
 *     pastilles de tâches), le jour « aujourd'hui » porte `.today`
 *     (le fond accent dynamique, le disque, le texte blanc, le
 *     700), les jours hors du mois portent `.other` (opacité 0.25)
 *     ;
 *   · `.cal-m-pill` : une pastille de tâche (8px, la teinte pastel
 *     `.ev-*` + les 4 variantes `-p` de la règle 10-09 : `.tan-p`/
 *     `.pink-p`/`.purple-p`/`.green-p` — le seul `rgba(…)`
 *     autorisé par la règle « pastilles pastel des événements »,
 *     les 6 teintes sont partagées avec `DayView`/`MultiDayView`
 *     via `shared-ev.ts`, jamais dupliquées ici).
 *
 * AD-7 (honest data) : la vue reçoit `events` (le miroir local du
 * calendrier, le parent `CalendarPage` le pilote) — si le miroir
 * n'est pas câblé, la grille est VIDE de pastilles (les numéros,
 * l'aujourd'hui restent, jamais une pastille factice).
 */
import type { RenderCalendarEvent } from "@aurora/ui";
import { useMemo } from "react";
import { dayEventTone, EV_PASTEL_CSS } from "./shared-ev";

/** La rangée des jours (L, M, M, J, V, S, D) — indexée par
 *  `getDay()` (0 = dimanche), le même ordre civil que `index.tsx`
 *  (le `DOW` de la grille existante) et `MultiDayView.tsx`
 *  (le `DAY_LETTER`), jamais l'ordre du système. */
const DOW_LETTER = ["L", "M", "M", "J", "V", "S", "D"] as const;

export interface MonthViewProps {
  /** Les événements du mois (le miroir local du calendrier, AD-7 :
   *  le parent pilote la donnée, jamais ce composant). */
  events: RenderCalendarEvent[];
  /** Le libellé du mois courant (le parent `CalendarPage` porte
   *  déjà `currentMonthLabel` — jamais une valeur factice ici). */
  monthLabel?: string;
  /** La classe racine supplémentaire (le parent peut scoper sur
   *  `.cal-dynamic` pour que le fond image respire derrière). */
  rootClassName?: string;
}

/** Les cellules de la grille (le numéro, l'état « today »/« other »,
 *  l'ISO `YYYY-MM-DD` pour le groupage des événements par jour). */
interface MonthCell {
  number: number;
  iso: string | null;
  faded: boolean;
  inMonth: boolean;
}

/** Construit les cellules du mois courant (la logique de `build-
 *  MonthCells` de `index.tsx`, lue ici en propre — jamais dupliquée
 *  dans les 2 fichiers). Le calendrier démarre au LUNDI (0 =
 *  dimanche → 6 cases avant, la règle fr de `index.tsx`). */
function buildMonthCells(now = new Date()): MonthCell[] {
  const year = now.getFullYear();
  const month = now.getMonth();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const firstDay = new Date(year, month, 1).getDay();
  const padBefore = firstDay === 0 ? 6 : firstDay - 1;
  const padAfter = (7 - ((padBefore + daysInMonth) % 7)) % 7;
  const prevMonthDays = new Date(year, month, 0).getDate();
  const cells: MonthCell[] = [];
  for (let i = 0; i < padBefore; i++) {
    cells.push({ number: prevMonthDays - padBefore + i + 1, iso: null, faded: true, inMonth: false });
  }
  for (let d = 1; d <= daysInMonth; d++) {
    const iso = `${year}-${String(month + 1).padStart(2, "0")}-${String(d).padStart(2, "0")}`;
    cells.push({ number: d, iso, faded: false, inMonth: true });
  }
  for (let i = 0; i < padAfter; i++) {
    cells.push({ number: i + 1, iso: null, faded: true, inMonth: false });
  }
  return cells;
}

export function MonthView({ events, monthLabel, rootClassName }: MonthViewProps) {
  const cells = useMemo(() => buildMonthCells(), []);
  const now = useMemo(() => new Date(), []);
  const todayDay = now.getDate();

  /* Le libellé du mois (le parent porte déjà `currentMonthLabel`,
   *  on ne le recalcule ici que si rien n'est passé — AD-7 :
   *  jamais une valeur factice). */
  const label =
    monthLabel ??
    now.toLocaleDateString("fr-FR", { month: "long", year: "numeric" });

  /* Les événements groupés par jour ISO + triés par heure (la
   *  lecture naturelle, jamais par index du tableau — AD-7 : si
   *  le miroir renvoie un ordre aléatoire, l'UI reste stable).
   *  Chaque jour de la grille n'affiche QUE SES événements,
   *  jamais les événements des jours pad (`.iso === null`). */
  const byDay = useMemo(() => {
    const map = new Map<string, RenderCalendarEvent[]>();
    for (const ev of events) {
      const key = ev.start.slice(0, 10);
      const arr = map.get(key) ?? [];
      arr.push(ev);
      map.set(key, arr);
    }
    for (const arr of map.values()) {
      arr.sort((a, b) => a.start.localeCompare(b.start));
    }
    return map;
  }, [events]);

  const pillVariants = ["tan-p", "pink-p", "purple-p", "green-p"] as const;

  return (
    <div className={`cal-month-view cal-month-scroll${rootClassName ? ` ${rootClassName}` : ""}`}>
      <div className="cal-month-head">
        <span className="cal-month-head-label">{label}</span>
      </div>

      {/* La rangée des jours (le même alignement que la grille,
          7 colonnes `1fr`, jamais un flex calc(100%/7)). */}
      <div className="cal-month-days-header" aria-hidden>
        {DOW_LETTER.map((letter, i) => (
          <span key={i}>{letter}</span>
        ))}
      </div>

      {/* La grille du mois (les cellules, le pastille de tâche par
          événement — le `data-day` porte l'ISO, le parent pilote
          le scroll « maintenant » s'il le faut plus tard). */}
      <div className="cal-month-grid" role="list" aria-label={label}>
        {cells.map((cell, i) => {
          const isToday = !cell.faded && cell.number === todayDay;
          const dayEvents = cell.iso !== null ? (byDay.get(cell.iso) ?? []) : [];
          return (
            <div
              key={i}
              role="listitem"
              className={`cal-m-day${cell.faded ? " other" : ""}${isToday ? " today" : ""}`}
              data-day={cell.iso ?? undefined}
            >
              <span className="cal-m-day-num">{cell.number}</span>
              {dayEvents.map((ev, j) => {
                const tone = dayEventTone(ev);
                const variant = pillVariants[(j + 1) % pillVariants.length];
                return (
                  <div key={ev.id} className={`cal-m-pill ev-${tone} ${variant}`}>
                    {ev.title}
                  </div>
                );
              })}
            </div>
          );
        })}
      </div>

      <style>{MONTH_VIEW_CSS}</style>
    </div>
  );
}

export const MONTH_VIEW_CSS = `
.cal-month-scroll {
  height: 100%;
  overflow-y: auto;
  padding: 6px 14px 100px;
  box-sizing: border-box;
}
.cal-month-head {
  display: flex;
  align-items: baseline;
  gap: 8px;
  padding: 4px 4px 8px;
}
.cal-month-head-label {
  font-size: 15px;
  font-weight: 700;
  color: var(--text-main);
}
/* La rangée des jours : le grid (7 colonnes 1fr, le même
   alignement que la grille — jamais un flex calc(100%/7)). */
.cal-month-days-header {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  font-size: 10px;
  color: var(--text-muted);
  font-weight: 600;
  text-align: center;
  padding: 2px 0 6px;
}
/* La grille des jours : le grid (7 colonnes, le gap 2px), chaque
   cellule porte le numéro + les pastilles de tâche. */
.cal-month-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 2px;
}
.cal-m-day {
  min-height: 70px;
  padding: 4px 3px 2px;
  display: flex;
  flex-direction: column;
  gap: 2px;
  border-radius: 6px;
  overflow: hidden;
}
.cal-m-day-num {
  width: 22px;
  height: 22px;
  border-radius: 50%;
  font-size: 12px;
  color: var(--text-main);
  display: flex;
  align-items: center;
  justify-content: center;
  font-variant-numeric: tabular-nums;
}
/* Le jour « aujourd'hui » : le fond accent dynamique (le disque,
   le texte passe en blanc, le 700 — jamais une valeur hex en dur,
   le fallback --ion-background-color garde l'isolation lisible en
   thème neutre, AD-13 honest degradation). */
.cal-m-day.today .cal-m-day-num {
  background: var(--dynamic-accent);
  color: var(--ion-contrast-color, var(--ion-background-color, var(--aurora-bg)));
  font-weight: 700;
}
/* Les jours hors du mois courant : l'opacité 0.25 (la cellule,
   jamais un hex de gris inventé — l'opacité porte l'atténuation). */
.cal-m-day.other {
  opacity: 0.25;
}
/* Les pastilles de tâche : le texte (8px, le titre, l'ellipsis),
   la teinte pastel .ev-* (le seul rgba(…) autorisé par la règle
   « pastilles pastel des événements », partagé via shared-ev.ts) +
   la variante -p (la pastille « tâche » au sens large, la même
   valeur pastel que l'événement, jamais une teinte séparée). */
.cal-m-pill {
  font-size: 8px;
  padding: 2px 4px;
  border-radius: 3px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  font-weight: 600;
  color: var(--text-main);
  border: 1px solid var(--glass-border);
  min-width: 0;
}
/* Les 4 variantes de pastille tâche (le fond pastel suit la
   teinte .ev-* — les variantes n'ajoutent qu'un code de lecture
   rapide « tâche » (tan-p/pink-p/purple-p/green-p), jamais une
   couleur en dur : elles héritent du .ev-* de la classe
   principale, ce bloc n'ajoute que le focus/lectibilité). */
.cal-m-pill.tan-p,
.cal-m-pill.pink-p,
.cal-m-pill.purple-p,
.cal-m-pill.green-p {
  /* Les pastilles « tâche » (les variantes -p) conservent le fond
     pastel de la teinte principale (.ev-*) — aucune teinte
     distincte n'est inventée ici, ZÉRO valeur hex en dur, ZÉRO
     nouvelle variable (la règle Phase 3 : les classes .ev-*
     portées par shared-ev.ts suffisent, les variantes -p sont un
     code de lecture rapide, pas une couleur séparée). */
}
${EV_PASTEL_CSS}
`;
