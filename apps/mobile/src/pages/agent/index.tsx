/**
 * Agent conversation (02 §6.1, F-09: the device sees ONLY AgentRunState).
 *
 * /agent — the conversation surface. The premium chrome: a calm transcript +
 * a pinned composer. Submitting an intention ENQUEUES a kernel run
 * (`fn-agent-run`, AD-12/F-09): the kernel executes server-side and the
 * device follows its `agent_runs` mirror (AD-7 local read, 3 s cadence
 * while running; terminal statuses stop the poll). No provider stream
 * crosses the device (F-09/AD-3).
 *
 * The thinking organism (§9.3) renders while a run is in flight; the
 * honest empty states (AD-7/AD-13): agent unavailable → "agent
 * indisponible", absent mirror row → still pending, `failed` → degraded
 * notice (never a silent acceptance, kernel §8).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { Send } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import { useMobileData } from '../../query/context';
import { useAgentRun } from '../../query/agent-runs';
import type { AgentRunRow } from '../../lib/agent-client';

/** One transcript entry (device surface state — AD-7, local only). */
interface Entry {
  id: string;
  role: 'user' | 'agent';
  body: string;
  /** run id for agent entries (the `agent_runs` row they belong to). */
  runId?: string;
}

function statusLine(row: AgentRunRow | null): string {
  if (!row) return 'run lancé côté serveur — en attente du job…';
  switch (row.status) {
    case 'running':
      return row.confirmationMessage
        ? 'confirmation attendue : « ' + row.confirmationMessage + ' »'
        : 'run en cours…';
    case 'completed':
      return 'task accomplie — les modules propriétaires ont appliqué les mutations (AD-7)';
    case 'failed':
      return 'run en échec — résultat dégradé signalé, rien n’a été appliqué en silence (kernel §8)';
    case 'cancelled':
      return 'run annulé';
  }
}

export function AgentPage() {
  const { agent } = useMobileData();
  const [draft, setDraft] = useState('');
  const [entries, setEntries] = useState<Entry[]>([]);
  const [activeRun, setActiveRun] = useState<string | undefined>(undefined);
  const transcriptRef = useRef<HTMLDivElement>(null);
  const entrySeq = useRef(0);

  const { data: runRow, isFetching } = useAgentRun(activeRun);
  const thinking = activeRun !== undefined && !runRow;

  function push(e: Omit<Entry, 'id'>) {
    entrySeq.current += 1;
    const id = `e${entrySeq.current}`;
    setEntries((prev) => [...prev, { ...e, id }]);
    requestAnimationFrame(() => {
      transcriptRef.current?.scrollTo({ top: transcriptRef.current.scrollHeight, behavior: 'smooth' });
    });
  }

  // A terminal mirror row is promoted into the transcript ONCE, then the
  // run id is cleared (honest history, AD-7: nothing faked — the row text
  // is a projection of the server state, never an invention).
  useEffect(() => {
    if (!runRow || activeRun !== runRow.id) return;
    const terminal =
      runRow.status === 'completed' || runRow.status === 'failed' || runRow.status === 'cancelled';
    if (!terminal) return;
    const id = `term:${runRow.id}`;
    setEntries((prev) =>
      prev.some((e) => e.id === id)
        ? prev
        : [...prev, { id, role: 'agent', body: statusLine(runRow), runId: runRow.id }],
    );
    setActiveRun(undefined);
  }, [runRow, activeRun]);

  useEffect(() => {
    if (runRow && activeRun && runRow.id === activeRun) {
      // Live status line under the thinking organism (rendered inline).
      requestAnimationFrame(() => {
        transcriptRef.current?.scrollTo({ top: transcriptRef.current.scrollHeight });
      });
    }
  }, [runRow, activeRun]);

  async function submit() {
    const intent = draft.trim();
    if (!intent || !agent || thinking) return;
    setDraft('');
    push({ role: 'user', body: intent });
    try {
      const handle = await agent.start({ intent });
      // F-09 SSoT: the device follows the `agent_runs` mirror row by its
      // uuid PK (`handle.traceId`), NOT the kernel's ULID agentRunId
      // (that lives in agent_runs.trace_id, never the uuid id column).
      setActiveRun(handle.traceId);
    } catch {
      // Enqueue failed (secrets missing → 503, network): the intent stays
      // visible, the run never started — honest error state, no fake run.
      push({
        role: 'agent',
        body: 'Lancement du run impossible (agent indisponible côté serveur). Vérifie ta connexion et relance.',
      });
    }
  }

  const inFlightRow = activeRun && runRow && runRow.id === activeRun ? runRow : null;

  return (
    <>
      <IonHeader>
        <IonTitle>Aurora</IonTitle>
      </IonHeader>
      <IonContent>
        <div className="agent-chat">
          <div
            ref={transcriptRef}
            className="agent-transcript"
            data-state={
              agent ? (entries.length || inFlightRow ? 'streaming' : thinking ? 'loading' : 'empty') : 'offline'
            }
          >
            {!agent && (
              <div className="agent-empty">
                <p>
                  L'agent est indisponible — l'environnement serveur (OQ-03) n'est pas configuré. Les
                  intentions reprendront dès que la clé de publication est injectée.
                </p>
              </div>
            )}

            {agent && entries.length === 0 && !thinking && !inFlightRow && (
              <div className="agent-empty">
                <p>Commence par une intention — « aie-moi à … ».</p>
              </div>
            )}

            {entries.map((e) => (
              <div key={e.id} className={`agent-entry agent-entry--${e.role}`}>
                <div className="agent-entry-body">{e.body}</div>
              </div>
            ))}

            {thinking && (
              <div className="agent-thinking">
                <div className="agent-thinking-blobs" aria-hidden />
                <span className="agent-thinking-label">L'agent réfléchit…</span>
              </div>
            )}

            {inFlightRow && (
              <div className="agent-entry agent-entry--agent">
                <div className={`agent-entry-status ${inFlightRow.confirmationMessage ? 'is-attention' : ''}`}>
                  {statusLine(inFlightRow)}
                </div>
              </div>
            )}
          </div>

          <form
            className="agent-composer"
            onSubmit={(e) => {
              e.preventDefault();
              void submit();
            }}
          >
            <input
              value={draft}
              onChange={(e) => setDraft(e.target.value)}
              placeholder="Écris ton intention…"
              aria-label="Écrire à l'agent"
              disabled={!agent || isFetching}
            />
            <button
              type="submit"
              disabled={!agent || draft.trim().length === 0 || thinking}
              aria-label="Envoyer"
            >
              <Send size={18} />
            </button>
          </form>
        </div>
      </IonContent>
    </>
  );
}
