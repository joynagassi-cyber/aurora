/**
 * 14 shared ports (AD-15 SSoT, 03-sync / contract-catalog).
 *
 * Ports are the hexagonal boundaries: interfaces that modules implement
 * and callers depend on. Declared in `packages/domain`; implemented in
 * the data / platform / agent / scientific-engine packages (AD-1 / AD-6).
 *
 * If a signature is not explicit in the docs it is declared minimal with
 * a `// TODO(wave1)` marker — no invented fields (AD-3: no keys on
 * device; all calls stay inside the typed contract).
 */

/**
 * 1. `IdentityPort` — user context + RLS scope. Identity is the sole
 * writer of `user_context` (03 S4.2).
 */
export interface IdentityPort {
  /** read the caller's user_context (RLS-scoped) */
  getUserContext(userId: string): Promise<import('./entities-identity').UserContext | null>;
  /** seed / merge the feature-registry activation state */
  setFeatureState(userId: string, state: import('./entities-identity').FeatureSeedState): Promise<void>;
  /** AD-17 theme write */
  setTheme(userId: string, theme: import('./entities-identity').AuroraTheme, style: 'light' | 'dark'): Promise<void>;
}

/**
 * 2. `SyncPort` — PowerSync local-first sync (AD-7). The app pushes
 * local mutations; the port resolves sync status.
 */
export interface SyncPort {
  /** push a local mutation (idempotent by mutation id) */
  push(localMutationId: string, payload: unknown): Promise<{ accepted: boolean }>;
  /** current sync status of a collection */
  status(collection: string): import('./envelopes').AsyncState<{ synced: boolean; lagMs?: number }>;
  /** the latest server commit known to the local store */
  lastSyncedCommit(): string;
}

/**
 * 3. `JobDispatcherPort` — enqueue / inspect persisted jobs (AD-8).
 * `sourceLocalMutationId` + `idempotencyKey` make re-dispatch safe.
 */
export interface JobDispatcherPort {
  dispatch(req: {
    jobKind: import('./jobs').JobKind;
    userId: string;
    payload: unknown;
    /** idempotency (AD-8) */
    idempotencyKey?: string;
    /** link back to the originating local mutation */
    sourceLocalMutationId?: string;
  }): Promise<{ jobId: string; status: import('./jobs').JobStatus }>;
  getJob(jobId: string): Promise<import('./jobs').JobQueue | null>;
}

/**
 * 4. `StoragePort` — R2 / object storage for artifacts (F-06: binaries in
 * R2, metadata in Postgres). No keys on device (AD-3): short-lived signed
 * URLs only.
 */
export interface StoragePort {
  /** upload an artifact, returns the R2 key */
  upload(artifactId: string, r2Key: string, body: Uint8Array, contentType: string): Promise<{ r2Key: string; sizeBytes: number; url?: string }>;
  /** a short-lived signed URL to fetch */
  signedUrl(r2Key: string, ttlSec: number): Promise<string>;
}

/**
 * 5. `KnowledgeGraphPort` — semantic tree / node / edge queries
 * (01 Knowledge S3, AD-11 provenance).
 */
export interface KnowledgeGraphPort {
  /** the current semantic tree version for a user */
  getTree(userId: string, version?: string): Promise<import('./entities-knowledge').SemanticTreeVersion | null>;
  /** nodes + their learning state */
  getNodes(treeVersionId: string, nodeId?: string): Promise<Array<{ node: import('./entities-knowledge').SemanticNode; state: import('./entities-knowledge').NodeState }>>;
  /** bridge / edge queries */
  getEdges(treeVersionId: string, nodeId?: string): Promise<import('./entities-knowledge').SemanticEdge[]>;
}

/**
 * 6. `LearningPort` — FSRS scheduling (Learning module).
 */
export interface LearningPort {
  /** the next-due learning items */
  due(userId: string, limit: number): Promise<import('./entities-learning').LearningItem[]>;
  /** record a review + advance FSRS state (F-07: Progress is the sole
   * producer of progress evidence, this only moves the schedule) */
  review(cardId: string, userId: string, rating: number, ts: number): Promise<import('./entities-learning').FsrsState>;
}

/**
 * 7. `ProgressPort` — SOLE producer of ProgressEvidence (F-07).
 */
export interface ProgressPort {
  /** create an evidence row + emit `ProgressEvidenceCreated` */
  createEvidence(e: import('./entities-progress').ProgressEvidence): Promise<void>;
  /** a skill's current state */
  skillState(skillId: string, userId: string): Promise<import('./entities-progress').SkillState | null>;
  /** the trajectory / scenario for a goal */
  scenario(goalId: string, userId: string): Promise<import('./entities-progress').ProgressTrajectoryScenario | null>;
}

/**
 * 8. `DiscoveryPort` — competence-profile driven recommendations.
 */
export interface DiscoveryPort {
  /** next discovery items given the competence profile */
  recommend(userId: string, count: number): Promise<import('./entities-discovery').DiscoveryItem[]>;
  /** a discovery item by id */
  get(discoveryItemId: string): Promise<import('./entities-discovery').DiscoveryItem | null>;
}

/**
 * 9. `AgentPort` — invoke the agent kernel with declared capabilities.
 */
export interface AgentPort {
  /** run the agent kernel loop; returns an AgentRun id + stream */
  run(req: {
    userId: string;
    goalId?: string;
    /** declared capability ids (registries S10) */
    capabilityIds: string[];
    /** optional context */
    context?: Record<string, unknown>;
  }): Promise<{ agentRunId: string; status: import('./entities-agent').AgentRun['status'] }>;
}

/**
 * 10. `AIPipelinePort` — the multi-provider AI pipeline (AD: Agnes ->
 * Cloudflare AI Gateway -> Workers AI -> Groq/Cerebras -> CF Worker).
 * Implementations live in `platform/ai-pipeline`.
 */
export interface AIPipelinePort {
  /** classify / extract (structured) */
  classify(input: unknown, opts?: Record<string, unknown>): Promise<import('./envelopes').AIResponseEnvelope<unknown>>;
  /** generate text */
  generate(prompt: string, opts?: Record<string, unknown>): Promise<import('./envelopes').AIResponseEnvelope<string>>;
}

/**
 * 11. `ScientificEnginePort` — the engineering / scientific solver
 * (AD-10 engines; problem IR in domain).
 */
export interface ScientificEnginePort {
  /** normalize a problem into ProblemIR */
  normalize(problem: import('./entities-engineering').ProblemIR): Promise<{ ir: import('./entities-engineering').ProblemIR }>;
  /** solve a validated ProblemIR */
  solve(ir: import('./entities-engineering').ProblemIR, solverId?: string): Promise<import('./entities-engineering').SolverResult>;
  /** verify a solver result against the Verification Registry */
  verify(result: import('./entities-engineering').SolverResult): Promise<{ results: import('./entities-engineering').VerificationResult[]; ok: boolean }>;
}

/**
 * 12. `IntegrationsPort` — Composio tool / automation (01 S4.7).
 * Vendor SDK isolation (AD-1): implementations live in `data/platform/integrations`.
 */
export interface IntegrationsPort {
  /** current connection states */
  states(userId: string): Promise<import('./entities-integrations').IntegrationsState[]>;
  /** create / update an automation */
  upsertAutomation(a: import('./entities-integrations').Automation): Promise<void>;
  /** the exposed tool ids */
  tools(userId: string): Promise<string[]>;
}

/**
 * 13. `NotificationsPort` — OneSignal / push (ADR S13 cadence).
 */
export interface NotificationsPort {
  /** schedule a notification respecting quiet hours + cadence */
  send(userId: string, body: { title: string; body: string; deepLink?: string }): Promise<{ accepted: boolean; scheduledFor?: string }>;
}

/**
 * 14. `EventsPort` — read the producer's `events` history (AD-9 transport:
 * no broker; incremental `since_event_id` reads).
 */
export interface EventsPort {
  /** events after a given id, newest last */
  since(userId: string, sinceEventId?: string, limit?: number): Promise<import('./events').DomainEvent[]>;
  /** the latest event id known */
  latest(userId: string): Promise<string>;
}
