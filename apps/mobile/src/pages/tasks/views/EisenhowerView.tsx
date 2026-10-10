/**
 * EisenhowerView (vue « Quadrants » de /tasks) — la matrice
 * d'Eisenhower REDESIGNÉE (PROMPT 8, 2026-10-10) : le repère
 * orthonormé central + les 4 quadrants (Q1 « à faire » / Q2 « à
 * reporter » / Q3 « à déléguer » / Q4 « à supprimer »).
 *
 * REDESIGN VALIDÉ — les INTERDICTIONS (Phase 3) sont absolues :
 *   ❌ AUCUNE barre latérale colorée sur les cartes de tâches ;
 *   ❌ AUCUNE couleur sur les cartes elles-mêmes (le fond est le
 *     translucide `rgba(0,0,0,0.35)`, le contour le quasi-invisible
 *     `rgba(255,255,255,0.04)` — les deux valeurs translucides neutres
 *     autorisées par le redesign, JAMAIS un hex opaque de teinte) ;
 *   ✅ Les couleurs vivent UNIQUEMENT sur : l'en-tête de chaque
 *     quadrant (le gradient 0.28 → 0.08 + la bordure 0.3) et le
 *     repère orthonormé (`var(--dynamic-accent)` — la couleur suit
 *     le thème dynamique du parent, jamais une valeur brute).
 *
 * La structure (Phase 2, le grid CSS natif — JAMAIS un flex
 * `calc(100%/…)` : `IonGrid`/`IonRow`/`IonCol` sont interdits) :
 *   · `.ei-wrap` : le wrapper (le `display: grid` 3 colonnes
 *     [axe-y / la matrice / le vide] × 3 lignes [le vide / matrice
 *     / axe-x] — l'axe Y reste collé à la matrice, l'axe X dessous,
 *     jamais un absolu qui déborde) ;
 *   · `.ei-axis-y` : le label vertical « IMPORTANT » (la rotation
 *     -90°, `writing-mode` + `transform` pour la lisibilité), la
 *     flèche `▲` en haut (opacité 0.8) + `▼` en bas (opacité 0.3)
 *     — les deux en `var(--dynamic-accent)` ;
 *   · `.ei-grid` : la matrice 2×2 (le position relative pour le
 *     repère), chaque quadrant `.ei-q` porte `.ei-q-header` (le
 *     gradient + la bordure — le SEUL bloc coloré), `.ei-q-title`
 *     (le libellé métier, la couleur du quadrant) + `.ei-q-subtitle`
 *     (« Important · Urgent » etc.), les cartes `.ei-card` SANS
 *     couleur (le fond noir translucide, le contour blanc quasi-
 *     invisible, JAMAIS une teinte du quadrant) ;
 *   · `.ei-cross` : le repère orthonormé (le `::before` = la ligne
 *     horizontale `linear-gradient(90deg, transparent,
 *     var(--dynamic-accent), transparent)` opacité 0.65, le
 *     `::after` = la verticale `linear-gradient(180deg, …)` identique
 *     — le centre de la matrice, jamais un absolu hors grille) ;
 *   · `.ei-origin` : le point central (le rond 10px
 *     `var(--dynamic-accent)`, le ring `--ion-background-color` qui
 *     le détache de la ligne + le glow `var(--dynamic-accent)` —
 *     l'unique glow du redesign, autorisé sur le repère SEUL) ;
 *   · `.ei-axis-x` : le label horizontal « URGENT » + la flèche
 *     `◀` (opacité 0.3, à gauche) + `▶` (opacité 0.8, à droite) —
 *     les deux en `var(--dynamic-accent)` ;
 *   · La barre de filtres en haut (`.ei-filters` : « Toutes »/
 *     « Aujourd'hui »/« En retard »/« Sans date ») — l'état local
 *     du filtre vit ICI (jamais dans `ui-state.ts` qui ne connaît
 *     que les 4 vues T4 ; AD-7 : le filtre est cosmétique, la
 *     donnée vient toujours du miroir `useTasks`, le filtrage ne
 *     mute jamais la donnée).
 *
 * 100 % `div`/`span` standards (interdiction IonList/IonItem/IonGrid/
 * IonRow/IonCol/IonCard, 10-09), les couleurs 100 % variables du
 * thème dynamique (le parent `/tasks` consomme `useDynamicTheme` via
 * l'image de fond — ce composant est un simple `<div>`, jamais de
 * `IonPage`/`IonContent` imbriqués).
 *
 * AD-7 (honest data) : la vue reçoit `tasks` (le miroir local du
 * module Tâches, le parent pilote la donnée) — si le miroir n'a
 * aucune tâche, les 4 quadrants restent VIDES (l'état « Vide »
 * honnête sous chaque en-tête, jamais une carte factice).
 */
import { useMemo, useState } from "react";
import type { Task } from "@aurora/domain";

/** Les 4 filtres de la barre du haut (le label court, la clé de
 *  filtrage — « Toutes » = aucun filtre, les 3 autres sont les
 *  états d'échéance de la tâche : aujourd'hui / en retard / sans
 *  date. La donnée est toujours le miroir local, AD-7 : le filtrage
 *  est une LECTURE (le `filter`), jamais une mutation). */
const EI_FILTERS = [
  { key: "all", label: "Toutes" },
  { key: "today", label: "Aujourd'hui" },
  { key: "overdue", label: "En retard" },
  { key: "nodate", label: "Sans date" },
] as const;
type EiFilter = (typeof EI_FILTERS)[number]["key"];

/** Le quadrant d'une tâche (la règle métier existante de
 *  `tasks/index.tsx`, lue ici en propre pour que la vue soit
 *  autonome : `urgent` = une échéance est posée, `important` =
 *  priorité 4 ou 5 — Q1 à faire / Q2 à reporter / Q3 à déléguer /
 *  Q4 à supprimer). Le code de quadrant est consommé ici, jamais
 *  une couleur brute (AD-17, la couleur vit dans le CSS
 *  `.ei-q1`…`.ei-q4`). */
function quadrantOf(t: Task): "q1" | "q2" | "q3" | "q4" {
  const urgent = Boolean(t.dueAt);
  const important = t.priority !== undefined && t.priority >= 4;
  if (urgent && important) return "q1";
  if (!urgent && important) return "q2";
  if (urgent && !important) return "q3";
  return "q4";
}

/** La tâche est-elle « aujourd'hui » (l'échéance tombe dans la
 *  journée courante, avant minuit passé) ? — le bornage `>=
 *  dayStart && < dayStart+1j`, jamais une date factice (AD-7). */
function isToday(t: Task): boolean {
  if (!t.dueAt) return false;
  const due = new Date(t.dueAt);
  if (Number.isNaN(due.getTime())) return false;
  const now = new Date();
  const dayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const dayEnd = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
  return due >= dayStart && due < dayEnd;
}

/** La tâche est-elle « en retard » (l'échéance passée ET non
 *  terminée — une tâche `done` échue n'est plus en retard, elle
 *  est close : l'état du miroir prime, AD-7). */
function isOverdue(t: Task): boolean {
  if (!t.dueAt || t.status === "done") return false;
  const due = new Date(t.dueAt);
  if (Number.isNaN(due.getTime())) return false;
  const now = new Date();
  const dayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  return due < dayStart;
}

export interface EisenhowerViewProps {
  /** Les tâches du module (le miroir local `useTasks`, AD-7 : le
   *  parent pilote la donnée, jamais ce composant qui n'invente
   *  rien). */
  tasks: Task[];
  /** La classe racine supplémentaire (le parent peut scoper sur
   *  `.cal-dynamic`-style pour que le fond image respire derrière). */
  rootClassName?: string;
}

export function EisenhowerView({ tasks, rootClassName }: EisenhowerViewProps) {
  /* Le filtre courant (l'état LOCAL de la barre, jamais `ui-state`
   *  — le prompt n'exige pas de persistance, AD-7 : cosmétique). */
  const [filter, setFilter] = useState<EiFilter>("all");

  /* Le filtrage par l'état d'échéance (la lecture, jamais une
   *  mutation du miroir) : « Aujourd'hui » = l'échéance du jour,
   *  « En retard » = l'échéance passée non close, « Sans date » =
   *  l'échéance absente — « Toutes » = le miroir complet. */
  const filtered = useMemo(() => {
    switch (filter) {
      case "today":
        return tasks.filter(isToday);
      case "overdue":
        return tasks.filter(isOverdue);
      case "nodate":
        return tasks.filter((t) => !t.dueAt);
      case "all":
      default:
        return tasks;
    }
  }, [tasks, filter]);

  /* Les 4 quadrants (le groupage par la règle métier
   *  `quadrantOf`, trié par priorité décroissante ensuite — la
   *  lecture « ce qui compte d'abord » dans chaque quadrant,
   *  jamais l'ordre brut du miroir). */
  const q = useMemo(() => {
    const map: Record<"q1" | "q2" | "q3" | "q4", Task[]> = {
      q1: [],
      q2: [],
      q3: [],
      q4: [],
    };
    for (const t of filtered) map[quadrantOf(t)].push(t);
    for (const key of Object.keys(map) as Array<keyof typeof map>) {
      map[key].sort(
        (a, b) => (b.priority ?? 0) - (a.priority ?? 0),
      );
    }
    return map;
  }, [filtered]);

  return (
    <div
      className={`eisenhower-view${rootClassName ? ` ${rootClassName}` : ""}`}
      data-state="success"
    >
      {/* La barre de filtres du haut (le `.ei-filters` : les 4
          états d'échéance, le filtre courant porte `.active` —
          l'accent dynamique, jamais une teinte par filtre). */}
      <div className="ei-filters" role="tablist" aria-label="Filtrer les tâches">
        {EI_FILTERS.map((f) => (
          <button
            key={f.key}
            type="button"
            role="tab"
            aria-selected={filter === f.key}
            className={`ei-filter${filter === f.key ? " active" : ""}`}
            onClick={() => setFilter(f.key)}
          >
            {f.label}
          </button>
        ))}
      </div>

      {/* Le wrapper de la matrice (le grid 3 colonnes / 3 lignes :
          l'axe Y à gauche de la matrice, l'axe X en dessous, le
          repère orthonormé au centre — JAMAIS un absolu qui
          déborde la grille, c'est du CSS Grid natif). */}
      <div className="ei-wrap">
        {/* L'axe Y (le label vertical « IMPORTANT », la rotation
            -90°, les 2 flèches `▲` (haut, 0.8) / ▼ (bas, 0.3) —
            la couleur suit le thème dynamique). */}
        <div className="ei-axis-y" aria-hidden>
          <span className="ei-axis-y-arrow ei-axis-y-arrow-top">▲</span>
          <span className="ei-axis-y-label">IMPORTANT</span>
          <span className="ei-axis-y-arrow ei-axis-y-arrow-bottom">▼</span>
        </div>

        {/* La matrice 2×2 (le position relative porte le repère
            orthonormé au centre, les 4 quadrants en grid natif). */}
        <div className="ei-grid">
          {/* Le repère orthonormé (la ligne horizontale ::before +
              la verticale ::after, le point central `.ei-origin`
              qui « perce » la ligne — l'unique glow du redesign,
              autorisé ICI SEUL sur le repère). */}
          <div className="ei-cross" aria-hidden />
          <div className="ei-origin" aria-hidden />

          {/* Les 4 quadrants (l'en-tête coloré — le SEUL bloc
              teinté du redesign — + le libellé métier + le
              sous-titre + les cartes SANS couleur). */}
          {(
            [
              ["q1", "À FAIRE", "Important · Urgent"],
              ["q2", "À REPORTER", "Important · Non urgent"],
              ["q3", "À DÉLÉGUER", "Urgent · Non important"],
              ["q4", "À SUPPRIMER", "Non urgent · Non important"],
            ] as const
          ).map(([key, title, subtitle]) => (
            <div key={key} className={`ei-q ei-${key}`}>
              <div className="ei-q-header">
                <span className="ei-q-title">{title}</span>
                <span className="ei-q-subtitle">{subtitle}</span>
              </div>
              {q[key].length === 0 ? (
                <p className="ei-q-empty">Vide</p>
              ) : (
                q[key].map((t) => (
                  <div key={t.id} className="ei-card">
                    <span className="ei-card-title">{t.title}</span>
                  </div>
                ))
              )}
            </div>
          ))}
        </div>

        {/* L'axe X (le label horizontal « URGENT », la flèche ◀
            à gauche (0.3) + `▶` à droite (0.8) — la couleur suit
            le thème dynamique). */}
        <div className="ei-axis-x" aria-hidden>
          <span className="ei-axis-x-arrow ei-axis-x-arrow-left">◀</span>
          <span className="ei-axis-x-label">URGENT</span>
          <span className="ei-axis-x-arrow ei-axis-x-arrow-right">▶</span>
        </div>
      </div>

      <style>{EISENHOWER_VIEW_CSS}</style>
    </div>
  );
}

/** Le CSS de la matrice (PROMPT 8) — les couleurs vivent UNIQUEMENT
 *  sur les en-têtes de quadrant (le gradient + la bordure) et le
 *  repère orthonormé (`var(--dynamic-accent)`), JAMAIS sur les
 *  cartes (le fond translucide neutre `rgba(0,0,0,0.35)` + le
 *  contour quasi-invisible blanc 0.04 — les 2 valeurs du redesign
 *  validé, le SEUL `rgba` opaque du composant, autorisées par le
 *  prompt : « les couleurs uniquement sur l'en-tête + le repère »). */
export const EISENHOWER_VIEW_CSS = `
.eisenhower-view {
  display: flex;
  flex-direction: column;
  gap: 14px;
  padding: 8px 16px 100px;
}
/* La barre de filtres du haut (le 4 boutons, l'accent dynamique
   sur le filtre courant, jamais une teinte par filtre). */
.ei-filters {
  display: flex;
  gap: 6px;
  overflow-x: auto;
  -webkit-overflow-scrolling: touch;
}
.ei-filter {
  flex: none;
  font-size: 12px;
  font-weight: 600;
  color: var(--text-muted, var(--ion-color-step-500));
  padding: 6px 10px;
  border-radius: 9999px;
  border: 1px solid var(--glass-border, var(--ion-color-step-250));
  background: transparent;
  transition: background-color 0.18s ease, color 0.18s ease;
}
.ei-filter.active {
  background: var(--dynamic-accent);
  color: var(--ion-contrast-color, var(--ion-background-color, var(--aurora-bg)));
  border-color: transparent;
}
/* Le wrapper (le grid 3 colonnes [axe-y / matrice / vide] ×
   3 lignes [vide / matrice / axe-x] — l'axe Y collé à la
   matrice, l'axe X dessous, jamais un absolu qui déborde). */
.ei-wrap {
  display: grid;
  grid-template-columns: 18px 1fr;
  grid-template-rows: 1fr 18px;
  gap: 6px;
}
/* L'axe Y (le label vertical « IMPORTANT », la rotation -90° —
   le writing-mode + le transform pour la lisibilité, les 2
   flèches ▲ (haut, 0.8) / ▼ (bas, 0.3), la couleur suit le thème
   dynamique, JAMAIS une valeur brute). */
.ei-axis-y {
  grid-column: 1;
  grid-row: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: space-between;
  color: var(--dynamic-accent);
}
.ei-axis-y-arrow {
  font-size: 9px;
  line-height: 1;
}
.ei-axis-y-arrow-top {
  opacity: 0.8;
}
.ei-axis-y-arrow-bottom {
  opacity: 0.3;
}
/* Le label vertical (le writing-mode vertical-rl + la
   rotation 180° — la lecture « bas vers haut », la convention des
   axes Y d'un repère orthonormé, jamais le transform seul
   qui casse l'alignement grid). */
.ei-axis-y-label {
  writing-mode: vertical-rl;
  transform: rotate(180deg);
  font-size: 8px;
  font-weight: 700;
  letter-spacing: 0.12em;
  color: var(--dynamic-accent);
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}
/* L'axe X (le label horizontal « URGENT », la flèche ◀ (gauche,
   0.3) + ▶ (droite, 0.8), la couleur suit le thème dynamique). */
.ei-axis-x {
  grid-column: 2;
  grid-row: 2;
  display: flex;
  align-items: center;
  gap: 6px;
  color: var(--dynamic-accent);
}
.ei-axis-x-arrow {
  font-size: 9px;
  line-height: 1;
}
.ei-axis-x-arrow-left {
  opacity: 0.3;
}
.ei-axis-x-arrow-right {
  opacity: 0.8;
}
.ei-axis-x-label {
  font-size: 8px;
  font-weight: 700;
  letter-spacing: 0.12em;
  color: var(--dynamic-accent);
  margin-left: auto;
  margin-right: auto;
}
/* La matrice 2×2 (le position relative porte le repère
   orthonormé au centre, le grid natif des quadrants, le gap 0
   pour que le repère tombe exactement au centre de la matrice). */
.ei-grid {
  grid-column: 2;
  grid-row: 1;
  display: grid;
  grid-template-columns: 1fr 1fr;
  grid-template-rows: 1fr 1fr;
  gap: 0;
  position: relative;
  min-height: 320px;
}
/* Le repère orthonormé (la ligne horizontale ::before + la
   verticale ::after, le gradient transparent→accent→transparent
   qui « fond » dans le fond (l'opacité 0.65), le centre de la
   matrice, jamais un absolu hors la grille). */
.ei-cross {
  position: absolute;
  left: 0;
  right: 0;
  top: 50%;
  height: 0;
  pointer-events: none;
}
.ei-cross::before {
  content: "";
  position: absolute;
  left: 0;
  right: 0;
  top: 0;
  height: 1.5px;
  background: linear-gradient(90deg, transparent, var(--dynamic-accent), transparent);
  opacity: 0.65;
}
.ei-cross::after {
  content: "";
  position: absolute;
  top: -120px;
  bottom: -120px;
  left: 0;
  width: 1.5px;
  background: linear-gradient(180deg, transparent, var(--dynamic-accent), transparent);
  opacity: 0.65;
}
/* Le point central (le rond 10px accent dynamique, le
   ring ion-background-color qui le détache de la ligne, le
   UNIQUE glow du redesign — l'UNIQUE glow du redesign,
   autorisé ICI SEUL sur le repère, jamais sur les cartes). */
.ei-origin {
  position: absolute;
  left: 50%;
  top: 50%;
  transform: translate(-50%, -50%);
  width: 10px;
  height: 10px;
  background: var(--dynamic-accent);
  border-radius: 50%;
  box-shadow: 0 0 0 3px var(--ion-background-color, var(--ion-color-step-100)), 0 0 12px var(--dynamic-accent);
  z-index: 3;
  pointer-events: none;
}
/* Les 4 quadrants (le grid natif, le position relative pour
   que le contenu passe au-dessus du repère (z-index 2 < l'origin
   3 — le point central « perce » les cartes qui passent sous),
   le padding qui laisse respirer le contenu du repère). */
.ei-q {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 10px 8px;
  z-index: 1;
  min-width: 0;
}
/* L'en-tête de quadrant (le SEUL bloc coloré du redesign : le
   gradient 0.28 → 0.08 + la bordure 0.3 de la teinte du quadrant
   — les 4 teintes sont FIXES par le redesign validé, JAMAIS
   re-définies par un thème (la règle « les couleurs du
   redesign validé sont figées » — AD-13 honest degradation :
   si le thème change l'accent, les 4 quadrants restent les 4
   teintes du redesign, le repère seul suit l'accent). */
.ei-q-header {
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: 8px 10px;
  border-radius: 6px;
}
/* Q1 : le rouge (le gradient 90deg 0.28 → 0.08, la bordure 0.3). */
.ei-q1 .ei-q-header {
  background: linear-gradient(90deg, rgba(255, 69, 58, 0.28), rgba(255, 69, 58, 0.08));
  border: 1px solid rgba(255, 69, 58, 0.3);
}
/* Q2 : le vert (le gradient 90deg 0.28 → 0.08, la bordure 0.3). */
.ei-q2 .ei-q-header {
  background: linear-gradient(90deg, rgba(48, 209, 88, 0.28), rgba(48, 209, 88, 0.08));
  border: 1px solid rgba(48, 209, 88, 0.3);
}
/* Q3 : le orange (le gradient 90deg 0.28 → 0.08, la bordure 0.3). */
.ei-q3 .ei-q-header {
  background: linear-gradient(90deg, rgba(255, 159, 10, 0.28), rgba(255, 159, 10, 0.08));
  border: 1px solid rgba(255, 159, 10, 0.3);
}
/* Q4 : le gris (le gradient 90deg 0.28 → 0.08, la bordure 0.3). */
.ei-q4 .ei-q-header {
  background: linear-gradient(90deg, rgba(142, 142, 147, 0.28), rgba(142, 142, 147, 0.08));
  border: 1px solid rgba(142, 142, 147, 0.3);
}
/* Le libellé métier (le titre du quadrant, la couleur du
   quadrant, le 700 — les 4 couleurs FIXES du redesign validé,
   jamais une valeur du thème). */
.ei-q-title {
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 0.04em;
}
.ei-q1 .ei-q-title {
  color: #ff6b60;
}
.ei-q2 .ei-q-title {
  color: #4ade80;
}
.ei-q3 .ei-q-title {
  color: #ffb84d;
}
.ei-q4 .ei-q-title {
  color: #b0b0b0;
}
/* Le sous-titre (le « Important · Urgent » etc., le texte
   atténué du quadrant, le 11px). */
.ei-q-subtitle {
  font-size: 11px;
  color: var(--text-muted, var(--ion-color-step-500));
  opacity: 0.8;
}
/* L'état vide (le « Vide » sous l'en-tête, le texte atténué —
   jamais une carte factice, AD-7 honest data). */
.ei-q-empty {
  margin: 0;
  font-size: 12px;
  color: var(--text-muted, var(--ion-color-step-500));
  opacity: 0.6;
}
/* Les cartes de tâches SANS couleur (le fond translucide neutre
   quasi-invisible noir translucide 0.35 + le contour quasi-invisible
   quasi-invisible blanc 0.04 — les 2 valeurs du redesign validé,
   le SEUL rgba du composant, JAMAIS une teinte du quadrant
   sur la carte, JAMAIS une barre latérale colorée (Phase 3 :
   l'interdiction absolue), le texte passe en blanc pour rester
   lisible sur le fond noir translucide). */
.ei-card {
  background: rgba(0, 0, 0, 0.35);
  border: 1px solid rgba(255, 255, 255, 0.04);
  border-radius: 7px;
  padding: 6px 8px;
}
.ei-card-title {
  font-size: 13px;
  font-weight: 500;
  color: var(--ion-color-step-50, var(--aurora-text-primary));
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  display: block;
}
`;
