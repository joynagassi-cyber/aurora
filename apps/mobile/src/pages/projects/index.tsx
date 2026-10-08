/**
 * Projects family view (05 §4.3, 02 S6.1 — upgraded with PRD-4, lot
 * 2026-10: kanban board structure + the synthesis-report list).
 *
 *   · Kanban (PRD-PM-02/03) : horizontal column board (À planifier /
 *     À faire / En cours / Terminé) with per-column header (name +
 *     counter + « + Ajouter une carte »). Columns are themed (bande
 *     colorée, PRD-PM-03). Cards = honest empty (the projects mirror
 *     is not wired, AD-7) — every affordance routes to a REAL action
 *     (the agent creates projects/cards), never a dead control.
 *   · Rapports (PRD-PM-01) : the synthesis-report list (9 original
 *     reports, French names — the reference's brand names are never
 *     reproduced). A report row generates the report THROUGH the
 *     agent (intent pré-rempli) — the agent computes, the page never
 *     invents numbers (AD-7).
 *   · Gantt / Chrono / Liste : view switchers kept (the engines mount
 *     here when the mirror is wired — the honest empty state stays).
 *
 * Local-first (AD-7): until the projects repo is wired to
 * `MobileDataProvider`, every surface ships clean empty states +
 * CTAs that route somewhere real — never fake data.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useState } from 'react';

/** The in-page views (T4 — the router does NOT know about these). */
type ProjectView = 'kanban' | 'rapports' | 'gantt' | 'timeline' | 'list';

/**
 * The kanban columns (PRD-PM-03 : bandeau coloré par colonne). The
 * colored band uses the FROZEN semantic tokens (05 §5.1 — theme
 * independent): planifier = info, faire = accent, cours = warning,
 * terminé = success. Counters are DERIVED (the mirror is empty → 0,
 * AD-7 honest, never a fake number).
 */
const BOARD_COLUMNS: Array<{
  id: string;
  label: string;
  band: 'info' | 'accent' | 'warning' | 'success';
  addIntent: string;
}> = [
  {
    id: 'planifier',
    label: 'À planifier',
    band: 'info',
    addIntent: "Ajoute une carte « définir la prochaine étape » dans ma colonne « À planifier » de mon projet.",
  },
  {
    id: 'faire',
    label: 'À faire',
    band: 'accent',
    addIntent: 'Ajoute une carte dans ma colonne « À faire » de mon projet.',
  },
  {
    id: 'en-cours',
    label: 'En cours',
    band: 'warning',
    addIntent: "Déplace une carte de « À faire » vers « En cours » dans mon projet.",
  },
  {
    id: 'termine',
    label: 'Terminé',
    band: 'success',
    addIntent: "Résume les cartes terminées de mon projet dans ma colonne « Terminé ».",
  },
];

/**
 * The synthesis reports (PRD-PM-01 « Choose a Report ») — ORIGINAL
 * French names (the reference's « Lineup / Mission Control / Hilltop
 * » brand names are never reproduced). Each row pre-fills the agent
 * intent that generates the report on the user's own data (AD-7: the
 * report is computed by the kernel, the page never invents numbers).
 */
const REPORTS: Array<{ id: string; label: string; desc: string; intent: string }> = [
  { id: 'frise', label: 'Frise des projets', desc: 'Tous tes projets sur une même ligne de temps.', intent: 'Génère ma frise de projets : tous mes projets et leurs jalons sur une même ligne de temps.' },
  { id: 'avancement', label: 'Avancement', desc: "Où en est chaque projet, d'un coup d'œil.", intent: "Fais-moi l'avancement de mes projets : état de chaque projet, pourcentage et prochaine étape." },
  { id: 'progression', label: 'Progression', desc: "Les courbes d'avancement de tes projets.", intent: 'Fais-moi les courbes de progression de mes projets, semaine par semaine.' },
  { id: 'a-venir', label: 'À venir', desc: 'Ce qui arrive dans les 7 prochains jours.', intent: "Liste ce qui arrive dans les 7 prochains jours sur mes projets (échances et jalons)." },
  { id: 'en-retard', label: 'En retard', desc: 'Tes échéances dépassées, classées par urgence.', intent: "Liste mes tâches et jalons en retard, classés par urgence, et propose-moi un plan pour rattraper." },
  { id: 'non-assignees', label: 'Sans responsable', desc: "Les étapes à qui personne ne s'occupe.", intent: "Montre-moi les étapes de mes projets sans responsable et propose qui devrait les prendre." },
  { id: 'activite', label: 'Activité', desc: 'Ajouts et terminaisons de la semaine.', intent: "Résume l'activité de la semaine sur mes projets : ajouts, terminaisons, mouvements de colonnes." },
  { id: 'charges', label: 'Charges', desc: 'Planned vs actual load, par projet.', intent: 'Compare la charge prévue et la charge réelle de mes projets, projet par projet.' },
  { id: 'risques', label: 'Risques', desc: "Les blocages qui menacent tes échéances.", intent: "Identifie les risques et blocages qui menacent les échéances de mes projets, avec une recommandation par risque." },
];

export function ProjectsPage() {
  const [view, setView] = useState<ProjectView>('kanban');

  return (
    <>
      <IonHeader>
        <IonTitle>Projets</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-projects-view={view}>
          {/* Le but du module, en une ligne simple (pattern lots 1+2,
              zéro jargon technique visible par l'utilisateur). */}
          <p className="page-purpose">
            Tes grands objectifs, découpés en projets, jalons et étapes.
          </p>

          {/* T4 pager (05 §3.4): in-page view switch, cosmetic + persistent. */}
          <div className="segmented" role="tablist" aria-label="Vue projet">
            {(
              [
                ['kanban', 'Kanban'],
                ['rapports', 'Rapports'],
                ['gantt', 'Gantt'],
                ['timeline', 'Chrono'],
                ['list', 'Liste'],
              ] as [ProjectView, string][]
            ).map(([v, label]) => (
              <button
                key={v}
                role="tab"
                aria-selected={view === v}
                className={view === v ? 'segmented-item active' : 'segmented-item'}
                onClick={() => setView(v)}
              >
                {label}
              </button>
            ))}
          </div>

          {/* Kanban board (PRD-PM-02/03) : the column structure ships
              NOW; cards come from the mirror when wired (AD-7: the
              per-column empty is honest, the add affordance routes to
              the agent — a real action, never a dead control). */}
          {view === 'kanban' && (
            <>
              <div data-board className="projects-board">
                {BOARD_COLUMNS.map((col) => (
                  <section key={col.id} className={`projects-col projects-col--${col.band}`}>
                    <header className="projects-col-header">
                      <span className="projects-col-title">
                        {col.label}
                        <span className="projects-col-count">0</span>
                      </span>
                    </header>
                    <div className="projects-col-body">
                      <a
                        className="projects-col-add aurora-tap"
                        href={`/agent?intent=${encodeURIComponent(col.addIntent)}`}
                      >
                        + Ajouter une carte
                      </a>
                    </div>
                  </section>
                ))}
              </div>
              <div className="projects-create-wrap">
                <a
                  className="projects-create aurora-btn aurora-btn--primary aurora-tap"
                  href="/agent?intent=Crée%20mon%20projet%20:%20aide-moi%20à%20le%20nommer%2C%20à%20poser%20ses%20jalons%20et%20ses%20premieres%20cartes%20kanban"
                >
                  Créer un projet
                </a>
              </div>
            </>
          )}

          {/* Reports (PRD-PM-01) : the 9 synthesis reports, each row
              pre-fills the agent intent that GENERATES it on the user's
              own data. Honest: the numbers never ship pre-baked. */}
          {view === 'rapports' && (
            <div data-reports className="projects-reports">
              <p className="page-hint projects-reports-hint">
                Chaque rapport se génère par l'agent, sur tes données.
              </p>
              {REPORTS.map((r) => (
                <a
                  key={r.id}
                  className="report-row aurora-tap"
                  href={`/agent?intent=${encodeURIComponent(r.intent)}`}
                >
                  <span className="report-row-dot" aria-hidden />
                  <span className="report-row-text">
                    <strong>{r.label}</strong>
                    <small>{r.desc}</small>
                  </span>
                </a>
              ))}
            </div>
          )}

          {/* Gantt / Chrono / Liste — the engines mount here when the
              mirror is wired. Until then: the honest empty + goal CTA
              (never fake rows, AD-7). */}
          {(view === 'gantt' || view === 'timeline' || view === 'list') && (
            <div data-state="empty">
              <p>Aucun projet</p>
              <p className="page-hint">
                Les jalons et les modèles de projet apparaîtront dès que
                tu auras créé ton premier projet.
              </p>
              <a className="aurora-btn aurora-btn--primary aurora-tap" href="/goals">
                Créer un objectif
              </a>
            </div>
          )}
        </div>
      </IonContent>
    </>
  );
}
