/**
 * Conversations list (PRD-AI-01, 10-08 — lot PRD-3 agent).
 *
 * /agent/conversations — « Retrouver, regrouper des conversations » :
 * the device-side view of the user's AGENT RUNS (`agent_runs`, 0008) :
 * each run = one intent + its status. Read-only surface — the device
 * NEVER writes `agent_runs` (kernel-owned, AD-2/F-03 single-writer) :
 * the PRD's « suppression groupée » is PARKED (it needs the kernel's
 * delete command, not a UI-side row delete). No dead controls : rows
 * are records, not buttons.
 *
 * Data : `useAgentRuns()` (publishable client, RLS user isolation,
 * antéchronologique, 50 most recent). Honest AD-13 states :
 *   loading → skeleton · error → message + Réessayer · empty →
 *   « Aucune conversation » + CTA (Nouvelle conversation) ·
 *   offline → badge + last-known · killed → Reconnexion….
 */
import { IonButton, IonButtons, IonContent, IonHeader, IonTitle } from '@ionic/react';
import { ArrowLeft, Bot, Search } from 'lucide-react';
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { UxStates, type UxStateFlags } from '../../ux-states';
import { useOnlineStatus } from '../../hooks/use-online';
import { useUiStateStore } from '../../state/ui-state';
import { useAgentRuns } from '../../query/agent-runs';
import type { AgentRunRow } from '../../query/agent-runs';
import { useMobileData } from '../../query/context';
import type { AsyncState, AppError } from '@aurora/domain';

/** Relative/absolute date, plain French (jargon jamais visible). */
function runDate(row: AgentRunRow, now: number): string {
  const t = row.completedAt ? Date.parse(row.completedAt) : Date.parse(row.startedAt);
  if (Number.isNaN(t)) return '';
  const diffMs = now - t;
  if (diffMs < 60_000) return "à l'instant";
  if (diffMs < 3_600_000) return `il y a ${Math.max(1, Math.round(diffMs / 60_000))} min`;
  if (diffMs < 86_400_000) return `il y a ${Math.round(diffMs / 3_600_000)} h`;
  if (diffMs < 7 * 86_400_000) return `il y a ${Math.round(diffMs / 86_400_000)} j`;
  return new Date(t).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' });
}

const STATUS_LABEL: Record<AgentRunRow['status'], string> = {
  running: 'En cours',
  completed: 'Terminé',
  failed: 'Échoué',
  cancelled: 'Annulé',
};

export function AgentConversationsPage() {
  const navigate = useNavigate();
  const online = useOnlineStatus();
  const killed = useUiStateStore((s) => s.killed);
  const { agent } = useMobileData();
  const [query, setQuery] = useState('');
  const { data, isFetching, isError, refetch } = useAgentRuns();

  const now = Date.now();
  // PRD-AI-01 « Recherche plein texte » — client-side filter on the
  // 50 most recent intents (the transcript full-text is server-side,
  // not synced to the device — AD-7 honest scope note in the empty
  // state copy).
  const rows =
    data && query.trim()
      ? data.filter((r) => r.intent.toLowerCase().includes(query.trim().toLowerCase()))
      : data;

  // No client (not signed in) = the empty CTA routes to SIGN IN (a real
  // action, AD-7) ; with a client it opens a new conversation.
  const flags: UxStateFlags = agent
    ? {
        offline: !online,
        killed,
        onRetry: () => {
          void refetch();
        },
        emptyCta: 'Nouvelle conversation',
        emptyCtaHref: '/agent',
      }
    : {
        offline: !online,
        killed,
        emptyCta: 'Se connecter',
        emptyCtaHref: '/login',
      };

  const error: AppError = {
    code: 'agent_runs.load_failed',
    message: 'Impossible de charger tes conversations.',
    retryable: true,
  };
  // AD-13 honest states (6) : the `agent` client is present only when the
  // shell has Supabase env — absent = the sign-in empty CTA (never a
  // perpetual loading). The query is disabled when absent (data stays
  // undefined), so the `!agent` branch must come BEFORE the loading one.
  const state: AsyncState<AgentRunRow[]> =
    isError
      ? { status: 'error', error }
      : !agent
        ? { status: 'empty' }
        : !data || (isFetching && data === undefined)
          ? { status: 'loading' }
          : rows?.length === 0
            ? { status: 'empty' }
            : { status: 'success', data: rows };

  return (
    <>
      <IonHeader>
        <IonButtons slot="start">
          <IonButton fill="clear" onClick={() => navigate('/agent')} aria-label="Retour à l'assistant">
            <ArrowLeft size={18} />
          </IonButton>
        </IonButtons>
        <IonTitle>Conversations</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-state={String(state.status)} data-conversations>
          {/* SearchPill (PRD-AI-01 : « Champ Rechercher »). */}
          <div className="agent-convo-search">
            <Search size={14} aria-hidden />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Rechercher dans mes conversations"
              aria-label="Rechercher dans mes conversations"
              disabled={state.status !== 'success' && state.status !== 'loading'}
            />
          </div>

          <UxStates state={state} flags={flags} label="Conversations">
            {state.status === 'success' && rows && (
              <div data-convo-list>
                {rows.map((row) => (
                  <div
                    key={row.id}
                    className={`agent-convo-row agent-convo-row--${row.status}`}
                    data-convo-id={row.id}
                  >
                    <span className="agent-convo-icon" aria-hidden>
                      <Bot size={16} />
                    </span>
                    <span className="agent-convo-text">
                      <span className="agent-convo-title">{row.intent}</span>
                      <span className="agent-convo-date">
                        {runDate(row, now)} · {STATUS_LABEL[row.status]}
                      </span>
                    </span>
                    <span className={`agent-convo-status agent-convo-status--${row.status}`}>
                      {STATUS_LABEL[row.status]}
                    </span>
                  </div>
                ))}
                <p className="page-hint agent-convo-hint">
                  Les 50 conversations les plus récentes — la recherche
                  porte sur les titres de tes demandes.
                </p>
              </div>
            )}
          </UxStates>
        </div>
      </IonContent>
    </>
  );
}
