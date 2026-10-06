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
 *  - Files (kernel not yet wired — the section ships in a later wave;
 *    there is no fake file picker on the surface)
 *  - Add connect (Composio: Google Workspace by default)
 *  - Skills marketplace (browse ClawHub / create personal skill)
 *  - Research mode (standard / deep)
 *  - Thinking level (low / medium / high / max)
 *
 * Agent modes: chat | agent (autonomous) | mirror (teach the AI).
 *
 * ————————————————————————————————————————————————————————————————
 * Gestures (emotion-design §3, mobile UX pattern: « fluid, never blocking »)
 *  - **Text selection → menu** : long-press / native selection inside the
 *    transcript exposes a floating action bar (Copy / Send-to-chat /
 *    Open page) — the bar appears on `selectionchange` when a selection
 *    is inside the transcript container.
 *  - **Horizontal drag (composer)** : the composer row is a swipe surface:
 *    swipe LEFT → opens the `+` sheet (files/connectors/research/skills);
 *    swipe RIGHT → cycles the agent mode tabs (chat → agent → mirror).
 *    The gesture is damped (not instant) so it never fights the keyboard.
 *  - **Vertical drag → modal (composer)** : swipe the composer row DOWN
 *    (pull-to-open) → opens the model picker modal (the same sheet as the
 *    `Cpu` trigger). Threshold 60 px; springs back below.
 *  - **Drag-to-open page (transcript)** : agent entries that carry a
 *    `route` payload (deep-link, 04 §3.2.5) are horizontally draggable:
 *    drag the bubble LEFT → the page it targets slides in from the right
 *    (navigate + push-state so the back button returns to the chat).
 *    The bubble « peels » (transform follows the finger, clamped).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { AgentThinkingLoader } from '@aurora/ui';
import {
  Bot,
  Brain,
  Cpu,
  Link2,
  Plus,
  Search,
  Send,
  Sparkles,
  Zap,
  Copy,
  ArrowRight,
  Quote,
} from 'lucide-react';
import {
  useEffect,
  useRef,
  useState,
  type PointerEvent as ReactPointerEvent,
} from 'react';
import { useNavigate } from 'react-router-dom';
import { useReducedMotion } from 'motion/react';
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
  /**
   * Deep-link target (04 §3.2.5): when present, the bubble is
   * drag-to-open — swipe LEFT peels the bubble and navigates to `route`
   * with replace-state so back returns to the chat.
   */
  route?: string;
  /** Optional short label shown on the peel affordance (chevron line). */
  routeLabel?: string;
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

/**
 * Gesture constants (emotional design §3: « calm, never snappy »).
 * Thresholds tuned so the gestures coexist with native text selection:
 * a 10 px dead-zone prevents accidental triggers when tapping the composer.
 */
const GESTURE_DEAD_ZONE = 10; // px before a swipe is "real"
const GESTURE_VELOCITY = 0.35; // px/ms — below = "slow, intentional"
const PULL_OPEN_DISTANCE = 64; // px for composer pull-down → model modal
const PULL_OPEN_EASE = 'cubic-bezier(0.22, 1, 0.36, 1)'; // ease-out « luxe »

export function AgentPage() {
  const navigate = useNavigate();
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
  // files: local surface state — kernel not yet wired (wave-N, see docs/kernel §files)
  const transcriptRef = useRef<HTMLDivElement>(null);
  const entrySeq = useRef(0);

  // ——— Text-selection floating menu state ————————————————————————————
  const [selection, setSelection] = useState<{
    text: string;
    x: number;
    y: number;
  } | null>(null);

  // ——— Composer pull-down (→ model modal) ——————————————————————————
  const [pullOffset, setPullOffset] = useState(0);
  const [pullActive, setPullActive] = useState(false);

  // ——— Composer horizontal swipe (left → + sheet, right → cycle mode) —
  const [swipeOffset, setSwipeOffset] = useState(0);
  const [swipeActive, setSwipeActive] = useState(false);
  const swipeStart = useRef<{ x: number; y: number; t: number } | null>(null);

  // ——— Transcript bubble peel (drag-to-open route) ———————————————————
  const [peel, setPeel] = useState<{ entryId: string; dx: number } | null>(null);
  const peelStart = useRef<{ x: number; entryId: string } | null>(null);

  const { data: runRow, isFetching } = useAgentRun(activeRun);
  const thinking = activeRun !== undefined && !runRow;

  // Reduced-motion guard (emotion-design §3, 05 §2.6 règle 2): smooth scroll
  // → instant scroll when the OS preference is ON.
  const reducedMotion = useReducedMotion();

  function push(e: Omit<Entry, 'id'>) {
    entrySeq.current += 1;
    const id = `e${entrySeq.current}`;
    setEntries((prev) => [...prev, { ...e, id }]);
    requestAnimationFrame(() => {
      transcriptRef.current?.scrollTo({
        top: transcriptRef.current.scrollHeight,
        behavior: reducedMotion ? 'auto' : 'smooth',
      });
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
        transcriptRef.current?.scrollTo({
          top: transcriptRef.current.scrollHeight,
          behavior: reducedMotion ? 'auto' : 'smooth',
        });
      });
    }
  }, [runRow, activeRun, reducedMotion]);

  // ——— Overlay dismissal (Escape) for the model picker + the + sheet
  // (pattern: src/ux/floating.tsx). ———
  useEffect(() => {
    if (!showPicker && !showPlusSheet) return;
    function onKey(e: KeyboardEvent) {
      if (e.key === 'Escape') {
        setShowPicker(false);
        setShowPlusSheet(false);
      }
    }
    document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, [showPicker, showPlusSheet]);

  async function submit() {
    const intent = draft.trim();
    if (!intent || !agent || thinking) return;
    setDraft('');
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
        body: `Lancement du run impossible (agent indisponible côté serveur). ${registerCopy(register, 'conn')}`,
      });
    }
  }

  /**
   * Prepend the selected text into the composer draft (the « send-to-chat »
   * action of the selection menu). The selection is cleared AFTER so the
   * user can keep scrolling; focus returns to the composer.
   */
  function selectionToDraft() {
    if (!selection) return;
    const quoted = selection.text;
    setDraft((prev) => (prev ? `${prev}\n${quoted}` : quoted));
    setSelection(null);
    window.getSelection()?.removeAllRanges();
    document.getElementById('agent-composer-input')?.focus();
  }

  /** Native copy (clipboard) — the « copy » action of the selection menu. */
  async function selectionCopy() {
    if (!selection) return;
    try {
      await navigator.clipboard.writeText(selection.text);
    } catch {
      /* mobile Safari: clipboard API may be gated; the text is still
         highlighted, the user can use the system share sheet. */
    }
    setSelection(null);
    window.getSelection()?.removeAllRanges();
  }

  // ——— selectionchange watcher (only when a selection is INSIDE the
  // transcript container — the floating menu must not track selections
  // in the composer input, the model picker, or other pages). ———
  useEffect(() => {
    function onSelectionChange() {
      const sel = window.getSelection();
      if (!sel || sel.isCollapsed || sel.rangeCount === 0) {
        setSelection(null);
        return;
      }
      const range = sel.getRangeAt(0);
      if (!transcriptRef.current?.contains(range.startContainer)) {
        setSelection(null);
        return;
      }
      const rect = range.getBoundingClientRect();
      setSelection({
        text: sel.toString(),
        x: Math.max(12, Math.min(window.innerWidth - 180, rect.left + rect.width / 2 - 90)),
        y: Math.max(8, rect.top - 56),
      });
    }
    document.addEventListener('selectionchange', onSelectionChange);
    return () => document.removeEventListener('selectionchange', onSelectionChange);
  }, []);

  // ————————————————————————————————————————————————————————————————
  // Composer gestures (horizontal swipe + vertical pull-down)
  // Both live on the composer row. The handler distinguishes the two
  // by the dominant axis at pointermove (first 15 px past the dead-zone).
  // ————————————————————————————————————————————————————————————————

  function onComposerPointerDown(e: ReactPointerEvent<HTMLDivElement>) {
    // Ignore if the user is interacting with a real control (buttons, input).
    const target = e.target as HTMLElement;
    if (target.closest('button, input, a')) return;
    swipeStart.current = { x: e.clientX, y: e.clientY, t: performance.now() };
    setSwipeActive(true);
  }

  function onComposerPointerMove(e: ReactPointerEvent<HTMLDivElement>) {
    if (!swipeStart.current) return;
    const dx = e.clientX - swipeStart.current.x;
    const dy = e.clientY - swipeStart.current.y;

    // Past the dead-zone: decide the axis (|dx| vs |dy| dominates).
    if (!swipeActive) return;
    if (Math.abs(dx) < GESTURE_DEAD_ZONE && Math.abs(dy) < GESTURE_DEAD_ZONE) return;

    if (Math.abs(dx) >= Math.abs(dy)) {
      // Horizontal: LEFT swipe → open the + sheet (files / connectors /
      // research — the sheet is the "right" surface, reaching left for it);
      // RIGHT swipe → cycle the agent-mode tab (chat → agent → mirror).
      const clamped = Math.max(-96, Math.min(96, dx));
      setSwipeOffset(clamped);
    } else if (dy > 0) {
      // Vertical down-pull → model modal (pull-to-open, spring-back below
      // the PULL_OPEN_DISTANCE threshold). 15 % damping keeps it calm.
      setPullOffset(Math.min(120, dy * 0.85));
      setPullActive(true);
    }
  }

  function onComposerPointerUp(e: ReactPointerEvent<HTMLDivElement>) {
    const start = swipeStart.current;

    if (start) {
      const totalDx = e.clientX - start.x;
      const totalDy = e.clientY - start.y;
      const dt = Math.max(1, performance.now() - start.t);
      const velocity = Math.abs(totalDx) / dt;
      if (totalDx < -GESTURE_DEAD_ZONE) {
        // LEFT swipe → open the + sheet (connectors / skills / research).
        if (Math.abs(totalDx) > 64 || velocity > GESTURE_VELOCITY) {
          setShowPicker(false);
          setShowPlusSheet(true);
        }
      } else if (totalDx > GESTURE_DEAD_ZONE) {
        // RIGHT swipe → cycle the agent mode (chat → agent → mirror → chat).
        if (Math.abs(totalDx) > 64 || velocity > GESTURE_VELOCITY) {
          setAgentMode((prev) => {
            const idx = Math.max(0, AGENT_MODES.findIndex((m) => m.id === prev));
            return AGENT_MODES[(idx + 1) % AGENT_MODES.length]!.id;
          });
        }
      } else if (totalDy > PULL_OPEN_DISTANCE) {
        // Down-pull past the threshold → open the model picker modal.
        setShowPlusSheet(false);
        setShowPicker(true);
      }
    }

    setSwipeActive(false);
    setPullActive(false);
    setSwipeOffset(0);
    setPullOffset(0);
    swipeStart.current = null;
  }

  // ————————————————————————————————————————————————————————————————
  // Transcript bubble peel (drag-to-open a route entry, 04 §3.2.5)
  // Only entries carrying a `route` are peelable; the chevron affordance
  // is the only visual cue (a static `→` line, no shadow), so the surface
  // stays calm by default.
  // ————————————————————————————————————————————————————————————————

  function onBubblePointerDown(e: ReactPointerEvent<HTMLDivElement>, entryId: string) {
    peelStart.current = { x: e.clientX, entryId };
  }
  function onBubblePointerMove(e: ReactPointerEvent<HTMLDivElement>) {
    if (!peelStart.current) return;
    const dx = Math.min(0, e.clientX - peelStart.current.x); // left only
    if (dx > -GESTURE_DEAD_ZONE) return;
    setPeel({ entryId: peelStart.current.entryId, dx: Math.max(-160, dx * 0.7) });
  }
  function onBubblePointerUp(e: ReactPointerEvent<HTMLDivElement>) {
    if (!peelStart.current) return;
    const totalDx = e.clientX - peelStart.current.x;
    const entry = entries.find((x) => x.id === peelStart.current?.entryId);
    if (totalDx < -96 && entry?.route) {
      // Confirmed peel: navigate to the target page over the chat (agent-chat
      // §5.1 G4). `state.from = '/agent'` preserves the return context — the
      // native back returns to this conversation (02 §6.3, RET column).
      navigate(entry.route, { state: { from: '/agent' } });
    }
    setPeel(null);
    peelStart.current = null;
  }

  // ——— Voice register (emotion-design §5.3): chat/agent = vouvoiement
  // (professional register); mirror = tutoiement (pedagogical register).
  // The right-swipe that cycles the mode therefore switches the register —
  // copy in the transcript follows agentMode. ———
  function registerCopy(
    register: 'pro' | 'pedagogical',
    keys: 'conn' | 'mirror' | 'write' | 'explain'
  ): string {
    const pro: Record<typeof keys, string> = {
      conn: 'Vérifiez votre connexion et relancez.',
      mirror: 'miroir — vous expliquez ce que vous avez appris',
      write: 'Écrivez votre intention…',
      explain: 'Expliquez ce que vous avez appris…',
    };
    const ped: Record<typeof keys, string> = {
      conn: 'Vérifie ta connexion et relance.',
      mirror: 'miroir — explique ce que tu as appris',
      write: 'Écris ton intention…',
      explain: 'Explique ce que tu as appris…',
    };
    return (register === 'pro' ? pro : ped)[keys];
  }

  const register: 'pro' | 'pedagogical' = agentMode === 'mirror' ? 'pedagogical' : 'pro';

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
                id={`tab-${m.id}`}
                aria-selected={agentMode === m.id}
                aria-controls="agent-transcript"
                tabIndex={agentMode === m.id ? 0 : -1}
                onKeyDown={(e) => {
                  if (thinking) return;
                  const idx = AGENT_MODES.findIndex((x) => x.id === m.id);
                  let next = -1;
                  if (e.key === 'ArrowRight') next = (idx + 1) % AGENT_MODES.length;
                  else if (e.key === 'ArrowLeft') next = (idx - 1 + AGENT_MODES.length) % AGENT_MODES.length;
                  else if (e.key === 'Home') next = 0;
                  else if (e.key === 'End') next = AGENT_MODES.length - 1;
                  if (next >= 0) {
                    e.preventDefault();
                    const target = AGENT_MODES[next]!;
                    setAgentMode(target.id);
                    document.getElementById(`tab-${target.id}`)?.focus();
                  }
                }}
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
            id="agent-transcript"
            className="agent-transcript"
            role="tabpanel"
            aria-labelledby={`tab-${agentMode}`}
            tabIndex={0}
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
                  Mode {agentMode === 'agent' ? 'agent' : agentMode === 'mirror' ? registerCopy(register, 'mirror') : 'chat'}.
                  {agentMode === 'mirror' ? 'Commence par un apprentissage.' : 'Commencez par une intention.'}
                </p>
              </div>
            )}

            {entries.map((e) => {
              const isPeeling = peel?.entryId === e.id;
              const peeling = isPeeling ? peel!.dx : 0;
              return (
                <div
                  key={e.id}
                  className={`agent-entry agent-entry--${e.role} ${e.route ? 'agent-entry--peelable' : ''}`}
                  style={
                    isPeeling
                      ? { transform: `translateX(${peeling}px)`, transition: 'transform 220ms ' + PULL_OPEN_EASE }
                      : undefined
                  }
                  onPointerDown={(ev) => e.route && onBubblePointerDown(ev, e.id)}
                  onPointerMove={(ev) => e.route && onBubblePointerMove(ev)}
                  onPointerUp={(ev) => e.route && onBubblePointerUp(ev)}
                  onPointerCancel={() => setPeel(null)}
                >
                  <div className="agent-entry-body">{e.body}</div>
                  {e.route && (
                    /* Peel affordance (agent-chat §5.1 G4): a focusable button
                       in addition to the drag gesture — the keyboard / SR
                       equivalent of the swipe. The chevron is decorative;
                       the button's aria-label carries the meaning. */
                    <button
                      type="button"
                      className="agent-entry-route"
                      onClick={() => navigate(e.route ?? '/', { state: { from: '/agent' } })}
                      aria-label={`Ouvrir ${e.routeLabel ?? 'la page'}`}
                    >
                      <ArrowRight size={12} aria-hidden />
                      <span>{e.routeLabel ?? 'Ouvrir la page'}</span>
                    </button>
                  )}
                </div>
              );
            })}

            {thinking && (
              <AgentThinkingLoader
                state="thinking"
                label={`L'agent réfléchit (${thinkingLevel})…`}
                className="agent-thinking"
              />
            )}

            {inFlightRow && (
              <div className="agent-entry agent-entry--agent">
                <div
                  className={`agent-entry-status ${inFlightRow.confirmationMessage ? 'is-attention' : ''}`}
                  aria-live="polite"
                >
                  {statusLine(inFlightRow)}
                </div>
              </div>
            )}
          </div>

          {/* Floating text-selection action bar (Copy / Send-to-chat / Open
              page) — appears when a selection is inside the transcript. */}
          {selection && (
            <div
              className="agent-selection-menu"
              role="menu"
              aria-label="Actions sur la sélection"
              style={{ left: selection.x, top: selection.y }}
            >
              <button
                type="button"
                onClick={selectionCopy}
                aria-label="Copier la sélection"
              >
                <Copy size={14} />
                <span>Copier</span>
              </button>
              <button
                type="button"
                onClick={selectionToDraft}
                aria-label="Ajouter au chat"
              >
                <Send size={14} />
                <span>Dans le chat</span>
              </button>
              <button
                type="button"
                onClick={() => {
                  // « Open page » = treat the selection as a query and open
                  // the knowledge search (the natural destination for a
                  // quoted snippet). If the selection looks like a route
                  // (a known in-app path), navigate there instead.
                  const text = selection.text.trim();
                  const looksLikeRoute =
                    text.startsWith('/') && !text.includes(' ') && text.length < 64;
                  setSelection(null);
                  window.getSelection()?.removeAllRanges();
                  if (looksLikeRoute) {
                    navigate(text);
                  } else {
                    navigate(`/knowledge?q=${encodeURIComponent(text)}`);
                  }
                }}
                aria-label="Ouvrir dans l'app"
              >
                <Quote size={14} />
                <span>Ouvrir</span>
              </button>
            </div>
          )}

          {/* Active chips: research + connectors */}
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
              onClick={() => {
                setShowPicker(false);
                setShowPlusSheet(true);
              }}
              disabled={!agent || thinking}
              aria-label="Plus d'options"
            >
              <Plus size={14} />
            </button>
            {connectors.length > 0 && (
              <span className="agent-chip agent-chip--static">
                <Link2 size={12} />
                {connectors.length}
              </span>
            )}
          </div>

          {/* Composer (pinned, swipe surface) */}
          <div
            className="agent-composer-gesture"
            onPointerDown={onComposerPointerDown}
            onPointerMove={onComposerPointerMove}
            onPointerUp={onComposerPointerUp}
            onPointerCancel={onComposerPointerUp}
            style={{
              transform: `translateX(${swipeOffset}px) translateY(${pullOffset}px)`,
              transition:
                swipeActive || pullActive ? 'none' : 'transform 260ms ' + PULL_OPEN_EASE,
              touchAction: 'none',
            }}
          >
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
                onClick={() => {
                  setShowPlusSheet(false);
                  setShowPicker(true);
                }}
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
                id="agent-composer-input"
                value={draft}
                onChange={(e) => setDraft(e.target.value)}
                placeholder={agentMode === 'mirror' ? registerCopy(register, 'explain') : registerCopy(register, 'write')}
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

            {/* Hint line (only visible while swiping: « glisser → options ») */}
            {(swipeActive || pullActive) && (
              <div className="agent-composer-hint" aria-live="polite">
                {swipeOffset < -16
                  ? 'Relâche pour les options'
                  : swipeOffset > 16
                  ? 'Relâche pour changer de mode'
                  : pullOffset > 16
                  ? 'Relâche pour le choix du modèle'
                  : 'Glisse'}
              </div>
            )}
          </div>

          {/* Model + thinking level picker modal */}
          {showPicker && (
            <div
              className="agent-model-picker-modal"
              role="dialog"
              aria-modal="true"
              aria-label="Choix du modèle"
              onMouseDown={(e) => {
                if (e.target === e.currentTarget) setShowPicker(false);
              }}
            >
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
                  <div className="agent-thinking-levels" role="radiogroup" aria-label="Niveau de réflexion">
                    {THINKING_LEVELS.map((lvl, i) => (
                      <button
                        key={lvl}
                        type="button"
                        role="radio"
                        aria-checked={thinkingLevel === lvl}
                        tabIndex={thinkingLevel === lvl ? 0 : -1}
                        className={`agent-thinking-level ${thinkingLevel === lvl ? 'is-active' : ''}`}
                        onClick={() => setThinkingLevel(lvl)}
                        onKeyDown={(e) => {
                          // Roving radio pattern: arrows move focus + selection.
                          if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
                            e.preventDefault();
                            const next = THINKING_LEVELS[(i + 1) % THINKING_LEVELS.length]!;
                            setThinkingLevel(next);
                          } else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
                            e.preventDefault();
                            const prev = THINKING_LEVELS[(i + 3) % THINKING_LEVELS.length]!;
                            setThinkingLevel(prev);
                          }
                        }}
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

          {/* + sheet: connectors / skills / research */}
          {showPlusSheet && (
            <div
              className="agent-plus-sheet"
              role="dialog"
              aria-modal="true"
              aria-label="Options du chat"
              onMouseDown={(e) => {
                if (e.target === e.currentTarget) setShowPlusSheet(false);
              }}
            >
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
                <div className="agent-plus-label">Skills</div>
                <button type="button" className="agent-plus-option" onClick={() => { setShowPlusSheet(false); navigate('/skills'); }}>
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
