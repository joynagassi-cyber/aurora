/**
 * Agent conversation (02 S6.1, F-09: the device sees ONLY AgentRunState).
 *
 * /agent — the conversation surface. The premium chrome: a calm transcript +
 * a pinned composer. The "thinking" state is the organic organism
 * (ui-libraries §9.3 AgentThinkingLoader @aurora/ui); when no run is
 * streaming yet, the token-native `.agent-thinking` fallback reads the same.
 *
 * Empty state = an invitation to a first intention (02 §6.2), NOT a
 * search box. Runs + history stream into the transcript from
 * `AgentRunState` (F-09, AD-7 local read-only); the draft is a local
 * surface state (AD-7: no network on save).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { Send } from 'lucide-react';
import { useState } from 'react';

export function AgentPage() {
  // Local draft (AD-7 surface state). A real run plugs into the transcript
  // via AgentRunState (F-09). On submit the organic organism (§9.3) shows
  // while the run is in flight — honest pending UX, not fake streaming.
  const [draft, setDraft] = useState('');
  const [thinking, setThinking] = useState(false);

  return (
    <>
      <IonHeader>
        <IonTitle>Aurora</IonTitle>
      </IonHeader>
      <IonContent>
        <div className="agent-chat">
          <div
            className="agent-transcript"
            data-state={thinking ? 'loading' : 'empty'}
          >
            {thinking ? (
              <div className="agent-thinking">
                <div className="agent-thinking-blobs" aria-hidden />
                <span className="agent-thinking-label">L'agent réfléchit…</span>
              </div>
            ) : (
              <div className="agent-empty">
                <p>Commence par une intention — « aie-moi à … ».</p>
              </div>
            )}
          </div>

          <form
            className="agent-composer"
            onSubmit={(e) => {
              e.preventDefault();
              if (draft.trim().length === 0) return;
              // A real run: post the intention to the kernel (AgentRunState
              // streaming). Until wired, surface the thinking organism.
              setThinking(true);
              setDraft('');
            }}
          >
            <input
              value={draft}
              onChange={(e) => setDraft(e.target.value)}
              placeholder="Écris ton intention…"
              aria-label="Écrire à l'agent"
            />
            <button type="submit" disabled={draft.trim().length === 0} aria-label="Envoyer">
              <Send size={18} />
            </button>
          </form>
        </div>
      </IonContent>
    </>
  );
}
