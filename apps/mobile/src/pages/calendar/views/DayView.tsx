/**
 * DayView (vue « Jour ») — timeline horaire 1 colonne (05 §4.4.2,
 * l'inspiration pattern 2026-10-03 : la vue jour est une frise
 * verticale 24h, pas une grille FullCalendar).
 *
 * 100 % div standards (interdiction IonList/IonItem/IonGrid/IonCard,
 * 10-09), les couleurs 100 % variables du thème dynamique
 * (useDynamicTheme : --text-main/--text-muted/--glass-bg/--glass-
 * border/--ion-color-*), le fond « verre » respire derrière.
 *
 * La structure (la grille `.cal-day-grid` est `display: grid` à
 * 2 colonnes 44px/1fr — JAMAIS un flex calc(100%/7), les heures à
 * gauche, les slots à droite) :
 *   · `.cal-day-scroll` : le conteneur défilant (height 100%, le
 *     padding-bottom 100px laisse passer la bottom nav locale du
 *     calendrier) ;
 *   · `.cal-hour-label` : 1 label par heure (58px, à droite, la
 *     bordure `--ion-color-step-100`) ;
 *   · `.cal-day-col` : le slot de droite (la même hauteur 58px,
 *     la bordure gauche+haut, position:relative pour les
 *     événements absolus) ;
 *   · `.cal-ev` : une carte d'événement absolue (top/height en px
 *     calculés depuis l'heure de départ — la page ne fait JAMAIS de
 *     maths par `calc(…)` en flex, c'est du grid classique), 6
 *     teintes pastel (`.ev-tan`/`.ev-blue`/`.ev-pink`/`.ev-purple`/
 *     `.ev-gray`/`.ev-green`) ;
 *   · `.cal-now-line` : le marqueur « maintenant » (la ligne rouge
 *     2px `--ion-color-danger` + le rond 10px, le `::before` porte
 *     le box-shadow qui le fait percer le fond).
 *
 * AD-7 (honest data) : la vue reçoit `events` (le miroir local du
 * calendrier, le parent `CalendarPage` le pilote) — si le miroir
 * n'est pas câblé, la frise est VIDE (le jour, les heures, la ligne
 * « maintenant » restent, jamais une carte factice).
 */
import type { RenderCalendarEvent } from "@aurora/ui";
import { useEffect, useMemo, useRef, useState } from "react";
import { dayEventTone, EV_PASTEL_CSS } from "./shared-ev";

/** L'étendue de la journée affichée (7h → 23h, 17 slots — la règle
 *  de lecture rapide mobile, jamais 24h d'un bloc le premier jour
 *  de l'app). Chaque slot = 58px (la constant `SLOT_H`). */
const DAY_START_HOUR = 7;
const DAY_END_HOUR = 23; // exclusif → 17 slots (7..22)
const SLOT_H = 58;

/** `hh:mm` d'un ISO `start` → l'offset en px depuis 7h00 (le top
 *  absolu de la carte, dans `.cal-day-col`). */
function topOfIso(iso: string): number {
  const d = new Date(iso);
  const mins = d.getHours() * 60 + d.getMinutes();
  const offsetMins = mins - DAY_START_HOUR * 60;
  if (offsetMins < 0 || offsetMins > 24 * 60) return 0;
  return (offsetMins / 60) * SLOT_H;
}

/** La hauteur en px de la carte (de `start` à `end`, min 1 slot si
 *  l'événement n'a pas d'`end`). */
function heightOfIso(start: string, end?: string): number {
  if (!end) return SLOT_H;
  const a = new Date(start).getTime();
  const b = new Date(end).getTime();
  const mins = Math.max(0, (b - a) / 60000);
  return Math.max(SLOT_H, (mins / 60) * SLOT_H);
}

/** Le top de la ligne « maintenant » (l'heure courante du jour, 0 si
 *  on est hors de la fenêtre affichée 7h-23h → la ligne ne se
 *  dessine que si on est dans la fenêtre). */
function nowLineTop(now: Date): number | null {
  const mins = now.getHours() * 60 + now.getMinutes();
  const offsetMins = mins - DAY_START_HOUR * 60;
  if (offsetMins < 0 || offsetMins >= (DAY_END_HOUR - DAY_START_HOUR + 1) * 60) {
    return null;
  }
  return (offsetMins / 60) * SLOT_H;
}

export interface DayViewProps {
  /** Les événements du jour courant (le miroir local du calendrier,
   *  AD-7 : le parent pilote la donnée, jamais ce composant qui
   *  n'invente rien). */
  events: RenderCalendarEvent[];
  /** La date affichée (le « Aujourd'hui » par défaut, jamais une
   *  date factice — le parent passe la date réelle du miroir). */
  dateLabel?: string;
  /** La classe racine supplémentaire (le parent peut scoper sur
   *  `.cal-dynamic` pour que le fond image respire derrière, cf.
   *  le parent `CalendarPage`). */
  rootClassName?: string;
}

/** Le composant Jour (la frise horaire 1 colonne, le pattern
 *  « agenda day » de l'inspiration 2026-10-03). Jamais de
 *  duplicata : c'est le SEUL composant qui porte la frise de jour —
 *  `CalendarPage` le consomme pour la vue `timeGridDay`, jamais un
 *  second composant « DayTimeline »/« DayGrid » ne doit exister
 *  (la règle « pas 2 composants faisant la même chose »).
 *
 *  Le composant est un simple `<div>` (JAMAIS `IonPage`/`IonContent`
 *  imbriqués — il s'intègre DANS le `IonContent` du parent
 *  `CalendarPage`, un double-nid casserait le scroll).
 */
export function DayView({ events, dateLabel, rootClassName }: DayViewProps) {
  const scrollRef = useRef<HTMLDivElement>(null);

  /* Le marqueur « maintenant » (l'heure courante, recalculé à chaque
   *  minute — un `useState` + `setInterval` pour que la ligne
   *  « Maintenant » reste vivante sans re-render l'app entière). */
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    const id = setInterval(() => setNow(new Date()), 60_000);
    return () => clearInterval(id);
  }, []);
  const nowTop = useMemo(() => nowLineTop(now), [now]);

  /* Les événements triés par heure (la lecture naturelle de la
   *  frise), jamais par index du tableau (AD-7 : si le miroir
   *  renvoie un ordre aléatoire, l'UI reste stable). */
  const sortedEvents = useMemo(() => {
    return [...events].sort((a, b) => a.start.localeCompare(b.start));
  }, [events]);

  /* L'heure courante (le label, fr-FR, jamais une valeur brute —
   *  le parent `CalendarPage` porte déjà le `todayLabel`, on ne
   *  le recalcule ici que si rien n'est passé). */
  const label =
    dateLabel ??
    now.toLocaleDateString("fr-FR", {
      weekday: "long",
      day: "numeric",
      month: "long",
    });

  /* 17 slots (7h..22h) : le label de l'heure + le slot de droite
   *  (la grille 2 colonnes `44px 1fr`). */
  const hours: number[] = [];
  for (let h = DAY_START_HOUR; h < DAY_END_HOUR; h++) hours.push(h);

  /* Le scroll initial : l'heure courante − 1 slot (le défilement
   *  automatique « tu vois toujours maintenant »), jamais le haut
   *  brut de la frise. */
  useEffect(() => {
    const el = scrollRef.current;
    if (!el) return;
    const target = Math.max(0, (nowTop ?? 0) - SLOT_H);
    el.scrollTop = target;
  }, [nowTop]);

  const totalHeight = hours.length * SLOT_H;

  return (
    <div
      ref={scrollRef}
      className={`cal-day-view cal-day-scroll${rootClassName ? ` ${rootClassName}` : ""}`}
    >
          <div className="cal-day-head">
            <span className="cal-day-head-title">{label}</span>
            {nowTop !== null && (
              <span className="cal-day-head-now">
                maintenant {now.toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" })}
              </span>
            )}
          </div>

          <div className="cal-day-grid" style={{ height: totalHeight }}>
            {/* La colonne gauche : les labels d'heures (44px, 1
                `.cal-hour-label` par slot, aligné à droite, la
                bordure `--ion-color-step-100`). */}
            <div className="cal-day-hours" aria-hidden>
              {hours.map((h) => (
                <div key={h} className="cal-hour-label">
                  {String(h).padStart(2, "0")}h
                </div>
              ))}
            </div>

            {/* La ligne « maintenant » (un enfant direct de
                `.cal-day-grid`, elle traverse les 2 colonnes : le
                rond ::before est calé à gauche, la ligne 2px à
                droite). */}
            {nowTop !== null && (
              <div
                className="cal-now-line"
                style={{ top: nowTop }}
                role="presentation"
                aria-label="Heure actuelle"
              />
            )}

            {/* La colonne droite : le slot `.cal-day-col` (position:
                relative, les événements absolus se posent ici). */}
            <div className="cal-day-col">
              {sortedEvents.map((ev) => {
                const tone = dayEventTone(ev);
                const top = topOfIso(ev.start);
                const height = heightOfIso(ev.start, ev.end);
                const start = new Date(ev.start);
                const end = ev.end ? new Date(ev.end) : null;
                return (
                  <div
                    key={ev.id}
                    className={`cal-ev ev-${tone}`}
                    style={{ top, height }}
                    role="listitem"
                    aria-label={`${ev.title}, ${start.toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" })}${end ? ` à ${end.toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" })}` : ""}`}
                  >
                    <div className="cal-ev-t">{ev.title}</div>
                    <div className="cal-ev-sub">
                      {start.toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" })}
                      {end ? ` – ${end.toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" })}` : ""}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          <style>{DAY_VIEW_CSS}</style>
    </div>
  );
}

/** Le CSS de la frise (100 % variables du thème dynamique, les
 *  pastilles pastel `.ev-*` sont le seul `rgba(…)` autorisé —
 *  translucides 0.18, le fond « verre » respire derrière). */
export const DAY_VIEW_CSS = `
.cal-day-scroll {
  height: 100%;
  overflow-y: auto;
  padding: 8px 14px 100px;
}
.cal-day-head {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 8px;
  padding: 4px 4px 10px;
}
.cal-day-head-title {
  font-size: 15px;
  font-weight: 700;
  color: var(--text-main);
}
.cal-day-head-now {
  font-size: 11px;
  font-weight: 600;
  color: var(--text-muted);
}
/* La grille 2 colonnes (44px les heures, 1fr le slot) — JAMAIS un
   flex calc(100%/7), c'est du grid classique (la règle de lecture
   rapide mobile, 05 §4.4.2). */
.cal-day-grid {
  display: grid;
  grid-template-columns: 44px 1fr;
  position: relative;
}
.cal-day-hours {
  display: flex;
  flex-direction: column;
}
.cal-hour-label {
  height: 58px;
  font-size: 10px;
  color: var(--text-muted);
  text-align: right;
  padding-right: 10px;
  padding-top: 4px;
  border-top: 1px solid var(--ion-color-step-100);
  box-sizing: border-box;
}
/* Le slot de droite : la bordure gauche+haut (la ligne du
   repère-à-l'heure, la même teinte --ion-color-step-100),
   position:relative pour les événements absolus. */
.cal-day-col {
  border-left: 1px solid var(--ion-color-step-100);
  border-top: 1px solid var(--ion-color-step-100);
  position: relative;
  min-height: 58px;
  overflow: hidden;
}
/* La ligne « maintenant » : le rond 10px qui perce le fond (le
   box-shadow --ion-background-color du ::before), la ligne 2px
   --ion-color-danger qui traverse le slot (z-index 5 au-dessus
   des cartes). */
.cal-now-line {
  position: absolute;
  left: 0;
  right: 0;
  height: 2px;
  background: var(--ion-color-danger);
  z-index: 5;
  pointer-events: none;
}
.cal-now-line::before {
  content: "";
  position: absolute;
  left: 0;
  top: 50%;
  transform: translate(0, -50%);
  width: 10px;
  height: 10px;
  background: var(--ion-color-danger);
  border-radius: 50%;
  box-shadow: 0 0 0 2px var(--ion-background-color);
}
/* Les événements : les cartes absolues (left/right 4px, les
   6 teintes pastel — la seule valeur non variable autorisée,
   translucides 0.18). */
.cal-ev {
  position: absolute;
  left: 4px;
  right: 4px;
  border-radius: 6px;
  padding: 7px 9px;
  font-size: 11px;
  font-weight: 600;
  overflow: hidden;
  color: var(--text-main);
  border: 1px solid var(--glass-border);
}
.cal-ev-t {
  font-size: 11px;
  font-weight: 600;
  color: var(--text-main);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
/* La sous-ligne d'heure (9px, opacité 0.7, --text-muted). */
.cal-ev-sub {
  font-size: 9px;
  opacity: 0.7;
  color: var(--text-muted);
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
/* Les 6 teintes pastel (le seul rgba(…) autorisé — partagé par
   MultiDayView via shared-ev.ts, jamais dupliqué ici). */
${EV_PASTEL_CSS}
`;
