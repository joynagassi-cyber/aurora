/**
 * shared-ev.ts — les helpers partagés de la frise événementielle du
 * calendrier (AD-17 : le code de teinte est consommé ici, JAMAIS une
 * couleur brute dans le JSX d'une vue).
 *
 * Ce module est le SEUL endroit qui porte le mapping « événement →
 * teinte pastel » (`dayEventTone`) et le jeu de 6 classes pastel
 * (`.ev-*`) : `DayView` (vue Jour) et `MultiDayView` (3/7 jours) le
 * partagent, jamais dupliqué. Le CSS pastel (`EV_PASTEL_CSS`) est
 * ré-exporté par `DAY_VIEW_CSS` (DayView) et intégré dans
 * `MULTI_DAY_VIEW_CSS` (MultiDayView) — les 2 vues portent le même
 * fond translucide 0.18 (la règle « pastilles pastel des événements
 * autorise ces `rgba(…)` — jamais un hex opaque en dur).
 */
import type { RenderCalendarEvent } from "@aurora/ui";

/** Les 6 teintes pastel des événements (AD-17 : le code de teinte
 *  est consommé ici, jamais une couleur brute dans le JSX) — le
 *  mapping `accentCode` → la teinte (`.ev-*`) :
 *  `primary` → blue, `secondary` → tan, `punctual` → purple,
 *  `neutral` → gray, le focus-session → green, le conflit → pink. */
export type EventTone =
  | "tan"
  | "blue"
  | "pink"
  | "purple"
  | "gray"
  | "green";

/** La teinte d'un événement (le focus-session et le conflit
 *  priment sur l'accent-code, la règle de lecture rapide mobile :
 *  les états « importants » sont toujours visibles, jamais
 *  masqués par un accent-couleur). */
export function dayEventTone(ev: RenderCalendarEvent): EventTone {
  if (ev.focusSession) return "green";
  if (ev.conflicting) return "pink";
  switch (ev.accentCode) {
    case "secondary":
      return "tan";
    case "punctual":
      return "purple";
    case "neutral":
      return "gray";
    case "primary":
    default:
      return "blue";
  }
}

/** Les 6 pastilles pastel (le seul `rgba(…)` autorisé par la règle
 *  « pastilles pastel des événements » — translucides 0.18, le fond
 *  « verre » respire derrière). */
export const EV_PASTEL_CSS = `
.ev-tan    { background: rgba(210, 170, 110, 0.18); }
.ev-blue   { background: rgba(10, 132, 255, 0.18); }
.ev-pink   { background: rgba(255, 120, 190, 0.18); }
.ev-purple { background: rgba(160, 100, 255, 0.18); }
.ev-gray   { background: rgba(120, 120, 130, 0.18); }
.ev-green  { background: rgba(48, 209, 88, 0.18); }
`;
