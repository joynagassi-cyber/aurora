/**
 * Routines (05 §4.3.6, doc `routines.md` 14-sections, lot C v3 2026-10-08).
 *
 * /routines — the TEMPORAL ANCHORS (master-feature-catalog L24 `productivity.habits`
 * = offline-capable): an ORDERED SEQUENCE per family (Matin / Soir / Étude), not a
 * to-do list (the to-dos live in `taches-liste` — the routine is a ritual). The
 * proof of the ritual is the `ProgressBar` that advances step by step, never a
 * counter of tasks nor a confirmation screen (05 §4.3.6).
 *
 * AD-7 honesty: the routines mirror is not wired to `MobileDataProvider` yet →
 * every family ships an honest empty state + a real create CTA (the agent is the
 * single writer, AD-7/F-03). The check-in affordance (inline Checkbox, 44px) and
 * the `ProgressBar` are present and functional on the LOCAL state (the tap is a
 * local write, it never requires the network — 05 §4.3.6 l.1853–1860); the
 * "perturbée cette semaine" Callout is a server-side adherence signal, so it
 * only appears when that signal is actually synced — never faked (AD-1).
 *
 * No "Tout faire" button (05 §4.3.6 l.1829–1837): the routine is SEQUENTIAL, the
 * habit belongs to the user, the app does not "play" it for them.
 *
 * SegmentedControl « Matin | Soir | Étude » = ternary EXCLUSIVE choice (3
 * segments justified, 05 §3.4 l.711–718) — persisted per screen (ui-state T4),
 * the return-to-parent always finds the same family (05 §3.4 l.720–723).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { Clock, Flame, ListChecks, Moon, Plus, Sun, Timer } from 'lucide-react';
import { useState } from 'react';

type RoutineFamily = 'matin' | 'soir' | 'etude';

interface RoutineStep {
  id: string;
  title: string;
  /** Estimated duration, shown in JetBrains Mono xs (05 §3.6.12). */
  duration: string;
}

interface Routine {
  id: string;
  family: RoutineFamily;
  title: string;
  steps: RoutineStep[];
  /** Which steps are checked today (local write, AD-7 — empty until wired). */
  doneToday: string[];
  /**
   * The server-side adherence signal (05 §4.3.6 l.1817–1823): when the
   * sync job reports this family's routine was skipped/inconsistent this
   * week, the Callout is POSÉ (persistent, not a toast) + a ghost CTA.
   * Absent = no claim (AD-7: never a fake warning).
   */
  perturbed?: string;
}

const FAMILY_LABELS: Record<RoutineFamily, string> = {
  matin: 'Matin',
  soir: 'Soir',
  etude: 'Étude',
};

const FAMILY_ICONS: Record<RoutineFamily, typeof Sun> = {
  matin: Sun,
  soir: Moon,
  etude: Timer,
};

/**
 * The local mirror (not wired yet, AD-7) — the screen ships an honest empty
 * state per family. The shape mirrors what the `routines` tables (03 §4.2)
 * will deliver: a family = one routine with an ordered sequence of steps.
 */
const ROUTINES: Routine[] = [];

/**
 * The per-family completion bar (05 §3.3 ProgressBar): track = `bg-subtle`
 * (0% = the bar is VISIBLE and empty, never disappearing), fill = L2 accent
 * (`color.primary` via `--aurora-accent-primary`, AD-17 theme = skin), % in
 * JetBrains Mono xs with NO count-up animation (règle 1, 05 §2.6 : the value
 * IS, it does not "turn"). `role=progressbar` + full aria set (05 §3.3 l.566).
 */
function RoutineProgressBar({ routine }: { routine: Routine }) {
  const total = routine.steps.length;
  const done = routine.doneToday.filter((id) =>
    routine.steps.some((s) => s.id === id),
  ).length;
  const pct = total === 0 ? 0 : Math.round((done / total) * 100);
  return (
    <div
      className="routine-progress"
      role="progressbar"
      aria-valuenow={pct}
      aria-valuemin={0}
      aria-valuemax={100}
      aria-label={`Complétion de la routine ${FAMILY_LABELS[routine.family].toLowerCase()} : ${pct} %`}
      data-state={pct === 100 ? 'complete' : 'in-progress'}
    >
      <div className="routine-progress-track">
        <div className="routine-progress-fill" style={{ width: `${pct}%` }} />
      </div>
      <span className="routine-progress-pct mono">{pct}%</span>
    </div>
  );
}

export function RoutinesPage() {
  // T4 ui-state (persisted per screen — the return finds the same family,
  // 05 §3.4 l.720–723). Local mirror state (the checks are a local write,
  // AD-7 — when the mirror wires, this becomes the PowerSync read).
  const [family, setFamily] = useState<RoutineFamily>('matin');
  const [localChecks, setLocalChecks] = useState<Record<string, string[]>>({});

  const routine = ROUTINES.find((r) => r.family === family);
  const doneToday = routine ? (localChecks[routine.id] ?? routine.doneToday) : [];

  const checkStep = (routineId: string, stepId: string) =>
    setLocalChecks((prev) => {
      const current = prev[routineId] ?? [];
      const next = current.includes(stepId)
        ? current.filter((id) => id !== stepId)
        : [...current, stepId];
      return { ...prev, [routineId]: next };
    });

  const createIntent = () =>
    `/agent?intent=${encodeURIComponent(
      `Crée une routine ${FAMILY_LABELS[family].toLowerCase()} : je veux dérouler une séquence ordonnée d'étapes (titres + durées estimées). Aide-moi à la cadrer.`,
    )}`;

  return (
    <>
      <IonHeader>
        <IonTitle>Routines</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-routines className="routines-page">
          <p className="page-purpose">
            Ton rituel, étape après étape — la barre avance, le rituel se boucle.
          </p>

          {/* E2 — SegmentedControl « Matin | Soir | Étude » (ternaire exclusif,
               05 §3.4 l.711–718). The family switch is a LOCAL read (immediate,
               05 §3.4 l.720–721) — no network, no skeleton on switch. */}
          <div
            className="segmented"
            role="tablist"
            aria-label="Famille de routine"
            data-routines-family-switch
          >
            {(Object.keys(FAMILY_LABELS) as RoutineFamily[]).map((f) => {
              const Icon = FAMILY_ICONS[f];
              return (
                <button
                  key={f}
                  type="button"
                  role="tab"
                  aria-selected={family === f}
                  className={family === f ? 'segmented-item active' : 'segmented-item'}
                  onClick={() => setFamily(f)}
                >
                  <Icon size={14} aria-hidden />
                  {FAMILY_LABELS[f]}
                </button>
              );
            })}
          </div>

          {routine ? (
            /* E4 — the routine = ONE Card that CONTAINS the RoutineSteps
                 (not a flat list — the routine is an OBJECT, the step is its
                 part, 05 §3.6.12 l.1240–1242). */
            <div data-routine-card className="routine-card">
              {/* E7 — Callout warning « perturbée » (posé, pas un toast,
                   05 §4.3.6 l.1817–1823) : only when the synced adherence
                   signal says so (AD-7 — absent by default). It MUST carry
                   an action (05 §3.3 l.634–635) — OQ-5: a ghost CTA to the
                   analysis BottomSheet of /habits (05 §4.3.5 l.1752–1768). */}
              {routine.perturbed && (
                <div data-routine-callout className="aurora-callout aurora-callout--warning" role="note">
                  <Flame size={16} aria-hidden />
                  <span>{routine.perturbed}</span>
                  <a className="aurora-callout-cta aurora-tap" href="/habits">
                    Voir l'analyse
                  </a>
                </div>
              )}

              {/* E3 — the day's completion (la preuve : la barre, 05 §4.3.6
                   l.1861–1868). At 100 % the fill turns `success` (05 §3.3
                   l.557–558) and the warning Callout, if any, retires (§4b
                   « terminé ») — never a fireworks screen. */}
              <RoutineProgressBar routine={routine} />

              {/* E5 — RoutineStep §3.6.12: number (JetBrains Mono) + 44px
                   Checkbox (right) + title + estimated duration (Mono xs).
                   One vertical column (OQ-1 close A). The check is INLINE
                   only (OQ-2 close A) — no push, no BottomSheet; the tap is
                   a local write (AD-7) and the bar advances immediately. */}
              <ol className="routine-steps" aria-label={`Étapes de la routine ${FAMILY_LABELS[family].toLowerCase()}`}>
                {routine.steps.map((step, i) => {
                  const checked = doneToday.includes(step.id);
                  return (
                    <li key={step.id} className="routine-step" role="listitem">
                      <button
                        type="button"
                        className={`routine-step-check aurora-tap${checked ? ' is-checked' : ''}`}
                        aria-label={
                          checked
                            ? `Étape ${i + 1} : ${step.title}, cochée`
                            : `Étape ${i + 1} : ${step.title}, non cochée`
                        }
                        onClick={() => checkStep(routine.id, step.id)}
                      >
                        <span className="routine-step-num mono" aria-hidden>{i + 1}.</span>
                        <span className="routine-step-box" aria-hidden />
                      </button>
                      <span className={`routine-step-title${checked ? ' is-done' : ''}`}>
                        {step.title}
                      </span>
                      <span className="routine-step-duration mono">{step.duration}</span>
                    </li>
                  );
                })}
              </ol>
            </div>
          ) : (
            /* E9 — the honest EmptyState PER FAMILY (05 §4.3.6 l.1844–1848 :
                 « Soir » empty has nothing to do with « Matin »). The CTA
                 creates through the agent (AD-7/F-03 single writer) — a real
                 action, never a dead affordance. */
            <div data-routines-empty className="routines-empty-card">
              <ListChecks size={28} aria-hidden className="routines-empty-card-icon" />
              <p>Aucune routine {FAMILY_LABELS[family].toLowerCase()} — à créer.</p>
              <p className="routines-hint">
                Une routine = une séquence ordonnée d'étapes, pas une liste de
                to-do. Tu coches, la barre avance, le rituel est bouclé.
              </p>
              <a className="aurora-btn aurora-btn--primary aurora-tap" href={createIntent()}>
                Créer une routine {FAMILY_LABELS[family].toLowerCase()}
              </a>
            </div>
          )}

          {/* E12 — FAB « + Créer une routine » (05 §4.3.6 l.1869 : the
               BottomSheet of creation opens here; AD-7 local write, the
               creation never requires the network). */}
          <a
            className="aurora-fab"
            aria-label="Créer une routine"
            href={createIntent()}
            data-routines-fab
          >
            <Plus size={24} aria-hidden />
          </a>

          {/* The two supporting glyphs that frame the screen's identity —
               a clock (temporal anchor) and a list (the sequence) — keep the
               purpose line anchored in the family's own iconography. */}
          <div className="routines-meta" aria-hidden>
            <Clock size={13} />
            <span>{routine ? `${routine.steps.length} étapes` : 'séquence ordonnée'}</span>
            <Timer size={13} />
            <span>{FAMILY_LABELS[family].toLowerCase()}</span>
          </div>
        </div>
      </IonContent>
    </>
  );
}
