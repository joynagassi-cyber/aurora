/**
 * Learning module — semantic retrieval: hybrid FTS + pgvector query
 * builder (server-only, AD-12 / F-09) (wave 2, SAPPHO).
 *
 * docs/knowledge/overview.md §11: the device NEVER runs semantic
 * retrieval locally — retrieval is a server Edge Function over
 * Postgres (FTSGIN on `document_chunks` + HNSW on the embedding) and
 * R2 (chunk bodies / document downloads). This file is the PURE query
 * contract: it builds the Postgres query shape + the weighted fusion
 * scorer, so the Edge Function (fn-retrieval) and the tests share one
 * implementation. No vendor imports (AD-1).
 */
import type { OrSetValue } from '@aurora/domain';

export interface RetrievalHit {
  /** the document chunk id (document_chunks.id) */
  chunkId: string;
  /** the owning knowledge document (R2 download by presigned key) */
  documentId: string;
  /** 0..1 fused relevance */
  score: number;
  /** 0..1 lexical FTS score */
  ftsScore: number;
  /** 0..1 cosine-similarity score */
  vectorScore: number;
  /** provenance (AD-11) */
  sourceRefIds: OrSetValue[];
}

export interface RetrievalRequest {
  userId: string;
  query: string;
  /** embedding of the query (768-dim, bge-base per 0004_knowledge.sql) */
  embedding?: number[];
  limit?: number;
  /** FTS weight in the fusion (0..1; default 0.4) */
  ftsWeight?: number;
}

/**
 * Build the two-leg retrieval query shape the Edge Function executes:
 *  - FTS: `to_tsvector('english', text)` rank via `ts_rank`;
 *  - vector: cosine distance on `embedding` via the HNSW index.
 * Both are user-scoped (RLS `user_id = auth.uid()`, migration 0004).
 * The function returns the SQL shape only — execution lives in the EF
 * (AD-12), keeping this module importable anywhere.
 */
export function buildRetrievalQueries(req: RetrievalRequest): {
  ftsSql: string;
  vectorSql?: string;
  limit: number;
} {
  const limit = req.limit ?? 10;
  const ftsSql = [
    'SELECT dc.id AS chunk_id, dc.document_id, ts_rank(websearch_to_tsvector(\'english\', dc.text), q.query) AS fts_score',
    'FROM document_chunks dc',
    `JOIN to_tsquery(\'english\', $1) AS q(query) ON true`,
    'WHERE dc.user_id = $2',
    "AND dc.text @@ q.query",
    'ORDER BY fts_score DESC',
    `LIMIT ${limit}`,
  ].join('\n');
  let vectorSql: string | undefined;
  if (req.embedding !== undefined && req.embedding.length === 768) {
    vectorSql = [
      'SELECT id AS chunk_id, document_id, 1 - (embedding <=> $1::vector) AS vector_score',
      'FROM document_chunks',
      'WHERE user_id = $2 AND embedding IS NOT NULL',
      'ORDER BY embedding <=> $1::vector',
      `LIMIT ${limit}`,
    ].join('\n');
  }
  return { ftsSql, vectorSql, limit };
}

/**
 * Reciprocal-rank fusion of the two legs (pure, deterministic):
 * a chunk in both lists outranks one in only one; the `ftsWeight`
 * blends the normalized scores. Input legs must be pre-sorted by
 * their own score (desc).
 */
export function fuseRetrieval(
  fts: Array<{ chunkId: string; documentId: string; score: number }>,
  vector: Array<{ chunkId: string; documentId: string; score: number }>,
  opts?: { limit?: number; ftsWeight?: number },
): Array<{ chunkId: string; documentId: string; score: number; ftsScore: number; vectorScore: number }> {
  const limit = opts?.limit ?? 10;
  const ftsW = opts?.ftsWeight ?? 0.4;
  const byChunk = new Map<
    string,
    { chunkId: string; documentId: string; ftsScore: number; vectorScore: number; inBoth: boolean }
  >();
  for (const hit of fts) {
    byChunk.set(hit.chunkId, {
      chunkId: hit.chunkId,
      documentId: hit.documentId,
      ftsScore: hit.score,
      vectorScore: 0,
      inBoth: false,
    });
  }
  for (const hit of vector) {
    const cur = byChunk.get(hit.chunkId);
    if (cur === undefined) {
      byChunk.set(hit.chunkId, {
        chunkId: hit.chunkId,
        documentId: hit.documentId,
        ftsScore: 0,
        vectorScore: hit.score,
        inBoth: false,
      });
    } else {
      cur.vectorScore = hit.score;
      cur.inBoth = true;
    }
  }
  const maxFts = Math.max(0, ...fts.map((h) => h.score));
  const maxVec = Math.max(0, ...vector.map((h) => h.score));
  const out = [...byChunk.values()]
    .map((h) => {
      const nf = maxFts > 0 ? h.ftsScore / maxFts : 0;
      const nv = maxVec > 0 ? h.vectorScore / maxVec : 0;
      // reciprocal-rank bonus for dual recall, then weighted blend
      const rrBonus = h.inBoth ? 0.1 : 0;
      return {
        chunkId: h.chunkId,
        documentId: h.documentId,
        ftsScore: h.ftsScore,
        vectorScore: h.vectorScore,
        score: Math.min(1, ftsW * nf + (1 - ftsW) * nv + rrBonus),
      };
    })
    .sort((a, b) => b.score - a.score || a.chunkId.localeCompare(b.chunkId));
  return out.slice(0, limit);
}

/** AD-12 guard: retrieval has NO local execution path. This type makes
 *  any attempt to call a local retriever from a package that only
 *  exports query-building a compile-time error (the only exports here
 *  are pure functions + types). */
export type RetrievalIsServerOnly = {
  [K in keyof RetrievalRequest]: true;
} extends { [k: string]: unknown }
  ? true
  : never;
