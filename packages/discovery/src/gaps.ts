/**
 * Discovery module — gap analysis (discovery-gap-pipeline S1, ADR S13.4/
 * S18.1). Discovery DETECTS gaps; the `Gap` rows are OWNED by Progress
 * (03 S4.2) — this module produces the DETECTION objects Progress persists.
 * No cross-module table writes (AD-2): the detection is a pure,
 * deterministic comparison of a Discovery result against the Semantic
 * Tree position + known gaps.
 */
import type { Gap, SemanticNode, SkillState } from '@aurora/domain';
import type { ResearchResult } from './research-provider.ts';

/** The structured gap detection input (S1.2 semantic confrontation). */
export interface GapDetectionInput {
  userId: string;
  /** the Discovery result that triggered the detection */
  result: ResearchResult;
  /** the current semantic tree nodes (Knowledge SSoT, read-only) */
  nodes: readonly Pick<SemanticNode, 'id' | 'label' | 'kind'>[];
  /** the existing gaps (dedupe: same concept + discipline = no dup) */
  existingGaps: readonly Pick<Gap, 'id' | 'kind' | 'description'>[];
  /** the competence states the gap weighs against (SkillStateChanged feed) */
  skillStates?: readonly Pick<SkillState, 'skillId' | 'level' | 'confidence'>[];
  /** the discipline the result belongs to (filter context) */
  discipline: string;
}

export type GapUrgency = 'critical' | 'high' | 'medium' | 'low';

/** A detected gap — the object Progress persists into `gaps` (S1.3). */
export interface DetectedGap {
  userId: string;
  /** the concept missing from the tree (e.g. "FEM validation") */
  concept: string;
  discipline: string;
  /** ADR S13.4 gap kind (domain `Gap.kind` SSoT) */
  kind: Gap['kind'];
  urgency: GapUrgency;
  /** what backs this gap (typed sources, AD-11 provenance) */
  sourceRefs: string[];
  /** the tree position the new branch/node should occupy (S1.2) */
  treePosition: {
    branch: string;
    prerequisite?: string;
    status: 'missing' | 'weak' | 'known-not-practiced';
  };
  /** the remediation hint for Learning (S1.3 `remediation`) */
  remediation?: {
    focusTime?: number;
    deadline?: string;
  };
  /** the Discovery result that produced it (traceability, AD-9) */
  discoveryRef: string;
}

export const URGENCY_BY_KIND: Record<Gap['kind'], GapUrgency> = {
  'program-vs-practice': 'high',
  'local-vs-international': 'medium',
  technological: 'medium',
  methodological: 'medium',
  portfolio: 'low',
  veille: 'low',
  depth: 'medium',
  skill: 'high',
  other: 'low',
};

/**
 * Detect a gap when a Discovery result references a concept NOT in the
 * tree but required by professional/normative practice (S1.2). Pure:
 * same input → same detection; dedupes on concept+discipline (S1.3:
 * "not duplicated if same concept already has a Gap").
 */
export function detectGap(
  input: GapDetectionInput,
): DetectedGap | null {
  const { result, nodes, existingGaps, discipline } = input;

  // Extract the candidate concept from the result (its title is the
  // concept name per S1.2: "FEM validation").
  const concept = result.title.trim();
  if (concept === '') return null;

  // Is the concept already in the tree? If so, no gap (S1.2: gap = NOT
  // in the tree).
  const inTree = nodes.some((n) =>
    n.label.toLowerCase() === concept.toLowerCase(),
  );
  if (inTree) return null;

  // Dedupe: same concept + discipline already has a gap (S1.3 test).
  const dup = existingGaps.some(
    (g) =>
      g.description.trim().toLowerCase() === concept.toLowerCase(),
  );
  if (dup) return null;

  // Urgency: exam-critical / normative = high, career-critical = medium (S1.2).
  const urgency: GapUrgency = result.kind === 'regulatory' ? 'high' : 'medium';

  return {
    userId: input.userId,
    concept,
    discipline,
    kind: 'skill',
    urgency,
    sourceRefs: [result.url ?? result.title],
    treePosition: {
      branch: discipline,
      status: 'missing',
    },
    discoveryRef: result.url ?? result.title,
  };
}

/**
 * Weigh a set of detections against competence states: a gap whose
 * referenced skill is already `mastered`/`expert` is downgraded (S2C
 * backlink: strong NodeState lowers the urgency).
 */
export function weighGapsAgainstStates(
  gaps: readonly DetectedGap[],
  states: readonly Pick<SkillState, 'skillId' | 'level' | 'confidence'>[],
): DetectedGap[] {
  const mastered = new Set(
    states
      .filter((s) => s.level === 'mastered' || s.level === 'expert')
      .map((s) => s.skillId),
  );
  return gaps.map((g) => {
    const hit = states.find((s) => s.skillId === g.concept);
    if (hit !== undefined && mastered.has(hit.skillId)) {
      return { ...g, urgency: 'low' as const };
    }
    return g;
  });
}
