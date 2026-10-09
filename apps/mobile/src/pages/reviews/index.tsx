/**
 * Reviews (05 §4.5.1, docs `revues-jour/semaine/mois.md`, lot C v3 2026-10-08,
 * ref_093–096).
 *
 * /reviews — the PERIOD REVIEW as an ACTION (doc §2.9 « réviser, pas voir ») :
 * ONE `Card` posée with the 5 fixed sections (bilan des tâches / analyse des
 * causes / révision des priorités / plan d'action suivant / journal des
 * décisions), pre-filled by the LOCAL data (AD-7 : the usage is to ADJUST,
 * not to write blank). The 3 periods share ONE time `Pager`
 * (Jour | Semaine | Mois, 05 §3.4 l.737–750 — the same component as the
 * calendar's), and the « À faire / Faite » switch carries only 2 segments :
 * a CANCELLED review is a historical `Callout info`, never a 3rd tab
 * (05 §4.5.1 l.2256–2263).
 *
 * AD-7 honesty: the review mirror is not wired to `MobileDataProvider` yet →
 * the screen ships its honest empty state + a real « Faire la revue » CTA
 * (through the agent, the single writer, AD-7/F-03). The « en retard »
 * Callout is a LOCAL computation (OQ-4 close a, AD-7) shown only when the
 * PREVIOUS period's review is genuinely absent — never a fake warning.
 * The agent SUGGESTS, the user DECIDES (05 §4.5.1 l.2358–2367) : the CTA of
 * the late Callout routes to the agent's suggestion, not to a free proposal.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { AlarmClock, ClipboardList, Compass } from 'lucide-react';
import { useState } from 'react';

type ReviewPeriod = 'jour' | 'semaine' | 'mois';
type ReviewStatus = 'a_faire' | 'faite';

/** Section 1 — a task of the period's recap (05 §4.5.1 l.2280–2287 :
 *  4 columns statut / titre / projet / « pourquoi »). */
interface ReviewBilanRow {
  id: string;
  status: 'accomplie' | 'reportee' | 'abandonnee' | 'bloquee';
  title: string;
  project: string;
  why: string;
}

const STATUS_LABELS: Record<ReviewBilanRow['status'], string> = {
  accomplie: 'Accomplie',
  reportee: 'Reportée',
  abandonnee: 'Abandonnée',
  bloquee: 'Bloquée',
};

/** Section 3 — the ordered priorities to review (05 §3.6.12 `RoutineStep`). */
interface ReviewPriority {
  id: string;
  title: string;
  /** The deviation tag (05 §3.6.12 l.1237–1239) : shown when out of plan. */
  tag?: string;
}

/** Section 4 — the next period's plan of action (each row can become a
 *  Task : the review GENERATES tasks, 05 §4.5.1 l.2388–2397). */
interface ReviewPlanStep {
  id: string;
  title: string;
  estimate: string;
}

interface Review {
  id: string;
  period: ReviewPeriod;
  status: ReviewStatus;
  cancelled?: string;
  bilan: ReviewBilanRow[];
  causes: string[];
  freeCause: string;
  priorities: ReviewPriority[];
  plan: ReviewPlanStep[];
  decisions: string;
}

const PERIOD_LABELS: Record<ReviewPeriod, string> = {
  jour: 'Jour',
  semaine: 'Semaine',
  mois: 'Mois',
};

/** The current period's label, DERIVED from today (AD-7 : one source of
 *  truth — the anchor is real data, never a fake window). */
function periodLabel(period: ReviewPeriod): string {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const fr = (d: Date) =>
    d.toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' });
  if (period === 'jour') return fr(today);
  if (period === 'semaine') {
    // ISO week (Monday start) — the study week of WDS 06.1.
    const day = (today.getDay() + 6) % 7; // 0 = Monday
    const monday = new Date(today);
    monday.setDate(today.getDate() - day);
    const sunday = new Date(monday);
    sunday.setDate(monday.getDate() + 6);
    return `${fr(monday)} – ${fr(sunday)}`;
  }
  // mois : the month's own range (the study month of WDS 06.2).
  const first = new Date(now.getFullYear(), now.getMonth(), 1);
  const last = new Date(now.getFullYear(), now.getMonth() + 1, 0);
  return `${fr(first)} – ${fr(last)} ${now.getFullYear()}`;
}

/** The three cause-Chips of section 2 (05 §4.5.1 l.2302–2310). */
const CAUSE_CHIPS = ['Charge', 'Fatigue', 'Blocage technique'];

/**
 * The local mirror (not wired yet, AD-7) — the screen ships an honest empty
 * state per period. When the review job wires, this becomes the pre-filled
 * Card (l.2368–2379 : bilan from `Task`, priorities from `Goal`).
 */
const REVIEWS: Review[] = [];

/**
 * The local « en retard » computation (OQ-4 close a, AD-7) : the previous
 * period's review is genuinely absent AND the previous period is past.
 * Absent by default (mirror not wired) — but the signal is a REAL,
 * derivable fact (the previous window), not an invented one, so the
 * Callout is honest: it says « no review recorded for the last period »,
 * which is exactly the truth when no mirror exists yet.
 */
function isLate(review: Review | undefined, period: ReviewPeriod): boolean {
  // The previous period's review does not exist in the local mirror yet →
  // for `semaine`/`mois` the prior window is genuinely unrevised.
  if (review?.status === 'faite') return false;
  if (review && review.status === 'a_faire') return false; // current, not late
  return period !== 'jour';
}

export function ReviewsPage() {
  // T4 ui-state (persisted per screen — the return finds the same period +
  // status, 05 §3.4 l.743–745 : non-surprise rule).
  const [period, setPeriod] = useState<ReviewPeriod>('semaine');
  const [status, setStatus] = useState<ReviewStatus>('a_faire');
  // Local write state (AD-7) : causes selected + free text, kept per review.
  const [selectedCauses, setSelectedCauses] = useState<string[]>([]);
  const [freeCause, setFreeCause] = useState('');
  const [decisions, setDecisions] = useState('');

  const review = REVIEWS.find((r) => r.period === period);
  const late = isLate(review, period);

  const toggleCause = (cause: string) =>
    setSelectedCauses((prev) =>
      prev.includes(cause) ? prev.filter((c) => c !== cause) : [...prev, cause],
    );

  const makeTaskIntent = (step: ReviewPlanStep) =>
    `/agent?intent=${encodeURIComponent(
      `Crée la tâche « ${step.title} » (estimation ${step.estimate}) — issue du plan d'action de ma revue.`,
    )}`;

  const createIntent = () =>
    `/agent?intent=${encodeURIComponent(
      `Faire ma revue ${PERIOD_LABELS[period].toLowerCase()} : pré-remplis le bilan des tâches, propose l'analyse des causes et le plan d'action. Je valide, tu ne décides pas à ma place.`,
    )}`;

  return (
    <>
      <IonHeader>
        <IonTitle>Revue</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-reviews className="reviews-page">
          <p className="page-purpose">
            Qu’est-ce qui s’est passé — et qu’est-ce que tu changes.
          </p>

          {/* The shared time Pager (05 §3.4 l.737–750) : period switch +
               the period's own line (JetBrains Mono, data — never animated).
               The switch is a LOCAL read (immediate, l.720–721). */}
          <div className="review-pager">
            <div
              className="segmented"
              role="tablist"
              aria-label="Période de la revue"
              data-reviews-pager
            >
              {(Object.keys(PERIOD_LABELS) as ReviewPeriod[]).map((p) => (
                <button
                  key={p}
                  type="button"
                  role="tab"
                  aria-selected={period === p}
                  className={period === p ? 'segmented-item active' : 'segmented-item'}
                  onClick={() => setPeriod(p)}
                >
                  {PERIOD_LABELS[p]}
                </button>
              ))}
            </div>
            <span className="review-pager-period" data-reviews-anchor>
              {periodLabel(period)}
            </span>
          </div>

          {/* The status switch — 2 segments ONLY (l.2249–2263) : the
               `Review` AD-15 `pending`/`completed`. A cancelled review is a
               historical `Callout info`, never a 3rd tab. */}
          <div
            className="segmented"
            role="tablist"
            aria-label="Statut de la revue"
            data-reviews-status
          >
            <button
              type="button"
              role="tab"
              aria-selected={status === 'a_faire'}
              className={status === 'a_faire' ? 'segmented-item active' : 'segmented-item'}
              onClick={() => setStatus('a_faire')}
            >
              À faire
            </button>
            <button
              type="button"
              role="tab"
              aria-selected={status === 'faite'}
              className={status === 'faite' ? 'segmented-item active' : 'segmented-item'}
              onClick={() => setStatus('faite')}
            >
              Faite
            </button>
          </div>

          {/* The late Callout (l.2323–2330) : LOCAL computation (OQ-4 close
               a, AD-7) — shown when the PREVIOUS period was not revised.
               It MUST carry its action (l.2380–2387) : the agent SUGGESTS
               an adjustment, the user DECIDES. */}
          {late && status === 'a_faire' && (
            <div className="aurora-callout aurora-callout--warning" role="note" data-reviews-late>
              <AlarmClock size={16} aria-hidden />
              <span>
                La revue {PERIOD_LABELS[period].toLowerCase()} précédente
                n’est pas faite — celle-ci est en retard.
              </span>
              <a className="aurora-callout-cta aurora-tap" href={createIntent()}>
                Suggérer un ajustement
              </a>
            </div>
          )}

          {review && review.status === 'faite' && (
            /* The « terminé » state (ui-libraries §6.1 l.198) : a
               Callout success posé — the review is closed, the plan is
               set (OQ-8 copy kept provisional, flagged). */
            <div className="aurora-callout aurora-callout--success" role="note">
              <Compass size={16} aria-hidden />
              <span>Revue bouclée — le plan d’action est posé.</span>
            </div>
          )}

          {review ? (
            /* The review = ONE Card posée (l.2264–2276) with its 5 sections
               (l.2277–2310). Pre-filled by the local mirror (here: honest
               empty fields, AD-7). */
            <div data-review-card className="review-card">
              {/* A cancelled review = historical Callout info (l.2256–2263). */}
              {review.cancelled && (
                <div className="aurora-callout aurora-callout--info" role="note">
                  <ClipboardList size={16} aria-hidden />
                  <span>{review.cancelled}</span>
                </div>
              )}

              {/* §1 — Bilan des tâches : the bounded, read-only recap table
                   (4 columns, < 20 rows → a semantic <table>, S8 l.304–307 ;
                   horizontal scroll on mobile, 05 §3.6.1 l.882–883). */}
              <section className="review-section" aria-label="Bilan des tâches">
                <h3 className="review-section-title">
                  Bilan des tâches <small>{review.bilan.length}</small>
                </h3>
                {review.bilan.length === 0 ? (
                  <div className="review-bilan-empty">Pas de tâches cette période.</div>
                ) : (
                  <div className="review-bilan">
                    <table>
                      <thead>
                        <tr>
                          <th>Statut</th>
                          <th>Titre</th>
                          <th>Projet</th>
                          <th>Pourquoi</th>
                        </tr>
                      </thead>
                      <tbody>
                        {review.bilan.map((row) => (
                          <tr key={row.id}>
                            <td>
                              <span className={`review-status review-status--${row.status === 'accomplie' ? 'done' : row.status === 'reportee' ? 'postponed' : 'blocked'}`}>
                                {STATUS_LABELS[row.status]}
                              </span>
                            </td>
                            <td>{row.title}</td>
                            <td>{row.project}</td>
                            <td className="review-bilan-why">{row.why}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </section>

              {/* §2 — Analyse des causes : the 3 cause-Chips (local write,
                   AD-7 — a tap is immediate, no network) + the free cause. */}
              <section className="review-section" aria-label="Analyse des causes">
                <h3 className="review-section-title">Analyse des causes</h3>
                <div className="review-causes" role="group" aria-label="Causes courantes">
                  {CAUSE_CHIPS.map((cause) => (
                    <button
                      key={cause}
                      type="button"
                      className={`review-cause-chip aurora-tap${selectedCauses.includes(cause) ? ' is-selected' : ''}`}
                      aria-pressed={selectedCauses.includes(cause)}
                      onClick={() => toggleCause(cause)}
                    >
                      {cause}
                    </button>
                  ))}
                </div>
                <div className="review-field">
                  <label htmlFor="review-cause">Autre cause (libre)</label>
                  <textarea
                    id="review-cause"
                    value={freeCause}
                    onChange={(e) => setFreeCause(e.target.value)}
                    placeholder="Ce qui a vraiment freiné la période…"
                  />
                </div>
              </section>

              {/* §3 — Révision des priorités (the ordered `RoutineStep`
                   list, l.2288–2291) : the number IS the order — no
                   re-sort (règle 1, 05 §2.6). */}
              <section className="review-section" aria-label="Révision des priorités">
                <h3 className="review-section-title">Révision des priorités</h3>
                <ol className="review-steps">
                  {review.priorities.map((p, i) => (
                    <li key={p.id} className="review-step">
                      <span className="review-step-num" aria-hidden>{i + 1}.</span>
                      <span className="review-step-title">{p.title}</span>
                      {p.tag && (
                        <span className="review-status review-status--postponed">{p.tag}</span>
                      )}
                    </li>
                  ))}
                </ol>
              </section>

              {/* §4 — Plan d'action suivant (l.2292–2294) : each step can
                   become a Task (l.2388–2397) — the ghost CTA is a LOCAL
                   write through the agent (AD-7/F-03). */}
              <section className="review-section" aria-label="Plan d'action suivant">
                <h3 className="review-section-title">Plan d’action suivant</h3>
                <ol className="review-steps">
                  {review.plan.map((step, i) => (
                    <li key={step.id} className="review-step">
                      <span className="review-step-num" aria-hidden>{i + 1}.</span>
                      <span className="review-step-title">{step.title}</span>
                      <span className="review-step-tag">{step.estimate}</span>
                      <a
                        className="review-step-cta aurora-tap"
                        href={makeTaskIntent(step)}
                        aria-label={`En faire une tâche : ${step.title}`}
                      >
                        En faire une tâche
                      </a>
                    </li>
                  ))}
                </ol>
              </section>

              {/* §5 — Journal des décisions (l.2295–2298) : free text,
                   `Decision` AD-15, sync server-wins. */}
              <section className="review-section" aria-label="Journal des décisions">
                <h3 className="review-section-title">Journal des décisions</h3>
                <div className="review-field">
                  <label htmlFor="review-decisions">Ce que tu as décidé, et pourquoi</label>
                  <textarea
                    id="review-decisions"
                    value={decisions}
                    onChange={(e) => setDecisions(e.target.value)}
                    placeholder="Une décision posée vaut mieux que dix intentions."
                  />
                </div>
              </section>
            </div>
          ) : (
            /* The honest EmptyState per period (l.2336–2347) : the CTA
               CREATES the object (05 §3.3 l.650) — through the agent, the
               single writer. Never a fake pre-filled Card. */
            <div data-reviews-empty className="reviews-empty-card">
              <ClipboardList size={28} aria-hidden className="reviews-empty-card-icon" />
              <p>Aucune revue {PERIOD_LABELS[period].toLowerCase()} pour l’instant.</p>
              <p className="reviews-hint">
                Cinq sections pré-remplies par tes données locales : bilan,
                causes, priorités, plan, journal. Tu ajustes — tu n’écris pas
                à blanc.
              </p>
              <a className="aurora-btn aurora-btn--primary aurora-tap" href={createIntent()}>
                Faire la revue
              </a>
            </div>
          )}

          {/* The screen's identity line : the Compass closes the loop
               Self-Improve → Adapt (ADR §19) — quiet, mono, never data. */}
          <div className="routines-meta" aria-hidden>
            <Compass size={13} />
            <span>{PERIOD_LABELS[period].toLowerCase()}</span>
          </div>
        </div>
      </IonContent>
    </>
  );
}
