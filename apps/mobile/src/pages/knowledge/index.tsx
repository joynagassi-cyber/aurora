/**
 * Knowledge family (02 S6.1, 01 §4.3).
 *
 * /knowledge — semantic tree screen (React Flow + Dagre via the AD-10
 * `SemanticTreeRenderer` @aurora/ui: lazy level-1, incremental expand,
 * 30 fps on 1000 nodes [OQ-11]). Node colors: mastered/fragile/unknown
 * (NodeState, AD-6). Bridges hidden by default. /knowledge/:nodeId —
 * node detail (lazy deeper branches) with provenance drill-down (AD-11).
 *
 * AD-7 local-first (03 S3.1): the tree reads the LOCAL PowerSync mirror
 * of `semantic_nodes` / `semantic_edges` / `node_state` (0004 columns,
 * snake_case in `packages/data/powersync-schema.ts` L187–236). The
 * `embedding` column is NOT mirrored (0004 §4.2 rule, AD-12/F-09) —
 * full semantic retrieval stays server-side and requires connectivity
 * (`docs/knowledge/overview.md` §16). `?q=` therefore does a LOCAL
 * substring scan over `title` / `content` of mirrored nodes; it is
 * never FTS or vector on the device.
 *
 * AD-10: the tree is the REAL `SemanticTreeRenderer` (React Flow engine,
 * engine CSS + `-h` tokens provided by packages/ui). Offline / no
 * Supabase env → the mirror is empty (or stale = frozen tree) and the
 * import CTA stays, never an error (AD-7: no blank, no fake data).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useQuery } from '@tanstack/react-query';
import { useParams, useSearchParams } from 'react-router-dom';
import { SemanticTreeRenderer } from '@aurora/ui';
import type { RenderSemanticEdge, RenderSemanticNode } from '@aurora/ui';
import { useUiStateStore } from '../../state/ui-state';
import { UxStates, type UxStateFlags } from '../../ux-states';
import { useOnlineStatus } from '../../hooks/use-online';
import { useMobileData } from '../../query/context';
import { readKnowledgeMirror, searchKnowledgeMirror } from '../../lib/knowledge-repo';

/** Shared 6-state flags for the knowledge family. */
function knowledgeFlags(): {
  knowledgeExpanded: string;
  online: boolean;
  killed: boolean;
  flags: UxStateFlags;
} {
  const knowledgeExpanded = JSON.stringify(useUiStateStore((s) => s.knowledgeExpanded));
  const online = useOnlineStatus();
  const killed = useUiStateStore((s) => s.killed);
  const flags: UxStateFlags = { offline: !online, killed };
  return { knowledgeExpanded, online, killed, flags };
}

export function KnowledgePage() {
  const { knowledgeExpanded, online, killed, flags } = knowledgeFlags();
  const [searchParams, setSearchParams] = useSearchParams();
  /**
   * Cross-page query intake (`?q=`, navigation-and-page-composition.md):
   * e.g. the agent transcript's « Open » action drops a quoted snippet
   * here (`/knowledge?q=…`). AD-7/AD-12: the search is a LOCAL substring
   * scan over mirrored `title` / `content` (knowledge-repo.ts) — full
   * semantic retrieval (FTS / pgvector, 0004) is server-only and needs
   * connectivity (`docs/knowledge/overview.md` §16), so when the query
   * matches nothing locally we say so honestly, we never fake a result.
   */
  const query = searchParams.get('q');

  // AD-7 local-first: read the mirror (never the network). One pass per
  // mount / 60s staleTime — the repo re-reads on `watch`-driven
  // invalidation of the shared local store (same channel as ascent).
  const mirrorProvider = useMobileData();
  const store = mirrorProvider.store;
  // AD-7 / 03 S8.1: when the provider was built without a local engine
  // (tests, or a degenerate boot), the mirror is empty — the import CTA
  // stays, never an error. `enabled` guards the `store!` non-null.
  const mirror = useQuery({
    queryKey: ['knowledge', 'mirror'],
    queryFn: () => (store ? readKnowledgeMirror(store) : { nodes: [], edges: [] }),
    staleTime: 60_000,
    retry: 1,
    enabled: store !== undefined,
  });

  const allNodes: RenderSemanticNode[] = mirror.data?.nodes ?? [];
  const allEdges: RenderSemanticEdge[] = mirror.data?.edges ?? [];

  // `?q=` narrows the tree to the matching nodes (+ their edges) — not a
  // separate result list. The full tree stays available below when the
  // banner is dismissed.
  let nodes: RenderSemanticNode[] = allNodes;
  let edges: RenderSemanticEdge[] = allEdges;
  let matchCount = 0;
  if (query && allNodes.length > 0 && store) {
    const matches = searchKnowledgeMirror(store, query);
    matchCount = matches.length;
    const matchedIds = new Set(matches.map((m) => m.id));
    nodes = matches;
    // keep edges whose BOTH endpoints are in the matched set (an edge to a
    // filtered-out node would reference a missing node in the layout).
    edges = allEdges.filter(
      (e) => matchedIds.has(e.source) && matchedIds.has(e.target),
    );
  }

  const hasMirrorData = allNodes.length > 0;

  return (
    <>
      <IonHeader>
        <IonTitle>Connaissance</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-knowledge>
          {query && (
            <div className="knowledge-query-banner" data-query={query}>
              <span>
                {hasMirrorData
                  ? matchCount > 0
                    ? `Recherche locale : « ${query} » — ${matchCount} nœud(s) trouvé(s) sur le miroir.`
                    : `Recherche locale : « ${query} » — aucun résultat sur le miroir (recherche sémantique complète = en ligne, 01 §4.3).`
                  : `Recherche locale : « ${query} » — miroir vide, importez d'abord un cours ou une fiche.`}
              </span>
              <a
                className="aurora-btn aurora-btn--ghost aurora-tap"
                href="/learn"
                onClick={(e) => {
                  e.preventDefault();
                  setSearchParams((prev: URLSearchParams) => {
                    const next = new URLSearchParams(prev);
                    next.delete('q');
                    return next;
                  });
                }}
              >
                Effacer
              </a>
            </div>
          )}
          {/* G-M2: killed = re-hydrate from the local store (skeleton + resync). */}
          {killed ? (
            <UxStates
              state={{ status: 'empty' }}
              flags={{ ...flags, emptyCta: "Importer un concept" }}
              label="Arbre"
            />
          ) : (
            <div
              className="knowledge-tree"
              data-semantic-tree="true"
              data-expanded={knowledgeExpanded}
              data-online={online ? 'true' : 'false'}
            >
              {/* AD-10: React Flow + Dagre mounted via the @aurora/ui contract,
                  fed by the LOCAL mirror (AD-7). Empty / stale mirror = the
                  canvas stays, never a crash (05 §3.6 / AD-8). */}
              <SemanticTreeRenderer nodes={nodes} edges={edges} fitView />
              {!hasMirrorData && (
                <div className="knowledge-tree-cta">
                  <p>Aucun concept sur le miroir local — importez un cours ou une fiche.</p>
                  <a
                    className="aurora-btn aurora-btn--primary aurora-tap"
                    href="/learn"
                  >
                    Importer
                  </a>
                </div>
              )}
              {!online && hasMirrorData && (
                <span className="aurora-badge" data-badge="offline">
                  Hors ligne — arbre figé sur le dernier miroir connu (AD-7)
                </span>
              )}
            </div>
          )}
        </div>
      </IonContent>
    </>
  );
}

export function KnowledgeNodePage() {
  const { nodeId } = useParams<{ nodeId: string }>();
  const { flags } = knowledgeFlags();
  const mirrorProvider = useMobileData();
  const store = mirrorProvider.store;

  // Resolve the node's READABLE name from the local mirror (AD-7). The
  // `concept` field already carries title → content-prefix → id (knowledge-repo.ts).
  const mirror = useQuery({
    queryKey: ['knowledge', 'mirror', nodeId],
    queryFn: () => (store ? readKnowledgeMirror(store) : { nodes: [], edges: [] }),
    staleTime: 60_000,
    enabled: store !== undefined,
  });

  // The node title: `concept` (readable) from the mirror, fallback `nodeId`.
  const nodeTitle =
    mirror.data?.nodes.find((n) => n.id === nodeId)?.concept ?? nodeId;

  return (
    <>
      <IonHeader>
        <IonTitle>{mirror.data ? nodeTitle : 'Nœud'}</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-node-id={nodeId} data-node-title={nodeTitle}>
          <span className="breadcrumb">Connaissance &rsaquo; {nodeTitle}</span>
          <UxStates
            state={
              mirror.data && mirror.data.nodes.length > 0
                ? { status: 'success', data: undefined }
                : { status: 'empty' }
            }
            flags={{ ...flags, emptyCta: 'Étudier ce concept' }}
            label={`Nœud ${nodeTitle}`}
          >
            {/* Provenance drill-down (AD-11) + lazy deeper branches mount here. */}
            <div className="knowledge-node">
              <p>Nœud « {nodeTitle} » — lecture locale + provenance.</p>
              <a className="aurora-btn aurora-btn--ghost aurora-tap" href="/learn">
                Étudier ce concept
              </a>
            </div>
          </UxStates>
        </div>
      </IonContent>
    </>
  );
}
