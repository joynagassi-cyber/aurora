/**
 * Knowledge family (02 S6.1, 01 §4.3).
 *
 * /knowledge — semantic tree screen (React Flow + Dagre via the AD-10
 * `SemanticTreeRenderer` @aurora/ui: lazy level-1, incremental expand,
 * 30 fps on 1000 nodes [OQ-11]). Node colors: mastered/fragile/unknown
 * (NodeState, AD-6). Bridges hidden by default. /knowledge/:nodeId —
 * node detail (lazy deeper branches) with provenance drill-down (AD-11).
 *
 * AD-10: the tree is the REAL `SemanticTreeRenderer` (React Flow engine,
 * engine CSS + `-h` tokens provided by packages/ui). The knowledge mirror
 * is not wired yet (AD-7) → the engine renders its empty canvas + the
 * import CTA; it lays out nodes the moment the mirror yields them.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useParams } from 'react-router-dom';
import { SemanticTreeRenderer } from '@aurora/ui';
import type { RenderSemanticEdge, RenderSemanticNode } from '@aurora/ui';
import { useUiStateStore } from '../../state/ui-state';
import { UxStates, type UxStateFlags } from '../../ux-states';
import { useOnlineStatus } from '../../hooks/use-online';

/** Shared 6-state flags for the knowledge family. */
function knowledgeFlags(): {
  knowledgeExpanded: string;
  online: boolean;
  killed: boolean;
  flags: UxStateFlags;
} {
  const knowledgeExpanded = useUiStateStore((s) => s.knowledgeExpanded);
  const online = useOnlineStatus();
  const killed = useUiStateStore((s) => s.killed);
  const flags: UxStateFlags = { offline: !online, killed };
  return { knowledgeExpanded, online, killed, flags };
}

export function KnowledgePage() {
  const { knowledgeExpanded, online, killed, flags } = knowledgeFlags();

  // AD-7: the knowledge mirror is not wired yet → the tree is empty. The
  // renderer is still MOUNTED (React Flow canvas + controls); it renders
  // its empty state + the import CTA, and lays out real nodes on demand.
  const nodes: RenderSemanticNode[] = [];
  const edges: RenderSemanticEdge[] = [];

  return (
    <>
      <IonHeader>
        <IonTitle>Connaissance</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-knowledge>
          {/* G-M2: killed = re-hydrate from the local store (skeleton + resync). */}
          {killed ? (
            <UxStates
              state={{ status: 'empty' }}
              flags={flags}
              label="Arbre"
              emptyCta="Importer un concept"
            />
          ) : (
            <div
              className="knowledge-tree"
              data-semantic-tree="true"
              data-expanded={JSON.stringify(knowledgeExpanded)}
              data-online={online ? 'true' : 'false'}
            >
              {/* AD-10: React Flow + Dagre mounted via the @aurora/ui contract. */}
              <SemanticTreeRenderer nodes={nodes} edges={edges} fitView />
              {nodes.length === 0 && (
                <div className="knowledge-tree-cta">
                  <p>Aucun concept — importez un cours ou une fiche.</p>
                  <a
                    className="aurora-btn aurora-btn--primary aurora-tap"
                    href="/learn"
                  >
                    Importer
                  </a>
                </div>
              )}
              {!online && (
                <span className="aurora-badge" data-badge="offline">
                  Offline
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
  return (
    <>
      <IonHeader>
        <IonTitle>{nodeId}</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-node-id={nodeId}>
          <span className="breadcrumb">Connaissance &rsaquo; {nodeId}</span>
          <UxStates
            state={{ status: 'loading' }}
            flags={flags}
            label={`Nœud ${nodeId}`}
          >
            {/* Provenance drill-down (AD-11) + lazy deeper branches mount here. */}
            <div className="knowledge-node" data-state="loading">
              <p>Nœud « {nodeId} » — lecture locale + provenance.</p>
              <a
                className="aurora-btn aurora-btn--ghost aurora-tap"
                href="/learn"
              >
                Étudier ce concept
              </a>
            </div>
          </UxStates>
        </div>
      </IonContent>
    </>
  );
}
