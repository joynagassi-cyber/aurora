/**
 * Tasks list + detail (02 S6.1 page matrix).
 *
 * List filters live in the ui-state store (02 §3: view mode is cosmetic
 * state, persistent). Data = local store (AD-7). Empty state = "no tasks" +
 * capture CTA. Detail opens OVER the /tasks tab (IonModal/IonSlides — never
 * a tab switch). Return to list keeps scroll + filters.
 *
 * Eisenhower quadrant view (G-L5) = a `tasksView` mode, NOT a separate
 * route (context-preserving: the filter is ui-state, the data is local).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useTasks, useTask } from '../../query/hooks';
import { useUiStateStore } from '../../state/ui-state';
import { useParams, useNavigate } from 'react-router-dom';

export function TasksPage() {
  const { data: tasks, isPending, isError } = useTasks();
  const view = useUiStateStore((s) => s.tasksView);

  return (
    <>
      <IonHeader>
        <IonTitle>Tâches</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-view={view}>
          {isPending && <div data-state="loading" />}
          {isError && <div data-state="error">Liste indisponible</div>}
          {tasks && tasks.length === 0 && (
            <div data-state="empty">
              Aucune tâche
              <button data-capture="true">Capturer</button>
            </div>
          )}
          <ul className="task-list">
            {tasks?.map((t) => (
              <li key={t.id}>
                <a href={`/tasks/${t.id}`}>{t.title}</a>
              </li>
            ))}
          </ul>
        </div>
      </IonContent>
    </>
  );
}

export function TaskDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { data: task, isPending } = useTask(id);

  return (
    <IonContent>
      {isPending && <div data-state="loading" />}
      {task && (
        <div>
          <IonHeader>
            <IonTitle>{task.title}</IonTitle>
          </IonHeader>
          <button onClick={() => navigate(-1)}>Retour à la liste</button>
        </div>
      )}
    </IonContent>
  );
}
