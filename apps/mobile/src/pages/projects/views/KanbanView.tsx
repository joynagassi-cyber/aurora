/**
 * KanbanView (vue « Kanban » de /projects, PROMPT 11 — REDESIGNÉ
 * mono-chrome + ZOOMABLE).
 *
 * ⚠️ Cette vue a été REDESIGNÉE (PROMPT 11, 2026-10-10) :
 * - Les CARTES sont MONOCHROMES (tout en niveaux de gris `#1c1c1c` /
 *   `#262626` / `#2a2a2a` / `#333`, AUCUNE couleur de priorité,
 *   AUCUNE bordure latérale) — les 4 en-têtes de colonne sont la
 *   SEULE partie colorée de la vue (leur gradient `rgba(teinte,0.35)`
 *   + leur bordure, les 4 teintes fixées par le prompt, documentées).
 * - Un SLIDER DE ZOOM (barre fixe en bas) pilote la variable CSS
 *   `--zoom` (0 à 1, l'état local du composant) sur le conteneur
 *   `.kb-scroll` : les colonnes, les cartes et le titre de carte
 *   grandissent en temps réel (la formule `calc(180px +
 *   var(--zoom, 0) * 70px)`, etc.).
 *
 * Les 4 colonnes de la famille /projects (le miroir projets, AD-7 :
 * quand le miroir ne câble pas, les compteurs restent 0 + l'état
 * vide honnête + le CTA « + Ajouter une carte » — l'action réelle,
 * jamais une carte factice). Les cartes, QUAND ELLES ARRIVENT (le
 * miroir branché), suivront ce même `KbCard` (monochrome, zoomable),
 * le contenu est déjà la forme attendue : le titre, les labels, la
 * barre de progression, l'avatar — jamais de couleurs par statut
 * (la SEMANTIQUE SANS ÉTAT du prompt : la TEINTE N'EXISTE PLUS SUR
 * LES CARTES, uniquement sur les en-têtes).
 *
 * 100 % div/span standards (interdiction IonList/IonItem/IonGrid/
 * IonRow/IonCol/IonCard — la vue est un div racine simple), les
 * seules couleurs en dur sont celles du prompt (les 4 gradients
 * d'en-tête + les hex de niveau de gris des cartes, documentés
 * `#1c1c1c` / `#262626` / `#2a2a2a` / `#333` / `#eee` / `#aaa` /
 * `#bbb` / `#6a6a6a` / `#141414` / `#1f1f1f` — zéro couleur
 * inventée ailleurs, PHASE 8 du prompt).
 */
import { useState } from "react";
import type { ProjectCard } from "../shared";

/* ── Les 4 colonnes (le même contenu que l'ancienne vue Kanban,
 *   SANS le `band` (la couleur) — le libellé + l'intent du CTA) ── */
const KB_COLUMNS: Array<{ id: string; label: string; addIntent: string }> = [
  {
    id: "todo",
    label: "À planifier",
    addIntent: "Ajoute une carte « définir la prochaine étape » dans ma colonne « À planifier » de mon projet.",
  },
  {
    id: "progress",
    label: "À faire",
    addIntent: "Ajoute une carte dans ma colonne « À faire » de mon projet.",
  },
  {
    id: "review",
    label: "En cours",
    addIntent: "Déplace une carte de « À faire » vers « En cours » dans mon projet.",
  },
  {
    id: "done",
    label: "Terminé",
    addIntent: "Résume les cartes terminées de mon projet dans ma colonne « Terminé ».",
  },
];

/* Le libellé de l'en-tête de colonne (le code couleur, PHASE 3 du
 *   prompt — les 4 gradients fixés, documentés en fin de CSS). */
const KB_HEADER_CLASS: Record<string, string> = {
  todo: "kb-h-todo",
  progress: "kb-h-progress",
  review: "kb-h-review",
  done: "kb-h-done",
};

/**
 * La CARTE MONOCHROME (PHASE 4 du prompt) : le fond `#1c1c1c`, la
 * bordure `#262626`, le titre `#eee`, les labels `#2a2a2a`/`#aaa`,
 * la barre de progression `#262626`/`#6a6a6a`, l'avatar `#333`/
 * `#bbb` — ZÉRO couleur de priorité (PHASE 6 du prompt). Quand le
 * miroir projets arrive, c'est cette forme qu'il rend (le contenu
 * est déjà la structure attendue : titre + labels + progression +
 * avatar, jamais un contenu factice quand le miroir est vide,
 * AD-7 : l'état vide reste l'affordance « + Ajouter une carte »).
 */
export function KbCard({ card }: { card: ProjectCard }) {
  const statusLabel =
    card.status === "termine" ? "Terminé" : card.status === "bloque" ? "Bloqué" : "En cours";
  return (
    <div className="kb-card">
      <span className="kb-card-title">{card.title}</span>
      <div className="kb-card-labels">
        <span className="kb-card-label">{statusLabel}</span>
        <span className="kb-card-label">Jalon · {card.nextMilestone}</span>
      </div>
      <div className="kb-card-progress" aria-hidden>
        <div className="kb-card-progress-fill" style={{ width: `${card.percent}%` }} />
      </div>
      <div className="kb-card-foot">
        <span className="kb-card-av" aria-hidden>
          {card.title.slice(0, 2).toUpperCase()}
        </span>
      </div>
    </div>
  );
}

/**
 * La vue Kanban MONOCHROME + ZOOMABLE (PROMPT 11) — la barre de
 * zoom pilote la variable CSS `--zoom` du conteneur `.kb-scroll`
 * (PHASE 5 du prompt) : `calc(180px + var(--zoom, 0) * 70px)` pour
 * les colonnes, `calc(8px + var(--zoom) * 3px)` pour le padding
 * des cartes, `calc(10.5px + var(--zoom) * 2px)` pour le titre de
 * carte. 4 colonnes + le slider + le compteur (les compteurs
 * restent 0 tant que le miroir ne câble pas, AD-7 honest).
 */
export function KanbanView() {
  /* Le zoom (PHASE 5 du prompt) : l'état local du composant, la
   * variable CSS `--zoom` (0 à 1, le slider) est pilotée via le
   * style inline du conteneur — les `calc()` du CSS la lisent. */
  const [zoom, setZoom] = useState(0.4);

  const handleZoom = (e: React.ChangeEvent<HTMLInputElement>) => {
    setZoom(parseFloat(e.target.value));
  };

  const zoomPercent = Math.round(zoom * 100);

  return (
    <div className="kb-view" style={{ "--zoom": zoom } as React.CSSProperties}>
      <div className="kb-scroll" data-kb-view>
        {KB_COLUMNS.map((col) => (
          <div key={col.id} className="kb-col">
            <div className={`kb-col-header ${KB_HEADER_CLASS[col.id]}`}>
              <span className="kb-col-title">{col.label}</span>
              <span className="kb-col-count">0</span>
            </div>
            <div className="kb-col-body">
              {/* AD-7 : le miroir non câblé → AUCUNE carte (le compte
                  reste 0, l'affordance « + Ajouter une carte » reste
                  l'action réelle — jamais une carte factice rendue).
                  Quand le miroir branchera, ce sera le `KbCard`
                  monochrome qui sera mappé ici. */}
              <a
                className="kb-col-add"
                href={`/agent?intent=${encodeURIComponent(col.addIntent)}`}
              >
                + Ajouter une carte
              </a>
            </div>
          </div>
        ))}

        {/* PHASE 5 du prompt — le slider de zoom (la barre fixe en
            bas, les `--zoom` 0 à 1, le slider pilote le conteneur). */}
        <div className="kb-zoom-bar">
          <svg
            className="kb-zoom-icon"
            width="14"
            height="14"
            viewBox="0 0 16 16"
            fill="none"
            aria-hidden
          >
            <circle cx="6" cy="6" r="4.5" stroke="currentColor" strokeWidth="1.2" />
            <line x1="9.4" y1="9.4" x2="13" y2="13" stroke="currentColor" strokeWidth="1.2" />
            <line x1="4" y1="6" x2="8" y2="6" stroke="currentColor" strokeWidth="1.2" />
          </svg>
          <input
            type="range"
            min="0"
            max="1"
            step="0.1"
            value={zoom}
            onChange={handleZoom}
            className="kb-zoom-slider"
            aria-label="Zoom du Kanban"
          />
          <svg
            className="kb-zoom-icon"
            width="14"
            height="14"
            viewBox="0 0 16 16"
            fill="none"
            aria-hidden
          >
            <circle cx="6" cy="6" r="4.5" stroke="currentColor" strokeWidth="1.2" />
            <line x1="9.4" y1="9.4" x2="13" y2="13" stroke="currentColor" strokeWidth="1.2" />
            <line x1="4" y1="6" x2="8" y2="6" stroke="currentColor" strokeWidth="1.2" />
            <line x1="6" y1="4" x2="6" y2="8" stroke="currentColor" strokeWidth="1.2" />
          </svg>
          <span className="kb-zoom-value">{zoomPercent}%</span>
        </div>
      </div>

      <style>{KANBAN_VIEW_CSS}</style>
    </div>
  );
}

/* Le CSS dédié (PROMPT 11, le mono-chrome + le zoomable) — 100 %
   `.kb-*`, les 4 en-têtes colorés (les SEULS hex du prompt,
   documentés) + les cartes monochromes en niveaux de gris. Le
   conteneur `.kb-scroll` porte `--zoom` (le style inline du
   composant) — les `calc()` de colonne/cartes/texte/padding en
   dépendent (PHASE 2, 4, 5 du prompt). */
export const KANBAN_VIEW_CSS = `
.kb-view {
  position: relative;
  padding: 6px 12px 100px;
}

/* Le conteneur de scroll horizontal (PHASE 2 du prompt) :
   flex + le gap 10px, le scroll horizontal est activé (pas
   vertical, la vue est horizontale). */
.kb-scroll {
  display: flex;
  gap: 10px;
  overflow-x: auto;
  overflow-y: hidden;
  position: relative;
}

/* La colonne (PHASE 2 du prompt) : la LARGUEUR suit le zoom
   (calc(180px + var(--zoom, 0) * 70px) — le slider en pilote la
   valeur en temps réel), le fond + la bordure + l'arrrondi sont
   fixés par le prompt. */
.kb-col {
  flex: none;
  width: calc(180px + var(--zoom, 0) * 70px);
  background: #141414;
  border: 1px solid #1f1f1f;
  border-radius: 14px;
  padding: 8px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

/* L'en-tête de colonne (PHASE 3 du prompt) : la SEULE partie
   COLORÉE de la vue (les 4 gradients par statut, documentés en
   commentaire — les 4 seules couleurs du prompt, jamais plus). */
.kb-col-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 6px;
  padding: 6px 8px;
  border-radius: 8px;
}
.kb-h-todo {
  background: linear-gradient(90deg, rgba(142,142,147,0.35), rgba(142,142,147,0.15));
  border: 1px solid rgba(142,142,147,0.35);
}
.kb-h-progress {
  background: linear-gradient(90deg, rgba(10,132,255,0.35), rgba(10,132,255,0.15));
  border: 1px solid rgba(10,132,255,0.35);
}
.kb-h-review {
  background: linear-gradient(90deg, rgba(255,159,10,0.35), rgba(255,159,10,0.15));
  border: 1px solid rgba(255,159,10,0.35);
}
.kb-h-done {
  background: linear-gradient(90deg, rgba(48,209,88,0.35), rgba(48,209,88,0.15));
  border: 1px solid rgba(48,209,88,0.35);
}
.kb-col-title {
  font-size: 10.5px;
  font-weight: 800;
  color: white;
  text-transform: uppercase;
  letter-spacing: 0.6px;
}
.kb-col-count {
  background: rgba(0,0,0,0.4);
  color: white;
  padding: 1px 7px;
  border-radius: 8px;
  font-weight: 800;
  font-size: 10px;
}

/* Le corps de colonne (le conteneur des cartes) : le scroll
   vertical interne n'existe que si les cartes débordent (le
   miroir vide → l'affordance « + Ajouter une carte » seule). */
.kb-col-body {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

/* L'affordance « + Ajouter une carte » (le CTA agent, l'action
   réelle, AD-7 honest — le miroir ne câble pas, ce CTA reste le
   chemin, jamais une carte factice). */
.kb-col-add {
  display: block;
  width: 100%;
  text-align: center;
  padding: 6px;
  font-size: 11px;
  font-weight: 600;
  color: #6a6a6a;
  background: transparent;
  border: 1px dashed #2a2a2a;
  border-radius: 8px;
  cursor: pointer;
}
.kb-col-add:hover {
  background: rgba(255,255,255,0.03);
  color: #bbb;
}

/* La CARTE MONOCHROME (PHASE 4 du prompt) : le fond + la
   bordure + le padding suivent le zoom (calc(8px +
   var(--zoom) * 3px) / calc(9px + var(--zoom) * 3px)), les
   niveaux de gris sont fixés par le prompt, ZÉRO couleur. */
.kb-card {
  background: #1c1c1c;
  border: 1px solid #262626;
  border-radius: 9px;
  padding: calc(8px + var(--zoom, 0) * 3px) calc(9px + var(--zoom, 0) * 3px);
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.kb-card-title {
  font-size: calc(10.5px + var(--zoom, 0) * 2px);
  color: #eee;
  font-weight: 600;
  line-height: 1.3;
}
/* Les labels (le fond + la couleur du prompt, la taille 7.5px
   fixe, jamais le zoom) : le statut + le jalon, le label est le
   badge (pas une couleur de priorité, le contenu). */
.kb-card-labels {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}
.kb-card-label {
  background: #2a2a2a;
  color: #aaa;
  font-size: 7.5px;
  padding: 1.5px 6px;
  border-radius: 3px;
  font-weight: 700;
}
/* La barre de progression (PHASE 4 du prompt) : le fond #262626
   (la piste), le fill #6a6a6a (l'avancement, la donnée), la
   hauteur 3px fixe (le zoom n'agrandit PAS la barre, c'est le
   contour de la carte qui grandit). */
.kb-card-progress {
  height: 3px;
  background: #262626;
  border-radius: 2px;
  overflow: hidden;
}
.kb-card-progress-fill {
  height: 100%;
  background: #6a6a6a;
  transition: width 0.3s ease;
}
/* L'avatar (PHASE 4 du prompt) : le fond #333, la couleur
   #bbb, la taille 16px, la font 7px (les initiales du projet,
   le contenu réel, jamais une teinte de couleur). */
.kb-card-foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.kb-card-av {
  width: 16px;
  height: 16px;
  border-radius: 50%;
  background: #333;
  color: #bbb;
  font-size: 7px;
  font-weight: 700;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

/* PHASE 5 du prompt — le slider de zoom (la barre fixe en bas,
   le slider 0-1 step 0.1, le label de % à droite, le position
   absolute est celui du prompt : bottom 78px, left/right 14px). */
.kb-zoom-bar {
  position: absolute;
  bottom: 78px;
  left: 14px;
  right: 14px;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 10px;
  background: rgba(0,0,0,0.45);
  border: 1px solid #1f1f1f;
  border-radius: 10px;
  backdrop-filter: blur(6px);
  -webkit-backdrop-filter: blur(6px);
  z-index: 10;
}
.kb-zoom-icon {
  color: #bbb;
  flex: none;
}
.kb-zoom-slider {
  flex: 1;
  -webkit-appearance: none;
  appearance: none;
  height: 4px;
  background: #2a2a2a;
  border-radius: 2px;
  outline: none;
}
.kb-zoom-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: #6a6a6a;
  cursor: pointer;
  border: 2px solid #141414;
}
.kb-zoom-slider::-moz-range-thumb {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: #6a6a6a;
  cursor: pointer;
  border: 2px solid #141414;
}
.kb-zoom-value {
  font-family: "JetBrains Mono", ui-monospace, monospace;
  font-size: 10px;
  font-weight: 700;
  color: #bbb;
  min-width: 3ch;
  text-align: right;
}
`;
