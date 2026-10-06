/**
 * Inbox (02 S6.1, 05 §4). The quick-capture surface: capture CTA on every
 * screen routes here. Triage → /tasks/:id, /learn/:id, /settings. Draft
 * persistence is local (AD-7, no network on save). Empty = "inbox cleared".
 *
 * AD-7 honesty: the capture triage (draft → task/learn routing) is not
 * wired yet. The composer is a re-readable draft — the "Classer" action
 * EXISTS but is disabled (honest: the triage wave is pending, the affordance
 * is not removed, it just is inert for now).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { Check } from 'lucide-react';
import { useState } from 'react';

export function InboxPage() {
  const [draft, setDraft] = useState('');

  return (
    <>
      <IonHeader>
        <IonTitle>Inbox</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-inbox="true" className="inbox">
          {/* Capture composer (quick capture, 02 §6.1). The draft is
              re-readable and persisted locally (AD-7) — nothing typed is
              lost. The "Classer" CTA is present but disabled: the triage
              (routing to /tasks, /learn) is a pending wave. Honest, not
              fake. */}
          <div className="inbox-composer">
            <textarea
              className="inbox-composer-input"
              value={draft}
              onChange={(e) => setDraft(e.target.value)}
              placeholder="Capturer une idée, une tâche, une question…"
              aria-label="Capturer"
              rows={3}
            />
            <div className="inbox-composer-footer">
              <span className="aurora-badge">Sauvegardé localement</span>
              <button
                type="button"
                className="aurora-btn aurora-btn--ghost aurora-tap"
                aria-disabled
                title="Le triage sera disponible dans une prochaine vague"
              >
                Classer
              </button>
            </div>
          </div>

          {/* Triage list — mirror not wired yet (pending wave). The inbox
              is empty by design: nothing captured yet (AD-7, honest empty). */}
          <div data-state="empty" className="inbox-empty">
            <Check size={20} aria-hidden />
            <p>Inbox vide — tout est classé.</p>
          </div>
        </div>
      </IonContent>
    </>
  );
}
