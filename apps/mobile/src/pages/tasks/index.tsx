/**
 * Tasks list + detail (02 S6.1, G-L5 eisenhower ratified → T4 under /tasks).
 *
 * The view (list / eisenhower / calendar) is a T4 ui-state (context-
 * preserving: the filter is cosmetic + persistent, the data is local AD-7).
 * Data = the tasks mirror (`useTasks`). Full 6 UX states + killed (AD-13).
 * Empty state = "no tasks" + capture CTA (routes to /inbox).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { ChevronDown, Repeat } from 'lucide-react';
import { useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import type { AppError, Task, TaskStatus } from '@aurora/domain';
import { useTasks, useTask } from '../../query/hooks';
import { useUiStateStore } from '../../state/ui-state';
import { EisenhowerSkeleton, TaskRowSkeleton } from '../../ux/skeletons';
import { UxStates, type UxStateFlags } from '../../ux-states';
import { useKilledDetection } from '../../hooks/use-killed';
import { useOnlineStatus } from '../../hooks/use-online';

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

/** A task as a card row (list view). */
function TaskRow({ task }: { task: Task }) {
  return (
    <a className="task-row aurora-tap" href={`/tasks/${task.id}`}>
      <span
        className="task-row-dot"
        data-status={task.status}
        aria-hidden
      />
      <span className="task-row-title">{task.title}</span>
      {task.dueAt && (
        <span className="task-row-due mono">{task.dueAt.slice(0, 10)}</span>
      )}
    </a>
  );
}

/** Row of the daily view (PRD-TASK-01): time in accent on the right,
 *  red date when overdue, strikethrough when done. */
function TodayTaskRow({ task, kind }: { task: Task; kind: 'overdue' | 'today' | 'done' }) {
  const time = task.dueAt ? task.dueAt.slice(11, 16) : '';
  return (
    <a className="task-row aurora-tap" href={`/tasks/${task.id}`}>
      <span className="task-row-dot" data-status={task.status} aria-hidden />
      <span className={`task-row-title ${kind === 'done' ? 'is-done' : ''}`}>
        {task.title}
      </span>
      {kind === 'overdue' && task.dueAt ? (
        <span className="task-row-due task-row-due--overdue mono">
          Échue {task.dueAt.slice(0, 10)}
        </span>
      ) : kind === 'today' && time ? (
        <span className="task-row-time mono">{time}</span>
      ) : null}
    </a>
  );
}

/**
 * The daily « Aujourd'hui » view (PRD-1, PRD-TASK-01) — ce qui compte
 * maintenant dans le module Tâches :
 *   · section « En retard » : compteur + CTA « Reporter » qui route vers
 *     l'agent (replanification assistée — AD-7 : la page ne mute jamais
 *     une tâche elle-même, le replan passe par le noyau);
 *   · section « Aujourd'hui » : les tâches dues aujourd'hui, heure en
 *     accent à droite ;
 *   · ligne « Mes habitudes » → /habits (PRD-1 §4.5) ;
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

  return (
    <div className="task-today" data-state="success">
      {/* Section « En retard » (PRD-TASK-01 : compteur + Reporter). */}
      {overdue.length > 0 && (
        <section className="task-today-section task-today-section--overdue">
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
          <div className="task-list">
            {overdue.map((t) => (
              <li key={t.id}>
                <TodayTaskRow task={t} kind={isOverdueDate(t) ? 'overdue' : 'today'} />
              </li>
            ))}
          </div>
        </section>
      )}

      {/* Section « Aujourd'hui » (PRD-TASK-01 : tâches dues ce jour). */}
      <section className="task-today-section">
        <header className="task-today-header">
          <h3>
            Aujourd'hui
            <span className="task-today-count">{today.length}</span>
          </h3>
        </header>
        {today.length === 0 ? (
          <p className="task-today-empty">Rien de prévu pour aujourd'hui.</p>
        ) : (
          <div className="task-list">
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
  const online = useOnlineStatus();
  const flags = taskFlags(() => refetch(), online);

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
        <IonTitle>Tâches</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-tasks-view={view}>
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
                ).map(([key, label]) => (
                  <div key={key} className={`eisenhower-q eisenhower-${key}`}>
                    <span className="eisenhower-q-title">{label}</span>
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
