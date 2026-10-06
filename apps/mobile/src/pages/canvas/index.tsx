import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { EditorContent, useEditor } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import { useEffect, useRef, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import type { AppError, AsyncState, CanvasBlock, CanvasComment } from '@aurora/domain';
import { markdownToHtml, commentAnchors } from '@aurora/ui';
import { UxStates, type UxStateFlags } from '../../ux-states';
import { useCanvasSession, useCanvasSave } from '../../query/canvas';
import { useMobileData } from '../../query/context';
import { useOnlineStatus } from '../../hooks/use-online';
import { useUiStateStore } from '../../state/ui-state';

type View = 'edit' | 'markdown' | 'html';

function buildChatIntent(id: string, selection: string): string {
  return `>[canvas ${id}] ${selection}`;
}

function stripTipTapJson(_json: unknown, fallbackMd: string): string {
  return fallbackMd;
}

export function CanvasPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const isCreation = id === 'new';
  const sessionId = isCreation ? undefined : id;

  const { canvas } = useMobileData();
  const { data, status, isError, refetch } = useCanvasSession(sessionId);
  const save = useCanvasSave();

  const online = useOnlineStatus();
  const killed = useUiStateStore((s) => s.killed);
  const flags: UxStateFlags = { offline: !online, killed };

  const [view, setView] = useState<View>('edit');
  const [blocks, setBlocks] = useState<CanvasBlock[]>(() =>
    isCreation ? [{ id: 'b-new', kind: 'md', content: '' }] : [],
  );

  const session = data?.session ?? null;
  const lastSessionKey = useRef<string | null>(null);
  useEffect(() => {
    if (session && lastSessionKey.current !== session.id) {
      lastSessionKey.current = session.id;
      setBlocks(session.blocks);
    }
  }, [session]);

  const [addingComment, setAddingComment] = useState(false);
  const [commentDraft, setCommentDraft] = useState('');
  const [commentError, setCommentError] = useState<string | null>(null);

  const editorContainerRef = useRef<HTMLDivElement>(null);
  const [selection, setSelection] = useState<{ text: string; x: number; y: number } | null>(null);

  useEffect(() => {
    function onSelectionChange() {
      const sel = window.getSelection();
      if (!sel || sel.isCollapsed || sel.rangeCount === 0) {
        setSelection(null);
        return;
      }
      const range = sel.getRangeAt(0);
      if (!editorContainerRef.current?.contains(range.startContainer)) {
        setSelection(null);
        return;
      }
      const text = sel.toString();
      if (!text.trim()) {
        setSelection(null);
        return;
      }
      const rect = range.getBoundingClientRect();
      setSelection({
        text,
        x: Math.max(12, Math.min(window.innerWidth - 180, rect.left + rect.width / 2 - 90)),
        y: Math.max(8, rect.top - 56),
      });
    }
    document.addEventListener('selectionchange', onSelectionChange);
    return () => document.removeEventListener('selectionchange', onSelectionChange);
  }, []);

  function onIndexInChat() {
    if (!selection) return;
    const intent = buildChatIntent(id ?? 'new', selection.text);
    navigate(`/agent?intent=${encodeURIComponent(intent)}`, {
      state: { from: '/canvas' },
    });
    setSelection(null);
    window.getSelection()?.removeAllRanges();
  }

  function openComposer() {
    setCommentError(null);
    setAddingComment(true);
    setSelection(null);
    window.getSelection()?.removeAllRanges();
  }

  function onAddComment() {
    if (!canvas || !sessionId || !commentDraft.trim() || !selection) return;
    const anchors = commentAnchors(selection.text, blocks);
    if (!anchors) {
      setCommentError(
        "Ancre introuvable : le texte sélectionné ne figure plus dans le " +
          'canvas (édition depuis la sélection, ou terme absent). ' +
          'Réessayez avec une sélection dans le contenu actuel.',
      );
      return;
    }
    void canvas
      .addComment(sessionId, { start: anchors[0], end: anchors[1] }, commentDraft.trim())
      .then(() => {
        setCommentDraft('');
        setAddingComment(false);
        setCommentError(null);
        refetch();
      })
      .catch((e: unknown) => {
        setCommentError(e instanceof Error ? e.message : "Erreur lors de l'envoi du commentaire.");
      });
  }

  function onDeleteComment(commentId: string) {
    if (!canvas) return;
    void canvas.deleteComment(commentId).then(() => refetch());
  }

  const [creating, setCreating] = useState(false);
  async function onCreate() {
    if (!canvas || creating) return;
    setCreating(true);
    try {
      const created = await canvas.create('Nouvelle session', blocks);
      navigate(`/canvas/${created.id}`, { replace: true });
    } finally {
      setCreating(false);
    }
  }

  const ux: AsyncState<{ blocks: CanvasBlock[]; comments: CanvasComment[] }> =
    isCreation
      ? ({ status: 'empty' } as const)
      : isError
        ? ({
            status: 'error',
            error: {
              code: 'canvas/load_failed',
              message: 'Canvas indisponible',
            } as AppError,
          } as const)
        : status === 'pending'
          ? ({ status: 'loading' } as const)
          : data && data.session
            ? {
                status: 'success',
                data: { blocks: data.session.blocks, comments: data.comments },
              }
            : ({ status: 'empty' } as const);

  const canEdit = Boolean(canvas);
  const flatMarkdown = blocks.map((b) => b.content).join('\n\n');
  const htmlRender = view === 'html' ? markdownToHtml(flatMarkdown) : '';

  return (
    <>
      <IonHeader>
        <IonTitle>Canvas</IonTitle>
      </IonHeader>
      <IonContent>
        <div className="canvas-page" data-canvas-id={id} data-ux={ux.status}>
          <UxStates state={ux} flags={flags} label="Canvas">
            {ux.status === 'success' && (
              <>
                <div className="canvas-toolbar" role="toolbar" aria-label="Vues du canvas">
                  {(['edit', 'markdown', 'html'] as const).map((v) => (
                    <button
                      key={v}
                      type="button"
                      className={view === v ? 'is-active' : ''}
                      onClick={() => setView(v)}
                      aria-label={
                        v === 'edit'
                          ? 'Éditer (blocs TipTap)'
                          : v === 'markdown'
                            ? 'Vue Markdown (texte plat)'
                            : 'Vue HTML (rendu lecture)'
                      }
                    >
                      {v === 'edit' ? 'Éditer' : v === 'markdown' ? 'Markdown' : 'HTML'}
                    </button>
                  ))}
                </div>

                {view === 'edit' && (
                  <div className="canvas-editor" ref={editorContainerRef} data-canvas="editor">
                    {blocks.map((b) => (
                      <CanvasBlockEditor
                        key={b.id}
                        block={b}
                        onChange={(md) => {
                          setBlocks((prev) => {
                            const next = prev.map((x) => (x.id === b.id ? { ...x, content: md } : x));
                            // Save le contenu ACTUEL (prev) — le `blocks` capturé
                            // dans le closure est stale d'une édition (YAGNI :
                            // le save debouncé porte la charge réseau, il doit
                            // porter la vérité, pas un état retardé).
                            if (sessionId) save(sessionId, next);
                            return next;
                          });
                        }}
                      />
                    ))}
                    {isCreation && (
                      <div className="canvas-create-cta">
                        <p>
                          Nouvelle session — enregistrez pour la rendre persistante.
                          Le contenu local est préservé, rien n'est perdu.
                        </p>
                        <button
                          type="button"
                          className="aurora-btn aurora-btn--primary aurora-tap"
                          onClick={() => void onCreate()}
                          disabled={!canEdit || creating}
                        >
                          {creating ? 'Enregistrement…' : 'Enregistrer'}
                        </button>
                      </div>
                    )}                  </div>
                )}

                {view === 'markdown' && (
                  <pre className="canvas-source" aria-label="Contenu Markdown du canvas">
                    {flatMarkdown}
                  </pre>
                )}

                {view === 'html' && (
                  <div
                    className="canvas-html"
                    aria-label="Rendu HTML en lecture"
                    dangerouslySetInnerHTML={{
                      __html: htmlRender || '<p class="canvas-html-empty">Contenu vide.</p>',
                    }}
                  />
                )}

                {selection && view === 'edit' && (
                  <div
                    className="canvas-selection-menu"
                    role="menu"
                    aria-label="Actions sur la sélection"
                    style={{ left: selection.x, top: selection.y }}
                  >
                    <button type="button" onClick={onIndexInChat} aria-label="Indexer la sélection dans le chat">
                      <span>Indexer dans le chat</span>
                    </button>
                    <button type="button" onClick={openComposer} aria-label="Commenter la sélection">
                      <span>Commenter</span>
                    </button>
                  </div>
                )}

                {addingComment && (
                  <div
                    className="canvas-comment-composer"
                    role="dialog"
                    aria-label="Nouveau commentaire"
                  >
                    {commentError && (
                      <p className="canvas-comment-error" role="alert">
                        {commentError}
                      </p>
                    )}
                    <textarea
                      value={commentDraft}
                      onChange={(e) => setCommentDraft(e.target.value)}
                      aria-label="Commentaire"
                      placeholder="Votre commentaire…"
                    />
                    <div className="canvas-comment-composer-actions">
                      <button
                        type="button"
                        className="aurora-btn aurora-btn--ghost aurora-tap"
                        onClick={() => {
                          setAddingComment(false);
                          setCommentDraft('');
                          setCommentError(null);
                        }}
                      >
                        Annuler
                      </button>
                      <button
                        type="button"
                        className="aurora-btn aurora-btn--primary aurora-tap"
                        onClick={onAddComment}
                        disabled={!commentDraft.trim() || !canvas || !sessionId}
                      >
                        Envoyer
                      </button>
                    </div>
                  </div>
                )}

                {data && data.comments.length > 0 && (
                  <div className="canvas-comments">
                    <h3>{data.comments.length} commentaire(s)</h3>
                    <ul>
                      {data.comments.map((c) => (
                        <li key={c.id} className="canvas-comment-item">
                          <span className="canvas-comment-anchor">
                            [offsets {c.anchorStart}–{c.anchorEnd}]
                          </span>
                          <span className="canvas-comment-body">{c.body}</span>
                          <button
                            type="button"
                            className="canvas-comment-delete"
                            onClick={() => onDeleteComment(c.id)}
                            aria-label="Supprimer le commentaire"
                          >
                            Supprimer
                          </button>
                        </li>
                      ))}
                    </ul>
                  </div>
                )}
              </>
            )}

            {ux.status === 'empty' && (
              <div className="canvas-empty">
                <p>
                  {isCreation
                    ? 'Nouvelle session en cours de composition — enregistrez pour la persister.'
                    : "Aucune session pour cet identifiant (elle n'existe pas, ou ne vous appartient pas — RLS user, 0022)."}
                </p>
                {isCreation ? (
                  <button
                    type="button"
                    className="aurora-btn aurora-btn--primary aurora-tap"
                    onClick={() => void onCreate()}
                    disabled={!canEdit || creating}
                  >
                    {creating ? 'Enregistrement…' : 'Enregistrer'}
                  </button>
                ) : (
                  <button
                    type="button"
                    className="aurora-btn aurora-btn--ghost aurora-tap"
                    onClick={() => navigate('/canvas/new', { state: { from: '/canvas' } })}
                  >
                    Créer une session
                  </button>
                )}
              </div>
            )}          </UxStates>
        </div>
      </IonContent>
    </>
  );
}

function CanvasBlockEditor({
  block,
  onChange,
}: {
  block: CanvasBlock;
  onChange: (md: string) => void;
}) {
  const lastMd = useRef(block.content);
  useEffect(() => {
    lastMd.current = block.content;
  }, [block.content]);

  const editor = useEditor(
    {
      extensions: [StarterKit],
      content: block.content,
      immediatelyRender: true,
      editorProps: {
        attributes: {
          class: 'canvas-block tiptap',
          'data-canvas-block': block.id,
          role: 'textbox',
          'aria-multiline': 'true',
          'aria-label': `Bloc ${block.id} du canvas (markdown)`,
        },
      },
      shouldRerenderOnTransaction: false,
      onUpdate: ({ editor }) => {
        if (editor.isDestroyed) return;
        const json = editor.getJSON();
        const next = stripTipTapJson(json, lastMd.current);
        onChange(next);
      },
    },
    [block.id],
  );

  return <EditorContent editor={editor} />;
}
