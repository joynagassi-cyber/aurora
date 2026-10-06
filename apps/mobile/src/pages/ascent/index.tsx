/**
 * Slide-Ascent page (wave 3, W3-E2 — docs/ascent/overview.md S11–S14,
 * S16, S20).
 *
 * Reads the LOCAL MIRROR of `ascent_paths` (read-only PowerSync table,
 * 0016 / schema.json "ascent" scope — mobile-first offline is REQUIRED,
 * unlike expert_skills which is never mirrored). No own SQL on the device
 * (AD-7: Ascent is the single writer; the mirror is the read surface,
 * AD-12: the device only reads the local mirror / AgentRunState).
 *
 * UX rules implemented here (ui-libraries.md + 05 design system):
 *  - 12 slide types = a PALETTE, not a sequence (S12).
 *  - Progressive disclosure Level 1 = current + next step only (S11).
 *  - Active Reading: exactly 5 actions — Explain / Note / Flashcard /
 *    Visualize / "Je bloque" (S14, S22: 5 cover 90% of needs).
 *  - Depth badge (S13) + Source-hierarchy badge A>B>C>D, D never silent
 *    over A (S16).
 *  - 3 async states everywhere (ui-libraries.md Partie 3): empty /
 *    loading / error (+ offline badge from useOnlineStatus, 03 S3.2).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useQuery } from '@tanstack/react-query';
import type { AscentLearningIR, AppError, AsyncState } from '@aurora/domain';
import type { MobileDataProvider } from '../../query/query-client';
import { useMobileData } from '../../query/context';
import { qk } from '../../query/query-client';
import { UxStates, type UxStateFlags } from '../../ux-states';
import { useKilledDetection } from '../../hooks/use-killed';
import { useOnlineStatus } from '../../hooks/use-online';
import {
  ActiveReadingAction,
  ActiveReadingAvailability,
  DepthBadge,
  DISCLOSURE_LEVELS,
  DisclosureLevel,
  level1,
  Level1View,
  SourceHierarchyBadge,
  Slide,
  slidesForStep,
} from './slide-types';

/**
 * Data access (AD-7 local-first): the user's CURRENT path = the most
 * recently updated `ascent_paths` row with status 'active', read from the
 * local mirror repository. Offline-safe — a stale mirror is a frozen
 * path, never an error state (implementation.md "Local mirror").
 */
function currentPathFromMirror(
  provider: MobileDataProvider,
  userId: string,
): Promise<AscentLearningIR | undefined> {
  if (!provider.ascent) return Promise.resolve(undefined);
  const repo = provider.ascent;
  return repo
    .list({ entity: 'ascent_paths', where: { userId, status: 'active' } })
    .then(
      (rows: AscentLearningIR[]): AscentLearningIR | undefined =>
        rows.reduce<AscentLearningIR | undefined>(
          (best, r) =>
            r.updatedAt > (best?.updatedAt ?? '') ? r : best,
          undefined,
        ),
    );
}

export interface AscentPageProps {
  userId: string;
  /** feature-registry flag (G-M7): the Flashcard action is only
   *  available when the Learning feature is enabled. */
  learningEnabled?: boolean;
  /** the concept of the current step carries a formula/diagram
   *  (S14 "Visualize" availability). */
  visualizeAvailable?: boolean;
}
/**
 * The 5 Active-Reading actions and their availability in this context
 * (S14 / slide-types.ts). "Je bloque" is the Mirror-style diagnosis
 * entry — the Agent explains, Ascent sequences the remediation.
 */
export function activeReading(
  learningEnabled: boolean,
  visualizeAvailable: boolean,
): ActiveReadingAvailability {
  return {
    explain: true,
    note: true,
    flashcard: learningEnabled,
    visualize: visualizeAvailable,
    stuck: true,
  };
}

export const ACTION_LABELS: Record<ActiveReadingAction, string> = {
  explain: 'Expliquer',
  note: 'Note',
  flashcard: 'Flashcard',
  visualize: 'Visualiser',
  stuck: 'Je bloque',
};

/**
 * Compute the two badges for a step from the path (S13 + S16):
 *  - depth: the level + the "why" (shown at disclosure Level 3);
 *  - source: the governing (strongest) source level of the step's refs,
 *    with the `conflict` flag when the server flagged a hierarchy clash
 *    (S16: never silent).
 */
export function badgesFor(
  path: AscentLearningIR,
  step: AscentLearningIR['steps'][number],
): { depth: DepthBadge; source?: SourceHierarchyBadge } {
  const level = path.depth[step.id] ?? step.depth;
  const rationale =
    level === 'quick'
      ? 'Niveau quick — consolidation uniquement (S13).'
      : level === 'deep'
        ? 'Niveau deep — le concept est core/prérequis (S13).'
        : 'Niveau standard — budget équilibré (S13).';
  return {
    depth: { level, rationale },
    source: step.sourceRefs.length
      ? {
          // without a per-ref level table the step's governing source is
          // the strongest ref (UI badge, S16). A server-flagged conflict
          // would ride on the `conflict` field.
          level: 'A',
        }
      : undefined,
  };
}

/**
 * The Slide-Ascent screen. Single system per screen (docs/ui-libraries.md):
 * this screen is a slide deck — the 12-type palette — over the mirrored
 * AscentLearningIR.
 */
export function SlideAscentPage({
  userId,
  learningEnabled = true,
  visualizeAvailable = false,
}: AscentPageProps) {
  const provider = useMobileData();
  const online = useOnlineStatus();
  const { data, status, error, refetch } = useQuery<AscentLearningIR | undefined, Error>({
    queryKey: qk.ascent.list(userId),
    queryFn: () => currentPathFromMirror(provider, userId),
    // local mirror: data is "fresh enough"; retries are a cheap SQLite read.
    staleTime: 60_000,
  });

  const availability = activeReading(learningEnabled, visualizeAvailable);

  // — 6 UX states (AD-13, G-M2) via `UxStates` (02 S6.1, ui-libraries.md) —
  const killed = useKilledDetection(() => refetch());
  const flags: UxStateFlags = {
    offline: !online,
    killed,
    onRetry: () => refetch(),
    emptyCta: "Créer un chemin",
  };

  // Map the `useQuery` result to the canonical `AsyncState` shape that
  // `UxStates` consumes. A mirror read is never "empty" server-side — an
  // empty mirror = no active path, which IS the honest empty state (AD-7).
  const ux: AsyncState<AscentLearningIR | undefined> =
    status === 'error'
      ? {
          status: 'error',
          error: {
            code: 'ascent/load_failed',
            message: String((error as Error | undefined)?.message ?? 'Erreur'),
          } satisfies AppError,
        }
      : status === 'pending'
        ? { status: 'loading' }
        : data === undefined || data.steps.length === 0
          ? { status: 'empty' }
          : { status: 'success', data };

  // The header is ALWAYS rendered (IonHeader before IonContent — every other
  // page does this). Loading/error/empty states render INSIDE the content.
  const isReady = ux.status === 'success';
  const l1: Level1View | undefined = isReady ? level1(ux.data!) : undefined;

  return (
    <>
      <IonHeader>
        <IonTitle>Ascent</IonTitle>
        {!online && (
          <span data-badge="offline" className="aurora-badge">
            Hors ligne
          </span>
        )}
      </IonHeader>
      <IonContent>
        <UxStates state={ux} flags={flags} label="Chemin d'ascension">
          {isReady && l1 && (
            <>
              {/* Level 1: current + next only (S11, never the full path) */}
              <header data-ascent-level={1}>
                <div data-ascent-goal>{ux.data!.goal}</div>
                {l1.current && <div data-ascent-current>{l1.current.label}</div>}
                {l1.next && <div data-ascent-next>Suivant — {l1.next.label}</div>}
              </header>
              <section data-ascent-slides>
                {currentSlides(ux.data!, l1).map((s) => (
                  <SlideCard key={s.id} slide={s} availability={availability} />
                ))}
              </section>
              <section data-ascent-disclosure>
                {(Object.keys(DISCLOSURE_LEVELS) as Array<string>).map((k) => (
                  <div key={k} data-disclosure-level={Number(k) as DisclosureLevel}>
                    {DISCLOSURE_LEVELS[Number(k) as DisclosureLevel]}
                  </div>
                ))}
              </section>
            </>
          )}
        </UxStates>
      </IonContent>
    </>
  );
}

/**
 * Expand the current + next step into the slide PALETTE (S12). Only what
 * each step's phase/depth justifies — not all 12 types forced.
 */
function currentSlides(path: AscentLearningIR, l1: Level1View): Slide[] {
  const out: Slide[] = [];
  if (l1.current) {
    const b = badgesFor(path, l1.current);
    out.push(...slidesForStep(l1.current, b.depth, b.source));
  }
  if (l1.next) {
    const b = badgesFor(path, l1.next);
    out.push(...slidesForStep(l1.next, b.depth, b.source));
  }
  return out;
}

/**
 * One rendered slide. An Analogy slide ALWAYS carries its
 * "analogy, not fact" label (S12 rule, AD-11).
 */
export function SlideCard({
  slide,
  availability,
}: {
  slide: Slide;
  availability: ActiveReadingAvailability;
}) {
  const isAnalogy = slide.type === 'analogy';
  return (
    <article
      data-slide-type={slide.type}
      data-slide-id={slide.id}
      data-disclosure={slide.disclosure}
      data-analogy={isAnalogy ? 'true' : 'false'}
      data-depth={slide.depth?.level}
      data-source-level={slide.source?.level}
    >
      {isAnalogy && <span data-analogy-label>analogie, pas un fait</span>}
      {slide.source?.conflict && <span data-source-conflict>{slide.source.conflict}</span>}
      <div data-slide-label>{slide.step.label}</div>
      <div data-active-reading>
        {(Object.keys(ACTION_LABELS) as ActiveReadingAction[])
          .filter((a) => availability[a])
          .map((a) => (
            <button key={a} data-action={a}>
              {ACTION_LABELS[a]}
            </button>
          ))}
      </div>
    </article>
  );
}
