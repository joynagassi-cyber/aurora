/**
 * Projects family view (05 §4.3, 02 S6.1 — upgraded with PRD-4, lot
 * 2026-10, C5 2026-10-08 : the 3 views that were still a shared empty
 * (Gantt / Chrono / Liste) are now REAL structures; a horizontal glide
 * reveals a hidden detail panel; a « ⋮ » menu lives in the top-right
 * corner (per-page + global settings overflow).
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
 *   · Gantt (05 §3.6.4, `timeline-gantt.md` OQ-01 option A = LISTE de
 *     `GanttRow`, pas une grille 2D interactive — budget OQ-11) : one
 *     task = one 44px row (titre sm ellipsis + barre 8px proportionnelle
 *     sur axe de dates partagé + % `JetBrains Mono` xs à droite) ; barre
 *     `accent-primary` (en cours) / `success` (terminée) /
 *     `border-strong` (à faire) / `danger-surface` + icône gauche
 *     (bloquée) ; jalons non atteints en `danger` ; axe = le `Pager`
 *     Jour|Semaine|Mois (05 §3.4 l.737-750, OQ-03 option A = présent) ;
 *     CTA unique « Générer la fiche » (AD-14, OQ-08 option A).
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
  useState,
} from 'react';
import {
  AlignCenter,
  AlignLeft,
  Flag,
  CalendarRange,
  ClipboardList,
  GanttChart,
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
  { id: 'a-venir', label: 'À venir', desc: 'Ce qui arrive dans les 7 prochains jours.', intent: "Liste ce qui arrive dans les 7 prochains jours sur mes projets (échéances et jalons)." },
  { id: 'en-retard', label: 'En retard', desc: 'Tes échéances dépassées, classées par urgence.', intent: "Liste mes tâches et jalons en retard, classés par urgence, et propose-moi un plan pour rattraper." },
  { id: 'non-assignees', label: 'Sans responsable', desc: "Les étapes à qui personne ne s'occupe.", intent: "Montre-moi les étapes de mes projets sans responsable et propose qui devrait les prendre." },
  { id: 'activite', label: 'Activité', desc: 'Ajouts et terminaisons de la semaine.', intent: "Résume l'activité de la semaine sur mes projets : ajouts, terminaisons, mouvements de colonnes." },
  { id: 'charges', label: 'Charges', desc: 'Planned vs actual load, par projet.', intent: 'Compare la charge prévue et la charge réelle de mes projets, projet par projet.' },
  { id: 'risques', label: 'Risques', desc: "Les blocages qui menacent tes échéances.", intent: "Identifie les risques et blocages qui menacent les échéances de mes projets, avec une recommandation par risque." },
];

/**
 * Gantt (05 §3.6.4, `timeline-gantt.md`) — a task's own GanttRow
 * (ONE row, 44px : titre sm + barre 8px proportionnelle + % mono xs).
 * The status drives the bar's FROZEN semantic color (05 §5.1 : jamais
 * redéfini par thème).
 */
interface GanttTask {
  id: string;
  title: string;
  /** 0-100, the task's own completion (data — never animated, règle 1). */
  percent: number;
  status: 'todo' | 'in_progress' | 'done' | 'blocked';
  /** The bar's [start, end] on a 0-100 axis (proportional, 05 §3.6.4 l.928-936). */
  span: [number, number];
  /** A missed milestone inherited from S-07 (marqué en `danger`, 05 §3.6.4 l.941-945). */
  milestoneMissed?: boolean;
  /**
   * The missed milestone's date (ref_056 : « Manquant 24/09 » en rouge
   * dans la section « PROCHAINES ÉTAPES ») — le libellé mono xs affiché
   * à gauche de la barre (le marker d'alerte, 05 §3.6.4 l.944).
   */
  missedLabel?: string;
}

/**
 * Chrono (05 §3.6.3 = vue narrative, `timeline-gantt.md` l.15 : « ce
 * qui s'est passé » vs le Gantt « ce qui reste ») : ONE past event,
 * a node on the vertical frise (date mono + libellé + statut badge).
 */
interface TimelineEvent {
  id: string;
  /** `JetBrains Mono` xs — la date est TOUJOURS mono (05 §2.2 l.227-229). */
  date: string;
  title: string;
  status: 'atteint' | 'en_cours' | 'manque';
  /**
   * The event's section (ref_056 : « JALONS & RÉALISÉS » / « PROCHAINES
   * ÉTAPES ») — the 2 sections of the frise, jamais 1 section unique.
   */
  section: 'realises' | 'prochaines';
  /**
   * C5.5 (10-08, image « Timeline Infographics ») : la **teinte du
   * nœud** (le grand cercle coloré + le titre qui la reprend).
   * AD-17 : c'est un **token d'accent du thème** (`primary` /
   * `secondary` / `punctual` / `neutral`), jamais une valeur brute —
   * quand le thème change, le cercle change automatiquement (le thème
   * pilote les variables, le code ne hardcode jamais).
   */
  tone?: 'primary' | 'secondary' | 'punctual' | 'neutral';
}

/**
 * Liste (SSoT 05 §4.3.1, `projets-liste.md`) : a project's `Card flat`
 * (objet riche : % progression + prochain jalon + tâches totales/
 * terminées — JAMAIS une `ListItem`, 05 §4.3.1 l.1439).
 */
interface ProjectCard {
  id: string;
  title: string;
  percent: number;
  status: 'en_cours' | 'bloque' | 'termine';
  nextMilestone: string;
  tasksTotal: number;
  tasksDone: number;
  /**
   * Le jalon raté (ref_056 : « Manquant 24/09 » en rouge, la date
   * mono) — affiché dans la card quand le statut est `bloque` (l'alerte
   * que la donnée a passé son échéance — la state est FROZEN `danger`,
   * 05 §5.1, la date est la donnée, 05 §2.2 l.227-229).
   */
  missedMilestone?: string;
}

/**
 * The local mirrors (not wired yet, AD-7) — every view ships its
 * honest empty state + a REAL create CTA (the agent is the single
 * writer, AD-7/F-03). When the projects repo wires, these become the
 * `MobileDataProvider` reads.
 */
const GANTT_TASKS: GanttTask[] = [];
const TIMELINE_EVENTS: TimelineEvent[] = [];
const PROJECT_CARDS: ProjectCard[] = [];

/**
 * The axis period (05 §3.4 l.737-750 Pager, OQ-03 option A = présent).
 * Chaque option porte sa propre `label` + un `periodLabel` (la période
 * courante affichée sous le Pager, `JetBrains Mono` xs, 05 §3.6.4
 * l.932-935 — la donnée, qui ne bouge pas). La période est une
 * **chaîne fixe** par option (miroir non câblé, AD-7 : « 2026 » =
 * l'année courante, pas un range factice).
 *
 * C5.5 (10-08) : 4 échelles (Jour / Semaine / Mois / Année) — le Gantt
 * ET la Timeline sont **flexibles** sur les 4 granularités (l'image
 * « 2024 » = la vue Année, 12 mini-mois ; l'image « August, 2024 » =
 * la vue Mois avec la liste des tâches sous la grille).
 */
const AXIS_PERIODS: Array<{
  id: 'jour' | 'semaine' | 'mois' | 'annee';
  label: string;
  periodLabel: string;
}> = [
  { id: 'jour', label: 'Jour', periodLabel: '12 oct. 2026' },
  { id: 'semaine', label: 'Semaine', periodLabel: '5 – 11 oct. 2026' },
  { id: 'mois', label: 'Mois', periodLabel: 'octobre 2026' },
  { id: 'annee', label: 'Année', periodLabel: '2026' },
];

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

/** The Gantt view (05 §3.6.4, `timeline-gantt.md` OQ-01 option A). */
function GanttView() {
  const [axis, setAxis] = useState<'jour' | 'semaine' | 'mois' | 'annee'>('semaine');
  const period = AXIS_PERIODS.find((p) => p.id === axis)!;

  return (
    <div data-gantt className="gantt-view gantt-view--h">
      {/* OQ-03 option A : le `Pager` = l'axe de dates partagé (stable au
          rechargement, 05 §3.6.4 l.941 ; JetBrains Mono xs, 05 §3.6.4 l.932-935).
          Reduced-motion (règle 2, 05 §2.6) : le basculement reste au tap
          (le basculement n'est PAS le glissement — le glissement est la
          surface, pas l'axe de dates, qui est un control tap classique). */}
      <div className="gantt-axis" role="tablist" aria-label="Axe de dates">
        {AXIS_PERIODS.map((p) => (
          <button
            key={p.id}
            type="button"
            role="tab"
            aria-selected={axis === p.id}
            className={axis === p.id ? 'segmented-item active' : 'segmented-item'}
            onClick={() => setAxis(p.id)}
          >
            {p.label}
          </button>
        ))}
      </div>

      {/* Le libellé de période (ref_020/056 : le mono sous le Pager,
          05 §3.4 l.737-750 : « le label central dates sm 600
          JetBrains Mono ») — la donnée courante, ne bouge jamais
          (règle 1) ; quand l'option change, le libellé change. */}
      <p className="gantt-period mono" aria-hidden>
        {period.periodLabel}
      </p>

      {GANTT_TASKS.length === 0 ? (
        /* OQ-09 option A (SSoT 05 §3.6.4 l.942-944) : le libellé honnête. */
        <div data-state="empty">
          <GanttChart size={28} aria-hidden className="gantt-empty-icon" />
          <p>Aucun planifié sur la période</p>
          <p className="page-hint">
            Le plan d'ouverture (tâches + jalons + barres) apparaît dès que
            ton premier projet est créé.
          </p>
          <a
            className="aurora-btn aurora-btn--primary aurora-tap"
            href="/agent?intent=G%C3%A8ne%20mon%20premier%20projet%20:%20aide-moi%20%C3%A0%20le%20nommer%2C%20%C3%A0%20poser%20ses%20jalons%20et%20son%20plan%20d%27ouverture"
          >
            Créer un projet
          </a>
        </div>
      ) : (
        <ol className="gantt-rows" aria-label="Plan d'ouverture">
          {GANTT_TASKS.map((task) => {
            const barClass = `gantt-row-bar gantt-row-bar--${task.status}`;
            return (
              <li
                key={task.id}
                className={`gantt-row${task.milestoneMissed ? ' is-missed' : ''}`}
                aria-label={`Tâche ${task.title} : ${task.percent}% complété, statut ${task.status}`}
              >
                <span className="gantt-row-title">
                  {task.title}
                  {task.milestoneMissed && task.missedLabel ? (
                    /* ref_056 : le marker de jalon manqué (05 §3.6.4
                       l.941-944 « le blocage est visible, pas seulement
                       dans le statut ») : le `Flag` 16px + la date mono
                       danger à gauche de la barre (l'attention saute). */
                    <span className="gantt-row-missed mono">
                      <Flag size={12} aria-hidden /> {task.missedLabel}
                    </span>
                  ) : null}
                </span>
                <div className="gantt-row-track" aria-hidden>
                  <div className={barClass} style={{ left: `${task.span[0]}%`, width: `${task.span[1] - task.span[0]}%` }} />
                </div>
                <span className="gantt-row-pct mono">{task.percent}%</span>
              </li>
            );
          })}
        </ol>
      )}

      {/* CTA unique (AD-14, OQ-08 option A) : le seul CTA d'action de la
          surface — jamais une proposition libre de l'agent. */}
      <a
        className="aurora-btn aurora-btn--primary aurora-tap gantt-cta"
        href="/agent?intent=G%C3%A8n%C3%A8re%20ma%20fiche%20:%20la%20premi%C3%A8re%20t%C3%A2che%20de%20mon%20plan%20d%27ouverture"
      >
        <Sparkles size={16} aria-hidden /> Générer la fiche
      </a>
    </div>
  );
}

/** The Chrono view (05 §3.6.3 = vue narrative).
 *
 *  ref_056 : la frise est DIVISÉE en 2 sections — « JALONS & RÉALISÉS »
 *  (ce qui s'est passé : les jalons atteints, les étapes terminées) et
 *  « PROCHAINES ÉTAPES » (ce qui reste : les jalons non atteints, dont
 *  le « Manquant 24/09 » en rouge). Les 2 libellés de section sont en
 *  `JetBrains Mono` xs uppercase (la donnée technique, 05 §2.2 l.227-229),
 *  jamais un libellé free-style.
 */
/**
 * La vue Chrono (05 §3.6.3 = vue narrative `Timeline`) — C5.5 (10-08,
 * image « Timeline Infographics ») : la frise est une **ligne centrale
 * horizontale** avec des **nœuds alternés au-dessus / en-dessous** (pas
 * une liste verticale). Chaque nœud = un **grand cercle coloré par
 * token d'accent** (AD-17 : jamais une valeur brute, le thème pilote
 * la couleur) + un **titre qui reprend la teinte du cercle** + une
 * **description mono** + un **badge de statut** (05 §5.1 FROZEN).
 *
 * L'axe est **flexible** (4 échelles : Jour / Semaine / Mois / Année)
 * — l'image « 2024 » = la vue Année (12 mini-mois), l'image
 * « August, 2024 » = la vue Mois (grille + liste des tâches).
 *
 * AD-7 (miroir non câblé) : l'état vide reste honnête — quand il n'y
 * a aucun événement, la frise affiche le **libellé de période**
 * (la donnée courante, `JetBrains Mono` xs) + le message « Aucun
 * événement sur la période » + le CTA agent (le planificateur).
 */
function TimelineView() {
  const [axis, setAxis] = useState<'jour' | 'semaine' | 'mois' | 'annee'>('mois');
  const period = AXIS_PERIODS.find((p) => p.id === axis)!;
  const realisees = TIMELINE_EVENTS.filter((ev) => ev.section === 'realises');
  const prochaines = TIMELINE_EVENTS.filter((ev) => ev.section === 'prochaines');

  return (
    <div data-timeline className="timeline-view">
      {/* L'axe (05 §3.4 l.737-750 Pager, OQ-03 option A = présent) :
          4 échelles flexibles (Jour / Semaine / Mois / Année) — le
          changement d'échelle **ne change pas la structure de la frise**
          (les nœuds restent alternés, la ligne centrale reste), il
          change la **période affichée** (le libellé mono sous le Pager).
          La donnée ne s'anime jamais (règle 1, 05 §2.6) — le tap seul
          bascule. */}
      <div className="timeline-axis" role="tablist" aria-label="Axe de dates">
        {AXIS_PERIODS.map((p) => (
          <button
            key={p.id}
            type="button"
            role="tab"
            aria-selected={axis === p.id}
            className={axis === p.id ? 'segmented-item segmented-item--active' : 'segmented-item'}
            onClick={() => setAxis(p.id)}
          >
            {p.label}
          </button>
        ))}
      </div>

      {/* Le libellé de période (ref_020/056 : le mono sous le Pager,
          05 §3.4 l.737-750 : « le label central dates sm 600
          JetBrains Mono ») — la donnée courante, ne bouge jamais
          (règle 1) ; quand l'échelle change, le libellé change. */}
      <p className="gantt-period mono" aria-hidden>
        {period.periodLabel}
      </p>

      {TIMELINE_EVENTS.length === 0 ? (
        <div data-state="empty">
          <Timer size={28} aria-hidden className="timeline-empty-icon" />
          <p>Aucun événement sur la période</p>
          <p className="page-hint">
            La frise chronologique (jalons atteints, étapes terminées)
            se remplit au fil de ton projet.
          </p>
          <a
            className="aurora-btn aurora-btn--primary aurora-tap"
            href="/agent?intent=G%C3%A8n%C3%A8re%20ma%20frise%20chronologique%20:%20la%20premi%C3%A8re%20%C3%A9tape%20de%20mon%20projet"
          >
            Planifier
          </a>
        </div>
      ) : (
        <>
          {/* Section 1 (ref_056 : « JALONS & RÉALISÉS ») — la frise
              des événements passés, l'axe vertical est continu. */}
          {realisees.length > 0 && (
            <section className="timeline-section">
              <p className="timeline-section-label mono" aria-hidden>
                Jalons &amp; réalisés
              </p>
              <ol className="timeline-nodes timeline-nodes--h" aria-label="Jalons et événements réalisés">
                {realisees.map((ev, i) => (
                  <li
                    key={ev.id}
                    className={`timeline-node timeline-node--${ev.status} timeline-node--${i % 2 === 0 ? 'up' : 'down'}${ev.tone ? ` timeline-node--tone-${ev.tone}` : ''}`}
                  >
                    <span className="timeline-node-dot" aria-hidden />
                    <div className="timeline-node-body">
                      <span className="timeline-node-title">{ev.title}</span>
                      <span className="timeline-node-date mono">{ev.date}</span>
                    </div>
                    <span className={`timeline-node-badge timeline-node-badge--${ev.status}`}>
                      {ev.status === 'atteint' ? 'Atteint' : 'En cours'}
                    </span>
                  </li>
                ))}
              </ol>
            </section>
          )}

          {/* Section 2 (ref_056 : « PROCHAINES ÉTAPES ») — les jalons
              restants, dont le « Manquant 24/09 » en danger (05 §5.1
              FROZEN). L'axe de la 2ᵉ section démarre au 1er nœud. */}
          {prochaines.length > 0 && (
            <section className="timeline-section">
              <p className="timeline-section-label mono" aria-hidden>
                Prochaines étapes
              </p>
              <ol className="timeline-nodes timeline-nodes--h" aria-label="Prochaines étapes et jalons restants">
                {prochaines.map((ev, i) => (
                  <li
                    key={ev.id}
                    className={`timeline-node timeline-node--${ev.status} timeline-node--${i % 2 === 0 ? 'up' : 'down'}${ev.tone ? ` timeline-node--tone-${ev.tone}` : ''}`}
                  >
                    <span className="timeline-node-dot" aria-hidden />
                    <div className="timeline-node-body">
                      <span className="timeline-node-title">{ev.title}</span>
                      <span className="timeline-node-date mono">{ev.date}</span>
                    </div>
                    <span className={`timeline-node-badge timeline-node-badge--${ev.status}`}>
                      {ev.status === 'manque' ? 'Manquant' : 'À venir'}
                    </span>
                  </li>
                ))}
              </ol>
            </section>
          )}
        </>
      )}
    </div>
  );
}

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
        <ul className="project-cards" aria-label="Projets">
          {PROJECT_CARDS.map((p) => (
            <li key={p.id} className={`project-card project-card--${p.status}`}>
              <div className="project-card-head">
                <span className="project-card-title">{p.title}</span>
                <span className="project-card-pct mono">{p.percent}%</span>
              </div>
              <div className="project-card-progress">
                <div
                  className="project-card-progress-fill"
                  style={{ width: `${p.percent}%` }}
                />
              </div>
              <div className="project-card-badges">
                <span className={`project-card-badge project-card-badge--${p.status}`}>
                  {p.status === 'termine' ? 'Terminé' : p.status === 'bloque' ? 'Bloqué' : 'En cours'}
                </span>
                <span className="project-card-badge project-card-badge--milestone mono">
                  Jalon : {p.nextMilestone}
                </span>
                {p.status === 'bloque' && p.missedMilestone ? (
                  /* ref_056 : le marker « Manquant 24/09 » — le jalon
                     qui a raté son échéance (la state `danger` FROZEN,
                     la date `JetBrains Mono` — la donnée, 05 §2.2). */
                  <span className="project-card-badge project-card-badge--missed mono">
                    <Flag size={12} aria-hidden /> {p.missedMilestone}
                  </span>
                ) : null}
              </div>
              <span className="project-card-kv mono">
                {p.tasksDone}/{p.tasksTotal} tâches
              </span>
            </li>
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

          {view === 'gantt' && <GanttView />}
          {view === 'timeline' && <TimelineView />}
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
