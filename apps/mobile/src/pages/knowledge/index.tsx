/**
 * Knowledge family (02 S6.1, 01 §4.3).
 *
 * /knowledge — semantic tree screen (React Flow + Dagre via the AD-10
 * `SemanticTreeRenderer` @aurora/ui: lazy level-1, incremental expand,
 * 30 fps on 1000 nodes [OQ-11]). Node colors: mastered/fragile/unknown
 * (NodeState, AD-6). Bridges hidden by default. /knowledge/:nodeId —
 * node detail (lazy deeper branches) with provenance drill-down (AD-11).
 *
 * Full 6 UX states + killed. Tree expansion state = ui-state. Server
 * retrieval ONLY when online (AD-12) — offline renders the last-known
 * tree from the local mirror. No knowledge mirror wired yet → the tree
 * container ships a clean empty + import CTA (never fake nodes, AD-7).
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useParams } from 'react-router-dom';
import { useUiStateStore } from '../../state/ui-state';
import { UxStates, type UxStateFlags } from '../../ux-states';
import { useOnlineStatus } from '../../hooks/use-online';

export function KnowledgePage() {
  const { knowledgeExpanded, online, flags } = knowledgeFlags();
  return (
    <>
      <IonHeader>
        <IonTitle>Connaissance</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-knowledge>
          <UxStates
            state={{ status: 'empty' }}
            flags={flags}
            label="Arbre"
            emptyCta="Importer un concept"
          >
            {/* React Flow + Dagre mount point (AD-10 SemanticTreeRenderer,
                packages/ui; lazy level-1, incremental Dagre, 30 fps). */}
            <div
              className="knowledge-tree"
              data-semantic-tree="true"
              data-expanded={JSON.stringify(knowledgeExpanded)}
              data-online={online ? 'true' : 'false'}
            >
              <p className="knowledge-tree-empty">
                Arbre vide — import CTA
              </p>
            </div>
          </UxStates>
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
          {/* Provenance drill-down (AD-11) + lazy deeper branches mount here. */}
          <div className="knowledge-node" data-state="loading">
            <p>Nœud « {nodeId} » — lecture locale + provenance.</p>
            <a className="aurora-btn aurora-btn--ghost aurora-tap" href="/learn">
              Étudier ce concept
            </a>
          </div>
        </div>
      </IonContent>
    </>
  );
}

/** Shared 6-state flags for the knowledge family (data-less → honest empty). */
function knowledgeFlags() {
  const knowledgeExpanded = useUiStateStore((s) => s.knowledgeExpanded);
  const online = useOnlineStatus();
  const killed = useUiStateStore((s) => s.killed);
  const flags: UxStateFlags = { offline: !online, killed };
  return { knowledgeExpanded, online, flags };
}
