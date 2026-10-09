/**
 * Countdowns (PRD-CD-01, lot C 2026-10-08, ref_109/110/111/112).
 *
 * /countdown — "J-X : qu'est-ce qui approche ?" The days-left on each
 * card is DERIVED from the entity's `targetDate` (AD-7: one source of
 * truth, no fake counter). Today the mirror is not wired — the screen
 * ships an honest empty state + a real create CTA (agent, the single
 * writer that will create the `Countdown` through the owning module,
 * AD-7/F-03). The big number + the target date's own line ("Jours
 * jusqu'à sam. 23/01/2027", ref_109) are the screen's signature, not a
 * KPI tile.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { CalendarClock } from 'lucide-react';
import { useState } from 'react';
import { useOnlineStatus } from '../../hooks/use-online';
import { useKilledDetection } from '../../hooks/use-killed';

/** The day's own line, as the reference's target-date caption reads it. */
function targetCaption(isoDate: string): string {
  const d = new Date(isoDate);
  if (Number.isNaN(d.getTime())) return isoDate;
  return `Jours jusqu'à ${d.toLocaleDateString('fr-FR', {
    weekday: 'short',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  })}`;
}

/** Days-left, DERIVED (targetDate - today, local timezone, AD-7). */
function daysLeft(targetDate: string): number {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const target = new Date(targetDate);
  target.setHours(0, 0, 0, 0);
  return Math.round((target.getTime() - today.getTime()) / 86_400_000);
}

export function CountdownsPage() {
  // AD-7: no mirror wired yet — honest empty, never a fake counter.
  const [countdowns] = useState<
    Array<{ id: string; title: string; targetDate: string; imageUrl?: string }>
  >([]);
  const online = useOnlineStatus();
  const killed = useKilledDetection(() => {});

  const createIntent = () =>
    `/agent?intent=${encodeURIComponent(
      'Crée un compte à rebours : dis-moi le titre, la date d\'arrivée, et si tu veux une photo de fond, je le mets en place.',
    )}`;

  return (
    <>
      <IonHeader>
        <IonTitle>Compte à rebours</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-countdowns className="countdown-page">
          <p className="page-purpose">J-X : qu’est-ce qui approche.</p>

          {countdowns.length === 0 ? (
            <div data-countdown-empty className="countdown-empty-card">
              <CalendarClock size={28} aria-hidden className="countdown-empty-card-icon" />
              <p>Aucun compte à rebours pour l’instant.</p>
              <p className="countdown-empty-card-hint">
                Fête, anniversaire, date marquante — un grand chiffre, une
                date d’arrivée, et c’est parti.
              </p>
              <a className="aurora-btn aurora-btn--primary aurora-tap" href={createIntent()}>
                Créer un compte à rebours
              </a>
            </div>
          ) : (
            <div className="countdown-list" data-state="success">
              {countdowns.map((c) => {
                const left = daysLeft(c.targetDate);
                const passed = left < 0;
                return (
                  <article
                    key={c.id}
                    className={`countdown-card${c.imageUrl ? ' countdown-card--image' : ''}`}
                    data-state={passed ? 'passed' : 'active'}
                  >
                    {c.imageUrl && (
                      <img
                        className="countdown-card-image"
                        src={c.imageUrl}
                        alt=""
                        aria-hidden
                      />
                    )}
                    <div className="countdown-card-body">
                      <span className="countdown-card-num mono" aria-hidden>
                        {Math.abs(left)}
                      </span>
                      <span className="countdown-card-title">{c.title}</span>
                      <span className="countdown-card-target mono">
                        {targetCaption(c.targetDate)}
                      </span>
                    </div>
                  </article>
                );
              })}
            </div>
          )}

          {/* AD-13 offline/killed affordances (the data is local, it stays
               readable; killed = auto-resync on return). */}
          {!online && (
            <p className="countdown-page-note">Hors ligne — les jours se mettent à jour au retour du réseau.</p>
          )}
          {killed && <p className="countdown-page-note">Reconnexion…</p>}
        </div>
      </IonContent>
    </>
  );
}
