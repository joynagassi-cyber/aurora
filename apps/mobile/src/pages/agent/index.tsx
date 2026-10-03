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
 * The composer's `+` button opens a bottom sheet with:
 *  - Add files / Add connect (Composio: Google Workspace by default)
 *  - Skills marketplace (browse ClawHub / create personal skill)
 *  - Research mode (standard / deep)
 *  - Thinking level (low / medium / high / max)
 *
 * Agent modes: chat | agent (autonomous) | mirror (teach the AI).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import {
  Bot,
  Brain,
  Cpu,
  FilePlus,
  Link2,
  Plus,
  Search,
  Send,
  Sparkles,
  Zap,
} from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import { useMobileData } from '../../query/context';
import { useAgentRun } from '../../query/agent-runs';
import type { AgentRunRow } from '../../lib/agent-client';

// ——— Model picker catalog (AD-3: static, public config — no key here). ———
const MODEL_CATALOG: Array<{ provider: string; name: string; models: string[] }> = [
  { provider: 'agnes', name: 'Agnes', models: ['agnes-3.0', 'agnes-2.5-flash'] },
  { provider: 'workers-ai', name: 'Cloudflare Workers AI', models: ['glm-4.7-flash', 'gemma-4-26b', 'nemotron-3-super-120b'] },
  { provider: 'groq', name: 'Groq', models: ['gpt-oss-120b', 'gpt-oss-20b'] },
  { provider: 'openrouter', name: 'OpenRouter', models: ['nemotron-3-ultra', 'gemma-4'] },
];

// ——— Agent modes (kernel §4) ———
type AgentMode = 'chat' | 'agent' | 'mirror';
const AGENT_MODES: Array<{ id: AgentMode; label: string; icon: React.ReactNode }> = [
  { id: 'chat', label: 'Chat', icon: <Bot size={12} /> },
  { id: 'agent', label: 'Agent', icon: <Zap size={12} /> },
  { id: 'mirror', label: 'Miroir', icon: <Brain size={12} /> },
];

// ——— Thinking levels ———
type ThinkingLevel = 'low' | 'medium' | 'high' | 'max';
const THINKING_LEVELS: ThinkingLevel[] = ['low', 'medium', 'high', 'max'];

// ——— Research modes ———
type ResearchMode = 'off' | 'standard' | 'deep';
const RESEARCH_MODES: Array<{ id: ResearchMode; label: string }> = [
  { id: 'off', label: 'Aucune recherche' },
  { id: 'standard', label: 'Recherche standard (Exa/Tavily/You.com)' },
  { id: 'deep', label: 'Deep research (multi-round + vérif sources)' },
];

// ——— Composio integration presets (default: Google Workspace) ———
const DEFAULT_CONNECTORS = [
  'Google Docs',
  'Gmail',
  'Google Calendar',
  'Google Drive',
  'Google Sheets',
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
  const [showPlusSheet, setShowPlusSheet] = useState(false);
  const [agentMode, setAgentMode] = useState<AgentMode>('agent');
  const [thinkingLevel, setThinkingLevel] = useState<ThinkingLevel>('medium');
  const [researchMode, setResearchMode] = useState<ResearchMode>('off');
  const [connectors, setConnectors] = useState<string[]>(DEFAULT_CONNECTORS);
  const [files, setFiles] = useState<string[]>([]);
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
      requestAnimationFrame(() => {
        transcriptRef.current?.scrollTo({ top: transcriptRef.current.scrollHeight });
      });
    }
  }, [runRow, activeRun]);

  async function submit() {
    const intent = draft.trim();
    if (!intent || !agent || thinking) return;
    setDraft('');
    setFiles([]);
    push({ role: 'user', body: intent });
    try {
      const handle = await agent.start({
        intent,
        taskProfile: {
          preferredProvider: modelChoice?.provider,
          preferredModel: modelChoice?.model,
          thinkingLevel,
          researchMode,
          agentMode,
        },
      });
      setActiveRun(handle.traceId);
    } catch {
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
          {/* Agent mode tabs (chat / agent / mirror) */}
          <div className="agent-mode-tabs" role="tablist">
            {AGENT_MODES.map((m) => (
              <button
                key={m.id}
                type="button"
                role="tab"
                aria-selected={agentMode === m.id}
                className={`agent-mode-tab ${agentMode === m.id ? 'is-active' : ''}`}
                onClick={() => setAgentMode(m.id)}
                disabled={thinking}
              >
                {m.icon}
                <span>{m.label}</span>
              </button>
            ))}
          </div>

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
                <p>
                  Mode {agentMode === 'agent' ? 'agent' : agentMode === 'mirror' ? 'miroir — explique ce que tu as appris' : 'chat'}.
                  Commence par une intention.
                </p>
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
                <span className="agent-thinking-label">L'agent réfléchit ({thinkingLevel})…</span>
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

          {/* Active chips: thinking level + research + files + connectors */}
          <div className="agent-active-chips">
            <button
              type="button"
              className={`agent-chip ${researchMode !== 'off' ? 'is-on' : ''}`}
              onClick={() => setResearchMode(researchMode === 'off' ? 'standard' : 'off')}
              disabled={!agent || thinking}
              aria-label="Mode recherche"
            >
              <Search size={12} />
              {researchMode === 'off' ? 'Recherche' : researchMode === 'deep' ? 'Deep' : 'Standard'}
            </button>
            <button
              type="button"
              className="agent-chip"
              onClick={() => setShowPlusSheet(true)}
              disabled={!agent || thinking}
              aria-label="Plus d'options"
            >
              <Plus size={14} />
            </button>
            {files.length > 0 && (
              <span className="agent-chip agent-chip--static">
                <FilePlus size={12} />
                {files.length} fichier{files.length > 1 ? 's' : ''}
              </span>
            )}
            {connectors.length > 0 && (
              <span className="agent-chip agent-chip--static">
                <Link2 size={12} />
                {connectors.length}
              </span>
            )}
          </div>

          <form
            className="agent-composer"
            onSubmit={(e) => {
              e.preventDefault();
              void submit();
            }}
          >
            <button
              type="button"
              className="agent-model-picker-trigger"
              onClick={() => setShowPicker(true)}
              aria-label="Choisir le modèle et le niveau de réflexion"
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
              placeholder={agentMode === 'mirror' ? 'Explique ce que tu as appris…' : 'Écris ton intention…'}
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

          {/* Model + thinking level picker modal */}
          {showPicker && (
            <div className="agent-model-picker-modal" role="dialog" aria-label="Choix du modèle">
              <div className="agent-model-picker-header">
                <Bot size={16} aria-hidden />
                <h3>Modèle & réflexion</h3>
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
                <div className="agent-picker-section">
                  <div className="agent-picker-section-label">Niveau de réflexion</div>
                  <div className="agent-thinking-levels">
                    {THINKING_LEVELS.map((lvl) => (
                      <button
                        key={lvl}
                        type="button"
                        className={`agent-thinking-level ${thinkingLevel === lvl ? 'is-active' : ''}`}
                        onClick={() => setThinkingLevel(lvl)}
                      >
                        {lvl}
                      </button>
                    ))}
                  </div>
                </div>

                <div className="agent-picker-section">
                  <div className="agent-picker-section-label">Modèle</div>
                  <button
                    type="button"
                    className={`agent-model-picker-option ${!modelChoice ? 'is-active' : ''}`}
                    onClick={() => {
                      setModelChoice(null);
                      setShowPicker(false);
                    }}
                  >
                    <Sparkles size={14} aria-hidden />
                    <span>Auto — le router choisit</span>
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
            </div>
          )}

          {/* + sheet: files / connectors / skills / research */}
          {showPlusSheet && (
            <div className="agent-plus-sheet" role="dialog" aria-label="Options du chat">
              <div className="agent-plus-header">
                <h3>Options</h3>
                <button
                  type="button"
                  className="agent-plus-close"
                  onClick={() => setShowPlusSheet(false)}
                  aria-label="Fermer"
                >
                  ×
                </button>
              </div>

              <div className="agent-plus-section">
                <div className="agent-plus-label">Recherche</div>
                {RESEARCH_MODES.map((m) => (
                  <button
                    key={m.id}
                    type="button"
                    className={`agent-plus-option ${researchMode === m.id ? 'is-active' : ''}`}
                    onClick={() => setResearchMode(m.id)}
                  >
                    <Search size={14} aria-hidden />
                    <span>{m.label}</span>
                  </button>
                ))}
              </div>

              <div className="agent-plus-section">
                <div className="agent-plus-label">Connecteurs (Composio)</div>
                {connectors.map((c) => (
                  <label key={c} className="agent-plus-connector">
                    <input
                      type="checkbox"
                      checked={connectors.includes(c)}
                      onChange={(e) => {
                        const next = e.target.checked
                          ? [...connectors, c]
                          : connectors.filter((x) => x !== c);
                        setConnectors(next);
                      }}
                    />
                    <span>{c}</span>
                  </label>
                ))}
              </div>

              <div className="agent-plus-section">
                <div className="agent-plus-label">Fichiers</div>
                <button
                  type="button"
                  className="agent-plus-option"
                  onClick={() => {
                    const next = `fichier-${files.length + 1}.pdf`;
                    setFiles([...files, next]);
                  }}
                >
                  <FilePlus size={14} aria-hidden />
                  <span>Ajouter un fichier</span>
                </button>
                {files.length > 0 && (
                  <div className="agent-plus-files">{files.map((f) => <span key={f} className="agent-plus-file">{f}</span>)}</div>
                )}
              </div>

              <div className="agent-plus-section">
                <div className="agent-plus-label">Skills</div>
                <button type="button" className="agent-plus-option" onClick={() => { setShowPlusSheet(false); /* navigate to /skills */ }}>
                  <Sparkles size={14} aria-hidden />
                  <span>Gérer mes skills (marketplace + perso)</span>
                </button>
              </div>
            </div>
          )}
        </div>
      </IonContent>
    </>
  );
}
