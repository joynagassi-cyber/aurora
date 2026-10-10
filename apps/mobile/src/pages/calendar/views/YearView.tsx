/**
 * YearView (vue « Année ») — 12 mini-mois en 3 colonnes (le pattern
 * « mini-mois » de l'inspiration 2026-10-03 : 3 colonnes, 12
 * mini-grilles, une case par jour, les jours ayant un événement
 * marqués, le « aujourd'hui » en accent dynamique).
 *
 * 100 % div/span standards (interdiction IonGrid/IonRow/IonCol/IonList/
 * IonItem/IonCard, 10-09), les couleurs 100 % variables du thème
 * dynamique (`useDynamicTheme` est branché par le parent
 * `CalendarPage` sur `<html>` — ce composant n'est qu'un `<div>`,
 * jamais de `IonPage`/`IonContent` imbriqués).
 *
 * La structure (le prompt 10-09, le grid classique — JAMAIS un flex
 * `calc(100%/7)`):
 *   · `.cal-year-scroll` : le conteneur défilant (height 100%, le
 *     padding-bottom 100px laisse passer la bottom nav locale du
 *     calendrier) ;
 *   · `.cal-year-grid` : la grille 3 colonnes des 12 mini-mois
 *     (gap 14px vertical / 10px horizontal, jamais un flex
 *     `calc(100%/3)` — c'est du grid CSS natif) ;
 *   · `.cal-y-month` : un mini-mois (le titre 12px, le header 7 jours
 *     7px, la grille des jours 7 colonnes 8px — le `padBefore` est
 *     calculé via `new Date(year, month, 1).getDay()`, Lundi = index
 *     0, la règle fr « lundi-premier » de `index.tsx`/`MonthView`/
 *     `MultiDayView` — jamais l'ordre du système) ;
 *   · `.cal-y-day` : une case de jour (`.has-ev` si le jour a
 *     l'événement, `.today` si le jour = aujourd'hui).
 *
 * Les mini-mois sont GÉNÉRÉS par `.map()` (Phase 3 : jamais un
 * `dangerouslySetInnerHTML`), le composant porte UNIQUEMENT son
 * propre logique de mini-grille (JAMAIS un `MiniMonth.tsx`
 * séparé qui dupliquerait ce calcul — la règle factorisation du
 * batch « MultiDayView sert les 2 vues 3j/7j en 1 composant »).
 *
 * AD-7 (honest data) : la vue reçoit `events` (le miroir local du
 * calendrier, le parent `CalendarPage` le pilote) — si le miroir
 * n'est pas câblé, les 12 mini-mois restent (la grille, le
 * « aujourd'hui », le header), mais AUCUN `.has-ev` (jamais une
 * case marquée factice).
 */
import type { RenderCalendarEvent } from "@aurora/ui";
import { useMemo } from "react";

/** Les 12 mois en français (le format court, jamais un numéro nu
 *  — ref_007, la même règle que `index.tsx`/`MonthView`). L'index 0
 *  = janvier (le `getMonth()` 0-based de `new Date`), la même
 *  convention que `MonthView.buildMonthCells`. */
const MONTH_NAMES = [
  "janvier",
  "février",
  "mars",
  "avril",
  "mai",
  "juin",
  "juillet",
  "août",
  "septembre",
  "octobre",
  "novembre",
  "décembre",
] as const;

/** Les 7 jours de la header 7px (L, M, M, J, V, S, D) — l'ordre
 *  lundi-premier, indexé par `getDay()` (0 = dimanche), la même
 *  constante que `MultiDayView.DAY_LETTER` (le jour 7 lettres,
 *  jamais un mot entier à 7px). */
const DOW_LETTER = ["L", "M", "M", "J", "V", "S", "D"] as const;

/** L'ISO `YYYY-MM-DD` d'un jour de la mini-grille (la clé de
 *  groupage des événements par jour — AD-7 : jamais une clé
 *  factice, l'ISO est calée sur le calendrier, le `getMonth()`
 *  0-based + 1 pour l'index 1-based du mois). */
function isoOf(year: number, month: number, day: number): string {
  return `${year}-${String(month + 1).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
}

export interface YearViewProps {
  /** Les événements de l'année (le miroir local du calendrier,
   *  AD-7 : le parent pilote la donnée, jamais ce composant qui
   *  n'invente rien). */
  events: RenderCalendarEvent[];
  /** L'année affichée (défaute : l'année courante, jamais une
   *  valeur factice — le parent passe l'année réelle du miroir
   *  s'il la porte). */
  year?: number;
  /** La classe racine supplémentaire (le parent peut scoper sur
   *  `.cal-dynamic` pour que le fond image respire derrière, cf.
   *  le parent `CalendarPage`). */
  rootClassName?: string;
}

export function YearView({ events, year, rootClassName }: YearViewProps) {
  const targetYear = year ?? new Date().getFullYear();

  /* L'aujourd'hui (le mois + le jour, pour marquer `.today` dans
   *  la mini-grille de l'année affichée — jamais une date factice
   *  si l'année affichée ≠ l'année courante : le `.today` ne se
   *  dessine QUE si le jour affiché EST l'aujourd'hui). */
  const now = useMemo(() => new Date(), []);
  const todayIso = isoOf(now.getFullYear(), now.getMonth(), now.getDate());

  /* Les événements groupés par jour ISO (la même logique que
   *  `MonthView`/`MultiDayView` — le `byDay` est le SEUL groupage
   *  par jour du calendrier, jamais dupliqué ici, on ne ré-écrit
   *  pas la boucle, on la consomme via la map). */
  const byDay = useMemo(() => {
    const map = new Map<string, RenderCalendarEvent[]>();
    for (const ev of events) {
      const key = ev.start.slice(0, 10);
      const arr = map.get(key) ?? [];
      arr.push(ev);
      map.set(key, arr);
    }
    return map;
  }, [events]);

  const hasEventOnDay = (iso: string): boolean => (byDay.get(iso)?.length ?? 0) > 0;

  /* Les 12 mini-mois : le `.map()` (Phase 3 : jamais un
   *  `dangerouslySetInnerHTML`), chaque `.cal-y-month` porte :
   *  · le titre (12px, --text-main, le `MONTH_NAMES` fr-FR) ;
   *  · la header des 7 jours (7px, --text-muted) ;
   *  · la grille 7 colonnes (gap 1px) : le `padBefore` = le
   *    `getDay()` du 1er jour du mois (0 = dimanche → 6 cases,
   *    Lundi = index 0, la même formule que `MonthView.build-
   *    MonthCells` — le calendrier démarre au LUNDI). */
  const months = useMemo(() => {
    return Array.from({ length: 12 }, (_, m) => {
      const daysInMonth = new Date(targetYear, m + 1, 0).getDate();
      const firstDay = new Date(targetYear, m, 1).getDay();
      const padBefore = firstDay === 0 ? 6 : firstDay - 1;
      const cells: { number: number; iso: string }[] = [];
      for (let i = 0; i < padBefore; i++) cells.push({ number: 0, iso: "" });
      for (let d = 1; d <= daysInMonth; d++) {
        cells.push({ number: d, iso: isoOf(targetYear, m, d) });
      }
      return {
        month: m,
        name: MONTH_NAMES[m],
        cells,
      };
    });
  }, [targetYear]);

  return (
    <div
      className={`cal-year-view cal-year-scroll${rootClassName ? ` ${rootClassName}` : ""}`}
      aria-label={`Année ${targetYear}`}
    >
      <div className="cal-year-title">{targetYear}</div>

      <div className="cal-year-grid">
        {months.map(({ month, name, cells }) => (
          <div key={month} className="cal-y-month">
            <h3 className="cal-y-month-title">{name}</h3>

            {/* La header des 7 jours (7px, --text-muted, le même
                alignement que la grille : 7 colonnes 1fr, jamais
                un flex calc(100%/7)). */}
            <div className="cal-y-dow" aria-hidden>
              {DOW_LETTER.map((letter, i) => (
                <span key={i}>{letter}</span>
              ))}
            </div>

            {/* La grille des jours (7 colonnes, gap 1px) : chaque
                `.cal-y-day` porte `.has-ev` si le jour a
                l'événement (le `byDay` — AD-7 : jamais factice),
                `.today` si le jour = l'aujourd'hui (le `iso`
                est calé sur le calendrier, jamais une date
                inventée). Les jours vides (le `padBefore`, le
                `number: 0`) sont rendus mais `color: transparent`
                (la case existe pour l'alignement de la grille,
                le contenu est masqué). */}
            <div className="cal-y-days" role="list" aria-label={name}>
              {cells.map((cell, i) => {
                const isEmpty = cell.number === 0;
                const isToday = !isEmpty && cell.iso === todayIso;
                const isHasEv = !isEmpty && hasEventOnDay(cell.iso);
                return (
                  <span
                    key={i}
                    role="listitem"
                    className={`cal-y-day${isEmpty ? " empty" : ""}${isHasEv ? " has-ev" : ""}${isToday ? " today" : ""}`}
                  >
                    {isEmpty ? "" : cell.number}
                  </span>
                );
              })}
            </div>
          </div>
        ))}
      </div>

      <style>{YEAR_VIEW_CSS}</style>
    </div>
  );
}

export const YEAR_VIEW_CSS = `
.cal-year-scroll {
  height: 100%;
  overflow-y: auto;
  padding: 10px 16px 100px;
  box-sizing: border-box;
}
.cal-year-title {
  font-size: 15px;
  font-weight: 700;
  color: var(--text-main);
  padding: 4px 4px 10px;
}
/* La grille 3 colonnes des 12 mini-mois (le gap 14px vertical /
   10px horizontal — le grid CSS natif, JAMAIS un flex calc(100%/3)). */
.cal-year-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 14px 10px;
}
.cal-y-month {
  min-width: 0;
}
.cal-y-month-title {
  font-size: 12px;
  font-weight: 700;
  color: var(--text-main);
  margin: 0 0 4px;
}
/* La header des 7 jours (7px, --text-muted, le même alignement
   que la grille : 7 colonnes 1fr, jamais un flex calc(100%/7)). */
.cal-y-dow {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 1px;
  font-size: 7px;
  color: var(--text-muted);
  font-weight: 600;
  text-align: center;
  padding-bottom: 3px;
}
/* La grille des jours (7 colonnes, gap 1px) : chaque case 8px,
   le contenu est masqué si la case est vide (empty →
   color: transparent, la case existe pour l'alignement de la
   grille, le contenu est invisible). */
.cal-y-days {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 1px;
}
.cal-y-day {
  font-size: 8px;
  padding: 2px 0;
  text-align: center;
  border-radius: 3px;
  color: var(--text-main);
  font-variant-numeric: tabular-nums;
}
/* Les jours vides (le padBefore — le color: transparent pour
   que la case existe pour l'alignement de la grille mais le
   contenu est invisible, jamais un hex de gris inventé). */
.cal-y-day.empty {
  color: transparent;
}
/* Les jours ayant un événement (le .has-ev : le fond translucide
   0.35, le texte passe en accent — la seule valeur non variable
   autorisée par la règle « pastilles pastel des événements »,
   jamais un hex opaque en dur). */
.cal-y-day.has-ev {
  background: rgba(10, 132, 255, 0.35);
  color: var(--dynamic-accent);
  font-weight: 700;
}
/* Le jour « aujourd'hui » : le fond accent dynamique (le disque,
   le texte passe en blanc, le 700 — jamais une valeur hex en dur,
   le fallback --ion-background-color garde l'isolation lisible en
   thème neutre, AD-13 honest degradation). */
.cal-y-day.today {
  background: var(--dynamic-accent);
  color: var(--ion-contrast-color, var(--ion-background-color, var(--aurora-bg)));
  font-weight: 700;
}
`;
