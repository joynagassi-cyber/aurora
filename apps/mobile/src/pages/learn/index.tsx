/**
 * Learning family (02 S6.1, 05 §4.6–4.9).
 *
 * /learn — due-reviews list + course chain entry (context-preserving:
 * course → chapter → sheet/QCM/flashcards/mirror). Study position is
 * persistent (ui-state); FSRS state is read-only local (AD-7).
 * /learn/:id — detail overlay over the /learn tab with the study modes.
 *
 * Full 6 UX states + killed. Data = the learning mirrors (courses, QCM,
 * flashcards, FSRS) — not yet wired to `MobileDataProvider`, so the
 * surfaces ship honest empty states + CTAs (never fake data, 05 §4).
 * KaTeX (`MathRenderer`) + virtuoso mount here once Tailwind is on mobile.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useParams } from 'react-router-dom';
import { useState } from 'react';
import { useUiStateStore } from '../../state/ui-state';
import { UxStates, type UxStateFlags } from '../../ux-states';
import { useOnlineStatus } from '../../hooks/use-online';

const STUDY_MODES = [
  ['sheet', 'Fiche'],
  ['qcm', 'QCM'],
  ['flashcards', 'Flashcards'],
  ['mirror', 'Miroir'],
] as const;

type StudyMode = (typeof STUDY_MODES)[number][0];

function emptyFlags() {
  const online = useOnlineStatus();
  const killed = useUiStateStore((s) => s.killed);
  return { flags: { offline: !online, killed } as UxStateFlags, online };
}

export function LearnPage() {
  const { flags } = emptyFlags();

  return (
    <>
      <IonHeader>
        <IonTitle>Apprendre</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-learn-home>
          {/* Due reviews (05 §4.8) — the FSRS read-only mirror. */}
          <UxStates
            state={{ status: 'empty' }}
            flags={flags}
            label="Révisions"
            emptyCta="Reprendre l'étude"
          >
            <div className="learn-section">
              <h2 className="learn-section-title">Révisions dues</h2>
              <p>Aucune révision due (05 §4.8).</p>
            </div>
          </UxStates>

          {/* Course chain entry (context-preserving: course → chapter → …). */}
          <div className="learn-section">
            <h2 className="learn-section-title">Cours</h2>
            <div data-state="empty">
              <p>Aucun cours</p>
              <a className="aurora-btn aurora-btn--ghost aurora-tap" href="/inbox">
                Importer un cours
              </a>
            </div>
          </div>
        </div>
      </IonContent>
    </>
  );
}

export function LearnDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [mode, setMode] = useState<StudyMode>('sheet');
  const { flags } = emptyFlags();

  return (
    <>
      <IonHeader>
        <IonTitle>{id}</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-course-detail data-course-id={id}>
          <span className="breadcrumb">Apprendre &rsaquo; {id}</span>

          <UxStates state={{ status: 'empty' }} flags={flags} label="Étude">
            <div className="learn-detail">
              {/* Study modes (05 §4.7): sheet / QCM / flashcards / mirror.
                  T4 in-page (cosmetic). KaTeX + virtuoso mount here later. */}
              <div className="segmented" role="tablist" aria-label="Mode d'étude">
                {STUDY_MODES.map(([value, label]) => (
                  <button
                    key={value}
                    role="tab"
                    aria-selected={mode === value}
                    className={
                      mode === value
                        ? 'segmented-item active'
                        : 'segmented-item'
                    }
                    onClick={() => setMode(value)}
                  >
                    {label}
                  </button>
                ))}
              </div>
              <p className="learn-detail-hint">
                Contenu d'étude ({mode}) — lecture locale.
              </p>
            </div>
          </UxStates>
        </div>
      </IonContent>
    </>
  );
}
