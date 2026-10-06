/**
 * 5 UX states + killed (AD-13, G-M2 — ui-libraries.md S6).
 *
 * Every async component MUST handle all 6 states:
 *   loading  -> Skeleton shimmer (shadcn Skeleton + Framer Motion GPU pulse)
 *   error    -> Alert destructive (red border + message + retry)
 *   empty    -> Card empty variant (icon + text + CTA "Demande à Aurora")
 *   success  -> Toast (auto-dismiss 3s) — wave-N (a toaster was planned and
 *               later removed as dead code, Q4 2026-10-05); no consumer
 *               currently surfaces a success toast.
 *   offline  -> Badge in the top bar + last-known data
 *   killed   -> Skeleton + auto-resync ("Reconnexion…" + shimmer, 04 S6.1:
 *                kill = taskbar swipe, no reliable signal; return-to-boot
 *                = RE-READ the local store (AD-7), re-hydrate ui-state).
 *
 * These are presentation-only blocks that consume the canonical
 * `AsyncState<T>` (packages/domain/envelopes) + the app-lifecycle flags
 * from P5's AppLifecycleAdapter. P4 installs the shadcn components;
 * this file wires their state semantics now so no async screen ships
 * without the full set (02 S11 gate: "No async component may be
 * missing any of these 6 states").
 */
import type { AsyncState, AppError } from '@aurora/domain';
import type { ReactNode } from 'react';
import { Skeleton } from '@aurora/ui';

export type UxStateName = 'loading' | 'empty' | 'success' | 'error' | 'offline' | 'killed';

/** The minimal state a data-driven screen must report (page matrix PERSIST/EMPTY). */
export interface UxStateFlags {
  /** 5th canonical state (03 S3.2): network down — render last-known data. */
  offline: boolean;
  /** G-M2: app was force-killed — re-hydrate from local store on open. */
  killed: boolean;
  /** retry handler for the `error` state (idempotent — local re-read). */
  onRetry?: () => void;
  /** CTA for the `empty` state — defaults to "Demande à Aurora" (agent). */
  emptyCta?: string;
  /**
   * Where the empty-state CTA routes (e.g. "/agent?intent=…"). Rendered as
   * an `<a>`; when absent the CTA is a plain button (no navigation).
   */
  emptyCtaHref?: string;
  /** Where the error-state "Réessayer" / "Voir le rapport" affordances route. */
  errorHref?: string;
}

/** Pick the single state to render from an AsyncState + flags. */
export function resolveUxState<T>(state: AsyncState<T>, flags: UxStateFlags): UxStateName {
  // precedence: killed > offline > (query states)
  if (flags.killed) return 'killed';
  if (flags.offline) return 'offline';
  switch (state.status) {
    case 'loading':
      return 'loading';
    case 'empty':
      return 'empty';
    case 'error':
      return 'error';
    case 'success':
      return 'success';
    default:
      return 'loading';
  }
}

/**
 * `UxStates` — the 6-state block. Consumed by every async screen.
 * `killed` renders a skeleton + "Reconnexion…" + shimmer, and auto-resyncs
 * (04 S6.1): the screen re-reads the local store (AD-7), then falls back
 * to `loading`/`empty`/`error`/`success` as usual.
 */
export function UxStates({
  state,
  flags,
  children,
  label,
}: {
  state: AsyncState<unknown>;
  flags: UxStateFlags;
  children?: ReactNode;
  /** accessible label for the loading/error skeleton (a11y). */
  label?: string;
}): ReactNode {
  const which = resolveUxState(state, flags);
  switch (which) {
    case 'loading':
      return (
        <div data-ux="loading" role="status" aria-label={label} className="aurora-skeleton-stack">
          <Skeleton className="h-4 w-full" />
          <Skeleton className="h-4 w-3/4" />
          <Skeleton className="h-4 w-1/2" />
        </div>
      );
    case 'killed':
      return (
        <div data-ux="killed" role="status" aria-label={label ?? 'Reconnexion…'} className="aurora-skeleton-stack">
          <Skeleton className="h-4 w-full" />
          <Skeleton className="h-4 w-2/3" />
          <p>Reconnexion…</p>
        </div>
      );
    case 'offline':
      return (
        <div data-ux="offline" data-badged="true">
          <span className="aurora-badge">Hors ligne</span>
          <div data-last-known="true">{children}</div>
        </div>
      );
    case 'empty':
      return (
        <div data-ux="empty">
          <p>Aucune donnée</p>
          {flags.emptyCtaHref ? (
            <a
              type="button"
              data-cta="agent"
              href={flags.emptyCtaHref}
              className="aurora-btn aurora-btn--primary aurora-tap"
            >
              {flags.emptyCta ?? 'Demande à Aurora'}
            </a>
          ) : (
            <button
              type="button"
              data-cta="agent"
              className="aurora-btn aurora-btn--primary aurora-tap"
            >
              {flags.emptyCta ?? 'Demande à Aurora'}
            </button>
          )}
        </div>
      );
    case 'error': {
      const err = (state as { error: AppError }).error;
      return (
        <div data-ux="error" role="alert">
          <p>{err?.message ?? 'Erreur'}</p>
          {flags.onRetry && (
            <button
              type="button"
              onClick={flags.onRetry}
              className="aurora-btn aurora-btn--ghost aurora-tap"
            >
              Réessayer
            </button>
          )}
          {flags.errorHref && (
            <a
              href={flags.errorHref}
              className="aurora-btn aurora-btn--ghost aurora-tap"
            >
              Voir le rapport
            </a>
          )}
        </div>
      );
    }
    case 'success':
      // success = data rendered; the toast (auto-dismiss) is raised by the
      // caller via the toaster (P4 shadcn), NOT by this block.
      return <div data-ux="success">{children}</div>;
  }
}
