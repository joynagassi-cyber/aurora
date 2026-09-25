/**
 * Knowledge family (02 S6.1, 01 §4.3).
 *
 * /knowledge — semantic tree screen (React Flow + Dagre, AD-10
 * SemanticTreeRenderer: lazy level-1, incremental expand, 30fps on 1000
 * nodes [OQ-11]). Node colors: mastered=green, fragile=yellow,
 * unknown=gray (NodeState, AD-6). Bridges hidden by default.
 * /knowledge/:nodeId — node detail (lazy deeper branches, 02 §9.2) with
 * provenance drill-down (AD-11). "study" CTA → /learn/:id
 * (context-preserving, 02 S6.2). Tree expansion state = ui-state.
 *
 * Server retrieval ONLY when online (AD-12) — the offline state renders
 * the last-known tree from the local mirror.
 */
import { IonContent, IonHeader, IonTitle } from '@ionic/react';
import { useParams } from 'react-router-dom';
import { useUiStateStore } from '../../state/ui-state';

export function KnowledgePage() {
  const expanded = useUiStateStore((s) => s.knowledgeExpanded);

  return (
    <>
      <IonHeader>
        <IonTitle>Connaissance</IonTitle>
      </IonHeader>
      <IonContent>
        {/* React Flow + Dagre mount point (P4: packages/ui AD-10 renderer;
            this page is the feature slice, the renderer lives in @aurora/ui). */}
        <div data-semantic-tree="true" data-expanded={JSON.stringify(expanded)} data-state="empty">
          Arbre vide — import CTA
        </div>
      </IonContent>
    </>
  );
}

export function KnowledgeNodePage() {
  const { nodeId } = useParams<{ nodeId: string }>();
  return (
    <>
      <IonHeader>
        <IonTitle>{nodeId}</IonTitle>
      </IonHeader>
      <IonContent>
        <div data-node-id={nodeId} data-state="loading">
          <a href="/learn">Étudier ce concept</a>
        </div>
      </IonContent>
    </>
  );
}
