/**
 * Tasks list + detail (02 S6.1, G-L5 eisenhower ratified → T4 under /tasks).
 *
 * The view (list / eisenhower / calendar) is a T4 ui-state (context-
 * preserving: the filter is cosmetic + persistent, the data is local AD-7).
 * Data = the tasks mirror (`useTasks`). Full 6 UX states + killed (AD-13).
 * Empty state = "no tasks" + capture CTA (routes to /inbox).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useNavigate, useParams } from 'react-router-dom';
import type { AppError, Task, TaskStatus } from '@aurora/domain';
import { useTasks, useTask } from '../../query/hooks';
import { useUiStateStore } from '../../state/ui-state';
import { EisenhowerSkeleton, TaskRowSkeleton } from '../../ux/skeletons';
import { UxStates, type UxStateFlags } from '../../ux-states';
import { useKilledDetection } from '../../hooks/use-killed';
import { useOnlineStatus } from '../../hooks/use-online';

/** The 2 in-page views (T4 — the router does NOT know about them). */
const TASK_VIEWS = [
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
            flags={{ ...flags, emptyCta: "Capturer une tâche" }}
            label="Tâches"
            skeleton={
              view === 'eisenhower' ? <EisenhowerSkeleton /> : <TaskRowSkeleton count={3} />
            }
          >
            {view === 'eisenhower' ? (
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
                  {status.replace('_', ' ')}
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
