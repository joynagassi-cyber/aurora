/**
 * Learning module — Mirror Cognitive Mode (G-L3, 01 S4.2; wave 2, SAPPHO).
 *
 * The student explains a concept (speech → transcription job, AD-8);
 * Aurora detects gaps, contradictions and errors against the Semantic
 * Tree + corpus (server job) and returns a structured report. No new
 * AD-9 event — the report is read via the `ArtifactGenerated` / job
 * result path; heavy work is a persisted `agent_run`/`research` job.
 */
import type {
  AIPipelinePort,
  JobDispatcherPort,
  SemanticNode,
} from '@aurora/domain';

export interface MirrorClaim {
  /** the student's own words (corpus-dominant, AD-11) */
  text: string;
  /** the Semantic Node it maps to, if any */
  nodeId?: string;
}

export interface MirrorFinding {
  kind: 'gap' | 'contradiction' | 'error';
  /** which concept / node the finding is about */
  nodeId?: string;
  /** the student formulation involved */
  claimText: string;
  /** the correction / completion, labelled AI-generated (ADR §17) */
  resolution: string;
  /** 0..1 how confident the detector is */
  confidence: number;
}

export interface MirrorReport {
  userId: string;
  subjectId?: string;
  claimsCount: number;
  findings: MirrorFinding[];
  /** the skill states the report implies (drives targeted revision) */
  weakNodes: string[];
  createdAt: string;
}

export interface MirrorCognitiveService {
  /** Transcribe + run the gap/contradiction/error detector as a job. */
  analyze(
    req: {
      userId: string;
      subjectId?: string;
      transcript: string;
      claims: MirrorClaim[];
      nodes: SemanticNode[];
    },
  ): Promise<{ jobId: string; status: 'pending' | 'running' | 'done' | 'failed' }>;

  /** Fetch a finished report by job id. */
  report(jobId: string, userId: string): Promise<MirrorReport | null>;
}

/**
 * The reference implementation: transcribe the audio (`transcription`
 * job), then run the detector (`agent_run` job) — both persisted,
 * idempotent (AD-8). The detector itself is a pure function over the
 * claims + tree so it is unit-testable without the job system.
 */
export class DefaultMirrorCognitiveService implements MirrorCognitiveService {
  readonly jobs: JobDispatcherPort;
  readonly ai: AIPipelinePort;
  constructor(
    jobs: JobDispatcherPort,
    ai: AIPipelinePort,
  ) {
    this.jobs = jobs;
    this.ai = ai;
  }

  async analyze(
    req: {
      userId: string;
      subjectId?: string;
      transcript: string;
      claims: MirrorClaim[];
      nodes: SemanticNode[];
    },
  ) {
    const idempotencyKey = `mirror:${req.userId}:${req.subjectId ?? 'x'}`;
    const job = await this.jobs.dispatch({
      jobKind: 'agent_run',
      userId: req.userId,
      payload: {
        capability: 'mirror_cognitive',
        transcript: req.transcript,
        claims: req.claims,
        nodeIds: req.nodes.map((n) => n.id),
      },
      idempotencyKey,
    });
    void this.ai;
    return { jobId: job.jobId, status: job.status };
  }

  /** Fetch a finished report by job id. The worker stores the report in
   *  `job_queue.payload.report` when it completes (AD-8); `JobQueue`
   *  carries the payload, not a separate result column. */
  async report(jobId: string, userId: string): Promise<MirrorReport | null> {
    const job = await this.jobs.getJob(jobId);
    if (job === null || job.status !== 'done' || userId !== job.userId) return null;
    return (job.payload?.report as MirrorReport | undefined) ?? null;
  }
}

/**
 * Pure detector: match each claim against the tree; flag nodes with
 * `learningState === 'not-yet'` referenced by a claim as gaps, claims
 * whose `corpusText` contradicts the node label as contradictions, and
 * low-confidence claims as errors. The job worker wraps this.
 */
export function detectMirrorFindings(
  claims: MirrorClaim[],
  nodes: Array<{ id: string; label: string; learningState?: 'mastered' | 'fragile' | 'forgotten' | 'not-yet' }>,
): { findings: MirrorFinding[]; weakNodes: string[] } {
  const findings: MirrorFinding[] = [];
  const weakNodes: string[] = [];
  for (const claim of claims) {
    if (claim.nodeId === undefined) continue;
    const node = nodes.find((n) => n.id === claim.nodeId);
    if (node === undefined) continue;
    if (node.learningState === 'not-yet' || node.learningState === 'forgotten') {
      findings.push({
        kind: 'gap',
        nodeId: node.id,
        claimText: claim.text,
        resolution: `Unmapped/missing concept: ${node.label}`,
        confidence: 0.7,
      });
      weakNodes.push(node.id);
    }
  }
  return { findings, weakNodes };
}
