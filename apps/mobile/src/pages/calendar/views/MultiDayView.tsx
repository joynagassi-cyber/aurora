/**
 * MultiDayView (les vues « 3 Jours » / « 7 Jours ») — la frise
 * multi-jours (le pattern « multi-day compact » de l'inspiration
 * 2026-10-03).
 *
 * FACTORISATION (la règle Phase 3) : c'est le SEUL composant de
 * « multi-jours » du calendrier — il est partagé par `threeDayGrid`
 * (`days={3}`) et par la vue semaine (`days={7}`), le même code
 * pour les deux, le prop `days` pilote le nombre de colonnes, le
 * `grid-template-columns` et les jours affichés. JAMAIS un
 * `ThreeDayView`/`WeekView`/`MultiDayView` dupliqué (le nom du
 * fichier = le nom du composant, c'est LUI le composant partagé).
 *
 * 100 % div standards (interdiction IonList/IonItem/IonGrid/IonCard,
 * 10-09), les couleurs 100 % variables du thème dynamique
 * (`useDynamicTheme` est branché par le parent `CalendarPage` sur
 * `<html>` — ce composant n'est qu'un `<div>`, jamais de
 * `IonPage`/`IonContent` imbriqués).
 *
 * La structure (le prompt 10-09, le grid classique — JAMAIS un flex
 * `calc(100%/N)`):
 *   · `.cal-md-head` : le header sticky (1 ligne, la même grille que
 *     le corps : 36px les heures, `repeat(days, 1fr)` les jours),
 *     `border-bottom` + `position: sticky; top: 0` (le fond «
 *     verre » --glass-bg pour que le scroll reste lisible);
 *   · `.cal-md-h` : 1 case par jour (le nom + le numéro, le jour
 *     « aujourd'hui » porte `.today` sur le numéro : le fond
 *     accent dynamique, le disque, le texte blanc);
 *   · `.cal-md-grid` : le corps défilant (le même `grid-template-
 *     columns` que le header, aligné), 1 `.cal-md-cell` par heure ×
 *     par jour (la bordure `--ion-color-step-100`, `position:
 *     relative` pour les événements absolus);
 *   · Les événements (`.cal-md-ev` + une teinte pastel `.ev-*`,
 *     8px, `left/right: 1px`, `border-radius: 3px`) — le même
 *     mapping `accentCode`/`focusSession`/`conflicting` que
 *     `DayView` (le `dayEventTone` est partagé, jamais dupliqué).
 */
import type { RenderCalendarEvent } from "@aurora/ui";
import { useMemo } from "react";
import { dayEventTone, EV_PASTEL_CSS } from "./shared-ev";

/** La fenêtre d'heures affichée (7h → 22h, 16 slots — la même que
 *  `DayView`, la règle de lecture rapide mobile, jamais 24h
 *  d'un bloc). */
const HOURS: number[] = Array.from({ length: 16 }, (_, i) => 7 + i);
const SLOT_H = 44;

/** Les jours en une lettre (L, M, M, J, V, S, D) — indexés par
 *  `getDay()` (0 = dimanche), l'ordre lundi-premier est géré par
 *  `nextDays()` (le jour courant en premier), jamais par le
 *  calendrier du système (`weekday: "narrow"` ne respecte PAS
 *  l'ordre lundi-premier en fr-FR — cf. le `DOW` de `index.tsx`). */
const DAY_LETTER: readonly [string, string, string, string, string, string, string] = [
  "D", "L", "M", "M", "J", "V", "S",
];

/** Les jours affichés : pour `count = 7` (la semaine), la fenêtre
 *  démarre au LUNDI de la semaine courante (l'ordre civel
 *  L-M-M-J-V-S-D, la règle de lecture rapide mobile — jamais
 *  l'aujourd'hui en premier qui donnerait V-S-D-L-M-M-J) ; pour
 *  `count = 3` (les 3 jours), la fenêtre démarre à l'aujourd'hui
 *  (la règle « Maintenant », le jour courant en premier). Jamais
 *  une date factice (les dates viennent du `new Date()` du
 *  miroir, AD-7). */
function nextDays(count: number): Date[] {
  const out: Date[] = [];
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  let start = new Date(today);
  if (count === 7) {
    // Le lundi de la semaine courante (le `getDay()` 0 = dimanche
    // → -1 jour, 1 = lundi → +0, 2 = mardi → -1 … 6 = samedi → -5).
    const mondayOffset = (today.getDay() + 6) % 7;
    start = new Date(today);
    start.setDate(today.getDate() - mondayOffset);
  }
  for (let i = 0; i < count; i++) {
    const d = new Date(start);
    d.setDate(start.getDate() + i);
    out.push(d);
  }
  return out;
}

function isoDay(d: Date): string {
  return d.toISOString().slice(0, 10);
}

export interface MultiDayViewProps {
  /** Le nombre de colonnes (3 pour `threeDayGrid`, 7 pour la vue
   *  semaine — le même composant, la même grille, ZÉRO duplication
   *  de code). */
  days?: 3 | 7;
  /** Les événements (le miroir local du calendrier, AD-7 : le
   *  parent pilote la donnée, jamais ce composant). */
  events: RenderCalendarEvent[];
}

export function MultiDayView({ days = 3, events }: MultiDayViewProps) {
  const daysList = useMemo(() => nextDays(days), [days]);
  const todayIso = useMemo(() => isoDay(new Date()), []);

  /* Les jours du header : en une lettre (L/M/M/J/V/S/D) — le
   *  format compact (la règle de lecture rapide mobile, la largeur
   *  étroite de `days={7}` ne porte jamais un mot entier). */
  const dayNames = useMemo(
    () =>
      daysList.map((d) => DAY_LETTER[d.getDay()] as string),
    [daysList],
  );
  const dayNums = useMemo(
    () => daysList.map((d) => d.getDate()),
    [daysList],
  );
  const isoList = useMemo(
    () => daysList.map((d) => isoDay(d)),
    [daysList],
  );

  /* Les événements, groupés par jour ISO + triés par heure (la
   *  lecture naturelle, jamais par index du tableau — AD-7). */
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

  const gridTemplate = `36px repeat(${days}, 1fr)`;

  /* `isoList` est un `string[]` (jamais undefined à l'exécution) —
     TS ne sait pas qu'un index de tableau est défini, on le rend
     type-safe avec ce fallback, le comportement est inchangé. */
  const isoOf = (col: number): string => isoList[col] as string;

  return (
    <div className="cal-md-scroll">
      {/* Le header sticky : la même grille que le corps (les heures +
          les jours), le fond « verre » pour que le scroll reste
          lisible au-dessus du contenu. */}
      <div className="cal-md-head" style={{ gridTemplateColumns: gridTemplate }}>
        <div className="cal-md-hourhead" aria-hidden />
        {dayNames.map((name, i) => {
          const isToday = isoOf(i) === todayIso;
          return (
            <div key={i} className={`cal-md-h${isToday ? " is-today" : ""}`}>
              <span className="cal-md-h-name">{name}</span>
              <span className={`cal-md-h-num${isToday ? " today" : ""}`}>{dayNums[i]}</span>
            </div>
          );
        })}
      </div>

      {/* Le corps défilant : la grille (les heures à gauche, les
          jours à droite), chaque `.cal-md-cell` porte les
          événements de son heure × son jour (absolus, `left/right:
          1px`, la teinte pastel). */}
      <div className="cal-md-grid" style={{ gridTemplateColumns: gridTemplate }}>
        {HOURS.map((hour) => (
          <div key={hour} className="cal-md-hourrow" aria-hidden>
            {Array.from({ length: days }, (_, col) => (
              <div
                key={col}
                className="cal-md-cell"
                style={{ height: SLOT_H }}
                data-day={isoOf(col)}
                data-hour={hour}
              >
                {hour === HOURS[0] && (
                  <span className="cal-md-cell-hour">{String(hour).padStart(2, "0")}h</span>
                )}
                {(byDay.get(isoOf(col)) ?? [])
                  .filter((ev) => ev.start && new Date(ev.start).getHours() === hour)
                  .map((ev) => {
                    const tone = dayEventTone(ev);
                    return (
                      <div
                        key={ev.id}
                        className={`cal-md-ev ev-${tone}`}
                        style={{ top: 3 + ((new Date(ev.start).getMinutes() / 60) * (SLOT_H - 8)) }}
                        role="listitem"
                        aria-label={ev.title}
                      >
                        {ev.title}
                      </div>
                    );
                  })}
              </div>
            ))}
          </div>
        ))}
      </div>
      <style>{MULTI_DAY_VIEW_CSS}</style>
    </div>
  );
}

export const MULTI_DAY_VIEW_CSS = `
.cal-md-scroll {
  height: 100%;
  overflow-y: auto;
  padding: 8px 14px 100px;
  box-sizing: border-box;
}
/* Le header sticky : la grille (36px + les jours), le fond «
   verre » (le flou laisse le fond image respirer), la bordure
   --ion-color-step-100 (jamais un hex de gris en dur). */
.cal-md-head {
  display: grid;
  padding: 8px 14px;
  border-bottom: 1px solid var(--ion-color-step-100);
  position: sticky;
  top: 0;
  z-index: 6;
  background: var(--glass-bg);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  margin: -8px -14px 0;
}
.cal-md-hourhead {
  height: 36px;
}
.cal-md-h {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1px;
  padding: 4px 0;
  border-left: 1px solid var(--ion-color-step-100);
  min-width: 0;
  overflow: hidden;
}
.cal-md-h-name {
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.06em;
  color: var(--text-muted);
  white-space: nowrap;
}
.cal-md-h-num {
  font-size: 12px;
  font-weight: 600;
  color: var(--text-main);
  width: 20px;
  height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
}
/* Le numéro « aujourd'hui » : le fond accent dynamique, le disque,
   le texte passe en blanc (jamais une valeur hex en dur). */
.cal-md-h-num.today {
  background: var(--dynamic-accent);
  border-radius: 50%;
  color: var(--ion-contrast-color, var(--ion-background-color, var(--aurora-bg)));
}
/* Le corps : la grille (le même grid-template-columns que le
   header — l'alignement heures↔jours), chaque cellule porte les
   événements absolus de son heure × jour. */
.cal-md-grid {
  display: grid;
  gap: 0;
}
.cal-md-hourrow {
  display: contents;
}
.cal-md-cell {
  border-top: 1px solid var(--ion-color-step-100);
  border-right: 1px solid var(--ion-color-step-100);
  position: relative;
  min-height: 52px;
  overflow: hidden;
}
.cal-md-cell-hour {
  position: absolute;
  top: 2px;
  right: 4px;
  font-size: 8px;
  font-variant-numeric: tabular-nums;
  color: var(--text-muted);
  opacity: 0.8;
}
/* Les événements : absolus dans la cellule (left/right 1px, la
   teinte pastel .ev-*, 8px — le seul rgba(…) autorisé par la
   règle « pastilles pastel des événements »). */
.cal-md-ev {
  position: absolute;
  left: 1px;
  right: 1px;
  border-radius: 3px;
  padding: 3px 5px;
  font-size: 8px;
  font-weight: 600;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
  color: var(--text-main);
  border: 1px solid var(--glass-border);
  min-width: 0;
}
/* Les 6 teintes pastel (partagées via shared-ev.ts — jamais
   dupliquées). */
${EV_PASTEL_CSS}
`;
