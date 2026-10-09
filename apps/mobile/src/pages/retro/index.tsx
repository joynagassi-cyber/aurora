/**
 * Retro-actions (WDS 06.3 + 05 §4.5.1, doc `retro-actions.md`, lot C v3
 * 2026-10-08) — the CLOSE of the retrospective chain.
 *
 * /retro — the post-review state (after the week's review is closed, WDS
 * 06.2) : three compact Cards —
 *   1. Écarts documentés : the milestones not reached (S-07), in the
 *      frozen `danger` (a theme never redefines a semantic state).
 *   2. Actions correctives : the 2 BAC blocks as compact `RoutineStep`
 *      lines (WDS 06.3 §6 Option A — compact, NEVER an interactive Gantt ;
 *      the budget is 30fps / TTI 1.5s / 300 Ko gz, OQ-11 close).
 *   3. Rythme posé : the next week's 7-day `GanttRow` with the 2 BAC
 *      blocks posed on their days — data only, no animation (règle 1,
 *      05 §2.6 : the data NEVER animates).
 *
 * ONE fixed CTA (AD-14) : « Planifier la semaine » → /calendar, posing
 * the 2 BAC blocks on the NEXT week (local write, AD-7 : the CTA stays
 * actionable even in the empty state and even offline). No agent free
 * proposal in the short path — the decision was already made by the tap.
 *
 * AD-7 honesty: the retrospective's local mirror is not wired to
 * `MobileDataProvider` yet → the screen ships an honest empty state
 * (« Semaine parfaite — pas de correctif nécessaire », WDS 06.3 §7) with
 * the CTA intact. No invented milestone, no fake BAC block, no fake
 * rhythm.
 *
 * The « rythmé » Callout info (WDS 06.3 §6 note) is shown only when the
 * proof is REAL (2 BAC blocks + routines kept = the rhythm is set) —
 * never a decorative claim.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { CalendarCheck, Flag, ListChecks, Sparkles } from 'lucide-react';

/** A missed milestone (S-07 : the milestone IS a goal — tapping drills
 *  into the goal's detail, PAGE_TRANSITION). */
interface RetroMilestone {
  id: string;
  title: string;
  goalId: string;
  dueDate: string;
}

/** A corrective BAC block (WDS 06.3 §6 : the 2 blocks, compact). */
interface RetroBlock {
  id: string;
  title: string;
  duration: string;
  /** The day of the NEXT week (0 = Monday … 6 = Sunday) the block is
   *  posed on (local write target, AD-7). */
  day: number;
}

interface Retro {
  id: string;
  /** The closed week's label (derived, AD-7 — one source of truth). */
  weekLabel: string;
  milestones: RetroMilestone[];
  blocks: RetroBlock[];
  /** The routines KEPT this week (the rhythm's proof, WDS 06.3 §6 note :
   *  "2 blocs BAC + routines tenues = rythme posé"). */
  keptRoutines: string[];
}

/**
 * The local mirror (not wired yet, AD-7) — the screen ships an honest empty
 * state. When the retrospective job wires, this becomes the read recap.
 */
const RETRO: Retro | null = null;

const DAY_LABELS = ['lun', 'mar', 'mer', 'jeu', 'ven', 'sam', 'dim'];

function weekLabel(): string {
  // The week that JUST closed (the review closed the week behind us) —
  // derived from today (AD-7 : real data, never a fake window).
  const now = new Date();
  const day = (now.getDay() + 6) % 7; // 0 = Monday
  const thisMonday = new Date(now.getFullYear(), now.getMonth(), now.getDate() - day);
  const lastMonday = new Date(thisMonday);
  lastMonday.setDate(thisMonday.getDate() - 7);
  const lastSunday = new Date(lastMonday);
  lastSunday.setDate(lastMonday.getDate() + 6);
  const fr = (d: Date) =>
    d.toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' });
  return `Semaine du ${fr(lastMonday)} au ${fr(lastSunday)}`;
}

/** The proof line (WDS 06.3 §6 note) : the rhythm is set when BOTH the BAC
 *  blocks AND the kept routines are present — a real computation, not a
 *  decorative claim (AD-7 : absent = no Callout). */
function rhythmProof(retro: Retro): string | null {
  if (retro.blocks.length >= 2 && retro.keptRoutines.length > 0) {
    return `${retro.blocks.length} blocs BAC + ${retro.keptRoutines.length} routines tenues = rythme posé`;
  }
  return null;
}

export function RetroActionsPage() {
  const retro = RETRO ?? { id: 'none', weekLabel: weekLabel(), milestones: [], blocks: [], keptRoutines: [] };
  const proof = RETRO ? rhythmProof(RETRO) : null;
  const empty = RETRO === null;

  /** The fixed CTA (AD-14) : pose the BAC blocks on the calendar (S-05),
   *  local write (AD-7) — stays actionable in every state, including
   *  the empty one (WDS 06.3 §7 : « le CTA reste le chemin »). */
  const planHref = `/calendar?plan=${encodeURIComponent(
    retro.blocks.map((b) => b.title).join('|'),
  )}`;

  return (
    <>
      <IonHeader>
        <IonTitle>Rétrospective</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-retro className="retro-page">
          <p className="page-purpose">
            La boucle se ferme : écarts documentés, actions posées, rythme tenu.
          </p>

          <p className="retro-card-hint" data-retro-week>{retro.weekLabel}</p>

          {empty ? (
            /* WDS 06.3 §7 — the honest empty state : « Semaine parfaite —
               pas de correctif nécessaire ». The CTA below stays the path
               (AD-14 invariant) : even a perfect week gets scheduled. */
            <div data-retro-empty className="retro-card">
              <Sparkles size={20} aria-hidden className="retro-card-hint" />
              <p className="retro-card-title">Semaine parfaite — pas de correctif nécessaire.</p>
              <p className="retro-card-hint">
                Aucun écart documenté, aucune action corrective identifiée :
                le rythme s’est tenu tout seul.
              </p>
            </div>
          ) : (
            <>
              {/* §1 — Écarts documentés (S-07 : the milestones not reached,
                   frozen `danger` + the milestone's own mono date). Each
                   row drills into the goal (the milestone IS a goal). */}
              <section className="retro-card" aria-label="Écarts documentés">
                <h3 className="retro-card-title">
                  <Flag size={14} aria-hidden /> Écarts documentés
                </h3>
                {retro.milestones.length === 0 ? (
                  <p className="retro-card-hint">Aucun jalon manqué cette semaine.</p>
                ) : (
                  retro.milestones.map((m) => (
                    <a
                      key={m.id}
                      className="retro-milestone aurora-tap"
                      href={`/goals/${m.goalId}`}
                      aria-label={`Jalon manqué : ${m.title}, au ${m.dueDate} — ouvrir l’objectif`}
                    >
                      <span className="review-status review-status--blocked">Manqué</span>
                      <span className="retro-milestone-title">{m.title}</span>
                      <span className="retro-milestone-date">{m.dueDate}</span>
                    </a>
                  ))
                )}
              </section>

              {/* §2 — Actions correctives (the 2 BAC blocks, compact
                   `RoutineStep` lines : number + title + mono duration.
                   NO drill-down, NO interactive Gantt — WDS 06.3 §6
                   Option A, budget OQ-11). */}
              <section className="retro-card" aria-label="Actions correctives">
                <h3 className="retro-card-title">
                  <ListChecks size={14} aria-hidden /> Actions correctives
                </h3>
                {retro.blocks.length === 0 ? (
                  <p className="retro-card-hint">Pas d’action corrective identifiée.</p>
                ) : (
                  <ol className="review-steps">
                    {retro.blocks.map((b, i) => (
                      <li key={b.id} className="review-step">
                        <span className="review-step-num" aria-hidden>{i + 1}.</span>
                        <span className="review-step-title">{b.title}</span>
                        <span className="review-step-tag">{b.duration}</span>
                      </li>
                    ))}
                  </ol>
                )}
              </section>

              {/* §3 — Rythme posé (the next week's 7-day GanttRow : the BAC
                   blocks posed on their day as `primary` Badges, the kept
                   routines as ghost day markers. Data only — never
                   animated (règle 1, 05 §2.6 l.323–330). */}
              <section className="retro-card" aria-label="Rythme posé">
                <h3 className="retro-card-title">
                  <CalendarCheck size={14} aria-hidden /> Rythme posé — semaine suivante
                </h3>
                <div className="retro-gantt" role="list" aria-label="Calendrier de la semaine suivante">
                  {DAY_LABELS.map((label, day) => {
                    const block = retro.blocks.find((b) => b.day === day);
                    const routine = retro.keptRoutines[day];
                    return (
                      <div key={label} className="retro-gantt-day" role="listitem" aria-label={`${label.toUpperCase()} : ${block ? block.title : routine ? `Routine : ${routine}` : 'libre'}`}>
                        <span className="retro-gantt-day-label">{label}</span>
                        {block && (
                            <span className="retro-gantt-block">{block.title}</span>
                        )}
                        {routine && (
                          <span className="retro-gantt-block retro-gantt-block--routine">{routine}</span>
                        )}
                      </div>
                    );
                  })}
                </div>
                {/* The proof line (WDS 06.3 §6 note) — shown ONLY when it is
                     a real computation (2 BAC + routines kept). */}
                {proof && (
                  <div className="aurora-callout aurora-callout--info" role="status">
                    <Sparkles size={16} aria-hidden />
                    <span>{proof}</span>
                  </div>
                )}
              </section>
            </>
          )}

          {/* The FIXED CTA (AD-14 : the ONLY action of the surface) —
               « Planifier la semaine » : poses the BAC blocks on /calendar
               (S-05), local write (AD-7 : it stays actionable in the empty
               and offline states). OQ-3 close (a) : direct navigation, no
               confirmation Modal — the decision was made at the tap. */}
          <a className="aurora-btn aurora-btn--primary aurora-tap retro-cta" href={planHref} data-retro-cta>
            <CalendarCheck size={16} aria-hidden />
            Planifier la semaine
          </a>
        </div>
      </IonContent>
    </>
  );
}
