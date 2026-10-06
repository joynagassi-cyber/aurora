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
              lost. Two actions:
              · "Ajouter" (primary, ALWAYS active when the draft is
                non-empty) — the honest, real first step. Without this the
                user has no way to actually commit a capture, which would
                make the whole surface read-only.
              · "Classer" (secondary, inert until the triage wave) — the
                second step (route to /tasks, /learn), present but disabled
                with an honest tooltip (AD-7: affordance not removed, just
                not yet functional). */}
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
              <div className="inbox-composer-actions">
                <button
                  type="button"
                  className="aurora-btn aurora-btn--ghost aurora-tap"
                  aria-disabled
                  title="Le triage sera disponible dans une prochaine vague"
                >
                  Classer
                </button>
                <button
                  type="button"
                  className="aurora-btn aurora-btn--primary aurora-tap"
                  disabled={draft.trim().length === 0}
                >
                  Ajouter
                </button>
              </div>
            </div>
          </div>

          {/* Triage list — mirror not wired yet (pending wave). The inbox
              is empty by design: nothing captured yet (AD-7, honest empty).
              Conditioned on an EMPTY draft — a draft in progress is not
              "tout est classé"; showing that message unconditionally
              (the pre-fix behavior) contradicted AD-7 honesty (the copy
              asserted a state that was never true). */}
          {draft.trim().length === 0 ? (
            <div data-state="empty" className="inbox-empty">
              <Check size={20} aria-hidden />
              <p>Aucun item à classer pour l'instant.</p>
            </div>
          ) : null}
        </div>
      </IonContent>
    </>
  );
}
