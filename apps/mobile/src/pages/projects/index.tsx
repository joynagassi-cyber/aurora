/**
 * Projects family view (05 §4.3, 02 S6.1 — upgraded with PRD-4, lot
 * 2026-10, C5 2026-10-08 : the 3 views that were still a shared empty
 * (Gantt / Chrono / Liste) are now REAL structures; a horizontal glide
 * reveals a hidden detail panel; a « ⋮ » menu lives in the top-right
 * corner (per-page + global settings overflow).
 *
 *   · Kanban (PROMPT 11, 2026-10-10 — REDESIGNÉ monochrome +
 *     zoomable, `views/KanbanView.tsx`) : les 4 colonnes + le slider
 *     de zoom (la variable CSS `--zoom`, l'état local du composant),
 *     les en-têtes = la SEULE partie colorée de la vue (les 4
 *     gradients fixés par le prompt), les cartes en mono-chrome
 *     (niveaux de gris, ZÉRO couleur de priorité) — le miroir
 *     projets (AD-7) : les compteurs restent 0, l'affordance « +
 *     Ajouter une carte » reste l'action réelle, jamais une carte
 *     factice.
 *   · Rapports (PRD-PM-01) : the synthesis-report list (9 original
 *     reports, French names — the reference's brand names are never
 *     reproduced). A report row generates the report THROUGH the
 *     agent (intent pré-rempli) — the agent computes, the page never
 *     invents numbers (AD-7).
 *   · Gantt (PROMPT 9, 2026-10-10 — REDESIGNÉ génie civil) : le
 *     composant dédié `views/GanttView.tsx` (le layout pro : la
 *     sidebar WBS 280px + la chart 2 niveaux, le chemin critique en
 *     danger, les jalons en diamants, la ligne « aujourd'hui », la
 *     baseline, les pastilles ressources, les filtres, la légende et
 *     la vue d'ensemble flottante — la forme de layout attendue pour
 *     les ingénieurs, jamais un rendu « simple » de liste).
 *   · Chrono (05 §3.6.3 = vue narrative `Timeline`, DISTINCTE du Gantt
 *     §3.6.4) : frise verticale des événements PASSÉS du projet (jalons
 *     atteints, étapes terminées) — chaque nœud = date `JetBrains Mono`
 *     xs + libellé sm + `Badge` statut ; Gantt = ce qui reste à faire
 *     (planification), Chrono = ce qui s'est passé (narratif).
 *   · Liste (SSoT 05 §4.3.1, `projets-liste.md`) : `Card flat` par
 *     projet (titre md-600, `ProgressBar` 8px + % mono xs, 2 `Badge`
 *     (statut sémantique + jalon mono), `KeyValueList` compact tâches
 *     totales/terminées) + FAB « Nouveau projet » (05 §4.3.1 l.1449) +
 *     tri (relégué dans le menu ⋮, 05 §4.3.1 l.1436-1437).
 *
 * C5 2026-10-08 :
 *   · Glissement horizontal = REVOILE un panneau latéral caché (pas une
 *     bascule de vue) — `useHorizontalSwiper` (pointer-based, GPU-only,
 *     `prefers-reduced-motion` = désactivé).
 *   · Menu « ⋮ » (3 points, haut à droite) : hybride — options propres à
 *     la page (trier par date/progression/priorité, basculer de vue,
 *     « Nouveau projet ») ET un dernier item « Paramètres » qui mène à
 *     `/settings?section=projects` (le réglage global lié à cette page,
 *     `PageOptionsMenu` + `settingsItem`).
 *   · « Petits détails » ref (2ᵉ vague C5, 10-08) : le Gantt porte le
 *     libellé de période mono sous le Pager + le marker de jalon manqué
 *     (ref_056 « Manquant 24/09 ») ; le Chrono est DIVISÉ en 2 sections
 *     (ref_056 « Jalons & réalisés » / « Prochaines étapes ») ; la Liste
 *     porte le jalon manqué rouge en card `bloque` ; le menu ⋮ porte
 *     des icônes couleur par item (ref_045) ; le panneau latéral porte
 *     le profil du projet (nom + % + jalon manqué + CTA).
 *
 * Local-first (AD-7): until the projects repo is wired to
 * `MobileDataProvider`, every surface ships clean empty states +
 * CTAs that route somewhere real — never fake data.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import {
  AlignCenter,
  AlignLeft,
  Flag,
  CalendarRange,
  ClipboardList,
  ListTree,
  Plus,
  Signal,
  Sparkles,
  Timer,
  TrendingUp,
} from 'lucide-react';
import { useUiStateStore } from '../../state/ui-state';
import { PageOptionsMenu, settingsItem, type PageOptionItem } from '../../ux/page-options-menu';
import { useHorizontalSwiper } from '../../ux/use-horizontal-swiper';
import { GanttView } from './views/GanttView';
import { TimelineView as TimelineViewGrouped, TLItem } from './views/TimelineView';
import { KanbanView } from './views/KanbanView';
import type { ProjectCard } from './shared';

/** The in-page views (T4 — the router does NOT know about these). */
type ProjectView = 'kanban' | 'rapports' | 'gantt' | 'timeline' | 'list';

/**
 * The views the user can SWITCH between by the pager / the glide / the
 * ⋮ menu — K-10 : the default view is « Liste », so `list` is NEVER a
 * switch option in the menu (it would be « back to default », not a
 * view to pick). The pager shows all 5 (the visual repère), the menu
 * shows only the 4 non-default.
 */
const VIEWS_SWITCHABLE: Array<[ProjectView, string]> = [
  ['kanban', 'Kanban'],
  ['rapports', 'Rapports'],
  ['gantt', 'Gantt'],
  ['timeline', 'Chrono'],
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
  { id: 'a-venir', label: 'À venir', desc: 'Ce qui arrive dans les 7 prochains jours.', intent: "Liste ce qui arrive dans les 7 prochains jours sur mes projets (échéances et jalons)." },
  { id: 'en-retard', label: 'En retard', desc: 'Tes échéances dépassées, classées par urgence.', intent: "Liste mes tâches et jalons en retard, classés par urgence, et propose-moi un plan pour rattraper." },
  { id: 'non-assignees', label: 'Sans responsable', desc: "Les étapes à qui personne ne s'occupe.", intent: "Montre-moi les étapes de mes projets sans responsable et propose qui devrait les prendre." },
  { id: 'activite', label: 'Activité', desc: 'Ajouts et terminaisons de la semaine.', intent: "Résume l'activité de la semaine sur mes projets : ajouts, terminaisons, mouvements de colonnes." },
  { id: 'charges', label: 'Charges', desc: 'Planned vs actual load, par projet.', intent: 'Compare la charge prévue et la charge réelle de mes projets, projet par projet.' },
  { id: 'risques', label: 'Risques', desc: "Les blocages qui menacent tes échéances.", intent: "Identifie les risques et blocages qui menacent les échéances de mes projets, avec une recommandation par risque." },
];

/**
 * The local mirrors (not wired yet, AD-7) — every view ships its
 * honest empty state + a REAL create CTA (the agent is the single
 * writer, AD-7/F-03). When the projects repo wires, these become the
 * `MobileDataProvider` reads. Le type de carte projet (le SEUL type
 * partagé, `ProjectCard`, 05 §4.3.1 `Card flat`) vit dans
 * `shared.ts` (PROMPT 10 — le `TLItem`/la vue groupée en consomment
 * un et un seul, ZÉRO duplication).
 */
const PROJECT_CARDS: ProjectCard[] = [];

/** The hidden side panel revealed by the horizontal glide (C5) — the
 *  project's own detail (ressources, 05 §4.3.2) until wired ; AD-7
 *  honest empty + the CTA stays the path (jamais un panneau factice).
 *  ref_045 : le panneau porte le **profil du projet** (nom + jalon manqué
 *  + le CTA « Générer la fiche ») — jamais un écran vide mort (AD-7 : le
 *  panneau reste lisible, le CTA reste actionnable). */
function ProjectsPanel() {
  return (
    <div data-projects-panel className="projects-panel">
      <p className="page-purpose">Le détail du projet.</p>
      {/* ref_045 : le profil du projet (nom + % + jalon manqué mono
          danger) — l'aperçu du CTA « Générer la fiche » que le panneau
          expose au glissement, sans re-coder une 2ᵉ fois la CTA de la
          surface (AD-14 : le CTA est unique, le panneau le réutilise). */}
      <div className="projects-panel-profile">
        <div className="projects-panel-profile-head">
          <span className="projects-panel-profile-name">Projet</span>
          <span className="projects-panel-profile-pct mono">0%</span>
        </div>
        <div className="projects-panel-profile-progress">
          <div
            className="projects-panel-profile-progress-fill"
            style={{ width: '0%' }}
          />
        </div>
        {/* Le jalon manqué (ref_056 : « Manquant 24/09 » en rouge mono) —
            la state est `danger` FROZEN (05 §5.1), la date est la donnée
            (05 §2.2 l.227-229, `JetBrains Mono`). */}
        <span className="projects-panel-profile-missed mono">
          <Flag size={12} aria-hidden /> Manquant 24/09
        </span>
        {/* L'aperçu du CTA (la sortie du panneau = le CTA, AD-14) :
            le CTA « Générer la fiche » est le SEUL CTA de la surface,
            jamais un CTA dupliqué dans le panneau. */}
        <a
          className="aurora-btn aurora-btn--primary aurora-tap projects-panel-cta"
          href="/agent?intent=G%C3%A8n%C3%A8re%20ma%20fiche%20:%20la%20premi%C3%A8re%20t%C3%A2che%20de%20mon%20plan%20d%27ouverture"
        >
          <Sparkles size={16} aria-hidden /> Générer la fiche
        </a>
      </div>
    </div>
  );
}

/**
 * La vue Chrono (PROMPT 10, 2026-10-10 — la vue chronologique GROUPÉE
 * par date, `views/TimelineView.tsx`) : la même carte projet que la vue
 * Liste (le `TLItem` partagé — ZÉRO duplication), regroupée par JOUR
 * avec des séparateurs de date bien visibles (le header
 * `.tl-group-date` + sa ligne 1px `--glass-border` en ::after, le
 * conteneur `.tl-items` dont la ::before trace la ligne verticale
 * continue). L'ancienne frise à nœuds alternés (C5.5, « Timeline
 * Infographics ») est SUBLUÉE par cette vue groupée.
 *
 * AD-7 (miroir non câblé) : l'état vide reste honnête — quand il n'y a
 * aucun projet, un seul groupe + le CTA planificateur (jamais un
 * groupe factice).
 */

/** The Liste view (SSoT 05 §4.3.1, `projets-liste.md` : `Card flat`).
 *
 *  ref_056 : chaque card affiche son **jalon manqué** en rouge mono
 *  quand le statut est `bloque` (l'alerte « Manquant 24/09 ») — la
 *  donnée (la date) est mono (05 §2.2 l.227-229), la state est
 *  `danger` FROZEN (05 §5.1) : jamais un rouge brut.
 */
function ListView() {
  return (
    <div data-list className="list-view">
      {PROJECT_CARDS.length === 0 ? (
        <div data-state="empty">
          <ClipboardList size={28} aria-hidden className="list-empty-icon" />
          <p>Aucun projet pour l'instant</p>
          <p className="page-hint">Un projet commence par un objectif.</p>
        </div>
      ) : (
        /* La vue PLATE (PROMPT 10) — le `TLItem` partagé, jamais une
           carte redessinée ici (ZÉRO duplication avec la vue groupée
           `TimelineViewGrouped`, PHASE 3 du prompt) : chaque item se
           lit `showDateSeparator: false` (la ligne horizontale du
           séparateur de date n'apparaît QUE dans la vue groupée). */
        <ul className="tl-items project-cards" aria-label="Projets">
          {PROJECT_CARDS.map((p) => (
            <TLItem key={p.id} card={p} showDateSeparator={false} />
          ))}
        </ul>
      )}
      <a
        className="aurora-fab"
        aria-label="Nouveau projet"
        href="/agent?intent=Cr%C3%A9e%20mon%20nouveau%20projet%20:%20aide-moi%20%C3%A0%20le%20nommer%20et%20%C3%A0%20le%20lier%20%C3%A0%20un%20objectif"
      >
        <Plus size={24} aria-hidden />
      </a>
    </div>
  );
}

export function ProjectsPage() {
  const view = useUiStateStore((s) => s.projectsView);
  const setView = useUiStateStore((s) => s.setProjectsView);
  const panelOpen = useUiStateStore((s) => s.panelOpen);
  const setPanelOpen = useUiStateStore((s) => s.setPanelOpen);
  const projectsSort = useUiStateStore((s) => s.projectsSort);
  const setProjectsSort = useUiStateStore((s) => s.setProjectsSort);

  /** C5 : le glissement horizontal REVOILE le panneau caché (pas une
      bascule de vue) — `useHorizontalSwiper` partagé (pointer-based,
      GPU-only, `prefers-reduced-motion` = désactivé, le tap seul
      bascule). La `translateX` vit dans le style inline du .tsx
      (le `transform` est le seul que le JS pilote — la donnée ne
      s'anime jamais, règle 1). */
  const { isGliding, handlers, surfaceStyle } = useHorizontalSwiper(setPanelOpen);

  /** Le menu « ⋮ » (C5) : hybride — les options propres à la page ET un
      dernier item « Paramètres » qui pointe vers `/settings?section=projects`
      (le réglage global lié à cette page, 05 §3.5 l.843-854, max 6 items).
      4 items de tri / vue + 1 item de settings = 5 items (sous le max 6,
      l'option « Liste » n'est PAS un item — K-10 : la vue par défaut n'est
      jamais dans le menu de bascule, elle est le retour).
      Chaque item porte une **icône 16px couleur** (ref_045 : le menu
      « Paramètres » a 8 items, chacun avec son icône teinte) — les
      icônes sont Lucide (le fournisseur du UI, ui-libraries §1 l.59),
      la teinte est le token FROZEN (AD-17 : jamais une valeur brute). */
  const VIEW_ICONS: Record<string, { icon: typeof AlignCenter; tone: PageOptionItem['iconTone'] }> = {
    kanban: { icon: ListTree, tone: 'accent' },
    rapports: { icon: TrendingUp, tone: 'success' },
    gantt: { icon: CalendarRange, tone: 'warning' },
    timeline: { icon: Timer, tone: 'danger' },
  };
  const menuItems: PageOptionItem[] = [
    {
      id: 'tri-date',
      label: 'Trier par date',
      icon: AlignLeft,
      iconTone: 'info',
      active: projectsSort === 'date',
      onClick: () => setProjectsSort('date'),
    },
    {
      id: 'tri-progression',
      label: 'Trier par progression',
      icon: AlignCenter,
      iconTone: 'accent',
      active: projectsSort === 'progression',
      onClick: () => setProjectsSort('progression'),
    },
    {
      id: 'tri-priorite',
      label: 'Trier par priorité',
      icon: Signal,
      iconTone: 'warning',
      active: projectsSort === 'priorite',
      onClick: () => setProjectsSort('priorite'),
    },
    ...VIEWS_SWITCHABLE.map(([v, label]) => ({
      id: `vue-${v}`,
      label,
      icon: VIEW_ICONS[v]?.icon,
      iconTone: VIEW_ICONS[v]?.tone,
      active: view === v,
      onClick: () => setView(v),
    })),
    settingsItem('projects'),
  ];

  return (
    <>
      <IonHeader>
        <div className="projects-header">
          <IonTitle>Projets</IonTitle>
          <PageOptionsMenu items={menuItems} ariaLabel="Options de la page Projets" />
        </div>
      </IonHeader>
      <IonContent>
        <div
          data-projects-view={view}
          className={`projects-surface${isGliding ? ' is-gliding' : ''}`}
          style={surfaceStyle}
          onPointerDown={handlers.onPointerDown}
          onPointerMove={handlers.onPointerMove}
          onPointerUp={handlers.onPointerUp}
          onPointerLeave={handlers.onPointerUp}
        >
          {/* Le but du module, en une ligne simple (pattern lots 1+2,
              zéro jargon technique visible par l'utilisateur). */}
          <p className="page-purpose">
            Tes grands objectifs, découpés en projets, jalons et étapes.
          </p>

          {/* T4 pager (05 §3.4) : in-page view switch, cosmetic +
              persistent (le store ui-state, pas un useState local —
              le retour retrouve la même vue, 05 §3.4 l.743-746). */}
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

          {/* Kanban (PROMPT 11, 2026-10-10 — REDESIGNÉ monochrome +
              zoomable, le composant dédié `views/KanbanView.tsx`) :
              les 4 colonnes + le slider de zoom (la variable CSS
              `--zoom`), les en-têtes = la SEULE partie colorée de la
              vue (les 4 gradients du prompt), les cartes mono-chrome
              (niveaux de gris fixés par le prompt, ZÉRO couleur de
              priorité). Le miroir projets (AD-7) : les compteurs
              restent 0, l'affordance « + Ajouter une carte » reste
              l'action réelle — jamais une carte factice. */}
          {view === 'kanban' && <KanbanView />}

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

          {view === 'gantt' && <GanttView />}
          {view === 'timeline' && <TimelineViewGrouped />}
          {view === 'list' && <ListView />}
        </div>

        {/* Le panneau caché révélé par le glissement horizontal (C5) —
            transformé en slide latéral (GPU-only), jamais un overlay
            qui masque la page (le panneau COEXISTE avec la vue). */}
        {panelOpen && (
          <div
            data-projects-panel-open
            className="projects-panel-slide"
            role="complementary"
            aria-label="Détail du projet"
          >
            <ProjectsPanel />
          </div>
        )}
      </IonContent>
    </>
  );
}
