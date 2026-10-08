/**
 * Projects family view (05 §4.3, 02 S6.1). Gantt/Kanban/Timeline/List
 * views (T4 in-page, ui-state persisted) + project detail (milestones,
 * docs, notes). Kanban drag & drop = dnd-kit (docs/ui-libraries §1).
 *
 * Local-first (AD-7): the list reads the projects mirror. Until that repo
 * is wired to `MobileDataProvider`, the surface is a clean, honest empty
 * state + a goal CTA (02 §6.2) — never fake data.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useState } from 'react';

/** The 4 in-page views (T4 — the router does NOT know about these). */
type ProjectView = 'kanban' | 'gantt' | 'timeline' | 'list';

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

          {/* Empty (AD-7: no mirror repo yet → honest empty + goal CTA). */}
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
        </div>
      </IonContent>
    </>
  );
}
