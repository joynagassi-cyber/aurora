/**
 * Tasks list + detail (02 S6.1, G-L5 eisenhower ratified → T4 under /tasks).
 *
 * The view (list / eisenhower / calendar) is a T4 ui-state (context-
 * preserving: the filter is cosmetic + persistent, the data is local AD-7).
 * Data = the tasks mirror (`useTasks`). Full 6 UX states + killed (AD-13).
 * Empty state = "no tasks" + capture CTA (routes to /inbox).
 *
 * C5.4 (2026-10-08, propagation) : the « ⋮ » menu (per-page + global
 * settings overflow, 05 §3.5 l.843-854) + the horizontal glide that
 * reveals a hidden detail panel (05 §3.6.15 l.1402-1411) — the SAME
 * pattern as `/projects` (the plan C5.4 : « réutilisé tel quel pour
 * /tasks »). The glide uses the shared `useHorizontalSwiper` hook
 * (pointer-based, GPU-only, `prefers-reduced-motion` = disabled); the
 * panel + the menu items carry the colored 16px icons (ref_045).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import {
  AlignLeft,
  Check,
  ChevronDown,
  Flag,
  LayoutGrid,
  List,
  Plus,
  Repeat,
  Signal,
  type LucideIcon,
} from 'lucide-react';import { useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import type { AppError, Task, TaskStatus } from '@aurora/domain';
import { useTasks, useTask } from '../../query/hooks';
import { useUiStateStore } from '../../state/ui-state';
import { EisenhowerSkeleton, TaskRowSkeleton } from '../../ux/skeletons';
import { UxStates, type UxStateFlags } from '../../ux-states';
import { useKilledDetection } from '../../hooks/use-killed';
import { useOnlineStatus } from '../../hooks/use-online';
import {
  PageOptionsMenu,
  settingsItem,
  type PageOptionItem,
} from '../../ux/page-options-menu';
import { useHorizontalSwiper } from '../../ux/use-horizontal-swiper';

/** Statuts tâches → libellé simple (zéro jargon, roadmap 10-07). */
const TASK_STATUS_FR: Record<string, string> = {
  todo: 'À faire',
  in_progress: 'En cours',
  done: 'Terminée',
  blocked: 'Bloquée',
  cancelled: 'Annulée',
};

/** The in-page views (T4 — the router does NOT know about them).
 * PRD-1 2026-10 : « Aujourd'hui » = la vue quotidienne (PRD-TASK-01 :
 * en retard / aujourd'hui / habitudes / terminées), avant Liste et
 * Quadrants. */
const TASK_VIEWS = [
  ['today', "Aujourd'hui"],
  ['list', 'Liste'],
  ['eisenhower', 'Quadrants'],
] as const;

function taskFlags(refetch: () => void, online: boolean) {
  const killed = useKilledDetection(refetch);
  const flags: UxStateFlags = { offline: !online, killed, onRetry: refetch };
  return flags;
}

/**
 * Format an ISO due date to the French style used in the reference
 * (ref_035: « 14 oct. 2022 », not the raw ISO string).
 */
function fmtDue(iso: string | undefined): string | null {
  if (!iso) return null;
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return null;
  return d.toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: 'numeric' });
}

/**
 * Priority flag (ref_035 — the 4-color priority ramp, NOT tag colors):
 *   rouge   = urgent (Q1, priority >= 4)
 *   vert    = bien  (Q2, priority === 3)
 *   jaune   = attentif (Q3, priority === 2)
 *   gris    = neutre (Q4, priority undefined / 0 / 1)
 * The flag is a static `Flag` icon (05 §2.5 — never below 16px) colored
 * with the frozen semantic states (05 §5.1 / AD-17 : never a raw color).
 */
function PriorityFlag({ priority }: { priority?: number }) {
  const tone = priority !== undefined && priority >= 4
    ? 'danger'
    : priority === 3
      ? 'success'
      : priority === 2
        ? 'warning'
        : 'muted';
  const cls =
    tone === 'danger'
      ? 'task-row-flag task-row-flag--danger'
      : tone === 'success'
        ? 'task-row-flag task-row-flag--success'
        : tone === 'warning'
          ? 'task-row-flag task-row-flag--warning'
          : 'task-row-flag task-row-flag--muted';
  return <span className={cls} aria-hidden><Flag size={16} /></span>;
}

/** A task as a card row (list view) — priority flag + due date FR + done state. */
function TaskRow({ task }: { task: Task }) {
  const done = task.status === 'done';
  const due = fmtDue(task.dueAt);
  return (
    <a
      className={`task-row aurora-tap${done ? ' is-done' : ''}`}
      href={`/tasks/${task.id}`}
    >
      <PriorityFlag priority={task.priority} />
      <span
        className="task-row-check"
        data-status={task.status}
        aria-hidden
      />
      <span className={`task-row-title${done ? ' is-done' : ''}`}>{task.title}</span>
      {due && (
        <span className="task-row-due mono">{due}</span>
      )}
    </a>
  );
}

/** Row of the daily view (PRD-TASK-01): time in accent on the right,
 *  red date when overdue, strikethrough when done, priority flag left. */
function TodayTaskRow({ task, kind }: { task: Task; kind: 'overdue' | 'today' | 'done' }) {
  const time = task.dueAt ? task.dueAt.slice(11, 16) : '';
  const done = kind === 'done';
  const due = fmtDue(task.dueAt);
  return (
    <a
      className={`task-row task-row--plain aurora-tap${done ? ' is-done' : ''}`}
      href={`/tasks/${task.id}`}
    >
      <PriorityFlag priority={task.priority} />
      <span
        className="task-row-check"
        data-status={task.status}
        aria-hidden
      />
      <span className={`task-row-title${done ? ' is-done' : ''}`}>
        {task.title}
      </span>
      {kind === 'overdue' && due ? (
        <span className="task-row-due task-row-due--overdue mono">
          Échue {due}
        </span>
      ) : kind === 'today' && time ? (
        <span className="task-row-time mono">{time}</span>
      ) : null}
    </a>
  );
}

/**
 * The daily « Aujourd'hui » view (PRD-1, PRD-TASK-01) — ce qui compte
 * maintenant dans le module Tâches (ref_056, lot C 2026-10-08 : la page
 * est un « monument » du jour, pas une liste plate — le bandeau du haut
 * porte les chiffres, les sections restent muettes en dessous).
 *   · bandeau « task-today-overview » : grand compteur du jour + compteur
 *     d'habitudes (lien /habits) + « en retard » si non nul — l'ordre
 *     reflète la priorité visuelle de la ref ;
 *   · section « En retard » : compteur + CTA « Reporter » qui route vers
 *     l'agent (replanification assistée — AD-7 : la page ne mute jamais
 *     une tâche elle-même, le replan passe par le noyau);
 *   · section « Aujourd'hui » : les tâches dues aujourd'hui, heure en
 *     accent à droite ;
 *   · section « Terminées » repliable avec compteur (texte barré grisé).
 * Tout est DÉRIVÉ du miroir local (AD-7) — aucun faux contenu.
 */
function TodayView({ tasks }: { tasks: Task[] }) {
  const [showDone, setShowDone] = useState(false);
  const now = new Date();
  const dayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const todayEnd = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);

  const overdue = tasks.filter(
    (t) => t.status !== 'done' && t.dueAt && new Date(t.dueAt) < dayStart,
  );
  const today = tasks.filter(
    (t) =>
      t.status !== 'done' &&
      t.dueAt &&
      new Date(t.dueAt) >= dayStart &&
      new Date(t.dueAt) < todayEnd,
  );
  const done = tasks.filter((t) => t.status === 'done');

  const isOverdueDate = (t: Task) =>
    Boolean(t.dueAt && new Date(t.dueAt) < dayStart);

  /* Bandeau « monument » (ref_056) — le chiffre du JOUR, en retrait de
   * l'overdue quand il y en a (la tension se lit d'un coup d'œil, pas à
   * chercher dans les sections). */
  const headline = overdue.length > 0
    ? `${overdue.length} à rattraper`
    : today.length > 0
      ? `${today.length} au programme`
      : done.length > 0
        ? `${done.length} terminée${done.length > 1 ? 's' : ''} aujourd'hui`
        : 'Jour calme';

  const HeadlineIcon: LucideIcon =
    overdue.length > 0 ? Repeat : today.length > 0 ? ChevronDown : Check;

  return (
    <div className="task-today" data-state="success">
      {/* Bandeau du jour — l'« horizon » du module, avant les sections. */}
      <div
        className="task-today-overview"
        role="group"
        aria-label={`Bilan du jour : ${headline}${overdue.length ? `, ${overdue.length} en retard` : ''}`}
      >
        <span className="task-today-overview-num mono" aria-hidden>
          {overdue.length > 0 ? overdue.length : today.length}
        </span>
        <div className="task-today-overview-copy">
          <p className="task-today-overview-eyebrow">
            <HeadlineIcon size={13} aria-hidden /> {headline}
          </p>
          {overdue.length > 0 && (
            <p className="task-today-overdue-note mono">{overdue.length} en retard</p>
          )}
        </div>
      </div>

      {/* Section « En retard » (PRD-TASK-01 : compteur + Reporter). */}
      {overdue.length > 0 && (
        <section
          className="task-today-section task-today-section--overdue"
          aria-label={`En retard, ${overdue.length} tâche(s)`}
        >
          <header className="task-today-header">
            <h3>
              En retard
              <span className="task-today-count">{overdue.length}</span>
            </h3>
            {/* Replanification assistée par l'agent (spec Productivity :
                « agent-assisted replanning ») — jamais de mutation directe
                depuis la liste (AD-7 single-writer). */}
            <a
              className="task-today-postpone aurora-btn aurora-btn--ghost aurora-tap"
              href="/agent?intent=Replanifie%20mes%20t%C3%A2ches%20en%20retard%20%3A%20propose-moi%20des%20nouveaux%20d%C3%A9lais%20et%20applique-les"
            >
              <Repeat size={14} aria-hidden /> Reporter
            </a>
          </header>
          <div className="task-list task-list--plain">
            {overdue.map((t) => (
              <li key={t.id}>
                <TodayTaskRow task={t} kind={isOverdueDate(t) ? 'overdue' : 'today'} />
              </li>
            ))}
          </div>
        </section>
      )}

      {/* Section « Aujourd'hui » (PRD-TASK-01 : tâches dues ce jour). */}
      <section
        className="task-today-section"
        aria-label={`Aujourd'hui, ${today.length} tâche(s)`}
      >
        <header className="task-today-header">
          <h3>
            Aujourd'hui
            <span className="task-today-count">{today.length}</span>
          </h3>
        </header>
        {today.length === 0 ? (
          <p className="task-today-empty">Rien de prévu pour aujourd'hui.</p>
        ) : (
          <div className="task-list task-list--plain">
            {today.map((t) => (
              <li key={t.id}>
                <TodayTaskRow task={t} kind="today" />
              </li>
            ))}
          </div>
        )}
      </section>

      {/* Ligne « Mes habitudes » (PRD-1 §4.5) — navigation honnête. */}
      <a className="task-today-habits aurora-tap" href="/habits">
        <span>Mes habitudes</span>
        <ChevronDown
          size={14}
          aria-hidden
          className="task-today-habits-chevron task-today-chevron--right"
        />
      </a>

      {/* Section « Terminées » repliable (compteur + texte barré grisé). */}
      {done.length > 0 && (
        <section className="task-today-section task-today-section--done">
          <button
            type="button"
            className="task-today-toggle aurora-tap"
            aria-expanded={showDone}
            onClick={() => setShowDone((v) => !v)}
          >
            <h3>
              Terminées
              <span className="task-today-count">{done.length}</span>
            </h3>
            <ChevronDown size={16} aria-hidden className={`task-today-chevron ${showDone ? 'is-open' : ''}`} />
          </button>
          {showDone && (
            <div className="task-list">
              {done.map((t) => (
                <li key={t.id}>
                  <TodayTaskRow task={t} kind="done" />
                </li>
              ))}
            </div>
          )}
        </section>
      )}
    </div>
  );
}

export function TasksPage() {
  const { data: tasks, isPending, isError, refetch } = useTasks();
  const view = useUiStateStore((s) => s.tasksView);
  const setView = useUiStateStore((s) => s.setTasksView);
  const tasksSort = useUiStateStore((s) => s.tasksSort);
  const setTasksSort = useUiStateStore((s) => s.setTasksSort);
  const panelOpen = useUiStateStore((s) => s.panelOpen);
  const setPanelOpen = useUiStateStore((s) => s.setPanelOpen);
  const online = useOnlineStatus();
  const flags = taskFlags(() => refetch(), online);

  /** C5.4 : le glissement horizontal REVOILE le panneau latéral caché
      (05 §3.6.15 l.1402-1411) — `useHorizontalSwiper` partagé (pointer-
      based, GPU-only, `prefers-reduced-motion` = désactivé, le bascule
      reste au tap). Le panneau reste T4 cosmetic-persistent (le retour
      y retrouve le panneau ouvert). */
  const { isGliding, handlers, surfaceStyle } = useHorizontalSwiper(setPanelOpen);

  /** C5.4 : le menu « ⋮ » (05 §3.5 l.843-854, max 6 items) — 3 items de
      tri + 3 items de vue (la vue par défaut « Aujourd'hui » n'est PAS
      dans le menu, K-10) + 1 item « Paramètres » = 7 items → troncature
      défensive à 6 (le dernier tri est coupé si le max est atteint).
      Chaque item porte une icône 16px couleur (ref_045) — les teintes
      sont les états FROZEN (05 §5.1, AD-17 : jamais une valeur brute). */
  const VIEW_ICONS: Record<string, { icon: LucideIcon; tone: PageOptionItem['iconTone'] }> = {
    today: { icon: Flag, tone: 'danger' },
    list: { icon: List, tone: 'accent' },
    eisenhower: { icon: LayoutGrid, tone: 'success' },
  };
  const menuItems: PageOptionItem[] = [
    {
      id: 'tri-echeance',
      label: 'Trier par échéance',
      icon: AlignLeft,
      iconTone: 'info',
      active: tasksSort === 'echeance',
      onClick: () => setTasksSort('echeance'),
    },
    {
      id: 'tri-priorite',
      label: 'Trier par priorité',
      icon: Signal,
      iconTone: 'warning',
      active: tasksSort === 'priorite',
      onClick: () => setTasksSort('priorite'),
    },
    ...(['today', 'list', 'eisenhower'] as const).map((v) => ({
      id: `vue-${v}`,
      label: TASK_VIEWS.find(([val]) => val === v)?.[1] ?? v,
      icon: VIEW_ICONS[v]?.icon,
      iconTone: VIEW_ICONS[v]?.tone,
      active: view === v,
      onClick: () => setView(v as typeof view),
    })),
    settingsItem('tasks'),
  ];

  const list = tasks ?? [];
  const taskState = isError
    ? ({ status: 'error', error: { code: 'task/load_failed', message: 'Tâches indisponibles' } as AppError } as const)
    : isPending
      ? ({ status: 'loading' } as const)
      : list.length === 0
        ? ({ status: 'empty' } as const)
        : ({ status: 'success', data: list } as const);

  // Eisenhower: 4 quadrants (do-now / schedule / delegate / drop).
  const quadrant = (t: Task) => {
    const urgent = Boolean(t.dueAt);
    const important = t.priority !== undefined && t.priority >= 4;
    if (urgent && important) return 'q1';
    if (!urgent && important) return 'q2';
    if (urgent && !important) return 'q3';
    return 'q4';
  };
  const q = { q1: [] as Task[], q2: [] as Task[], q3: [] as Task[], q4: [] as Task[] };
  for (const t of list) q[quadrant(t)].push(t);

  return (
    <>
      <IonHeader>
        <div className="tasks-header">
          <IonTitle>Tâches</IonTitle>
          <PageOptionsMenu items={menuItems} ariaLabel="Options de la page Tâches" />
        </div>
      </IonHeader>
      <IonContent>
        <div
          data-tasks-view={view}
          className={`tasks-surface${isGliding ? ' is-gliding' : ''}`}
          style={surfaceStyle}
          onPointerDown={handlers.onPointerDown}
          onPointerMove={handlers.onPointerMove}
          onPointerUp={handlers.onPointerUp}
          onPointerLeave={handlers.onPointerUp}
        >
          {/* Le but du module, en une ligne simple (pattern lots 1+2,
              zéro jargon technique visible par l'utilisateur). */}
          <p className="page-purpose">
            Tout ce qu'il y a à faire, dans le bon ordre.
          </p>

          <div className="segmented" role="tablist" aria-label="Vue tâches">
            {TASK_VIEWS.map(([value, label]) => (
              <button
                key={value}
                role="tab"
                aria-selected={view === value}
                className={view === value ? 'segmented-item active' : 'segmented-item'}
                onClick={() => setView(value)}
              >
                {label}
              </button>
            ))}
          </div>

          <UxStates
            state={taskState}
            flags={{ ...flags, emptyCta: "Capturer une tâche", emptyCtaHref: "/inbox" }}
            label="Tâches"
            skeleton={
              view === 'eisenhower' ? <EisenhowerSkeleton /> : <TaskRowSkeleton count={3} />
            }
          >
            {view === 'today' ? (
              <TodayView tasks={list} />
            ) : view === 'eisenhower' ? (
              <div className="eisenhower" data-state="success">
                {(
                  [
                    ['q1', 'Urgent · Important'],
                    ['q2', 'Important'],
                    ['q3', 'Urgent'],
                    ['q4', 'Négliger'],
                  ] as const
                ).map(([key, label], i) => (
                  <div key={key} className={`eisenhower-q eisenhower-${key}`}>
                    <span className="eisenhower-q-title">
                      <span className="eisenhower-q-num mono" aria-hidden>
                        {i + 1}
                      </span>
                      {label}
                    </span>
                    {q[key].length === 0 ? (
                      <p className="eisenhower-q-empty">Vide</p>
                    ) : (
                      q[key].map((t) => <TaskRow key={t.id} task={t} />)
                    )}
                  </div>
                ))}
              </div>
            ) : (
              <div className="task-list" data-state="success">
                {list.map((t) => (
                  <li key={t.id}>
                    <TaskRow task={t} />
                  </li>
                ))}
              </div>
            )}
          </UxStates>
        </div>

        {/* Le panneau caché révélé par le glissement horizontal (C5.4) —
            transformé en slide latéral (GPU-only), jamais un overlay
            qui masque la page (le panneau COEXISTE avec la vue).
            ref_045 : le panneau porte le profil de la tâche courante
            (nom + % + jalon manqué + CTA) — jamais un écran vide mort. */}
        {panelOpen && (
          <div
            data-tasks-panel-open
            className="tasks-panel-slide"
            role="complementary"
            aria-label="Détail de la tâche"
          >
            <div data-tasks-panel className="tasks-panel">
              <p className="page-purpose">Le détail de la tâche.</p>
              <div className="tasks-panel-profile">
                <div className="tasks-panel-profile-head">
                  <span className="tasks-panel-profile-name">Tâche</span>
                  <span className="tasks-panel-profile-pct mono">0%</span>
                </div>
                <div className="tasks-panel-profile-progress">
                  <div
                    className="tasks-panel-profile-progress-fill"
                    style={{ width: '0%' }}
                  />
                </div>
                <span className="tasks-panel-profile-missed mono">
                  <Flag size={12} aria-hidden /> Manquant 24/09
                </span>
                <a
                  className="aurora-btn aurora-btn--primary aurora-tap tasks-panel-cta"
                  href="/agent?intent=Cr%C3%A9e%20ma%20t%C3%A2che%20:%20aide-moi%20%C3%A0%20la%20nommer%2C%20%C3%A0%20lui%20poser%20une%20%C3%A9ch%C3%A9ance%20et%20une%20priorit%C3%A9"
                >
                  <Plus size={16} aria-hidden /> Créer une tâche
                </a>
              </div>
            </div>
          </div>
        )}
      </IonContent>
    </>
  );
}

export function TaskDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { data: task, isPending, isError, refetch } = useTask(id);
  const online = useOnlineStatus();
  const flags = taskFlags(() => refetch(), online);

  const detailState = isError
    ? ({ status: 'error', error: { code: 'task/not_found', message: 'Tâche introuvable' } as AppError } as const)
    : isPending
      ? ({ status: 'loading' } as const)
      : !task
        ? ({ status: 'empty' } as const)
        : ({ status: 'success', data: task } as const);

  const status: TaskStatus = task?.status ?? 'todo';

  return (
    <IonContent>
      <IonHeader>
        <IonTitle>{task?.title ?? 'Tâche'}</IonTitle>
      </IonHeader>
      <UxStates state={detailState} flags={flags} label="Tâche">
        <div data-task-detail>
          <button className="aurora-btn aurora-btn--ghost aurora-tap" onClick={() => navigate(-1)}>
            Retour à la liste
          </button>
          {task && (
            <>
              <div data-task-meta>
                <span
                  className="task-status-chip"
                  data-status={status}
                >
                  {TASK_STATUS_FR[status] ?? status.replace('_', ' ')}
                </span>
                {task.dueAt && (
                  <span className="task-due mono">échéance {task.dueAt.slice(0, 10)}</span>
                )}
              </div>
              {task.description && <p className="task-description">{task.description}</p>}
            </>
          )}
        </div>
      </UxStates>
    </IonContent>
  );
}
