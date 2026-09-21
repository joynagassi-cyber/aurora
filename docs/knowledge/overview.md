# Knowledge Module — Technical Page (Knowledge Base + Semantic Tree)

Status: `DESIGNED_NOT_IMPLEMENTED` (wave 2). Authority: ADR §14/§16/§25, spine AD-6/AD-10/
AD-11, `01-backend` §4.3, `03-sync` §4.2, `02-frontend` §5.1, `05-design-system` §3.6.

1. **Purpose** — the knowledge layer of record: documents/R2, semantic retrieval
   (FTS + pgvector), and the **hierarchical** semantic tree of knowledge ("a readable
   hierarchy of knowledge, not a second-brain web", ADR §14).
2. **Responsibilities** — document storage (R2) + metadata; FTS + vector retrieval
   (server-only, AD-12/F-09); tree structure & content (`SemanticNode/Edge/Bridge`),
   consolidation (merge duplicates when evidence is sufficient, ADR §14);
   **sole writer of `NodeState`** (mastered/fragile/forgotten — updated by consuming
   `ProgressEvidenceCreated`/`SkillStateChanged`, AD-6); `SourceRef` provenance (AD-11);
   tree versioning (`semantic_tree_version`, Knowledge-owned, NOT Event History, AD-6).
3. **Non-responsibilities** — rendering (React Flow is presentation only, AD-10/AD-6:
   "the engine is never the source of truth"); progress measurement (Progress emits,
   Knowledge writes state); generation of evidence rows (Progress only, F-07).
4. **User flows** — browse tree (level-by-level exploration, collapse/expand,
   prerequisite paths, a few contextualized cross-domain bridges — readability rule,
   ADR §14); progress view (fragile branches, consolidated branches, isolated notions,
   missing prerequisites, under-covered zones); provenance drill-down (document →
   page → passage, ADR §14/AD-11); search → context retrieval → study sheet hand-off.
5. **Architecture** — server: Postgres + pgvector + R2; device: **read-only mirror**
   (`semantic_nodes/edges/bridges`, `node_state`, `source_refs` — **no embedding
   column locally**, 03 §4.2 rule); UI: `SemanticTreeRenderer` contract only
   (`@xyflow/react` + `@dagrejs/dagre` inside `packages/ui`, AD-10 boundary).
6. **Domain model** — `SemanticNode` (concept/law/method/formula/example/application/
   skill; domain, subject, prerequisites), `SemanticEdge` (primary hierarchy:
   "depends on", "is a case of", "deepens", "applies", "leads to"), `SemanticBridge`
   (annotated cross-domain, secondary, on-demand), `NodeState`
   (collapsed/expanded/selected/focused/mastered/fragile/forgotten, ADR §25.3),
   `SourceRef` (document/page/passage/formula/result provenance, AD-11).
7. **Application services** — tree ingestion use-cases (from `CourseImported` /
   `DiscoveryItemCreated` / search results); consolidation (duplicate merge with
   evidence threshold); versioned snapshots.
8. **Ports / interfaces** — `KnowledgeBase` (retrieval; server-side), renderer contract
   `SemanticTreeRenderer` (02 §5.1 CONSO, 05 §3.6.6 DEF), `ObjectStorage` for R2
   documents.
9. **Adapters** — pgvector + FTS adapters (server), `packages/ui` React Flow
   implementation (lazy level-1 render, memoized nodes, incremental Dagre — 02 §9.2
   perf rule: 30 fps, 1000-node test), R2 presigned download (04 §3.2.2).
10. **Data model** — 01 §4.3 (documents, sources, semantic tables + pgvector +
    `semantic_tree_version`); local mirror rules (03 §4.2: read-only content mirror;
    `evidence_refs[]` in CRDT lists; no vectors).
11. **API** — retrieval & tree read via server jobs/Edge Functions; device never runs
    semantic retrieval locally (AD-12/F-09, 03 §4.2 note).
12. **Events** — consumes `CourseImported` (tree ingestion), `DiscoveryItemCreated`
    (tree links), `ProgressEvidenceCreated`/`SkillStateChanged` (writes `NodeState`),
    `ArtifactGenerated` (`SourceRef`) — all declared in the Knowledge Contract Pack.
13. **Jobs** — ingestion, embedding generation, consolidation, version snapshotting.
14. **Permissions** — none beyond user scope (read-heavy module).
15. **Security** — RLS per user; documents in private R2 (presigned only); corpus
    content is sensitive → data-policy-aware AI routing (ADR v1.7 §11).
16. **Offline behavior** — tree browsing offline from the mirror (root + level-1 first,
    deeper branches lazy — but **new retrieval requires connectivity**); `node_state`
    mirrors update downstream via PowerSync.
17. **Error handling** — retrieval miss → empty state with suggested actions; renderer
    degradation (02 §5.1: tree stays a tree, never a chaotic graph — readability rule
    enforced by layout + bridge-on-demand).
18. **Recovery** — mirror resync (03 §5.5); versioning allows restoring a prior tree
    state (`semantic_tree_version`, ADR §14 "évolution temporelle").
19. **Observability** — retrieval latency SLOs, tree size per user (perf budget 02
    §9.2), consolidation job SLOs.
20. **Tests** — AD-6 writer test (only Knowledge writes `node_state`), view-join static
    test (03 §7), 1000-node perf (02 §11), provenance completeness (AD-11: every
    significant concept carries a ref).
21. **Known limitations** — no local semantic retrieval by design (server-only); tree
    quality depends on corpus + consolidation jobs; G6 future option (large-scale
    Knowledge Graph via G6, ADR §25.9 — explicitly not V1).
22. **Dependencies** — R2/Postgres/pgvector, Progress (state writes), Learning
    (ingestion source), Discovery (links), renderer contracts (05).
23. **Future evolution** — G6-scale knowledge graph (evaluated, deferred, ADR §25.9);
    tree evolution analytics from `semantic_tree_version`.
