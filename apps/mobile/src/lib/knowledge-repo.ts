/**
 * Knowledge local-mirror repo (AD-7, 02 §5.1 CONSO side).
 *
 * The PowerSync mirror stores `semantic_nodes` / `semantic_edges` in
 * SNAKE_CASE (packages/data/powersync-schema.ts L187–212; 0004 columns),
 * with JSONB-in-TEXT (e.g. `crdt_*`). The renderer contracts
 * (`@aurora/ui` `RenderSemanticNode` / `RenderSemanticEdge`) are the
 * AD-10 DEF-side projections — this module translates between them,
 * confined to the provider layer (as ascent-repo.ts does for A2).
 *
 * AD-7 local-first: the screen reads ONLY through `store()` here —
 * no network. AD-12/F-09: the `embedding` column is NOT mirrored
 * (0004 §4.2 rule) — retrieval stays server-only; this module exposes
 * local substring search over `title` / `content` only, which is
 * honest: "recherche sémantique complète = online requis".
 */
import type { LocalStore } from '@aurora/data';
import type { RenderSemanticNode, RenderSemanticEdge, TreeRelation } from '@aurora/ui';
import type { NodeState } from '@aurora/domain';

type RawRow = Record<string, unknown>;

/** Column names on the mirror side (0004 snake_case, PowerSync text). */
const NODE = 'semantic_nodes';
const EDGE = 'semantic_edges';
const STATE = 'node_state';

/** 0004 relation (CHECK) → the `@aurora/ui` `TreeRelation` union. */
function mapRelation(raw: unknown): TreeRelation {
  switch (raw) {
    case 'depends_on':
      return 'dependsOn';
    case 'is_a_case_of':
      return 'isCaseOf';
    case 'deepens':
      return 'deepens';
    case 'applies':
      return 'applies';
    case 'leads_to':
      return 'leadsTo';
    default:
      // 0004 `example_of` (domain `example-of`) has no `TreeRelation`
      // union member yet (contracts.ts L34–39) → falls back to 'applies'.
      return 'applies';
  }
}

/**
 * Snapshot of the local mirror — one read (no `watch`; the screen calls
 * this inside `useQuery` + staleTime 60s, same as ascent). Stale =
 * frozen tree, never an error (AD-7).
 */
export function readKnowledgeMirror(store: LocalStore): {
  nodes: RenderSemanticNode[];
  edges: RenderSemanticEdge[];
} {
  // node_state is the AD-6 domain truth (mastered / fragile / forgotten).
  // The mirror's `state` column carries both view + domain states; we map
  // ONLY the 3 domain values to `NodeState.learningState`, default 'not-yet'.
  const stateByNode = new Map<string, NodeState['learningState']>();
  for (const row of store.allRows(STATE) as RawRow[]) {
    const nodeId = typeof row.node_id === 'string' ? row.node_id : undefined;
    if (!nodeId) continue;
    const raw = row.state;
    if (raw === 'mastered') stateByNode.set(nodeId, 'mastered');
    else if (raw === 'fragile') stateByNode.set(nodeId, 'fragile');
    else if (raw === 'forgotten') stateByNode.set(nodeId, 'forgotten');
  }

  const nodeIds = new Set<string>();
  const nodes: RenderSemanticNode[] = [];

  for (const row of store.allRows(NODE) as RawRow[]) {
    const id = typeof row.id === 'string' ? row.id : undefined;
    if (!id) continue;
    nodeIds.add(id);
    const title = typeof row.title === 'string' ? row.title : '';
    const content = typeof row.content === 'string' ? row.content : '';
    nodes.push({
      id,
      concept: title || content.slice(0, 80) || id.slice(0, 8),
      state: {
        userId: '',
        nodeId: id,
        learningState: stateByNode.get(id) ?? 'not-yet',
        setAt: typeof row.created_at === 'string' ? row.created_at : '',
      },
      hasChildren: false,
    });
  }

  // `hasChildren`: an edge whose `source_id` is a node id → that node is
  // a parent. Set AFTER we know all node ids (edge source might reference
  // a node not yet mirrored — skip silently, AD-7 frozen mirror).
  const edges: RenderSemanticEdge[] = [];
  const nodeById = new Map<string, RenderSemanticNode>();
  for (const n of nodes) nodeById.set(n.id, n);
  for (const row of store.allRows(EDGE) as RawRow[]) {
    const id = typeof row.id === 'string' ? row.id : undefined;
    const sourceId = typeof row.source_id === 'string' ? row.source_id : undefined;
    const targetId = typeof row.target_id === 'string' ? row.target_id : undefined;
    if (!id || !sourceId || !targetId) continue;
    // Both endpoints must be mirrored nodes — a dangling reference is a
    // stale-mirror artifact; we never invent a node (AD-7).
    if (!nodeIds.has(sourceId) || !nodeIds.has(targetId)) continue;
    if (nodeById.get(sourceId)) nodeById.get(sourceId)!.hasChildren = true;
    edges.push({
      id,
      source: sourceId,
      target: targetId,
      relation: mapRelation(row.relation),
    });
  }

  return { nodes, edges };
}

/**
 * Local substring search over mirrored `title` / `content` (AD-7 / AD-12).
 *
 * NOT FTS, NOT vector — the mirror has no `embedding` column (0004 §4.2),
 * so full semantic retrieval is server-only and requires connectivity
 * (`docs/knowledge/overview.md` §16). This is an honest local scan:
 * case-insensitive substring on two TEXT fields. `q` shorter than 2 chars
 * returns `[]` (too short to be meaningful, avoids matching everything).
 */
export function searchKnowledgeMirror(
  store: LocalStore,
  q: string,
): RenderSemanticNode[] {
  const needle = q.trim().toLowerCase();
  if (needle.length < 2) return [];
  const { nodes } = readKnowledgeMirror(store);
  // The `concept` field already carries `title || content-prefix || id`.
  // We search on the raw mirror again to get the full content, not just
  // the 80-char prefix. Re-read is cheap (SQLite, local, one pass).
  const byId = new Map<string, { title: string; content: string }>();
  for (const row of store.allRows(NODE) as RawRow[]) {
    const id = typeof row.id === 'string' ? row.id : undefined;
    if (!id) continue;
    byId.set(id, {
      title: typeof row.title === 'string' ? row.title : '',
      content: typeof row.content === 'string' ? row.content : '',
    });
  }
  return nodes.filter((n) => {
    const raw = byId.get(n.id);
    if (!raw) return false;
    const hay = (raw.title + ' ' + raw.content).toLowerCase();
    return hay.includes(needle);
  });
}
