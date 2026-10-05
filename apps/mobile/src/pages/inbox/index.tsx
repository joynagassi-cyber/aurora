/**
 * Inbox (02 S6.1, 05 §4). The quick-capture surface: capture CTA on every
 * screen routes here. Triage → /tasks/:id, /learn/:id, /settings. Draft
 * persistence is local (AD-7, no network on save). Empty = "inbox cleared".
 * Full 6 UX states + killed (AD-13, G-M2).
 *
 * Tiptap (the capture editor) mounts here once Tailwind is on mobile; this
 * turn ships a token-styled composer + an honest empty list.
 *
 * AD-7 honesty: the capture triage (draft → task/learn routing) is not
 * wired yet. The composer is a re-readable draft — there is deliberately no
 * capture CTA (a "Capturer" button would claim a triage that does not
 * happen); the textarea stays editable so nothing typed is lost.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { Check } from 'lucide-react';
import { useState } from 'react';

export function InboxPage() {
  const [draft, setDraft] = useState('');
  // Local capture buffer (AD-7 surface state). Triage routes each item to
  // its owning screen; the inbox mirror is not yet wired → honest empty.
  const captured: string[] = [];

  return (
    <>
      <IonHeader>
        <IonTitle>Inbox</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-inbox="true" className="inbox">
          {/* Capture composer (quick capture, 02 §6.1). The draft is
              re-readable — the triage (routing to /tasks, /learn) is a
              pending wave, so the CTA is an honest badge, not a button. */}
          <div className="inbox-composer">
            <textarea
              className="inbox-composer-input"
              value={draft}
              onChange={(e) => setDraft(e.target.value)}
              placeholder="Capturer une idée, une tâche, une question…"
              aria-label="Capturer"
              rows={3}
            />
            <span className="aurora-badge">Capture en cours de wiring</span>
          </div>

          {/* Triage list (local draft; mirror not wired → honest empty). */}
          {captured.length === 0 ? (
            <div data-state="empty" className="inbox-empty">
              <Check size={20} aria-hidden />
              <p>Inbox vide — tout est classé.</p>
            </div>
          ) : (
            <ul className="inbox-list">
              {captured.map((c, i) => (
                <li key={i} className="inbox-item">
                  <span>{c}</span>
                </li>
              ))}
            </ul>
          )}
        </div>
      </IonContent>
    </>
  );
}
