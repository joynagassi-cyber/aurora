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
 *
 * Model picker (AD-3 public config): the device can pin a provider/model
 * before the run; AD-5 fallback still applies server-side on 429/error.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { Bot, Cpu, Send, Sparkles } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import { useMobileData } from '../../query/context';
import { useAgentRun } from '../../query/agent-runs';
import type { AgentRunRow } from '../../lib/agent-client';

// ——— Model picker catalog (AD-3: static, public config — no key here). ———
// Mirrors `PROVIDER_MODEL_CATALOG` in fn-agent-bootstrap.ts; the kernel
// enforces the actual availability server-side (no key → provider hidden).
const MODEL_CATALOG: Array<{ provider: string; name: string; models: string[] }> = [
  { provider: 'agnes', name: 'Agnes', models: ['agnes-3.0', 'agnes-2.5-flash'] },
  { provider: 'workers-ai', name: 'Cloudflare Workers AI', models: ['glm-4.7-flash', 'gemma-4-26b', 'nemotron-3-super-120b'] },
  { provider: 'groq', name: 'Groq', models: ['gpt-oss-120b', 'gpt-oss-20b'] },
  { provider: 'openrouter', name: 'OpenRouter', models: ['nemotron-3-ultra', 'gemma-4'] },
];

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
  const [modelChoice, setModelChoice] = useState<{ provider: string; model: string } | null>(null);
  const [showPicker, setShowPicker] = useState(false);
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
      const handle = await agent.start({
        intent,
        taskProfile: modelChoice
          ? { preferredProvider: modelChoice.provider, preferredModel: modelChoice.model }
          : undefined,
      });
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
            {/* Model picker trigger — AD-3 public config; AD-5 fallback is
                enforced server-side on 429/error. */}
            <button
              type="button"
              className="agent-model-picker-trigger"
              onClick={() => setShowPicker(true)}
              aria-label="Choisir le modèle"
              disabled={!agent || thinking}
            >
              {modelChoice ? (
                <span className="agent-model-picker-label">
                  <Cpu size={12} aria-hidden />
                  {modelChoice.model}
                </span>
              ) : (
                <span className="agent-model-picker-label">
                  <Sparkles size={12} aria-hidden />
                  Auto
                </span>
              )}
            </button>

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

          {showPicker && (
            <div className="agent-model-picker-modal" role="dialog" aria-label="Choix du modèle">
              <div className="agent-model-picker-header">
                <Bot size={16} aria-hidden />
                <h3>Choix du modèle</h3>
                <button
                  type="button"
                  className="agent-model-picker-close"
                  onClick={() => setShowPicker(false)}
                  aria-label="Fermer"
                >
                  ×
                </button>
              </div>
              <div className="agent-model-picker-body">
                {/* Auto = the S2.6 router picks automatically */}
                <button
                  type="button"
                  className={`agent-model-picker-option ${!modelChoice ? 'is-active' : ''}`}
                  onClick={() => {
                    setModelChoice(null);
                    setShowPicker(false);
                  }}
                >
                  <Sparkles size={14} aria-hidden />
                  <span>Auto — le router choisit (recommandé)</span>
                </button>

                {MODEL_CATALOG.map((entry) => (
                  <div key={entry.provider} className="agent-model-picker-group">
                    <div className="agent-model-picker-group-label">{entry.name}</div>
                    {entry.models.map((m) => (
                      <button
                        key={m}
                        type="button"
                        className={`agent-model-picker-option ${
                          modelChoice?.provider === entry.provider && modelChoice.model === m
                            ? 'is-active'
                            : ''
                        }`}
                        onClick={() => {
                          setModelChoice({ provider: entry.provider, model: m });
                          setShowPicker(false);
                        }}
                      >
                        <Cpu size={14} aria-hidden />
                        <span>{m}</span>
                      </button>
                    ))}
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </IonContent>
    </>
  );
}
