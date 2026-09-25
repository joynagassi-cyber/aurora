/**
 * @aurora/learning — test suite (node built-in test runner, per-feature).
 *
 * Pure-domain tests: no vendor deps, no DOM. Each test is one
 * acceptance slice of a feature (wave 2 delivery rule #4).
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  DefaultCourseImportPipeline,
  type CourseImportUpload,
} from '../src/course-import.ts';
import { fsrsNext, FlashcardService, buildFsrsTickPayload } from '../src/fsrs.ts';
import { detectMirrorFindings, DefaultMirrorCognitiveService } from '../src/mirror-cognitive.ts';
import {
  detectRecurringErrors,
  nextRevisionDifficulty,
  QcmService,
} from '../src/qcm.ts';
import { checkFidelity, sheetPrompt, StudySheetService } from '../src/study-sheets.ts';
import { checkTreeInvariants, lazyExpand, treeLayout } from '../src/semantic-tree.ts';
import { buildRetrievalQueries, fuseRetrieval } from '../src/retrieval.ts';
import type {
  JobDispatcherPort,
  SemanticNode,
  SemanticEdge,
  AIPipelinePort,
} from '@aurora/domain';

// ---- feature 1: course import (camera -> R2 -> job dispatch) ----

const fakeJobs: JobDispatcherPort = {
  async dispatch(req) {
    assert.equal(typeof req.idempotencyKey, 'string');
    return { jobId: 'job-1', status: 'pending' };
  },
  async getJob() {
    return null;
  },
};

const fakeStorage = {
  async upload(_artifactId: string, r2Key: string, _body: Uint8Array, _contentType: string) {
    return { r2Key, sizeBytes: 10 };
  },
  async signedUrl() {
    return 'https://signed.example/x';
  },
};

test('course-import: deterministic R2 key + idempotent course_import dispatch', async () => {
  const pipeline = new DefaultCourseImportPipeline(fakeJobs, fakeStorage);
  const upload: CourseImportUpload = {
    courseId: 'course-1',
    userId: 'user-1',
    r2Key: '',
    contentType: 'application/pdf',
    sizeBytes: 10,
    source: 'camera',
    course: { title: 'Mecanique des fluides', userId: 'user-1', tags: ['fluids'] },
    createdAt: '2026-09-25T00:00:00Z',
  };
  const a = await pipeline.capture(upload, new Uint8Array(10));
  const b = await pipeline.capture(upload, new Uint8Array(10));
  assert.equal(a.r2Key, b.r2Key); // idempotent (AD-8)
  assert.match(a.r2Key, /^courses\/user-1\/course-1\/mecanique-des-fluides-10\.pdf$/);
  const job = await pipeline.dispatchImport(a.uploadId);
  assert.equal(job.jobId, 'job-1');
});

// ---- feature 2: FSRS (server-side, deterministic) ----

test('fsrs: new card "Good" lands on the 5-min learning step', () => {
  const out = fsrsNext({ state: null, rating: 3, elapsedDays: 0, now: 1_700_000_000_000 });
  assert.equal(out.lapses, 0);
  assert.equal(out.due, 1_700_000_000_000 + 5 * 60_000);
  assert.ok(out.stability >= 1 && out.stability <= 10);
});

test('fsrs: failure increments lapses and shrinks stability', () => {
  const out = fsrsNext({
    state: { stability: 5, difficulty: 4, lapses: 0 },
    rating: 0,
    elapsedDays: 3,
    now: 1_700_000_000_000,
  });
  assert.equal(out.lapses, 1);
  assert.ok(out.stability < 5);
});

test('fsrs: FlashcardService returns a well-formed FlashcardReviewed event', async () => {
  const svc = new FlashcardService({
    async review(_cardId: string, _userId: string, _rating: number, ts: number) {
      return {
        learningItemId: 'li-1',
        userId: 'user-1',
        due: ts + 86_400_000,
        stability: 3,
        difficulty: 4,
        lapses: 0,
        lastReviewedAt: new Date(ts).toISOString(),
        updatedAt: new Date(ts).toISOString(),
      };
    },
    async due() {
      return [];
    },
  });
  const { event } = await svc.review('card-1', 'user-1', 3);
  assert.equal(event.type, 'FlashcardReviewed');
  assert.equal(event.payload.cardId, 'card-1');
  assert.equal(event.payload.fsrsState.stability, 3);
  assert.ok(buildFsrsTickPayload('user-1', [{ v: 'c1', ts: 1, c: 'cl' }]).courseIds.includes('c1'));
});

// ---- feature 3: QCM (progressive ladder + recurring-error detection) ----

const attempts = [
  { learningItemId: 'li-1', userId: 'u', correct: false, confidence: 0.4, difficulty: 'recall' as const, at: 't' },
  { learningItemId: 'li-1', userId: 'u', correct: false, confidence: 0.3, difficulty: 'application' as const, at: 't' },
  { learningItemId: 'li-2', userId: 'u', correct: true, confidence: 0.9, difficulty: 'recall' as const, at: 't' },
];

test('qcm: item failed on 2 distinct difficulties is flagged recurring', () => {
  const clusters = detectRecurringErrors(attempts);
  assert.equal(clusters.length, 1);
  assert.equal(clusters[0]!.itemIds[0], 'li-1');
  assert.equal(clusters[0]!.count, 2);
});

test('qcm: skill level maps to the next revision difficulty', () => {
  assert.equal(nextRevisionDifficulty({ level: 'comprehended' } as never), 'comprehension');
  assert.equal(nextRevisionDifficulty({ level: 'novel-problem' } as never), 'synthesis');
});

test('qcm: generation prompt keeps the corpus text dominant', () => {
  const svc = new QcmService();
  const p = svc.prompt([{ content: 'E = mc^2', corpusText: 'L\'energie est E=mc^2' }], 'application');
  assert.match(p, /application-level QCM/);
  assert.match(p, /E=mc\^2/);
});

// ---- feature 4: study sheets (7 structures + fidelity check) ----

test('study-sheets: fidelity passes when every corpus sentence survives', () => {
  const corpus = 'The law of momentum is conserved. Friction converts motion into heat.';
  const out = checkFidelity({ content: '## Summary. The law of momentum is conserved. Friction converts motion into heat.', corpusText: corpus });
  assert.equal(out.ok, true);
  assert.deepEqual(out.missing, []);
});

test('study-sheets: dropped corpus sentences fail the fidelity gate', () => {
  const out = checkFidelity({
    content: 'Only momentum is kept here.',
    corpusText: 'The law of momentum is conserved. Friction converts motion into heat.',
  });
  assert.equal(out.ok, false);
  assert.equal(out.missing.length, 2); // both corpus sentences are gone
  assert.equal(sheetPrompt('formulas', [{ id: '1', content: 'F=ma' }]).includes('formulas'), true);
  void StudySheetService;
});

// ---- feature 5: Mirror Cognitive Mode (gap detector) ----

test('mirror: claims pointing at not-yet nodes produce gap findings', () => {
  const out = detectMirrorFindings(
    [{ text: "I think X is... um", nodeId: 'n1' }, { text: 'Y is solid', nodeId: 'n2' }],
    [
      { id: 'n1', label: 'X', learningState: 'not-yet' },
      { id: 'n2', label: 'Y', learningState: 'mastered' },
    ],
  );
  assert.equal(out.findings.length, 1);
  assert.equal(out.findings[0]!.kind, 'gap');
  assert.deepEqual(out.weakNodes, ['n1']);
});

test('mirror: analyze dispatches a persisted agent_run job', async () => {
  const seen: string[] = [];
  const jobs: JobDispatcherPort = {
    async dispatch(req) {
      seen.push(req.jobKind);
      return { jobId: 'job-m', status: 'pending' };
    },
    async getJob() {
      return {
        id: 'job-m', userId: 'u1', kind: 'agent_run', status: 'done', attempts: 1,
        dueAt: 't', idempotencyKey: 'k', updatedAt: 't',
        payload: {
          report: { userId: 'u1', claimsCount: 1, findings: [], weakNodes: [], createdAt: 't' },
        },
      };
    },
  };
  const svc = new DefaultMirrorCognitiveService(jobs, {} as AIPipelinePort);
  const res = await svc.analyze({ userId: 'u1', transcript: 't', claims: [], nodes: [] });
  assert.deepEqual(seen, ['agent_run']);
  assert.equal(res.jobId, 'job-m');
  const report = await svc.report('job-m', 'u1');
  assert.equal(report?.claimsCount, 1);
});

// ---- feature 6: semantic tree (invariants + lazy layout) ----

function node(id: string, label: string, opts?: { parentId?: string; isRoot?: boolean }): SemanticNode {
  return {
    id, userId: 'u', kind: 'concept', label,
    parentId: opts?.parentId, isRoot: opts?.isRoot,
    sourceRefIds: [], evidenceRefIds: [],
    createdAt: 't', updatedAt: 't',
  };
}

function edge(id: string, from: string, to: string, relation: SemanticEdge['relation']): SemanticEdge {
  return { id, userId: 'u', fromNodeId: from, toNodeId: to, relation, createdAt: 't', updatedAt: 't' };
}

test('semantic-tree: well-formed tree passes the invariants', () => {
  const nodes = [node('r', 'Root', { isRoot: true }), node('a', 'A', { parentId: 'r' }), node('b', 'B', { parentId: 'a' })];
  const res = checkTreeInvariants(nodes, [edge('e1', 'r', 'a', 'deepens')]);
  assert.equal(res.ok, true);
  assert.deepEqual(res.violations, []);
});

test('semantic-tree: unreachable node is a violation', () => {
  const nodes = [node('r', 'Root', { isRoot: true }), node('x', 'Orphan')];
  const res = checkTreeInvariants(nodes, []);
  assert.equal(res.ok, false);
});

test('semantic-tree: lazy expand stops at the requested depth', () => {
  const nodes = [node('r', 'Root', { isRoot: true }), node('a', 'A', { parentId: 'r' }), node('b', 'B', { parentId: 'a' })];
  assert.deepEqual(lazyExpand(nodes, [], 1), ['r', 'a']);
});

test('semantic-tree: layout is deterministic and row-ordered', () => {
  const nodes = [node('r', 'Root', { isRoot: true }), node('a', 'A', { parentId: 'r' }), node('b', 'B', { parentId: 'a' })];
  const l1 = treeLayout(nodes, []);
  const l2 = treeLayout(nodes, []);
  assert.deepEqual(l1, l2);
  const byId = new Map(l1.nodes.map((n) => [n.id, n]));
  assert.ok(byId.get('r')!.y < byId.get('a')!.y);
  assert.ok(byId.get('a')!.y < byId.get('b')!.y);
});

// ---- feature 7: retrieval (FTS + vector, server-only) ----

test('retrieval: query builder emits both legs and respects user scoping', () => {
  const q = buildRetrievalQueries({ userId: 'u', query: 'pythagoras', embedding: new Array(768).fill(0.1) });
  assert.match(q.ftsSql, /user_id = \$2/);
  assert.match(q.ftsSql, /ts_rank/);
  assert.match(q.vectorSql!, /embedding <=>/);
  const noVec = buildRetrievalQueries({ userId: 'u', query: 'x' });
  assert.equal(noVec.vectorSql, undefined);
});

test('retrieval: fusion ranks dual-recall chunks first', () => {
  const fused = fuseRetrieval(
    [{ chunkId: 'c1', documentId: 'd1', score: 0.9 }, { chunkId: 'c2', documentId: 'd1', score: 0.5 }],
    [{ chunkId: 'c1', documentId: 'd1', score: 0.8 }, { chunkId: 'c3', documentId: 'd2', score: 0.7 }],
    { limit: 10 },
  );
  assert.equal(fused[0]!.chunkId, 'c1');
  assert.ok(fused[0]!.score > fused[1]!.score);
});
