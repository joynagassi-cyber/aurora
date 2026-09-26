/**
 * @aurora/ascent — path builder (wave 3, docs/ascent/overview.md S3,
 * S10, S13; implementation.md Step 2).
 *
 * Builds an `AscentLearningIR` from: the goal, the `LearnerBaseline`
 * (Progress), the knowledge concepts available to the goal, and the
 * goal's target date. PURE + deterministic (S22: no pedagogical LLM) —
 * the LLM explains, Ascent sequences.
 *
 * Invariants:
 *  - AD-7: Ascent writes ONLY `ascent_paths`; this builder is data.
 *  - AD-6: steps reference Knowledge objects by ID (conceptRefs /
 *    sourceRefs) — never content.
 *  - overview S20 (80/20): the output is the single-row projection
 *    persisted in `ascent_paths` (steps JSONB, depth JSONB, baseline
 *    snapshot, adaptation log).
 *
 * Id generation is injectable (server ULIDs in prod, sequential in
 * tests) — pure function, no clock, no randomness.
 */
import type {
  AscentActivity,
  AscentLearningIR,
  AscentStep,
  DepthLevel,
  LearnerBaseline,
} from '@aurora/domain';
import { DEPTH_BUDGETS, selectDepth, type DepthImportance } from './depth';

/** A knowledge unit the goal can compose (Knowledge SSoT, referenced by id). */
export interface AscentStepInput {
  /** Knowledge concept_id (AD-6: reference, not content) */
  conceptId: string;
  label: string;
  /** Progress skill_id the step works on (optional) */
  skillId?: string;
  /** SourceRef ids (AD-11 provenance) — hierarchy enforced separately */
  sourceRefIds: string[];
  /**
   * what must be mastered before this concept: other conceptIds in the
   * path (chain gating) or Progress skill_ids (baseline gating).
   */
  requires: string[];
  /** trajectory importance (depth selection, S13) */
  importance: DepthImportance['importance'];
  /** Knowledge refs attached to the step (formula/document/source) */
  knowledgeRefs?: Array<{ type: 'concept' | 'formula' | 'document' | 'source'; id: string }>;
}

export interface BuildPathInput {
  userId: string;
  /** "Master RDM by exam day" (NL, verbatim) */
  goal: string;
  /** target skill (Progress) when the goal binds to one */
  targetSkill?: string;
  /** ISO deadline */
  targetDate?: string;
  baseline: LearnerBaseline;
  inputs: AscentStepInput[];
  now: string;
  /** deterministic id allocator (server ULID in prod) */
  nextId?: (prefix: string) => string;
  /** path id */
  pathId?: string;
}

/**
 * READ → DO → PROVE sequencing of activities, scaled by depth (S10/S13).
 * The sequence is a FRAMEWORK, not a rigid constraint: the Agent may
 * reorder / skip phases (see adapter.ts) — but this is the DEFAULT.
 */
export function sequencePhaseActivities(
  step: AscentStep,
  knowledgeRef: { type: 'concept' | 'formula' | 'document' | 'source'; id: string } | undefined,
  nextId: (prefix: string) => string,
): AscentActivity[] {
  const budget = DEPTH_BUDGETS[step.depth] ?? DEPTH_BUDGETS.standard;
  const acts: AscentActivity[] = [];

  if (step.phase === 'read') {
    acts.push({
      id: nextId('act'),
      type: 'read',
      knowledgeRef: knowledgeRef ?? { type: 'concept', id: step.conceptRefs[0] ?? '' },
    });
  }

  if (step.phase === 'do') {
    acts.push({
      id: nextId('act'),
      type: 'exercise',
      learningCommand: {
        action: 'create_exercise',
        params: { topic: step.label, depth: step.depth, item_count: budget.examples },
      },
    });
    if (budget.flashcards > 0) {
      acts.push({
        id: nextId('act'),
        type: 'flashcard',
        learningCommand: {
          action: 'generate_flashcards',
          params: { topic: step.label, depth: step.depth, item_count: budget.flashcards },
        },
      });
    }
  }

  if (step.phase === 'prove') {
    acts.push({
      id: nextId('act'),
      type: 'quiz',
      learningCommand: {
        action: 'generate_qcm',
        params: { topic: step.label, depth: step.depth, item_count: budget.qcmItems },
      },
    });
    if (budget.mirror) {
      acts.push({
        id: nextId('act'),
        type: 'mirror',
        learningCommand: { action: 'start_mirror', params: { topic: step.label } },
      });
    }
    if (budget.openProblems > 0) {
      acts.push({
        id: nextId('act'),
        type: 'exercise',
        learningCommand: {
          action: 'create_exercise',
          params: { topic: step.label, kind: 'open-problem', count: budget.openProblems },
        },
      });
    }
  }

  if (step.phase === 'remediation') {
    acts.push({
      id: nextId('act'),
      type: 'remediation',
      learningCommand: {
        action: 'create_exercise',
        params: { topic: step.label, kind: 'remediation', count: 2 },
      },
    });
  }

  if (step.phase === 'recap') {
    acts.push({ id: nextId('act'), type: 'recap' });
  }

  return acts;
}

/**
 * Build the IR. Step order = input order (the goal decomposition fixes
 * it); each concept expands to READ → DO → PROVE (S10 framework order),
 * plus one RECAP closing the path. Prerequisites + passage criteria are
 * declared per step; all step statuses start `pending` — enforcement
 * happens in the adapter (a step cannot become `active` while a
 * prerequisite is not `done`).
 */
export function buildPath(build: BuildPathInput): AscentLearningIR {
  const counter = { n: 0 };
  const nextId =
    build.nextId ??
    ((prefix: string) => `${prefix}-${(++counter.n).toString().padStart(4, '0')}`);

  const inputs = build.inputs;

  // Per concept: READ, DO, PROVE (framework order, S10).
  type Phase = AscentStep['phase'];
  const stepInputs: Array<{ input: AscentStepInput; phase: Phase }> = [];
  for (const i of inputs) {
    stepInputs.push({ input: i, phase: 'read' });
    stepInputs.push({ input: i, phase: 'do' });
    stepInputs.push({ input: i, phase: 'prove' });
  }
  // one recap closing the path (S10 / S13)
  stepInputs.push({
    input: {
      conceptId: inputs[inputs.length - 1]?.conceptId ?? 'recap',
      label: 'Récapitulatif',
      sourceRefIds: [],
      requires: [],
      importance: 'peripheral',
    },
    phase: 'recap',
  });

  const steps: AscentStep[] = stepInputs.map(({ input, phase }) => {
    const id = nextId('step');
    const importance: DepthImportance = {
      skillId: input.skillId,
      importance: phase === 'recap' ? 'peripheral' : input.importance,
    };
    const depth =
      phase === 'recap'
        ? 'quick'
        : selectDepth({
            baseline: build.baseline,
            importance,
            targetDate: build.targetDate,
            now: build.now,
          });

    const step: AscentStep = {
      id,
      label:
        phase === 'recap'
          ? `Recap — ${input.label}`
          : `${phase === 'read' ? 'Read' : phase === 'do' ? 'Practice' : 'Prove'} — ${input.label}`,
      conceptRefs: phase === 'recap' ? [] : [input.conceptId],
      skillRef: input.skillId,
      sourceRefs: input.sourceRefIds,
      activities: [],
      phase,
      depth,
      status: 'pending',
    };
    const knowledgeRef = input.knowledgeRefs?.[0] ?? {
      type: 'concept' as const,
      id: input.conceptId,
    };
    step.activities = sequencePhaseActivities(step, knowledgeRef, nextId);
    return step;
  });

  // concept step id per phase (used to declare the intra-concept chain).
  const stepByConceptPhase = new Map<string, AscentStep>();
  for (const s of steps) {
    if (s.conceptRefs[0]) stepByConceptPhase.set(`${s.conceptRefs[0]}:${s.phase}`, s);
  }
  const stepIndex = new Map(steps.map((s) => [s.id, s]));
  const idOf = (key: string): string | undefined => stepByConceptPhase.get(key)?.id;

  /** A `requires` entry resolves to: a step id (intra-path chain), a
   *  baseline-known skill id, or an external skill_id (baseline check). */
  const prereqMet = (r: string): boolean => {
    // chain step id (rare, explicit) — resolved through its "done" status
    if (stepIndex.get(r)?.status === 'done') return true;
    // baseline: the skill is mastered (S6.2 `mastered` bucket)
    return build.baseline.mastered.includes(r);
  };

  const prerequisites: AscentLearningIR['prerequisites'] = [];
  for (const s of steps) {
    const concept = s.conceptRefs[0];
    const requires: string[] = [];
    if (concept && s.phase === 'do') {
      const r = idOf(`${concept}:read`);
      if (r) requires.push(r);
    }
    if (concept && s.phase === 'prove') {
      for (const p of ['read', 'do'] as const) {
        const r = idOf(`${concept}:${p}`);
        if (r) requires.push(r);
      }
    }
    if (concept && s.phase === 'read') {
      // external prerequisites declared on the input gate the READ step
      // of the concept (that is where the chain is gated, S10).
      const inputOfStep = inputs.find((i) => i.conceptId === concept);
      for (const r of inputOfStep?.requires ?? []) {
        // resolve: if r is a concept in the path, its READ step; else skill_id
        const rStep = idOf(`${r}:read`);
        requires.push(rStep ?? r);
      }
    }
    if (requires.length === 0) continue;

    const allMet = requires.every((r) => {
      const step = stepIndex.get(r);
      if (step) return step.status === 'done';
      return prereqMet(r); // baseline / external skill
    });
    prerequisites.push({
      stepId: s.id,
      requires,
      status: allMet ? 'met' : 'pending',
    });
  }

  // Passage criteria (S13 / S19 "adaptation on evidence"): PROVE steps
  // gate on the QCM score, threshold 0.8 (>= 80%).
  const passageCriteria: AscentLearningIR['passageCriteria'] = steps
    .filter((s) => s.phase === 'prove')
    .map((s) => ({
      stepId: s.id,
      criterion: 'QCM >= 80%',
      metric: 'qcm_score',
      threshold: 0.8,
    }));

  const depthRecord: Record<string, DepthLevel> = {};
  for (const s of steps) depthRecord[s.id] = s.depth;

  return {
    id: build.pathId ?? nextId('path'),
    userId: build.userId,
    goal: build.goal,
    targetSkill: build.targetSkill,
    targetDate: build.targetDate,
    steps,
    depth: depthRecord,
    baseline: build.baseline,
    prerequisites,
    passageCriteria,
    adaptations: [],
    status: 'active',
    createdAt: build.now,
    updatedAt: build.now,
  };
}
