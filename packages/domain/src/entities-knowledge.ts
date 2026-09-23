/**
 * Knowledge entities (AD-15 SSoT, 01 S4.3, AD-6).
 *
 * AD-6: the Semantic Tree's truth lives in the Knowledge Base (server),
 * NEVER in the rendering engine. `NodeState` is written by Knowledge only,
 * by consuming `ProgressEvidenceCreated` / `SkillStateChanged`.
 */
import type { OrSetValue } from './crdt';

export interface Source {
  id: string;
  userId: string;
  title: string;
  kind: 'course' | 'document' | 'web' | 'book' | 'paper' | 'video' | 'audio' | 'other';
  url?: string;
  /** R2 object key when the source is a stored document */
  r2Key?: string;
  subjectId?: string;
  tags: OrSetValue[];
  createdAt: string;
  updatedAt: string;
}

export interface Concept {
  id: string;
  userId: string;
  name: string;
  /** corpus-authoritative definition (AD-11 fidelity) */
  definition?: string;
  subjectId?: string;
  sourceIds: OrSetValue[]; // CRDT list
  tags: OrSetValue[];
  createdAt: string;
  updatedAt: string;
}

export interface Formula {
  id: string;
  userId: string;
  /** LaTeX representation (ADR S15) */
  latex: string;
  /** plain-language meaning */
  description?: string;
  variables?: Record<string, { name: string; unit?: string; description?: string }>;
  conditions?: string;
  conceptId?: string;
  sourceRefIds: OrSetValue[]; // CRDT list
  createdAt: string;
  updatedAt: string;
}

export interface Definition {
  id: string;
  userId: string;
  term: string;
  /** the corpus formulation, kept textually dominant (AD-11) */
  corpusText?: string;
  /** Aurora's separate pedagogical explanation (AD-11: labelled, never replaces corpus) */
  explanation?: string;
  conceptId?: string;
  sourceRefIds: OrSetValue[];
  createdAt: string;
  updatedAt: string;
}

export interface Method {
  id: string;
  userId: string;
  name: string;
  /** ordered procedure (ADR S17) */
  steps: OrSetValue[];
  context?: string;
  subjectId?: string;
  sourceRefIds: OrSetValue[];
  createdAt: string;
  updatedAt: string;
}

/**
 * A node in the Semantic Tree (ADR S25.3): concept, domain, subject,
 * principle, definition, formula, method, example, application, skill.
 * The engine (React Flow) only VISUALISES this; truth is here + server.
 */
export interface SemanticNode {
  id: string;
  userId: string;
  /** node kind (ADR S25.3) */
  kind:
    | 'concept'
    | 'domain'
    | 'subject'
    | 'principle'
    | 'definition'
    | 'formula'
    | 'method'
    | 'example'
    | 'application'
    | 'skill';
  label: string;
  /** parent in the hierarchy (vertical relations) */
  parentId?: string;
  /** root = principle / definition / prerequisite (ADR S14) */
  isRoot?: boolean;
  /**
   * provenance refs (ADR S14.25: every important concept points to the
   * documents/passages/formulas supporting it). CRDT list; local mirror
   * has NO embedding column (03 S4.2).
   */
  sourceRefIds: OrSetValue[];
  /** Progress evidence refs (ADR S25.3 EvidenceRef) */
  evidenceRefIds: OrSetValue[];
  /** tree version the node belongs to (semantic_tree_version) */
  versionId?: string;
  /** local display state is NOT here — NodeState is the server-owned truth */
  createdAt: string;
  updatedAt: string;
}

/** Vertical (hierarchical) relation: depends-on / is-a-case-of / deepens / applies / leads-to. */
export interface SemanticEdge {
  id: string;
  userId: string;
  fromNodeId: string;
  toNodeId: string;
  relation:
    | 'depends-on'
    | 'is-a-case-of'
    | 'deepens'
    | 'applies'
    | 'leads-to'
    | 'example-of';
  createdAt: string;
  updatedAt: string;
}

/**
 * Transversal inter-domain bridge (ADR S14: secondary, explicitly
 * annotated; the main interface stays a tree, never a web).
 */
export interface SemanticBridge {
  id: string;
  userId: string;
  fromNodeId: string;
  toNodeId: string;
  /** the annotation explaining the cross-domain connection */
  label: string;
  annotation?: string;
  createdAt: string;
  updatedAt: string;
}

/**
 * Tree versioning (AD-6: a Knowledge-owned table, NOT Progress Event
 * History). "évolution temporelle" — how the knowledge deepened.
 */
export interface SemanticTreeVersion {
  id: string;
  userId: string;
  /** monotonically increasing revision */
  revision: number;
  /** why this version was cut (new ingestion, consolidation…) */
  summary?: string;
  createdAt: string;
}

/**
 * Per-node mastery state. AD-6: Knowledge is the ONLY writer of
 * NodeState (by consuming ProgressEvidenceCreated / SkillStateChanged).
 */
export interface NodeState {
  userId: string;
  nodeId: string;
  /** collapsed/expanded/selected/focused are VIEW state (02 S3), NOT domain
   *  truth; mastered/fragile/forgotten are the domain states (ADR S18.2).
   *  Domain-level truth here is the learning state only. */
  learningState: 'mastered' | 'fragile' | 'forgotten' | 'not-yet';
  /** 0..1 */
  confidence?: number;
  /** when the state was last set */
  setAt: string;
}

/** Provenance ref (ADR S14.25 / S25.3): points to a document, page, passage,
 *  formula, or discovery supporting a concept. */
export interface SourceRef {
  id: string;
  userId: string;
  sourceId: string;
  /** optional page / passage / section locator */
  locator?: string;
  /** the cited text (fidelity, AD-11) */
  quotedText?: string;
  createdAt: string;
  updatedAt: string;
}
