/**
 * Skeletons "shape-feature" (AD-13 loading/killed, 05 §2.6).
 *
 * Un skeleton doit préviser la FORME de la feature en cours de chargement
 * (carte d'objectif, rangée de tâche, slot générique), pas un placeholder
 * générique. Chacun reproduit le layout réel de sa feature cible (mêmes
 * classes de contenu quand c'est possible : `.goal-cards`, `.task-list`).
 *
 * CSS : `.sk-*` (styles/shell.css) — tokens only, pulse opacité GPU,
 * respect de prefers-reduced-motion (05 §3).
 */

/** Une ligne de placeholder. */
function SkLine({ w }: { w?: string }) {
  return <div className={`sk sk-line${w ? ` sk-line-${w}` : ''}`} />;
}

/**
 * Skeleton du SLOT "Progression critique" (Home slot 2) : 1 carte
 * d'objectif (avatar + titre + progression), forme de `.goal-card`.
 */
export function GoalCardSkeleton({ count = 1 }: { count?: number }) {
  return (
    <div data-skeleton="goal-card" aria-hidden className="goal-cards">
      {Array.from({ length: count }, (_, i) => (
        <div key={i} className="sk sk-card">
          <div className="sk-card-head">
            <div className="sk sk-circle" />
            <div className="sk-lines">
              <SkLine w="t2" />
              <SkLine w="t3" />
            </div>
          </div>
          <div className="sk sk-progress" />
        </div>
      ))}
    </div>
  );
}

/**
 * Skeleton du SLOT "Next actions" (Home slot 7) : rangées de tâche
 * (pastille statut + titre + échéance), forme de `.task-row`.
 */
export function TaskRowSkeleton({ count = 3 }: { count?: number }) {
  return (
    <div data-skeleton="task-row" aria-hidden className="task-list">
      {Array.from({ length: count }, (_, i) => (
        <div key={i} className="sk sk-row">
          <div className="sk sk-dot" />
          <div className="sk-lines">
            <SkLine w="t4" />
            <SkLine w="t5" />
          </div>
          <div className="sk sk-chip" />
        </div>
      ))}
    </div>
  );
}

/**
 * Skeleton générique pour un slot à contenu libre (titre + lignes).
 * Sert les slots Home sans forme dédiée + les écrans simples.
 */
export function SlotSkeleton({ rows = 2 }: { rows?: number }) {
  return (
    <div data-skeleton="slot" aria-hidden>
      <SkLine w="t3" />
      {Array.from({ length: rows }, (_, i) => (
        <SkLine key={i} w={i % 2 ? 't4' : 't5'} />
      ))}
    </div>
  );
}

/**
 * Skeleton de la vue "Quadrants" (/tasks, G-L5) : la matrice
 * EISENHOWER REDESIGNÉE (PROMPT 8, 2026-10-10) — le wrapper
 * `.ei-wrap` (l'axe Y à gauche, la matrice 2×2 au centre, l'axe X
 * en dessous) + les 4 en-têtes de quadrant `.ei-q-header` (le SEUL
 * bloc coloré du redesign, le gradient de la teinte du quadrant) +
 * les cartes SANS couleur (le fond translucide neutre, le contour
 * quasi-invisible). L'ancienne grille `.eisenhower*` (liserés 3px
 * colorés + fond teinté `color-mix`) n'existe plus, ce skeleton
 * reproduit la FORME réelle de la nouvelle matrice (règle AD-13 :
 * le skeleton prévisse le layout, jamais un placeholder générique).
 */
export function EisenhowerSkeleton() {
  const quadrants = ['q1', 'q2', 'q3', 'q4'] as const;
  return (
    <div data-skeleton="eisenhower" aria-hidden className="eisenhower-view">
      <div className="ei-wrap">
        <div className="ei-axis-y" aria-hidden>
          <span className="sk sk-line sk-line-t3" />
        </div>
        <div className="ei-grid">
          {quadrants.map((key) => (
            <div key={key} className={`ei-q ei-${key}`}>
              <div className="ei-q-header">
                <SkLine w="t3" />
              </div>
              <div className="sk sk-row">
                <div className="sk sk-dot" />
                <div className="sk-lines">
                  <SkLine w="t4" />
                </div>
              </div>
              <div className="sk sk-row">
                <div className="sk sk-dot" />
                <div className="sk-lines">
                  <SkLine w="t5" />
                </div>
              </div>
            </div>
          ))}
        </div>
        <div className="ei-axis-x" aria-hidden>
          <SkLine w="t3" />
        </div>
      </div>
    </div>
  );
}

/**
 * Skeleton de la liste /goals (forme VRAIE `.goal-row` dans `.goals-list` :
 * libellé de famille + titre de l'objectif), pas un placeholder générique.
 */
export function GoalRowSkeleton({ count = 3 }: { count?: number }) {
  return (
    <div data-skeleton="goal-row" aria-hidden className="goals-list goals-list-wrap">
      {Array.from({ length: count }, (_, i) => (
        <div key={i} className="sk sk-goal-row">
          <SkLine w="t5" />
          <SkLine w="t3" />
        </div>
      ))}
    </div>
  );
}

/**
 * Skeleton du Goal Dashboard (/goals/:id, goal-dashboard-ui S2–S4) :
 * bandeau d'en-tête (titre + critères + horizon + barre de progression),
 * rangées de NŒUDS DE FEATURE (forme réelle `.goal-feature-node` 96×56)
 * et strip de contexte (chips de stats + suggestion).
 * Forme exacte de `.goal-dashboard` quand la donnée arrive.
 */
export function GoalDashboardSkeleton() {
  return (
    <div data-skeleton="goal-dashboard" aria-hidden className="goal-dashboard">
      <div className="sk sk-dashboard-header">
        <div className="sk-lines-column">
          <SkLine w="t2" />
          <SkLine w="t4" />
          <SkLine w="t3" />
        </div>
        <div className="sk sk-progress" />
      </div>
      <div className="sk sk-node-row">
        <div className="sk sk-node" />
        <div className="sk sk-node" />
      </div>
      <div className="sk sk-node-row">
        <div className="sk sk-node" />
      </div>
      <div className="sk sk-context-strip">
        <div className="sk sk-chips">
          <div className="sk sk-chip" />
          <div className="sk sk-chip" />
        </div>
        <SkLine w="t4" />
      </div>
    </div>
  );
}

/**
 * Skeleton de la carte de veille (discovery-vault plan 2026-10-10, Lot 4,
 * AD-13) : la forme de `.veille-program-card` (`.sk-card` de shell.css).
 * Titre de programme + sous-titre (l'action configurée), un chip de
 * "sources ce jour" + delta, un verdict de pertinence, le menu 3
 * points (`.sk-dot`) ET le rendu TipTap du SSoT `vaultMd` (Lot 4.1)
 * prévisualisé par un bloc de contenu (`.vault-md-view`). Le skeleton
 * prévisse la FORME réelle de la carte (règle AD-13 : jamais un
 * placeholder générique).
 */
export function VeilleProgramSkeleton({ count = 2 }: { count?: number }) {
  return (
    <div data-skeleton="veille-program" aria-hidden className="veille-programs">
      {Array.from({ length: count }, (_, i) => (
        <div key={i} className="sk sk-card veille-program-card">
          <div className="sk-card-head">
            <div className="sk-lines">
              <div className="sk sk-line sk-line-t3" />
              <div className="sk sk-line sk-line-t5" />
            </div>
            <div className="sk sk-dot" />
          </div>
          <div className="sk veille-card-stats">
            <div className="sk sk-chip" />
            <div className="sk sk-chip" />
            <div className="sk sk-chip" />
          </div>
          {/* Lot 4.1 : le rendu TipTap du VAULT.md dans la carte — le
              skeleton prévisse ce bloc de contenu `.vault-md-view` (le
              même layout que le rendu réel, pas un placeholder générique). */}
          <div className="sk vault-md-view">
            <div className="sk-lines">
              <SkLine w="t3" />
              <SkLine w="t4" />
              <SkLine w="t5" />
              <SkLine w="t4" />
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
