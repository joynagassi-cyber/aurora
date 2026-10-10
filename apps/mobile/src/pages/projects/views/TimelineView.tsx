/**
 * TimelineView (vue « Chrono » de /projects, PROMPT 10 — la vue
 * chronologique GROUPÉE par date).
 *
 * La vue « Liste » (/projects, SSoT 05 §4.3.1 `Card flat`) est une vue
 * PLATE triée par ordre chronologique ; cette vue est sa SŒUR
 * GROUPÉE : le même contenu (le miroir projets, AD-7 : jamais factice
 * quand il est vide) mais regroupé par JOUR, avec des séparateurs de
 * date bien visibles (le header `.tl-group-date` + sa ligne 1px
 * `--glass-border` en ::after, le conteneur `.tl-items` dont la
 * ::before trace la ligne verticale continue).
 *
 * RÉUTILISATION (PHASE 3 du prompt, ZÉRO duplication avec ListView) :
 * le composant d'item partagé est le module `shared` de cette page —
 * le `TLItem` (le point `.tl-dot` + la carte `.tl-card` et ses
 * libellés) est le SEUL endroit où la morphologie de la carte vit, la
 * ListView (la plate) et cette vue (la groupée) le partagent. La
 * prop `showDateSeparator` est le switch interne qui monte la ligne
 * horizontale du séparateur de jour quand l'item est le PREMIER de
 * son groupe (le cas groupé), jamais dans le cas plate.
 *
 * 100 % div/span standards (interdiction IonList/IonItem/IonGrid/
 * IonRow/IonCol/IonCard — les vues in-page de cette famille sont des
 * div racine simples, jamais un IonPage imbriqué), les couleurs sont
 * 100 % variables de thème (`--glass-bg`, `--glass-border`,
 * `--text-main`, `--text-muted`, `--ion-color-*`) — le fond image
 * respire derrière (Dynamic Theming, AD-13 honest degradation : les
 * fallbacks `--aurora-*` canons restent lisibles en thème neutre).
 */
import type { ProjectCard } from "../shared";

/* ── L'item partagé (le SEUL endroit où la carte vit — la Plate
 *   ListView et la Groupée TimelineView le réutilisent, ZÉRO
 *   duplication, PHASE 3 du prompt) ── */
export function TLItem({
  card,
  showDateSeparator = false,
}: {
  card: ProjectCard;
  showDateSeparator?: boolean;
}) {
  const statusLabel =
    card.status === "termine" ? "Terminé" : card.status === "bloque" ? "Bloqué" : "En cours";
  /* Le point reprend la SEMANTIQUE SANS ÉTAT (FROZEN 05 §5.1, les
   * 5 teintes .tl-dot-* du calendrier, AD-17 : jamais une valeur
   * brute) : terminé = success (vert), en cours = accent (bleu),
   * bloqué = warning (orange, l'alerte que l'étape est au point
   * mort, le jalon manqué reste le rouge danger dans la carte
   * elle-même, jamais le point). */
  const dotTone = card.status === "termine" ? "green" : card.status === "bloque" ? "orange" : "blue";
  return (
    <div className={`tl-item${showDateSeparator ? " is-date-separator" : ""}`}>
      <div className={`tl-dot tl-dot-${dotTone}`} aria-hidden />
      <div className="tl-card">
        <div className="tl-card-head">
          <span className="tl-card-title">{card.title}</span>
          <span className="tl-card-time mono">{card.percent}%</span>
        </div>
        <div className="tl-card-desc">
          Jalon : {card.nextMilestone}
          {card.status === "bloque" && card.missedMilestone
            ? ` · Manquant ${card.missedMilestone}`
            : null}
        </div>
        <div className="tl-card-tags">
          <span className={`tl-tag tl-tag-${dotTone}`}>{statusLabel}</span>
        </div>
      </div>
    </div>
  );
}

/* ── Le groupe par date (PHASE 2 du prompt) : le header de date
 *   (le « Aujourd'hui · 7 octobre » + sa ligne horizontale 1px en
 *   ::after, `--glass-border`) + le conteneur des items (la ligne
 *   verticale continue en ::before, l'indent 22px qui la laisse
 *   passer) ── */
export function TLGroup({
  dateLabel,
  cards,
}: {
  dateLabel: string;
  cards: ProjectCard[];
}) {
  return (
    <div className="tl-group">
      <div className="tl-group-date">{dateLabel}</div>
      <div className="tl-items">
        {cards.length === 0 ? (
          <div className="tl-item">
            <div className="tl-card">
              <div className="tl-card-title">Aucun projet ce jour</div>
              <div className="tl-card-desc">
                Les jalons et étapes planifiés apparaissent ici dès que
                ton premier projet avance.
              </div>
            </div>
          </div>
        ) : (
          cards.map((card, i) => (
            <TLItem key={card.id} card={card} showDateSeparator={i === 0} />
          ))
        )}
      </div>
    </div>
  );
}

/**
 * La vue chronologique groupée (PROMPT 10) — le SEUL composant de
 * cette morphologie : la frise groupée par JOUR (le séparateur de
 * date bien visible), le contenu est le miroir projets (AD-7, la
 * vue reste honnête : quand le miroir est vide, un seul groupe
 * « Aujourd'hui » + le message honnête + le CTA planificateur,
 * jamais un groupe factice).
 */
export function TimelineView() {
  const groups = [
    { dateLabel: "Aujourd'hui", cards: [] as ProjectCard[] },
    { dateLabel: "Cette semaine", cards: [] as ProjectCard[] },
  ];

  const totalCards = groups.reduce((n, g) => n + g.cards.length, 0);

  return (
    <div data-timeline-grouped className="tl-scroll">
      {groups.map((g) => (
        <TLGroup key={g.dateLabel} dateLabel={g.dateLabel} cards={g.cards} />
      ))}

      {totalCards === 0 && (
        <div data-state="empty" className="tl-empty-cta">
          <p>Aucun jalons planifiés pour le moment</p>
          <p className="page-hint">
            La chronologie groupée par jour se remplit au fil de tes
            projets — chaque étape termine ici.
          </p>
          <a
            className="aurora-btn aurora-btn--primary aurora-tap"
            href="/agent?intent=G%C3%A8n%C3%A8re%20ma%20frise%20chronologique%20:%20la%20premi%C3%A8re%20%C3%A9tape%20de%20mon%20projet"
          >
            Planifier
          </a>
        </div>
      )}

      <style>{TIMELINE_VIEW_CSS}</style>
    </div>
  );
}

/* Le CSS dédié (PROMPT 10, la vue groupée) — les classes `.tl-*`
   partagées avec la liste plate du calendrier (jamais redéfinies ici,
   la ZONE DU PROMPT, la même morphologie de carte) + les séparateurs
   de groupe `.tl-group*` + le CTA d'état vide. 100 % variables,
   le fond image respire derrière. */
export const TIMELINE_VIEW_CSS = `
/* Le scroll conteneur (la hauteur plein écran, le même que le
   calendrier, le fond image respire derrière). */
.tl-scroll {
  height: 100%;
  overflow-y: auto;
  padding: 10px 16px 100px;
}

/* Le groupe par date (PHASE 2) : le header + le conteneur indented. */
.tl-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.tl-group-date {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-main, var(--ion-color-step-100, var(--aurora-text-primary)));
  padding: 10px 0 4px;
  position: relative;
}
/* La ligne horizontale du séparateur (1px, --glass-border, la règle
   PHASE 2 du prompt — jamais un hex de gris en dur). */
.tl-group-date::after {
  content: "";
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  height: 1px;
  background: var(--glass-border, var(--ion-toolbar-border-color, var(--aurora-border)));
}
/* Le conteneur des items : l'indent 22px laisse passer la ligne
   verticale continue (la ::before), le premier item du groupe monte
   sa ligne horizontale de date (la prop showDateSeparator). */
.tl-items {
  padding-left: 22px;
  position: relative;
}
.tl-items::before {
  content: "";
  position: absolute;
  left: 7px;
  top: 8px;
  bottom: 4px;
  width: 1px;
  background: var(--glass-border, var(--ion-toolbar-border-color, var(--aurora-border)));
  opacity: 0.6;
}

/* L'état vide du groupe (AD-7 : jamais un contenu factice, le
   message honnête dans la forme de carte existante, le CTA reste
   le chemin — le planificateur agent). */
.tl-empty-cta {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 16px;
}

/* Les teintes de point + les tags par statut (la SEMANTIQUE SANS
   ÉTAT FROZEN du calendrier, les 5 .tl-dot-* existantes) : terminé
   = green (success), en cours = blue (accent), bloqué = orange
   (warning) — jamais une valeur brute (AD-17). */
.tl-dot-green { background: var(--ion-color-success, var(--aurora-success)); }
.tl-dot-blue { background: var(--ion-color-primary, var(--aurora-accent-primary)); }
.tl-dot-orange { background: var(--ion-color-warning, var(--aurora-warning)); }
.tl-tag {
  display: inline-flex;
  align-items: center;
  padding: 2px 8px;
  border-radius: 9999px;
  font-size: 11px;
  font-weight: 600;
  color: var(--text-main, var(--ion-color-step-100, var(--aurora-text-primary)));
  background: rgba(10, 132, 255, 0.2);
}
.tl-tag-blue { background: rgba(10, 132, 255, 0.2); }
.tl-tag-green { background: rgba(48, 209, 88, 0.2); }
.tl-tag-orange { background: rgba(255, 159, 10, 0.2); }
`;
