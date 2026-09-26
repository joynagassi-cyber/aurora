/**
 * @aurora/ascent — adapter (wave 3, docs/ascent/overview.md S3.2, S17;
 * implementation.md "Events (consumed only — AD-9 stays closed)").
 *
 * Adapts a path on the 6 AD-9 events Ascent CONSUMES. Ascent EMITS NO
 * new event (AD-9 closed vocabulary): every adaptation is logged as an
 * `AscentAdaptation` (append-only log data, NOT a vocabulary entry) and
 * the path is rewritten in `ascent_paths` (AD-7 single-writer).
 *
 * Each function is PURE: (path, event, opts) -> new path. The server
 * (fn-ascent / fn-agent-run) applies the result; the device only reads
 * the mirrored row (AD-12).
 */
import type {
  AscentAdaptation,
  AscentLearningIR,
  DomainEvent,
} from '@aurora/domain';

/**
 * The 6 events Ascent reacts to (overview S17 / implementation.md).
 * Anything else (CourseImported, FlashcardReviewed, JobCompleted,
 * ArtifactGenerated handled below) — the full AD-9 union is accepted but
 * only these 6 drive an adaptation.
 */
export const ASCENT_CONSUMED_EVENTS: readonly string[] = [
  'ProgressEvidenceCreated',
  'SkillStateChanged',
  'DiscoveryItemCreated',
  'GoalUpdated',
  'TaskCompleted',
  'ArtifactGenerated',
];

export interface AdaptOpts {
  now: string;
  nextId: (prefix: string) => string;
}

function logAdaptation(
  path: AscentLearningIR,
  opts: AdaptOpts,
  entry: Omit<AscentAdaptation, 'id' | 'pathId' | 'createdAt'>,
): AscentLearningIR {
  const adaptation: AscentAdaptation = {
    id: opts.nextId('adapt'),
    pathId: path.id,
    createdAt: opts.now,
    ...entry,
  };
  return {
    ...path,
    adaptations: [...path.adaptations, adaptation],
    updatedAt: opts.now,
  };
}

function stepById(path: AscentLearningIR, id: string): AscentLearningIR['steps'][number] {
  const s = path.steps.find((x) => x.id === id);
  if (!s) throw new Error(`ascent/unknown_step: ${id}`);
  return s;
}

/**
 * Adapt on `ProgressEvidenceCreated` (mastery changed).
 *
 * - evidence on a PROVE step's skill with confidence below the passage
 *   threshold → `insert_remediation` before the next step (overview S19
 *   "adaptation on evidence: QCM 50% → remediation inserted").
 * - evidence meeting the threshold → mark the PROVE step `done`,
 *   unblock its dependents, log an adaptation.
 *
 * Evidence carries a `skillId`; the matching PROVE step is the one whose
 * `skillRef` equals it. When no PROVE step binds the skill, the evidence
 * only logs (no structural change — Ascent is conservative).
 */
export function adaptOnEvidence(
  path: AscentLearningIR,
  evidence: { evidenceId: string; skillId?: string; confidence: number; sourceEventId: string },
  opts: AdaptOpts,
): AscentLearningIR {
  if (!evidence.skillId) return logAdaptation(path, opts, {
    trigger: `ProgressEvidence: ${evidence.evidenceId} (no skill binding)`,
    action: 'reorder',
    detail: 'Evidence without a step binding — no structural change.',
    affectedSteps: [],
    evidenceRefs: [evidence.evidenceId],
  });

  const proveSteps = path.steps.filter(
    (s) => s.phase === 'prove' && s.skillRef === evidence.skillId,
  );
  if (proveSteps.length === 0) {
    return logAdaptation(path, opts, {
      trigger: `ProgressEvidence: skill ${evidence.skillId} not on the path`,
      action: 'reorder',
      detail: 'Evidence for a skill the path does not cover — no structural change.',
      affectedSteps: [],
      evidenceRefs: [evidence.evidenceId],
    });
  }

  const threshold = path.passageCriteria.find((c) => c.stepId === proveSteps[0]!.id)
    ?.threshold ?? 0.8;
  const passed = evidence.confidence >= threshold;

  if (passed) {
    const next = structuredClone(path);
    for (const s of proveSteps) stepById(next, s.id).status = 'done';
    // unblock: mark prerequisites of the satisfied steps as met
    next.prerequisites = next.prerequisites.map((p) =>
      p.stepId === proveSteps[0]!.id ? { ...p, status: 'met' as const } : p,
    );
    return logAdaptation(next, opts, {
      trigger: `ProgressEvidence: skill ${evidence.skillId} ${evidence.confidence} >= ${threshold}`,
      action: 'accelerate',
      detail: 'PROVE step passed — step marked done, dependents unblocked.',
      affectedSteps: proveSteps.map((s) => s.id),
      evidenceRefs: [evidence.evidenceId],
    });
  }

  // failed: insert a remediation step BEFORE the first pending PROVE step
  const next = structuredClone(path);
  const idx = next.steps.findIndex((s) => s.id === proveSteps[0]!.id);
  const remediation: AscentLearningIR['steps'][number] = {
    id: opts.nextId('step'),
    label: `Remediation — ${path.goal}`,
    conceptRefs: proveSteps[0]!.conceptRefs,
    skillRef: evidence.skillId,
    sourceRefs: proveSteps[0]!.sourceRefs,
    activities: [
      {
        id: opts.nextId('act'),
        type: 'remediation',
        learningCommand: {
          action: 'create_exercise',
          params: {
            topic: proveSteps[0]!.label,
            kind: 'remediation',
            count: 2,
            evidenceRef: evidence.evidenceId,
          },
        },
      },
    ],
    phase: 'remediation',
    depth: next.depth[proveSteps[0]!.id] ?? 'standard',
    status: 'pending',
  };
  next.steps.splice(idx, 0, remediation);
  next.depth[remediation.id] = remediation.depth;
  const prove = stepById(next, proveSteps[0]!.id);
  prove.status = 'remediation';
  return logAdaptation(next, opts, {
    trigger: `ProgressEvidence: skill ${evidence.skillId} ${evidence.confidence} < ${threshold}`,
    action: 'insert_remediation',
    detail: `Remediation inserted before step ${prove.label}.`,
    affectedSteps: [remediation.id, proveSteps[0]!.id],
    evidenceRefs: [evidence.evidenceId],
  });
}

/**
 * Adapt on `SkillStateChanged` (baseline refresh: a skill went e.g.
 * fragile → mastered, S17). Updates the baseline snapshot + the depth of
 * the bound steps (mastered → shallow, S10/S13 "mastered = skip").
 */
export function adaptOnSkillStateChanged(
  path: AscentLearningIR,
  event: DomainEvent & { type: 'SkillStateChanged' },
  opts: AdaptOpts,
): AscentLearningIR {
  const { skillId, newState } = event.payload;
  const mastered = newState === 'mastered' || newState === 'expert';

  const next = structuredClone(path);
  // refresh the baseline skill entry (the snapshot stays in sync)
  const entry = next.baseline.skillStates.find((s) => s.skillId === skillId);
  if (entry) entry.status = mastered ? 'mastered' : 'fragile';
  if (mastered && !next.baseline.mastered.includes(skillId)) {
    next.baseline.mastered.push(skillId);
  }
  if (!mastered) {
    next.baseline.mastered = next.baseline.mastered.filter((x) => x !== skillId);
  }

  // shallow the bound steps (S13 "mastered = skip")
  const affected = next.steps
    .filter((s) => s.skillRef === skillId && s.status !== 'done')
    .map((s) => s.id);
  if (mastered && affected.length > 0) {
    for (const id of affected) {
      const s = stepById(next, id);
      s.depth = 'quick';
      next.depth[id] = 'quick';
    }
  }

  return logAdaptation(next, opts, {
    trigger: `SkillStateChanged: ${skillId} -> ${newState}`,
    action: mastered ? 'shallow' : 'revisit',
    detail: mastered
      ? 'Skill mastered — bound steps shallowed to quick (S13).'
      : 'Skill regressed — bound steps kept for revisit.',
    affectedSteps: affected,
    evidenceRefs: [],
  });
}

/**
 * Adapt on `DiscoveryItemCreated` (a new gap / topic, S17). Inserts a new
 * READ step at the end of the path (before the recap) for the new topic.
 */
export function adaptOnDiscovery(
  path: AscentLearningIR,
  event: DomainEvent & { type: 'DiscoveryItemCreated' },
  opts: AdaptOpts,
): AscentLearningIR {
  const { discoveryItemId, topic, sources } = event.payload;
  const next = structuredClone(path);
  const recapIdx = next.steps.findIndex((s) => s.phase === 'recap');
  const step: AscentLearningIR['steps'][number] = {
    id: opts.nextId('step'),
    label: `Discovery — ${topic}`,
    conceptRefs: [discoveryItemId],
    sourceRefs: sources,
    activities: [
      {
        id: opts.nextId('act'),
        type: 'read',
        knowledgeRef: { type: 'source', id: discoveryItemId },
      },
    ],
    phase: 'read',
    depth: 'quick',
    status: 'pending',
  };
  next.depth[step.id] = 'quick';
  if (recapIdx === -1) next.steps.push(step);
  else next.steps.splice(recapIdx, 0, step);
  return logAdaptation(next, opts, {
    trigger: `DiscoveryItemCreated: ${topic}`,
    action: 'insert_remediation',
    detail: `New discovery topic '${topic}' inserted before the recap.`,
    affectedSteps: [step.id],
    evidenceRefs: [],
  });
}

/**
 * Adapt on `GoalUpdated` (S17: goal changed → recompose). V1 is
 * deterministic: the kernel recomposes by calling `buildPath` again;
 * this function only flags the path for recomposition + logs.
 */
export function adaptOnGoalUpdated(
  path: AscentLearningIR,
  event: DomainEvent & { type: 'GoalUpdated' },
  opts: AdaptOpts,
): AscentLearningIR {
  const { goalId, fields } = event.payload;
  return logAdaptation(path, opts, {
    trigger: `GoalUpdated: ${goalId} (${fields.join(', ')})`,
    action: 'recompose',
    detail: 'Goal changed — path flagged for recomposition by the kernel (V1 = 1 active goal).',
    affectedSteps: path.steps.map((s) => s.id),
    evidenceRefs: [],
  });
}

/**
 * Adapt on `TaskCompleted` (S17: practice done → check passage criteria).
 * Marks the matching PROVE step done when its criteria are met.
 */
export function adaptOnTaskCompleted(
  path: AscentLearningIR,
  event: DomainEvent & { type: 'TaskCompleted' },
  opts: AdaptOpts,
): AscentLearningIR {
  const { taskId, evidenceRefs } = event.payload;
  const next = structuredClone(path);
  const affected: string[] = [];
  for (const s of next.steps) {
    if (s.phase !== 'prove' || s.status === 'done') continue;
    const ref = evidenceRefs?.find((e) => e.includes(taskId) || e.includes(s.id));
    if (ref) {
      s.status = 'done';
      affected.push(s.id);
    }
  }
  return logAdaptation(next, opts, {
    trigger: `TaskCompleted: ${taskId}`,
    action: 'accelerate',
    detail: 'Practice task completed — passage criteria checked, matching PROVE step advanced.',
    affectedSteps: affected,
    evidenceRefs: evidenceRefs ?? [],
  });
}

/**
 * Adapt on `ArtifactGenerated` (S17: study sheet ready → READ complete).
 * Marks the READ phase of the bound step done.
 */
export function adaptOnArtifact(
  path: AscentLearningIR,
  event: DomainEvent & { type: 'ArtifactGenerated' },
  opts: AdaptOpts,
): AscentLearningIR {
  const { artifactId } = event.payload;
  const next = structuredClone(path);
  const affected: string[] = [];
  for (const s of next.steps) {
    if (s.phase !== 'read' || s.status === 'done') continue;
    s.status = 'done';
    affected.push(s.id);
    if (affected.length === 1) break; // the most recent read step
  }
  return logAdaptation(next, opts, {
    trigger: `ArtifactGenerated: ${artifactId}`,
    action: 'accelerate',
    detail: 'Study sheet ready — READ phase marked complete.',
    affectedSteps: affected,
    evidenceRefs: [artifactId],
  });
}

/**
 * Dispatch an AD-9 event to the matching adaptation. Returns the path
 * unchanged for events Ascent does not react to (AD-9 stays closed —
 * Ascent never invents a 10th reaction).
 */
export function adaptPath(
  path: AscentLearningIR,
  event: DomainEvent,
  opts: AdaptOpts,
): AscentLearningIR {
  switch (event.type) {
    case 'ProgressEvidenceCreated':
      return adaptOnEvidence(
        path,
        {
          evidenceId: event.payload.evidenceId,
          skillId: event.payload.skillId,
          confidence: event.payload.confidence,
          sourceEventId: event.payload.sourceEventId,
        },
        opts,
      );
    case 'SkillStateChanged':
      return adaptOnSkillStateChanged(path, event, opts);
    case 'DiscoveryItemCreated':
      return adaptOnDiscovery(path, event, opts);
    case 'GoalUpdated':
      return adaptOnGoalUpdated(path, event, opts);
    case 'TaskCompleted':
      return adaptOnTaskCompleted(path, event, opts);
    case 'ArtifactGenerated':
      return adaptOnArtifact(path, event, opts);
    default:
      // CourseImported, FlashcardReviewed, JobCompleted — not consumed.
      return path;
  }
}

/**
 * "Je bloque" flow (overview S14). The user is stuck on a concept/formula.
 * 1. DIAGNOSE: find the blocker — the first non-done step on the active
 *    skill that is not yet `done` (the sub-concept likely blocking).
 * 2. REMEDIATE: insert a targeted remediation step (2 exercises) before
 *    it. The Agent/Mirror explains; Ascent sequences the fix.
 */
export function diagnoseBlocker(
  path: AscentLearningIR,
  skillId: string,
): AscentLearningIR['steps'][number] | undefined {
  const active = path.steps.find(
    (s) => s.skillRef === skillId && s.status === 'active' && s.phase !== 'recap',
  );
  if (active) return active;
  const pending = path.steps.find(
    (s) => s.skillRef === skillId && s.status === 'pending' && s.phase !== 'recap',
  );
  return pending;
}

export function insertRemediationForBlocker(
  path: AscentLearningIR,
  skillId: string,
  opts: AdaptOpts,
): AscentLearningIR {
  const blocker = diagnoseBlocker(path, skillId);
  if (!blocker) {
    return logAdaptation(path, opts, {
      trigger: `Je bloque: ${skillId}`,
      action: 'reorder',
      detail: 'No blocker step found for the skill — nothing to insert.',
      affectedSteps: [],
      evidenceRefs: [],
    });
  }
  return adaptOnEvidence(
    path,
    {
      evidenceId: `blocker:${skillId}`,
      skillId,
      confidence: 0, // stuck ⇒ below threshold ⇒ remediation path
      sourceEventId: '',
    },
    opts,
  );
}
